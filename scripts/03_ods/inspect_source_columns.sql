
/*==============================================================
  Purpose:
      Inspects the source database metadata to identify the
      structure and properties of the four bookstore tables
      before creating the ODS layer.

  Tables Inspected:
      Categories
      Promotions
      Books
      Sales

  Metadata Retrieved:
      1. Column names
      2. Data types
      3. Maximum character lengths
      4. Nullability

  Source Database: datab5
  Source Platform: Azure SQL Database
  Connection: BookstoreAzure Linked Server

  Note:
      This script is intended for source schema inspection.
      The retrieved metadata is used to guide ODS table
      definitions and data type selection.

  Execution Order:
      Run before create_ods_tables.sql.

==============================================================*/


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
