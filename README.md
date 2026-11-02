# Online Bookstore – End-to-End Data Warehouse

An end-to-end Data Engineering project developed as part of my Data Engineering training at **Global Brands Group**.

The project focuses on building a SQL Server data warehouse solution, starting with data ingestion from Azure SQL Database and progressing through data cleaning, transformation, dimensional modeling, data quality validation, and analytical reporting.

## Project Overview

The objective was to transform operational bookstore data into a structured data warehouse that supports business analysis and reporting.

The solution follows a layered ETL architecture consisting of:

* **Source:** Azure SQL Database
* **ODS:** Operational Data Store
* **STG:** Staging Layer
* **DWH:** Data Warehouse

The pipeline uses SQL Server stored procedures to automate data ingestion and transformation between layers.

## Technologies Used

| Technology                          | Purpose                                                 |
| ----------------------------------- | ------------------------------------------------------- |
| Microsoft SQL Server                | Database development and data warehousing               |
| Azure SQL Database                  | Source database                                         |
| SQL Server Management Studio (SSMS) | Database management and SQL development                 |
| T-SQL                               | Data extraction, transformation, loading and validation |
| Linked Server                       | Connecting local SQL Server to Azure SQL                |
| SQL Server Agent                    | Scheduling and executing ODS loading jobs               |
| SQL Server Database Diagrams        | Visualizing database relationships                      |

## Architecture

The project follows a layered ETL approach:

```text
        Azure SQL Database
          (Source Data)
                |
                |
          Linked Server
                |
                v
        Operational Data Store
               (ODS)
                |
                v
          Staging Layer
               (STG)
                |
                v
         Data Warehouse
               (DWH)
                |
                v
       Analytical SQL Queries
```

### 1. Source Database

The source database is hosted on Azure SQL Database and contains four operational tables:

| Table      | Description                               |
| ---------- | ----------------------------------------- |
| Categories | Book category information                 |
| Books      | Book details, ISBN, category and price    |
| Promotions | Promotion codes and discount percentages  |
| Sales      | Sales transactions and line-level details |

The source data was accessed from the local SQL Server environment through a Linked Server connection.

### 2. Operational Data Store (ODS)

The ODS layer was designed to ingest and preserve source-oriented data before applying cleaning and transformation rules.

**Implementation:**

* Created ODS tables corresponding to the source tables.
* Established a Linked Server connection to Azure SQL Database.
* Developed the `ods.LoadODS` stored procedure.
* Implemented full-refresh loading using table truncation.
* Added transaction handling with TRY/CATCH, COMMIT and ROLLBACK.
* Included execution timestamps and table-level loading messages.
* Configured a SQL Server Agent job to execute the ODS loading procedure on demand.

### 3. Staging Layer (STG)

The staging layer handles data type conversion, standardization and data quality preparation before loading the warehouse.

**Transformations performed:**

* Converted source fields into appropriate SQL Server data types.
* Used `TRY_CONVERT` to handle potentially invalid conversions.
* Applied `TRIM` to remove unwanted whitespace.
* Used `NULLIF` to standardize empty strings as NULL.
* Standardized payment methods into consistent categories.
* Identified and removed duplicate sales lines.
* Preserved source identifiers for traceability.
* Prepared promotion identifiers for subsequent many-to-many relationship handling.
* Derived a `PromotionStatus` classification based on promotion references and discount amounts.

**Duplicate handling:**

Sales records were checked using the business key:

`(ReceiptNumber, LineNumber)`

Duplicate records were identified using `ROW_NUMBER()` and resolved by retaining the record with the lowest `SalesLineID`.

This reduced the sales records from 120 in ODS to 116 in STG.

### 4. Data Warehouse (DWH)

The warehouse was designed using a star-schema-based dimensional model.

#### Database Model

The warehouse consists of six tables:

| Table                | Type      | Description                                                         |
| -------------------- | --------- | ------------------------------------------------------------------- |
| DimCategory          | Dimension | Book category attributes                                            |
| DimBook              | Dimension | Book details and category relationship                              |
| DimPromotion         | Dimension | Promotion information                                               |
| DimDate              | Dimension | Calendar attributes                                                 |
| FactSales            | Fact      | Sales transaction measures                                          |
| BridgeSalesPromotion | Bridge    | Resolves the many-to-many relationship between sales and promotions |

#### Fact Table Grain

The grain of `FactSales` is **one row per unique sales line**, identified by the combination of `ReceiptNumber` and `LineNumber`.

A surrogate key (`SalesKey`) was introduced as the primary key, while a composite UNIQUE constraint was applied to the source business key.

#### Dimensional Modeling

* Implemented surrogate keys for dimension and fact tables.
* Established primary and foreign key relationships.
* Connected the sales fact table to book and
