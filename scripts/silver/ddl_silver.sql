/*
================================================================================
Script Name : CreateSilverTables.sql
Purpose     : Create the Silver-layer tables in the DataWarehouse database.

Description:
    This script creates six tables in the silver schema to store cleaned,
    standardized, and transformed data originating from the Bronze layer.

    The Silver layer acts as an intermediate layer between raw source data
    and the business-ready Gold layer. Its tables support data cleansing,
    standardization, validation, and integration.

CRM Tables:
    1. crm_cust_info:
       Stores standardized customer information, including customer IDs,
       names, marital status, gender, and creation date.

    2. crm_prd_info:
       Stores product information, including product identifiers, category
       IDs, names, costs, product lines, and validity dates.

    3. crm_sales_details:
       Stores sales transactions, customer and product references, order
       dates, shipping dates, due dates, sales amounts, quantities, and prices.

ERP Tables:
    4. erp_loc_a101:
       Stores standardized customer location and country information.

    5. erp_cust_az12:
       Stores customer identifiers, birth dates, and standardized gender data.

    6. erp_px_cat_g1v2:
       Stores product category, subcategory, and maintenance information.

Design Decisions:
    - Each table is created in the silver schema.
    - Existing tables are dropped before recreation to ensure a clean
      structure. This permanently removes their existing data and objects.
    - No primary keys, foreign keys, or additional constraints are defined
      in this script.
    - dwh_create_date is a data warehouse audit column. Its DEFAULT
      constraint assigns the current server date and time when an INSERT
      does not explicitly supply a value for this column.
    - DATETIME2 is used for the audit timestamp to provide date and time
      precision.
    - The default timestamp records the insertion time, not necessarily
      the original source creation time or the most recent update time.

Execution Flow:
    1. Check whether each Silver-layer table already exists.
    2. Drop the existing table when present.
    3. Create the table with its required columns and data types.
    4. Apply a default constraint to record the data warehouse insertion time.

Important Notes:
    - Run this script in the DataWarehouse database.
    - Ensure that the silver schema exists before executing the script.
    - Execute this script before running silver.load_silver.
    - Re-running the script removes existing Silver-layer data.
    - GO separates batches in SQL Server tools such as SSMS and sqlcmd.

================================================================================
*/

-- CRM: Standardized customer master data
IF OBJECT_ID('silver.crm_cust_info', 'U') IS NOT NULL
    DROP TABLE silver.crm_cust_info;
GO

CREATE TABLE silver.crm_cust_info (
    cst_id              INT,
    cst_key             NVARCHAR(50),
    cst_firstname       NVARCHAR(50),
    cst_lastname        NVARCHAR(50),
    cst_marital_status  NVARCHAR(50),
    cst_gndr            NVARCHAR(50),
    cst_create_date     DATE,
    dwh_create_date     DATETIME2 DEFAULT GETDATE()
);
GO

-- CRM: Product master data, including category mapping and validity period
IF OBJECT_ID('silver.crm_prd_info', 'U') IS NOT NULL
    DROP TABLE silver.crm_prd_info;
GO

CREATE TABLE silver.crm_prd_info (
    prd_id              INT,
    cat_id              NVARCHAR(50),
    prd_key             NVARCHAR(50),
    prd_nm              NVARCHAR(50),
    prd_cost            INT,
    prd_line            NVARCHAR(50),
    prd_start_dt        DATE,
    prd_end_dt          DATE,
    dwh_create_date     DATETIME2 DEFAULT GETDATE()
);
GO

-- CRM: Sales transactions with standardized dates and numeric measures
IF OBJECT_ID('silver.crm_sales_details', 'U') IS NOT NULL
    DROP TABLE silver.crm_sales_details;
GO

CREATE TABLE silver.crm_sales_details (
    sls_ord_num         NVARCHAR(50),
    sls_prd_key         NVARCHAR(50),
    sls_cust_id         INT,
    sls_order_dt        DATE,
    sls_ship_dt         DATE,
    sls_due_dt          DATE,
    sls_sales           INT,
    sls_quantity        INT,
    sls_price           INT,
    dwh_create_date     DATETIME2 DEFAULT GETDATE()
);
GO

-- ERP: Standardized customer location and country reference data
IF OBJECT_ID('silver.erp_loc_a101', 'U') IS NOT NULL
    DROP TABLE silver.erp_loc_a101;
GO

CREATE TABLE silver.erp_loc_a101 (
    cid                 NVARCHAR(50),
    cntry               NVARCHAR(50),
    dwh_create_date     DATETIME2 DEFAULT GETDATE()
);
GO

-- ERP: Customer birth dates and standardized gender information
IF OBJECT_ID('silver.erp_cust_az12', 'U') IS NOT NULL
    DROP TABLE silver.erp_cust_az12;
GO

CREATE TABLE silver.erp_cust_az12 (
    cid                 NVARCHAR(50),
    bdate               DATE,
    gen                 NVARCHAR(50),
    dwh_create_date     DATETIME2 DEFAULT GETDATE()
);
GO

-- ERP: Product category hierarchy and maintenance reference data
IF OBJECT_ID('silver.erp_px_cat_g1v2', 'U') IS NOT NULL
    DROP TABLE silver.erp_px_cat_g1v2;
GO

CREATE TABLE silver.erp_px_cat_g1v2 (
    id                  NVARCHAR(50),
    cat                 NVARCHAR(50),
    subcat              NVARCHAR(50),
    maintenance         NVARCHAR(50),
    dwh_create_date     DATETIME2 DEFAULT GETDATE()
);
GO
