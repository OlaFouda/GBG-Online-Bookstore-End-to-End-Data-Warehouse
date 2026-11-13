
/*
===============================================================================
    Phase B: Staging Layer (STG) - Data Loading
===============================================================================

    Procedure:
        stg.LoadSTG

    Purpose:
        Load data from the ODS layer into the STG layer, applying data
        cleaning, standardization, and transformations.

    Transformations:
        - Convert source values into appropriate data types.
        - Remove leading and trailing spaces.
        - Standardize category names and payment methods.
        - Replace missing category descriptions with a default value.
        - Remove duplicate sales lines based on ReceiptNumber and LineNumber.
        - Retain the sales line with the lowest SalesLineID.
        - Identify the promotion status of each sales line.

    Loading Strategy:
        Full Load - existing STG records are truncated before reloading.

    Source:
        ODS Layer

    Target:
        STG Layer
===============================================================================
*/

USE Bookstore_DWH;
GO


/*=============================================================================
    Create or Alter STG Loading Procedure
=============================================================================*/

CREATE OR ALTER PROCEDURE stg.LoadSTG
AS
BEGIN

    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    DECLARE
        @start_time       DATETIME,
        @end_time         DATETIME,
        @batch_start_time DATETIME,
        @batch_end_time   DATETIME;

    BEGIN TRY

        BEGIN TRANSACTION;

        SET @batch_start_time = GETDATE();


        /*---------------------------------------------------------------------
            Step 1: Clear STG Tables
            Truncate existing records before performing a full load.
        ---------------------------------------------------------------------*/

        TRUNCATE TABLE stg.Categories;
        TRUNCATE TABLE stg.Sales;
        TRUNCATE TABLE stg.Books;
        TRUNCATE TABLE stg.Promotions;


        /*---------------------------------------------------------------------
            Step 2: Load Categories
            - Convert CategoryID to INT.
            - Standardize CategoryName capitalization.
            - Replace missing descriptions with a default value.
        ---------------------------------------------------------------------*/

        SET @start_time = GETDATE();

        INSERT INTO stg.Categories
        (
            CategoryID,
            CategoryName,
            Description
        )
        SELECT
            TRY_CONVERT(INT, CategoryID),

            UPPER(LEFT(NULLIF(TRIM(CategoryName), ''), 1))
                + LOWER(SUBSTRING(
                    TRIM(CategoryName),
                    2,
                    LEN(TRIM(CategoryName))
                )),

            COALESCE(
                NULLIF(TRIM(Description), ''),
                'No Description Available'
            )

        FROM ods.Categories;


        SET @end_time = GETDATE();

        PRINT '>> stg.Categories Load Duration: '
            + CAST(DATEDIFF(SECOND, @start_time, @end_time) AS NVARCHAR(20))
            + ' seconds';


        /*---------------------------------------------------------------------
            Step 3: Load Promotions
            - Convert PromotionID to INT.
            - Trim text values.
            - Convert DiscountPercent to DECIMAL.
        ---------------------------------------------------------------------*/

        SET @start_time = GETDATE();

        INSERT INTO stg.Promotions
        (
            PromotionID,
            PromotionCode,
            PromotionName,
            DiscountPercent
        )
        SELECT
            TRY_CONVERT(INT, PromotionID),
            TRIM(PromotionCode),
            TRIM(PromotionName),
            TRY_CONVERT(DECIMAL(5,2), TRIM(DiscountPercent))

        FROM ods.Promotions;


        SET @end_time = GETDATE();

        PRINT '>> stg.Promotions Load Duration: '
            + CAST(DATEDIFF(SECOND, @start_time, @end_time) AS NVARCHAR(20))
            + ' seconds';


        /*---------------------------------------------------------------------
            Step 4: Load Books
            - Trim ISBN and BookTitle.
            - Convert CategoryID to INT.
            - Convert Price to DECIMAL.
        ---------------------------------------------------------------------*/

        SET @start_time = GETDATE();

        INSERT INTO stg.Books
        (
            BookID,
            ISBN,
            BookTitle,
            CategoryID,
            Price
        )
        SELECT
            TRY_CONVERT(INT, BookID),
            TRIM(ISBN),
            TRIM(BookTitle),
            TRY_CONVERT(INT, CategoryID),
            TRY_CONVERT(DECIMAL(10,2), Price)

        FROM ods.Books;


        SET @end_time = GETDATE();

        PRINT '>> stg.Books Load Duration: '
            + CAST(DATEDIFF(SECOND, @start_time, @end_time) AS NVARCHAR(20))
            + ' seconds';


        /*---------------------------------------------------------------------
            Step 5: Load Sales

            Duplicate Handling:
                - Identify duplicates using ReceiptNumber and LineNumber.
                - Retain the record with the lowest SalesLineID.

            Data Cleaning:
                - Convert source values to appropriate data types.
                - Standardize PaymentMethod values.
                - Trim PromotionIDs.

            Promotion Status:
                - Promotional: A promotion ID is provided.
                - No Promotion: No promotion ID and discount amount is zero.
                - Unknown: Other cases.
        ---------------------------------------------------------------------*/

        SET @start_time = GETDATE();

        WITH RankedSaleLine AS
        (
            SELECT
                *,
                ROW_NUMBER() OVER
                (
                    PARTITION BY ReceiptNumber, LineNumber
                    ORDER BY SalesLineID
                ) AS RankedSaleLine

            FROM ods.Sales
        )

        INSERT INTO stg.Sales
        (
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
            PromotionIDs,
            PromotionStatus
        )
        SELECT
            TRY_CONVERT(INT, SalesLineID),
            TRY_CONVERT(INT, SaleID),
            TRIM(ReceiptNumber),
            TRY_CONVERT(INT, LineNumber),
            TRY_CONVERT(INT, BookID),
            TRY_CONVERT(DATE, TRIM(SaleDate)),

            CASE
                WHEN UPPER(TRIM(PaymentMethod)) = 'CASH'
                    THEN 'Cash'

                WHEN UPPER(TRIM(PaymentMethod)) = 'CARD'
                    THEN 'Card'

                WHEN UPPER(TRIM(PaymentMethod)) = 'BANK TRANSFER'
                    THEN 'Bank Transfer'

                WHEN PaymentMethod IS NULL
                     OR TRIM(PaymentMethod) = ''
                    THEN 'Unknown'

                ELSE TRIM(PaymentMethod)
            END,

            TRY_CONVERT(INT, TRIM(Quantity)),
            TRY_CONVERT(DECIMAL(10,2), TRIM(UnitPrice)),
            TRY_CONVERT(DECIMAL(10,2), TRIM(DiscountAmount)),

            NULLIF(TRIM(PromotionIDs), ''),

            CASE
                WHEN PromotionIDs IS NOT NULL
                     AND TRIM(PromotionIDs) <> ''
                    THEN 'Promotional'

                WHEN (PromotionIDs IS NULL OR TRIM(PromotionIDs) = '')
                     AND TRY_CONVERT(
                         DECIMAL(10,2),
                         TRIM(DiscountAmount)
                     ) = 0
                    THEN 'No Promotion'

                ELSE 'Unknown'
            END

        FROM RankedSaleLine
        WHERE RankedSaleLine = 1;


        SET @end_time = GETDATE();

        PRINT '>> stg.Sales Load Duration: '
            + CAST(DATEDIFF(SECOND, @start_time, @end_time) AS NVARCHAR(20))
            + ' seconds';


        /*---------------------------------------------------------------------
            Step 6: Complete Loading
        ---------------------------------------------------------------------*/

        SET @batch_end_time = GETDATE();

        COMMIT TRANSACTION;

        PRINT 'STG Layer Loading Completed Successfully.';

        PRINT '>> Full Batch Load Duration: '
            + CAST(DATEDIFF(SECOND, @batch_start_time, @batch_end_time) AS NVARCHAR(20))
            + ' seconds';


    END TRY

    BEGIN CATCH

        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;

        PRINT 'ERROR OCCURRED DURING STG DATA LOADING.';
        PRINT 'Error Message: ' + ERROR_MESSAGE();
        PRINT 'Error Number: ' + CAST(ERROR_NUMBER() AS NVARCHAR(20));
        PRINT 'Error State: ' + CAST(ERROR_STATE() AS NVARCHAR(20));

        THROW;

    END CATCH;

END;
GO


/*=============================================================================
    Execute STG Loading Procedure
=============================================================================*/

-- EXEC stg.LoadSTG;
