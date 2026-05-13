-- ── RESELLER SALES SNOWFLAKE SCHEMA ──
-- Add to existing poc schema alongside Internet Sales star schema

-- ── SNOWFLAKE: Product Category (root) ──
CREATE TABLE poc.DimCategory (
    CategoryKey     INT PRIMARY KEY,
    CategoryName    NVARCHAR(50),
    CategoryCode    NVARCHAR(10)
);

-- ── SNOWFLAKE: Product Subcategory (middle) ──
CREATE TABLE poc.DimSubcategory (
    SubcategoryKey  INT PRIMARY KEY,
    SubcategoryName NVARCHAR(50),
    CategoryKey     INT FOREIGN KEY REFERENCES poc.DimCategory(CategoryKey)
);

-- ── SNOWFLAKE: Product Detail (leaf) ──
CREATE TABLE poc.DimProductDetail (
    ProductDetailKey INT PRIMARY KEY,
    ProductName      NVARCHAR(100),
    SKU              NVARCHAR(50),
    UnitCost         DECIMAL(10,2),
    ListPrice        DECIMAL(10,2),
    SubcategoryKey   INT FOREIGN KEY REFERENCES poc.DimSubcategory(SubcategoryKey)
);

-- ── DIMENSION: Reseller ──
CREATE TABLE poc.DimReseller (
    ResellerKey     INT PRIMARY KEY,
    ResellerName    NVARCHAR(100),
    BusinessType    NVARCHAR(50),
    City            NVARCHAR(50),
    Country         NVARCHAR(50)
);

-- ── DIMENSION: Employee (flat) ──
CREATE TABLE poc.DimEmployee (
    EmployeeKey     INT PRIMARY KEY,
    FirstName       NVARCHAR(50),
    LastName        NVARCHAR(50),
    Title           NVARCHAR(100),
    Region          NVARCHAR(50),
    HireDate        DATE
);

-- ── FACT: Reseller Sales ──
CREATE TABLE poc.FactResellerSales (
    ResellerSalesKey INT PRIMARY KEY,
    DateKey          INT FOREIGN KEY REFERENCES poc.DimDate(DateKey),
    ResellerKey      INT FOREIGN KEY REFERENCES poc.DimReseller(ResellerKey),
    EmployeeKey      INT FOREIGN KEY REFERENCES poc.DimEmployee(EmployeeKey),
    ProductDetailKey INT FOREIGN KEY REFERENCES poc.DimProductDetail(ProductDetailKey),
    OrderQuantity    INT,
    UnitPrice        DECIMAL(10,2),
    TotalAmount      DECIMAL(10,2),
    UnitCost         DECIMAL(10,2),
    GrossMargin      DECIMAL(10,2)
);