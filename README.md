# Sql_Data_Warehouse
A modern DWH using SQL Server, including ETL, data modelling, and analytics

**Data WareHouse and Analytics Project**
This project demonstrates a comprehensive data warehousing and analytics solution, from building a data Warehouse to generating actionable insights.

---**Project requirements**

**Building the Data Warehouse**
### Objective
Develop a modern data warehouse using SQL Server to consolidate sales data, enabling analytical reporting and informed decision-making.

### Specifications

- **Data Source**: Import data from two source systems (ERP and CRM) provided as csv files.
- **Data Quality**: Cleanse and resolve data quality issues prior to analytics.
- **Integration**: Combine both sources into a single, user-friendly data model designed for analytical queries.
- **Scope**: Focus on the latest dataset only; historization of data is not required.

**Documentation**: Provide clear documentation of the data model to support both business stakeholders and analytics teams.

<img width="712" height="317" alt="image" src="https://github.com/user-attachments/assets/2a72f1c7-e328-48fb-99c9-e7ce4c6bc939" />


### Architecture
The data architecture for this project follows Medallion Architecture **Bronze**, **Silver**, and **Gold** layers.

<img width="826" height="423" alt="image" src="https://github.com/user-attachments/assets/63925e92-ebf0-4c74-a45c-d5c211c2bef7" />

**Bronze Layer:** Stores raw data as-is from the source systems. Data is ingested from CSV Files into SQL Server Database.
**Silver Layer:** This layer includes data cleansing, standardization, and normalization processes to prepare data for analysis.
**Gold Layer:** Houses business-ready data modeled into a star schema required for reporting and analytics.

### Project Overview

**Design the architecture:** a modern data warehouse with three layers, bronze, silver and gold.
**Build the ETL pipelines:** load the source files and move the data through the layers.
**Model the data:** facts and dimensions, ready for reports.
**Analyze it:** answer business questions with SQL.

### License 
MIT.

### About Me
Hi, I'm Alfiya Anjum. I'm a student of IIT Jammu CSE'28.
