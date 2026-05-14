# Graph Embedding for Automated Semantic Layer Generation in Power BI

> *Productivity, Data Governance, and Schema-Scale Automation*

**Liyuan Zhang**  
github.com/stevetab03/graph_embedding

---

## Abstract

GraphEmbed\_PBI addresses a structural inefficiency present in every Power BI
implementation: the manual reconstruction of dimensional models that already
exist in the data warehouse. By modeling the warehouse schema as a directed
graph and applying an injective graph homomorphism to the Power BI semantic
layer, the tool eliminates redundant development effort, enforces data
governance through a single source of truth, and generates deployment-ready
semantic models for all detected logical subject areas simultaneously.
The proof-of-concept is validated on SQL Server. The extraction layer is
architected for portability across any ANSI-compliant relational database.

---

## The Problem

Every time a BI developer starts a new Power BI project, days are spent doing
work that should take minutes. The data is already in the warehouse — tables
defined, foreign keys enforced, relationships documented. Power BI has no way
to read that structure automatically. So the developer rebuilds it by hand:
importing every table, drawing every relationship, making sure nothing is
connected incorrectly.

This happens on every project, at every company, with every BI tool. It is
repetitive, error-prone, and adds zero analytical value. Worse, when the
warehouse changes, the Power BI model does not update automatically —
creating a growing gap between the actual data and what reports show. This is
a data governance failure hiding in plain sight.

**The typical cost:** 2–5 days of skilled developer time per subject area,
repeated every time a new data mart is built — and ongoing maintenance cost
every time the underlying schema changes.

Enterprise warehouses contain multiple subject areas — Internet Sales, Reseller
Sales, Finance, HR. Each subject area requires the same manual reconstruction.
The cost scales linearly with the number of logical models in the schema.

---

## The Solution

GraphEmbed\_PBI is an open-source Python tool that reads the data structure
directly from any relational database and automatically generates
deployment-ready Power BI project files — one per detected logical model —
with tables, columns, and relationships already wired together correctly.

The developer runs one command, answers four prompts (server, database, schema,
conformed dimensions), and receives N Power BI PBIP files — one per subject
area detected in the schema. No manual table import. No relationship drawing.
No guesswork. The semantic layer is built directly from the single source of
truth: the warehouse itself.

**What GraphEmbed\_PBI delivers:**

- **Productivity** — Eliminates days of manual setup per subject area. One
  schema scan generates all logical models simultaneously. Developers go
  straight to building reports and writing business logic.

- **Data Governance** — The semantic layer inherits its structure directly
  from the warehouse. One source of truth. No drift between what the data
  says and what reports show.

- **Schema-Scale Automation** — Connected component detection partitions
  the schema graph into N logical models automatically. An enterprise schema
  with three subject areas produces three governed semantic models in a
  single run.

- **Reproducibility** — Any developer on any team can bootstrap a correctly
  structured model set in seconds. No tribal knowledge required.

- **Fabric-Ready** — Each generated PBIP file carries a unique identifier
  making it independently publishable to a Microsoft Fabric workspace. The
  roadmap includes direct Fabric publishing via REST API, closing the
  warehouse-to-analytics-platform pipeline entirely.

- **Extensibility** — The extraction layer and output translation layer are
  independently variable. Adding a new database backend or BI platform is a
  contained adapter change. The core graph classification and component
  detection logic does not move.

---

## How It Works

Every relational database — SQL Server, PostgreSQL, Snowflake, Oracle,
Redshift — stores a description of its own structure in a standard location.
Table names, column names, data types, and the relationships between tables
are all readable by any tool that knows where to look.

GraphEmbed\_PBI reads that metadata, identifies all logical subject areas
in the schema via connected component analysis of the foreign key graph,
and generates a separate pre-wired Power BI project for each one. When the
developer opens a generated file, the model is already built.

**The multi-model detection step** is what separates this tool from a simple
import helper. Real enterprise schemas contain multiple disconnected subject
areas. The tool detects these boundaries automatically by removing shared
conformed dimensions (tables like `DimDate` that span subject areas), finding
the connected components of the residual graph, and reinserting the shared
dimensions into every component output. Each subject area becomes its own
governed, independently deployable semantic model.

**The connector analogy.** Extending to additional databases requires changing
only the connection method and type translation — the same pattern used by
every BI connector on the market. Power BI has separate connectors for SQL
Server, Snowflake, Oracle, and dozens of others; each connector is a different
adapter feeding the same engine. GraphEmbed\_PBI applies that architecture to
model generation: one core, multiple source adapters, multiple output
translators.

---

## Why Two Models, Not One

Power BI does not support multiple independent semantic models within a single
project file — each model is a governed, independently deployable artifact by
design. The N generated PBIP files are the correct enterprise pattern: separate
subject areas as separate semantic models, each publishable to a Microsoft
Fabric workspace, each available for composite model consumption by reports
that need to span subject areas.

The alternative — one model containing all tables — produces an ungoverned
monolith where subject area boundaries are invisible, governance is impossible,
and every developer sees every table regardless of their domain. That is what
the manual approach produces by default. GraphEmbed\_PBI produces governed
separation automatically.

---

## About the Author

GraphEmbed\_PBI was not built as a portfolio exercise. It was built by someone
who spent a decade deploying Power BI in production across upstream oil and
gas, LNG operations, and financial services — and who recognized the redundant
rebuild problem as solvable only because they had lived its cost on every
project.

Most BI practitioners accept the manual rebuild as a given. Recognizing it as
an unnecessary structural failure, and having the technical range to solve it,
requires a specific combination of skills that is genuinely rare.

**Domain depth:**

- 10+ years of production Power BI deployments — ExxonMobil, Cheniere Energy,
  Hilcorp, GCM Grosvenor
- Kimball methodology expertise — the industry standard for dimensional
  modeling that the tool is built to serve
- Production experience with Power BI's PBIP format from enterprise deployments,
  which made generating valid output possible where others would have had to guess

**Technical foundation:**

- Dual BS in Applied Mathematics and Nuclear Engineering from Purdue University
- MS in Mathematical and Computational Finance from NJIT
- Currently completing a second MS in Mathematics (Measure Theory, Applied
  Analysis, Advanced Calculus) at Emporia State University
- Independent quantitative research: production stochastic models in yield
  curve analytics and options microstructure, surfaced in live Power BI
  dashboards backed by real market data
- Engineering breadth: Python, SQL across six database platforms, Alteryx,
  SSIS, cloud data platforms, full-stack BI deployment from warehouse to report

A decade of production BI work provides the domain knowledge to know what
correct output looks like. A rigorous mathematics background provides the
tools to solve the structural problems the domain work surfaces.
GraphEmbed\_PBI is evidence of both working together.

---

## The Bottom Line

Every organization running Power BI is paying the redundant rebuild tax on
every project, multiplied across every subject area in the schema.
GraphEmbed\_PBI eliminates it — not by adding complexity, but by reading what
the warehouse already knows and delivering it directly to the semantic layer,
for all logical models, all at once.

The tool is open source, documented, and working. It is not a concept or a
prototype. It is a proof.

**github.com/stevetab03/graph_embedding**

---

**Contact**  
LinkedIn: https://www.linkedin.com/in/hlzhang/  
GitHub: https://github.com/stevetab03
