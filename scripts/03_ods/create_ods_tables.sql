
USE Bookstore_DWH;
GO

/*==============================================================
  Script: create_ods_tables.sql

  Purpose:
      Creates the ODS schema and its four source-oriented tables.

  Tables:
      ods.Categories
      ods.Promotions
      ods.Books
      ods.Sales

  Note:
      Existing ODS tables are dropped and recreated.
      Data loading is handled separately by ods.LoadODS.
==============================================================*/

-- Create ODS schema if it does not exist
IF SCHEMA_ID(N'ods') IS NULL
    EXEC(N'CREATE SCHEMA ods;');
GO

-- Drop existing tables
DROP TABLE IF EXISTS ods.Sales;
DROP TABLE IF EXISTS ods.Books;
DROP TABLE IF EXISTS ods.Promotions;
DROP TABLE IF EXISTS ods.Categories;
GO

-- Create Categories
CREATE TABLE ods.Categories (
    CategoryID INT NOT NULL PRIMARY KEY,
    CategoryName NVARCHAR(100) NULL,
    Description NVARCHAR(250) NULL
);

-- Create Promotions
CREATE TABLE ods.Promotions (
    PromotionID INT NOT NULL PRIMARY KEY,
    PromotionCode NVARCHAR(30) NULL,
    PromotionName NVARCHAR(120) NULL,
    DiscountPercent NVARCHAR(20) NULL
);

-- Create Books
CREATE TABLE ods.Books (
    BookID INT NOT NULL PRIMARY KEY,
    ISBN NVARCHAR(20) NULL,
    BookTitle NVARCHAR(150) NULL,
    CategoryID INT NOT NULL,
    Price NVARCHAR(30) NULL
);

-- Create Sales
CREATE TABLE ods.Sales (
    SalesLineID INT NOT NULL PRIMARY KEY,
    SaleID INT NOT NULL,
    ReceiptNumber NVARCHAR(30) NOT NULL,
    LineNumber INT NOT NULL,
    BookID INT NOT NULL,
    SaleDate NVARCHAR(30) NULL,
    PaymentMethod NVARCHAR(50) NULL,
    Quantity NVARCHAR(10) NULL,
    UnitPrice NVARCHAR(30) NULL,
    DiscountAmount NVARCHAR(30) NULL,
    PromotionIDs NVARCHAR(100) NULL
);
GO
