Script Name : CreateDataWarehouse.sql
Purpose     : Create the DataWarehouse database and its three schemas:
Bronze, Silver, and Gold.

Description :
This script prepares the initial structure of a data warehouse in
Microsoft SQL Server. It creates a dedicated database and separates
data into three schemas representing different stages of data processing.

Schema responsibilities:
  1. bronze - Stores raw data ingested from source systems with minimal
              transformation.
  2. silver - Stores cleaned, standardized, and validated data.
  3. gold   - Stores business-ready, aggregated, and analytical data
              intended for reporting and dashboards.

Execution Flow:
1. Switch to the master database.
2. Check whether DataWarehouse already exists.
3. If it exists, force active connections to close by switching the
database to SINGLE_USER mode and rolling back active transactions,
then drop the existing database.
4. Create a fresh DataWarehouse database.
5. Switch to the newly created database.
6. Create the Bronze, Silver, and Gold schemas.

Important Notes:
- Run this script using an account with sufficient database permissions.
- **WARNING**: If DataWarehouse already exists, this script permanently
drops it, including its tables, data, and other database objects.
Back up any required data before execution.
- GO is a batch separator recognized by SQL Server tools such as
SQL Server Management Studio (SSMS) and sqlcmd; it is not a T-SQL
statement.
- The script is intended for Microsoft SQL Server, not MySQL or Oracle.
- Re-running the script recreates the database from scratch.

================================================================================
*/

USE master;
GO

-- Recreate the database to ensure a clean environment for the warehouse setup.
IF EXISTS (SELECT 1 FROM sys.databases WHERE name = 'DataWarehouse')
BEGIN
    -- Disconnect active sessions and roll back their uncommitted transactions
    -- so the existing database can be dropped without connection conflicts.
    ALTER DATABASE DataWarehouse SET SINGLE_USER WITH ROLLBACK IMMEDIATE;

    DROP DATABASE DataWarehouse;
END;
GO

CREATE DATABASE DataWarehouse;
GO

USE DataWarehouse;
GO

-- Bronze: stores raw data as it arrives from source systems.
CREATE SCHEMA bronze;
GO

-- Silver: stores cleaned, standardized, and transformed data.
CREATE SCHEMA silver;
GO

-- Gold: stores business-ready data for reporting and analytics.
CREATE SCHEMA gold;
GO
