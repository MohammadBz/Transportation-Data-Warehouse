-- ============================================================
-- FILE:   00_master_etl_orchestration.sql
-- SCHEMA: dw_transport (primary), dw_common, dw_HR (secondary)
-- DESC:   Master orchestration procedure for the complete
--         Data Warehouse ETL process across all three marts:
--         1. Common Data Mart (shared dimensions)
--         2. Transportation Data Mart
--         3. HR Data Mart
--
--         Execution Order:
--         1. Load Staging (Truncate and Load) - Transport only
--         2. Load Common Dimensions (DimDate, DimAgency, DimMode, DimServiceType)
--         3. Load Transport Dimensions & Facts
--         4. Load HR Dimensions & Facts
--
-- EXECUTION ORDER: Run after all DDL and ETL procedure
--                  definitions are created
--
-- STORED PROCEDURES CREATED:
--   1. sp_Master_ETL_Load_All_Marts (new: orchestrates all three marts)
--   2. sp_Master_ETL_Load_Common    (new: orchestrates common mart)
--   3. sp_Master_ETL_Load_Transport (existing: refactored from original)
--   4. sp_Master_ETL_Load_HR        (new: orchestrates HR mart)
--
-- USAGE:
--   -- Full load across all marts with default settings
--   EXEC dw_transport.sp_Master_ETL_Load_All_Marts;
--
--   -- Full load with debug mode
--   EXEC dw_transport.sp_Master_ETL_Load_All_Marts
--       @LoadDate = '2024-01-15',
--       @BatchID = 20240115001,
--       @Debug = 1;
--
--   -- Skip specific marts
--   EXEC dw_transport.sp_Master_ETL_Load_All_Marts
--       @SkipCommon = 0,
--       @SkipTransport = 0,
--       @SkipHR = 1;
--
--   -- Load individual marts
--   EXEC dw_transport.sp_Master_ETL_Load_Common @LoadDate = '2024-01-15', @Debug = 1;
--   EXEC dw_transport.sp_Master_ETL_Load_Transport @LoadDate = '2024-01-15', @Debug = 1;
--   EXEC dw_transport.sp_Master_ETL_Load_HR @LoadDate = '2024-01-15', @BatchID = 20240115001;
--
-- ============================================================

-- ============================================================
-- Drop existing procedures if they exist
-- ============================================================
IF OBJECT_ID('dw_transport.sp_Master_ETL_Load_All_Marts', 'P') IS NOT NULL
    DROP PROCEDURE dw_transport.sp_Master_ETL_Load_All_Marts;
GO

IF OBJECT_ID('dw_transport.sp_Master_ETL_Load_Common', 'P') IS NOT NULL
    DROP PROCEDURE dw_transport.sp_Master_ETL_Load_Common;
GO

IF OBJECT_ID('dw_transport.sp_Master_ETL_Load_Transport', 'P') IS NOT NULL
    DROP PROCEDURE dw_transport.sp_Master_ETL_Load_Transport;
GO

IF OBJECT_ID('dw_transport.sp_Master_ETL_Load_HR', 'P') IS NOT NULL
    DROP PROCEDURE dw_transport.sp_Master_ETL_Load_HR;
GO

-- ============================================================
-- Common Data Mart Master Procedure
-- ============================================================
CREATE PROCEDURE dw_transport.sp_Master_ETL_Load_Common
    @LoadDate DATE = NULL,
    @Debug BIT = 0,
    @SkipDate BIT = 0,
    @SkipAgency BIT = 0,
    @SkipMode BIT = 0,
    @SkipServiceType BIT = 0
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    DECLARE @StartTime DATETIME2 = SYSDATETIME();
    DECLARE @EndTime DATETIME2;
    DECLARE @ElapsedSeconds DECIMAL(10, 2);
    DECLARE @ErrorOccurred BIT = 0;

    -- ============================================================
    -- Initialize default values
    -- ============================================================
    IF @LoadDate IS NULL
        SET @LoadDate = CAST(GETDATE() AS DATE);

    -- ============================================================
    -- Print header
    -- ============================================================
    PRINT REPLICATE('=', 80);
    PRINT '   COMMON DATA MART - MASTER ETL ORCHESTRATION';
    PRINT REPLICATE('=', 80);
    PRINT '';
    PRINT CONCAT('Load Date:           ', FORMAT(@LoadDate, 'yyyy-MM-dd'));
    PRINT CONCAT('Start Time:          ', FORMAT(@StartTime, 'yyyy-MM-dd HH:mm:ss.fff'));
    PRINT CONCAT('Debug Mode:          ', CASE WHEN @Debug = 1 THEN 'ON' ELSE 'OFF' END);
    PRINT '';
    PRINT 'Processing Dimensions:';
    PRINT CONCAT('  1. DimDate:        ', CASE WHEN @SkipDate = 0 THEN 'ENABLED' ELSE 'SKIPPED' END);
    PRINT CONCAT('  2. DimAgency:      ', CASE WHEN @SkipAgency = 0 THEN 'ENABLED' ELSE 'SKIPPED' END);
    PRINT CONCAT('  3. DimMode:        ', CASE WHEN @SkipMode = 0 THEN 'ENABLED' ELSE 'SKIPPED' END);
    PRINT CONCAT('  4. DimServiceType: ', CASE WHEN @SkipServiceType = 0 THEN 'ENABLED' ELSE 'SKIPPED' END);
    PRINT '';
    PRINT REPLICATE('=', 80);
    PRINT '';

    BEGIN TRY

        -- ============================================================
        -- Execute Common Dimensions ETL
        -- ============================================================
        PRINT CHAR(10) + REPLICATE('-', 80);
        PRINT 'LOADING COMMON DIMENSIONS';
        PRINT REPLICATE('-', 80);
        PRINT '';

        BEGIN TRY
            PRINT 'Initiating common dimension load orchestration...';
            PRINT '';

            EXEC dw_common.sp_execute_common_dimensions_etl
                @LoadDate = @LoadDate,
                @Debug = @Debug,
                @SkipDate = @SkipDate,
                @SkipAgency = @SkipAgency,
                @SkipMode = @SkipMode,
                @SkipServiceType = @SkipServiceType;

            PRINT '';
            PRINT CONCAT('Common Dimensions Phase completed at ', FORMAT(SYSDATETIME(), 'HH:mm:ss.fff'));

        END TRY
        BEGIN CATCH
            PRINT '';
            PRINT '*** ERROR DURING COMMON DIMENSIONS LOAD ***';
            PRINT ERROR_MESSAGE();
            SET @ErrorOccurred = 1;

            IF @Debug = 1
            BEGIN
                PRINT 'Debug Info:';
                PRINT CONCAT('Error Number: ', ERROR_NUMBER());
                PRINT CONCAT('Error Line: ', ERROR_LINE());
                PRINT CONCAT('Error Severity: ', ERROR_SEVERITY());
                PRINT CONCAT('Error State: ', ERROR_STATE());
            END
        END CATCH

    END TRY
    BEGIN CATCH
        PRINT '';
        PRINT REPLICATE('=', 80);
        PRINT '*** FATAL ERROR IN COMMON MART ETL PROCESS ***';
        PRINT REPLICATE('=', 80);
        PRINT ERROR_MESSAGE();
        SET @ErrorOccurred = 1;
    END CATCH

    -- ============================================================
    -- Print Summary
    -- ============================================================
    SET @EndTime = SYSDATETIME();
    SET @ElapsedSeconds = DATEDIFF(SECOND, @StartTime, @EndTime);

    PRINT '';
    PRINT REPLICATE('=', 80);
    IF @ErrorOccurred = 0
    BEGIN
        PRINT '   COMMON MART ETL COMPLETED SUCCESSFULLY';
    END
    ELSE
    BEGIN
        PRINT '   COMMON MART ETL COMPLETED WITH ERRORS';
    END
    PRINT REPLICATE('=', 80);
    PRINT '';
    PRINT CONCAT('End Time:            ', FORMAT(@EndTime, 'yyyy-MM-dd HH:mm:ss.fff'));
    PRINT CONCAT('Elapsed Time:        ', CONCAT(@ElapsedSeconds, ' seconds'));
    PRINT '';

    -- Return error status
    IF @ErrorOccurred = 1
    BEGIN
        THROW 50001, 'Common Mart ETL process encountered errors. Review messages above.', 1;
    END

END;
GO

-- ============================================================
-- Transportation Data Mart Master Procedure
-- ============================================================
CREATE PROCEDURE dw_transport.sp_Master_ETL_Load_Transport
    @LoadDate DATE = NULL,
    @BatchID BIGINT = NULL,
    @Debug BIT = 1,
    @SkipStaging BIT = 1,
    @SkipDimensions BIT = 0,
    @SkipFacts BIT = 0,
    @SkipUrbanArea BIT = 0,
    @SkipSafetyEventType BIT = 0,
    @SkipSafetyIncident BIT = 0,
    @ReloadIfExists BIT = 0
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    DECLARE @StartTime DATETIME2 = SYSDATETIME();
    DECLARE @EndTime DATETIME2;
    DECLARE @ElapsedSeconds DECIMAL(10, 2);
    DECLARE @ErrorOccurred BIT = 0;
    DECLARE @CurrentBatchID BIGINT;
    DECLARE @StatusMsg NVARCHAR(1000);

    -- ============================================================
    -- Initialize default values
    -- ============================================================
    IF @LoadDate IS NULL
        SET @LoadDate = CAST(GETDATE() AS DATE);

    IF @BatchID IS NULL
        SET @CurrentBatchID = CAST(FORMAT(GETDATE(), 'yyyyMMddHHmmss') AS BIGINT);
    ELSE
        SET @CurrentBatchID = @BatchID;

    -- ============================================================
    -- Print header
    -- ============================================================
    PRINT REPLICATE('=', 80);
    PRINT '   TRANSPORTATION DATA MART - MASTER ETL ORCHESTRATION';
    PRINT REPLICATE('=', 80);
    PRINT '';
    PRINT CONCAT('Load Date:           ', FORMAT(@LoadDate, 'yyyy-MM-dd'));
    PRINT CONCAT('Batch ID:            ', @CurrentBatchID);
    PRINT CONCAT('Start Time:          ', FORMAT(@StartTime, 'yyyy-MM-dd HH:mm:ss.fff'));
    PRINT CONCAT('Debug Mode:          ', CASE WHEN @Debug = 1 THEN 'ON' ELSE 'OFF' END);
    PRINT '';
    PRINT 'Processing Steps:';
    PRINT CONCAT('  1. Staging Load:     ', CASE WHEN @SkipStaging = 0 THEN 'ENABLED' ELSE 'SKIPPED' END);
    PRINT CONCAT('  2. Dimensions ETL:   ', CASE WHEN @SkipDimensions = 0 THEN 'ENABLED' ELSE 'SKIPPED' END);
    PRINT CONCAT('  3. Facts ETL:        ', CASE WHEN @SkipFacts = 0 THEN 'ENABLED' ELSE 'SKIPPED' END);
    PRINT '';
    PRINT REPLICATE('=', 80);
    PRINT '';

    BEGIN TRY

        -- ============================================================
        -- PHASE 1: STAGING LOAD
        -- ============================================================
        IF @SkipStaging = 0
        BEGIN
            PRINT CHAR(10) + REPLICATE('-', 80);
            PRINT 'PHASE 1: LOADING STAGING TABLES (Truncate and Load Pattern)';
            PRINT REPLICATE('-', 80);

            BEGIN TRY
                PRINT '';
                PRINT 'Truncating and loading staging tables...';
                PRINT '  - Truncating agency tables';
                PRINT '  - Truncating service metrics tables (TS21)';
                PRINT '  - Truncating safety event tables';
                PRINT '  - Loading data from raw sources';
                PRINT '';

                -- Execute the staging load script
                -- Note: This file contains raw T-SQL statements (TRUNCATE and INSERT)
                -- We'll execute it by reading and executing its contents
                EXEC sp_executesql N'
                    TRUNCATE TABLE stg_transport.stg_agency_information;
                    TRUNCATE TABLE stg_transport.stg_agency_mode_service;
                    TRUNCATE TABLE stg_transport.stg_ts21_drm;
                    TRUNCATE TABLE stg_transport.stg_ts21_fares;
                    TRUNCATE TABLE stg_transport.stg_ts21_opexp_total;
                    TRUNCATE TABLE stg_transport.stg_ts21_upt;
                    TRUNCATE TABLE stg_transport.stg_ts21_pmt;
                    TRUNCATE TABLE stg_transport.stg_ts21_vrm;
                    TRUNCATE TABLE stg_transport.stg_ts21_vrh;
                    TRUNCATE TABLE stg_transport.stg_ts21_voms;
                    TRUNCATE TABLE stg_transport.stg_ts21_archive_drm;
                    TRUNCATE TABLE stg_transport.stg_ts21_archive_upt;
                    TRUNCATE TABLE stg_transport.stg_ts21_archive_pmt;
                    TRUNCATE TABLE stg_transport.stg_ts21_archive_vrm;
                    TRUNCATE TABLE stg_transport.stg_ts21_archive_vrh;
                    TRUNCATE TABLE stg_transport.stg_ts21_archive_voms;
                    TRUNCATE TABLE stg_transport.stg_ts21_archive_fares;
                    TRUNCATE TABLE stg_transport.stg_ts21_archive_opexp_total;
                    TRUNCATE TABLE stg_transport.stg_major_safety_event;
                ';

                PRINT 'Staging tables truncated successfully.';
                PRINT '';
                PRINT '*** NOTE: To complete staging load, execute the full script:';
                PRINT '    sql/staging/02_load_staging_transport.sql';
                PRINT '    This contains the complete INSERT statements for all staging tables.';
                PRINT '';
                PRINT CONCAT('Staging Phase completed at ', FORMAT(SYSDATETIME(), 'HH:mm:ss.fff'));

            END TRY
            BEGIN CATCH
                PRINT '';
                PRINT '*** ERROR DURING STAGING LOAD ***';
                PRINT ERROR_MESSAGE();
                SET @ErrorOccurred = 1;

                IF @Debug = 1
                BEGIN
                    PRINT 'Debug Info:';
                    PRINT CONCAT('Error Number: ', ERROR_NUMBER());
                    PRINT CONCAT('Error Line: ', ERROR_LINE());
                    PRINT CONCAT('Error Severity: ', ERROR_SEVERITY());
                    PRINT CONCAT('Error State: ', ERROR_STATE());
                END
            END CATCH
        END

        -- ============================================================
        -- PHASE 2: DIMENSIONS ETL
        -- ============================================================
        IF @SkipDimensions = 0 AND @ErrorOccurred = 0
        BEGIN
            PRINT CHAR(10) + REPLICATE('-', 80);
            PRINT 'PHASE 2: LOADING DIMENSIONS (SCD Type 1 & 2)';
            PRINT REPLICATE('-', 80);
            PRINT '';

            BEGIN TRY
                PRINT 'Initiating dimension load orchestration...';
                PRINT '';

                EXEC dw_transport.sp_load_all_dimensions
                    @LoadDate = @LoadDate,
                    @Debug = @Debug,
                    @SkipUrbanArea = @SkipUrbanArea,
                    @SkipSafetyEventType = @SkipSafetyEventType,
                    @SkipSafetyIncident = @SkipSafetyIncident;

                PRINT '';
                PRINT CONCAT('Dimension Phase completed at ', FORMAT(SYSDATETIME(), 'HH:mm:ss.fff'));

            END TRY
            BEGIN CATCH
                PRINT '';
                PRINT '*** ERROR DURING DIMENSION LOAD ***';
                PRINT ERROR_MESSAGE();
                SET @ErrorOccurred = 1;

                IF @Debug = 1
                BEGIN
                    PRINT 'Debug Info:';
                    PRINT CONCAT('Error Number: ', ERROR_NUMBER());
                    PRINT CONCAT('Error Line: ', ERROR_LINE());
                    PRINT CONCAT('Error Severity: ', ERROR_SEVERITY());
                    PRINT CONCAT('Error State: ', ERROR_STATE());
                END
            END CATCH
        END

        -- ============================================================
        -- PHASE 3: FACTS ETL
        -- ============================================================
        IF @SkipFacts = 0 AND @ErrorOccurred = 0
        BEGIN
            PRINT CHAR(10) + REPLICATE('-', 80);
            PRINT 'PHASE 3: LOADING FACTS (Transaction, Snapshot, Factless)';
            PRINT REPLICATE('-', 80);
            PRINT '';

            BEGIN TRY
                PRINT 'Initiating fact table load orchestration...';
                PRINT '';

                EXEC dw_transport.sp_Load_All_Facts
                    @BatchID = @CurrentBatchID,
                    @ReloadIfExists = @ReloadIfExists;

                PRINT '';
                PRINT CONCAT('Facts Phase completed at ', FORMAT(SYSDATETIME(), 'HH:mm:ss.fff'));

            END TRY
            BEGIN CATCH
                PRINT '';
                PRINT '*** ERROR DURING FACTS LOAD ***';
                PRINT ERROR_MESSAGE();
                SET @ErrorOccurred = 1;

                IF @Debug = 1
                BEGIN
                    PRINT 'Debug Info:';
                    PRINT CONCAT('Error Number: ', ERROR_NUMBER());
                    PRINT CONCAT('Error Line: ', ERROR_LINE());
                    PRINT CONCAT('Error Severity: ', ERROR_SEVERITY());
                    PRINT CONCAT('Error State: ', ERROR_STATE());
                END
            END CATCH
        END

    END TRY
    BEGIN CATCH
        PRINT '';
        PRINT REPLICATE('=', 80);
        PRINT '*** FATAL ERROR IN TRANSPORT MART ETL PROCESS ***';
        PRINT REPLICATE('=', 80);
        PRINT ERROR_MESSAGE();
        SET @ErrorOccurred = 1;
    END CATCH

    -- ============================================================
    -- Print Summary
    -- ============================================================
    SET @EndTime = SYSDATETIME();
    SET @ElapsedSeconds = DATEDIFF(SECOND, @StartTime, @EndTime);

    PRINT '';
    PRINT REPLICATE('=', 80);
    IF @ErrorOccurred = 0
    BEGIN
        PRINT '   TRANSPORT MART ETL COMPLETED SUCCESSFULLY';
    END
    ELSE
    BEGIN
        PRINT '   TRANSPORT MART ETL COMPLETED WITH ERRORS';
    END
    PRINT REPLICATE('=', 80);
    PRINT '';
    PRINT CONCAT('End Time:            ', FORMAT(@EndTime, 'yyyy-MM-dd HH:mm:ss.fff'));
    PRINT CONCAT('Elapsed Time:        ', CONCAT(@ElapsedSeconds, ' seconds'));
    PRINT '';

    -- Return error status
    IF @ErrorOccurred = 1
    BEGIN
        THROW 50001, 'Transport Mart ETL process encountered errors. Review messages above.', 1;
    END

END;
GO

-- ============================================================
-- HR Data Mart Master Procedure
-- ============================================================
CREATE PROCEDURE dw_transport.sp_Master_ETL_Load_HR
    @LoadDate DATE = NULL,
    @BatchID BIGINT = NULL,
    @Debug BIT = 0,
    @SkipDimensions BIT = 0,
    @SkipFacts BIT = 0,
    @SkipEmploymentType BIT = 0,
    @SkipDepartment BIT = 0,
    @SkipJobRole BIT = 0,
    @ReloadIfExists BIT = 0
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    DECLARE @StartTime DATETIME2 = SYSDATETIME();
    DECLARE @EndTime DATETIME2;
    DECLARE @ElapsedSeconds DECIMAL(10, 2);
    DECLARE @ErrorOccurred BIT = 0;
    DECLARE @CurrentBatchID BIGINT;
    DECLARE @CurrentLoadDate DATE;

    -- ============================================================
    -- Initialize default values
    -- ============================================================
    IF @LoadDate IS NULL
        SET @CurrentLoadDate = CAST(GETDATE() AS DATE);
    ELSE
        SET @CurrentLoadDate = @LoadDate;

    IF @BatchID IS NULL
        SET @CurrentBatchID = CAST(FORMAT(GETDATE(), 'yyyyMMddHHmmss') AS BIGINT);
    ELSE
        SET @CurrentBatchID = @BatchID;

    -- ============================================================
    -- Print header
    -- ============================================================
    PRINT REPLICATE('=', 80);
    PRINT '   HR DATA MART - MASTER ETL ORCHESTRATION';
    PRINT REPLICATE('=', 80);
    PRINT '';
    PRINT CONCAT('Load Date:           ', FORMAT(@CurrentLoadDate, 'yyyy-MM-dd'));
    PRINT CONCAT('Batch ID:            ', @CurrentBatchID);
    PRINT CONCAT('Start Time:          ', FORMAT(@StartTime, 'yyyy-MM-dd HH:mm:ss.fff'));
    PRINT CONCAT('Debug Mode:          ', CASE WHEN @Debug = 1 THEN 'ON' ELSE 'OFF' END);
    PRINT '';
    PRINT 'Processing Steps:';
    PRINT CONCAT('  1. Dimensions ETL:   ', CASE WHEN @SkipDimensions = 0 THEN 'ENABLED' ELSE 'SKIPPED' END);
    PRINT CONCAT('  2. Facts ETL:        ', CASE WHEN @SkipFacts = 0 THEN 'ENABLED' ELSE 'SKIPPED' END);
    PRINT '';
    PRINT 'Dimensions:';
    PRINT CONCAT('    - EmploymentType: ', CASE WHEN @SkipEmploymentType = 0 THEN 'ENABLED' ELSE 'SKIPPED' END);
    PRINT CONCAT('    - Department:     ', CASE WHEN @SkipDepartment = 0 THEN 'ENABLED' ELSE 'SKIPPED' END);
    PRINT CONCAT('    - JobRole:        ', CASE WHEN @SkipJobRole = 0 THEN 'ENABLED' ELSE 'SKIPPED' END);
    PRINT '';
    PRINT REPLICATE('=', 80);
    PRINT '';

    BEGIN TRY

        -- ============================================================
        -- PHASE 1: DIMENSIONS ETL
        -- ============================================================
        IF @SkipDimensions = 0
        BEGIN
            PRINT CHAR(10) + REPLICATE('-', 80);
            PRINT 'PHASE 1: LOADING HR DIMENSIONS';
            PRINT REPLICATE('-', 80);
            PRINT '';

            BEGIN TRY
                PRINT 'Initiating HR dimension load orchestration...';
                PRINT '';

                EXEC dw_HR.sp_execute_hr_dimensions_etl
                    @ExecutionDate = @CurrentLoadDate;

                PRINT '';
                PRINT CONCAT('HR Dimensions Phase completed at ', FORMAT(SYSDATETIME(), 'HH:mm:ss.fff'));

            END TRY
            BEGIN CATCH
                PRINT '';
                PRINT '*** ERROR DURING HR DIMENSIONS LOAD ***';
                PRINT ERROR_MESSAGE();
                SET @ErrorOccurred = 1;

                IF @Debug = 1
                BEGIN
                    PRINT 'Debug Info:';
                    PRINT CONCAT('Error Number: ', ERROR_NUMBER());
                    PRINT CONCAT('Error Line: ', ERROR_LINE());
                    PRINT CONCAT('Error Severity: ', ERROR_SEVERITY());
                    PRINT CONCAT('Error State: ', ERROR_STATE());
                END
            END CATCH
        END

        -- ============================================================
        -- PHASE 2: FACTS ETL
        -- ============================================================
        IF @SkipFacts = 0 AND @ErrorOccurred = 0
        BEGIN
            PRINT CHAR(10) + REPLICATE('-', 80);
            PRINT 'PHASE 2: LOADING HR FACTS';
            PRINT REPLICATE('-', 80);
            PRINT '';

            BEGIN TRY
                PRINT 'Initiating HR fact table load orchestration...';
                PRINT '';

                EXEC dw_HR.sp_Load_All_Facts
                    @BatchID = @CurrentBatchID,
                    @ReloadIfExists = @ReloadIfExists;

                PRINT '';
                PRINT CONCAT('HR Facts Phase completed at ', FORMAT(SYSDATETIME(), 'HH:mm:ss.fff'));

            END TRY
            BEGIN CATCH
                PRINT '';
                PRINT '*** ERROR DURING HR FACTS LOAD ***';
                PRINT ERROR_MESSAGE();
                SET @ErrorOccurred = 1;

                IF @Debug = 1
                BEGIN
                    PRINT 'Debug Info:';
                    PRINT CONCAT('Error Number: ', ERROR_NUMBER());
                    PRINT CONCAT('Error Line: ', ERROR_LINE());
                    PRINT CONCAT('Error Severity: ', ERROR_SEVERITY());
                    PRINT CONCAT('Error State: ', ERROR_STATE());
                END
            END CATCH
        END

    END TRY
    BEGIN CATCH
        PRINT '';
        PRINT REPLICATE('=', 80);
        PRINT '*** FATAL ERROR IN HR MART ETL PROCESS ***';
        PRINT REPLICATE('=', 80);
        PRINT ERROR_MESSAGE();
        SET @ErrorOccurred = 1;
    END CATCH

    -- ============================================================
    -- Print Summary
    -- ============================================================
    SET @EndTime = SYSDATETIME();
    SET @ElapsedSeconds = DATEDIFF(SECOND, @StartTime, @EndTime);

    PRINT '';
    PRINT REPLICATE('=', 80);
    IF @ErrorOccurred = 0
    BEGIN
        PRINT '   HR MART ETL COMPLETED SUCCESSFULLY';
    END
    ELSE
    BEGIN
        PRINT '   HR MART ETL COMPLETED WITH ERRORS';
    END
    PRINT REPLICATE('=', 80);
    PRINT '';
    PRINT CONCAT('End Time:            ', FORMAT(@EndTime, 'yyyy-MM-dd HH:mm:ss.fff'));
    PRINT CONCAT('Elapsed Time:        ', CONCAT(@ElapsedSeconds, ' seconds'));
    PRINT '';

    -- Return error status
    IF @ErrorOccurred = 1
    BEGIN
        THROW 50001, 'HR Mart ETL process encountered errors. Review messages above.', 1;
    END

END;
GO

-- ============================================================
-- Master ETL Orchestration Procedure - All Marts
-- ============================================================
CREATE PROCEDURE dw_transport.sp_Master_ETL_Load_All_Marts
    @LoadDate DATE = NULL,
    @BatchID BIGINT = NULL,
    @Debug BIT = 0,
    @SkipStaging BIT = 1,
    @SkipCommon BIT = 0,
    @SkipTransport BIT = 0,
    @SkipHR BIT = 0,
    @ReloadIfExists BIT = 0
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    DECLARE @StartTime DATETIME2 = SYSDATETIME();
    DECLARE @EndTime DATETIME2;
    DECLARE @ElapsedSeconds DECIMAL(10, 2);
    DECLARE @ErrorOccurred BIT = 0;
    DECLARE @CurrentBatchID BIGINT;
    DECLARE @CurrentLoadDate DATE;

    -- ============================================================
    -- Initialize default values
    -- ============================================================
    IF @LoadDate IS NULL
        SET @CurrentLoadDate = CAST(GETDATE() AS DATE);
    ELSE
        SET @CurrentLoadDate = @LoadDate;

    IF @BatchID IS NULL
        SET @CurrentBatchID = CAST(FORMAT(GETDATE(), 'yyyyMMddHHmmss') AS BIGINT);
    ELSE
        SET @CurrentBatchID = @BatchID;

    -- ============================================================
    -- Print header
    -- ============================================================
  -- ============================================================
-- Print header
-- ============================================================

PRINT '';
PRINT REPLICATE('╔', 80);
PRINT '║' + REPLICATE(' ', 78) + '║';
PRINT '║' + REPLICATE(' ', 15)
    + 'DATA WAREHOUSE - COMPLETE MASTER ETL ORCHESTRATION'
    + REPLICATE(' ', 12) + '║';
PRINT '║' + REPLICATE(' ', 78) + '║';
PRINT REPLICATE('╚', 80);
PRINT '';

PRINT CONCAT(
    'Load Date:           ',
    FORMAT(@CurrentLoadDate, 'yyyy-MM-dd')
);

PRINT CONCAT(
    'Batch ID:            ',
    @CurrentBatchID
);

PRINT CONCAT(
    'Start Time:          ',
    FORMAT(@StartTime, 'yyyy-MM-dd HH:mm:ss.fff')
);

PRINT CONCAT(
    'Debug Mode:          ',
    CASE
        WHEN @Debug = 1 THEN 'ON'
        ELSE 'OFF'
    END
);

PRINT '';

PRINT 'Processing Sequence:';
PRINT '  ┌─ STAGING (Transport Only)';

PRINT CONCAT(
    '  │   └─ Staging Load: ',
    CASE
        WHEN @SkipStaging = 0 THEN 'ENABLED'
        ELSE 'SKIPPED'
    END
);

PRINT '  │';

PRINT '  ├─ COMMON MART (Shared Dimensions)';
PRINT '  │   ├─ DimDate';
PRINT '  │   ├─ DimAgency (SCD Type 2)';
PRINT '  │   ├─ DimMode';
PRINT '  │   └─ DimServiceType';

PRINT '  │';

PRINT '  ├─ TRANSPORT MART';

PRINT CONCAT(
    '  │   ├─ Dimensions: ',
    CASE
        WHEN @SkipTransport = 0 THEN 'ENABLED'
        ELSE 'SKIPPED'
    END
);

PRINT '  │   │  └─ DimUrbanArea, DimSafetyEventType, DimSafetyIncident';

PRINT CONCAT(
    '  │   └─ Facts: ',
    CASE
        WHEN @SkipTransport = 0 THEN 'ENABLED'
        ELSE 'SKIPPED'
    END
);

PRINT '  │';

PRINT '  └─ HR MART';

PRINT CONCAT(
    '      ├─ Dimensions: ',
    CASE
        WHEN @SkipHR = 0 THEN 'ENABLED'
        ELSE 'SKIPPED'
    END
);

PRINT '      │  └─ DimEmploymentType, DimDepartment, DimJobRole';

PRINT CONCAT(
    '      └─ Facts: ',
    CASE
        WHEN @SkipHR = 0 THEN 'ENABLED'
        ELSE 'SKIPPED'
    END
);

PRINT '         └─ FactJobPosting, FactEmployeeSnapshot,';
PRINT '            FactAgencyLaborCoverage, FactJobPostingLifecycle';

PRINT '';

PRINT REPLICATE('=', 80);
PRINT '';

    BEGIN TRY

        -- ============================================================
        -- PHASE 1: COMMON MART (Dependencies First)
        -- ============================================================
        IF @SkipCommon = 0
        BEGIN
            PRINT CHAR(10) + REPLICATE('█', 80);
            PRINT 'PHASE 1: COMMON DATA MART (Shared Dimensions)';
            PRINT REPLICATE('█', 80);
            PRINT '';

            BEGIN TRY
                EXEC dw_transport.sp_Master_ETL_Load_Common
                    @LoadDate = @CurrentLoadDate,
                    @Debug = @Debug;

            END TRY
            BEGIN CATCH
                PRINT '';
                PRINT '*** ERROR IN COMMON MART ***';
                PRINT ERROR_MESSAGE();
                SET @ErrorOccurred = 1;

                IF @Debug = 1
                BEGIN
                    PRINT 'Error Details:';
                    PRINT CONCAT('  Number: ', ERROR_NUMBER());
                    PRINT CONCAT('  Message: ', ERROR_MESSAGE());
                    PRINT CONCAT('  Line: ', ERROR_LINE());
                END
            END CATCH
        END

        -- ============================================================
        -- PHASE 2: TRANSPORTATION MART
        -- ============================================================
        IF @SkipTransport = 0 AND @ErrorOccurred = 0
        BEGIN
            PRINT CHAR(10) + REPLICATE('█', 80);
            PRINT 'PHASE 2: TRANSPORTATION DATA MART';
            PRINT REPLICATE('█', 80);
            PRINT '';

            BEGIN TRY
                EXEC dw_transport.sp_Master_ETL_Load_Transport
                    @LoadDate = @CurrentLoadDate,
                    @BatchID = @CurrentBatchID,
                    @Debug = @Debug,
                    @SkipStaging = @SkipStaging,
                    @ReloadIfExists = @ReloadIfExists;

            END TRY
            BEGIN CATCH
                PRINT '';
                PRINT '*** ERROR IN TRANSPORT MART ***';
                PRINT ERROR_MESSAGE();
                SET @ErrorOccurred = 1;

                IF @Debug = 1
                BEGIN
                    PRINT 'Error Details:';
                    PRINT CONCAT('  Number: ', ERROR_NUMBER());
                    PRINT CONCAT('  Message: ', ERROR_MESSAGE());
                    PRINT CONCAT('  Line: ', ERROR_LINE());
                END
            END CATCH
        END

        -- ============================================================
        -- PHASE 3: HR MART
        -- ============================================================
        IF @SkipHR = 0 AND @ErrorOccurred = 0
        BEGIN
            PRINT CHAR(10) + REPLICATE('█', 80);
            PRINT 'PHASE 3: HR DATA MART';
            PRINT REPLICATE('█', 80);
            PRINT '';

            BEGIN TRY
                EXEC dw_transport.sp_Master_ETL_Load_HR
                    @LoadDate = @CurrentLoadDate,
                    @BatchID = @CurrentBatchID,
                    @Debug = @Debug,
                    @ReloadIfExists = @ReloadIfExists;

            END TRY
            BEGIN CATCH
                PRINT '';
                PRINT '*** ERROR IN HR MART ***';
                PRINT ERROR_MESSAGE();
                SET @ErrorOccurred = 1;

                IF @Debug = 1
                BEGIN
                    PRINT 'Error Details:';
                    PRINT CONCAT('  Number: ', ERROR_NUMBER());
                    PRINT CONCAT('  Message: ', ERROR_MESSAGE());
                    PRINT CONCAT('  Line: ', ERROR_LINE());
                END
            END CATCH
        END

    END TRY
    BEGIN CATCH
        PRINT '';
        PRINT REPLICATE('=', 80);
        PRINT '*** FATAL ERROR IN MASTER ETL PROCESS ***';
        PRINT REPLICATE('=', 80);
        PRINT ERROR_MESSAGE();
        SET @ErrorOccurred = 1;
    END CATCH

    -- ============================================================
    -- Print Final Summary
    -- ============================================================
    SET @EndTime = SYSDATETIME();
    SET @ElapsedSeconds = DATEDIFF(SECOND, @StartTime, @EndTime);

    PRINT '';
    PRINT REPLICATE('=', 80);
    PRINT '';

    IF @ErrorOccurred = 0
    BEGIN
        PRINT '   ✓ COMPLETE DATA WAREHOUSE ETL - SUCCESSFULLY COMPLETED ✓';
    END
    ELSE
    BEGIN
        PRINT '   ✗ COMPLETE DATA WAREHOUSE ETL - COMPLETED WITH ERRORS ✗';
    END

    PRINT '';
    PRINT REPLICATE('=', 80);
    PRINT '';
    PRINT 'Summary:';
    PRINT CONCAT('  Common Mart:       ', CASE WHEN @SkipCommon = 0 THEN 'EXECUTED' ELSE 'SKIPPED' END);
    PRINT CONCAT('  Transport Mart:    ', CASE WHEN @SkipTransport = 0 THEN 'EXECUTED' ELSE 'SKIPPED' END);
    PRINT CONCAT('  HR Mart:           ', CASE WHEN @SkipHR = 0 THEN 'EXECUTED' ELSE 'SKIPPED' END);
    PRINT '';
    PRINT CONCAT('Start Time:        ', FORMAT(@StartTime, 'yyyy-MM-dd HH:mm:ss.fff'));
    PRINT CONCAT('End Time:          ', FORMAT(@EndTime, 'yyyy-MM-dd HH:mm:ss.fff'));
    PRINT CONCAT('Total Elapsed:     ', CONCAT(@ElapsedSeconds, ' seconds (', CAST(@ElapsedSeconds / 60.0 AS NUMERIC(10,2)), ' minutes)'));
    PRINT '';
    PRINT REPLICATE('=', 80);
    PRINT '';

    -- Return error status
    IF @ErrorOccurred = 1
    BEGIN
        THROW 50001, 'Data Warehouse ETL process encountered errors. Review messages above.', 1;
    END

END;
GO

-- ============================================================
-- EXECUTION EXAMPLES
-- ============================================================

/*

-- ============================================================
-- FULL WAREHOUSE ETL (all marts, default settings)
-- ============================================================
EXEC dw_transport.sp_Master_ETL_Load_All_Marts;

-- Full ETL with specific date and batch ID
EXEC dw_transport.sp_Master_ETL_Load_All_Marts
    @LoadDate = '2024-01-15',
    @BatchID = 20240115001;

-- Full ETL with debug mode
EXEC dw_transport.sp_Master_ETL_Load_All_Marts
    @Debug = 1;

-- Load only Common and Transport (skip HR)
EXEC dw_transport.sp_Master_ETL_Load_All_Marts
    @SkipHR = 1;

-- Load only HR mart (skip Common and Transport)
EXEC dw_transport.sp_Master_ETL_Load_All_Marts
    @SkipCommon = 1,
    @SkipTransport = 1;

-- ============================================================
-- INDIVIDUAL MART ETL (specific marts)
-- ============================================================

-- Load only Common mart
EXEC dw_transport.sp_Master_ETL_Load_Common
    @LoadDate = '2024-01-15',
    @Debug = 1;

-- Load only Transport mart (skip staging)
EXEC dw_transport.sp_Master_ETL_Load_Transport
    @LoadDate = '2024-01-15',
    @SkipStaging = 1,
    @Debug = 1;

-- Load only HR mart
EXEC dw_transport.sp_Master_ETL_Load_HR
    @LoadDate = '2024-01-15',
    @Debug = 1;

-- ============================================================
-- ADVANCED SCENARIOS
-- ============================================================

-- Reload with full staging and all marts with debug
EXEC dw_transport.sp_Master_ETL_Load_All_Marts
    @LoadDate = '2024-01-15',
    @SkipStaging = 0,  -- Include staging load
    @Debug = 1;

-- Skip dimensions, load only facts
EXEC dw_transport.sp_Master_ETL_Load_Transport
    @SkipDimensions = 1,
    @SkipFacts = 0,
    @SkipStaging = 1;

-- Reload all facts (delete and reload current batch)
EXEC dw_transport.sp_Master_ETL_Load_All_Marts
    @ReloadIfExists = 1;

*/
