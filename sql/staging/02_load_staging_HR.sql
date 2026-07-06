-- ========================================
-- HR STAGING DATA LOAD SCRIPT
-- ========================================
-- This script loads data from raw_HR tables into stg_HR staging tables
-- with appropriate data cleaning, type conversion, and business logic

-- Step 1: Clear staging tables
-- ========================================

TRUNCATE TABLE stg_HR.stg_job_openings;
TRUNCATE TABLE stg_HR.stg_employees;
TRUNCATE TABLE stg_HR.stg_employee_monthly_snapshot;
TRUNCATE TABLE stg_HR.stg_job_posting_performance;
TRUNCATE TABLE stg_HR.stg_labor_category;
TRUNCATE TABLE stg_HR.stg_employment_type;
TRUNCATE TABLE stg_HR.stg_job_role;
TRUNCATE TABLE stg_HR.stg_education_level;
TRUNCATE TABLE stg_HR.stg_agency_labor_coverage;
TRUNCATE TABLE stg_HR.stg_employee_attrition;
TRUNCATE TABLE stg_HR.stg_department;

-- Step 2: Load Job Openings
-- ========================================

INSERT INTO stg_HR.stg_job_openings (
    opening_id,
    ntd_id,
    agency_name,
    position_title,
    position_description,
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
    salary_min_annual,
    salary_max_annual,
    posting_status,
    vacancy_reason,
    requirements_summary,
    education_required,
    benefits_summary,
    schedule,
    location_city,
    location_state
)
SELECT
    -- 1. Primary Key and Identifiers
    LEFT(NULLIF(TRIM([OpeningID]), ''), 100),
    LEFT(NULLIF(TRIM([NTD_ID]), ''), 50),
    LEFT(NULLIF(TRIM([AgencyName]), ''), 255),

    -- 2. Position Information
    LEFT(NULLIF(TRIM([PositionTitle]), ''), 255),
    LEFT(NULLIF(TRIM([PositionDescription]), ''), 8000),
    LEFT(NULLIF(TRIM([EmploymentType]), ''), 100),
    LEFT(NULLIF(TRIM([LaborCategory]), ''), 100),
    LEFT(NULLIF(TRIM([Department]), ''), 255),
    LEFT(NULLIF(TRIM([Mode]), ''), 20),
    LEFT(NULLIF(TRIM([ServiceType]), ''), 100),

    -- 3. Date Fields
    TRY_CAST(NULLIF(TRIM([PostingDate]), '') AS DATE),
    TRY_CAST(NULLIF(TRIM([ClosingDate]), '') AS DATE),
    TRY_CAST(NULLIF(TRIM([FilledDate]), '') AS DATE),

    -- 4. Numeric Counts
    TRY_CAST(TRY_CAST(NULLIF(TRIM([OpenPositions]), '') AS FLOAT) AS INTEGER),
    TRY_CAST(TRY_CAST(NULLIF(TRIM([HiredCount]), '') AS FLOAT) AS INTEGER),

    -- 5. Salary Information
    TRY_CAST(NULLIF(TRIM([SalaryMinHourly]), '') AS NUMERIC(18,2)),
    TRY_CAST(NULLIF(TRIM([SalaryMaxHourly]), '') AS NUMERIC(18,2)),
    TRY_CAST(NULLIF(TRIM([SalaryMinAnnual]), '') AS NUMERIC(18,2)),
    TRY_CAST(NULLIF(TRIM([SalaryMaxAnnual]), '') AS NUMERIC(18,2)),

    -- 6. Status and Reason Fields
    LEFT(NULLIF(TRIM([PostingStatus]), ''), 50),
    LEFT(NULLIF(TRIM([VacancyReason]), ''), 255),
    LEFT(NULLIF(TRIM([RequirementsSummary]), ''), 8000),
    LEFT(NULLIF(TRIM([EducationRequired]), ''), 100),
    LEFT(NULLIF(TRIM([BenefitsSummary]), ''), 8000),
    LEFT(NULLIF(TRIM([Schedule]), ''), 100),

    -- 7. Location Fields
    LEFT(NULLIF(TRIM([LocationCity]), ''), 100),
    LEFT(NULLIF(TRIM([LocationState]), ''), 20)

FROM raw_HR.job_openings
WHERE NULLIF(TRIM([OpeningID]), '') IS NOT NULL;

-- Step 3: Load Employees
-- ========================================

INSERT INTO stg_HR.stg_employees (
    employee_id,
    ntd_id,
    agency_name,
    first_name,
    last_name,
    full_name,
    employment_type,
    job_title,
    job_classification,
    labor_category,
    department,
    division,
    mode,
    service_type,
    hire_date,
    termination_date,
    salary_hourly,
    salary_annual,
    hours_per_week,
    hours_per_year,
    location_city,
    location_state,
    education_level,
    employment_status,
    years_of_service
)
SELECT
    -- 1. Primary Key and Identifiers
    LEFT(NULLIF(TRIM([EmployeeID]), ''), 100),
    LEFT(NULLIF(TRIM([NTD_ID]), ''), 50),
    LEFT(NULLIF(TRIM([AgencyName]), ''), 255),

    -- 2. Personal Information
    LEFT(NULLIF(TRIM([FirstName]), ''), 100),
    LEFT(NULLIF(TRIM([LastName]), ''), 100),
    LEFT(NULLIF(TRIM([FullName]), ''), 255),

    -- 3. Employment Classification
    LEFT(NULLIF(TRIM([EmploymentType]), ''), 100),
    LEFT(NULLIF(TRIM([JobTitle]), ''), 255),
    LEFT(NULLIF(TRIM([JobClassification]), ''), 100),
    LEFT(NULLIF(TRIM([LaborCategory]), ''), 100),
    LEFT(NULLIF(TRIM([Department]), ''), 255),
    LEFT(NULLIF(TRIM([Division]), ''), 255),
    LEFT(NULLIF(TRIM([Mode]), ''), 20),
    LEFT(NULLIF(TRIM([ServiceType]), ''), 100),

    -- 4. Employment Dates
    hire_date_calc,
    termination_date_calc,

    -- 5. Compensation and Hours
    TRY_CAST(NULLIF(TRIM([SalaryHourly]), '') AS NUMERIC(18,2)),
    TRY_CAST(NULLIF(TRIM([SalaryAnnual]), '') AS NUMERIC(18,2)),
    TRY_CAST(NULLIF(TRIM([HoursPerWeek]), '') AS NUMERIC(18,2)),
    TRY_CAST(NULLIF(TRIM([HoursPerYear]), '') AS NUMERIC(18,2)),

    -- 6. Location and Education
    LEFT(NULLIF(TRIM([LocationCity]), ''), 100),
    LEFT(NULLIF(TRIM([LocationState]), ''), 20),
    LEFT(NULLIF(TRIM([EducationLevel]), ''), 100),

    -- 7. Status and Tenure (derived from dates)
    LEFT(NULLIF(TRIM([EmploymentStatus]), ''), 50),
    years_of_service_calc

FROM raw_HR.employees
CROSS APPLY (
    -- Date parsing
    SELECT
        TRY_CAST(NULLIF(TRIM([HireDate]), '') AS DATE) AS hire_date_calc,
        TRY_CAST(NULLIF(TRIM([TerminationDate]), '') AS DATE) AS termination_date_calc
) dates
CROSS APPLY (
    -- Years of service calculation
    -- For active employees: years from hire date to today
    -- For terminated employees: years from hire date to termination date
    SELECT
        CASE
            WHEN dates.hire_date_calc IS NULL
                THEN NULL
            WHEN dates.termination_date_calc IS NOT NULL
                THEN CAST(DATEDIFF(DAY, dates.hire_date_calc, dates.termination_date_calc) AS NUMERIC(10,2)) / 365.25
            ELSE CAST(DATEDIFF(DAY, dates.hire_date_calc, CAST(GETDATE() AS DATE)) AS NUMERIC(10,2)) / 365.25
        END AS years_of_service_calc
) tenure
WHERE NULLIF(TRIM([EmployeeID]), '') IS NOT NULL;

-- Step 4: Load Employee Monthly Snapshots
-- ========================================

INSERT INTO stg_HR.stg_employee_monthly_snapshot (
    snapshot_id,
    snapshot_month,
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
    total_hours_worked,
    total_overtime_hours,
    total_paid_hours,
    average_hours_per_employee,
    turnover_count
)
SELECT
    -- 1. Identifiers
    CONCAT(
        LEFT(NULLIF(TRIM([NTD_ID]), ''), 50), '_',
        FORMAT(TRY_CAST(NULLIF(TRIM([SnapshotMonth]), '') AS DATE), 'yyyyMM'), '_',
        LEFT(NULLIF(TRIM([LaborCategory]), ''), 50)
    ),
    TRY_CAST(NULLIF(TRIM([SnapshotMonth]), '') AS DATE),
    YEAR(TRY_CAST(NULLIF(TRIM([SnapshotMonth]), '') AS DATE)),

    -- 2. Agency and Classification
    LEFT(NULLIF(TRIM([NTD_ID]), ''), 50),
    LEFT(NULLIF(TRIM([AgencyName]), ''), 255),
    LEFT(NULLIF(TRIM([LaborCategory]), ''), 100),
    LEFT(NULLIF(TRIM([Mode]), ''), 20),
    LEFT(NULLIF(TRIM([ServiceType]), ''), 100),
    LEFT(NULLIF(TRIM([EmploymentType]), ''), 100),
    LEFT(NULLIF(TRIM([Department]), ''), 255),

    -- 3. Metrics
    TRY_CAST(TRY_CAST(NULLIF(TRIM([EmployeeCount]), '') AS FLOAT) AS INTEGER),
    TRY_CAST(NULLIF(TRIM([AverageHourlyWage]), '') AS NUMERIC(18,2)),
    TRY_CAST(NULLIF(TRIM([TotalHoursWorked]), '') AS NUMERIC(18,2)),
    TRY_CAST(NULLIF(TRIM([TotalOvertimeHours]), '') AS NUMERIC(18,2)),
    TRY_CAST(NULLIF(TRIM([TotalPaidHours]), '') AS NUMERIC(18,2)),
    TRY_CAST(NULLIF(TRIM([AverageHoursPerEmployee]), '') AS NUMERIC(18,2)),
    TRY_CAST(TRY_CAST(NULLIF(TRIM([TurnoverCount]), '') AS FLOAT) AS INTEGER)

FROM raw_HR.employee_monthly_snapshot
WHERE NULLIF(TRIM([NTD_ID]), '') IS NOT NULL
  AND NULLIF(TRIM([SnapshotMonth]), '') IS NOT NULL;

-- Step 5: Load Job Posting Performance
-- ========================================

INSERT INTO stg_HR.stg_job_posting_performance (
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
    filled_percentage,
    applicant_count,
    applicant_to_hire_ratio,
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
    LEFT(NULLIF(TRIM([PositionTitle]), ''), 255),
    LEFT(NULLIF(TRIM([EmploymentType]), ''), 100),
    LEFT(NULLIF(TRIM([LaborCategory]), ''), 100),

    -- 2. Dates
    posting_date_calc,
    closing_date_calc,
    TRY_CAST(NULLIF(TRIM([FilledDate]), '') AS DATE),

    -- 3. Performance Metrics (with derived calculations)
    days_open_calc,
    open_positions_calc,
    hired_count_calc,
    filled_percentage_calc,
    applicant_count_calc,
    applicant_to_hire_ratio_calc,

    -- 4. Classification
    LEFT(NULLIF(TRIM([Mode]), ''), 20),
    LEFT(NULLIF(TRIM([ServiceType]), ''), 100),
    salary_midpoint_calc,
    LEFT(NULLIF(TRIM([PostingStatus]), ''), 50)

FROM raw_HR.job_posting_performance
CROSS APPLY (
    -- Date calculations
    SELECT
        TRY_CAST(NULLIF(TRIM([PostingDate]), '') AS DATE) AS posting_date_calc,
        TRY_CAST(NULLIF(TRIM([ClosingDate]), '') AS DATE) AS closing_date_calc
) dates_calc
CROSS APPLY (
    -- Days open calculation (from posting to closing or filled date)
    -- If filled date exists and is after posting, use that; otherwise use closing date
    SELECT
        CASE
            WHEN dates_calc.posting_date_calc IS NULL OR dates_calc.closing_date_calc IS NULL
                THEN NULL
            ELSE DATEDIFF(DAY, dates_calc.posting_date_calc, dates_calc.closing_date_calc)
        END AS days_open_calc,
        TRY_CAST(TRY_CAST(NULLIF(TRIM([OpenPositions]), '') AS FLOAT) AS INTEGER) AS open_positions_calc,
        TRY_CAST(TRY_CAST(NULLIF(TRIM([HiredCount]), '') AS FLOAT) AS INTEGER) AS hired_count_calc,
        TRY_CAST(TRY_CAST(NULLIF(TRIM([ApplicantCount]), '') AS FLOAT) AS INTEGER) AS applicant_count_calc
) metrics_calc
CROSS APPLY (
    -- Fill percentage: (Hired Count / Open Positions) * 100
    -- Clamped to 0-100 range
    SELECT
        CASE
            WHEN metrics_calc.open_positions_calc IS NULL OR metrics_calc.open_positions_calc = 0
                THEN NULL
            WHEN CAST(metrics_calc.hired_count_calc AS NUMERIC(18,2)) / metrics_calc.open_positions_calc * 100 > 100
                THEN 100.00
            WHEN CAST(metrics_calc.hired_count_calc AS NUMERIC(18,2)) / metrics_calc.open_positions_calc * 100 < 0
                THEN 0.00
            ELSE CAST(metrics_calc.hired_count_calc AS NUMERIC(18,2)) / metrics_calc.open_positions_calc * 100
        END AS filled_percentage_calc
) fill_calc
CROSS APPLY (
    -- Applicant to hire ratio
    -- Protects against division by zero
    SELECT
        CASE
            WHEN metrics_calc.hired_count_calc IS NULL OR metrics_calc.hired_count_calc = 0
                THEN NULL
            ELSE CAST(metrics_calc.applicant_count_calc AS NUMERIC(18,2)) / metrics_calc.hired_count_calc
        END AS applicant_to_hire_ratio_calc,
        TRY_CAST(NULLIF(TRIM([SalaryMinHourly]), '') AS NUMERIC(18,2)) AS salary_min_calc,
        TRY_CAST(NULLIF(TRIM([SalaryMaxHourly]), '') AS NUMERIC(18,2)) AS salary_max_calc
) ratio_calc
CROSS APPLY (
    -- Salary midpoint: (Min + Max) / 2
    SELECT
        CASE
            WHEN ratio_calc.salary_min_calc IS NULL OR ratio_calc.salary_max_calc IS NULL
                THEN NULL
            ELSE (ratio_calc.salary_min_calc + ratio_calc.salary_max_calc) / 2
        END AS salary_midpoint_calc
) salary_calc
WHERE NULLIF(TRIM([OpeningID]), '') IS NOT NULL;

-- Step 6: Load Labor Categories (Reference Data)
-- ========================================

INSERT INTO stg_HR.stg_labor_category (
    labor_category_code,
    labor_category_name,
    category_type,
    category_description,
    operator_status,
    is_active
)
SELECT DISTINCT
    LEFT(NULLIF(TRIM([LaborCategoryCode]), ''), 50),
    LEFT(NULLIF(TRIM([LaborCategoryName]), ''), 255),
    LEFT(NULLIF(TRIM([CategoryType]), ''), 100),
    LEFT(NULLIF(TRIM([CategoryDescription]), ''), 8000),
    LEFT(NULLIF(TRIM([OperatorStatus]), ''), 50),
    CAST(NULLIF(TRIM([IsActive]), '') AS BIT)

FROM raw_HR.labor_category
WHERE NULLIF(TRIM([LaborCategoryCode]), '') IS NOT NULL;

-- Step 7: Load Employment Types (Reference Data)
-- ========================================

INSERT INTO stg_HR.stg_employment_type (
    employment_type_code,
    employment_type_name,
    employment_type_description,
    is_full_time,
    is_active
)
SELECT DISTINCT
    LEFT(NULLIF(TRIM([EmploymentTypeCode]), ''), 50),
    LEFT(NULLIF(TRIM([EmploymentTypeName]), ''), 100),
    LEFT(NULLIF(TRIM([EmploymentTypeDescription]), ''), 8000),
    CAST(NULLIF(TRIM([IsFullTime]), '') AS BIT),
    CAST(NULLIF(TRIM([IsActive]), '') AS BIT)

FROM raw_HR.employment_type
WHERE NULLIF(TRIM([EmploymentTypeCode]), '') IS NOT NULL;

-- Step 8: Load Job Roles (Reference Data)
-- ========================================

INSERT INTO stg_HR.stg_job_role (
    position_title,
    position_description,
    labor_category,
    employment_type,
    operator_status,
    typical_salary_min,
    typical_salary_max,
    is_active
)
SELECT DISTINCT
    LEFT(NULLIF(TRIM([PositionTitle]), ''), 255),
    LEFT(NULLIF(TRIM([PositionDescription]), ''), 8000),
    LEFT(NULLIF(TRIM([LaborCategory]), ''), 100),
    LEFT(NULLIF(TRIM([EmploymentType]), ''), 100),
    LEFT(NULLIF(TRIM([OperatorStatus]), ''), 50),
    TRY_CAST(NULLIF(TRIM([TypicalSalaryMin]), '') AS NUMERIC(18,2)),
    TRY_CAST(NULLIF(TRIM([TypicalSalaryMax]), '') AS NUMERIC(18,2)),
    CAST(NULLIF(TRIM([IsActive]), '') AS BIT)

FROM raw_HR.job_role
WHERE NULLIF(TRIM([PositionTitle]), '') IS NOT NULL;

-- Step 9: Load Education Levels (Reference Data)
-- ========================================

INSERT INTO stg_HR.stg_education_level (
    education_level_code,
    education_level_name,
    education_level_description,
    hierarchy_level,
    is_active
)
SELECT DISTINCT
    LEFT(NULLIF(TRIM([EducationLevelCode]), ''), 50),
    LEFT(NULLIF(TRIM([EducationLevelName]), ''), 100),
    LEFT(NULLIF(TRIM([EducationLevelDescription]), ''), 8000),
    TRY_CAST(NULLIF(TRIM([HierarchyLevel]), '') AS INTEGER),
    CAST(NULLIF(TRIM([IsActive]), '') AS BIT)

FROM raw_HR.education_level
WHERE NULLIF(TRIM([EducationLevelCode]), '') IS NOT NULL;

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

-- Step 11: Load Employee Attrition Data
-- ========================================

INSERT INTO stg_HR.stg_employee_attrition (
    employee_id,
    ntd_id,
    agency_name,
    full_name,
    department,
    job_title,
    employment_type,
    labor_category,
    hire_date,
    termination_date,
    tenure_years,
    attrition_flag,
    attrition_reason,
    education_level,
    monthly_income,
    years_at_company,
    job_involvement,
    performance_rating,
    age
)
SELECT
    -- 1. Identifiers
    LEFT(NULLIF(TRIM([EmployeeID]), ''), 100),
    LEFT(NULLIF(TRIM([NTD_ID]), ''), 50),
    LEFT(NULLIF(TRIM([AgencyName]), ''), 255),
    LEFT(NULLIF(TRIM([FullName]), ''), 255),

    -- 2. Work Information
    LEFT(NULLIF(TRIM([Department]), ''), 255),
    LEFT(NULLIF(TRIM([JobTitle]), ''), 255),
    LEFT(NULLIF(TRIM([EmploymentType]), ''), 100),
    LEFT(NULLIF(TRIM([LaborCategory]), ''), 100),

    -- 3. Employment Timeline (with derived tenure)
    hire_date_calc,
    termination_date_calc,
    tenure_years_calc,

    -- 4. Attrition Information
    CAST(NULLIF(TRIM([AttritionFlag]), '') AS BIT),
    LEFT(NULLIF(TRIM([AttritionReason]), ''), 255),
    LEFT(NULLIF(TRIM([EducationLevel]), ''), 100),
    TRY_CAST(NULLIF(TRIM([MonthlyIncome]), '') AS NUMERIC(18,2)),
    TRY_CAST(NULLIF(TRIM([YearsAtCompany]), '') AS NUMERIC(10,2)),
    LEFT(NULLIF(TRIM([JobInvolvement]), ''), 50),
    TRY_CAST(NULLIF(TRIM([PerformanceRating]), '') AS NUMERIC(10,2)),

    -- 5. Demographics
    TRY_CAST(TRY_CAST(NULLIF(TRIM([Age]), '') AS FLOAT) AS INTEGER)

FROM raw_HR.employee_attrition
CROSS APPLY (
    -- Date parsing
    SELECT
        TRY_CAST(NULLIF(TRIM([HireDate]), '') AS DATE) AS hire_date_calc,
        TRY_CAST(NULLIF(TRIM([TerminationDate]), '') AS DATE) AS termination_date_calc
) dates
CROSS APPLY (
    -- Tenure calculation: derives years from hire/termination dates
    -- If termination date exists, use it; otherwise use current date
    SELECT
        CASE
            WHEN dates.hire_date_calc IS NULL
                THEN NULL
            WHEN dates.termination_date_calc IS NOT NULL
                THEN CAST(DATEDIFF(DAY, dates.hire_date_calc, dates.termination_date_calc) AS NUMERIC(10,2)) / 365.25
            ELSE CAST(DATEDIFF(DAY, dates.hire_date_calc, CAST(GETDATE() AS DATE)) AS NUMERIC(10,2)) / 365.25
        END AS tenure_years_calc
) tenure
WHERE NULLIF(TRIM([EmployeeID]), '') IS NOT NULL;

-- Step 12: Load Departments (Reference Data)
-- ========================================

INSERT INTO stg_HR.stg_department (
    department_code,
    department_name,
    ntd_labor_object_class,
    department_description,
    is_active
)
SELECT DISTINCT
    LEFT(NULLIF(TRIM([DepartmentCode]), ''), 50),
    LEFT(NULLIF(TRIM([DepartmentName]), ''), 255),
    LEFT(NULLIF(TRIM([NTDLaborObjectClass]), ''), 100),
    LEFT(NULLIF(TRIM([DepartmentDescription]), ''), 8000),
    CAST(NULLIF(TRIM([IsActive]), '') AS BIT)

FROM raw_HR.department
WHERE NULLIF(TRIM([DepartmentCode]), '') IS NOT NULL;

-- ========================================
-- Load Complete
-- ========================================
-- Summary statistics (uncomment to view after successful load):
--
-- SELECT 'stg_job_openings' AS table_name, COUNT(*) AS row_count FROM stg_HR.stg_job_openings
-- UNION ALL
-- SELECT 'stg_employees', COUNT(*) FROM stg_HR.stg_employees
-- UNION ALL
-- SELECT 'stg_employee_monthly_snapshot', COUNT(*) FROM stg_HR.stg_employee_monthly_snapshot
-- UNION ALL
-- SELECT 'stg_job_posting_performance', COUNT(*) FROM stg_HR.stg_job_posting_performance
-- UNION ALL
-- SELECT 'stg_labor_category', COUNT(*) FROM stg_HR.stg_labor_category
-- UNION ALL
-- SELECT 'stg_employment_type', COUNT(*) FROM stg_HR.stg_employment_type
-- UNION ALL
-- SELECT 'stg_job_role', COUNT(*) FROM stg_HR.stg_job_role
-- UNION ALL
-- SELECT 'stg_education_level', COUNT(*) FROM stg_HR.stg_education_level
-- UNION ALL
-- SELECT 'stg_agency_labor_coverage', COUNT(*) FROM stg_HR.stg_agency_labor_coverage
-- UNION ALL
-- SELECT 'stg_employee_attrition', COUNT(*) FROM stg_HR.stg_employee_attrition
-- UNION ALL
-- SELECT 'stg_department', COUNT(*) FROM stg_HR.stg_department
-- ORDER BY table_name;
