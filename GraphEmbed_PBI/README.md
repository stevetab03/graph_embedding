# GraphEmbed\_PBI

**Source:** SQL Server (any schema, any database)  
**Output:** Power BI PBIP — deployment-ready semantic model  
**Part of:** [graph\_embedding](https://github.com/stevetab03/graph_embedding)

---

## What This Does

Reads the complete dimensional model from a SQL Server database — tables, columns, data types, and foreign key relationships — and generates a valid Power BI PBIP folder with all relationships pre-wired and correctly classified as active or inactive.

The developer opens the generated `.pbip` file in Power BI Desktop and finds a fully structured semantic model. No manual table import. No relationship drawing. No guesswork.

---

## Requirements

```
pyodbc
```

```bash
pip install -r requirements.txt
```

**Prerequisites:**
- ODBC Driver 17 for SQL Server installed ([download](https://learn.microsoft.com/en-us/sql/connect/odbc/download-odbc-driver-for-sql-server))
- Power BI Desktop (March 2026 / v2.152+ validated)
- SQL Server with Windows Authentication (Trusted Connection)

---

## Usage

```bash
python graphembed_pbi.py
```

```
=== GraphEmbed_PBI ===
Server   [default: localhost]:
Database (data model name)  : YourDatabase
Schema   [default: dbo]: your_schema
Output name [default: same as database]: YourOutputName
```

**Prompts:**

| Prompt | Default | Description |
|---|---|---|
| Server | localhost | SQL Server instance name or address |
| Database | required | Database name — treated as the data model identifier |
| Schema | dbo | Schema to scope extraction — all tables from this schema only |
| Output name | same as database | Controls the PBIP folder and file names |

---

## Output Structure

```
output/
├── {OutputName}.pbip                        ← open this in Power BI Desktop
├── {OutputName}.SemanticModel/
│   ├── model.bim                            ← tables, columns, relationships (TMDL JSON)
│   ├── definition.pbism                     ← semantic model definition pointer
│   ├── .platform                            ← Fabric platform metadata
│   └── diagramLayout.json                   ← relationship diagram layout
└── {OutputName}.Report/
    └── definition.pbir                      ← report definition pointing to semantic model
```

---

## Relationship Classification

The tool applies **BFS reachability** to classify each foreign key relationship as active or inactive before writing `model.bim`. Power BI requires that no two active relationships create multiple paths between any pair of tables — the active subgraph must be a spanning forest.

Three categories of relationships are handled automatically:

| Case | Handling |
|---|---|
| Self-referencing FK (parent-child hierarchy) | Excluded — Power BI does not support self-joins |
| Composite FK (multi-column) | Deduplicated — first column retained, duplicates skipped |
| Ambiguous path (two routes between same tables) | Second relationship marked inactive |

---

## Supported Databases

| Database | Status | Notes |
|---|---|---|
| SQL Server 2019+ | Supported | Validated — SQL Server 2025 Developer Edition |
| Azure SQL | Compatible | Same driver, connection string update required |
| PostgreSQL | Roadmap v0.2 | Requires ANSI REFERENTIAL\_CONSTRAINTS adapter |
| Snowflake | Roadmap v0.2 | Requires Snowflake connector adapter |
| Oracle | Roadmap v0.2 | Requires ALL\_CONSTRAINTS adapter (non-ANSI) |
| Amazon Redshift | Roadmap v0.2 | ANSI compliant, M-query update required |

---

## What Changes Per Database Backend

The extraction and output layers are independently variable. Adding a new database requires changes to three contained components only:

1. **Connection string** — provider and authentication syntax per backend
2. **Power Query (M) function** — `Sql.Database()` becomes `Snowflake.Databases()`, `PostgreSQL.Database()`, etc.
3. **Data type mapping** — each database has its own type vocabulary; the mapping to Power BI's internal types changes per source

The BFS classification, model.bim assembly, PBIP folder structure, and all file writing logic are **unchanged across all backends**.

---

## Example Run

See [`examples/poc_star_schema/`](../examples/poc_star_schema/) for a complete walkthrough including DDL to create a clean 5-table star schema and expected output.
