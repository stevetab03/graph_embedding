# Graph Embedding for Automated Semantic Layer Generation in Power BI

> *An Application of Injective Graph Homomorphism to Data-Warehouse-to-Semantic-Layer Translation*

**Liyuan (Steve) Zhang**  
github.com/stevetab03/graph_embedding

---

## Abstract

Every Power BI implementation begins with the same structural inefficiency:
a dimensional model already exists in the data warehouse — tables defined,
foreign keys enforced, grain documented, hierarchies established — yet a BI
developer rebuilds it manually from a blank canvas. This paper formalizes that
redundancy as a graph-theoretic problem, identifies the correct mathematical
object for its solution, and presents a working implementation.

The warehouse schema is modeled as a directed graph G = (V, E) where vertices
are tables and edges are foreign key constraints. The Power BI semantic model
is a second directed graph G' = (V', E') of identical structure. The mapping
from G to G' is an **injective graph homomorphism** — preserving vertices,
preserving adjacency, and constraining the image to a **spanning forest** via
BFS reachability. A second BFS pass performs **connected component
decomposition** of the schema graph, partitioning it into N logical models
corresponding to distinct subject areas. Each component is translated into an
independent deployment-ready Power BI PBIP artifact.

The proof-of-concept is validated on SQL Server against two logical models —
a star schema and a snowflake schema — sharing a conformed dimension. The
extraction layer is architected for portability across any ANSI-compliant
relational database. The output translation layer is independently variable,
establishing a pluggable adapter architecture for additional BI platforms.

---

## 1. Naming and Mathematical Grounding

The tool is named **GraphEmbed\_PBI** — the Power BI application of the
broader `graph_embedding` framework. The name is chosen for mathematical
precision.

A **graph homomorphism** f: G → G' is a map between graphs that preserves
adjacency — if (u, v) ∈ E then (f(u), f(v)) ∈ E'. An **injective** homomorphism
additionally requires that distinct vertices map to distinct vertices:
u ≠ v ⟹ f(u) ≠ f(v). When the image f(G) faithfully represents the
structure of G in G' — preserving both adjacency and non-adjacency — the map
is a **graph embedding**.

GraphEmbed\_PBI computes exactly this: tables in the warehouse map injectively
to tables in the semantic model, foreign key relationships map to Power BI
relationships, and the image is constrained to be a valid spanning forest
by the active/inactive classification step. The mapping is faithful — no
warehouse relationship is invented, no warehouse table is collapsed into
another.

The alternative term **functor** (from category theory) is also precise:
the warehouse schema is a category with tables as objects and foreign keys as
morphisms, the Power BI semantic model is a second category, and the mapping
preserves composition. Graph embedding is the preferred term because it
emphasizes the spatial interpretation — the semantic layer is an embedding of
the warehouse graph into a new representational space — and is the standard
vocabulary in both computer science and modern mathematics for this class of
structure-preserving map.

---

## 2. The Problem

### 2.1 The Redundant Rebuild

The relational schema of any warehouse is a directed graph: tables are
vertices, foreign key constraints are directed edges. This graph is fully
defined by the warehouse — enforced at the engine level, readable from system
metadata, and updated automatically when the schema changes.

The Power BI semantic model is also a directed graph of identical type: tables
are vertices, relationships are edges with direction, from-column, and
to-column attributes.

The mapping from one graph to the other is not ambiguous. It is a
deterministic, computable function of the warehouse metadata. Yet in standard
practice, this function is evaluated manually by a BI developer on every
project — a process that consumes two to five days per subject area, introduces
structural errors, and produces a semantic layer that immediately begins to
drift from its source.

### 2.2 Three Classes of Failure

Manual reconstruction introduces three systematic failure modes:

**Structural errors.** Relationships drawn in the wrong direction. Cardinality
misspecified. Join columns misidentified. These are not rare — they are the
expected output of a manual process performed without ground truth.

**Coverage gaps.** Tables omitted. Relationships missed. Subject areas
partially implemented. Enterprise warehouses with 30+ tables and 40+
relationships exceed what a developer can reliably reconstruct in a single
session.

**Definition drift.** The warehouse changes. A foreign key is modified.
A table is renamed. The semantic layer is not updated. Reports silently
return incorrect results. This is the most costly failure mode and the
hardest to detect.

All three are eliminated when the mapping is computed rather than drawn.

### 2.3 The Multi-Model Problem

Real enterprise warehouse schemas contain multiple disconnected subject areas.
AdventureWorksDW contains at minimum Internet Sales, Reseller Sales, Finance,
and HR subject areas — each a distinct dimensional model with its own fact
tables and dimension tables.

The standard approach assigns one developer per subject area, each spending
two to five days on the same manual reconstruction problem. The redundancy
scales linearly with the number of subject areas.

`graph_embedding` detects all subject areas simultaneously via connected
component decomposition of the schema graph, and generates independent
deployment-ready semantic models for all of them in a single run.

---

## 3. The Framework

GraphEmbed\_PBI is organized into four sequential layers.

### 3.1 Layer 1 — Metadata Extraction

The warehouse schema is read from the ANSI-standard `INFORMATION_SCHEMA`
interface, scoped to the specified schema:

- `INFORMATION_SCHEMA.TABLES` — table inventory
- `INFORMATION_SCHEMA.COLUMNS` — column names and data types
- `sys.foreign_keys` + `sys.foreign_key_columns` — relationship graph
  (SQL Server; ANSI equivalent: `INFORMATION_SCHEMA.REFERENTIAL_CONSTRAINTS`)

The foreign key graph is constructed:

```
G = (V, E)
V = { table names in schema }
E = { (parent_table, referenced_table) | foreign key constraint exists }
```

Edge attributes include the from-column and to-column for each foreign key,
the relationship name, and the directionality (many-side to one-side).

### 3.2 Layer 2 — Graph Classification via BFS Reachability

Power BI enforces a constraint that the active relationship subgraph must
be a **spanning forest**: acyclic, with at most one active path between any
two vertices. Relationships that would create a second path between an already-
connected pair are permitted in the model but must be classified as inactive.

Before each edge (u, v) is classified, a BFS reachability check determines
whether u and v are already connected in the active subgraph:

```
active_graph = {}

for each foreign key (u, v, fk_name):
    if u == v:
        skip                          # self-referencing: excluded
    if fk_name already seen:
        skip                          # composite FK: deduplicated
    if BFS(active_graph, u) reaches v:
        classify INACTIVE             # ambiguous path: mark inactive
    elif BFS(active_graph, v) reaches u:
        classify INACTIVE
    else:
        classify ACTIVE
        add edge (u, v) to active_graph
```

This incrementally constructs the maximal spanning forest of G. The
classification is equivalent to the cycle detection step in Kruskal's minimum
spanning tree algorithm: edges that would create cycles in the active subgraph
are classified inactive; edges that extend the forest are classified active.

The result is the largest acyclic active relationship subgraph that Power BI's
constraint system permits — the spanning forest of G.

### 3.3 Layer 3 — Connected Component Decomposition

After relationship classification, the schema graph contains N connected
components corresponding to N logical subject areas. Conformed dimensions —
tables shared across subject areas (e.g. `DimDate`) — bridge components and
must be excluded from the partitioning pass to reveal the true logical model
boundaries.

```
conformed_dims = user-specified shared tables

for each table t not in conformed_dims and not yet visited:
    component_i = BFS(active_graph, t, exclude=conformed_dims)
    components.append(component_i)

for each component_i:
    full_component_i = component_i ∪ conformed_dims
```

This is the standard graph-theoretic treatment of shared vertices in
multi-graph partitioning: remove the shared vertices, decompose the residual
graph into connected components, then reattach the shared vertices to each
component.

The result is N table sets, each representing one complete dimensional model,
each containing the conformed dimensions required for time-based analysis.

### 3.4 Layer 4 — Output Translation

Each logical model is translated independently into Power BI's native PBIP
format. The output for each component is a complete PBIP folder:

```
{ModelName}.SemanticModel/
├── model.bim              Tabular Model Scripting Language (TMSL) JSON:
│                          tables, columns, data types, relationships,
│                          M-query partition expressions, data source
├── definition.pbism       semantic model format pointer
├── .platform              Fabric platform metadata with unique logicalId
└── diagramLayout.json     relationship diagram layout

{ModelName}.Report/
└── definition.pbir        report definition referencing the semantic model

{ModelName}.pbip           project pointer — open this in Power BI Desktop
```

Each generated model receives a unique `logicalId` (UUID) in `.platform`,
making it independently addressable as a Fabric workspace artifact.

---

## 4. Mathematical Basis

### 4.1 The Spanning Forest Construction

**Definition.** Let G = (V, E) be the foreign key graph of a warehouse schema.
The *active subgraph* A = (V, E_A) where E_A ⊆ E is the spanning forest of G
constructed by the BFS classification: the maximal acyclic subgraph of G such
that no two edges in E_A create a cycle.

**Observation.** The BFS classification algorithm is equivalent to Kruskal's
MST algorithm on an unweighted graph. Each edge is processed in sequence; an
edge is accepted (classified active) if and only if its endpoints are not yet
connected in the active subgraph. The result is a spanning forest of G.

**Corollary.** The active subgraph A is a spanning forest of G. Every
connected component of A is a tree. There is at most one active path between
any two vertices in A.

This is precisely the constraint Power BI's relationship model enforces:
no two active relationships may create multiple paths between any pair of
tables. The BFS classification guarantees this constraint is satisfied by
construction.

### 4.2 The Injective Homomorphism

**Definition.** The mapping f: G → G' from the warehouse schema graph to the
Power BI semantic model graph defined by GraphEmbed\_PBI is an injective graph
homomorphism:

- *Injectivity:* distinct tables map to distinct semantic model tables —
  f(u) = f(v) ⟹ u = v
- *Homomorphism:* foreign key adjacency maps to relationship adjacency —
  (u, v) ∈ E ⟹ (f(u), f(v)) ∈ E'
- *Spanning forest constraint:* the image f(A) is constrained to be a
  spanning forest of G' by the BFS classification

The composition of the spanning forest construction (Layer 2) and the output
translation (Layer 4) defines this homomorphism explicitly and constructively.

### 4.3 The Component Decomposition

**Definition.** Let A\* = (V \ C, E_A\*) be the active subgraph with conformed
dimensions C removed. The connected components of A\* are the logical model
partitions {M_1, M_2, ..., M_N}. The full logical models are
{M_1 ∪ C, M_2 ∪ C, ..., M_N ∪ C}.

**Observation.** The conformed dimensions C act as articulation vertices in G
— their removal increases the number of connected components. The partitioning
algorithm exploits this property: by excluding C during the BFS decomposition,
the algorithm reveals the N natural subject area boundaries encoded in the
warehouse schema.

---

## 5. Proof of Concept

### 5.1 Schema Design

The POC schema (`poc`) within AdventureWorksDW2022 contains two logical models
and one conformed dimension, designed to validate the full framework:

**Model 1 — Internet Sales (star schema)**

```
FactInternetSales ──→ DimDate        (conformed)
FactInternetSales ──→ DimCustomer
FactInternetSales ──→ DimProduct
FactInternetSales ──→ DimTerritory
```

5 tables, 4 edges, star topology. Validates baseline embedding correctness.
All 4 relationships classified active. No ambiguous paths in a clean star.

**Model 2 — Reseller Sales (snowflake schema)**

```
FactResellerSales ──→ DimDate        (conformed)
FactResellerSales ──→ DimReseller
FactResellerSales ──→ DimEmployee
FactResellerSales ──→ DimProductDetail ──→ DimSubcategory ──→ DimCategory
```

7 tables, 6 edges, three-level snowflake product hierarchy. Validates
multi-hop chain preservation. All 6 relationships classified active.

**Conformed dimension:** `DimDate` — referenced by both fact tables,
excluded during component detection, reinjected into both outputs.

### 5.2 Results

| Metric | Value |
|---|---|
| Tables extracted | 11 |
| Foreign keys read | 10 |
| Relationships classified active | 10 |
| Relationships classified inactive | 0 |
| Logical models detected | 2 |
| PBIP files generated | 2 |
| Conformed dimensions correctly reinjected | 1 (DimDate) |
| Power BI Desktop compatibility | v2.152 (March 2026) — validated |

Both generated PBIP files open in Power BI Desktop with all tables and
relationships pre-wired. No manual intervention required.

### 5.3 SQL Server Specificity

The current POC is validated against SQL Server. This is a deliberate scoping
decision — not a limitation of the framework. The output translation layer
(model.bim generation, PBIP folder structure, BFS classification, component
decomposition) is fully validated and independent of the source database.
Only the extraction layer is SQL Server-specific in the current implementation.

---

## 6. Portability Architecture

### 6.1 What Changes Per Database Backend

The extraction layer is the only component that varies across database backends.
Three contained changes are required per adapter:

| Component | SQL Server | PostgreSQL | Snowflake | Oracle |
|---|---|---|---|---|
| Connection string | SQLNCLI11 provider | psycopg2 / pg8000 | snowflake-connector | cx\_Oracle |
| Relationship query | `sys.foreign_keys` | `INFORMATION_SCHEMA` | `INFORMATION_SCHEMA` | `ALL_CONSTRAINTS` |
| M-query function | `Sql.Database()` | `PostgreSQL.Database()` | `Snowflake.Databases()` | `Oracle.Database()` |
| Data type mapping | SQL Server types | PostgreSQL types | Snowflake types | Oracle types |

The BFS classification, component decomposition, and all PBIP output generation
are **unchanged** across all backends.

### 6.2 What Changes Per BI Platform

The output translation layer is the only component that varies across BI
platforms. The intermediate representation — the classified relationship graph
and component partition — is tool-agnostic. Adding a new output translator
requires implementing one function:

```python
def translate(component_tables, component_relationships, model_name) -> files:
    # write tool-specific output files
```

This is the same connector/adapter pattern used by Power BI and Tableau
natively: each connector is a separate adapter; the engine is unchanged.
GraphEmbed\_PBI applies that pattern in reverse — one warehouse scan, any
number of output translators, all at once.

### 6.3 Scope Boundary

NoSQL systems (MongoDB, DynamoDB, Cassandra) are explicitly out of scope.
They enforce no foreign key constraints, eliminating the signal the extraction
layer depends on. The correct boundary is: **any relational database that
enforces referential integrity is in scope. Document stores are not.**

---

## 7. Infrastructure Extension: Microsoft Fabric

Each generated PBIP file is a first-class Microsoft Fabric artifact —
addressable by its `logicalId`, publishable to a Fabric workspace via the
Fabric REST API, and compatible with Fabric Git integration for CI/CD pipelines.

The natural extension of the current tool is **direct Fabric publishing**:
upon completion of the PBIP generation, the tool calls the Fabric Items API
to deploy each semantic model directly to a specified workspace. The developer
never opens Power BI Desktop — the semantic layer is live in Fabric seconds
after the warehouse scan completes.

This transforms the tool from a local developer productivity aid into an
organizational semantic layer automation pipeline. Combined with CI/CD
triggers on warehouse schema changes, the tool closes the drift gap
permanently: any schema change automatically regenerates and republishes
all affected semantic models, keeping the Fabric workspace synchronized with
the warehouse at all times.

---

## 8. Conclusion

The warehouse schema is a graph. The Power BI semantic model is a graph.
The mapping between them is an injective graph homomorphism, computable from
metadata that already exists, requiring no manual reconstruction.

`graph_embedding` formalizes this mapping, implements it correctly — handling
spanning forest constraints via BFS reachability, identifying logical model
boundaries via connected component decomposition, and managing conformed
dimensions via shared vertex reinjection — and generates deployment-ready
Power BI artifacts for all detected logical models in a single run.

The POC validates the framework on SQL Server against star and snowflake
schemas with a shared conformed dimension. The architecture is designed for
portability: the extraction layer adapts per source database; the output
translation layer adapts per BI platform; the graph classification and
component decomposition core is unchanged across all combinations.

The full manuscript including IP-sensitive derivations is available upon
request.

---

**Contact**  
LinkedIn: https://www.linkedin.com/in/hlzhang/  
GitHub: https://github.com/stevetab03
