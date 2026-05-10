# graph_embedding: Graph Embedding for BI Semantic Layer Generation

[![Python 3.11+](https://img.shields.io/badge/python-3.11+-blue.svg)](https://www.python.org/downloads/)
[![Methods: ANSI Schema · BFS · Injective Homomorphism](https://img.shields.io/badge/Methods-ANSI_Schema_%7C_BFS_%7C_Injective_Homomorphism-blueviolet)](https://github.com/stevetab03/graph_embedding)
[![Domain: BI Semantic Layer Automation](https://img.shields.io/badge/Domain-BI_Semantic_Layer_Automation-success)](https://github.com/stevetab03/graph_embedding)
[![Target: Power BI PBIP](https://img.shields.io/badge/Target-Power_BI_PBIP-F2C811?logo=powerbi&logoColor=black)](https://github.com/stevetab03/graph_embedding)
[![Status: Active Development](https://img.shields.io/badge/Status-Active_Development-orange)](https://github.com/stevetab03/graph_embedding)

**Author:** Liyuan Zhang  
**Status:** Active Research & Development — v0.1 Power BI (SQL Server) · Roadmap: PostgreSQL · Snowflake · Oracle · Tableau

*Source code is provided as-is for portfolio and research purposes. The architectural framework, graph embedding formulation, and BFS relationship classification algorithm represent original applied work by the author.*

---

## Motivation

Every Power BI implementation begins with the same avoidable failure. A dimensional model already exists in the warehouse — tables defined, foreign keys enforced, grain documented, hierarchies established. The structural intelligence of the data is fully encoded.

Then a BI developer opens Power BI Desktop and starts over from a blank canvas.

They import every table manually. They draw every relationship by hand. They guess at cardinality. They get join directions wrong. In a typical enterprise implementation this consumes two to five days of skilled developer time — for work that adds zero analytical value. Worse: when the warehouse changes, the Power BI semantic layer does not update automatically. Definition drift accumulates silently until a report is wrong and nobody knows why.

> *The warehouse and the semantic layer are two representations of the same graph. The question is why the second is ever built by hand when the first already exists.*

`graph_embedding` is the answer to that question.

---

## The Problem with the Standard Approach

The relational schema of any warehouse is a directed graph: tables are vertices, foreign key constraints are edges. The Power BI semantic model is also a directed graph: tables are vertices, relationships are edges. The mapping from one to the other is a well-defined mathematical object — an **injective graph homomorphism** — that preserves vertices, preserves adjacency, and maps edge attributes (foreign key columns) to relationship properties (from/to columns, active/inactive state).

This mapping is currently performed manually by every BI developer on every project, introducing three classes of failure:

- **Structural errors** — relationships drawn in the wrong direction, cardinality misspecified
- **Coverage gaps** — tables missed, relationships omitted
- **Drift** — the manually-built semantic layer diverges from the warehouse over time as schema changes are not propagated

All three failures are eliminated when the mapping is computed rather than drawn.

---

## The Framework

`graph_embedding` computes the injective graph homomorphism from the warehouse foreign key graph to the Power BI semantic model graph automatically.

### Layer 1 — Metadata Extraction

The warehouse schema is read from the ANSI-standard `INFORMATION_SCHEMA` interface — tables, columns, data types, and foreign key relationships. This layer is database-agnostic: any relational database exposing the ANSI standard is a valid source.

The foreign key graph G = (V, E) is constructed where:
- V = { table names }
- E = { (parent\_table, referenced\_table) | foreign key constraint exists }

### Layer 2 — Graph Classification via BFS Reachability

Power BI enforces a constraint that no two active relationships may create multiple paths between any pair of tables. Formally, the active relationship subgraph must be a **spanning forest** — acyclic, with at most one active path between any two vertices.

Before each edge is classified as active, a Breadth-First Search reachability check determines whether the two vertices are already connected in the active subgraph:

```
for each foreign key (u, v):
    if BFS(active_graph, u) reaches v → mark INACTIVE
    else → mark ACTIVE, add edge to active_graph
```

This incrementally constructs the maximal spanning forest of the foreign key graph, classifying edges that would create cycles as inactive relationships. Self-referencing edges (parent-child hierarchies) are excluded entirely as Power BI does not support them as native relationships.

### Layer 3 — Output Translation

The classified graph is translated into Power BI's native PBIP format: `model.bim` (the Tabular Model Definition Language JSON), `definition.pbism`, `.platform`, `diagramLayout.json`, `definition.pbir`, and the `.pbip` project pointer. The developer opens one file and finds a pre-wired semantic model.

---

## Mathematical Basis

The active relationship classification is equivalent to building a **spanning forest** of the foreign key graph. The BFS reachability check is the connectivity oracle that determines, for each candidate edge (u, v), whether u and v are already in the same connected component of the active subgraph.

This is structurally identical to the cycle detection step in Kruskal's minimum spanning tree algorithm — edges that would create cycles are rejected (marked inactive), edges that extend the forest are accepted (marked active). The result is the largest acyclic subgraph of the foreign key graph that Power BI's constraint system permits.

The mapping from warehouse schema graph to Power BI semantic model graph is an **injective graph homomorphism**: distinct tables map to distinct model tables (injectivity), foreign key adjacency maps to relationship adjacency (homomorphism), and the image is constrained to a spanning forest by the BFS classification step.

---

## Current Implementation: GraphEmbed\_PBI

The current implementation targets **SQL Server** as source and **Power BI PBIP** as output. Full documentation in [`GraphEmbed_PBI/README.md`](GraphEmbed_PBI/README.md).

```bash
cd GraphEmbed_PBI
pip install -r requirements.txt
python graphembed_pbi.py
```

```
=== GraphEmbed_PBI ===
Server   [default: localhost]:
Database (data model name)  : AdventureWorksDW2022
Schema   [default: dbo]: poc
Output name [default: same as database]: InternetSales_POC
```

**Output:** A deployment-ready PBIP folder. Open `{Output}.pbip` in Power BI Desktop — all tables and relationships are pre-wired.

---

## Proof of Concept

Validated against a clean 5-table star schema (1 fact, 4 dimensions) in SQL Server under a dedicated `poc` schema within AdventureWorksDW2022. The tool correctly:

- Extracted all 5 tables and their column definitions
- Read all 4 foreign key relationships
- Classified all 4 as active (no ambiguous paths in a clean star schema)
- Generated a valid PBIP folder that opens in Power BI Desktop March 2026 (v2.152)

Full POC DDL and instructions: [`examples/poc_star_schema/`](examples/poc_star_schema/)

---

## Repository Structure

```
graph_embedding/
├── README.md
├── LICENSE
├── ROADMAP.md                   development roadmap
│
├── GraphEmbed_PBI/
│   ├── graphembed_pbi.py        main script maps SQL Server to Power BI
│   ├── requirements.txt
│   └── README.md
│
├── docs/
│   ├── technical_paper.md       graph embedding framework — technical depth
│   └── business_case.md         non-technical whitepaper — productivity and governance
│
└── examples/
    └── poc_star_schema/
        ├── create_schema.sql    DDL to recreate the POC star schema
        └── README.md            step-by-step POC walkthrough
```

---

## Status

| Component | Status |
|---|---|
| SQL Server metadata extraction | Complete |
| BFS relationship classification | Complete |
| Self-referencing exclusion | Complete |
| Composite FK deduplication | Complete |
| Power BI PBIP output (model.bim + all required files) | Complete |
| Schema-scoped extraction | Complete |
| Interactive CLI (server / database / schema / output) | Complete |
| POC validation — SQL Server + AdventureWorksDW2022 | Complete |
| PostgreSQL adapter | Roadmap v0.2 |
| Snowflake adapter | Roadmap v0.2 |
| Oracle adapter | Roadmap v0.2 |
| Tableau .tds output translator | Roadmap v0.3 |
| Alteryx workflow scaffold output | Roadmap v0.3 |
| Microsoft Fabric direct publishing | Roadmap v0.4 |
| UI layer | Roadmap v0.4 |

---

## Connection to Other Work

[ARCM](https://github.com/stevetab03/ARCM) and [ORBIT](https://github.com/stevetab03/ORBIT) apply rigorous mathematical frameworks to quantitative finance problems. `graph_embedding` applies the same intellectual register to enterprise data infrastructure — formalizing a problem that the industry has treated as manual workflow, identifying the correct mathematical object (injective graph homomorphism), and building a working implementation.

The shared principle: *problems that appear to be operational are often structural. Structural problems have precise solutions.*

---

## Documentation

- **Technical paper** — graph embedding formulation, BFS reachability, injective homomorphism, portability architecture: [`docs/technical_paper.md`](docs/technical_paper.md)
- **Business case** — productivity, data governance, non-technical overview: [`docs/business_case.md`](docs/business_case.md)
- **Monograph** — available upon request for full mathematical derivations

---

## Contact

**LinkedIn:** https://www.linkedin.com/in/hlzhang/  
**GitHub:** https://github.com/stevetab03
