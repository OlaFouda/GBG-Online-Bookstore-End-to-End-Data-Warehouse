/*
===============================================================================
    Phase C: Loading the Data Warehouse (DWH)
===============================================================================

    Procedure:
        dwh.LoadDWH

    Purpose:
        Perform a full refresh of the Data Warehouse by loading data
        from the staging layer into the dimensional model.

    Loading Order:
        1. DimCategory
        2. DimBook
        3. DimPromotion
        4. DimDate
        5. DimPaymentMethod
        6. FactSales
        7. BridgeSalesPromotion

    Notes:
        - Surrogate keys are generated automatically for dimensions and facts.
        - Date_SK is generated in YYYYMMDD format.
        - Promotion benefits belonging to the same package are aggregated
          into one promotion record.
===============================================================================
*/

CREATE OR ALTER PROCEDURE dwh.LoadDWH
AS
BEGIN

    DECLARE
        @batch_start_time DATETIME2,
        @batch_end_time   DATETIME2;

    BEGIN TRY

        BEGIN TRANSACTION;

        SET @batch_start_time = SYSDATETIME();


        /*=====================================================================
            Step 1: Clear Existing DWH Data
        =====================================================================*/

        -- Clear bridge table first because it references FactSales
        -- and DimPromotion.

        DELETE FROM dwh.BridgeSalesPromotion;

        -- Clear fact table.

        DELETE FROM dwh.FactSales;

        -- Clear dimension tables.

        DELETE FROM dwh.DimBook;
        DELETE FROM dwh.DimPromotion;
        DELETE FROM dwh.DimPaymentMethod;
        DELETE FROM dwh.DimCategory;
        DELETE FROM dwh.DimDate;


        /*=====================================================================
            Step 2: Reset Identity Values
        =====================================================================*/

        DBCC CHECKIDENT ('dwh.DimCategory', RESEED, 0);
        DBCC CHECKIDENT ('dwh.DimBook', RESEED, 0);
        DBCC CHECKIDENT ('dwh.DimPromotion', RESEED, 0);
        DBCC CHECKIDENT ('dwh.DimPaymentMethod', RESEED, 0);
        DBCC CHECKIDENT ('dwh.FactSales', RESEED, 0);


        /*=====================================================================
            Step 3: Load Dimension Tables
        =====================================================================*/


        -- 3.1 Load DimCategory

        INSERT INTO dwh.DimCategory
        (
            CategoryID,
            CategoryName,
            Description
        )
        SELECT
            CategoryID,
            CategoryName,
            Description
        FROM stg.Categories;


        -- 3.2 Load DimBook

        INSERT INTO dwh.DimBook
        (
            BookID,
            ISBN,
            BookTitle,
            Category_SK,
            CurrentPrice
        )
        SELECT
            b.BookID,
            b.ISBN,
            b.BookTitle,
            c.Category_SK,
            b.Price
        FROM stg.Books b
        INNER JOIN dwh.DimCategory c
            ON b.CategoryID = c.CategoryID;


        -- 3.3 Load DimPromotion

        -- Aggregate benefit percentages belonging to the same package.

        INSERT INTO dwh.DimPromotion
        (
            PromotionID,
            PromotionCode,
            PromotionName,
            DiscountPercent
        )
        SELECT
            PromotionID,
            PromotionCode,
            PromotionName,
            SUM(DiscountPercent)
        FROM stg.Promotions
        GROUP BY
            PromotionID,
            PromotionCode,
            PromotionName;


        -- 3.4 Load DimDate

        INSERT INTO dwh.DimDate
        (
            Date_SK,
            FullDate,
            DayNumber,
            DayName,
            WeekNumber,
            MonthNumber,
            MonthName,
            QuarterNumber,
            YearNumber
        )
        SELECT
            CONVERT(INT, CONVERT(CHAR(8), d.DateValue, 112)),
            d.DateValue,
            DAY(d.DateValue),
            DATENAME(WEEKDAY, d.DateValue),
            DATEPART(WEEK, d.DateValue),
            MONTH(d.DateValue),
            DATENAME(MONTH, d.DateValue),
            DATEPART(QUARTER, d.DateValue),
            YEAR(d.DateValue)
        FROM
        (
            SELECT DISTINCT SaleDate AS DateValue
            FROM stg.Sales
            WHERE SaleDate IS NOT NULL
        ) d;


        -- 3.5 Load DimPaymentMethod

        -- Replace NULL or empty payment methods with 'Unknown'.

        INSERT INTO dwh.DimPaymentMethod
        (
            PaymentMethod
        )
        SELECT DISTINCT
            COALESCE(NULLIF(TRIM(PaymentMethod), ''), 'Unknown')
        FROM stg.Sales;


        /*=====================================================================
            Step 4: Load Fact Table
        =====================================================================*/

        INSERT INTO dwh.FactSales
        (
            SalesLineID,
            SaleID,
            ReceiptNumber,
            LineNumber,
            Book_SK,
            Date_SK,
            PaymentMethod_SK,
            Quantity,
            UnitPrice,
            GrossAmount,
            DiscountAmount,
            NetAmount,
            PromotionStatus
        )
        SELECT
            s.SalesLineID,
            s.SaleID,
            s.ReceiptNumber,
            s.LineNumber,
            b.Book_SK,
            dd.Date_SK,
            pm.PaymentMethod_SK,
            s.Quantity,
            s.UnitPrice,
            s.Quantity * s.UnitPrice,
            COALESCE(s.DiscountAmount, 0),
            (s.Quantity * s.UnitPrice) - COALESCE(s.DiscountAmount, 0),

            CASE
                WHEN s.PromotionID IS NULL THEN 'No Promotion'
                ELSE 'Promotion Applied'
            END

        FROM stg.Sales s

        INNER JOIN dwh.DimBook b
            ON s.BookID = b.BookID

        INNER JOIN dwh.DimDate dd
            ON s.SaleDate = dd.FullDate

        INNER JOIN dwh.DimPaymentMethod pm
            ON COALESCE(NULLIF(TRIM(s.PaymentMethod), ''), 'Unknown')
               = pm.PaymentMethod;


        /*=====================================================================
            Step 5: Load Bridge Table
        =====================================================================*/

        INSERT INTO dwh.BridgeSalesPromotion
        (
            Sales_SK,
            Promotion_SK
        )
        SELECT DISTINCT
            fs.Sales_SK,
            dp.Promotion_SK

        FROM stg.Sales s

        INNER JOIN dwh.FactSales fs
            ON s.SalesLineID = fs.SalesLineID

        INNER JOIN dwh.DimPromotion dp
            ON s.PromotionID = dp.PromotionID

        WHERE s.PromotionID IS NOT NULL;


        /*=====================================================================
            Step 6: Complete Batch
        =====================================================================*/

        SET @batch_end_time = SYSDATETIME();

        COMMIT TRANSACTION;

        PRINT 'DWH Loading Completed Successfully';

        PRINT 'Full Batch Load Duration: '
            + CAST(DATEDIFF(SECOND, @batch_start_time, @batch_end_time) AS NVARCHAR(20))
            + ' seconds';


    END TRY

    BEGIN CATCH

        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;

        PRINT 'ERROR OCCURRED DURING DWH LOADING';
        PRINT 'Error Message: ' + ERROR_MESSAGE();
        PRINT 'Error Number: ' + CAST(ERROR_NUMBER() AS NVARCHAR(20));
        PRINT 'Error State: ' + CAST(ERROR_STATE() AS NVARCHAR(20));

        THROW;

    END CATCH;

END;
GO


/*=============================================================================
    Execute DWH Loading Procedure
=============================================================================*/

EXEC dwh.LoadDWH;
GO
