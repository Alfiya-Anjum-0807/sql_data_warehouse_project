/*
================================================================================
Script Name : CreateGoldViews.sql
Purpose     : Create the Gold-layer dimension and fact views for analytics.

Description:
    The Gold layer provides business-ready data using a dimensional model.
    This script creates two dimension views and one fact view by combining
    cleaned data from the Silver layer.

Views Created:
    1. gold.dim_customers
       Creates the customer dimension by combining CRM customer information
       with ERP birth-date, gender, and country information.

       - Generates a surrogate customer key using ROW_NUMBER().
       - Exposes customer identifiers and descriptive attributes.
       - Uses CRM gender when available; otherwise, falls back to ERP gender.
       - Uses LEFT JOINs to retain customers even when matching ERP records
         are unavailable.

    2. gold.dim_products
       Creates the product dimension by combining CRM product information
       with ERP product category details.

       - Generates a surrogate product key using ROW_NUMBER().
       - Includes product, category, subcategory, cost, and product-line data.
       - Filters out historical product records by retaining products whose
         end date is NULL.

    3. gold.fact_sales
       Creates the sales fact view by combining sales transactions with
       customer and product dimension keys.

       - Includes order identifiers, customer and product keys, dates,
         sales amounts, quantities, and prices.
       - Uses LEFT JOINs to retain sales records even when matching dimension
         records are unavailable.

Execution Flow:
    1. Drop existing Gold views when present.
    2. Create the customer dimension.
    3. Create the product dimension.
    4. Create the sales fact view using the two dimension views.

Important Notes:
    - Execute this script in the DataWarehouse database.
    - The gold schema and referenced Silver-layer tables must already exist.
    - Views store query definitions rather than materializing data by default.
    - ROW_NUMBER() generates surrogate keys dynamically. These keys are not
      guaranteed to remain stable if the underlying data or ordering changes.
    - The current product filter retains records with a NULL end date.
    - Dropping and recreating views can affect dependent database objects
      and permissions associated with the views.

================================================================================
*/

-- =============================================================================
-- Dimension: Customers
-- Combines CRM customer attributes with ERP gender, birth date, and country.
-- =============================================================================

IF OBJECT_ID('gold.dim_customers', 'V') IS NOT NULL
    DROP VIEW gold.dim_customers;
GO

CREATE VIEW gold.dim_customers AS
SELECT
    ROW_NUMBER() OVER (ORDER BY ci.cst_id) AS customer_key, -- Surrogate key
    ci.cst_id AS customer_id,
    ci.cst_key AS customer_number,
    ci.cst_firstname AS first_name,
    ci.cst_lastname AS last_name,
    la.cntry AS country,
    ci.cst_marital_status AS marital_status,

    -- CRM is the primary source for gender; ERP provides a fallback.
    CASE
        WHEN ci.cst_gndr <> 'n/a' THEN ci.cst_gndr
        ELSE COALESCE(ca.gen, 'n/a')
    END AS gender,

    ca.bdate AS birthdate,
    ci.cst_create_date AS create_date

FROM silver.crm_cust_info AS ci
LEFT JOIN silver.erp_cust_az12 AS ca
    ON ci.cst_key = ca.cid
LEFT JOIN silver.erp_loc_a101 AS la
    ON ci.cst_key = la.cid;
GO


-- =============================================================================
-- Dimension: Products
-- Combines CRM product details with ERP category and subcategory information.
-- =============================================================================

IF OBJECT_ID('gold.dim_products', 'V') IS NOT NULL
    DROP VIEW gold.dim_products;
GO

CREATE VIEW gold.dim_products AS
SELECT
    ROW_NUMBER() OVER (
        ORDER BY pn.prd_start_dt, pn.prd_key
    ) AS product_key, -- Surrogate key

    pn.prd_id AS product_id,
    pn.prd_key AS product_number,
    pn.prd_nm AS product_name,
    pn.cat_id AS category_id,
    pc.cat AS category,
    pc.subcat AS subcategory,
    pc.maintenance,
    pn.prd_cost AS cost,
    pn.prd_line AS product_line,
    pn.prd_start_dt AS start_date

FROM silver.crm_prd_info AS pn
LEFT JOIN silver.erp_px_cat_g1v2 AS pc
    ON pn.cat_id = pc.id

-- Exclude historical versions and retain currently active product records.
WHERE pn.prd_end_dt IS NULL;
GO


-- =============================================================================
-- Fact: Sales
-- Combines sales transactions with the corresponding customer and product keys.
-- =============================================================================

IF OBJECT_ID('gold.fact_sales', 'V') IS NOT NULL
    DROP VIEW gold.fact_sales;
GO

CREATE VIEW gold.fact_sales AS
SELECT
    sd.sls_ord_num AS order_number,
    pr.product_key,
    cu.customer_key,
    sd.sls_order_dt AS order_date,
    sd.sls_ship_dt AS shipping_date,
    sd.sls_due_dt AS due_date,
    sd.sls_sales AS sales_amount,
    sd.sls_quantity AS quantity,
    sd.sls_price AS price

FROM silver.crm_sales_details AS sd
LEFT JOIN gold.dim_products AS pr
    ON sd.sls_prd_key = pr.product_number
LEFT JOIN gold.dim_customers AS cu
    ON sd.sls_cust_id = cu.customer_id;
GO

-- Usage examples: query the Gold-layer views after creation.
-- SELECT TOP 10 * FROM gold.dim_customers;
-- SELECT TOP 10 * FROM gold.dim_products;
-- SELECT TOP 10 * FROM gold.fact_sales;
