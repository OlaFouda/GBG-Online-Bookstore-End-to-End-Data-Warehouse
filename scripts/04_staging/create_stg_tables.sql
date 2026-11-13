
/*
===============================================================================
    Phase B: Staging Layer (STG) - Table Creation
===============================================================================

    Purpose:
        Create the staging schema and tables used to store cleaned and
        standardized data before loading it into the Data Warehouse.

    Tables:
        1. Categories
        2. Promotions
        3. Books
        4. Sales

    Note:
        Existing STG tables are dropped and recreated when this script runs.
        This will remove any data currently stored in these tables.
===============================================================================
*/

USE Bookstore_DWH;
GO


/*=============================================================================
    Step 1: Create STG Schema
=============================================================================*/

IF SCHEMA_ID(N'stg') IS NULL
BEGIN
    EXEC(N'CREATE SCHEMA stg;');
END;
GO


/*=============================================================================
    Step 2: Create STG Tables
=============================================================================*/


/*-----------------------------------------------------------------------------
    2.1 Categories
-----------------------------------------------------------------------------*/

IF OBJECT_ID(N'stg.Categories', N'U') IS NOT NULL
    DROP TABLE stg.Categories;
GO

CREATE TABLE stg.Categories
(
    CategoryID   INT            NOT NULL PRIMARY KEY,
    CategoryName NVARCHAR(100)  NULL,
    Description  NVARCHAR(250)  NULL
);
GO


/*-----------------------------------------------------------------------------
    2.2 Promotions
-----------------------------------------------------------------------------*/

IF OBJECT_ID(N'stg.Promotions', N'U') IS NOT NULL
    DROP TABLE stg.Promotions;
GO

CREATE TABLE stg.Promotions
(
    PromotionID     INT            NOT NULL PRIMARY KEY,
    PromotionCode   NVARCHAR(30)   NULL,
    PromotionName   NVARCHAR(120)  NULL,
    DiscountPercent DECIMAL(5,2)   NULL
);
GO


/*-----------------------------------------------------------------------------
    2.3 Books
-----------------------------------------------------------------------------*/

IF OBJECT_ID(N'stg.Books', N'U') IS NOT NULL
    DROP TABLE stg.Books;
GO

CREATE TABLE stg.Books
(
    BookID     INT            NOT NULL PRIMARY KEY,
    ISBN       NVARCHAR(20)   NULL,
    BookTitle  NVARCHAR(150)  NULL,
    CategoryID INT            NOT NULL,
    Price      DECIMAL(10,2)  NULL
);
GO


/*-----------------------------------------------------------------------------
    2.4 Sales
-----------------------------------------------------------------------------*/

IF OBJECT_ID(N'stg.Sales', N'U') IS NOT NULL
    DROP TABLE stg.Sales;
GO

CREATE TABLE stg.Sales
(
    SalesLineID    INT            NOT NULL PRIMARY KEY,
    SaleID         INT            NOT NULL,
    ReceiptNumber  NVARCHAR(30)   NOT NULL,
    LineNumber     INT            NOT NULL,
    BookID         INT            NOT NULL,
    SaleDate       DATE           NULL,
    PaymentMethod  NVARCHAR(50)   NULL,
    Quantity       INT            NULL,
    UnitPrice      DECIMAL(10,2)  NULL,
    DiscountAmount DECIMAL(10,2)  NULL,
    PromotionIDs   NVARCHAR(100)  NULL,
    PromotionStatus NVARCHAR(30)  NULL
);
GO
