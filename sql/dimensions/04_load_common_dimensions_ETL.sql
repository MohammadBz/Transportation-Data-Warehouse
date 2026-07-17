-- ============================================================
-- FILE:   02_load_common_dimensions_ETL.sql
-- SCHEMA: dw_common
-- DESC:   ETL procedures to load common dimensions from staging.
--         Implements Kimball-style SCD logic with unknown sentinels.
--
-- EXECUTION ORDER: Run after 01_dim_common_DDL.sql
--
-- DIMENSION LOADING PATTERNS:
--   1. DimDate        - Static; pre-loaded from staging
--   2. DimAgency      - SCD Type 2; merge on NTD_ID
--   3. DimMode        - Static; pre-populated; no ETL needed
--   4. DimServiceType - Static; pre-populated; no ETL needed
--
-- IMPROVEMENTS IN THIS VERSION:
--   - Fixed NULL handling in change detection (uses ISNULL)
--   - Added indexes on temp tables for join/filter performance
--   - Moved LTRIM/RTRIM to staging preparation
--   - Added duplicate business key detection
--   - Optimized change detection with HASHBYTES
--   - Enhanced error handling with proper transaction rollback checks
--   - Better debug output and diagnostics
--   - Prevents cascade failures in master orchestration
--   - Only updates Type 1 when data actually changes
--   - Added ETL audit logging table for data quality tracking
--
-- ============================================================

USE [TransportationDB];
GO


-- ============================================================
-- STEP 0: Load DimDate (Static Dimension from Raw Source)
-- ============================================================

CREATE OR ALTER PROCEDURE dw_common.sp_load_dim_date
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
    INSERT INTO dw_common.etl_load_audit (
        procedure_name, load_date, load_start_time, status
    )
    VALUES ('sp_load_dim_date', @LoadDate, @StartTime, 'IN_PROGRESS');
    SET @AuditId = SCOPE_IDENTITY();

    DECLARE @RowsProcessed INT = 0;

    BEGIN TRY
        -- Load DimDate from raw source, skipping rows that already exist
        -- DimDate is static (no SCD needed), so we only insert new dates
        INSERT INTO dw_common.DimDate (
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
            TRY_CAST(src.Id AS INT),
            TRY_CAST(src.Date AS DATE),
            NULLIF(src.DayLongName, 'undefined'), NULLIF(src.DayShortName, 'undefined'),
            NULLIF(src.MonthLongName, 'undefined'), NULLIF(src.MonthShortName, 'undefined'),
            TRY_CAST(NULLIF(src.CalendarDay, 'undefined') AS INT), TRY_CAST(NULLIF(src.CalendarDayInWeek, 'undefined') AS INT),
            TRY_CAST(NULLIF(src.CalendarWeek, 'undefined') AS INT), TRY_CAST(NULLIF(src.CalendarWeekStartDateId, 'undefined') AS INT), TRY_CAST(NULLIF(src.CalendarWeekEndDateId, 'undefined') AS INT),
            TRY_CAST(NULLIF(src.CalendarMonth, 'undefined') AS INT), TRY_CAST(NULLIF(src.CalendarMonthStartDateId, 'undefined') AS INT), TRY_CAST(NULLIF(src.CalendarMonthEndDateId, 'undefined') AS INT),
            TRY_CAST(NULLIF(src.CalendarNumberOfDaysInMonth, 'undefined') AS INT), TRY_CAST(NULLIF(src.CalendarDayInMonth, 'undefined') AS INT),
            TRY_CAST(NULLIF(src.CalendarQuarter, 'undefined') AS INT), TRY_CAST(NULLIF(src.CalendarQuarterStartDateId, 'undefined') AS INT), TRY_CAST(NULLIF(src.CalendarQuarterEndDateId, 'undefined') AS INT),
            TRY_CAST(NULLIF(src.CalendarNumberOfDaysInQuarter, 'undefined') AS INT), TRY_CAST(NULLIF(src.CalendarDayInQuarter, 'undefined') AS INT),
            TRY_CAST(NULLIF(src.CalendarYear, 'undefined') AS INT), TRY_CAST(NULLIF(src.CalendarYearStartDateId, 'undefined') AS INT), TRY_CAST(NULLIF(src.CalendarYearEndDateId, 'undefined') AS INT),
            TRY_CAST(NULLIF(src.CalendarNumberOfDaysInYear, 'undefined') AS INT)
        FROM [TransportationDB].[raw_transport].[raw_dimdates] src
        WHERE TRY_CAST(src.Id AS INT) IS NOT NULL
          AND TRY_CAST(src.Date AS DATE) IS NOT NULL
          AND NOT EXISTS (
            SELECT 1 FROM dw_common.DimDate dw
            WHERE dw.DateKey = TRY_CAST(src.Id AS INT)
        );

        SET @RowsInserted = @@ROWCOUNT;

        IF @Debug = 1
            PRINT CONCAT('DimDate: Inserted ', @RowsInserted, ' new date records');

        -- Get total row count for audit
        SELECT @RowsProcessed = COUNT(*) FROM dw_common.DimDate WHERE DateKey > -1;

        -- Update audit table with success
        UPDATE dw_common.etl_load_audit
        SET load_end_time = SYSDATETIME(),
            rows_processed = @RowsProcessed,
            rows_inserted = @RowsInserted,
            status = 'SUCCESS'
        WHERE audit_id = @AuditId;

        IF @Debug = 1
            PRINT CONCAT(CHAR(10), 'DimDate load complete. Total dimension rows: ', @RowsProcessed);
    END TRY
    BEGIN CATCH
        SET @ErrorMsg = ERROR_MESSAGE();

        -- Log failure
        UPDATE dw_common.etl_load_audit
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

CREATE OR ALTER PROCEDURE dw_common.sp_load_dim_agency
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
    DECLARE @RowsProcessed INT = 0;
    DECLARE @ErrorMsg NVARCHAR(MAX) = NULL;

    IF @LoadDate IS NULL
        SET @LoadDate = CAST(GETDATE() AS DATE);

    -- Log start of audit
    INSERT INTO dw_common.etl_load_audit (
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
    LEFT JOIN dw_common.DimAgency dw
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
        SELECT
            CONCAT('NTD_ID: ', NTD_ID, ' | Type: ', ChangeType) AS ChangeLog
        FROM #AgencyChanges
        WHERE ChangeType IN ('NEW', 'CHANGE');
    END

    BEGIN TRANSACTION;

    BEGIN TRY
        -- Step 1: Expire current rows for changed agencies (SCD Type 2)
        UPDATE dw_common.DimAgency
        SET ExpirationDate = DATEADD(DAY, -1, @LoadDate),
            CurrentFlag = 0
        WHERE NTD_ID IN (SELECT NTD_ID FROM #AgencyChanges WHERE ChangeType = 'CHANGE')
          AND CurrentFlag = 1
          AND AgencyKey != -1;

        SET @RowsUpdated = @@ROWCOUNT;
        IF @Debug = 1
            PRINT CONCAT('Expired ', @RowsUpdated, ' agency history rows');

        -- Step 2: Insert new rows for new agencies
        INSERT INTO dw_common.DimAgency (
            NTD_ID, LegacyNTD_ID, AgencyName, OrganizationType,
            City, State, Region,
            ServiceAreaSqMiles, ServiceAreaPopulation,
            EffectiveDate, ExpirationDate, CurrentFlag
        )
SELECT
    NTD_ID,
    LegacyNTD_ID,
    AgencyName,
    OrganizationType,
    City,
    State,
    Region,
    ServiceAreaSqMiles,
    ServiceAreaPopulation,

    CASE
        WHEN ChangeType = 'NEW'
            THEN CAST('2000-01-01' AS DATE)
        WHEN ChangeType = 'CHANGE'
            THEN @LoadDate
    END AS EffectiveDate,

    CAST('9999-12-31' AS DATE) AS ExpirationDate,
    1 AS CurrentFlag

FROM #AgencyChanges
WHERE ChangeType IN ('NEW', 'CHANGE');

        SET @RowsInserted = @@ROWCOUNT;
        IF @Debug = 1
            PRINT CONCAT('Inserted ', @RowsInserted, ' new agency rows');

        COMMIT TRANSACTION;

        -- Get total row count for audit
        SELECT @RowsProcessed = COUNT(*) FROM dw_common.DimAgency WHERE AgencyKey != -1;

        -- Log success
        UPDATE dw_common.etl_load_audit
        SET load_end_time = SYSDATETIME(),
            rows_processed = @RowsProcessed,
            rows_inserted = @RowsInserted,
            rows_updated = @RowsUpdated,
            duplicate_count = @DuplicateCount,
            status = 'SUCCESS'
        WHERE audit_id = @AuditId;

        IF @Debug = 1
            PRINT CHAR(10) + 'DimAgency load complete';
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;

        SET @ErrorMsg = ERROR_MESSAGE();

        -- Log failure
        UPDATE dw_common.etl_load_audit
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
-- STEP 2: Load DimMode (Static Dimension)
-- ============================================================

CREATE OR ALTER PROCEDURE dw_common.sp_load_dim_mode
    @LoadDate DATE = NULL,
    @Debug BIT = 0
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @AuditId INT;
    DECLARE @StartTime DATETIME2 = SYSDATETIME();
    DECLARE @RowsProcessed INT = 0;
    DECLARE @ErrorMessage NVARCHAR(4000);

    IF @LoadDate IS NULL
        SET @LoadDate = CAST(GETDATE() AS DATE);

    INSERT INTO dw_common.etl_load_audit
    (
        procedure_name,
        load_date,
        load_start_time,
        status
    )
    VALUES
    (
        'sp_load_dim_mode',
        @LoadDate,
        @StartTime,
        'IN_PROGRESS'
    );

    SET @AuditId = SCOPE_IDENTITY();

    BEGIN TRY

        SELECT
            @RowsProcessed = COUNT(*)
        FROM dw_common.DimMode
        WHERE ModeKey > -1;

        UPDATE dw_common.etl_load_audit
        SET
            load_end_time = SYSDATETIME(),
            rows_processed = @RowsProcessed,
            status = 'SUCCESS'
        WHERE audit_id = @AuditId;

        IF @Debug = 1
        BEGIN
            PRINT CONCAT(
                'DimMode: Static dimension. Total rows: ',
                @RowsProcessed
            );
        END;

    END TRY
    BEGIN CATCH

        SET @ErrorMessage = ERROR_MESSAGE();

        UPDATE dw_common.etl_load_audit
        SET
            load_end_time = SYSDATETIME(),
            status = 'FAILED',
            error_message = @ErrorMessage
        WHERE audit_id = @AuditId;

        THROW;

    END CATCH;
END;
GO


-- ============================================================
-- STEP 3: Load DimServiceType (Static Dimension)
-- ============================================================

CREATE OR ALTER PROCEDURE dw_common.sp_load_dim_service_type
    @LoadDate DATE = NULL,
    @Debug BIT = 0
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @AuditId INT;
    DECLARE @StartTime DATETIME2 = SYSDATETIME();
    DECLARE @RowsProcessed INT = 0;
    DECLARE @ErrorMessage NVARCHAR(4000);

    IF @LoadDate IS NULL
        SET @LoadDate = CAST(GETDATE() AS DATE);

    INSERT INTO dw_common.etl_load_audit
    (
        procedure_name,
        load_date,
        load_start_time,
        status
    )
    VALUES
    (
        'sp_load_dim_service_type',
        @LoadDate,
        @StartTime,
        'IN_PROGRESS'
    );

    SET @AuditId = SCOPE_IDENTITY();

    BEGIN TRY

        SELECT
            @RowsProcessed = COUNT(*)
        FROM dw_common.DimServiceType
        WHERE ServiceTypeKey > -1;

        UPDATE dw_common.etl_load_audit
        SET
            load_end_time = SYSDATETIME(),
            rows_processed = @RowsProcessed,
            status = 'SUCCESS'
        WHERE audit_id = @AuditId;

        IF @Debug = 1
        BEGIN
            PRINT CONCAT(
                'DimServiceType: Static dimension. Total rows: ',
                @RowsProcessed
            );
        END;

    END TRY
    BEGIN CATCH

        SET @ErrorMessage = ERROR_MESSAGE();

        UPDATE dw_common.etl_load_audit
        SET
            load_end_time = SYSDATETIME(),
            status = 'FAILED',
            error_message = @ErrorMessage
        WHERE audit_id = @AuditId;

        THROW;

    END CATCH;
END;
GO

-- ============================================================
-- MASTER ETL ORCHESTRATION PROCEDURE
-- ============================================================

CREATE OR ALTER PROCEDURE dw_common.sp_execute_common_dimensions_etl
    @LoadDate DATE = NULL,
    @Debug BIT = 0,
    @SkipDate BIT = 0,
    @SkipAgency BIT = 0,
    @SkipMode BIT = 0,
    @SkipServiceType BIT = 0
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @StartTime DATETIME2 = SYSDATETIME();
    DECLARE @StatusMsg NVARCHAR(500);
    DECLARE @ErrorOccurred BIT = 0;

    IF @LoadDate IS NULL
        SET @LoadDate = CAST(GETDATE() AS DATE);

    PRINT REPLICATE('=', 70);
    PRINT 'COMMON DIMENSIONS DATA WAREHOUSE - ETL ORCHESTRATION';
    PRINT CONCAT('Load Date: ', @LoadDate);
    PRINT CONCAT('Debug Mode: ', CASE WHEN @Debug = 1 THEN 'ON' ELSE 'OFF' END);
    PRINT Concat('Start Time: ', FORMAT(@StartTime, 'yyyy-MM-dd HH:mm:ss.fff'));
    PRINT REPLICATE('=', 70);

    -- Load DimDate (Static dimension from raw source)
    IF @SkipDate = 0 AND @ErrorOccurred = 0
    BEGIN
        PRINT CHAR(10) + 'Loading DimDate (Static Dimension)...';
        BEGIN TRY
            EXEC dw_common.sp_load_dim_date
                @LoadDate = @LoadDate,
                @Debug = @Debug;

            SET @StatusMsg = CONCAT(
                'DimDate loaded successfully. Total records: ',
                (SELECT COUNT(*) FROM dw_common.DimDate WHERE DateKey > -1)
            );
            PRINT @StatusMsg;
        END TRY
        BEGIN CATCH
            PRINT '*** ERROR loading DimDate ***';
            PRINT ERROR_MESSAGE();
            SET @ErrorOccurred = 1;
        END CATCH
    END

    -- Load DimAgency (SCD Type 2)
    IF @SkipAgency = 0 AND @ErrorOccurred = 0
    BEGIN
        PRINT CHAR(10) + 'Loading DimAgency (SCD Type 2)...';
        BEGIN TRY
            EXEC dw_common.sp_load_dim_agency
                @LoadDate = @LoadDate,
                @Debug = @Debug;

            SET @StatusMsg = CONCAT(
                'DimAgency loaded successfully. ',
                'Current records: ',
                (SELECT COUNT(*) FROM dw_common.DimAgency WHERE CurrentFlag = 1),
                ' (Total historical: ',
                (SELECT COUNT(*) FROM dw_common.DimAgency WHERE AgencyKey != -1),
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

    -- Load DimMode (Static reference)
    IF @SkipMode = 0 AND @ErrorOccurred = 0
    BEGIN
        PRINT CHAR(10) + 'Loading DimMode (Static Reference)...';
        BEGIN TRY
            EXEC dw_common.sp_load_dim_mode
                @LoadDate = @LoadDate,
                @Debug = @Debug;

            SET @StatusMsg = CONCAT(
                'DimMode verified. Total records: ',
                (SELECT COUNT(*) FROM dw_common.DimMode WHERE ModeKey > -1)
            );
            PRINT @StatusMsg;
        END TRY
        BEGIN CATCH
            PRINT '*** ERROR loading DimMode ***';
            PRINT ERROR_MESSAGE();
            SET @ErrorOccurred = 1;
        END CATCH
    END

    -- Load DimServiceType (Static reference)
    IF @SkipServiceType = 0 AND @ErrorOccurred = 0
    BEGIN
        PRINT CHAR(10) + 'Loading DimServiceType (Static Reference)...';
        BEGIN TRY
            EXEC dw_common.sp_load_dim_service_type
                @LoadDate = @LoadDate,
                @Debug = @Debug;

            SET @StatusMsg = CONCAT(
                'DimServiceType verified. Total records: ',
                (SELECT COUNT(*) FROM dw_common.DimServiceType WHERE ServiceTypeKey > -1)
            );
            PRINT @StatusMsg;
        END TRY
        BEGIN CATCH
            PRINT '*** ERROR loading DimServiceType ***';
            PRINT ERROR_MESSAGE();
            SET @ErrorOccurred = 1;
        END CATCH
    END

    -- Summary
    PRINT CHAR(10) + REPLICATE('=', 70);
    IF @ErrorOccurred = 0
    BEGIN
        PRINT 'ETL ORCHESTRATION COMPLETED SUCCESSFULLY';
    END
    ELSE
    BEGIN
        PRINT 'ETL ORCHESTRATION COMPLETED WITH ERRORS';
    END
    PRINT CONCAT('End Time: ', FORMAT(SYSDATETIME(), 'yyyy-MM-dd HH:mm:ss.fff'));
    PRINT CONCAT('Total Duration: ',
        DATEDIFF(SECOND, @StartTime, SYSDATETIME()), ' seconds');
    PRINT REPLICATE('=', 70);
END;
GO
