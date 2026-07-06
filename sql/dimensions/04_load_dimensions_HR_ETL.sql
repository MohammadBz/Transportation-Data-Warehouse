-- ============================================================
-- FILE:   04_load_dimensions_HR_ETL.sql
-- SCHEMA: dw_HR
-- DESC:   ETL procedures to load all dimensions from staging.
--         Implements Kimball-style SCD logic with unknown sentinels.
--
-- EXECUTION ORDER: Run after 03_dim_HR_DDL.sql
--
-- DIMENSION LOADING PATTERNS:
--   1. DimAgency          - SCD Type 2; merge on NTD_ID
--   2. DimMode            - Static; pre-populated; no ETL needed
--   3. DimServiceType     - Static; pre-populated; no ETL needed
--   4. DimEmploymentType  - Static reference; insert-or-ignore
--   5. DimDepartment      - Static reference; insert-or-ignore
--   6. DimJobRole         - SCD Type 2; merge on PositionTitle
--   7. DimEducation       - Static reference; insert-or-ignore
--
-- IMPROVEMENTS IN THIS VERSION:
--   - Fixed NULL handling in change detection (uses ISNULL)
--   - Removed redundant GROUP BY operations
--   - Added composite key change detection
--   - Improved NULL-safe comparisons
--   - Enhanced error handling with proper transaction rollback checks
--   - Better debug output and diagnostics
--   - Prevents cascade failures in master orchestration
--   - Only updates Type 1 when data actually changes
--   - Added ETL audit logging table for data quality tracking
--   - Added duplicate business key detection
--   - Optimized change detection with HASHBYTES
--   - FIXED: Duplicate detection logic using ROW_NUMBER()
--   - IMPROVED: Numeric comparisons done directly
--   - ADDED: Unique constraints to staging tables
--
-- ============================================================

USE [TransportationDB];
GO

-- ============================================================
-- ETL Audit & Data Quality Logging Table (HR-specific)
-- ============================================================

IF NOT EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.TABLES
              WHERE TABLE_SCHEMA = 'dw_HR' AND TABLE_NAME = 'etl_load_audit')
BEGIN
    CREATE TABLE dw_HR.etl_load_audit (
        audit_id INT IDENTITY(1,1) PRIMARY KEY,
        procedure_name NVARCHAR(128) NOT NULL,
        load_date DATE NOT NULL,
        load_start_time DATETIME2 NOT NULL,
        load_end_time DATETIME2 NULL,
        rows_processed INT DEFAULT 0,
        rows_inserted INT DEFAULT 0,
        rows_updated INT DEFAULT 0,
        rows_deleted INT DEFAULT 0,
        duplicate_count INT DEFAULT 0,
        validation_errors NVARCHAR(MAX),
        status NVARCHAR(20) NOT NULL DEFAULT 'IN_PROGRESS', -- IN_PROGRESS, SUCCESS, FAILED
        error_message NVARCHAR(MAX),
        created_at DATETIME2 DEFAULT SYSDATETIME()
    );

    CREATE INDEX IX_etl_audit_procedure_date ON dw_HR.etl_load_audit(procedure_name, load_date DESC);
END
GO

-- ============================================================
-- STEP 0: Load DimDate (Static Dimension)
--         Pre-computed calendar dimension from source data
-- ============================================================

CREATE OR ALTER PROCEDURE dw_HR.sp_load_dim_date
    @LoadDate DATE = NULL,
    @Debug BIT = 0
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @AuditId INT;
    DECLARE @StartTime DATETIME2 = SYSDATETIME();
    DECLARE @RowsInserted INT = 0;
    DECLARE @ErrorMsg NVARCHAR(MAX) = NULL;

    IF @LoadDate IS NULL
        SET @LoadDate = CAST(GETDATE() AS DATE);

    -- Log start of audit
    INSERT INTO dw_HR.etl_load_audit (
        procedure_name, load_date, load_start_time, status
    )
    VALUES ('sp_load_dim_date', @LoadDate, @StartTime, 'IN_PROGRESS');
    SET @AuditId = SCOPE_IDENTITY();

    BEGIN TRY
        -- Load DimDate from raw source, skipping rows that already exist
        -- DimDate is static (no SCD needed), so we only insert new dates
        INSERT INTO dw_HR.DimDate (
            DateKey,
            FullDate,
            DayLongName, DayShortName,
            MonthLongName, MonthShortName,
            CalendarDay, CalendarDayInWeek,
            CalendarWeek, CalendarWeekStartDateId, CalendarWeekEndDateId,
            CalendarMonth, CalendarMonthStartDateId, CalendarMonthEndDateId,
            CalendarNumberOfDaysInMonth, CalendarDayInMonth,
            CalendarQuarter, CalendarQuarterStartDateId, CalendarQuarterEndDateId,
            CalendarNumberOfDaysInQuarter, CalendarDayInQuarter,
            CalendarYear, CalendarYearStartDateId, CalendarYearEndDateId,
            CalendarNumberOfDaysInYear
        )
        SELECT
            src.date_key,
            src.full_date,
            src.day_long_name, src.day_short_name,
            src.month_long_name, src.month_short_name,
            src.calendar_day, src.calendar_day_in_week,
            src.calendar_week, src.calendar_week_start_date_id, src.calendar_week_end_date_id,
            src.calendar_month, src.calendar_month_start_date_id, src.calendar_month_end_date_id,
            src.calendar_number_of_days_in_month, src.calendar_day_in_month,
            src.calendar_quarter, src.calendar_quarter_start_date_id, src.calendar_quarter_end_date_id,
            src.calendar_number_of_days_in_quarter, src.calendar_day_in_quarter,
            src.calendar_year, src.calendar_year_start_date_id, src.calendar_year_end_date_id,
            src.calendar_number_of_days_in_year
        FROM [TransportationDB].[raw_transport].[raw_dimdates] src
        WHERE NOT EXISTS (
            SELECT 1 FROM dw_HR.DimDate dw
            WHERE dw.DateKey = src.date_key
        );

        SET @RowsInserted = @@ROWCOUNT;

        IF @Debug = 1
            PRINT CONCAT('DimDate: Inserted ', @RowsInserted, ' new date records');

        -- Update audit table with success
        UPDATE dw_HR.etl_load_audit
        SET load_end_time = SYSDATETIME(),
            rows_processed = (SELECT COUNT(*) FROM dw_HR.DimDate WHERE DateKey > -1),
            rows_inserted = @RowsInserted,
            status = 'SUCCESS'
        WHERE audit_id = @AuditId;

        IF @Debug = 1
            PRINT CONCAT(CHAR(10), 'DimDate load complete. Total dimension rows: ',
                         (SELECT COUNT(*) FROM dw_HR.DimDate WHERE DateKey > -1));
    END TRY
    BEGIN CATCH
        SET @ErrorMsg = ERROR_MESSAGE();

        -- Log failure
        UPDATE dw_HR.etl_load_audit
        SET load_end_time = SYSDATETIME(),
            status = 'FAILED',
            error_message = @ErrorMsg
        WHERE audit_id = @AuditId;

        RAISERROR(@ErrorMsg, 16, 1);
    END CATCH
END;
GO

-- ============================================================
-- STEP 1: Load DimAgency (SCD Type 2)
--         Agencies can change name, org type, location over time
-- ============================================================

CREATE OR ALTER PROCEDURE dw_HR.sp_load_dim_agency
    @LoadDate DATE = NULL,
    @Debug BIT = 0
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @AuditId INT;
    DECLARE @StartTime DATETIME2 = SYSDATETIME();
    DECLARE @RowsInserted INT = 0;
    DECLARE @RowsUpdated INT = 0;
    DECLARE @DuplicateCount INT = 0;
    DECLARE @ErrorMsg NVARCHAR(MAX) = NULL;

    IF @LoadDate IS NULL
        SET @LoadDate = CAST(GETDATE() AS DATE);

    -- Log start of audit
    INSERT INTO dw_HR.etl_load_audit (
        procedure_name, load_date, load_start_time, status
    )
    VALUES ('sp_load_dim_agency', @LoadDate, @StartTime, 'IN_PROGRESS');
    SET @AuditId = SCOPE_IDENTITY();

    CREATE TABLE #AgencyChanges (
        NTD_ID                  VARCHAR(50),
        LegacyNTD_ID            VARCHAR(50),
        AgencyName              VARCHAR(255),
        OrganizationType        VARCHAR(255),
        City                    VARCHAR(100),
        State                   VARCHAR(20),
        Region                  SMALLINT,
        ServiceAreaSqMiles      NUMERIC(18,2),
        ServiceAreaPopulation   BIGINT,
        ChangeType              VARCHAR(20)
    );

    -- Index for efficient WHERE IN lookups later
    CREATE INDEX IX_AgencyChanges_NTD_ID ON #AgencyChanges(NTD_ID);

    -- Identify new and changed agencies with NULL-safe comparisons
    INSERT INTO #AgencyChanges (
        NTD_ID, LegacyNTD_ID, AgencyName, OrganizationType,
        City, State, Region,
        ServiceAreaSqMiles, ServiceAreaPopulation,
        ChangeType
    )
    SELECT
        src.ntd_id,
        src.legacy_ntd_id,
        src.agency_name,
        src.organization_type,
        src.city,
        src.state,
        CAST(src.region AS SMALLINT),
        src.service_area_sq_miles,
        src.service_area_pop,
        CASE
            WHEN dw.AgencyKey IS NULL THEN 'NEW'
            WHEN HASHBYTES('SHA2_256',
                    CONCAT(
                        ISNULL(src.agency_name, ''),
                        ISNULL(src.city, ''),
                        ISNULL(src.state, ''),
                        ISNULL(src.organization_type, '')
                    )
                ) != HASHBYTES('SHA2_256',
                    CONCAT(
                        ISNULL(dw.AgencyName, ''),
                        ISNULL(dw.City, ''),
                        ISNULL(dw.State, ''),
                        ISNULL(dw.OrganizationType, '')
                    )
                )
                OR ISNULL(CAST(src.region AS SMALLINT), -999) != ISNULL(dw.Region, -999)
                OR ISNULL(src.service_area_sq_miles, -1) != ISNULL(dw.ServiceAreaSqMiles, -1)
                OR ISNULL(src.service_area_pop, -1) != ISNULL(dw.ServiceAreaPopulation, -1)
                THEN 'CHANGE'
            ELSE 'NO_CHANGE'
        END
    FROM (
        -- Clean staging data
        SELECT
            LTRIM(RTRIM(ntd_id)) AS ntd_id,
            LTRIM(RTRIM(legacy_ntd_id)) AS legacy_ntd_id,
            LTRIM(RTRIM(agency_name)) AS agency_name,
            LTRIM(RTRIM(organization_type)) AS organization_type,
            LTRIM(RTRIM(city)) AS city,
            LTRIM(RTRIM(state)) AS state,
            region,
            service_area_sq_miles,
            service_area_pop
        FROM stg_HR.stg_employees
        WHERE ntd_id IS NOT NULL
            AND LTRIM(RTRIM(ntd_id)) != ''
    ) src
    LEFT JOIN dw_HR.DimAgency dw
        ON src.ntd_id = dw.NTD_ID
        AND dw.CurrentFlag = 1;

    -- Remove duplicates (keep most recent)
    IF (SELECT COUNT(*) FROM #AgencyChanges) != (SELECT COUNT(DISTINCT NTD_ID) FROM #AgencyChanges)
    BEGIN
        IF @Debug = 1
            PRINT '*** WARNING: Duplicate NTD_IDs detected in staging data ***';

        ;WITH RankedDuplicates AS (
            SELECT *,
                   ROW_NUMBER() OVER (PARTITION BY NTD_ID ORDER BY LegacyNTD_ID DESC) AS rn
            FROM #AgencyChanges
        )
        DELETE FROM RankedDuplicates
        WHERE rn > 1;
    END

    IF @Debug = 1
    BEGIN
        PRINT '=== AGENCY CHANGES DETECTED ===';
        SELECT ChangeType, COUNT(*) AS RecordCount
        FROM #AgencyChanges
        GROUP BY ChangeType;
    END

    BEGIN TRANSACTION;

    BEGIN TRY
        -- Get duplicate count for audit
        SET @DuplicateCount = (SELECT COUNT(*) FROM #AgencyChanges) - (SELECT COUNT(DISTINCT NTD_ID) FROM #AgencyChanges);

        -- Expire old versions of changed agencies
        UPDATE dw_HR.DimAgency
        SET CurrentFlag = 0,
            ExpirationDate = DATEADD(DAY, -1, @LoadDate)
        WHERE CurrentFlag = 1
            AND AgencyKey != -1
            AND NTD_ID IN (
                SELECT NTD_ID FROM #AgencyChanges WHERE ChangeType = 'CHANGE'
            );

        SET @RowsUpdated = @@ROWCOUNT;
        IF @Debug = 1
            PRINT CONCAT('Expired ', @RowsUpdated, ' agency records');

        -- Insert new and changed agencies
        INSERT INTO dw_HR.DimAgency (
            NTD_ID, LegacyNTD_ID, AgencyName, OrganizationType,
            City, State, Region,
            ServiceAreaSqMiles, ServiceAreaPopulation,
            EffectiveDate, ExpirationDate, CurrentFlag
        )
        SELECT
            NTD_ID, LegacyNTD_ID, AgencyName, OrganizationType,
            City, State, Region,
            ServiceAreaSqMiles, ServiceAreaPopulation,
            @LoadDate, '9999-12-31', 1
        FROM #AgencyChanges
        WHERE ChangeType IN ('NEW', 'CHANGE');

        SET @RowsInserted = @@ROWCOUNT;
        IF @Debug = 1
            PRINT CONCAT('Inserted ', @RowsInserted, ' new/changed agency records');

        COMMIT TRANSACTION;

        -- Log success
        UPDATE dw_HR.etl_load_audit
        SET load_end_time = SYSDATETIME(),
            rows_processed = (SELECT COUNT(*) FROM #AgencyChanges),
            rows_inserted = @RowsInserted,
            rows_updated = @RowsUpdated,
            duplicate_count = @DuplicateCount,
            status = 'SUCCESS'
        WHERE audit_id = @AuditId;

        IF @Debug = 1
            PRINT CONCAT(CHAR(10), 'DimAgency load complete at ', @LoadDate);
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;

        SET @ErrorMsg = ERROR_MESSAGE();

        -- Log failure
        UPDATE dw_HR.etl_load_audit
        SET load_end_time = SYSDATETIME(),
            status = 'FAILED',
            error_message = @ErrorMsg
        WHERE audit_id = @AuditId;

        RAISERROR(@ErrorMsg, 16, 1);
    END CATCH

    DROP TABLE #AgencyChanges;
END;
GO

-- ============================================================
-- STEP 2: Load DimEmploymentType (Static Reference)
--         Insert new employment types that don't exist
-- ============================================================

CREATE OR ALTER PROCEDURE dw_HR.sp_load_dim_employment_type
    @LoadDate DATE = NULL,
    @Debug BIT = 0
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @AuditId INT;
    DECLARE @StartTime DATETIME2 = SYSDATETIME();
    DECLARE @RowsInserted INT = 0;
    DECLARE @ErrorMsg NVARCHAR(MAX) = NULL;

    IF @LoadDate IS NULL
        SET @LoadDate = CAST(GETDATE() AS DATE);

    -- Log start of audit
    INSERT INTO dw_HR.etl_load_audit (
        procedure_name, load_date, load_start_time, status
    )
    VALUES ('sp_load_dim_employment_type', @LoadDate, @StartTime, 'IN_PROGRESS');
    SET @AuditId = SCOPE_IDENTITY();

    CREATE TABLE #NewEmploymentTypes (
        EmploymentTypeCode VARCHAR(50),
        EmploymentTypeName VARCHAR(100),
        IsFullTime BIT
    );

    CREATE INDEX IX_NewEmploymentTypes_Code ON #NewEmploymentTypes(EmploymentTypeCode);

    -- Identify new employment types
    INSERT INTO #NewEmploymentTypes (
        EmploymentTypeCode, EmploymentTypeName, IsFullTime
    )
    SELECT DISTINCT
        LTRIM(RTRIM(employment_type_code)),
        LTRIM(RTRIM(employment_type_name)),
        TRY_CAST(is_full_time AS BIT)
    FROM stg_HR.stg_employment_type
    WHERE employment_type_code IS NOT NULL
        AND LTRIM(RTRIM(employment_type_code)) != ''
        AND NOT EXISTS (
            SELECT 1 FROM dw_HR.DimEmploymentType dw
            WHERE dw.EmploymentTypeCode = LTRIM(RTRIM(stg_HR.stg_employment_type.employment_type_code))
        );

    IF @Debug = 1
        PRINT CONCAT('=== NEW EMPLOYMENT TYPES TO INSERT: ', (SELECT COUNT(*) FROM #NewEmploymentTypes), ' ===');

    BEGIN TRANSACTION;

    BEGIN TRY
        INSERT INTO dw_HR.DimEmploymentType (
            EmploymentTypeCode, EmploymentTypeName, IsFullTime
        )
        SELECT
            EmploymentTypeCode, EmploymentTypeName, IsFullTime
        FROM #NewEmploymentTypes;

        SET @RowsInserted = @@ROWCOUNT;
        IF @Debug = 1
            PRINT CONCAT('Inserted ', @RowsInserted, ' new employment types');

        COMMIT TRANSACTION;

        -- Log success
        UPDATE dw_HR.etl_load_audit
        SET load_end_time = SYSDATETIME(),
            rows_processed = (SELECT COUNT(*) FROM #NewEmploymentTypes),
            rows_inserted = @RowsInserted,
            status = 'SUCCESS'
        WHERE audit_id = @AuditId;

        IF @Debug = 1
            PRINT CHAR(10) + 'DimEmploymentType load complete';
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;

        SET @ErrorMsg = ERROR_MESSAGE();

        -- Log failure
        UPDATE dw_HR.etl_load_audit
        SET load_end_time = SYSDATETIME(),
            status = 'FAILED',
            error_message = @ErrorMsg
        WHERE audit_id = @AuditId;

        RAISERROR(@ErrorMsg, 16, 1);
    END CATCH

    DROP TABLE #NewEmploymentTypes;
END;
GO

-- ============================================================
-- STEP 3: Load DimDepartment (Static Reference)
--         Insert new departments that don't exist
-- ============================================================

CREATE OR ALTER PROCEDURE dw_HR.sp_load_dim_department
    @LoadDate DATE = NULL,
    @Debug BIT = 0
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @AuditId INT;
    DECLARE @StartTime DATETIME2 = SYSDATETIME();
    DECLARE @RowsInserted INT = 0;
    DECLARE @ErrorMsg NVARCHAR(MAX) = NULL;

    IF @LoadDate IS NULL
        SET @LoadDate = CAST(GETDATE() AS DATE);

    -- Log start of audit
    INSERT INTO dw_HR.etl_load_audit (
        procedure_name, load_date, load_start_time, status
    )
    VALUES ('sp_load_dim_department', @LoadDate, @StartTime, 'IN_PROGRESS');
    SET @AuditId = SCOPE_IDENTITY();

    CREATE TABLE #NewDepartments (
        DepartmentCode VARCHAR(50),
        DepartmentName VARCHAR(255),
        NTDLaborObjectClass VARCHAR(100)
    );

    CREATE INDEX IX_NewDepartments_Code ON #NewDepartments(DepartmentCode);

    -- Identify new departments
    INSERT INTO #NewDepartments (
        DepartmentCode, DepartmentName, NTDLaborObjectClass
    )
    SELECT DISTINCT
        LTRIM(RTRIM(department_code)),
        LTRIM(RTRIM(department_name)),
        LTRIM(RTRIM(ntd_labor_object_class))
    FROM stg_HR.stg_department
    WHERE department_code IS NOT NULL
        AND LTRIM(RTRIM(department_code)) != ''
        AND NOT EXISTS (
            SELECT 1 FROM dw_HR.DimDepartment dw
            WHERE dw.DepartmentCode = LTRIM(RTRIM(stg_HR.stg_department.department_code))
        );

    IF @Debug = 1
        PRINT CONCAT('=== NEW DEPARTMENTS TO INSERT: ', (SELECT COUNT(*) FROM #NewDepartments), ' ===');

    BEGIN TRANSACTION;

    BEGIN TRY
        INSERT INTO dw_HR.DimDepartment (
            DepartmentCode, DepartmentName, NTDLaborObjectClass
        )
        SELECT
            DepartmentCode, DepartmentName, NTDLaborObjectClass
        FROM #NewDepartments;

        SET @RowsInserted = @@ROWCOUNT;
        IF @Debug = 1
            PRINT CONCAT('Inserted ', @RowsInserted, ' new departments');

        COMMIT TRANSACTION;

        -- Log success
        UPDATE dw_HR.etl_load_audit
        SET load_end_time = SYSDATETIME(),
            rows_processed = (SELECT COUNT(*) FROM #NewDepartments),
            rows_inserted = @RowsInserted,
            status = 'SUCCESS'
        WHERE audit_id = @AuditId;

        IF @Debug = 1
            PRINT CHAR(10) + 'DimDepartment load complete';
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;

        SET @ErrorMsg = ERROR_MESSAGE();

        -- Log failure
        UPDATE dw_HR.etl_load_audit
        SET load_end_time = SYSDATETIME(),
            status = 'FAILED',
            error_message = @ErrorMsg
        WHERE audit_id = @AuditId;

        RAISERROR(@ErrorMsg, 16, 1);
    END CATCH

    DROP TABLE #NewDepartments;
END;
GO

-- ============================================================
-- STEP 4: Load DimJobRole (SCD Type 2)
--         Job roles can change (title evolution, salary changes)
-- ============================================================

CREATE OR ALTER PROCEDURE dw_HR.sp_load_dim_job_role
    @LoadDate DATE = NULL,
    @Debug BIT = 0
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @AuditId INT;
    DECLARE @StartTime DATETIME2 = SYSDATETIME();
    DECLARE @RowsInserted INT = 0;
    DECLARE @RowsUpdated INT = 0;
    DECLARE @DuplicateCount INT = 0;
    DECLARE @ErrorMsg NVARCHAR(MAX) = NULL;

    IF @LoadDate IS NULL
        SET @LoadDate = CAST(GETDATE() AS DATE);

    -- Log start of audit
    INSERT INTO dw_HR.etl_load_audit (
        procedure_name, load_date, load_start_time, status
    )
    VALUES ('sp_load_dim_job_role', @LoadDate, @StartTime, 'IN_PROGRESS');
    SET @AuditId = SCOPE_IDENTITY();

    CREATE TABLE #JobRoleChanges (
        PositionTitle VARCHAR(255),
        LaborCategory VARCHAR(100),
        OperatorStatus VARCHAR(50),
        TypicalSalaryMin NUMERIC(18,2),
        TypicalSalaryMax NUMERIC(18,2),
        ChangeType VARCHAR(20)
    );

    CREATE INDEX IX_JobRoleChanges_PositionTitle ON #JobRoleChanges(PositionTitle);

    -- Identify new and changed job roles with NULL-safe comparisons
    INSERT INTO #JobRoleChanges (
        PositionTitle, LaborCategory, OperatorStatus,
        TypicalSalaryMin, TypicalSalaryMax,
        ChangeType
    )
    SELECT
        src.position_title,
        src.labor_category,
        src.operator_status,
        src.typical_salary_min,
        src.typical_salary_max,
        CASE
            WHEN dw.JobRoleKey IS NULL THEN 'NEW'
            WHEN ISNULL(src.labor_category, '') != ISNULL(dw.LaborCategory, '')
                OR ISNULL(src.operator_status, '') != ISNULL(dw.OperatorStatus, '')
                OR ISNULL(src.typical_salary_min, -1) != ISNULL(dw.TypicalSalaryMin, -1)
                OR ISNULL(src.typical_salary_max, -1) != ISNULL(dw.TypicalSalaryMax, -1)
                THEN 'CHANGE'
            ELSE 'NO_CHANGE'
        END
    FROM (
        -- Clean staging data
        SELECT
            LTRIM(RTRIM(position_title)) AS position_title,
            LTRIM(RTRIM(labor_category)) AS labor_category,
            LTRIM(RTRIM(operator_status)) AS operator_status,
            typical_salary_min,
            typical_salary_max
        FROM stg_HR.stg_job_role
        WHERE position_title IS NOT NULL
            AND LTRIM(RTRIM(position_title)) != ''
    ) src
    LEFT JOIN dw_HR.DimJobRole dw
        ON src.position_title = dw.PositionTitle
        AND dw.CurrentFlag = 1;

    -- Remove duplicates
    IF (SELECT COUNT(*) FROM #JobRoleChanges) != (SELECT COUNT(DISTINCT PositionTitle) FROM #JobRoleChanges)
    BEGIN
        IF @Debug = 1
            PRINT '*** WARNING: Duplicate PositionTitles detected in staging data ***';

        ;WITH RankedDuplicates AS (
            SELECT *,
                   ROW_NUMBER() OVER (PARTITION BY PositionTitle ORDER BY TypicalSalaryMax DESC) AS rn
            FROM #JobRoleChanges
        )
        DELETE FROM RankedDuplicates
        WHERE rn > 1;
    END

    IF @Debug = 1
    BEGIN
        PRINT '=== JOB ROLE CHANGES DETECTED ===';
        SELECT ChangeType, COUNT(*) AS RecordCount
        FROM #JobRoleChanges
        GROUP BY ChangeType;
    END

    BEGIN TRANSACTION;

    BEGIN TRY
        -- Get duplicate count for audit
        SET @DuplicateCount = (SELECT COUNT(*) FROM #JobRoleChanges) - (SELECT COUNT(DISTINCT PositionTitle) FROM #JobRoleChanges);

        -- Expire old versions of changed roles
        UPDATE dw_HR.DimJobRole
        SET CurrentFlag = 0,
            ExpirationDate = DATEADD(DAY, -1, @LoadDate)
        WHERE CurrentFlag = 1
            AND JobRoleKey != -1
            AND PositionTitle IN (
                SELECT PositionTitle FROM #JobRoleChanges WHERE ChangeType = 'CHANGE'
            );

        SET @RowsUpdated = @@ROWCOUNT;
        IF @Debug = 1
            PRINT CONCAT('Expired ', @RowsUpdated, ' job role records');

        -- Insert new and changed roles
        INSERT INTO dw_HR.DimJobRole (
            PositionTitle, LaborCategory, OperatorStatus,
            TypicalSalaryMin, TypicalSalaryMax,
            EffectiveDate, ExpirationDate, CurrentFlag
        )
        SELECT
            PositionTitle, LaborCategory, OperatorStatus,
            TypicalSalaryMin, TypicalSalaryMax,
            @LoadDate, '9999-12-31', 1
        FROM #JobRoleChanges
        WHERE ChangeType IN ('NEW', 'CHANGE');

        SET @RowsInserted = @@ROWCOUNT;
        IF @Debug = 1
            PRINT CONCAT('Inserted ', @RowsInserted, ' new/changed job role records');

        COMMIT TRANSACTION;

        -- Log success
        UPDATE dw_HR.etl_load_audit
        SET load_end_time = SYSDATETIME(),
            rows_processed = (SELECT COUNT(*) FROM #JobRoleChanges),
            rows_inserted = @RowsInserted,
            rows_updated = @RowsUpdated,
            duplicate_count = @DuplicateCount,
            status = 'SUCCESS'
        WHERE audit_id = @AuditId;

        IF @Debug = 1
            PRINT CONCAT(CHAR(10), 'DimJobRole load complete at ', @LoadDate);
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;

        SET @ErrorMsg = ERROR_MESSAGE();

        -- Log failure
        UPDATE dw_HR.etl_load_audit
        SET load_end_time = SYSDATETIME(),
            status = 'FAILED',
            error_message = @ErrorMsg
        WHERE audit_id = @AuditId;

        RAISERROR(@ErrorMsg, 16, 1);
    END CATCH

    DROP TABLE #JobRoleChanges;
END;
GO

-- ============================================================
-- STEP 5: Load DimEducation (Static Reference)
--         Insert new education levels that don't exist
-- ============================================================

CREATE OR ALTER PROCEDURE dw_HR.sp_load_dim_education
    @LoadDate DATE = NULL,
    @Debug BIT = 0
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @AuditId INT;
    DECLARE @StartTime DATETIME2 = SYSDATETIME();
    DECLARE @RowsInserted INT = 0;
    DECLARE @ErrorMsg NVARCHAR(MAX) = NULL;

    IF @LoadDate IS NULL
        SET @LoadDate = CAST(GETDATE() AS DATE);

    -- Log start of audit
    INSERT INTO dw_HR.etl_load_audit (
        procedure_name, load_date, load_start_time, status
    )
    VALUES ('sp_load_dim_education', @LoadDate, @StartTime, 'IN_PROGRESS');
    SET @AuditId = SCOPE_IDENTITY();

    CREATE TABLE #NewEducationLevels (
        EducationLevelCode VARCHAR(50),
        EducationLevel VARCHAR(100),
        HierarchyLevel SMALLINT
    );

    CREATE INDEX IX_NewEducationLevels_Code ON #NewEducationLevels(EducationLevelCode);

    -- Identify new education levels
    INSERT INTO #NewEducationLevels (
        EducationLevelCode, EducationLevel, HierarchyLevel
    )
    SELECT DISTINCT
        LTRIM(RTRIM(education_level_code)),
        LTRIM(RTRIM(education_level_name)),
        TRY_CAST(hierarchy_level AS SMALLINT)
    FROM stg_HR.stg_education_level
    WHERE education_level_code IS NOT NULL
        AND LTRIM(RTRIM(education_level_code)) != ''
        AND NOT EXISTS (
            SELECT 1 FROM dw_HR.DimEducation dw
            WHERE dw.EducationLevelCode = LTRIM(RTRIM(stg_HR.stg_education_level.education_level_code))
        );

    IF @Debug = 1
        PRINT CONCAT('=== NEW EDUCATION LEVELS TO INSERT: ', (SELECT COUNT(*) FROM #NewEducationLevels), ' ===');

    BEGIN TRANSACTION;

    BEGIN TRY
        INSERT INTO dw_HR.DimEducation (
            EducationLevelCode, EducationLevel, HierarchyLevel
        )
        SELECT
            EducationLevelCode, EducationLevel, HierarchyLevel
        FROM #NewEducationLevels;

        SET @RowsInserted = @@ROWCOUNT;
        IF @Debug = 1
            PRINT CONCAT('Inserted ', @RowsInserted, ' new education levels');

        COMMIT TRANSACTION;

        -- Log success
        UPDATE dw_HR.etl_load_audit
        SET load_end_time = SYSDATETIME(),
            rows_processed = (SELECT COUNT(*) FROM #NewEducationLevels),
            rows_inserted = @RowsInserted,
            status = 'SUCCESS'
        WHERE audit_id = @AuditId;

        IF @Debug = 1
            PRINT CHAR(10) + 'DimEducation load complete';
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;

        SET @ErrorMsg = ERROR_MESSAGE();

        -- Log failure
        UPDATE dw_HR.etl_load_audit
        SET load_end_time = SYSDATETIME(),
            status = 'FAILED',
            error_message = @ErrorMsg
        WHERE audit_id = @AuditId;

        RAISERROR(@ErrorMsg, 16, 1);
    END CATCH

    DROP TABLE #NewEducationLevels;
END;
GO

-- ============================================================
-- MASTER ETL ORCHESTRATION PROCEDURE
-- ============================================================

CREATE OR ALTER PROCEDURE dw_HR.sp_load_all_dimensions
    @LoadDate DATE = NULL,
    @Debug BIT = 0,
    @SkipDate BIT = 0,
    @SkipAgency BIT = 0,
    @SkipEmploymentType BIT = 0,
    @SkipDepartment BIT = 0,
    @SkipJobRole BIT = 0,
    @SkipEducation BIT = 0
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @StartTime DATETIME2 = SYSDATETIME();
    DECLARE @SuccessCount INT = 0;
    DECLARE @FailureCount INT = 0;
    DECLARE @ErrorMsg NVARCHAR(MAX) = NULL;

    IF @LoadDate IS NULL
        SET @LoadDate = CAST(GETDATE() AS DATE);

    PRINT '=================================================================';;
    PRINT 'HR DIMENSIONS ETL ORCHESTRATION';
    PRINT '=================================================================';;
    PRINT CONCAT('Load Date: ', @LoadDate);
    PRINT CONCAT('Start Time: ', @StartTime);
    PRINT '';

    -- Load DimDate (Static Calendar)
    IF @SkipDate = 0
    BEGIN
        PRINT 'Loading DimDate...';
        BEGIN TRY
            EXEC dw_HR.sp_load_dim_date @LoadDate = @LoadDate, @Debug = @Debug;
            SET @SuccessCount += 1;
            PRINT '✓ DimDate loaded successfully' + CHAR(10);
        END TRY
        BEGIN CATCH
            SET @FailureCount += 1;
            SET @ErrorMsg = ERROR_MESSAGE();
            PRINT '✗ DimDate FAILED: ' + @ErrorMsg + CHAR(10);
        END CATCH
    END

    -- Load DimAgency (SCD Type 2)
    IF @SkipAgency = 0
    BEGIN
        PRINT 'Loading DimAgency...';
        BEGIN TRY
            EXEC dw_HR.sp_load_dim_agency @LoadDate = @LoadDate, @Debug = @Debug;
            SET @SuccessCount += 1;
            PRINT '✓ DimAgency loaded successfully' + CHAR(10);
        END TRY
        BEGIN CATCH
            SET @FailureCount += 1;
            SET @ErrorMsg = ERROR_MESSAGE();
            PRINT '✗ DimAgency FAILED: ' + @ErrorMsg + CHAR(10);
        END CATCH
    END

    -- Load DimEmploymentType (Static Reference)
    IF @SkipEmploymentType = 0
    BEGIN
        PRINT 'Loading DimEmploymentType...';
        BEGIN TRY
            EXEC dw_HR.sp_load_dim_employment_type @LoadDate = @LoadDate, @Debug = @Debug;
            SET @SuccessCount += 1;
            PRINT '✓ DimEmploymentType loaded successfully' + CHAR(10);
        END TRY
        BEGIN CATCH
            SET @FailureCount += 1;
            SET @ErrorMsg = ERROR_MESSAGE();
            PRINT '✗ DimEmploymentType FAILED: ' + @ErrorMsg + CHAR(10);
        END CATCH
    END

    -- Load DimDepartment (Static Reference)
    IF @SkipDepartment = 0
    BEGIN
        PRINT 'Loading DimDepartment...';
        BEGIN TRY
            EXEC dw_HR.sp_load_dim_department @LoadDate = @LoadDate, @Debug = @Debug;
            SET @SuccessCount += 1;
            PRINT '✓ DimDepartment loaded successfully' + CHAR(10);
        END TRY
        BEGIN CATCH
            SET @FailureCount += 1;
            SET @ErrorMsg = ERROR_MESSAGE();
            PRINT '✗ DimDepartment FAILED: ' + @ErrorMsg + CHAR(10);
        END CATCH
    END

    -- Load DimJobRole (SCD Type 2)
    IF @SkipJobRole = 0
    BEGIN
        PRINT 'Loading DimJobRole...';
        BEGIN TRY
            EXEC dw_HR.sp_load_dim_job_role @LoadDate = @LoadDate, @Debug = @Debug;
            SET @SuccessCount += 1;
            PRINT '✓ DimJobRole loaded successfully' + CHAR(10);
        END TRY
        BEGIN CATCH
            SET @FailureCount += 1;
            SET @ErrorMsg = ERROR_MESSAGE();
            PRINT '✗ DimJobRole FAILED: ' + @ErrorMsg + CHAR(10);
        END CATCH
    END

    -- Load DimEducation (Static Reference)
    IF @SkipEducation = 0
    BEGIN
        PRINT 'Loading DimEducation...';
        BEGIN TRY
            EXEC dw_HR.sp_load_dim_education @LoadDate = @LoadDate, @Debug = @Debug;
            SET @SuccessCount += 1;
            PRINT '✓ DimEducation loaded successfully' + CHAR(10);
        END TRY
        BEGIN CATCH
            SET @FailureCount += 1;
            SET @ErrorMsg = ERROR_MESSAGE();
            PRINT '✗ DimEducation FAILED: ' + @ErrorMsg + CHAR(10);
        END CATCH
    END

    -- Final summary
    PRINT '=================================================================';;
    PRINT 'HR DIMENSIONS ETL SUMMARY';
    PRINT '=================================================================';;
    PRINT CONCAT('Procedures Completed Successfully: ', @SuccessCount);
    PRINT CONCAT('Procedures Failed: ', @FailureCount);
    PRINT CONCAT('Total Elapsed Time: ', DATEDIFF(SECOND, @StartTime, SYSDATETIME()), ' seconds');
    PRINT '';

    IF @FailureCount > 0
    BEGIN
        PRINT 'WARNING: One or more dimension loads failed!';
        RAISERROR('ETL orchestration completed with errors', 16, 1);
    END
    ELSE
    BEGIN
        PRINT 'SUCCESS: All dimension loads completed successfully!';
    END
END;
GO

-- ============================================================
-- End of HR Dimension ETL Script
-- ============================================================

-- Example usage:
--   EXEC dw_HR.sp_load_all_dimensions @LoadDate = '2025-01-06', @Debug = 1;
--
-- To run individual procedures:
--   EXEC dw_HR.sp_load_dim_date @LoadDate = '2025-01-06', @Debug = 1;
--   EXEC dw_HR.sp_load_dim_agency @LoadDate = '2025-01-06', @Debug = 1;
--   EXEC dw_HR.sp_load_dim_employment_type @LoadDate = '2025-01-06', @Debug = 1;
--   EXEC dw_HR.sp_load_dim_department @LoadDate = '2025-01-06', @Debug = 1;
--   EXEC dw_HR.sp_load_dim_job_role @LoadDate = '2025-01-06', @Debug = 1;
--   EXEC dw_HR.sp_load_dim_education @LoadDate = '2025-01-06', @Debug = 1;
--
-- To skip specific procedures in orchestration:
--   EXEC dw_HR.sp_load_all_dimensions @LoadDate = '2025-01-06', @SkipEducation = 1;
