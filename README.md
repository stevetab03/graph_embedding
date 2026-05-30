# graph_embedding: Graph Embedding for BI Semantic Layer Generation

[![Python 3.11+](https://img.shields.io/badge/python-3.11+-blue.svg)](https://www.python.org/downloads/)
[![Methods: ANSI Schema · BFS · Connected Components · Injective Homomorphism](https://img.shields.io/badge/Methods-ANSI_Schema_%7C_BFS_%7C_Connected_Components_%7C_Injective_Homomorphism-blueviolet)](https://github.com/stevetab03/graph_embedding)
[![Domain: BI Semantic Layer Automation](https://img.shields.io/badge/Domain-BI_Semantic_Layer_Automation-success)](https://github.com/stevetab03/graph_embedding)
[![Target: Power BI · Microsoft Fabric](https://img.shields.io/badge/Target-Power_BI_%7C_Microsoft_Fabric-F2C811?logo=powerbi&logoColor=black)](https://github.com/stevetab03/graph_embedding)
[![Status: Active Development](https://img.shields.io/badge/Status-Active_Development-orange)](https://github.com/stevetab03/graph_embedding)

**Author:** Liyuan (Steve) Zhang  
**Status:** Active Research & Development — v0.2 Multi-Model · SQL Server → Power BI PBIP · Roadmap: Fabric Publishing · Additional Databases · Tableau · Alteryx

*Source code is provided as-is for portfolio and research purposes. The architectural framework, graph embedding formulation, BFS relationship classification, and connected component logical model detection represent original applied work by the author.*

---

## Motivation

Enterprise data warehouses contain multiple logical subject areas — Internet Sales, Reseller Sales, Finance, HR — each a distinct dimensional model with its own fact tables, dimension tables, and foreign key relationships. These subject areas are encoded in the warehouse schema as disconnected subgraphs of the foreign key graph.

Today, each subject area requires a BI developer to manually build a separate Power BI semantic model from a blank canvas — importing tables, drawing relationships, guessing at cardinality. In a typical enterprise warehouse with three to five subject areas, this consumes two to five developer-days per subject area. The result is N manually-built semantic models that immediately begin to drift from the warehouse they were built from.

> *Every schema already contains the complete definition of every logical model it supports. The question is why those definitions are ever rebuilt by hand.*

`graph_embedding` detects all logical models in a schema automatically — via connected component analysis of the foreign key graph — and generates deployment-ready Power BI semantic models for each one simultaneously. One schema scan. N governed semantic models. Each ready to publish directly to Microsoft Fabric.

---

## The Problem with the Standard Approach

The relational schema of any warehouse is a directed graph: tables are vertices, foreign key constraints are edges. The Power BI semantic model is also a directed graph: tables are vertices, relationships are edges. The mapping from one to the other is a well-defined mathematical object — an **injective graph homomorphism** — that preserves vertices, preserves adjacency, and maps edge attributes (foreign key columns) to relationship properties (from/to columns, active/inactive state).

This mapping is currently performed manually by every BI developer on every project, introducing three classes of failure:

- **Structural errors** — relationships drawn in the wrong direction, cardinality misspecified
- **Coverage gaps** — tables missed, relationships omitted
- **Drift** — the manually-built semantic layer diverges from the warehouse over time as schema changes are not propagated

All three failures are eliminated when the mapping is computed rather than drawn. At the organizational level, automating this mapping across all logical models in a schema eliminates the redundant rebuild tax entirely — and produces governed, version-controlled semantic model artifacts ready for Fabric deployment.

---

## The Framework

`graph_embedding` computes the injective graph homomorphism from the warehouse foreign key graph to Power BI semantic model graphs automatically, with full logical model partitioning.

### Layer 1 — Metadata Extraction

The warehouse schema is read from the ANSI-standard `INFORMATION_SCHEMA` interface — tables, columns, data types, and foreign key relationships, scoped to the specified schema. This layer is database-agnostic: any relational database exposing the ANSI standard is a valid source.

The foreign key graph G = (V, E) is constructed where:
- V = { table names }
- E = { (parent\_table, referenced\_table) | foreign key constraint exists }

### Layer 2 — Graph Classification via BFS Reachability

Power BI enforces a constraint that no two active relationships may create multiple paths between any pair of tables. Formally, the active relationship subgraph must be a **spanning forest** — acyclic, with at most one active path between any two vertices.

Before each edge is classified as active, a Breadth-First Search reachability check determines whether the two vertices are already connected in the active subgraph:

```
for each foreign key (u, v):
    if BFS(active_graph, u) reaches v  →  mark INACTIVE
    else                               →  mark ACTIVE, add edge to active_graph
```

This incrementally constructs the maximal spanning forest of the foreign key graph. Self-referencing edges (parent-child hierarchies) and composite FK duplicates are excluded. The result is the largest valid active relationship subgraph Power BI's constraint system permits.

### Layer 3 — Connected Component Detection

Real warehouse schemas contain multiple disconnected subject areas. After relationship classification, a second BFS pass — executed on the active graph with conformed dimensions temporarily removed — identifies the connected components of the schema graph. Each component is a logical model boundary.

```
for each non-conformed table not yet visited:
    BFS(active_graph, table, exclude=conformed_dims)
    → component = all reachable tables
```

Conformed dimensions (e.g. DimDate shared across subject areas) are added back into every component after detection. The result is N logically isolated table sets, each representing one complete dimensional model.

### Layer 4 — Output Translation

Each detected logical model is translated into Power BI's native PBIP format independently: `model.bim`, `definition.pbism`, `.platform` (with unique `logicalId` per model), `diagramLayout.json`, `definition.pbir`, and the `.pbip` project pointer. Each PBIP file opens independently in Power BI Desktop with only its subject area's tables and relationships pre-wired.

N logical models in the schema → N deployment-ready PBIP files generated in a single run.

---

## Mathematical Basis

The active relationship classification is equivalent to building a **spanning forest** of the foreign key graph. The BFS reachability check is the connectivity oracle that determines, for each candidate edge (u, v), whether u and v are already in the same connected component of the active subgraph — structurally identical to the cycle detection step in Kruskal's minimum spanning tree algorithm.

The logical model partitioning is a **connected component decomposition** of the active relationship graph, with conformed dimensions treated as shared vertices excluded from the partitioning pass and reinjected into each component post-detection. This is the standard graph-theoretic treatment of shared vertices in multi-graph partitioning problems.

The full mapping — from warehouse schema graph to N Power BI semantic model graphs — is an **injective graph homomorphism** where the image is partitioned into N spanning forests, one per detected logical model, each independently valid under Power BI's relationship constraint system.

---

## Current Implementation: GraphEmbed\_PBI v0.2

The current implementation targets **SQL Server** as source and **Power BI PBIP** as output, with full multi-model detection. Full documentation in [`GraphEmbed_PBI/README.md`](GraphEmbed_PBI/README.md).

```bash
cd GraphEmbed_PBI
pip install -r requirements.txt
python graphembed_pbi.py
```

```
=== GraphEmbed_PBI v0.2 ===
Server   [default: localhost]:
Database (data model name)  : AdventureWorksDW2022
Schema   [default: dbo]: poc
Output name [default: same as database]: poc

Tables in schema: DimCategory, DimCustomer, DimDate, DimEmployee...
Conformed dimensions (comma-separated, or Enter to skip): DimDate

Logical models detected: 2
  Model 1 [FactInternetSales]: DimCustomer, DimDate, DimProduct, DimTerritory, FactInternetSales
  Model 2 [FactResellerSales]: DimCategory, DimDate, DimEmployee, DimProductDetail, DimReseller, DimSubcategory, FactResellerSales
```

**Output:** N deployment-ready PBIP files — one per detected logical model, each independently openable in Power BI Desktop with only its subject area's tables and relationships pre-wired. Each model carries a unique `logicalId` for Fabric workspace deployment.

---

## Proof of Concept

Validated against a two-model schema in SQL Server under a dedicated `poc` schema within AdventureWorksDW2022:

**Model 1 — Internet Sales (star schema):** 5 tables, 4 active relationships, clean star topology. All 4 relationships classified active with zero ambiguous paths.

**Model 2 — Reseller Sales (snowflake schema):** 7 tables, 6 active relationships, three-level product hierarchy (`FactResellerSales → DimProductDetail → DimSubcategory → DimCategory`). Snowflake chain correctly classified with all relationships active.

**Conformed dimension:** `DimDate` — shared across both models, correctly identified as a bridge vertex and injected into both PBIP outputs post-component-detection.

**Total:** 2 PBIP files generated in a single run from 11 tables and 10 foreign key constraints. Both open independently in Power BI Desktop March 2026 (v2.152) with no manual wiring required.

Full POC DDL and instructions: [`examples/poc_star_schema/`](examples/poc_star_schema/)

---

## Repository Structure

```
graph_embedding/
├── README.md
├── LICENSE                            MIT
├── ROADMAP.md                         development roadmap
│
├── GraphEmbed_PBI/
│   ├── graphembed_pbi.py              main script — SQL Server → Power BI PBIP (multi-model)
│   ├── requirements.txt               pyodbc
│   └── README.md                      usage, configuration, supported databases
│
├── docs/
│   ├── technical_paper.md             graph embedding formulation — full technical depth
│   └── business_case.md               non-technical whitepaper — productivity and governance
│
└── examples/
    └── poc_star_schema/
        ├── create_schema.sql          DDL — Internet Sales (star) + Reseller Sales (snowflake)
        └── README.md                  step-by-step POC walkthrough
```

---

## Status

| Component | Status |
|---|---|
| SQL Server metadata extraction (ANSI INFORMATION\_SCHEMA) | Complete |
| BFS relationship classification — spanning forest | Complete |
| Self-referencing exclusion (parent-child hierarchies) | Complete |
| Composite FK deduplication | Complete |
| Power BI PBIP output — model.bim + all required files | Complete |
| Schema-scoped extraction | Complete |
| Interactive CLI (server / database / schema / output) | Complete |
| Connected component detection — logical model partitioning | Complete |
| Conformed dimension handling — shared vertex reinjection | Complete |
| Multi-model output — N PBIP files per schema scan | Complete |
| POC validation — star schema (Internet Sales) | Complete |
| POC validation — snowflake schema (Reseller Sales) | Complete |
| POC validation — conformed dimension (DimDate) across both models | Complete |
| TMDL output format (replaces model.bim) | Roadmap v0.3 |
| PostgreSQL adapter | Roadmap v0.4 |
| Snowflake adapter | Roadmap v0.4 |
| Oracle adapter | Roadmap v0.4 |
| Amazon Redshift adapter | Roadmap v0.4 |
| Tableau .tds output translator | Roadmap v0.5 |
| Alteryx workflow scaffold output | Roadmap v0.5 |
| Microsoft Fabric direct publishing via REST API | Roadmap v0.6 |
| CI/CD pipeline trigger support | Roadmap v0.6 |
| UI layer | Roadmap v0.6 |

---

## Connection to Other Work

[ARCM](https://github.com/stevetab03/ARCM) and [ORBIT](https://github.com/stevetab03/ORBIT) apply rigorous mathematical frameworks to quantitative finance problems. `graph_embedding` applies the same intellectual register to enterprise data infrastructure — formalizing a problem the industry has treated as manual workflow, identifying the correct mathematical objects (injective graph homomorphism, connected component decomposition), and building a working implementation.

The shared principle: *problems that appear to be operational are often structural. Structural problems have precise solutions.*

---

## Documentation

- **Technical paper** — full framework, BFS reachability, injective homomorphism, portability across database backends and BI platforms: [`docs/technical_paper.md`](docs/technical_paper.md)
- **Business case** — productivity, data governance, Fabric deployment, non-technical overview: [`docs/business_case.md`](docs/business_case.md)
- **Monograph** — available upon request for full mathematical derivations

---

## Contact

**LinkedIn:** https://www.linkedin.com/in/hlzhang/  
**GitHub:** https://github.com/stevetab03
