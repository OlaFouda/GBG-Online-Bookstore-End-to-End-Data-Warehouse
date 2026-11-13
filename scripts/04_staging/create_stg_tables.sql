
/*
===============================================================================
    Phase B: Staging Layer (STG)
===============================================================================

    Purpose:
        Create the staging schema and tables used to store cleaned,
        standardized, and analysis-ready data.

    Responsibilities:
        - Define the staging table structures.
        - Apply data cleaning and transformations during the loading process.

    Steps:
        1. Create the STG schema.
        2. Create the STG tables.

    Note:
        Data loading and transformation logic is implemented separately
        in the staging stored procedure.
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
    PromotionBenefitID INT            NOT NULL,
    PromotionID        INT            NOT NULL,
    PromotionCode      NVARCHAR(30)   NOT NULL,
    PromotionName      NVARCHAR(120)  NOT NULL,
    BenefitCode        NVARCHAR(30)   NOT NULL,
    BenefitName        NVARCHAR(120)  NOT NULL,
    DiscountPercent    DECIMAL(5,2)   NOT NULL,

    CONSTRAINT PK_stg_Promotions
        PRIMARY KEY (PromotionBenefitID)
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
    PromotionID    INT            NULL
);
GO
