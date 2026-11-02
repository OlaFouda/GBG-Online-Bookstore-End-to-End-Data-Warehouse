
/*==============================================================
  Script: create_linked_server.sql

  Purpose:
      Configures a Linked Server connection between the local
      SQL Server instance and the Azure SQL source database.

  Operations:
      1. Checks whether the Linked Server already exists.
      2. Creates the Linked Server named 'BookstoreAzure'.
      3. Configures the remote data source and provider.
      4. Configures remote login authentication.
      5. Verifies the Linked Server configuration.
      6. Tests connectivity to the Azure SQL database.

  Source Database: datab5
  Source Platform: Azure SQL Database
  Linked Server Name: BookstoreAzure
  Provider: ----

  Note:
      Authentication credentials must be configured separately.
      Do not include passwords or sensitive credentials in GitHub.

  Execution Order:
      Run after creating the local Bookstore_DWH database
      and before executing the ODS loading scripts.

==============================================================*/


-- linked server creation script

EXEC master.dbo.sp_addlinkedserver
    @server     = N'BookstoreAzure',
    @srvproduct = N'',
    @provider   = N'----',
    @datasrc    = N'----',
    @catalog    = N'----';
GO

-- linked server login (authentication configuration)
EXEC master.dbo.sp_addlinkedsrvlogin
    @rmtsrvname = N'BookstoreAzure',
    @useself = N'False',
    @locallogin = NULL,
    @rmtuser = N'',
    @rmtpassword = N'';
GO

-- verifying the connection in created
SELECT 
    name,
    product,
    provider,
    data_source,
    catalog,
    is_linked
FROM sys.servers
WHERE name = 'BookstoreAzure';


-- testing the connection
EXEC master.dbo.sp_testlinkedserver
    @servername = N'BookstoreAzure';


SELECT
@@SERVERNAME AS ServerName,
DB_NAME() AS CurrentDatabase;

