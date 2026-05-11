import pyodbc, json, os
from collections import defaultdict, deque

# Input
print("=== PBIP Bootstrap ===")
SERVER   = input("Server   [default: localhost]: ").strip() or "localhost"
DATABASE = input("Database (data model name)  : ").strip()
if not DATABASE:
    raise ValueError("Database name is required.")
SCHEMA   = input("Schema   [default: dbo]: ").strip() or "dbo"
OUTPUT   = input("Output name [default: same as database]: ").strip() or DATABASE

# Connection
conn = pyodbc.connect(
    f"Driver={{ODBC Driver 17 for SQL Server}};"
    f"Server={SERVER};"
    f"Database={DATABASE};"
    f"Trusted_Connection=yes;"
    f"TrustServerCertificate=yes;"
)
cursor = conn.cursor()

#########################################
#                                     	#
#     Contact me for my source code     #
#                                     	#
# Step 1: Tables	       		#
# Step 2: Columns	       		#
# Step 3: Relationships			#
# Datatype mapping	      		#
# Build columns	       			#
# Build tables	       			#
# Build relationships	       		#
# Build model.bim	       		#
# Output path	       			#
# Write model.bim	       		#
# Write definition.pbism	       	#
# Write .platform	       		#
# Write diagramLayout.json	       	#
# Write definition.pbir	       		#
# Write .pbip	       			#
#					#
#########################################

print(f"\nFiles generated:")
print(f"  {OUTPUT}.SemanticModel/model.bim")
print(f"  {OUTPUT}.SemanticModel/definition.pbism")
print(f"  {OUTPUT}.SemanticModel/.platform")
print(f"  {OUTPUT}.SemanticModel/diagramLayout.json")
print(f"  {OUTPUT}.Report/definition.pbir")
print(f"  {OUTPUT}.pbip")
print(f"\nOpen: {os.path.join(base_dir, OUTPUT + '.pbip')}")
print(f"Tables: {len(bim_tables)}  |  Relationships: {len(bim_relationships)}")

"""
Server   [default: localhost]:
Database (data model name)  : AdventureWorksDW2022
Schema   [default: dbo]: poc
Output name [default: same as database]: InternetSales_POC
"""
