# POC: Multi-Model Schema Walkthrough

A complete end-to-end example of `GraphEmbed_PBI v0.2` validating the full
graph embedding framework — connected component detection, conformed dimension
handling, and multi-model PBIP output — against two logical models in a single
SQL Server schema.

**Schema:** `poc`  
**Database:** AdventureWorksDW2022 (or any SQL Server database)  
**Logical models:** 2 — Internet Sales (star) + Reseller Sales (snowflake)  
**Conformed dimension:** `DimDate` — shared across both models  
**Total tables:** 11 · **Total foreign keys:** 10 · **Output:** 2 PBIP files

---

## Schema Design

The `poc` schema contains two disconnected subject areas deliberately chosen
to validate the full capability of the framework.

### Model 1 — Internet Sales (Star Schema)

A clean star schema — one central fact table connected directly to four
dimension tables. No snowflake normalization. No ambiguous paths. All
relationships active. The simplest valid dimensional model and the baseline
proof that the embedding is correct.

| Table | Type | Description |
|---|---|---|
| `poc.FactInternetSales` | Fact | Sales transactions |
| `poc.DimDate` | Dimension (conformed) | Date spine — shared with Reseller Sales |
| `poc.DimCustomer` | Dimension | Customer attributes |
| `poc.DimProduct` | Dimension | Product (flat — category and subcategory as columns) |
| `poc.DimTerritory` | Dimension | Geographic hierarchy |

**Foreign key graph — Internet Sales:**

```
FactInternetSales ──→ DimDate        (DateKey)
FactInternetSales ──→ DimCustomer    (CustomerKey)
FactInternetSales ──→ DimProduct     (ProductKey)
FactInternetSales ──→ DimTerritory   (TerritoryKey)
```

4 edges · 4 active · 0 inactive · Clean spanning tree.

---

### Model 2 — Reseller Sales (Snowflake Schema)

A three-level snowflake product hierarchy — the product dimension is normalized
into separate tables rather than collapsed into a single flat dimension. This
tests the framework's handling of multi-hop relationship chains and validates
that the BFS classification correctly preserves all edges in a snowflake
topology.

| Table | Type | Description |
|---|---|---|
| `poc.FactResellerSales` | Fact | Reseller sales transactions |
| `poc.DimDate` | Dimension (conformed) | Date spine — shared with Internet Sales |
| `poc.DimReseller` | Dimension | Reseller attributes |
| `poc.DimEmployee` | Dimension | Sales employee (flat) |
| `poc.DimProductDetail` | Dimension (snowflake leaf) | SKU-level product detail |
| `poc.DimSubcategory` | Dimension (snowflake middle) | Product subcategory |
| `poc.DimCategory` | Dimension (snowflake root) | Product category |

**Foreign key graph — Reseller Sales:**

```
FactResellerSales ──→ DimDate           (DateKey)
FactResellerSales ──→ DimReseller       (ResellerKey)
FactResellerSales ──→ DimEmployee       (EmployeeKey)
FactResellerSales ──→ DimProductDetail  (ProductDetailKey)
DimProductDetail  ──→ DimSubcategory    (SubcategoryKey)
DimSubcategory    ──→ DimCategory       (CategoryKey)
```

6 edges · 6 active · 0 inactive · Three-level snowflake chain preserved intact.

---

### Conformed Dimension — DimDate

`DimDate` is referenced by both `FactInternetSales` and `FactResellerSales`.
It is the canonical Kimball conformed dimension — one date table shared across
all subject areas.

Without conformed dimension handling, `DimDate` bridges the two disconnected
clusters into one connected component, causing both subject areas to be
detected as a single logical model. The connected component detection excludes
`DimDate` during partitioning, correctly identifying the two independent
clusters, then reinjects `DimDate` into both component outputs.

---

## Step 1 — Create the Schema

Run `create_schema.sql` in SSMS against your target database.

The script creates the `poc` schema and all 11 tables with foreign key
constraints enforced at the database engine level — the signal the extraction
layer reads.

Verify the schema created correctly:

```sql
SELECT TABLE_NAME
FROM INFORMATION_SCHEMA.TABLES
WHERE TABLE_SCHEMA = 'poc'
ORDER BY TABLE_NAME;
-- Expected: 11 rows
```

Verify the foreign keys:

```sql
SELECT
    fk.name        AS fk_name,
    tp.name        AS parent_table,
    tr.name        AS referenced_table
FROM sys.foreign_keys fk
JOIN sys.tables  tp ON fk.parent_object_id  = tp.object_id
JOIN sys.tables  tr ON fk.referenced_object_id = tr.object_id
JOIN sys.schemas sp ON tp.schema_id = sp.schema_id
WHERE sp.name = 'poc'
ORDER BY tp.name;
-- Expected: 10 rows
```

---

## Step 2 — Run GraphEmbed\_PBI v0.2

```bash
cd GraphEmbed_PBI
python graphembed_pbi.py
```

```
=== GraphEmbed_PBI v0.2 ===
Server   [default: localhost]:
Database (data model name)  : AdventureWorksDW2022
Schema   [default: dbo]: poc
Output name [default: same as database]: poc

Tables in schema: DimCategory, DimCustomer, DimDate, DimEmployee,
DimProduct, DimProductDetail, DimReseller, DimSubcategory,
DimTerritory, FactInternetSales, FactResellerSales

Conformed dimensions (comma-separated, or Enter to skip): DimDate
Conformed dimensions: DimDate
```

Expected terminal output:

```
Tables found: 11
Columns found: 64
Relationships found: 10

Relationships: 10 total, 10 active, 0 inactive

Logical models detected: 2
  Model 1 [FactInternetSales]: DimCustomer, DimProduct, DimTerritory, FactInternetSales
  Model 2 [FactResellerSales]: DimCategory, DimEmployee, DimProductDetail, DimReseller, DimSubcategory, FactResellerSales
  Conformed dimensions (shared): DimDate

Generating PBIP files...

  [poc_FactInternetSales]
    Tables: 5  |  Relationships: 4
    Open: output/poc_FactInternetSales.pbip

  [poc_FactResellerSales]
    Tables: 7  |  Relationships: 6
    Open: output/poc_FactResellerSales.pbip

──────────────────────────────────────────────────
Schema  : poc
Database: AdventureWorksDW2022
Models generated: 2
Conformed dimensions: DimDate
```

---

## Step 3 — Open in Power BI Desktop

**Model 1:** Open `output/poc_FactInternetSales.pbip`

Model view shows 5 tables — `FactInternetSales` connected to `DimDate`,
`DimCustomer`, `DimProduct`, `DimTerritory`. Clean star topology. All 4
relationships pre-wired and active.

**Model 2:** Open `output/poc_FactResellerSales.pbip`

Model view shows 7 tables — `FactResellerSales` connected to `DimDate`,
`DimReseller`, `DimEmployee`, and `DimProductDetail`. `DimProductDetail`
connected to `DimSubcategory`. `DimSubcategory` connected to `DimCategory`.
Full snowflake chain pre-wired. All 6 relationships active.

Both files open independently. Neither contains tables from the other's
subject area. `DimDate` appears correctly in both.

---

## What This Validates

| Capability | Validated By |
|---|---|
| Star schema extraction and embedding | Internet Sales — 4-table star, all active |
| Snowflake schema extraction and embedding | Reseller Sales — 3-level product chain, all active |
| BFS active/inactive classification | 10 FKs processed, 10 active, 0 ambiguous paths |
| Connected component detection | 2 logical models correctly partitioned from 11-table schema |
| Conformed dimension handling | DimDate excluded from partitioning, reinjected into both outputs |
| Multi-model PBIP output | 2 independent PBIP files, unique `logicalId` per model |
| Power BI Desktop compatibility | Both PBIP files open in Power BI Desktop March 2026 (v2.152) |

---

## Why Two Models, Not One

Power BI does not support multiple independent semantic models within a single
`.pbip` file — each semantic model is a governed, independently deployable
artifact. The two generated PBIP files are the correct enterprise pattern:
separate subject areas as separate semantic models, each publishable
independently to a Microsoft Fabric workspace, each available for composite
model consumption by reports that need to span subject areas.

The alternative — one model with all 11 tables — produces an ungoverned
monolith where Internet Sales and Reseller Sales share a single semantic
layer with no logical boundary. That is what the manual approach produces.
This tool produces governed separation by default.

---

## Files

```
examples/poc_star_schema/
├── create_schema.sql          DDL — both logical models + conformed dimension
└── README.md
```
