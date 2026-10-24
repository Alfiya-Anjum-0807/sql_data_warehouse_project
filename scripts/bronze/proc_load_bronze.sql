/*
================================================================================
Procedure Name : bronze.load_bronze
Purpose        : Load raw CRM and ERP source data into the Bronze layer.

Description:
    This stored procedure loads data from six CSV files into their
    corresponding Bronze-layer tables in the DataWarehouse database.

    CRM source tables:
      1. bronze.crm_cust_info
      2. bronze.crm_prd_info
      3. bronze.crm_sales_details

    ERP source tables:
      4. bronze.erp_loc_a101
      5. bronze.erp_cust_az12
      6. bronze.erp_px_cat_g1v2

Execution Flow:
    1. Display messages indicating the start of Bronze-layer loading.
    2. Truncate each destination table to remove previously loaded data.
    3. Import the corresponding CSV file using BULK INSERT.
    4. Measure and display the loading duration for each table.
    5. Display the total duration for the entire loading process.
    6. Catch and display error details if an operation fails.

Usage Example:
    EXEC bronze.load_bronze;

Important Notes:
    - Execute this procedure in the DataWarehouse database.
    - Update the CSV file paths if the project directory changes.
    - SQL Server must be able to access the specified files. BULK INSERT
      reads files from the perspective of the SQL Server service or execution
      environment, not necessarily the desktop running SSMS.
    - The destination tables are truncated before loading. Existing data
      is removed and may be lost if the subsequent import fails.
    - The procedure assumes each CSV file has a header row and comma-separated
      fields.
    - Required permissions include appropriate table access and bulk-import
      permissions, as applicable to the SQL Server configuration.

================================================================================
*/

CREATE OR ALTER PROCEDURE bronze.load_bronze
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE
        @start_time      DATETIME,
        @end_time        DATETIME,
        @whole_start_time DATETIME,
        @whole_end_time   DATETIME;

    BEGIN TRY

        PRINT '=========================================================================================';
        PRINT 'Loading Bronze Layer';
        PRINT '=========================================================================================';

        SET @whole_start_time = GETDATE();

        PRINT '-----------------------------------------------------------------------------------------';
        PRINT 'Loading CRM Tables';
        PRINT '-----------------------------------------------------------------------------------------';

        -- CRM: Customer information
        SET @start_time = GETDATE();

        PRINT '>> Truncating Table: bronze.crm_cust_info';
        TRUNCATE TABLE bronze.crm_cust_info;

        PRINT '>> Inserting Data Into: bronze.crm_cust_info';
        BULK INSERT bronze.crm_cust_info
        FROM 'C:\Users\victus\OneDrive\Desktop\Projects\sql-data-warehouse-project\sql-data-warehouse-project\datasets\source_crm\cust_info.csv'
        WITH (
            FIRSTROW = 2,
            FIELDTERMINATOR = ',',
            TABLOCK
        );

        SET @end_time = GETDATE();

        PRINT '>> Load Duration: '
            + CAST(DATEDIFF(SECOND, @start_time, @end_time) AS NVARCHAR(20))
            + ' seconds';
        PRINT '----------------------------------------------------------------------';

        -- CRM: Product information
        SET @start_time = GETDATE();

        PRINT '>> Truncating Table: bronze.crm_prd_info';
        TRUNCATE TABLE bronze.crm_prd_info;

        PRINT '>> Inserting Data Into: bronze.crm_prd_info';
        BULK INSERT bronze.crm_prd_info
        FROM 'C:\Users\victus\OneDrive\Desktop\Projects\sql-data-warehouse-project\sql-data-warehouse-project\datasets\source_crm\prd_info.csv'
        WITH (
            FIRSTROW = 2,
            FIELDTERMINATOR = ',',
            TABLOCK
        );

        SET @end_time = GETDATE();

        PRINT '>> Load Duration: '
            + CAST(DATEDIFF(SECOND, @start_time, @end_time) AS NVARCHAR(20))
            + ' seconds';
        PRINT '----------------------------------------------------------------------';

        -- CRM: Sales transaction details
        SET @start_time = GETDATE();

        PRINT '>> Truncating Table: bronze.crm_sales_details';
        TRUNCATE TABLE bronze.crm_sales_details;

        PRINT '>> Inserting Data Into: bronze.crm_sales_details';
        BULK INSERT bronze.crm_sales_details
        FROM 'C:\Users\victus\OneDrive\Desktop\Projects\sql-data-warehouse-project\sql-data-warehouse-project\datasets\source_crm\sales_details.csv'
        WITH (
            FIRSTROW = 2,
            FIELDTERMINATOR = ',',
            TABLOCK
        );

        SET @end_time = GETDATE();

        PRINT '>> Load Duration: '
            + CAST(DATEDIFF(SECOND, @start_time, @end_time) AS NVARCHAR(20))
            + ' seconds';
        PRINT '----------------------------------------------------------------------';

        PRINT '-----------------------------------------------------------------------------------------';
        PRINT 'Loading ERP Tables';
        PRINT '-----------------------------------------------------------------------------------------';

        -- ERP: Customer location and country information
        SET @start_time = GETDATE();

        PRINT '>> Truncating Table: bronze.erp_loc_a101';
        TRUNCATE TABLE bronze.erp_loc_a101;

        PRINT '>> Inserting Data Into: bronze.erp_loc_a101';
        BULK INSERT bronze.erp_loc_a101
        FROM 'C:\Users\victus\OneDrive\Desktop\Projects\sql-data-warehouse-project\sql-data-warehouse-project\datasets\source_erp\LOC_A101.csv'
        WITH (
            FIRSTROW = 2,
            FIELDTERMINATOR = ',',
            TABLOCK
        );

        SET @end_time = GETDATE();

        PRINT '>> Load Duration: '
            + CAST(DATEDIFF(SECOND, @start_time, @end_time) AS NVARCHAR(20))
            + ' seconds';
        PRINT '----------------------------------------------------------------------';

        -- ERP: Customer birth dates and gender information
        SET @start_time = GETDATE();

        PRINT '>> Truncating Table: bronze.erp_cust_az12';
        TRUNCATE TABLE bronze.erp_cust_az12;

        PRINT '>> Inserting Data Into: bronze.erp_cust_az12';
        BULK INSERT bronze.erp_cust_az12
        FROM 'C:\Users\victus\OneDrive\Desktop\Projects\sql-data-warehouse-project\sql-data-warehouse-project\datasets\source_erp\CUST_AZ12.csv'
        WITH (
            FIRSTROW = 2,
            FIELDTERMINATOR = ',',
            TABLOCK
        );

        SET @end_time = GETDATE();

        PRINT '>> Load Duration: '
            + CAST(DATEDIFF(SECOND, @start_time, @end_time) AS NVARCHAR(20))
            + ' seconds';
        PRINT '----------------------------------------------------------------------';

        -- ERP: Product categories, subcategories, and maintenance information
        SET @start_time = GETDATE();

        PRINT '>> Truncating Table: bronze.erp_px_cat_g1v2';
        TRUNCATE TABLE bronze.erp_px_cat_g1v2;

        PRINT '>> Inserting Data Into: bronze.erp_px_cat_g1v2';
        BULK INSERT bronze.erp_px_cat_g1v2
        FROM 'C:\Users\victus\OneDrive\Desktop\Projects\sql-data-warehouse-project\sql-data-warehouse-project\datasets\source_erp\PX_CAT_G1V2.csv'
        WITH (
            FIRSTROW = 2,
            FIELDTERMINATOR = ',',
            TABLOCK
        );

        SET @end_time = GETDATE();

        PRINT '>> Load Duration: '
            + CAST(DATEDIFF(SECOND, @start_time, @end_time) AS NVARCHAR(20))
            + ' seconds';
        PRINT '----------------------------------------------------------------------';

        -- Calculate the total elapsed time for all six table loads.
        SET @whole_end_time = GETDATE();

        PRINT '>> Entire Load Duration of Bronze Loading: '
            + CAST(DATEDIFF(SECOND, @whole_start_time, @whole_end_time) AS NVARCHAR(20))
            + ' seconds';

        PRINT '----------------------------------------------------------------------';
        PRINT 'Bronze Layer Loading Completed Successfully';

    END TRY

    BEGIN CATCH

        -- Report the SQL Server error details to help diagnose load failures.
        PRINT '===================================================================';
        PRINT 'ERROR OCCURRED DURING BRONZE LAYER LOADING';
        PRINT 'Error Message: ' + ERROR_MESSAGE();
        PRINT 'Error Number: ' + CAST(ERROR_NUMBER() AS NVARCHAR(20));
        PRINT 'Error State: ' + CAST(ERROR_STATE() AS NVARCHAR(20));
        PRINT '===================================================================';

    END CATCH
END;
GO

-- Usage example: execute the procedure to reload all six Bronze tables.
EXEC bronze.load_bronze;
GO
