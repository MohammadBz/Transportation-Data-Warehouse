-- ========================================
-- HR STAGING DATA LOAD SCRIPT
-- ========================================
-- This script loads data from raw_HR tables into stg_HR staging tables
-- with appropriate data cleaning, type conversion, and business logic




-- stg_job_openings
--        <- synthetic_ntd_job_openings_2014_2024.xlsx
--        -> FactJobPosting
--
-- stg_employee_annual_snapshot
--        <- Employee files (2014-2024)
--        -> FactEmployeeSnapshot
--
-- stg_job_posting_performance
--        <- synthetic_ntd_job_openings_2014_2024.xlsx
--        -> FactJobPostingLifecycle
--
-- stg_job_role
--        <- synthetic_ntd_job_openings_2014_2024.xlsx
--        -> DimJobRole
--
-- stg_department
--        <- synthetic_ntd_job_openings_2014_2024.xlsx
--        -> DimDepartment
--
-- stg_employment_type
--        <- Employee files + Job Openings
--        -> DimEmploymentType
--
-- stg_labor_category
--        <- Employee files + Job Openings
--        -> DimLaborCategory
--
-- stg_agency_labor_coverage
--        <- Employee files + Job Openings
--        -> FactAgencyLaborCoverage
--
-- ============================================================



-- Step 1: Clear staging tables
-- ========================================

TRUNCATE TABLE stg_HR.stg_job_openings;

TRUNCATE TABLE stg_HR.stg_employee_annual_snapshot;
TRUNCATE TABLE stg_HR.stg_job_posting_performance;
TRUNCATE TABLE stg_HR.stg_labor_category;
TRUNCATE TABLE stg_HR.stg_employment_type;
TRUNCATE TABLE stg_HR.stg_job_role;
TRUNCATE TABLE stg_HR.stg_agency_labor_coverage;
TRUNCATE TABLE stg_HR.stg_department;

-- Step 2: Load Job Openings
-- ========================================
-- ========================================
-- Load Job Openings Staging Table
-- ========================================
-- Grain:
-- One row per job opening

INSERT INTO stg_HR.stg_job_openings (
    opening_id,
    ntd_id,
    agency_name,

    position_title,

    employment_type,
    labor_category,
    department,

    mode,
    service_type,

    posting_date,
    closing_date,
    filled_date,

    open_positions,
    hired_count,

    salary_min_hourly,
    salary_max_hourly,

    posting_status,
    vacancy_reason,

    location_city,
    location_state
)

SELECT

    -- 1. Identifiers
    LEFT(NULLIF(TRIM([OpeningID]), ''), 100),

    LEFT(NULLIF(TRIM([NTD_ID]), ''), 50),

    LEFT(NULLIF(TRIM([AgencyName]), ''), 255),


    -- 2. Position Information
    LEFT(NULLIF(TRIM([PositionTitle]), ''), 255),

    LEFT(NULLIF(TRIM([EmploymentType]), ''), 100),

    LEFT(NULLIF(TRIM([NTDLaborObjectClass]), ''), 100),

    LEFT(NULLIF(TRIM([Department]), ''), 255),


    -- 3. Transportation Classification
    LEFT(NULLIF(TRIM([ModeName]), ''), 20),

    LEFT(NULLIF(TRIM([TypeOfServiceName]), ''), 100),


    -- 4. Dates
    TRY_CAST(NULLIF(TRIM([PostingDate]), '') AS DATE),

    TRY_CAST(NULLIF(TRIM([ClosingDate]), '') AS DATE),

    TRY_CAST(NULLIF(TRIM([FilledDate]), '') AS DATE),


    -- 5. Counts
    TRY_CAST(
        TRY_CAST(NULLIF(TRIM([OpenPositions]), '') AS FLOAT)
        AS INTEGER
    ),

    TRY_CAST(
        TRY_CAST(NULLIF(TRIM([HiredCount]), '') AS FLOAT)
        AS INTEGER
    ),


    -- 6. Salary
    TRY_CAST(
        NULLIF(TRIM([SalaryMinHourly]), '')
        AS NUMERIC(18,2)
    ),

    TRY_CAST(
        NULLIF(TRIM([SalaryMaxHourly]), '')
        AS NUMERIC(18,2)
    ),


    -- 7. Status
    LEFT(NULLIF(TRIM([PostingStatus]), ''), 50),

    LEFT(NULLIF(TRIM([VacancyReason]), ''), 255),


    -- 8. Location
    LEFT(NULLIF(TRIM([City]), ''), 100),

    LEFT(NULLIF(TRIM([State]), ''), 20)


FROM raw_HR.job_openings

WHERE NULLIF(TRIM([OpeningID]), '') IS NOT NULL;

-- Step 3: Load Employee Annual Snapshots
-- ========================================
-- Grain:
-- One row per year per agency per labor category
-- per employment type per mode per service type

-- ========================================
-- Load Employee Annual Snapshot Staging
-- ========================================
-- Grain:
-- One row per year per agency
-- per labor category
-- per employment type
-- per mode per service type

INSERT INTO stg_HR.stg_employee_annual_snapshot
(
    snapshot_id,

    snapshot_year,

    ntd_id,
    agency_name,

    labor_category,

    mode,
    service_type,

    employment_type,

    department,

    employee_count,

    average_hourly_wage,

    total_hours_worked
)

SELECT

    -- 1. Snapshot Identifier
    CONCAT(
        LEFT(NULLIF(TRIM([NTD_ID]), ''), 50),
        '_',
        CAST([ReportYear] AS VARCHAR(4)),
        '_',
        LEFT(NULLIF(TRIM([LaborCategory]), ''), 100)
    ),


    -- 2. Annual Snapshot Year
    [ReportYear],


    -- 3. Agency
    LEFT(NULLIF(TRIM([NTD_ID]), ''), 50),

    LEFT(NULLIF(TRIM([AgencyName]), ''), 255),


    -- 4. Labor Classification
    LEFT(NULLIF(TRIM([LaborCategory]), ''), 100),


    -- 5. Transportation
    LEFT(NULLIF(TRIM([Mode]), ''), 20),

    LEFT(NULLIF(TRIM([ServiceType]), ''), 100),


    -- 6. Employment Type
    LEFT(NULLIF(TRIM([EmploymentType]), ''), 100),


    -- 7. Department
    LEFT(NULLIF(TRIM([Department]), ''), 255),


    -- 8. Employee Count
    TRY_CAST(
        TRY_CAST(NULLIF(TRIM([EmployeeCount]), '') AS FLOAT)
        AS INTEGER
    ),


    -- 9. Wage
    TRY_CAST(
        NULLIF(TRIM([AverageHourlyWage]), '')
        AS NUMERIC(18,2)
    ),


    -- 10. Hours
    TRY_CAST(
        NULLIF(TRIM([TotalHoursWorked]), '')
        AS NUMERIC(18,2)
    )


FROM raw_HR.employee_annual_snapshot


WHERE NULLIF(TRIM([NTD_ID]), '') IS NOT NULL
AND [ReportYear] IS NOT NULL;
-- Step 5: Load Job Posting Performance
-- ========================================
-- ========================================
-- Load Job Posting Performance Staging
-- ========================================
-- Grain:
-- One row per OpeningID
-- Used for FactJobPostingLifecycle

INSERT INTO stg_HR.stg_job_posting_performance
(
    opening_id,

    ntd_id,
    agency_name,

    position_title,

    employment_type,

    labor_category,

    posting_date,
    closing_date,
    filled_date,

    days_open,

    open_positions,
    hired_count,

    mode,
    service_type,

    salary_midpoint_hourly,

    posting_status
)

SELECT

    -- 1. Identifiers
    LEFT(NULLIF(TRIM([OpeningID]), ''), 100),

    LEFT(NULLIF(TRIM([NTD_ID]), ''), 50),

    LEFT(NULLIF(TRIM([AgencyName]), ''), 255),


    -- 2. Position
    LEFT(NULLIF(TRIM([PositionTitle]), ''), 255),

    LEFT(NULLIF(TRIM([EmploymentType]), ''), 100),

    LEFT(NULLIF(TRIM([NTDLaborObjectClass]), ''), 100),


    -- 3. Dates
    TRY_CAST(NULLIF(TRIM([PostingDate]), '') AS DATE),

    TRY_CAST(NULLIF(TRIM([ClosingDate]), '') AS DATE),

    TRY_CAST(NULLIF(TRIM([FilledDate]), '') AS DATE),


    -- 4. Days Open
    CASE
        WHEN TRY_CAST(NULLIF(TRIM([PostingDate]), '') AS DATE) IS NULL
            THEN NULL

        WHEN TRY_CAST(NULLIF(TRIM([FilledDate]), '') AS DATE) IS NOT NULL
            THEN DATEDIFF(
                DAY,
                TRY_CAST(NULLIF(TRIM([PostingDate]), '') AS DATE),
                TRY_CAST(NULLIF(TRIM([FilledDate]), '') AS DATE)
            )

        WHEN TRY_CAST(NULLIF(TRIM([ClosingDate]), '') AS DATE) IS NOT NULL
            THEN DATEDIFF(
                DAY,
                TRY_CAST(NULLIF(TRIM([PostingDate]), '') AS DATE),
                TRY_CAST(NULLIF(TRIM([ClosingDate]), '') AS DATE)
            )

        ELSE NULL
    END,


    -- 5. Hiring Metrics
    TRY_CAST(
        TRY_CAST(NULLIF(TRIM([OpenPositions]), '') AS FLOAT)
        AS INTEGER
    ),

    TRY_CAST(
        TRY_CAST(NULLIF(TRIM([HiredCount]), '') AS FLOAT)
        AS INTEGER
    ),


    -- 6. Transportation Classification
    LEFT(NULLIF(TRIM([ModeName]), ''), 20),

    LEFT(NULLIF(TRIM([TypeOfServiceName]), ''), 100),


    -- 7. Salary Midpoint
    CASE
        WHEN TRY_CAST(NULLIF(TRIM([SalaryMinHourly]), '') AS NUMERIC(18,2)) IS NULL
          OR TRY_CAST(NULLIF(TRIM([SalaryMaxHourly]), '') AS NUMERIC(18,2)) IS NULL

        THEN NULL

        ELSE
        (
            TRY_CAST(NULLIF(TRIM([SalaryMinHourly]), '') AS NUMERIC(18,2))
            +
            TRY_CAST(NULLIF(TRIM([SalaryMaxHourly]), '') AS NUMERIC(18,2))
        ) / 2
    END,


    -- 8. Status
    LEFT(NULLIF(TRIM([PostingStatus]), ''), 50)


FROM raw_HR.job_openings


WHERE NULLIF(TRIM([OpeningID]), '') IS NOT NULL;
-- Step 6: Load Labor Categories (Reference Data)
-- ========================================

-- ========================================
-- Load Labor Category Staging
-- ========================================
-- Grain:
-- One row per unique labor category

INSERT INTO stg_HR.stg_labor_category
(
    labor_category_code,
    labor_category_name,
    is_active
)
SELECT DISTINCT

    -- Use labor category value as code
    LEFT(
        NULLIF(TRIM([NTDLaborObjectClass]), ''),
        50
    ),
    -- Labor category name
    LEFT(
        NULLIF(TRIM([NTDLaborObjectClass]), ''),
        255
    ),
    -- Active flag
    CAST(1 AS BIT)
FROM raw_HR.job_openings


WHERE NULLIF(TRIM([NTDLaborObjectClass]), '') IS NOT NULL;

-- Load Employment Type Staging
-- ========================================
-- Grain:
-- One row per unique employment type

INSERT INTO stg_HR.stg_employment_type
(
    employment_type_code,
    employment_type_name,
    employment_type_description,
    is_full_time,
    is_active
)

SELECT DISTINCT
    -- Employment type code
    LEFT(
        NULLIF(TRIM([EmploymentType]), ''),
        50
    ),
    -- Employment type name
    LEFT(
        NULLIF(TRIM([EmploymentType]), ''),
        100
    ),
    -- No description available in source
    NULL,
    -- Full time flag derived from value
    CASE
        WHEN UPPER(TRIM([EmploymentType])) LIKE '%FULL%'
            THEN CAST(1 AS BIT)

        ELSE CAST(0 AS BIT)
    END,
    -- All source values are considered active
    CAST(1 AS BIT)
FROM raw_HR.job_openings
WHERE NULLIF(TRIM([EmploymentType]), '') IS NOT NULL;
-- ========================================
-- Load Job Role Staging
-- ========================================
-- Grain:
-- One row per unique position title

INSERT INTO stg_HR.stg_job_role
(
    position_title,
    labor_category,
    employment_type,
    is_active
)

SELECT DISTINCT

    -- Position title
    LEFT(NULLIF(TRIM([PositionTitle]), ''), 255),


    -- Labor category
    LEFT(NULLIF(TRIM([NTDLaborObjectClass]), ''), 100),


    -- Employment type
    LEFT(NULLIF(TRIM([EmploymentType]), ''), 100),


    -- Active flag
    CAST(1 AS BIT)


FROM raw_HR.job_openings


WHERE NULLIF(TRIM([PositionTitle]), '') IS NOT NULL;
-- Step 10: Load Agency Labor Coverage
-- ========================================

INSERT INTO stg_HR.stg_agency_labor_coverage (
    coverage_id,
    ntd_id,
    agency_name,
    labor_category,
    mode,
    service_type,
    employment_type,
    effective_date,
    end_date,
    is_active
)
SELECT DISTINCT
    CONCAT(
        LEFT(NULLIF(TRIM([NTD_ID]), ''), 50), '_',
        LEFT(NULLIF(TRIM([LaborCategory]), ''), 50), '_',
        LEFT(NULLIF(TRIM([Mode]), ''), 20)
    ),
    LEFT(NULLIF(TRIM([NTD_ID]), ''), 50),
    LEFT(NULLIF(TRIM([AgencyName]), ''), 255),
    LEFT(NULLIF(TRIM([LaborCategory]), ''), 100),
    LEFT(NULLIF(TRIM([Mode]), ''), 20),
    LEFT(NULLIF(TRIM([ServiceType]), ''), 100),
    LEFT(NULLIF(TRIM([EmploymentType]), ''), 100),
    TRY_CAST(NULLIF(TRIM([EffectiveDate]), '') AS DATE),
    TRY_CAST(NULLIF(TRIM([EndDate]), '') AS DATE),
    CAST(NULLIF(TRIM([IsActive]), '') AS BIT)

FROM raw_HR.agency_labor_coverage
WHERE NULLIF(TRIM([NTD_ID]), '') IS NOT NULL;
-- ========================================
-- Load Department Staging
-- ========================================
-- Grain:
-- One row per unique department

INSERT INTO stg_HR.stg_department
(
    department_code,
    department_name,
    ntd_labor_object_class,
    is_active
)

SELECT DISTINCT

    -- Department code
    LEFT(
        NULLIF(TRIM([Department]), ''),
        50
    ),
    -- Department name
    LEFT(
        NULLIF(TRIM([Department]), ''),
        255
    ),
    -- Labor object classification
    LEFT(
        NULLIF(TRIM([NTDLaborObjectClass]), ''),
        100
    ),
    -- Active flag
    CAST(1 AS BIT)
FROM raw_HR.job_openings
WHERE NULLIF(TRIM([Department]), '') IS NOT NULL;
-- ========================================
-- Load Complete
-- ========================================
-- Summary statistics (uncomment to view after successful load):
--
-- SELECT 'stg_job_openings' AS table_name, COUNT(*) AS row_count FROM stg_HR.stg_job_openings
-- UNION ALL

-- SELECT 'stg_employee_annual_snapshot', COUNT(*) FROM stg_HR.stg_employee_annual_snapshot
-- UNION ALL
-- SELECT 'stg_job_posting_performance', COUNT(*) FROM stg_HR.stg_job_posting_performance
-- UNION ALL
-- SELECT 'stg_labor_category', COUNT(*) FROM stg_HR.stg_labor_category
-- UNION ALL
-- SELECT 'stg_employment_type', COUNT(*) FROM stg_HR.stg_employment_type
-- UNION ALL
-- SELECT 'stg_job_role', COUNT(*) FROM stg_HR.stg_job_role
-- UNION ALL
-- SELECT 'stg_agency_labor_coverage', COUNT(*) FROM stg_HR.stg_agency_labor_coverage
-- UNION ALL
-- SELECT 'stg_department', COUNT(*) FROM stg_HR.stg_department
-- ORDER BY table_name;
