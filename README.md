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
* Connected the sales fact table to book and date dimensions.
* Created a bridge table to support multiple promotions per sales line.
* Used a composite primary key in the bridge table to prevent duplicate sales-promotion associations.

#### Measures and Calculations

The fact table contains the following measures:

* Gross Amount = Quantity × Unit Price
* Net Amount = Gross Amount − Discount Amount

The historical transaction `UnitPrice` from the sales source was retained instead of using the current book price.

The actual transaction-level `DiscountAmount` was used rather than recalculating discounts from the configured promotion percentages.

#### Date Dimension

Created `DimDate` to support date-based analysis, including:

* Day number and name
* Week number
* Month number and name
* Quarter
* Year

A numerical `DateKey` in YYYYMMDD format was used to connect the fact table to the date dimension.

### 5. Data Quality and Validation

Data quality checks were performed across the staging and warehouse layers.

Validation included:

* Duplicate sales record detection.
* Data type conversion checks.
* NULL and empty-value checks.
* Referential integrity validation.
* Invalid book and category reference checks.
* Invalid promotion reference detection.
* Fact table grain and uniqueness validation.
* Gross and net sales calculation validation.
* Record count reconciliation between pipeline layers.
* Duplicate association checks in the bridge table.

These checks helped ensure that the warehouse maintained consistent relationships and reliable analytical results.

## Challenges and Engineering Decisions

During implementation, several data-related and technical challenges required investigation and resolution.

| Challenge                                       | Approach / Resolution                                                                                                                                      |
| ----------------------------------------------- | ---------------------------------------------------------------------------------------------------------------------------------------------------------- |
| Connecting local SQL Server to Azure SQL        | Configured and tested a Linked Server connection.                                                                                                          |
| Inconsistent source data types                  | Applied appropriate data type conversions in STG.                                                                                                          |
| Empty strings and whitespace                    | Used `TRIM` and `NULLIF` to standardize values.                                                                                                            |
| Duplicate sales records                         | Used `ROW_NUMBER()` with the business key to identify and resolve duplicates.                                                                              |
| Duplicate promotion references                  | Used `DISTINCT` when generating bridge-table associations.                                                                                                 |
| Invalid promotion reference                     | Identified an invalid promotion ID and excluded the unmatched reference from the bridge while retaining the original source information in earlier layers. |
| Many-to-many promotion relationships            | Designed a bridge table between FactSales and DimPromotion.                                                                                                |
| Surrogate and business keys                     | Used surrogate keys for warehouse relationships while preserving source identifiers and enforcing business-key uniqueness.                                 |
| Historical versus current book prices           | Used transaction-level UnitPrice for historical sales calculations.                                                                                        |
| Full-refresh loading with foreign keys          | Used DELETE in the appropriate dependency order where TRUNCATE was blocked by foreign key relationships.                                                   |
| Duplicate DateKey during reloading              | Corrected the full-refresh procedure to clear DimDate before inserting dates again.                                                                        |
| Fact table loading before date dimension        | Corrected the loading sequence to ensure DimDate was populated before FactSales.                                                                           |
| Incorrect identity reseeding                    | Removed DBCC CHECKIDENT for DimDate because DateKey is not an IDENTITY column.                                                                             |
| Potential double counting in analytical queries | Considered the many-to-many bridge relationship when joining sales with promotions.                                                                        |

## ETL Execution Order

The complete pipeline is executed through the following stored procedures:

```sql
EXEC ods.LoadODS;

EXEC stg.LoadSTG;

EXEC dwh.LoadDWH;

EXEC dwh.DataQualityDWH;
```

The loading process uses a **full-refresh strategy**, rebuilding the relevant layer contents rather than performing incremental loads.

## Business Analysis

After loading the warehouse, analytical SQL queries were developed to evaluate bookstore sales performance.

The analysis covers:

1. **Overall Sales Performance**

   * Total sales lines
   * Total receipts
   * Units sold
   * Gross sales
   * Total discounts
   * Net sales

2. **Monthly Sales Analysis**

   * Monthly revenue
   * Sales volume
   * Transaction trends
   * Monthly performance comparisons

3. **Payment Method Analysis**

   * Sales distribution by payment method
   * Revenue and units sold by payment method

4. **Category Performance**

   * Revenue by book category
   * Units sold by category
   * Category contribution to total sales

5. **Book Performance**

   * Best-selling books by quantity
   * Books ranked by net sales
   * Revenue contribution by book

6. **Promotion Analysis**

   * Promotion usage
   * Number of associated sales lines
   * Units sold under each promotion

**Analytical consideration:** Since a sales line can be associated with multiple promotions, financial measures must not be summed across promotion associations without an explicit allocation rule. Otherwise, the same sales amount may be counted multiple times.

## Project Results

The completed warehouse contains the following records:

| Table                | Loaded Records |
| -------------------- | -------------: |
| DimCategory          |              6 |
| DimBook              |             30 |
| DimPromotion         |              8 |
| FactSales            |            116 |
| BridgeSalesPromotion |            153 |

The sales fact table contains 116 unique sales lines after duplicate resolution.

### Overall Sales Summary

| Metric          |    Result |
| --------------- | --------: |
| Sales Lines     |       116 |
| Total Receipts  |        60 |
| Units Sold      |       290 |
| Gross Sales     | 77,075.00 |
| Total Discounts |    630.00 |
| Net Sales       | 76,445.00 |

*Note: The discount totals reflect the implemented assumption that NULL discount amounts are treated as zero.*

## Assumptions and Limitations

* The pipeline currently uses full-refresh loading rather than incremental loading.
* NULL discount amounts are treated as zero in the fact table; this assumes that a missing discount represents no discount.
* Invalid promotion references are excluded from the bridge relationship but retained in the earlier pipeline layers.
* Promotion discount percentages represent configured promotion values and are not used to recalculate actual transaction discounts.
* The date dimension contains distinct dates available in the sales data rather than a complete calendar range.
* Line-level discounts cannot be allocated to individual promotions without an additional business allocation rule or more detailed source information.

## Skills and Learning Outcomes

This project provided practical experience in several core Data Engineering areas:

* Designing and implementing a multi-layer ETL pipeline.
* Working with Azure SQL Database and local SQL Server.
* Configuring and troubleshooting Linked Server connections.
* Writing T-SQL stored procedures for data ingestion and transformation.
* Applying data cleaning and standardization techniques.
* Understanding data warehouse architecture and dimensional modeling.
* Designing fact, dimension and bridge tables.
* Working with surrogate keys, composite keys and referential integrity.
* Identifying and resolving data quality issues.
* Implementing full-refresh loading strategies.
* Validating data consistency across pipeline layers.
* Writing analytical SQL queries to extract business insights.

The project strengthened my understanding of how operational data is transformed into a structured data warehouse and how engineering decisions affect data quality, relationships and analytical accuracy.

---

## Repository Structure

```text
online-bookstore-data-warehouse/
│
├── README.md
│
├── docs/
│   ├── architecture.png
│   ├── database_diagram.png
│   └── data_dictionary.md
│
├── sql/
│   ├── 01_database_setup/
│   ├── 02_connection_setup/
│   ├── 03_ods/
│   ├── 04_staging/
│   ├── 05_data_warehouse/
│   ├── 06_data_quality/
│   └── 07_analysis/
│
└── screenshots/
    ├── pipeline_execution.png
    └── analysis_results.png
```

## Acknowledgment

Developed as a practical Data Engineering training assignment during my training at **Global Brands Group**.

The project provided hands-on experience with SQL Server, Azure SQL, ETL development, data warehousing, dimensional modeling and analytical SQL.
