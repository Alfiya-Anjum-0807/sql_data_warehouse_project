/*
================================================================================
Script Name : CreateBronzeTables.sql
Purpose     : Create the Bronze-layer tables for the DataWarehouse database.

Description :
    This script creates six tables in the bronze schema to store raw data
    extracted from CRM (Customer Relationship Management) and ERP
    (Enterprise Resource Planning) source systems.

    CRM source tables:
      1. crm_cust_info     - Customer information, including names, status,
                             gender, and creation date.
      2. crm_prd_info      - Product details, costs, product lines, and
                             product validity dates.
      3. crm_sales_details - Sales transaction details, including orders,
                             customers, products, shipping dates, quantities,
                             prices, and sales amounts.

    ERP source tables:
      4. erp_loc_a101      - Customer location and country information.
      5. erp_cust_az12     - Customer birth dates and gender information.
      6. erp_px_cat_g1v2   - Product categories, subcategories, and
                             maintenance information.

Execution Flow:
    1. Check whether each table already exists in the bronze schema.
    2. Drop an existing table to avoid conflicts during recreation.
    3. Create the table with the specified columns and data types.

Important Notes:
    - Run this script in the DataWarehouse database.
    - Existing tables are dropped and recreated, so any data stored in them
      will be permanently lost.
    - No primary keys, foreign keys, or additional constraints are defined
      because these tables serve as raw-data landing tables.
    - Source data types and formats may require validation and conversion
      during subsequent Silver-layer processing.
    - GO separates batches in SQL Server tools such as SSMS and sqlcmd.

================================================================================
*/

-- CRM: Customer master data
IF OBJECT_ID('bronze.crm_cust_info', 'U') IS NOT NULL
    DROP TABLE bronze.crm_cust_info;
GO

CREATE TABLE bronze.crm_cust_info (
    cst_id              INT,
    cst_key             NVARCHAR(50),
    cst_firstname       NVARCHAR(50),
    cst_lastname        NVARCHAR(50),
    cst_marital_status  NVARCHAR(50),
    cst_gndr            NVARCHAR(50),
    cst_create_date     DATE
);
GO

-- CRM: Product master data and validity period
IF OBJECT_ID('bronze.crm_prd_info', 'U') IS NOT NULL
    DROP TABLE bronze.crm_prd_info;
GO

CREATE TABLE bronze.crm_prd_info (
    prd_id       INT,
    prd_key      NVARCHAR(50),
    prd_nm       NVARCHAR(50),
    prd_cost     INT,
    prd_line     NVARCHAR(50),
    prd_start_dt DATETIME,
    prd_end_dt   DATETIME
);
GO

-- CRM: Sales transactions and order-related details
IF OBJECT_ID('bronze.crm_sales_details', 'U') IS NOT NULL
    DROP TABLE bronze.crm_sales_details;
GO

CREATE TABLE bronze.crm_sales_details (
    sls_ord_num  NVARCHAR(50),
    sls_prd_key  NVARCHAR(50),
    sls_cust_id  INT,
    sls_order_id INT,
    sls_ship_dt  INT,
    sls_due_dt   INT,
    sls_sales    INT,
    sls_quantity INT,
    sls_price    INT
);
GO

-- ERP: Customer location and country reference data
IF OBJECT_ID('bronze.erp_loc_a101', 'U') IS NOT NULL
    DROP TABLE bronze.erp_loc_a101;
GO

CREATE TABLE bronze.erp_loc_a101 (
    cid   NVARCHAR(50),
    cntry NVARCHAR(50)
);
GO

-- ERP: Customer birth date and gender reference data
IF OBJECT_ID('bronze.erp_cust_az12', 'U') IS NOT NULL
    DROP TABLE bronze.erp_cust_az12;
GO

CREATE TABLE bronze.erp_cust_az12 (
    cid   NVARCHAR(50),
    bdate DATE,
    gen   NVARCHAR(50)
);
GO

-- ERP: Product category hierarchy and maintenance information
IF OBJECT_ID('bronze.erp_px_cat_g1v2', 'U') IS NOT NULL
    DROP TABLE bronze.erp_px_cat_g1v2;
GO

CREATE TABLE bronze.erp_px_cat_g1v2 (
    id          NVARCHAR(50),
    cat         NVARCHAR(50),
    subcat      NVARCHAR(50),
    maintenance NVARCHAR(50)
);
GO
