`graph_embedding` is built around a clean architectural separation between the
extraction layer (reading warehouse metadata) and the output translation layer
(generating BI tool artifacts). Each version either deepens the extraction
layer, adds an output translator, or extends the infrastructure.

---

## v0.1 — SQL Server → Power BI PBIP (Single Model)
*Complete*

- ANSI `INFORMATION_SCHEMA` metadata extraction (SQL Server)
- BFS relationship classification — active/inactive spanning forest
- Self-referencing exclusion (parent-child hierarchies)
- Composite FK deduplication
- Power BI PBIP output: `model.bim`, `definition.pbism`, `.platform`,
  `diagramLayout.json`, `definition.pbir`, `.pbip`
- Schema-scoped extraction
- Interactive CLI (server / database / schema / output)
- POC validation: 5-table star schema, SQL Server 2025, Power BI Desktop v2.152

---

## v0.2 — Multi-Model Detection and Output
*Complete*

- Connected component detection via BFS on active relationship graph
- Logical model partitioning — N subject areas detected from one schema scan
- Conformed dimension handling — shared vertex reinjection across components
- N independent PBIP files generated per run, one per logical model
- Unique `logicalId` per generated semantic model (Fabric-ready)
- POC validation: Internet Sales (star) + Reseller Sales (snowflake),
  shared DimDate conformed dimension, SQL Server 2025

---

## v0.3 — TMDL Output Format
*Roadmap*

Replace monolithic `model.bim` (TMSL) with TMDL folder structure:
{Model}.SemanticModel/
└── definition/
├── database.tmdl
├── relationships.tmdl
└── tables/
├── FactInternetSales.tmdl
├── DimDate.tmdl
└── ...

- One `.tmdl` file per table — human-readable, Git-diffable
- Relationships in dedicated `relationships.tmdl`
- Compatible with Fabric Git integration and VS Code TMDL extension
- Text-template based generation (no .NET/TOM dependency)
- Upgrade path: existing `model.bim` outputs remain valid in parallel

---

## v0.4 — Database Adapter Layer
*Roadmap*

Extend extraction layer to additional warehouse backends.
The BFS classification, component detection, and PBIP output are unchanged —
only the connection string, M-query function, and type mapping change per adapter.

| Backend | Metadata Source | M-Query Function |
|---|---|---|
| PostgreSQL | ANSI `INFORMATION_SCHEMA` | `PostgreSQL.Database()` |
| Snowflake | ANSI `INFORMATION_SCHEMA` | `Snowflake.Databases()` |
| Amazon Redshift | ANSI `INFORMATION_SCHEMA` | `AmazonRedshift.Database()` |
| Oracle | `ALL_CONSTRAINTS` / `ALL_CONS_COLUMNS` | `Oracle.Database()` |
| Azure SQL | ANSI `INFORMATION_SCHEMA` | `Sql.Database()` (same as SQL Server) |

> **Scope note:** NoSQL systems (MongoDB, DynamoDB, Cassandra) are out of scope.
> They enforce no foreign key constraints, eliminating the signal the extraction
> layer depends on.

---

## v0.5 — BI Platform Adapter Layer
*Roadmap*

Add output translators for additional BI platforms.
The extraction core and component detection are unchanged —
only the output format changes per translator.

- **Tableau** — `.tds` data source file generation
- **Alteryx** — workflow input scaffold generation

Each translator consumes the same intermediate graph representation
produced by v0.4 extraction adapters, making the combination
(any source × any BI target) a matter of adapter selection.

---

## v0.6 — Infrastructure
*Roadmap*

- **Microsoft Fabric direct publishing** — deploy generated semantic models
  to Fabric workspaces via REST API; bypass Power BI Desktop entirely
- **CI/CD pipeline trigger** — schema change in warehouse triggers
  `graph_embedding` run, updates all logical models, publishes to Fabric
  automatically; closes the warehouse-to-semantic-layer drift gap permanently
- **UI layer** — web-based interface for database/schema selection,
  conformed dimension tagging, model preview, and output configuration;
  eliminates CLI dependency for non-developer users

---

## Architectural Principle

The extraction layer and output translation layer are independently variable.
Any source database can feed any output translator without changes to the
graph classification or component detection core. This is the same
connector/adapter pattern used by Power BI and Tableau natively —
each connector is a separate adapter; the engine is unchanged.

`graph_embedding` applies that principle to semantic layer generation:
one warehouse scan, any number of BI tools, all logical models, all at once.
