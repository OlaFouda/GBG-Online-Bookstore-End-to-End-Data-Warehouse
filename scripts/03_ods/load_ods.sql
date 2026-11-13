
USE Bookstore_DWH;
GO

/*==============================================================
  Script: load_ods.sql

  Purpose:
      Loads source data from Azure SQL Database into the
      Operational Data Store (ODS) layer.

  Source Database: datab5
  Target Database: Bookstore_DWH
  Linked Server: BookstoreAzure

  Tables Loaded:
      1. ods.Categories
      2. ods.Promotions
      3. ods.Books
      4. ods.Sales

  Loading Strategy:
      Full Refresh

  Operations:
      1. Begins a database transaction.
      2. Truncates existing ODS records.
      3. Extracts data from the Azure SQL source.
      4. Loads all four ODS tables.
      5. Tracks individual table loading durations.
      6. Commits the transaction upon success.
      7. Rolls back and reports errors upon failure.

  Note:
      ODS preserves source-oriented data.
      Data cleaning and type conversions are handled
      in the subsequent STG layer.

  Execution:
      EXEC ods.LoadODS;

==============================================================*/

-- Create or alter the ODS loading procedure

CREATE OR ALTER PROCEDURE ods.LoadODS
AS
BEGIN

    SET NOCOUNT ON;

    DECLARE
        @start_time DATETIME,
        @end_time DATETIME,
        @batch_start_time DATETIME,
        @batch_end_time DATETIME;

    BEGIN TRY

        BEGIN TRANSACTION;

        SET @batch_start_time = GETDATE();

        -- Truncate ODS tables for a full refresh

        TRUNCATE TABLE ods.Categories;
        TRUNCATE TABLE ods.Sales;
        TRUNCATE TABLE ods.Books;
        TRUNCATE TABLE ods.Promotions;


        --======================================================
        -- Load Categories
        --======================================================

        SET @start_time = GETDATE();

        INSERT INTO ods.Categories (
            CategoryID,
            CategoryName,
            Description
        )
        SELECT
            CategoryID,
            CategoryName,
            Description
        FROM [BookstoreAzure].[datab5].[dbo].[Categories];

        SET @end_time = GETDATE();

        PRINT '>> ods.Categories Load Duration: '
            + CAST(DATEDIFF(SECOND, @start_time, @end_time) AS NVARCHAR(20))
            + ' seconds';


        --======================================================
        -- Load Promotions
        --======================================================

        SET @start_time = GETDATE();

        INSERT INTO ods.Promotions (
            PromotionBenefitID,
            PromotionID,
            PromotionCode,
            PromotionName,
            BenefitCode,
            BenefitName,
            DiscountPercent
        )
        SELECT
            PromotionBenefitID,
            PromotionID,
            PromotionCode,
            PromotionName,
            BenefitCode,
            BenefitName,
            DiscountPercent
        FROM [BookstoreAzure].[datab5].[dbo].[Promotions];

        SET @end_time = GETDATE();

        PRINT '>> ods.Promotions Load Duration: '
            + CAST(DATEDIFF(SECOND, @start_time, @end_time) AS NVARCHAR(20))
            + ' seconds';


        --======================================================
        -- Load Books
        --======================================================

        SET @start_time = GETDATE();

        INSERT INTO ods.Books (
            BookID,
            ISBN,
            BookTitle,
            CategoryID,
            Price
        )
        SELECT
            BookID,
            ISBN,
            BookTitle,
            CategoryID,
            Price
        FROM [BookstoreAzure].[datab5].[dbo].[Books];

        SET @end_time = GETDATE();

        PRINT '>> ods.Books Load Duration: '
            + CAST(DATEDIFF(SECOND, @start_time, @end_time) AS NVARCHAR(20))
            + ' seconds';


        --======================================================
        -- Load Sales
        --======================================================

        SET @start_time = GETDATE();

        INSERT INTO ods.Sales (
            SalesLineID,
            SaleID,
            ReceiptNumber,
            LineNumber,
            BookID,
            SaleDate,
            PaymentMethod,
            Quantity,
            UnitPrice,
            DiscountAmount,
            PromotionIDs
        )
        SELECT
            SalesLineID,
            SaleID,
            ReceiptNumber,
            LineNumber,
            BookID,
            SaleDate,
            PaymentMethod,
            Quantity,
            UnitPrice,
            DiscountAmount,
            PromotionIDs
        FROM [BookstoreAzure].[datab5].[dbo].[Sales];

        SET @end_time = GETDATE();

        PRINT '>> ods.Sales Load Duration: '
            + CAST(DATEDIFF(SECOND, @start_time, @end_time) AS NVARCHAR(20))
            + ' seconds';


        --======================================================
        -- Complete Batch
        --======================================================

        SET @batch_end_time = GETDATE();

        COMMIT TRANSACTION;

        PRINT 'Loading ODS Layer Complete';

        PRINT '>> Full Batch Load Duration: '
            + CAST(DATEDIFF(SECOND, @batch_start_time, @batch_end_time) AS NVARCHAR(20))
            + ' seconds';


    END TRY

    BEGIN CATCH

        PRINT 'ERROR OCCURRED DURING ODS DATA LOADING';

        PRINT 'Error Message: ' + ERROR_MESSAGE();

        PRINT 'Error Number: '
            + CAST(ERROR_NUMBER() AS NVARCHAR(20));

        PRINT 'Error State: '
            + CAST(ERROR_STATE() AS NVARCHAR(20));

        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;

        THROW;

    END CATCH;

END;
GO


--==============================================================
-- Execute ODS Loading Procedure
--==============================================================

EXEC ods.LoadODS;
GO


--==============================================================
-- Verify Loaded Record Counts
--==============================================================

SELECT 'Categories' AS TableName, COUNT(*) AS RecordCount
FROM ods.Categories

UNION ALL

SELECT 'Promotions', COUNT(*)
FROM ods.Promotions

UNION ALL

SELECT 'Books', COUNT(*)
FROM ods.Books

UNION ALL

SELECT 'Sales', COUNT(*)
FROM ods.Sales;
GO
