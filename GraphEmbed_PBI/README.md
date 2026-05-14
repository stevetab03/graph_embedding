# GraphEmbed\_PBI

**Source:** SQL Server (any schema, any database)  
**Output:** Power BI PBIP — N deployment-ready semantic models, one per logical model  
**Version:** 0.2  
**Part of:** [graph\_embedding](https://github.com/stevetab03/graph_embedding)

---

## What This Does

Reads the complete schema from a SQL Server database — tables, columns, data
types, and foreign key relationships — detects all logical subject areas via
connected component analysis of the foreign key graph, and generates an
independent Power BI PBIP folder for each one.

Each generated PBIP file opens in Power BI Desktop with only its subject
area's tables and relationships pre-wired. No manual table import. No
relationship drawing. No guesswork. No monolith containing every table in
the schema.

---

## Requirements

```
pyodbc
```

```bash
pip install -r requirements.txt
```

**Prerequisites:**

- ODBC Driver 17 for SQL Server ([download](https://learn.microsoft.com/en-us/sql/connect/odbc/download-odbc-driver-for-sql-server))
- Power BI Desktop March 2026 / v2.152+ (validated)
- SQL Server with Windows Authentication (Trusted Connection)

---

## Usage

```bash
python graphembed_pbi.py
```

```
=== GraphEmbed_PBI v0.2 ===
Server   [default: localhost]:
Database (data model name)  : YourDatabase
Schema   [default: dbo]: your_schema
Output name [default: same as database]: YourOutputName

Tables in schema: DimCategory, DimCustomer, DimDate, DimEmployee, ...

Conformed dimensions (comma-separated, or Enter to skip): DimDate
```

**Prompts:**

| Prompt | Default | Description |
|---|---|---|
| Server | localhost | SQL Server instance name or address |
| Database | required | Database name — treated as the data model identifier |
| Schema | dbo | Schema to scope extraction — all tables from this schema only |
| Output name | same as database | Prefix for all generated PBIP folder and file names |
| Conformed dimensions | none | Tables shared across subject areas (e.g. DimDate) — reinjected into all models post-detection |

---

## Output Structure

One PBIP folder per detected logical model:

```
output/
├── {OutputName}_{Model1}.pbip
├── {OutputName}_{Model1}.SemanticModel/
│   ├── model.bim                tables, columns, relationships (TMSL JSON)
│   ├── definition.pbism         semantic model format pointer
│   ├── .platform                Fabric platform metadata — unique logicalId per model
│   └── diagramLayout.json       relationship diagram layout
├── {OutputName}_{Model1}.Report/
│   └── definition.pbir          report definition referencing this semantic model
│
├── {OutputName}_{Model2}.pbip
├── {OutputName}_{Model2}.SemanticModel/
│   └── ...
└── {OutputName}_{Model2}.Report/
    └── ...
```

Each model is named after its primary fact table. Each `.platform` file
receives a unique `logicalId` (UUID) making each model independently
addressable as a Microsoft Fabric workspace artifact.

---

## Relationship Classification

The tool applies **BFS reachability** to classify each foreign key relationship
as active or inactive. Power BI requires that the active relationship subgraph
be a spanning forest — no two active relationships may create multiple paths
between any pair of tables.

Three cases are handled automatically:

| Case | Handling |
|---|---|
| Self-referencing FK (parent-child hierarchy) | Excluded — Power BI does not support self-joins as native relationships |
| Composite FK (multi-column foreign key) | Deduplicated — first column retained, duplicates skipped |
| Ambiguous path (two routes between same tables) | Second relationship marked inactive |

---

## Connected Component Detection

After relationship classification, a second BFS pass identifies the connected
components of the active relationship graph — the logical subject area
boundaries. Conformed dimensions are temporarily excluded during partitioning
to prevent them from bridging independent subject areas into a single component.

```
for each non-conformed table not yet visited:
    BFS(active_graph, table, exclude=conformed_dims)
    → component = all reachable tables

for each component:
    full_component = component ∪ conformed_dims
    → generate PBIP
```

The result is N table sets, each representing one complete dimensional model,
each containing the shared conformed dimensions.

---

## Supported Databases

| Database | Status | Notes |
|---|---|---|
| SQL Server 2019+ | Supported | Validated — SQL Server 2025 Developer Edition |
| Azure SQL | Compatible | Same driver, connection string update required |
| PostgreSQL | Roadmap v0.4 | Requires ANSI `REFERENTIAL_CONSTRAINTS` adapter |
| Snowflake | Roadmap v0.4 | Requires Snowflake connector adapter |
| Oracle | Roadmap v0.4 | Requires `ALL_CONSTRAINTS` adapter (non-ANSI) |
| Amazon Redshift | Roadmap v0.4 | ANSI compliant, M-query update required |

---

## What Changes Per Database Backend

The extraction and output layers are independently variable. Adding a new
database requires changes to three contained components only:

1. **Connection string** — provider and authentication syntax per backend
2. **Power Query (M) function** — `Sql.Database()` becomes `Snowflake.Databases()`, `PostgreSQL.Database()`, `Oracle.Database()`, etc.
3. **Data type mapping** — each database has its own type vocabulary; the mapping to Power BI's internal types changes per source

The BFS classification, connected component detection, model.bim assembly,
PBIP folder structure, and all file writing logic are **unchanged across
all backends**.

---

## Example Run

See [`examples/poc_star_schema/`](../examples/poc_star_schema/) for a complete
walkthrough including DDL to recreate the two-model POC schema (Internet Sales
star + Reseller Sales snowflake, shared DimDate) and full expected output.
