
/*
===============================================================================
    Data Warehouse Layer (DWH)
===============================================================================

    Purpose:
        Create the dimensional model for the Bookstore Data Warehouse.

    Data Model:
        - 5 Dimension Tables:
            1. DimCategory
            2. DimBook
            3. DimPromotion
            4. DimDate
            5. DimPaymentMethod

        - 1 Fact Table:
            6. FactSales

        - 1 Bridge Table:
            7. BridgeSalesPromotion

    Design:
        - Star schema with a bridge table to handle the many-to-many
          relationship between sales and promotion benefits.
        - Surrogate keys use the _SK suffix.
        - Date_SK is stored in YYYYMMDD format.
===============================================================================
*/

USE Bookstore_DWH;
GO


/*=============================================================================
    Step 1: Create DWH Schema
=============================================================================*/

IF SCHEMA_ID(N'dwh') IS NULL
BEGIN
    EXEC(N'CREATE SCHEMA dwh;');
END;
GO


/*=============================================================================
    Step 2: Drop Existing Tables
=============================================================================*/

-- Drop dependent tables first to avoid foreign key conflicts.

IF OBJECT_ID(N'dwh.BridgeSalesPromotion', N'U') IS NOT NULL
    DROP TABLE dwh.BridgeSalesPromotion;
GO

IF OBJECT_ID(N'dwh.FactSales', N'U') IS NOT NULL
    DROP TABLE dwh.FactSales;
GO

IF OBJECT_ID(N'dwh.DimBook', N'U') IS NOT NULL
    DROP TABLE dwh.DimBook;
GO

IF OBJECT_ID(N'dwh.DimPromotion', N'U') IS NOT NULL
    DROP TABLE dwh.DimPromotion;
GO

IF OBJECT_ID(N'dwh.DimPaymentMethod', N'U') IS NOT NULL
    DROP TABLE dwh.DimPaymentMethod;
GO

IF OBJECT_ID(N'dwh.DimCategory', N'U') IS NOT NULL
    DROP TABLE dwh.DimCategory;
GO

IF OBJECT_ID(N'dwh.DimDate', N'U') IS NOT NULL
    DROP TABLE dwh.DimDate;
GO


/*=============================================================================
    Step 3: Create Dimension Tables
=============================================================================*/


/*-----------------------------------------------------------------------------
    3.1 DimCategory
-----------------------------------------------------------------------------*/

CREATE TABLE dwh.DimCategory
(
    Category_SK  INT IDENTITY(1,1) NOT NULL,
    CategoryID   INT NOT NULL,
    CategoryName NVARCHAR(100) NULL,
    Description  NVARCHAR(250) NULL,

    CONSTRAINT PK_DimCategory
        PRIMARY KEY (Category_SK),

    CONSTRAINT UQ_DimCategory_CategoryID
        UNIQUE (CategoryID)
);
GO


/*-----------------------------------------------------------------------------
    3.2 DimDate
-----------------------------------------------------------------------------*/

CREATE TABLE dwh.DimDate
(
    Date_SK       INT NOT NULL,
    FullDate      DATE NOT NULL,
    DayNumber     TINYINT NOT NULL,
    DayName       NVARCHAR(15) NOT NULL,
    WeekNumber    TINYINT NOT NULL,
    MonthNumber   TINYINT NOT NULL,
    MonthName     NVARCHAR(15) NOT NULL,
    QuarterNumber TINYINT NOT NULL,
    YearNumber    SMALLINT NOT NULL,

    CONSTRAINT PK_DimDate
        PRIMARY KEY (Date_SK),

    CONSTRAINT UQ_DimDate_FullDate
        UNIQUE (FullDate)
);
GO


/*-----------------------------------------------------------------------------
    3.3 DimBook
-----------------------------------------------------------------------------*/

CREATE TABLE dwh.DimBook
(
    Book_SK      INT IDENTITY(1,1) NOT NULL,
    BookID       INT NOT NULL,
    ISBN         NVARCHAR(20) NULL,
    BookTitle    NVARCHAR(150) NULL,
    Category_SK  INT NULL,
    CurrentPrice DECIMAL(10,2) NULL,

    CONSTRAINT PK_DimBook
        PRIMARY KEY (Book_SK),

    CONSTRAINT UQ_DimBook_BookID
        UNIQUE (BookID),

    CONSTRAINT FK_DimBook_DimCategory
        FOREIGN KEY (Category_SK)
        REFERENCES dwh.DimCategory(Category_SK)
);
GO


/*-----------------------------------------------------------------------------
    3.4 DimPromotion

    Grain:
        One row per promotion benefit.
-----------------------------------------------------------------------------*/

CREATE TABLE dwh.DimPromotion (
    Promotion_SK INT IDENTITY(1,1) PRIMARY KEY,
    PromotionID INT NOT NULL,
    PromotionCode NVARCHAR(30),
    PromotionName NVARCHAR(120),
    DiscountPercent DECIMAL(5,2)
);


/*-----------------------------------------------------------------------------
    3.5 DimPaymentMethod
-----------------------------------------------------------------------------*/

CREATE TABLE dwh.DimPaymentMethod
(
    PaymentMethod_SK INT IDENTITY(1,1) NOT NULL,
    PaymentMethod    NVARCHAR(50) NOT NULL,

    CONSTRAINT PK_DimPaymentMethod
        PRIMARY KEY (PaymentMethod_SK),

    CONSTRAINT UQ_DimPaymentMethod_PaymentMethod
        UNIQUE (PaymentMethod)
);
GO


/*=============================================================================
    Step 4: Create Fact Table
=============================================================================*/

/*-----------------------------------------------------------------------------
    4.1 FactSales

    Grain:
        One record per unique sales line.

    Measures:
        Quantity, UnitPrice, GrossAmount, DiscountAmount, NetAmount.

    Dimension References:
        Book_SK, Date_SK, PaymentMethod_SK.
-----------------------------------------------------------------------------*/

CREATE TABLE dwh.FactSales
(
    Sales_SK       INT IDENTITY(1,1) NOT NULL,

    SalesLineID    INT NOT NULL,
    SaleID         INT NOT NULL,
    ReceiptNumber  NVARCHAR(30) NOT NULL,
    LineNumber     INT NOT NULL,

    Book_SK        INT NOT NULL,
    Date_SK        INT NOT NULL,
    PaymentMethod_SK INT NOT NULL,

    Quantity       INT NULL,
    UnitPrice      DECIMAL(10,2) NULL,
    GrossAmount    DECIMAL(12,2) NULL,
    DiscountAmount DECIMAL(10,2) NULL,
    NetAmount      DECIMAL(12,2) NULL,

    PromotionStatus NVARCHAR(50) NULL,

    CONSTRAINT PK_FactSales
        PRIMARY KEY (Sales_SK),

    CONSTRAINT UQ_FactSales_Receipt_Line
        UNIQUE (ReceiptNumber, LineNumber),

    CONSTRAINT FK_FactSales_DimBook
        FOREIGN KEY (Book_SK)
        REFERENCES dwh.DimBook(Book_SK),

    CONSTRAINT FK_FactSales_DimDate
        FOREIGN KEY (Date_SK)
        REFERENCES dwh.DimDate(Date_SK),

    CONSTRAINT FK_FactSales_DimPaymentMethod
        FOREIGN KEY (PaymentMethod_SK)
        REFERENCES dwh.DimPaymentMethod(PaymentMethod_SK)
);
GO


/*=============================================================================
    Step 5: Create Bridge Table
=============================================================================*/

/*-----------------------------------------------------------------------------
    5.1 BridgeSalesPromotion

    Purpose:
        Resolve the many-to-many relationship between sales and promotion
        benefits.

    A sales line can be associated with multiple benefits belonging to
    the same promotion package.
-----------------------------------------------------------------------------*/

CREATE TABLE dwh.BridgeSalesPromotion
(
    Sales_SK     INT NOT NULL,
    Promotion_SK INT NOT NULL,

    CONSTRAINT PK_BridgeSalesPromotion
        PRIMARY KEY (Sales_SK, Promotion_SK),

    CONSTRAINT FK_BridgeSalesPromotion_FactSales
        FOREIGN KEY (Sales_SK)
        REFERENCES dwh.FactSales(Sales_SK),

    CONSTRAINT FK_BridgeSalesPromotion_DimPromotion
        FOREIGN KEY (Promotion_SK)
        REFERENCES dwh.DimPromotion(Promotion_SK)
);
GO
