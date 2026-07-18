# 🚆 Transportation Data Warehouse

This repository implements a transportation data warehouse based on NTD (National Transit Database) source data, built as a **Database 2 course** project. It is designed to consolidate, store, and analyze transit-related data efficiently, providing a robust platform for data integration, reporting, and business intelligence.

The project covers both the **Transportation** and **HR** marts, using a layered data warehouse architecture with staging, dimensional modeling, and fact table loading. This implementation demonstrates a complete enterprise-style warehouse solution for transit analytics and decision support.

## Tech Stack

- **SQL Server / T-SQL** – primary implementation language for all ETL, DDL, and orchestration logic
- **CSV** – raw source data format for HR and transportation datasets
- **Power BI** – presentation layer artifacts are stored in the `PowerBI/` folder
- **DBML / diagrams** – data model definitions in `docs/diagrams/`

> No Node, Python, or Docker configuration is present in this repository; the project is implemented using SQL scripts and raw data files.

## Key Features

- ✅ **Master ETL orchestration** via `sql/master/00_master_etl_orchestration.sql` for common, transport, and HR marts
- 🧹 **Staging layer data integration** for HR and transportation NTD datasets, including cleansing and standardization
- 🧩 **Dimensional modeling** for shared dimensions such as date, agency, mode, service type, department, and employment type
- 📊 **Fact table population** for employee snapshots, job postings, and transportation operational measures
- 🛡️ **Data quality and audit support** with safe numeric conversion, lookup joins, and status reporting

## Warehouse Implementation Highlights

This project demonstrates practical warehouse design skills for a transportation-focused database assignment:

- Implemented **conformed dimensions** across multiple marts, including `DimDate`, `DimAgency`, `DimMode`, `DimServiceType`, `DimDepartment`, and `DimEmploymentType`
- Built **fact tables** for HR and transport reporting, including `FactEmployeeSnapshot`, `FactJobPosting`, and lifecycle tracking
- Used **slowly changing dimension (SCD) patterns** with effective/expiration date logic for time-sensitive dimension lookups
- Consolidated raw NTD source feeds into **staging tables** before dimension and fact loading for cleaner transformation logic
- Designed the warehouse for **BI-ready analysis**, with a clear star schema separation between dimensions and facts

## Getting Started

### Prerequisites

- Microsoft SQL Server (or compatible T-SQL runtime)
- Access to the raw CSV files under `DataSources/`
- A database named `TransportationDB` or an equivalent target database for schema deployment

### Installation

This repository does not use a package manager. To use it, deploy the SQL scripts into your SQL Server environment in the following order:

1. Create the database and required schemas (`dw_common`, `dw_transport`, `dw_HR`, `stg_HR`, `stg_transport`, etc.)
2. Execute common schema scripts in `sql/staging/` and `sql/dimensions/`
3. Execute staging load scripts in `sql/staging/`
4. Execute dimension load scripts in `sql/dimensions/`
5. Execute fact ETL scripts in `sql/facts/`
6. Execute the orchestration script in `sql/master/00_master_etl_orchestration.sql`

### Run the project

The primary orchestration procedure is defined in:

```sql
EXEC dw_transport.sp_Master_ETL_Load_All_Marts;
```

For targeted loads, use the specific sub-procedures:

```sql
EXEC dw_transport.sp_Master_ETL_Load_Common;
EXEC dw_transport.sp_Master_ETL_Load_Transport;
EXEC dw_transport.sp_Master_ETL_Load_HR;
```

## Project Structure

```text
Transportation-Data-Warehouse/
├── DataSources/                 # Raw CSV input data for HR and transport
│   ├── HR/
│   └── Transport/
├── docs/
│   └── diagrams/                # DBML diagrams and data model visuals
├── PowerBI/                     # Power BI report artifacts
├── sql/
│   ├── master/                  # Master orchestration scripts
│   │   └── 00_master_etl_orchestration.sql
│   ├── staging/                 # Staging schema and load scripts
│   │   ├── 00_common_schema.sql
│   │   ├── 01_stg_HR_DDL.sql
│   │   ├── 02_load_staging_HR.sql
│   │   ├── 02_load_staging_transport.sql
│   │   └── ...
│   ├── dimensions/              # Dimension DDL and dimension ETL scripts
│   │   ├── 03_dim_common_DDL.sql
│   │   ├── 04_load_dimensions_HR_ETL.sql
│   │   └── ...
│   └── facts/                   # Fact DDL and fact ETL scripts
│       ├── 05_fact_HR_DDL.sql
│       ├── 06_fact_HR_ETL.sql
│       └── ...
```

## Notes

- The repository is a course project focused on implementing a Kimball-style data warehouse architecture.
- The SQL scripts include both DDL definitions and procedural ETL logic for staging, dimensions, and facts.
- Source data is primarily HR employee and job posting records plus transportation operational datasets.
