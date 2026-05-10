A White Paper on

**Graph Embedding**

> *An Application of Injective Graph Homomorphism to Data-Warehouse-to-Semantic-Layer Translation*

Liyuan (Steve) Zhang ▪ github.com/stevetab03/graph_embedding\
\
\
***Abstract***

> *GraphEmbed_PBI addresses a structural inefficiency present in every Power BI implementation: the manual reconstruction of a dimensional model that already exists in the data warehouse. By modeling the data warehouse schema as a directed graph and applying an injective graph homomorphism to the Power BI semantic layer, the tool eliminates redundant development effort, enforces data governance through a single source of truth, and generates a deployment-ready semantic model instantly. The proof-of-concept is validated on SQL Server. The extraction layer is architected for portability across any ANSI-compliant relational database.*

**THE PROBLEM\
\
**Every time a BI developer starts a new Power BI project, he spends days doing work that should take minutes. The data is already in the data warehouse with all relationships defined and documented. But Power BI has no way to fetch that structure automatically. So the developer rebuilds it manually: importing every table, drawing every relationship, making sure nothing is connected wrong.

This happens on every project, at every company, with every BI tool. It is repetitive, error-prone, and adds no analytical value. Worse, when the data warehouse changes, the Power BI model does not update automatically, thereby creating a growing gap between the actual data and what reports show. This is a data governance failure hiding in plain sight.

The typical cost is 2--5 days of skilled developer time per project, repeated every time a new report or data mart is built --- and ongoing maintenance cost every time the underlying data model changes.\
\
**THE SOLUTION\
\
**GraphEmbed_PBI is an open-source Python program that reads the data structure directly from any relational database and automatically generates a ready-to-use Power BI project file (.pbip) that contains tables, columns, and relationships already wired together correctly.

The developer runs one command, answers three prompts (server, database, output name), and receives a .pbip file they can open immediately. No manual table import. No relationship drawing. No guesswork. The semantic layer is built from the single source of truth --- the data warehouse itself.

What GraphEmbed_PBI delivers:

-   **Productivity ---** Eliminates days of manual setup on every project. Developers go straight to building reports and writing business logic from day one.

-   **Data Governance ---** The semantic layer inherits its structure directly from the data warehouse. One source of truth. No inconsistency between what the data says and what reports show.

-   **Reproducibility ---** Any developer on any team can bootstrap a correctly structured model in a matter of seconds. No knowledge required.

-   **Extensibility ---** The tool is architected with a clean separation between reading the database and generating the output file. Adding support for additional databases or BI tools is a contained change because the core logic does not move.

-   **Future-ready ---** A next step is publishing to Microsoft Fabric workspaces, making the bootstrapped model immediately available to the entire organization without manual file handling.

**HOW IT WORKS\
**\
Every relational database, e.g., SQL Server, PostgreSQL, Snowflake, Oracle, Redshift, stores its metadata in a standard location. Table names, column names, data types, and the relationships between tables are all readable by any tool that knows where to look.

GraphEmbed_PBI fetches that metadata, translates it into the format Power BI understands, and writes the result to disk as a valid Power BI project. When the developer opens it, the data model is already built.

The proof-of-concept is validated against SQL Server. Extending to other databases requires changing only the connection method and type translation --- the same pattern used by every BI connector on the market. Power BI itself has separate connectors for SQL Server, Snowflake, Oracle, and dozens of others; each connector is a different adapter feeding the same engine. GraphEmbed_PBI is the same idea applied to model generation.

**The Mathematical Framing**

The data warehouse schema is modeled as a directed graph: tables are nodes, foreign key constraints are directed edges. The Power BI semantic model is a second graph with identical structure requirements. GraphEmbed_PBI computes an injective graph homomorphism from the data warehouse graph to the Power BI graph which is a structure-preserving map where distinct tables remain distinct and adjacency relationships are preserved.

Power BI enforces an additional constraint such that no two active relationships may create multiple paths between any pair of tables (ambiguous path detection). The tool enforces this by maintaining an active relationship graph and running a breadth-first search reachability check before marking each relationship active. Relationships that would create ambiguous paths are marked inactive, thereby preserving the full structural information while satisfying Power BI\'s acyclicity requirement on active edges. The result is a simplified, cleaned-up map of the data warehouse: connected, acyclic in the active subgraph, and isomorphic to the maximal path-unambiguous subgraph of the original. It connects all necessary areas without creating any circular loops, removing redundant paths while keeping the most direct routes intact.

**What Changes Per Database. What Does Not.**

The extraction layer is source-specific. Three things change per backend: the connection string format, the Power Query (M) function that connects Power BI to the source, and the data type vocabulary mapping. These are contained, well-defined adapter changes --- the same pattern BI tool vendors use for their own connector libraries.

The output translation layer does not change. The model.bim assembly, the Power BI project folder structure, the BFS relationship classification, the self-referencing exclusion, and the composite key deduplication are all backend-independent. Oracle requires its own extraction adapter using ALL_CONSTRAINTS rather than INFORMATION_SCHEMA. NoSQL systems with no referential integrity constraints are out of scope for the current work.\
\
**WHY DID STEVE BUILD IT\
**\
GraphEmbed_PBI was not built as a portfolio exercise. It was built by someone who spent a decade deploying Power BI solutions in production across upstream oil and gas, LNG operations, and financial services. It is someone who recognized the redundant rebuild problem as solvable only because he had lived its cost on every project.

Most BI professionals accept the manual rebuild as a given. Recognizing it as an unnecessary structural failure, and having the technical range to solve it, requires a specific combination of skills.

**Domain Depth**

-   **10+ years** of production Power BI deployments across energy and financial services --- ExxonMobil, Cheniere Energy, Hilcorp, and GCM Grosvenor.

-   **Kimball methodology** expertise --- the industry gold standard for dimensional modeling that the tool is built to serve.

-   **Power BI internals** production experience with Power BI\'s GitHub-compatible project format from enterprise deployments, which made generating valid .pbip output possible where others would have had to guess.

**Technical Foundation**

-   **Mathematics ---** Dual BS in Applied Mathematics and Nuclear Engineering; MS in Mathematical and Computational Finance; currently completing a second MS in Mathematics (Measure Theory, Applied Analysis, Graph Theory, Combinatory Logic) at Emporia State University.

-   **Independent research ---** Production quantitative models in stochastic calculus, yield curve analytics, and options microstructure, surfaced in live Power BI dashboards backed by real market data.

-   **Engineering breadth ---** Python, SQL, Alteryx, SSIS, cloud data platforms, and full-stack BI deployment from warehouse to report.

A decade of production BI work provides the domain knowledge to know what correct output looks like. A rigorous mathematics background provides the tools to solve the structural problems the domain work surfaces. GraphEmbed_PBI is evidence of both working in synergy.\
\
**STRATEGIC RECOMMENDATIONS\
**\
Every organization running Power BI is paying the redundant rebuild tax on every project. GraphEmbed_PBI eliminates the manual overhead by tapping into the matadata native to the data warehouse and feeding it straight to the BI layer.

GraphEmbed_PBI is open source, documented, and working. It is not a concept or a prototype. It is a proof, built by someone who understood the problem from the inside and had the skills and bandwidth (a short intermission) to solve it. Hire Steve.
