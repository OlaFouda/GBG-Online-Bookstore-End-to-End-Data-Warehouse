
/*==============================================================
  Script: create_database.sql

  Purpose:
      Creates the local SQL Server database used as the target
      environment for the Online Bookstore Data Warehouse project.

  Operations:
      1. Displays the SQL Server instance and current database.
      2. Checks whether Bookstore_DWH already exists.
      3. Creates the database if it does not exist.

  Target Database: Bookstore_DWH
  Platform: Microsoft SQL Server

  Note:
      Schema and table creation are handled separately within
      their respective ODS, STG, and DWH setup scripts.

  Execution Order:
      Run this script before executing the pipeline setup scripts.

==============================================================*/



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
