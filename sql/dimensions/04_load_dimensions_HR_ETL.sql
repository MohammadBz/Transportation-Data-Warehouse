-- ============================================================
-- ETL: Load DimAgency
-- Source:
--   stg_HR.stg_job_openings
--   stg_HR.stg_employee_annual_snapshot
--
-- Type:
--   SCD Type 2
-- ============================================================


DECLARE @LoadDate DATE = GETDATE();



-- Close changed existing records

UPDATE tgt
SET
    ExpirationDate = DATEADD(DAY,-1,@LoadDate),
    CurrentFlag = 0

FROM dw_HR.DimAgency tgt

JOIN
(
    SELECT DISTINCT
        ntd_id,
        agency_name
    FROM stg_HR.stg_job_openings

) src

ON tgt.NTD_ID = src.ntd_id
AND tgt.CurrentFlag = 1


WHERE
    tgt.AgencyName <> src.agency_name;



-- Insert new agencies and new SCD versions

INSERT INTO dw_HR.DimAgency
(
    NTD_ID,
    AgencyName,
    EffectiveDate,
    ExpirationDate,
    CurrentFlag
)

SELECT DISTINCT

    src.ntd_id,

    src.agency_name,

    @LoadDate,

    '9999-12-31',

    1


FROM
(
    SELECT
        ntd_id,
        agency_name

    FROM stg_HR.stg_job_openings

    WHERE ntd_id IS NOT NULL


) src


LEFT JOIN dw_HR.DimAgency tgt

ON tgt.NTD_ID = src.ntd_id
AND tgt.CurrentFlag = 1


WHERE tgt.AgencyKey IS NULL

OR tgt.AgencyName <> src.agency_name;
-- ============================================================
-- ETL: Load DimMode
-- Source:
-- stg_HR.stg_job_openings
-- ============================================================


INSERT INTO dw_HR.DimMode
(
    ModeCode,
    ModeName
)

SELECT DISTINCT

    LEFT(Mode,10),

    LEFT(Mode,100)


FROM stg_HR.stg_job_openings src


WHERE src.Mode IS NOT NULL


AND NOT EXISTS
(
    SELECT 1

    FROM dw_HR.DimMode tgt

    WHERE tgt.ModeCode = src.Mode
);
-- ============================================================
-- ETL: Load DimServiceType
-- ============================================================


INSERT INTO dw_HR.DimServiceType
(
    ServiceTypeCode,
    ServiceTypeName
)

SELECT DISTINCT

    LEFT(ServiceType,10),

    LEFT(ServiceType,100)


FROM stg_HR.stg_job_openings src


WHERE ServiceType IS NOT NULL


AND NOT EXISTS
(
    SELECT 1

    FROM dw_HR.DimServiceType tgt

    WHERE tgt.ServiceTypeCode = src.ServiceType
);

-- ============================================================
-- ETL: Load DimEmploymentType
-- ============================================================


INSERT INTO dw_HR.DimEmploymentType
(
    EmploymentTypeCode,
    EmploymentTypeName,
    IsFullTime
)


SELECT DISTINCT

    LEFT(EmploymentType,50),

    LEFT(EmploymentType,100),


    CASE

        WHEN UPPER(EmploymentType) LIKE '%FULL%'
        THEN 1

        WHEN UPPER(EmploymentType) LIKE '%PART%'
        THEN 0

        ELSE NULL

    END


FROM stg_HR.stg_job_openings src


WHERE EmploymentType IS NOT NULL


AND NOT EXISTS
(
    SELECT 1

    FROM dw_HR.DimEmploymentType tgt

    WHERE tgt.EmploymentTypeCode = src.EmploymentType
);
-- ============================================================
-- ETL: Load DimDepartment
-- Source:
-- stg_HR.stg_department
-- ============================================================


INSERT INTO dw_HR.DimDepartment
(
    DepartmentCode,
    DepartmentName,
    NTDLaborObjectClass
)


SELECT DISTINCT


    LEFT(department,50),


    LEFT(department,255),


    LEFT(ntd_labor_object_class,100)


FROM stg_HR.stg_department src


WHERE department IS NOT NULL


AND NOT EXISTS
(
    SELECT 1

    FROM dw_HR.DimDepartment tgt

    WHERE tgt.DepartmentCode = src.department
);

-- ============================================================
-- ETL: Load DimJobRole
-- Source:
-- stg_HR.stg_job_role
--
-- Type:
-- SCD Type 2
-- ============================================================


DECLARE @LoadDate DATE = GETDATE();



-- Close changed roles

UPDATE tgt

SET

    ExpirationDate = DATEADD(DAY,-1,@LoadDate),

    CurrentFlag = 0


FROM dw_HR.DimJobRole tgt


JOIN stg_HR.stg_job_role src


ON tgt.PositionTitle = src.position_title


AND tgt.CurrentFlag = 1



WHERE

ISNULL(tgt.LaborCategory,'')
<>
ISNULL(src.labor_category,'');



-- Insert new roles

INSERT INTO dw_HR.DimJobRole
(
    PositionTitle,
    LaborCategory,
    EffectiveDate,
    ExpirationDate,
    CurrentFlag
)


SELECT DISTINCT


    src.position_title,

    src.labor_category,


    @LoadDate,

    '9999-12-31',

    1



FROM stg_HR.stg_job_role src


LEFT JOIN dw_HR.DimJobRole tgt


ON tgt.PositionTitle = src.position_title

AND tgt.CurrentFlag = 1



WHERE tgt.JobRoleKey IS NULL;

-- ============================================================
-- ETL: Load FactJobPosting
--
-- Source:
--   stg_HR.stg_job_openings
--
-- Grain:
--   One row per OpeningID
--
-- ============================================================


INSERT INTO dw_HR.FactJobPosting
(
    DateKey,

    AgencyKey,

    ModeKey,

    ServiceTypeKey,

    EmploymentTypeKey,

    DepartmentKey,

    JobRoleKey,


    OpeningID,


    OpenPositions,


    SalaryMinHourly,

    SalaryMaxHourly,

    SalaryMidHourly,


    DaysOpen,


    HiredCount,


    PostingStatus,

    VacancyReason
)



SELECT


    -- Date Lookup
    ISNULL(date_dim.DateKey,-1),


    -- Agency Lookup
    ISNULL(agency_dim.AgencyKey,-1),


    -- Mode Lookup
    ISNULL(mode_dim.ModeKey,-1),


    -- Service Type Lookup
    ISNULL(service_dim.ServiceTypeKey,-1),


    -- Employment Type Lookup
    ISNULL(emp_dim.EmploymentTypeKey,-1),


    -- Department Lookup
    ISNULL(dept_dim.DepartmentKey,-1),


    -- Job Role Lookup
    ISNULL(role_dim.JobRoleKey,-1),



    src.opening_id,



    src.open_positions,



    src.salary_min_hourly,

    src.salary_max_hourly,



    CASE

        WHEN src.salary_min_hourly IS NOT NULL

        AND src.salary_max_hourly IS NOT NULL

        THEN

            (
                src.salary_min_hourly
                +
                src.salary_max_hourly
            ) / 2

        ELSE NULL

    END,



    CASE

        WHEN src.posting_date IS NOT NULL

        AND src.closing_date IS NOT NULL

        THEN

            DATEDIFF
            (
                DAY,

                src.posting_date,

                src.closing_date
            )

        ELSE NULL

    END,



    src.hired_count,


    src.posting_status,


    src.vacancy_reason



FROM stg_HR.stg_job_openings src



LEFT JOIN dw_HR.DimDate date_dim

ON date_dim.FullDate = src.posting_date



LEFT JOIN dw_HR.DimAgency agency_dim

ON agency_dim.NTD_ID = src.ntd_id

AND agency_dim.CurrentFlag = 1



LEFT JOIN dw_HR.DimMode mode_dim

ON mode_dim.ModeCode = src.mode



LEFT JOIN dw_HR.DimServiceType service_dim

ON service_dim.ServiceTypeCode = src.service_type



LEFT JOIN dw_HR.DimEmploymentType emp_dim

ON emp_dim.EmploymentTypeCode = src.employment_type



LEFT JOIN dw_HR.DimDepartment dept_dim

ON dept_dim.DepartmentCode = src.department



LEFT JOIN dw_HR.DimJobRole role_dim

ON role_dim.PositionTitle = src.position_title

AND role_dim.CurrentFlag = 1;
-- ============================================================
-- ETL: Load FactJobPostingLifecycle
--
-- Source:
--   stg_HR.stg_job_posting_performance
--
-- Grain:
--   One row per OpeningID
--
-- Accumulating Snapshot Fact
--
-- ============================================================


INSERT INTO dw_HR.FactJobPostingLifecycle
(
    AgencyKey,

    ModeKey,

    ServiceTypeKey,

    EmploymentTypeKey,

    DepartmentKey,

    JobRoleKey,


    OpeningID,


    PostingDateKey,

    FilledDateKey,

    ClosingDateKey,


    DaysOpen,


    HiredCount,


    PostingStatus
)



SELECT



    ISNULL(agency_dim.AgencyKey,-1),


    ISNULL(mode_dim.ModeKey,-1),


    ISNULL(service_dim.ServiceTypeKey,-1),


    ISNULL(emp_dim.EmploymentTypeKey,-1),


    ISNULL(dept_dim.DepartmentKey,-1),


    ISNULL(role_dim.JobRoleKey,-1),



    src.opening_id,



    ISNULL(post_date.DateKey,-1),


    ISNULL(fill_date.DateKey,-1),


    ISNULL(close_date.DateKey,-1),



    src.days_open,


    src.hired_count,


    src.posting_status



FROM stg_HR.stg_job_posting_performance src



LEFT JOIN dw_HR.DimAgency agency_dim

ON agency_dim.NTD_ID = src.ntd_id

AND agency_dim.CurrentFlag = 1



LEFT JOIN dw_HR.DimMode mode_dim

ON mode_dim.ModeCode = src.mode



LEFT JOIN dw_HR.DimServiceType service_dim

ON service_dim.ServiceTypeCode = src.service_type



LEFT JOIN dw_HR.DimEmploymentType emp_dim

ON emp_dim.EmploymentTypeCode = src.employment_type



LEFT JOIN dw_HR.DimDepartment dept_dim

ON dept_dim.DepartmentCode = src.department



LEFT JOIN dw_HR.DimJobRole role_dim

ON role_dim.PositionTitle = src.position_title

AND role_dim.CurrentFlag = 1



LEFT JOIN dw_HR.DimDate post_date

ON post_date.FullDate = src.posting_date



LEFT JOIN dw_HR.DimDate fill_date

ON fill_date.FullDate = src.filled_date



LEFT JOIN dw_HR.DimDate close_date

ON close_date.FullDate = src.closing_date;
-- ============================================================
-- ETL: Load FactEmployeeSnapshot
--
-- Source:
--   stg_HR.stg_employee_annual_snapshot
--
-- Grain:
--   Year x Agency x Labor Category
--   x Employment Type x Mode
--   x Service Type x Department
--   x Job Role
--
-- Type:
--   Periodic Snapshot Fact
--
-- ============================================================


INSERT INTO dw_HR.FactEmployeeSnapshot
(
    DateKey,

    AgencyKey,

    ModeKey,

    ServiceTypeKey,

    EmploymentTypeKey,

    DepartmentKey,

    JobRoleKey,


    EmployeeCount,

    AverageHourlyWage,

    TotalHoursWorked
)



SELECT



    -- ========================================================
    -- Date Lookup
    -- Snapshot is annual
    -- ========================================================

    ISNULL(date_dim.DateKey,-1),



    -- ========================================================
    -- Dimension Lookups
    -- ========================================================

    ISNULL(agency_dim.AgencyKey,-1),


    ISNULL(mode_dim.ModeKey,-1),


    ISNULL(service_dim.ServiceTypeKey,-1),


    ISNULL(emp_dim.EmploymentTypeKey,-1),


    ISNULL(dept_dim.DepartmentKey,-1),


    ISNULL(role_dim.JobRoleKey,-1),



    -- ========================================================
    -- Measures
    -- ========================================================

    src.employee_count,


    src.average_hourly_wage,


    src.total_hours_worked



FROM stg_HR.stg_employee_annual_snapshot src



-- ============================================================
-- Date Dimension
--
-- SnapshotYear -> DateKey
--
-- Uses first day of year
-- ============================================================

LEFT JOIN dw_HR.DimDate date_dim

ON date_dim.CalendarYear = src.snapshot_year

AND date_dim.MonthNumber = 1



-- ============================================================
-- Agency Dimension
-- ============================================================

LEFT JOIN dw_HR.DimAgency agency_dim

ON agency_dim.NTD_ID = src.ntd_id

AND agency_dim.CurrentFlag = 1



-- ============================================================
-- Mode Dimension
-- ============================================================

LEFT JOIN dw_HR.DimMode mode_dim

ON mode_dim.ModeCode = src.mode



-- ============================================================
-- Service Type Dimension
-- ============================================================

LEFT JOIN dw_HR.DimServiceType service_dim

ON service_dim.ServiceTypeCode = src.service_type

-- ============================================================
-- Employment Type Dimension
-- ============================================================

LEFT JOIN dw_HR.DimEmploymentType emp_dim

ON emp_dim.EmploymentTypeCode = src.employment_type

-- ============================================================
-- Department Dimension
-- ============================================================

LEFT JOIN dw_HR.DimDepartment dept_dim

ON dept_dim.DepartmentCode = src.department

-- ============================================================
-- Job Role Dimension
-- ============================================================

LEFT JOIN dw_HR.DimJobRole role_dim

ON role_dim.PositionTitle = src.labor_category

AND role_dim.CurrentFlag = 1;

-- ============================================================
-- ETL: Load FactAgencyLaborCoverage
--
-- Type:
--   Factless Fact
--
-- Source:
--   stg_HR.stg_employee_annual_snapshot
--
-- Grain:
--   Year x Agency x Department
--   x Mode x ServiceType
--   x EmploymentType
--
-- Purpose:
--   Identify workforce coverage provided by agencies
--
-- ============================================================

INSERT INTO dw_HR.FactAgencyLaborCoverage
(
    DateKey,

    AgencyKey,

    DepartmentKey,

    ModeKey,

    ServiceTypeKey,

    EmploymentTypeKey
)

SELECT DISTINCT

    -- ========================================================
    -- Date Lookup
    -- Annual snapshot
    -- ========================================================
    ISNULL(date_dim.DateKey,-1),
    -- ========================================================
    -- Dimension Keys
    -- ========================================================

    ISNULL(agency_dim.AgencyKey,-1),


    ISNULL(dept_dim.DepartmentKey,-1),


    ISNULL(mode_dim.ModeKey,-1),


    ISNULL(service_dim.ServiceTypeKey,-1),


    ISNULL(emp_dim.EmploymentTypeKey,-1)
FROM stg_HR.stg_employee_annual_snapshot src

-- ============================================================
-- Date Dimension
-- Snapshot year -> First day of year
-- ============================================================

LEFT JOIN dw_HR.DimDate date_dim

ON date_dim.CalendarYear = src.snapshot_year

AND date_dim.MonthNumber = 1

-- ============================================================
-- Agency Dimension
-- ============================================================

LEFT JOIN dw_HR.DimAgency agency_dim

ON agency_dim.NTD_ID = src.ntd_id

AND agency_dim.CurrentFlag = 1

-- ============================================================
-- Department Dimension
-- ============================================================

LEFT JOIN dw_HR.DimDepartment dept_dim

ON dept_dim.DepartmentCode = src.department
-- ============================================================
-- Mode Dimension
-- ============================================================

LEFT JOIN dw_HR.DimMode mode_dim

ON mode_dim.ModeCode = src.mode

-- ============================================================
-- Service Type Dimension
-- ============================================================

LEFT JOIN dw_HR.DimServiceType service_dim

ON service_dim.ServiceTypeCode = src.service_type

-- ============================================================
-- Employment Type Dimension
-- ============================================================

LEFT JOIN dw_HR.DimEmploymentType emp_dim

ON emp_dim.EmploymentTypeCode = src.employment_type;
