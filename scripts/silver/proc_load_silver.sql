/*
================================================================================
Procedure Name : silver.load_silver
Purpose        : Transform and load cleaned data from the Bronze layer into
                 the Silver layer of the DataWarehouse database.

Description:
    This stored procedure processes six CRM and ERP tables. It cleans,
    standardizes, validates, and transforms raw Bronze-layer data before
    loading it into the corresponding Silver-layer tables.

CRM Transformations:
    1. crm_cust_info:
       - Removes duplicate customer IDs, keeping the latest record.
       - Removes leading and trailing spaces from customer names.
       - Standardizes marital status and gender values.

    2. crm_prd_info:
       - Derives category IDs and product keys for joining with other tables.
       - Replaces missing product costs with zero.
       - Standardizes product line values.
       - Derives product validity end dates using LEAD().

    3. crm_sales_details:
       - Converts valid date values into DATE format.
       - Recalculates inconsistent sales amounts and invalid prices.

ERP Transformations:
    4. erp_cust_az12:
       - Removes the NAS prefix from customer IDs where applicable.
       - Replaces future birth dates with NULL.
       - Standardizes gender values.

    5. erp_loc_a101:
       - Removes hyphens from customer IDs.
       - Standardizes country names and handles missing values.

    6. erp_px_cat_g1v2:
       - Transfers product category data into the Silver layer.

Execution Flow:
    1. Display the start of Silver-layer loading.
    2. Process CRM tables, followed by ERP tables.
    3. Truncate each destination table before loading transformed data.
    4. Display progress messages and the duration of each table load.
    5. Display the total duration of Silver-layer loading.
    6. Catch and display SQL Server error details if a step fails.

Usage Example:
    EXEC silver.load_silver;

Important Notes:
    - Execute this procedure in the DataWarehouse database.
    - Destination tables must exist before executing this procedure.
    - The procedure truncates destination tables before inserting new data.
    - If an error occurs, the procedure reports it but does not automatically
      roll back previously completed table loads.
    - Verify that bronze.crm_sales_details contains the sls_order_dt column
      referenced by this procedure.

================================================================================
*/

CREATE OR ALTER PROCEDURE silver.load_silver
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE
        @start_time       DATETIME,
        @end_time         DATETIME,
        @whole_start_time DATETIME,
        @whole_end_time   DATETIME;

    BEGIN TRY

        SET @whole_start_time = GETDATE();

        PRINT '=========================================================================================';
        PRINT 'Loading Silver Layer';
        PRINT '=========================================================================================';

        -- =====================================================================
        -- CRM TABLES
        -- =====================================================================

        PRINT '-----------------------------------------------------------------------------------------';
        PRINT 'Loading CRM Tables';
        PRINT '-----------------------------------------------------------------------------------------';

        -- CRM: Customer information
        SET @start_time = GETDATE();

        PRINT '>> Truncating Table: silver.crm_cust_info';
        TRUNCATE TABLE silver.crm_cust_info;

        PRINT '>> Inserting Data Into: silver.crm_cust_info';

        INSERT INTO silver.crm_cust_info (
            cst_id,
            cst_key,
            cst_firstname,
            cst_lastname,
            cst_marital_status,
            cst_gndr,
            cst_create_date
        )
        SELECT
            cst_id,
            cst_key,
            TRIM(cst_firstname) AS cst_firstname,
            TRIM(cst_lastname) AS cst_lastname,
            CASE
                WHEN UPPER(TRIM(cst_marital_status)) = 'S' THEN 'Single'
                WHEN UPPER(TRIM(cst_marital_status)) = 'M' THEN 'Married'
                ELSE 'n/a'
            END AS cst_marital_status,
            CASE
                WHEN UPPER(TRIM(cst_gndr)) = 'F' THEN 'Female'
                WHEN UPPER(TRIM(cst_gndr)) = 'M' THEN 'Male'
                ELSE 'n/a'
            END AS cst_gndr,
            cst_create_date
        FROM (
            -- Retain the most recent record for each non-null customer ID.
            SELECT *,
                ROW_NUMBER() OVER (
                    PARTITION BY cst_id
                    ORDER BY cst_create_date DESC
                ) AS flag_last
            FROM bronze.crm_cust_info
            WHERE cst_id IS NOT NULL
        ) AS t
        WHERE flag_last = 1;

        SET @end_time = GETDATE();

        PRINT '>> Load Duration: '
            + CAST(DATEDIFF(SECOND, @start_time, @end_time) AS NVARCHAR(20))
            + ' seconds';
        PRINT '----------------------------------------------------------------------';


        -- CRM: Product information
        SET @start_time = GETDATE();

        PRINT '>> Truncating Table: silver.crm_prd_info';
        TRUNCATE TABLE silver.crm_prd_info;

        PRINT '>> Inserting Data Into: silver.crm_prd_info';

        INSERT INTO silver.crm_prd_info (
            prd_id,
            cat_id,
            prd_key,
            prd_nm,
            prd_cost,
            prd_line,
            prd_start_dt,
            prd_end_dt
        )
        SELECT
            prd_id,
            REPLACE(SUBSTRING(prd_key, 1, 5), '-', '_') AS cat_id,
            SUBSTRING(prd_key, 7, LEN(prd_key)) AS prd_key,
            prd_nm,
            ISNULL(prd_cost, 0) AS prd_cost,
            CASE UPPER(TRIM(prd_line))
                WHEN 'M' THEN 'Mountain'
                WHEN 'R' THEN 'Road'
                WHEN 'S' THEN 'Other Sales'
                WHEN 'T' THEN 'Touring'
                ELSE 'n/a'
            END AS prd_line,
            CAST(prd_start_dt AS DATE) AS prd_start_dt,

            -- The next start date minus one day defines the current
            -- product record's validity end date.
            CAST(
                LEAD(prd_start_dt) OVER (
                    PARTITION BY prd_key
                    ORDER BY prd_start_dt
                ) - 1 AS DATE
            ) AS prd_end_dt
        FROM bronze.crm_prd_info;

        SET @end_time = GETDATE();

        PRINT '>> Load Duration: '
            + CAST(DATEDIFF(SECOND, @start_time, @end_time) AS NVARCHAR(20))
            + ' seconds';
        PRINT '----------------------------------------------------------------------';


        -- CRM: Sales transaction details
        SET @start_time = GETDATE();

        PRINT '>> Truncating Table: silver.crm_sales_details';
        TRUNCATE TABLE silver.crm_sales_details;

        PRINT '>> Inserting Data Into: silver.crm_sales_details';

        INSERT INTO silver.crm_sales_details (
            sls_ord_num,
            sls_prd_key,
            sls_cust_id,
            sls_order_dt,
            sls_ship_dt,
            sls_due_dt,
            sls_sales,
            sls_quantity,
            sls_price
        )
        SELECT
            sls_ord_num,
            sls_prd_key,
            sls_cust_id,

            -- Convert YYYYMMDD values to DATE; zero or invalid-length
            -- values are treated as missing dates.
            CASE
                WHEN sls_order_dt = 0 OR LEN(sls_order_dt) <> 8 THEN NULL
                ELSE CAST(CAST(sls_order_dt AS VARCHAR(8)) AS DATE)
            END AS sls_order_dt,

            CASE
                WHEN sls_ship_dt = 0 OR LEN(sls_ship_dt) <> 8 THEN NULL
                ELSE CAST(CAST(sls_ship_dt AS VARCHAR(8)) AS DATE)
            END AS sls_ship_dt,

            CASE
                WHEN sls_due_dt = 0 OR LEN(sls_due_dt) <> 8 THEN NULL
                ELSE CAST(CAST(sls_due_dt AS VARCHAR(8)) AS DATE)
            END AS sls_due_dt,

            -- Recalculate sales when missing or inconsistent with
            -- quantity multiplied by the absolute unit price.
            CASE
                WHEN sls_sales IS NULL
                     OR sls_sales <> sls_quantity * ABS(sls_price)
                THEN sls_quantity * ABS(sls_price)
                ELSE sls_sales
            END AS sls_sales,

            sls_quantity,

            -- Derive the unit price from sales and quantity when
            -- the original price is missing or non-positive.
            CASE
                WHEN sls_price IS NULL OR sls_price <= 0
                THEN sls_sales / NULLIF(sls_quantity, 0)
                ELSE sls_price
            END AS sls_price

        FROM bronze.crm_sales_details;

        SET @end_time = GETDATE();

        PRINT '>> Load Duration: '
            + CAST(DATEDIFF(SECOND, @start_time, @end_time) AS NVARCHAR(20))
            + ' seconds';
        PRINT '----------------------------------------------------------------------';


        -- =====================================================================
        -- ERP TABLES
        -- =====================================================================

        PRINT '-----------------------------------------------------------------------------------------';
        PRINT 'Loading ERP Tables';
        PRINT '-----------------------------------------------------------------------------------------';

        -- ERP: Customer birth dates and gender
        SET @start_time = GETDATE();

        PRINT '>> Truncating Table: silver.erp_cust_az12';
        TRUNCATE TABLE silver.erp_cust_az12;

        PRINT '>> Inserting Data Into: silver.erp_cust_az12';

        INSERT INTO silver.erp_cust_az12 (
            cid,
            bdate,
            gen
        )
        SELECT
            CASE
                WHEN cid LIKE 'NAS%' THEN SUBSTRING(cid, 4, LEN(cid))
                ELSE cid
            END AS cid,

            CASE
                WHEN bdate > GETDATE() THEN NULL
                ELSE bdate
            END AS bdate,

            CASE
                WHEN UPPER(TRIM(gen)) IN ('F', 'FEMALE') THEN 'Female'
                WHEN UPPER(TRIM(gen)) IN ('M', 'MALE') THEN 'Male'
                ELSE 'n/a'
            END AS gen

        FROM bronze.erp_cust_az12;

        SET @end_time = GETDATE();

        PRINT '>> Load Duration: '
            + CAST(DATEDIFF(SECOND, @start_time, @end_time) AS NVARCHAR(20))
            + ' seconds';
        PRINT '----------------------------------------------------------------------';


        -- ERP: Customer location and country
        SET @start_time = GETDATE();

        PRINT '>> Truncating Table: silver.erp_loc_a101';
        TRUNCATE TABLE silver.erp_loc_a101;

        PRINT '>> Inserting Data Into: silver.erp_loc_a101';

        INSERT INTO silver.erp_loc_a101 (
            cid,
            cntry
        )
        SELECT
            REPLACE(cid, '-', '') AS cid,

            CASE
                WHEN TRIM(cntry) = 'DE' THEN 'Germany'
                WHEN TRIM(cntry) IN ('US', 'USA') THEN 'United States'
                WHEN TRIM(cntry) = '' OR cntry IS NULL THEN 'n/a'
                ELSE TRIM(cntry)
            END AS cntry

        FROM bronze.erp_loc_a101;

        SET @end_time = GETDATE();

        PRINT '>> Load Duration: '
            + CAST(DATEDIFF(SECOND, @start_time, @end_time) AS NVARCHAR(20))
            + ' seconds';
        PRINT '----------------------------------------------------------------------';


        -- ERP: Product category and subcategory information
        SET @start_time = GETDATE();

        PRINT '>> Truncating Table: silver.erp_px_cat_g1v2';
        TRUNCATE TABLE silver.erp_px_cat_g1v2;

        PRINT '>> Inserting Data Into: silver.erp_px_cat_g1v2';

        INSERT INTO silver.erp_px_cat_g1v2 (
            id,
            cat,
            subcat,
            maintenance
        )
        SELECT
            id,
            cat,
            subcat,
            maintenance
        FROM bronze.erp_px_cat_g1v2;

        SET @end_time = GETDATE();

        PRINT '>> Load Duration: '
            + CAST(DATEDIFF(SECOND, @start_time, @end_time) AS NVARCHAR(20))
            + ' seconds';
        PRINT '----------------------------------------------------------------------';


        -- Report the total elapsed time for all Silver-layer table loads.
        SET @whole_end_time = GETDATE();

        PRINT '=========================================================================================';
        PRINT 'Silver Layer Loading Completed Successfully';
        PRINT '>> Total Silver Load Duration: '
            + CAST(
                DATEDIFF(SECOND, @whole_start_time, @whole_end_time)
                AS NVARCHAR(20)
              )
            + ' seconds';
        PRINT '=========================================================================================';

    END TRY

    BEGIN CATCH

        -- Display diagnostic details for the failed loading operation.
        PRINT '=========================================================================================';
        PRINT 'ERROR OCCURRED DURING SILVER LAYER LOADING';
        PRINT 'Error Message: ' + ERROR_MESSAGE();
        PRINT 'Error Number: ' + CAST(ERROR_NUMBER() AS NVARCHAR(20));
        PRINT 'Error State: ' + CAST(ERROR_STATE() AS NVARCHAR(20));
        PRINT 'Error Line: ' + CAST(ERROR_LINE() AS NVARCHAR(20));
        PRINT '=========================================================================================';

    END CATCH
END;
GO

-- Usage example: execute the procedure to reload all Silver-layer tables.
EXEC silver.load_silver;
GO
