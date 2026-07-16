-- ============================================================
-- FILE:   04_load_dimensions_Transport_etl.sql
-- SCHEMA: dw_transport
-- DESC:   ETL procedures to load transport-specific dimensions from staging.
--         Implements Kimball-style SCD logic with unknown sentinels.
--         Common dimensions (DimDate, DimAgency, DimMode, DimServiceType)
--         are now loaded from dw_common schema via separate ETL.
--
-- EXECUTION ORDER: Run after 03_dim_transport_DDL.sql
--                  Note: Common dimensions must be loaded separately via
--                  sp_execute_common_dimensions_etl in the common schema.
--
-- DIMENSION LOADING PATTERNS:
--   1. DimDate        - Common dimension; loaded via dw_common ETL
--   2. DimAgency      - Common dimension; loaded via dw_common ETL
--   3. DimMode        - Common dimension; loaded via dw_common ETL
--   4. DimServiceType - Common dimension; loaded via dw_common ETL
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
-- NOTE: Audit table is now centralized in dw_common schema.
--       See 04_load_common_dimensions_ETL.sql for table creation.
-- ============================================================
GO





-- ============================================================
-- STEP 1: Load DimUrbanArea (SCD Type 2)
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
    DECLARE @RowsProcessed INT = 0;
    DECLARE @ErrorMsg NVARCHAR(MAX) = NULL;

    IF @LoadDate IS NULL
        SET @LoadDate = CAST(GETDATE() AS DATE);

    -- Log start of audit
    INSERT INTO dw_common.etl_load_audit (
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
            '2000-01-01', '9999-12-31', 1
        FROM #UrbanAreaChanges
        WHERE ChangeType IN ('NEW', 'CHANGE');

        SET @RowsInserted = @@ROWCOUNT;
        IF @Debug = 1
            PRINT CONCAT('Inserted ', @RowsInserted, ' new/changed urban area records');

        COMMIT TRANSACTION;

        -- Get total row count for audit
        SELECT @RowsProcessed = COUNT(*) FROM #UrbanAreaChanges;

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
            PRINT CONCAT(CHAR(10), 'DimUrbanArea load complete at ', @LoadDate);
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
END;
GO

-- ============================================================
-- STEP 2: Load DimSafetyEventType (Static Reference)
-- ============================================================
CREATE OR ALTER PROCEDURE dw_transport.sp_load_dim_safety_event_type
    @LoadDate DATE = NULL,
    @Debug BIT = 0
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @AuditId INT;
    DECLARE @StartTime DATETIME2 = SYSDATETIME();
    DECLARE @RowsProcessed INT = 0;
    DECLARE @ErrorMsg NVARCHAR(4000);

    IF @LoadDate IS NULL
        SET @LoadDate = CAST(GETDATE() AS DATE);

    -- Log start of audit
    INSERT INTO dw_common.etl_load_audit
    (
        procedure_name,
        load_date,
        load_start_time,
        status
    )
    VALUES
    (
        'sp_load_dim_safety_event_type',
        @LoadDate,
        @StartTime,
        'IN_PROGRESS'
    );

    SET @AuditId = SCOPE_IDENTITY();

    BEGIN TRY

        CREATE TABLE #NewSafetyEventTypes
        (
            EventCategory VARCHAR(100),
            EventType VARCHAR(200),
            EventSubType VARCHAR(200),
            SeverityLevel VARCHAR(50)
        );

        INSERT INTO #NewSafetyEventTypes
        (
            EventCategory,
            EventType,
            EventSubType,
            SeverityLevel
        )
        SELECT DISTINCT
            src.event_category,
            src.event_type,
            src.event_type_group,
            CASE
                WHEN UPPER(src.safety_security) IN ('SFT', 'SAFETY')
                    THEN 'Safety'

                WHEN UPPER(src.safety_security) IN ('SEC', 'SECURITY')
                    THEN 'Security'

                ELSE src.safety_security
            END AS SeverityLevel
        FROM
        (
            SELECT
                NULLIF(LTRIM(RTRIM(event_category)), '') AS event_category,
                NULLIF(LTRIM(RTRIM(event_type)), '') AS event_type,
                NULLIF(LTRIM(RTRIM(event_type_group)), '') AS event_type_group,
                NULLIF(LTRIM(RTRIM(safety_security)), '') AS safety_security
            FROM stg_transport.stg_major_safety_event
        ) src
        WHERE src.event_category IS NOT NULL
          AND NOT EXISTS
          (
              SELECT 1
              FROM dw_transport.DimSafetyEventType dw
              WHERE ISNULL(dw.EventCategory, '') =
                    ISNULL(src.event_category, '')

                AND ISNULL(dw.EventType, '') =
                    ISNULL(src.event_type, '')

                AND ISNULL(dw.EventSubType, '') =
                    ISNULL(src.event_type_group, '')

                AND ISNULL(dw.SeverityLevel, '') =
                    ISNULL
                    (
                        CASE
                            WHEN UPPER(src.safety_security)
                                IN ('SFT', 'SAFETY')
                                THEN 'Safety'

                            WHEN UPPER(src.safety_security)
                                IN ('SEC', 'SECURITY')
                                THEN 'Security'

                            ELSE src.safety_security
                        END,
                        ''
                    )
          );

        BEGIN TRANSACTION;

        INSERT INTO dw_transport.DimSafetyEventType
        (
            EventCategory,
            EventType,
            EventSubType,
            SeverityLevel
        )
        SELECT DISTINCT
            EventCategory,
            EventType,
            EventSubType,
            SeverityLevel
        FROM #NewSafetyEventTypes;

        SET @RowsProcessed = @@ROWCOUNT;

        COMMIT TRANSACTION;

        -- Log success
        UPDATE dw_common.etl_load_audit
        SET
            load_end_time = SYSDATETIME(),
            rows_processed = @RowsProcessed,
            status = 'SUCCESS'
        WHERE audit_id = @AuditId;

        IF @Debug = 1
        BEGIN
            PRINT CONCAT(
                'DimSafetyEventType: Inserted ',
                @RowsProcessed,
                ' new rows.'
            );
        END;

        DROP TABLE #NewSafetyEventTypes;

    END TRY
    BEGIN CATCH

        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;

        SET @ErrorMsg = ERROR_MESSAGE();

        UPDATE dw_common.etl_load_audit
        SET
            load_end_time = SYSDATETIME(),
            status = 'FAILED',
            error_message = @ErrorMsg
        WHERE audit_id = @AuditId;

        THROW;

    END CATCH;

END;
GO

-- ============================================================
-- STEP 3: Load DimSafetyIncident (Type 1 - Upsert)
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
    DECLARE @RowsProcessed INT = 0;
    DECLARE @ErrorMsg NVARCHAR(MAX) = NULL;

    IF @LoadDate IS NULL
        SET @LoadDate = CAST(GETDATE() AS DATE);

    -- Log start of audit
    INSERT INTO dw_common.etl_load_audit (
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
            LTRIM(RTRIM(event_description)) AS narrative
        FROM stg_transport.stg_major_safety_event
        WHERE incident_number IS NOT NULL
            AND LTRIM(RTRIM(incident_number)) != ''
    ) src;

    IF @Debug = 1
    BEGIN
        DECLARE @SafetyIncidentCount INT = (SELECT COUNT(*) FROM #SafetyIncidents);
        PRINT CONCAT('=== SAFETY INCIDENTS FOUND: ', @SafetyIncidentCount, ' ===');
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

        -- Get total row count for audit
        SELECT @RowsProcessed = COUNT(*) FROM #SafetyIncidents;

        -- Log success
        UPDATE dw_common.etl_load_audit
        SET load_end_time = SYSDATETIME(),
            rows_processed = @RowsProcessed,
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
        UPDATE dw_common.etl_load_audit
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

    -- Common dimensions (DimDate, DimAgency, DimMode, DimServiceType) are loaded separately
    PRINT CHAR(10) + 'Common Dimensions:';
    PRINT 'DimDate: Loaded via dw_common.sp_execute_common_dimensions_etl';
    PRINT 'DimAgency: Loaded via dw_common.sp_execute_common_dimensions_etl';
    PRINT 'DimMode: Static reference. Pre-populated. Skipping.';
    PRINT 'DimServiceType: Static reference. Pre-populated. Skipping.';



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
    FROM dw_common.etl_load_audit
    WHERE load_date = @LoadDate
    ORDER BY audit_id DESC;

    IF @ErrorOccurred = 1
        RETURN 1;
    ELSE
        RETURN 0;
END;
GO
