-- ============================================================
-- GraphEmbed_PBI — POC Star Schema
-- Author: Liyuan Zhang
-- github.com/stevetab03/graph_embedding
--
-- Prerequisites: AdventureWorksDW2022 restored in SQL Server
-- Execute this script against AdventureWorksDW2022
-- then run graphembed_pbi.py with schema: poc
-- 
-- Run this script, create_schema_star, first for schema creation
-- Run create_schema_snowflake next for an additional logical model
--
-- ============================================================

CREATE SCHEMA poc;
GO

-- Dimension Table: Date
CREATE TABLE poc.DimDate (
    DateKey INT PRIMARY KEY,
    FullDate DATE,
    Year INT,
    Quarter INT,
    Month INT,
    MonthName VARCHAR(20),
    WeekDay VARCHAR(20)
);

-- Dimension Table: Customer
CREATE TABLE poc.DimCustomer (
    CustomerKey INT PRIMARY KEY,
    FirstName NVARCHAR(50),
    LastName NVARCHAR(50),
    Email NVARCHAR(100),
    City NVARCHAR(50),
    Country NVARCHAR(50)
);

-- Dimension Table: Product
CREATE TABLE poc.DimProduct (
    ProductKey INT PRIMARY KEY,
    ProductName NVARCHAR(100),
    Category NVARCHAR(50),
    Subcategory NVARCHAR(50),
    UnitCost DECIMAL(10,2)
);

-- Dimension Table: Territory
CREATE TABLE poc.DimTerritory (
    TerritoryKey INT PRIMARY KEY,
    Region NVARCHAR(50),
    Country NVARCHAR(50),
    Continent NVARCHAR(50)
);

-- Fact Table: Internet Sales
CREATE TABLE poc.FactInternetSales (
    SalesOrderKey INT PRIMARY KEY,
    DateKey INT FOREIGN KEY REFERENCES poc.DimDate(DateKey),
    CustomerKey INT FOREIGN KEY REFERENCES poc.DimCustomer(CustomerKey),
    ProductKey INT FOREIGN KEY REFERENCES poc.DimProduct(ProductKey),
    TerritoryKey INT FOREIGN KEY REFERENCES poc.DimTerritory(TerritoryKey),
    Quantity INT,
    UnitPrice DECIMAL(10,2),
    TotalAmount DECIMAL(10,2)
);
