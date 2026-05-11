# POC: Star Schema Walkthrough

A complete end-to-end example of `GraphEmbed_PBI` against a minimal, clean 5-table star schema. This is the reference proof-of-concept validating the graph embedding framework on SQL Server.

**Schema:** `poc`  
**Database:** AdventureWorksDW2022 (or any SQL Server database)  
**Tables:** 1 fact, 4 dimensions  
**Relationships:** 4 foreign keys — all active, no ambiguous paths

---

## Step 1 — Create the Star Schema

Run `create_schema.sql` in SSMS against your target database:

```sql
CREATE SCHEMA poc;
GO
```

This creates a clean Internet Sales star schema under the `poc` schema with properly enforced foreign key constraints. The schema is intentionally minimal — one subject area, no snowflake complexity, no self-referencing dimensions — to provide a clear baseline demonstration of the embedding.

**Tables created:**

| Table | Type | Rows (sample) |
|---|---|---|
| poc.DimDate | Dimension | Date spine |
| poc.DimCustomer | Dimension | Customer attributes |
| poc.DimProduct | Dimension | Product hierarchy |
| poc.DimTerritory | Dimension | Geographic hierarchy |
| poc.FactInternetSales | Fact | Sales transactions |

**Foreign keys (edges in the warehouse graph):**

| FK | Parent Table | Referenced Table |
|---|---|---|
| FK\_FactInternetSales\_Date | poc.FactInternetSales | poc.DimDate |
| FK\_FactInternetSales\_Customer | poc.FactInternetSales | poc.DimCustomer |
| FK\_FactInternetSales\_Product | poc.FactInternetSales | poc.DimProduct |
| FK\_FactInternetSales\_Territory | poc.FactInternetSales | poc.DimTerritory |

A clean star schema produces no ambiguous paths — all 4 relationships are classified active. This is the expected behaviour for a properly designed dimensional model.

---

## Step 2 — Run GraphEmbed\_PBI

```bash
cd GraphEmbed_PBI
python graphembed_pbi.py
```

```
=== GraphEmbed_PBI ===
Server   [default: localhost]:
Database (data model name)  : AdventureWorksDW2022
Schema   [default: dbo]: poc
Output name [default: same as database]: InternetSales_POC
```

**Expected terminal output:**

```
Tables found: 5
Columns found: 28
Relationships found: 4

Relationships: 4 total, 4 active, 0 inactive

Files generated:
  InternetSales_POC.SemanticModel/model.bim
  InternetSales_POC.SemanticModel/definition.pbism
  InternetSales_POC.SemanticModel/.platform
  InternetSales_POC.SemanticModel/diagramLayout.json
  InternetSales_POC.Report/definition.pbir
  InternetSales_POC.pbip

Tables: 5  |  Relationships: 4
```

---

## Step 3 — Open in Power BI Desktop

Open `output/InternetSales_POC.pbip` in Power BI Desktop.

The Model view shows all 5 tables with all 4 relationships pre-wired — FactInternetSales connected to each dimension on the correct key columns. No manual wiring required.

---

## Why This Matters

A developer starting from a blank Power BI file would spend 30–60 minutes importing these 5 tables and drawing these 4 relationships manually — and would likely get at least one relationship direction wrong on the first attempt.

GraphEmbed\_PBI produces the same result in under 10 seconds.

For a production warehouse with 30+ tables and 40+ relationships (AdventureWorksDW2022 full schema), the manual process takes 2–5 days. The embedding produces it in the same 10 seconds.

---

## Files

```
examples/poc_star_schema/
├── create_schema.sql
└── README.md
```
