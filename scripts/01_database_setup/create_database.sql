
/*---------------------------------------------------

### Purpose

Creates the local SQL Server database that serves as the target environment for the Online Bookstore Data Warehouse project.

### Operations

1. Retrieves the SQL Server instance name and current database context for environment verification.
2. Checks whether the `Bookstore_DWH` database already exists.
3. Creates the database only if it does not exist, preventing unnecessary errors when the script is executed multiple times.

### Target Database

* **Database Name:** `Bookstore_DWH`
* **Platform:** Microsoft SQL Server

### Execution

Run this script before executing the ODS, STG and DWH setup scripts.

### Notes

* The script does not create schemas or tables; these are handled separately within their respective pipeline layers.
* The database is created locally and acts as the destination for the warehouse pipeline.
* The existence check makes the script safe to execute repeatedly.

 ----------------------------------------------------*/


-- Verify SQL Server and current database
SELECT
    @@SERVERNAME AS ServerName,
    DB_NAME() AS CurrentDatabase;

-- Create database if it doesn't exist
IF DB_ID('Bookstore_DWH') IS NULL
BEGIN
    CREATE DATABASE Bookstore_DWH;
END;
GO
