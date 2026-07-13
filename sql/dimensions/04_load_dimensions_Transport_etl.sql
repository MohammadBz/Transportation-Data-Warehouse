-- ============================================================
-- FILE:   04_load_dimensions_Transport_etl.sql
-- SCHEMA: dw_transport
-- DESC:   ETL procedures to load all dimensions from staging.
--         Implements Kimball-style SCD logic with unknown sentinels.
--
-- EXECUTION ORDER: Run after 03_dim_transport_DDL.sql
--
-- DIMENSION LOADING PATTERNS:
--   1. DimDate        - Static; pre-loaded from CSV (not handled here)
--   2. DimAgency      - SCD Type 2; merge on NTD_ID
--   3. DimMode        - Static; pre-populated; no ETL needed
--   4. DimServiceType - Static; pre-populated; no ETL needed
--   5. DimUrbanArea   - SCD Type 2; merge on UACECode
--   6. DimSafetyEventType - Static with merge; insert-or-ignore
--   7. DimSafetyIncident  - Type 1; upsert on SourceEventID
--
-- IMPROVEMENTS IN THIS VERSION:
--   - Fixed NULL handling in change detection (uses ISNULL)
--   - Removed redundant GROUP BY in sp_load_dim_agency
--   - Added UZAName change detection in sp_load_dim_urban_area
--   - Improved NULL-safe comparisons in sp_load_dim_safety_event_type
--   - Enhanced error handling with proper transaction rollback checks
--   - Better debug output and diagnostics
--   - Prevents cascade failures in master orchestration
--   - Only updates Type 1 when data actually changes
--   - REMOVED NOLOCK hints from SCD joins (prevents dirty reads)
--   - Removed unnecessary DISTINCT from staging queries
--   - Added indexes on temp tables for join/filter performance
--   - Moved LTRIM/RTRIM to staging preparation
--   - Added duplicate business key detection
--   - Optimized change detection with HASHBYTES
--   - FIXED: Duplicate detection logic using ROW_NUMBER() instead of broken NOT IN subquery
--   - IMPROVED: Numeric comparisons now done directly instead of via HASHBYTES concatenation
--   - REMOVED: DISTINCT from all staging prep queries (fixes duplicate masking issue)
--   - ADDED: UNIQUE constraints to staging tables to prevent duplicates at source
--   - ADDED: ETL audit logging table for data quality tracking
--   - REMOVED: DISTINCT from all staging prep queries (fixes #1 issue)
--   - ADDED: UNIQUE constraints to staging tables to prevent duplicates at source
--   - ADDED: ETL audit logging table for data
--
-- ============================================================

USE [TransportationDB];
GO

-- ============================================================
-- ETL Audit & Data Quality Logging Table
-- ============================================================

IF NOT EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_NAME = 'etl_load_audit')
BEGIN
    CREATE TABLE dw_transport.etl_load_audit (
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

    CREATE INDEX IX_etl_audit_procedure_date ON dw_transport.etl_load_audit(procedure_name, load_date DESC);
END
GO

-- ============================================================
-- STEP 0: Load DimDate (Static Dimension from Raw Source)
-- ============================================================

CREATE OR ALTER PROCEDURE dw_transport.sp_load_dim_date
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
    INSERT INTO dw_transport.etl_load_audit (
        procedure_name, load_date, load_start_time, status
    )
    VALUES ('sp_load_dim_date', @LoadDate, @StartTime, 'IN_PROGRESS');
    SET @AuditId = SCOPE_IDENTITY();

    BEGIN TRY
        -- Load DimDate from raw source, skipping rows that already exist
        -- DimDate is static (no SCD needed), so we only insert new dates
        INSERT INTO dw_transport.DimDate (
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
            SELECT 1 FROM dw_transport.DimDate dw
            WHERE dw.DateKey = src.date_key
        );

        SET @RowsInserted = @@ROWCOUNT;

        IF @Debug = 1
            PRINT CONCAT('DimDate: Inserted ', @RowsInserted, ' new date records');

        -- Update audit table with success
        UPDATE dw_transport.etl_load_audit
        SET load_end_time = SYSDATETIME(),
            rows_processed = (SELECT COUNT(*) FROM dw_transport.DimDate WHERE DateKey > -1),
            rows_inserted = @RowsInserted,
            status = 'SUCCESS'
        WHERE audit_id = @AuditId;

        IF @Debug = 1
            PRINT CONCAT(CHAR(10), 'DimDate load complete. Total dimension rows: ',
                         (SELECT COUNT(*) FROM dw_transport.DimDate WHERE DateKey > -1));
    END TRY
    BEGIN CATCH
        SET @ErrorMsg = ERROR_MESSAGE();

        -- Log failure
        UPDATE dw_transport.etl_load_audit
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
-- ============================================================

CREATE OR ALTER PROCEDURE dw_transport.sp_load_dim_agency
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
    INSERT INTO dw_transport.etl_load_audit (
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
    -- Pre-filter to eliminate duplicates and NULL keys before processing
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
        -- Clean staging data (UNIQUE constraint on ntd_id prevents duplicates)
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
        FROM stg_transport.stg_agency_information
        WHERE ntd_id IS NOT NULL
            AND LTRIM(RTRIM(ntd_id)) != ''
    ) src
    LEFT JOIN dw_transport.DimAgency dw
        ON src.ntd_id = dw.NTD_ID
        AND dw.CurrentFlag = 1;

    -- Check for duplicate business keys in staging
    -- Note: UNIQUE constraint in stg_agency_information prevents duplicates at source
    -- This check is a safety net for data quality validation
    IF (SELECT COUNT(*) FROM #AgencyChanges) != (SELECT COUNT(DISTINCT NTD_ID) FROM #AgencyChanges)
    BEGIN
        IF @Debug = 1
            PRINT '*** WARNING: Duplicate NTD_IDs detected in staging data ***';

        -- Remove duplicates using ROW_NUMBER, keeping last occurrence by LegacyNTD_ID
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

        UPDATE dw_transport.DimAgency
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

        INSERT INTO dw_transport.DimAgency (
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
        UPDATE dw_transport.etl_load_audit
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
        UPDATE dw_transport.etl_load_audit
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
-- STEP 2: Load DimUrbanArea (SCD Type 2)
-- ============================================================

CREATE OR ALTER PROCEDURE dw_transport.sp_load_dim_urban_area
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
    INSERT INTO dw_transport.etl_load_audit (
        procedure_name, load_date, load_start_time, status
    )
    VALUES ('sp_load_dim_urban_area', @LoadDate, @StartTime, 'IN_PROGRESS');
    SET @AuditId = SCOPE_IDENTITY();

    CREATE TABLE #UrbanAreaChanges (
        UACECode            VARCHAR(50),
        UZAName             VARCHAR(255),
        UZASqMiles          NUMERIC(18,2),
        UZAPopulation       BIGINT,
        UZADensity          NUMERIC(18,2),
        ChangeType          VARCHAR(20)
    );

    -- Index for efficient WHERE IN lookups later
    CREATE INDEX IX_UrbanAreaChanges_UACECode ON #UrbanAreaChanges(UACECode);

    -- Identify new and changed urban areas including name changes
    -- Pre-filter to eliminate duplicates and NULL keys before processing
    INSERT INTO #UrbanAreaChanges (
        UACECode, UZAName,
        UZASqMiles, UZAPopulation, UZADensity,
        ChangeType
    )
    SELECT
        src.primary_uza_uace_code,
        src.uza_name,
        src.sq_miles,
        src.population,
        src.density,
        CASE
            WHEN dw.UrbanAreaKey IS NULL THEN 'NEW'
            WHEN HASHBYTES('SHA2_256', ISNULL(src.uza_name, ''))
                    != HASHBYTES('SHA2_256', ISNULL(dw.UZAName, ''))
                OR ISNULL(src.sq_miles, -1) != ISNULL(dw.UZASqMiles, -1)
                OR ISNULL(src.population, -1) != ISNULL(dw.UZAPopulation, -1)
                OR ISNULL(src.density, -1) != ISNULL(dw.UZADensity, -1)
                THEN 'CHANGE'
            ELSE 'NO_CHANGE'
        END
    FROM (
        -- Clean staging data (UNIQUE constraint on ntd_id prevents duplicates)
        SELECT
            LTRIM(RTRIM(primary_uza_uace_code)) AS primary_uza_uace_code,
            LTRIM(RTRIM(uza_name)) AS uza_name,
            sq_miles,
            population,
            density
        FROM stg_transport.stg_agency_information
        WHERE primary_uza_uace_code IS NOT NULL
            AND LTRIM(RTRIM(primary_uza_uace_code)) != ''
    ) src
    LEFT JOIN dw_transport.DimUrbanArea dw
        ON src.primary_uza_uace_code = dw.UACECode
        AND dw.CurrentFlag = 1;

    -- Check for duplicate business keys in staging
    -- Note: stg_agency_information enforces UNIQUE on UACECode via ntd_id constraint
    -- This is a safety net check for data quality
    DECLARE @UrbanAreaDuplicateCount INT = (SELECT COUNT(*) FROM #UrbanAreaChanges) - (SELECT COUNT(DISTINCT UACECode) FROM #UrbanAreaChanges);
    IF @UrbanAreaDuplicateCount > 0
    BEGIN
        IF @Debug = 1
            PRINT CONCAT('*** WARNING: ', @UrbanAreaDuplicateCount, ' duplicate UACECodes detected in staging data ***');

        -- Remove duplicates using ROW_NUMBER, keeping last occurrence by UZAName
        ;WITH RankedDuplicates AS (
            SELECT *,
                   ROW_NUMBER() OVER (PARTITION BY UACECode ORDER BY UZAName DESC) AS rn
            FROM #UrbanAreaChanges
        )
        DELETE FROM RankedDuplicates
        WHERE rn > 1;
    END

    IF @Debug = 1
    BEGIN
        PRINT '=== URBAN AREA CHANGES DETECTED ===';
        SELECT ChangeType, COUNT(*) AS RecordCount
        FROM #UrbanAreaChanges
        GROUP BY ChangeType;
    END

    BEGIN TRANSACTION;

    BEGIN TRY
        -- Get duplicate count for audit
        SET @DuplicateCount = (SELECT COUNT(*) FROM #UrbanAreaChanges) - (SELECT COUNT(DISTINCT UACECode) FROM #UrbanAreaChanges);

        UPDATE dw_transport.DimUrbanArea
        SET CurrentFlag = 0,
            ExpirationDate = DATEADD(DAY, -1, @LoadDate)
        WHERE CurrentFlag = 1
            AND UrbanAreaKey != -1
            AND UACECode IN (
                SELECT UACECode FROM #UrbanAreaChanges WHERE ChangeType = 'CHANGE'
            );

        SET @RowsUpdated = @@ROWCOUNT;
        IF @Debug = 1
            PRINT CONCAT('Expired ', @RowsUpdated, ' urban area records');

        INSERT INTO dw_transport.DimUrbanArea (
            UACECode, UZAName,
            UZASqMiles, UZAPopulation, UZADensity,
            EffectiveDate, ExpirationDate, CurrentFlag
        )
        SELECT
            UACECode, UZAName,
            UZASqMiles, UZAPopulation, UZADensity,
            @LoadDate, '9999-12-31', 1
        FROM #UrbanAreaChanges
        WHERE ChangeType IN ('NEW', 'CHANGE');

        SET @RowsInserted = @@ROWCOUNT;
        IF @Debug = 1
            PRINT CONCAT('Inserted ', @RowsInserted, ' new/changed urban area records');

        COMMIT TRANSACTION;

        -- Log success
        UPDATE dw_transport.etl_load_audit
        SET load_end_time = SYSDATETIME(),
            rows_processed = (SELECT COUNT(*) FROM #UrbanAreaChanges),
            rows_inserted = @RowsInserted,
            rows_updated = @RowsUpdated,
            duplicate_count = @DuplicateCount,
            status = 'SUCCESS'
        WHERE audit_id = @AuditId;

        IF @Debug = 1
            PRINT CONCAT(CHAR(10), 'DimUrbanArea load complete at ', @LoadDate);
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;

        SET @ErrorMsg = ERROR_MESSAGE();

        -- Log failure
        UPDATE dw_transport.etl_load_audit
        SET load_end_time = SYSDATETIME(),
            status = 'FAILED',
            error_message = @ErrorMsg
        WHERE audit_id = @AuditId;

        RAISERROR(@ErrorMsg, 16, 1);
    END CATCH

    DROP TABLE #UrbanAreaChanges;
END;
GO

-- ============================================================
-- STEP 3: Load DimSafetyEventType (Static with Merge)
-- ============================================================

CREATE OR ALTER PROCEDURE dw_transport.sp_load_dim_safety_event_type
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
    INSERT INTO dw_transport.etl_load_audit (
        procedure_name, load_date, load_start_time, status
    )
    VALUES ('sp_load_dim_safety_event_type', @LoadDate, @StartTime, 'IN_PROGRESS');
    SET @AuditId = SCOPE_IDENTITY();

    CREATE TABLE #NewSafetyEventTypes (
        EventCategory   VARCHAR(100),
        EventType       VARCHAR(200),
        EventSubType    VARCHAR(200),
        SeverityLevel   VARCHAR(50)
    );

    -- Index for EXISTS check lookups
    CREATE INDEX IX_NewSafetyEventTypes_Composite
        ON #NewSafetyEventTypes(EventCategory, EventType, EventSubType, SeverityLevel);

    -- Identify new event type combinations with NULL-safe comparisons
    INSERT INTO #NewSafetyEventTypes (
        EventCategory, EventType, EventSubType, SeverityLevel
    )
    SELECT
        src.event_category,
        src.event_type,
        src.event_type_group,
        src.safety_security
    FROM (
        -- Clean staging data (UNIQUE constraint on incident_number prevents duplicates)
        SELECT
            LTRIM(RTRIM(event_category)) AS event_category,
            LTRIM(RTRIM(event_type)) AS event_type,
            LTRIM(RTRIM(event_type_group)) AS event_type_group,
            LTRIM(RTRIM(safety_security)) AS safety_security
        FROM stg_transport.stg_major_safety_event
    ) src
    WHERE src.event_category IS NOT NULL
        AND LTRIM(RTRIM(src.event_category)) != ''
        AND NOT EXISTS (
            SELECT 1
            FROM dw_transport.DimSafetyEventType dw
            WHERE ISNULL(dw.EventCategory, '') = ISNULL(src.event_category, '')
                AND ISNULL(dw.EventType, '') = ISNULL(src.event_type, '')
                AND ISNULL(dw.EventSubType, '') = ISNULL(src.event_type_group, '')
                AND ISNULL(dw.SeverityLevel, '') = ISNULL(src.safety_security, '')
        );

    IF @Debug = 1
    BEGIN
        PRINT CONCAT('=== NEW SAFETY EVENT TYPES TO INSERT: ', (SELECT COUNT(*) FROM #NewSafetyEventTypes), ' ===');
    END

    BEGIN TRANSACTION;

    BEGIN TRY
        INSERT INTO dw_transport.DimSafetyEventType (
            EventCategory, EventType, EventSubType, SeverityLevel
        )
        SELECT
            EventCategory, EventType, EventSubType, SeverityLevel
        FROM #NewSafetyEventTypes;

        SET @RowsInserted = @@ROWCOUNT;
        IF @Debug = 1
            PRINT CONCAT('Inserted ', @RowsInserted, ' new safety event types');

        COMMIT TRANSACTION;

        -- Log success
        UPDATE dw_transport.etl_load_audit
        SET load_end_time = SYSDATETIME(),
            rows_processed = (SELECT COUNT(*) FROM #NewSafetyEventTypes),
            rows_inserted = @RowsInserted,
            status = 'SUCCESS'
        WHERE audit_id = @AuditId;

        IF @Debug = 1
            PRINT CHAR(10) + 'DimSafetyEventType load complete';
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;

        SET @ErrorMsg = ERROR_MESSAGE();

        -- Log failure
        UPDATE dw_transport.etl_load_audit
        SET load_end_time = SYSDATETIME(),
            status = 'FAILED',
            error_message = @ErrorMsg
        WHERE audit_id = @AuditId;

        RAISERROR(@ErrorMsg, 16, 1);
    END CATCH

    DROP TABLE #NewSafetyEventTypes;
END;
GO

-- ============================================================
-- STEP 4: Load DimSafetyIncident (Type 1 - Upsert)
-- ============================================================

CREATE OR ALTER PROCEDURE dw_transport.sp_load_dim_safety_incident
    @LoadDate DATE = NULL,
    @Debug BIT = 0
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @AuditId INT;
    DECLARE @StartTime DATETIME2 = SYSDATETIME();
    DECLARE @RowsInserted INT = 0;
    DECLARE @RowsUpdated INT = 0;
    DECLARE @ErrorMsg NVARCHAR(MAX) = NULL;

    IF @LoadDate IS NULL
        SET @LoadDate = CAST(GETDATE() AS DATE);

    -- Log start of audit
    INSERT INTO dw_transport.etl_load_audit (
        procedure_name, load_date, load_start_time, status
    )
    VALUES ('sp_load_dim_safety_incident', @LoadDate, @StartTime, 'IN_PROGRESS');
    SET @AuditId = SCOPE_IDENTITY();

    CREATE TABLE #SafetyIncidents (
        SourceEventID       VARCHAR(50),
        EventDescription    VARCHAR(4000)
    );

    -- Index for join operations
    CREATE INDEX IX_SafetyIncidents_SourceEventID ON #SafetyIncidents(SourceEventID);

    INSERT INTO #SafetyIncidents (
        SourceEventID, EventDescription
    )
    SELECT
        src.incident_number,
        src.narrative
    FROM (
        -- Clean staging data (UNIQUE constraint on incident_number prevents duplicates)
        SELECT
            LTRIM(RTRIM(incident_number)) AS incident_number,
            LTRIM(RTRIM(narrative)) AS narrative
        FROM stg_transport.stg_major_safety_event
        WHERE incident_number IS NOT NULL
            AND LTRIM(RTRIM(incident_number)) != ''
    ) src;

    IF @Debug = 1
    BEGIN
        PRINT CONCAT('=== SAFETY INCIDENTS FOUND: ', (SELECT COUNT(*) FROM #SafetyIncidents), ' ===');
    END

    BEGIN TRANSACTION;

    BEGIN TRY
        -- Update only if description actually changed
        UPDATE dw_transport.DimSafetyIncident
        SET EventDescription = src.EventDescription
        FROM dw_transport.DimSafetyIncident dw
        INNER JOIN #SafetyIncidents src
            ON dw.SourceEventID = src.SourceEventID
        WHERE dw.SafetyIncidentKey != -1
            AND ISNULL(dw.EventDescription, '') != ISNULL(src.EventDescription, '');

        SET @RowsUpdated = @@ROWCOUNT;
        IF @Debug = 1
            PRINT CONCAT('Updated ', @RowsUpdated, ' incident descriptions');

        INSERT INTO dw_transport.DimSafetyIncident (
            SourceEventID, EventDescription
        )
        SELECT
            src.SourceEventID,
            src.EventDescription
        FROM #SafetyIncidents src
        WHERE NOT EXISTS (
            SELECT 1
            FROM dw_transport.DimSafetyIncident dw
            WHERE dw.SourceEventID = src.SourceEventID
        );

        SET @RowsInserted = @@ROWCOUNT;
        IF @Debug = 1
            PRINT CONCAT('Inserted ', @RowsInserted, ' new incidents');

        COMMIT TRANSACTION;

        -- Log success
        UPDATE dw_transport.etl_load_audit
        SET load_end_time = SYSDATETIME(),
            rows_processed = (SELECT COUNT(*) FROM #SafetyIncidents),
            rows_inserted = @RowsInserted,
            rows_updated = @RowsUpdated,
            status = 'SUCCESS'
        WHERE audit_id = @AuditId;

        IF @Debug = 1
            PRINT CHAR(10) + 'DimSafetyIncident load complete';
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;

        SET @ErrorMsg = ERROR_MESSAGE();

        -- Log failure
        UPDATE dw_transport.etl_load_audit
        SET load_end_time = SYSDATETIME(),
            status = 'FAILED',
            error_message = @ErrorMsg
        WHERE audit_id = @AuditId;

        RAISERROR(@ErrorMsg, 16, 1);
    END CATCH

    DROP TABLE #SafetyIncidents;
END;
GO

-- ============================================================
-- MASTER ETL ORCHESTRATION PROCEDURE
-- ============================================================

CREATE OR ALTER PROCEDURE dw_transport.sp_load_all_dimensions
    @LoadDate DATE = NULL,
    @Debug BIT = 0,
    @SkipAgency BIT = 0,
    @SkipUrbanArea BIT = 0,
    @SkipSafetyEventType BIT = 0,
    @SkipSafetyIncident BIT = 0
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @StartTime DATETIME2 = SYSDATETIME();
    DECLARE @StatusMsg NVARCHAR(500);
    DECLARE @ErrorOccurred BIT = 0;

    IF @LoadDate IS NULL
        SET @LoadDate = CAST(GETDATE() AS DATE);

    PRINT REPLICATE('=', 70);
    PRINT 'TRANSPORTATION DATA WAREHOUSE - DIMENSION ETL ORCHESTRATION';
    PRINT CONCAT('Load Date: ', @LoadDate);
    PRINT CONCAT('Debug Mode: ', CASE WHEN @Debug = 1 THEN 'ON' ELSE 'OFF' END);
    PRINT Concat('Start Time: ', FORMAT(@StartTime, 'yyyy-MM-dd HH:mm:ss.fff'));
    PRINT REPLICATE('=', 70);

    -- Load DimDate (Static dimension from raw source)
    IF @ErrorOccurred = 0
    BEGIN
        PRINT CHAR(10) + 'Loading DimDate (Static Dimension)...';
        BEGIN TRY
            EXEC dw_transport.sp_load_dim_date
                @LoadDate = @LoadDate,
                @Debug = @Debug;

            SET @StatusMsg = CONCAT(
                'DimDate loaded successfully. Total records: ',
                (SELECT COUNT(*) FROM dw_transport.DimDate WHERE DateKey > -1)
            );
            PRINT @StatusMsg;
        END TRY
        BEGIN CATCH
            PRINT '*** ERROR loading DimDate ***';
            PRINT ERROR_MESSAGE();
            SET @ErrorOccurred = 1;
        END CATCH
    END

    PRINT CHAR(10) + 'DimMode: Static reference. Pre-populated. Skipping.';
    PRINT 'DimServiceType: Static reference. Pre-populated. Skipping.';

    -- Load DimAgency (SCD Type 2)
    IF @SkipAgency = 0
    BEGIN
        PRINT CHAR(10) + 'Loading DimAgency (SCD Type 2)...';
        BEGIN TRY
            EXEC dw_transport.sp_load_dim_agency
                @LoadDate = @LoadDate,
                @Debug = @Debug;

            SET @StatusMsg = CONCAT(
                'DimAgency loaded successfully. ',
                'Current records: ',
                (SELECT COUNT(*) FROM dw_transport.DimAgency WHERE CurrentFlag = 1),
                ' (Total historical: ',
                (SELECT COUNT(*) FROM dw_transport.DimAgency WHERE AgencyKey != -1),
                ')'
            );
            PRINT @StatusMsg;
        END TRY
        BEGIN CATCH
            PRINT '*** ERROR loading DimAgency ***';
            PRINT ERROR_MESSAGE();
            SET @ErrorOccurred = 1;
        END CATCH
    END
    ELSE
        PRINT CHAR(10) + 'DimAgency: Skipped per parameter.';

    -- Load DimUrbanArea (SCD Type 2)
    IF @SkipUrbanArea = 0 AND @ErrorOccurred = 0
    BEGIN
        PRINT CHAR(10) + 'Loading DimUrbanArea (SCD Type 2)...';
        BEGIN TRY
            EXEC dw_transport.sp_load_dim_urban_area
                @LoadDate = @LoadDate,
                @Debug = @Debug;

            SET @StatusMsg = CONCAT(
                'DimUrbanArea loaded successfully. ',
                'Current records: ',
                (SELECT COUNT(*) FROM dw_transport.DimUrbanArea WHERE CurrentFlag = 1),
                ' (Total historical: ',
                (SELECT COUNT(*) FROM dw_transport.DimUrbanArea WHERE UrbanAreaKey != -1),
                ')'
            );
            PRINT @StatusMsg;
        END TRY
        BEGIN CATCH
            PRINT '*** ERROR loading DimUrbanArea ***';
            PRINT ERROR_MESSAGE();
            SET @ErrorOccurred = 1;
        END CATCH
    END
    ELSE IF @SkipUrbanArea = 1
        PRINT CHAR(10) + 'DimUrbanArea: Skipped per parameter.';

    -- Load DimSafetyEventType
    IF @SkipSafetyEventType = 0 AND @ErrorOccurred = 0
    BEGIN
        PRINT CHAR(10) + 'Loading DimSafetyEventType...';
        BEGIN TRY
            EXEC dw_transport.sp_load_dim_safety_event_type
                @LoadDate = @LoadDate,
                @Debug = @Debug;

            SET @StatusMsg = CONCAT(
                'DimSafetyEventType loaded successfully. ',
                'Total records: ',
                (SELECT COUNT(*) FROM dw_transport.DimSafetyEventType WHERE SafetyEventTypeKey != -1)
            );
            PRINT @StatusMsg;
        END TRY
        BEGIN CATCH
            PRINT '*** ERROR loading DimSafetyEventType ***';
            PRINT ERROR_MESSAGE();
            SET @ErrorOccurred = 1;
        END CATCH
    END
    ELSE IF @SkipSafetyEventType = 1
        PRINT CHAR(10) + 'DimSafetyEventType: Skipped per parameter.';

    -- Load DimSafetyIncident
    IF @SkipSafetyIncident = 0 AND @ErrorOccurred = 0
    BEGIN
        PRINT CHAR(10) + 'Loading DimSafetyIncident...';
        BEGIN TRY
            EXEC dw_transport.sp_load_dim_safety_incident
                @LoadDate = @LoadDate,
                @Debug = @Debug;

            SET @StatusMsg = CONCAT(
                'DimSafetyIncident loaded successfully. ',
                'Total records: ',
                (SELECT COUNT(*) FROM dw_transport.DimSafetyIncident WHERE SafetyIncidentKey != -1)
            );
            PRINT @StatusMsg;
        END TRY
        BEGIN CATCH
            PRINT '*** ERROR loading DimSafetyIncident ***';
            PRINT ERROR_MESSAGE();
            SET @ErrorOccurred = 1;
        END CATCH
    END
    ELSE IF @SkipSafetyIncident = 1
        PRINT CHAR(10) + 'DimSafetyIncident: Skipped per parameter.';

    -- Final summary
    PRINT CHAR(10) + REPLICATE('=', 70);

    IF @ErrorOccurred = 1
    BEGIN
        PRINT '*** DIMENSION ETL COMPLETED WITH ERRORS ***';
        PRINT 'Review error messages above for details.';
    END
    ELSE
    BEGIN
        PRINT 'DIMENSION ETL COMPLETED SUCCESSFULLY';
    END

    DECLARE @EndTime DATETIME2 = SYSDATETIME();
    PRINT CONCAT('End Time: ', FORMAT(@EndTime, 'yyyy-MM-dd HH:mm:ss.fff'));
    PRINT CONCAT('Total Duration: ', DATEDIFF(SECOND, @StartTime, @EndTime), ' seconds');
    PRINT REPLICATE('=', 70);

    -- Show audit log summary
    PRINT CHAR(10) + 'ETL Audit Log Summary:';
    SELECT
        procedure_name,
        load_date,
        status,
        rows_processed,
        rows_inserted,
        rows_updated,
        rows_deleted,
        duplicate_count,
        DATEDIFF(SECOND, load_start_time, ISNULL(load_end_time, SYSDATETIME())) AS duration_seconds
    FROM dw_transport.etl_load_audit
    WHERE load_date = @LoadDate
    ORDER BY audit_id DESC;

    IF @ErrorOccurred = 1
        RETURN 1;
    ELSE
        RETURN 0;
END;
GO
