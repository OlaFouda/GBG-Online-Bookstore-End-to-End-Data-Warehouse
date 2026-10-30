

--USE Bookstore_DWH;

/*-----------------------------------------------------------------------
	Phase A: Step 2: Creating ODS
		Broken to 3 steps:
		1. Inspect source columns. 
		2. Create the ODS layer tables.
		3. load all four source tables using SQL Server stored procedures.
 -----------------------------------------------------------------------*/

 --===============   Setp 1: Inspect source columns for 4 tables ===================

 -- inspecting source columns for table 'Ctegories'


SELECT
	COLUMN_NAME,
	DATA_TYPE,
	CHARACTER_MAXIMUM_LENGTH,
	IS_NULLABLE

FROM OPENQUERY(BookstoreAzure, '
		SELECT
			COLUMN_NAME,
			DATA_TYPE,
			CHARACTER_MAXIMUM_LENGTH,
			IS_NULLABLE
		FROM datab5.INFORMATION_SCHEMA.COLUMNS
		WHERE TABLE_NAME = ''Categories'' 
	')


 -- inspecting source columns for table 'Promotions'

 SELECT
	COLUMN_NAME,
	DATA_TYPE,
	CHARACTER_MAXIMUM_LENGTH,
	IS_NULLABLE

FROM OPENQUERY(BookstoreAzure, '
		SELECT
			COLUMN_NAME,
			DATA_TYPE,
			CHARACTER_MAXIMUM_LENGTH,
			IS_NULLABLE
		FROM datab5.INFORMATION_SCHEMA.COLUMNS
		WHERE TABLE_NAME = ''Promotions'' 
	')

 -- inspecting source columns for table 'Books'

 SELECT
	COLUMN_NAME,
	DATA_TYPE,
	CHARACTER_MAXIMUM_LENGTH,
	IS_NULLABLE

FROM OPENQUERY(BookstoreAzure, '
		SELECT
			COLUMN_NAME,
			DATA_TYPE,
			CHARACTER_MAXIMUM_LENGTH,
			IS_NULLABLE
		FROM datab5.INFORMATION_SCHEMA.COLUMNS
		WHERE TABLE_NAME = ''Books'' 
	')


-- inspecting source columns for table 'Sales'

 SELECT
	COLUMN_NAME,
	DATA_TYPE,
	CHARACTER_MAXIMUM_LENGTH,
	IS_NULLABLE

FROM OPENQUERY(BookstoreAzure, '
		SELECT
			COLUMN_NAME,
			DATA_TYPE,
			CHARACTER_MAXIMUM_LENGTH,
			IS_NULLABLE
		FROM datab5.INFORMATION_SCHEMA.COLUMNS
		WHERE TABLE_NAME = ''Sales'' 
	')


 --============   Setp 2: Create the ODS tables   =================



 -- creating schema for ODS layer

 CREATE SCHEMA ods;
 

 -- drop categories table if exists
 IF OBJECT_ID ('ods.Categories','U') IS NOT NULL
	DROP TABLE ods.Categories ;

-- creating Categories table

 CREATE TABLE ods.Categories (
		CategoryID INT NOT NULL PRIMARY KEY,
		CategoryName NVARCHAR(100) NULL,
		Description NVARCHAR(250) NULL
		);



 -- drop promotions table if exists
 IF OBJECT_ID ('ods.Promotions','U') IS NOT NULL
	DROP TABLE ods.Promotions ;

-- creating Promotions table

CREATE TABLE ods.Promotions (
		PromotionID INT NOT NULL PRIMARY KEY,
		PromotionCode NVARCHAR (30) NULL,
		PromotionName NVARCHAR (120) NULL,
		DiscountPercent NVARCHAR (20) NULL
		);



 -- drop Books table if exists
 IF OBJECT_ID ('ods.Books','U') IS NOT NULL
	DROP TABLE ods.Books ;

-- creating Books table

CREATE TABLE ods.Books (
		BookID INT NOT NULL PRIMARY KEY,
		ISBN NVARCHAR (20) NULL,
		BookTitle NVARCHAR (150) NULL,
		CategoryID INT NOT NULL,
		Price NVARCHAR (30) NULL
		);



 -- drop Sales table if exists
 IF OBJECT_ID ('ods.Sales','U') IS NOT NULL
	DROP TABLE ods.Sales ;

-- creating sales table

CREATE TABLE ods.Sales (
		SalesLineID INT NOT NULL PRIMARY KEY,
		SaleID INT NOT NULL,
		ReceiptNumber NVARCHAR (30) NOT NULL,
		LineNumber INT NOT NULL,
		BookID INT NOT NULL, 
		SaleDate NVARCHAR (30) NULL,
		PaymentMethod NVARCHAR (50) NULL,
		Quantity NVARCHAR (10) NULL,
		UnitPrice NVARCHAR (30) NULL,
		DiscountAmount NVARCHAR (30) NULL,
		PromotionIDs NVARCHAR (100) NULL

		);



 --============   Setp 3: Loading to the ODS tables procedure   =================



 -- loading tables procedure

 CREATE OR ALTER PROCEDURE ods.LoadODS
 AS
 BEGIN

	DECLARE @start_time DATETIME, @end_time DATETIME, @batch_start_time DATETIME, @batch_end_time DATETIME;

	BEGIN TRY
		BEGIN TRANSACTION;

		SET @batch_start_time = GETDATE();

		-- Truncate tables for a full load
	
		TRUNCATE TABLE ods.Categories;
		TRUNCATE TABLE ods.Sales;
		TRUNCATE TABLE ods.Books;
		TRUNCATE TABLE ods.Promotions;

		-- loading data to categories table

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
		PRINT '>> ods.Categories Load Duration:' + CAST(DATEDIFF(second, @start_time, @end_time) AS NVARCHAR) + ' seconds';

		-- loading data to Promotions table

		SET @start_time = GETDATE();

		INSERT INTO ods.Promotions (
			PromotionID,
			PromotionCode,
			PromotionName,
			DiscountPercent
			)

			SELECT 
				PromotionID,
				PromotionCode,
				PromotionName,
				DiscountPercent
			FROM [BookstoreAzure].[datab5].[dbo].[Promotions];

			
		SET @end_time = GETDATE();
		PRINT '>> ods.Promotions Load Duration:' + CAST(DATEDIFF(second, @start_time, @end_time) AS NVARCHAR) + ' seconds';

		
		-- loading data to Books table

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
		PRINT '>> ods.Books Load Duration:' + CAST(DATEDIFF(second, @start_time, @end_time) AS NVARCHAR) + ' seconds';


		-- loading data to Sales table

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
			PromotionIDs )

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
			PRINT '>> ods.Sales Load Duration:' + CAST(DATEDIFF(second, @start_time, @end_time) AS NVARCHAR) + ' seconds';

		SET @batch_end_time = GETDATE();

		COMMIT TRANSACTION;

		PRINT 'Loading ODS Layer Complete'
		PRINT '>> Full Batch Load Duration: ' + CAST(DATEDIFF(second, @batch_start_time, @batch_end_time) AS NVARCHAR) + ' seconds';


	END TRY

	BEGIN CATCH

		PRINT 'ERROR OCCURED DURING LOADING ODS DATA'
		PRINT 'Error Message:' + ERROR_MESSAGE();
		PRINT 'Error Number:' + CAST (ERROR_NUMBER() AS NVARCHAR);
		PRINT 'Error State:' + CAST (ERROR_STATE() AS NVARCHAR);

		IF @@TRANCOUNT > 0
			ROLLBACK TRANSACTION;

	THROW
	END CATCH;

END;
GO


 -- to run proc

 -- EXEC ods.loadODS



