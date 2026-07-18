-- ============================================================
-- FILE:   06_fact_transport_etl.sql
-- SCHEMA: dw_transport
-- DESC:   ETL procedures to load all fact tables from staging
--         tables. Implements Kimball best practices for
--         transaction, factless, and accumulating snapshots.
--
-- EXECUTION ORDER: Run after 05_fact_transport_DDL.sql
--                  Run after 04_load_dimensions_Transport_etl.sql
--
-- STORED PROCEDURES:
--   1. sp_Load_Fact_Annual_Service_Performance  (Snapshot)
--   2. sp_Load_Fact_Major_Safety_Event          (Transaction)
--   3. sp_Load_Fact_Service_Availability        (Factless Coverage)
--   4. sp_Load_Fact_Service_Lifecycle_Accumulating (Accumulating Snapshot)
--
-- ETL PATTERNS APPLIED:
--   * Consolidated UNPIVOT via FULL OUTER JOIN (single staging read)
--   * SCD Type 2 effective date range lookups (not just CurrentFlag)
--   * Surrogate key lookups with unknown member (-1) fallback
--   * Degenerate dimension for incident-level idempotency
--   * ETL audit columns (BatchID, SourceSystem, timestamps)
--   * Proper grain uniqueness via UNIQUE constraints
--   * Join-based dimension matching (no correlated subqueries)
--
-- ============================================================

USE [TransportationDB];
GO

-- ============================================================
-- 1. FACT_ANNUAL_SERVICE_PERFORMANCE ETL
--    Transaction fact table with annual service metrics
-- ============================================================

IF OBJECT_ID('dw_transport.sp_Load_Fact_Annual_Service_Performance', 'P') IS NOT NULL
    DROP PROCEDURE dw_transport.sp_Load_Fact_Annual_Service_Performance;
GO

CREATE PROCEDURE dw_transport.sp_Load_Fact_Annual_Service_Performance
    @BatchID BIGINT = NULL,
    @SourceSystem VARCHAR(50) = 'NTD_Annual_Performance',
    @ReloadIfExists BIT = 0
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    DECLARE @RowsInserted INT = 0;
    DECLARE @RowsDeleted INT = 0;
    DECLARE @LoadStartTime DATETIME2 = SYSDATETIME();
    DECLARE @LoadDate DATE = CAST(GETDATE() AS DATE);
    DECLARE @TransactionStarted BIT = 0;
    DECLARE @AuditId INT;
    DECLARE @ErrorMsg NVARCHAR(MAX) = NULL;

    -- Log start of audit
    INSERT INTO dw_common.etl_load_audit (
        procedure_name, load_date, load_start_time, status
    )
    VALUES ('dw_transport.sp_Load_Fact_Annual_Service_Performance', @LoadDate, @LoadStartTime, 'IN_PROGRESS');
    SET @AuditId = SCOPE_IDENTITY();

    BEGIN TRY
        IF @@TRANCOUNT = 0
        BEGIN
            BEGIN TRANSACTION;
            SET @TransactionStarted = 1;
        END

        -- ============================================================
        -- STEP 1: Build dimension grain (master key list)
        --         All combinations of Year + Agency + Mode + ServiceType
        --         using UNION from all metric sources
        --
        -- BEST PRACTICE: Use LEFT JOIN pattern instead of FULL OUTER
        -- ============================================================

        -- Create metric temp tables once (avoiding 8x duplicate unpivots)
        IF OBJECT_ID('tempdb..#UPT', 'U') IS NOT NULL
            DROP TABLE #UPT;
        IF OBJECT_ID('tempdb..#PMT', 'U') IS NOT NULL
            DROP TABLE #PMT;
        IF OBJECT_ID('tempdb..#DRM', 'U') IS NOT NULL
            DROP TABLE #DRM;
        IF OBJECT_ID('tempdb..#Fares', 'U') IS NOT NULL
            DROP TABLE #Fares;
        IF OBJECT_ID('tempdb..#OpExp', 'U') IS NOT NULL
            DROP TABLE #OpExp;
        IF OBJECT_ID('tempdb..#VRM', 'U') IS NOT NULL
            DROP TABLE #VRM;
        IF OBJECT_ID('tempdb..#VRH', 'U') IS NOT NULL
            DROP TABLE #VRH;
        IF OBJECT_ID('tempdb..#VOMS', 'U') IS NOT NULL
            DROP TABLE #VOMS;

        -- Unpivot UPT once
        SELECT
            CAST(SUBSTRING(YearColumn, 2, 4) AS INT) AS ReportYear,
            ntd_id,
            uace_code,
            mode,
            type_of_service,
            CAST(YearValue AS BIGINT) AS UPT
        INTO #UPT
        FROM stg_transport.stg_ts21_upt
        UNPIVOT (
            YearValue FOR YearColumn IN (
                [y2015], [y2016], [y2017], [y2018], [y2019], [y2020],
                [y2021], [y2022], [y2023], [y2024]
            )
        ) AS unpvt
        WHERE YearValue IS NOT NULL;

        -- Unpivot PMT once
        SELECT
            CAST(SUBSTRING(YearColumn, 2, 4) AS INT) AS ReportYear,
            ntd_id,
            uace_code,
            mode,
            type_of_service,
            CAST(YearValue AS BIGINT) AS PMT
        INTO #PMT
        FROM stg_transport.stg_ts21_pmt
        UNPIVOT (
            YearValue FOR YearColumn IN (
                [y2015], [y2016], [y2017], [y2018], [y2019], [y2020],
                [y2021], [y2022], [y2023], [y2024]
            )
        ) AS unpvt
        WHERE YearValue IS NOT NULL;

        -- Unpivot DRM once
        SELECT
            CAST(SUBSTRING(YearColumn, 2, 4) AS INT) AS ReportYear,
            ntd_id,
            uace_code,
            mode,
            type_of_service,
            CAST(YearValue AS BIGINT) AS DRM
        INTO #DRM
        FROM stg_transport.stg_ts21_drm
        UNPIVOT (
            YearValue FOR YearColumn IN (
                [y2015], [y2016], [y2017], [y2018], [y2019], [y2020],
                [y2021], [y2022], [y2023], [y2024]
            )
        ) AS unpvt
        WHERE YearValue IS NOT NULL;

        -- Unpivot Fares once
        SELECT
            CAST(SUBSTRING(YearColumn, 2, 4) AS INT) AS ReportYear,
            ntd_id,
            uace_code,
            mode,
            type_of_service,
            CAST(YearValue AS DECIMAL(18,2)) AS Fares
        INTO #Fares
        FROM stg_transport.stg_ts21_fares
        UNPIVOT (
            YearValue FOR YearColumn IN (
                [y2015], [y2016], [y2017], [y2018], [y2019], [y2020],
                [y2021], [y2022], [y2023], [y2024]
            )
        ) AS unpvt
        WHERE YearValue IS NOT NULL;

        -- Unpivot Operating Expense once
        SELECT
            CAST(SUBSTRING(YearColumn, 2, 4) AS INT) AS ReportYear,
            ntd_id,
            uace_code,
            mode,
            type_of_service,
            CAST(YearValue AS DECIMAL(18,2)) AS OperatingExpenseTotal
        INTO #OpExp
        FROM stg_transport.stg_ts21_opexp_total
        UNPIVOT (
            YearValue FOR YearColumn IN (
                [y2015], [y2016], [y2017], [y2018], [y2019], [y2020],
                [y2021], [y2022], [y2023], [y2024]
            )
        ) AS unpvt
        WHERE YearValue IS NOT NULL;

        -- Unpivot VRM once
        SELECT
            CAST(SUBSTRING(YearColumn, 2, 4) AS INT) AS ReportYear,
            ntd_id,
            uace_code,
            mode,
            type_of_service,
            CAST(YearValue AS BIGINT) AS VRM
        INTO #VRM
        FROM stg_transport.stg_ts21_vrm
        UNPIVOT (
            YearValue FOR YearColumn IN (
                [y2015], [y2016], [y2017], [y2018], [y2019], [y2020],
                [y2021], [y2022], [y2023], [y2024]
            )
        ) AS unpvt
        WHERE YearValue IS NOT NULL;

        -- Unpivot VRH once
        SELECT
            CAST(SUBSTRING(YearColumn, 2, 4) AS INT) AS ReportYear,
            ntd_id,
            uace_code,
            mode,
            type_of_service,
            CAST(YearValue AS BIGINT) AS VRH
        INTO #VRH
        FROM stg_transport.stg_ts21_vrh
        UNPIVOT (
            YearValue FOR YearColumn IN (
                [y2015], [y2016], [y2017], [y2018], [y2019], [y2020],
                [y2021], [y2022], [y2023], [y2024]
            )
        ) AS unpvt
        WHERE YearValue IS NOT NULL;

        -- Unpivot VOMS once
        SELECT
            CAST(SUBSTRING(YearColumn, 2, 4) AS INT) AS ReportYear,
            ntd_id,
            uace_code,
            mode,
            type_of_service,
            CAST(YearValue AS INT) AS VOMS
        INTO #VOMS
        FROM stg_transport.stg_ts21_voms
        UNPIVOT (
            YearValue FOR YearColumn IN (
                [y2015], [y2016], [y2017], [y2018], [y2019], [y2020],
                [y2021], [y2022], [y2023], [y2024]
            )
        ) AS unpvt
        WHERE YearValue IS NOT NULL;

        -- Create master grain key list with only needed columns
        IF OBJECT_ID('tempdb..#MasterGrainKeys', 'U') IS NOT NULL
            DROP TABLE #MasterGrainKeys;

        CREATE TABLE #MasterGrainKeys (
            ReportYear INT,
            ntd_id VARCHAR(50),
            uace_code VARCHAR(50),
            mode VARCHAR(20),
            type_of_service VARCHAR(20),
            UNIQUE (ReportYear, ntd_id, uace_code, mode, type_of_service)
        );

        -- Populate from ALL metrics using UNION to capture every business key that exists in any metric table
        -- Reuse the temp tables already created, avoiding duplicate unpivots
        INSERT INTO #MasterGrainKeys
        SELECT ReportYear, ntd_id, uace_code, mode, type_of_service
        FROM (
            SELECT DISTINCT ReportYear, ntd_id, uace_code, mode, type_of_service
            FROM #UPT
            UNION
            SELECT DISTINCT ReportYear, ntd_id, uace_code, mode, type_of_service
            FROM #PMT
            UNION
            SELECT DISTINCT ReportYear, ntd_id, uace_code, mode, type_of_service
            FROM #DRM
            UNION
            SELECT DISTINCT ReportYear, ntd_id, uace_code, mode, type_of_service
            FROM #Fares
            UNION
            SELECT DISTINCT ReportYear, ntd_id, uace_code, mode, type_of_service
            FROM #OpExp
            UNION
            SELECT DISTINCT ReportYear, ntd_id, uace_code, mode, type_of_service
            FROM #VRM
            UNION
            SELECT DISTINCT ReportYear, ntd_id, uace_code, mode, type_of_service
            FROM #VRH
            UNION
            SELECT DISTINCT ReportYear, ntd_id, uace_code, mode, type_of_service
            FROM #VOMS
        ) mgk;

        -- Create clustered index on master grain keys for performance
        CREATE CLUSTERED INDEX IX_MasterGrain
            ON #MasterGrainKeys (ReportYear, ntd_id, mode, type_of_service);

        -- Now LEFT JOIN all metrics to the master grain (reusing temp tables)
        IF OBJECT_ID('tempdb..#AnnualPerformanceStaging', 'U') IS NOT NULL
            DROP TABLE #AnnualPerformanceStaging;

        CREATE TABLE #AnnualPerformanceStaging (
            ReportYear INT,
            ntd_id VARCHAR(50),
            uace_code VARCHAR(50),
            mode VARCHAR(20),
            type_of_service VARCHAR(20),
            UPT BIGINT,
            PMT BIGINT,
            VRM BIGINT,
            VRH BIGINT,
            VOMS INT,
            DRM BIGINT,
            Fares DECIMAL(18,2),
            OperatingExpenseTotal DECIMAL(18,2)
        );

        INSERT INTO #AnnualPerformanceStaging
        SELECT
            grain.ReportYear,
            grain.ntd_id,
            grain.uace_code,
            grain.mode,
            grain.type_of_service,
            upt.UPT,
            pmt.PMT,
            vrm.VRM,
            vrh.VRH,
            voms.VOMS,
            drm.DRM,
            fares.Fares,
            opexp.OperatingExpenseTotal
        FROM #MasterGrainKeys grain
        -- LEFT JOIN all metrics to the master grain (reuse already-unpivoted temp tables)
        LEFT JOIN #UPT upt
            ON grain.ReportYear = upt.ReportYear
            AND grain.ntd_id = upt.ntd_id
            AND grain.mode = upt.mode
            AND grain.type_of_service = upt.type_of_service
        LEFT JOIN #PMT pmt
            ON grain.ReportYear = pmt.ReportYear
            AND grain.ntd_id = pmt.ntd_id
            AND grain.mode = pmt.mode
            AND grain.type_of_service = pmt.type_of_service
        LEFT JOIN #DRM drm
            ON grain.ReportYear = drm.ReportYear
            AND grain.ntd_id = drm.ntd_id
            AND grain.mode = drm.mode
            AND grain.type_of_service = drm.type_of_service
        LEFT JOIN #Fares fares
            ON grain.ReportYear = fares.ReportYear
            AND grain.ntd_id = fares.ntd_id
            AND grain.mode = fares.mode
            AND grain.type_of_service = fares.type_of_service
        LEFT JOIN #OpExp opexp
            ON grain.ReportYear = opexp.ReportYear
            AND grain.ntd_id = opexp.ntd_id
            AND grain.mode = opexp.mode
            AND grain.type_of_service = opexp.type_of_service
        LEFT JOIN #VRM vrm
            ON grain.ReportYear = vrm.ReportYear
            AND grain.ntd_id = vrm.ntd_id
            AND grain.mode = vrm.mode
            AND grain.type_of_service = vrm.type_of_service
        LEFT JOIN #VRH vrh
            ON grain.ReportYear = vrh.ReportYear
            AND grain.ntd_id = vrh.ntd_id
            AND grain.mode = vrh.mode
            AND grain.type_of_service = vrh.type_of_service
        LEFT JOIN #VOMS voms
            ON grain.ReportYear = voms.ReportYear
            AND grain.ntd_id = voms.ntd_id
            AND grain.mode = voms.mode
            AND grain.type_of_service = voms.type_of_service;

        -- Clustered index on #AnnualPerformanceStaging: Check data size before creating
        -- For ~50k rows or less, skip the index; for 500k+, create it.
        DECLARE @StagingRowCount INT = (SELECT COUNT(*) FROM #AnnualPerformanceStaging);
        DECLARE @DistinctNTDIds INT = (SELECT COUNT(DISTINCT ntd_id) FROM #AnnualPerformanceStaging);
        DECLARE @DistinctUACECodes INT = (SELECT COUNT(DISTINCT uace_code) FROM #AnnualPerformanceStaging);
        DECLARE @SampleNTDID VARCHAR(50) = (SELECT TOP 1 ntd_id FROM #AnnualPerformanceStaging WHERE ntd_id IS NOT NULL);
        DECLARE @DimAgencyCount INT = (SELECT COUNT(*) FROM dw_common.DimAgency);
        DECLARE @DimUrbanAreaCount INT = (SELECT COUNT(*) FROM dw_transport.DimUrbanArea);
        PRINT CONCAT('Staging records to load: ', @StagingRowCount);
        PRINT CONCAT('Distinct NTD IDs: ', @DistinctNTDIds);
        PRINT CONCAT('Distinct UACE Codes: ', @DistinctUACECodes);
        PRINT CONCAT('Sample NTD ID: ', ISNULL(@SampleNTDID, 'NULL'));
        PRINT CONCAT('DimAgency record count: ', @DimAgencyCount);
        PRINT CONCAT('DimUrbanArea record count: ', @DimUrbanAreaCount);

        -- ============================================================
        -- STEP 2: Optional reload handling for data corrections
        --         CRITIC #4 FIX: Added @ReloadIfExists parameter
        -- ============================================================

        IF @ReloadIfExists = 1
        BEGIN
            -- Delete any existing rows with the same grain before reload
            DELETE FROM dw_transport.Fact_Annual_Service_Performance
            WHERE EXISTS (
                SELECT 1 FROM #AnnualPerformanceStaging aps
                LEFT JOIN dw_common.DimDate dd
                    ON dd.CalendarYear = aps.ReportYear
                    AND dd.CalendarMonth = 1
                    AND dd.CalendarDay = 1
                LEFT JOIN dw_common.DimAgency da
                    ON da.NTD_ID = aps.ntd_id
                    AND COALESCE(dd.FullDate, CAST(CONCAT(aps.ReportYear, '-01-01') AS DATE)) >= da.EffectiveDate
                    AND COALESCE(dd.FullDate, CAST(CONCAT(aps.ReportYear, '-01-01') AS DATE)) < da.ExpirationDate
                LEFT JOIN dw_common.DimMode dm
                    ON dm.ModeCode = aps.mode
                LEFT JOIN dw_common.DimServiceType dst
                    ON dst.TOSCode = aps.type_of_service
                WHERE Fact_Annual_Service_Performance.DateKey = COALESCE(dd.DateKey, -1)
                AND Fact_Annual_Service_Performance.AgencyKey = COALESCE(da.AgencyKey, -1)
                AND Fact_Annual_Service_Performance.ModeKey = COALESCE(dm.ModeKey, -1)
                AND Fact_Annual_Service_Performance.ServiceTypeKey = COALESCE(dst.ServiceTypeKey, -1)

            );
            SET @RowsDeleted = @@ROWCOUNT;
            PRINT CONCAT('Deleted ', @RowsDeleted, ' rows for grain reload');
        END

        -- ============================================================
        -- STEP 3: Join with dimensions using SCD Type 2 effective dates
        --         CRITIC #3 FIX: Changed from CurrentFlag = 1 to
        --         effective date range checks for historical accuracy
        -- ============================================================

        INSERT INTO dw_transport.Fact_Annual_Service_Performance (
            DateKey,
            AgencyKey,
            ModeKey,
            ServiceTypeKey,
            UrbanAreaKey,
            UPT,
            PMT,
            VRM,
            VRH,
            VOMS,
            DRM,
            Fares,
            OperatingExpenseTotal,
            ETL_InsertDate,
            ETL_UpdateDate,
            ETL_BatchID,
            RecordSourceSystem
        )
        SELECT
            COALESCE(dd.DateKey, -1) AS DateKey,
            COALESCE(da.AgencyKey, -1) AS AgencyKey,
            COALESCE(dm.ModeKey, -1) AS ModeKey,
            COALESCE(dst.ServiceTypeKey, -1) AS ServiceTypeKey,
            COALESCE(dua.UrbanAreaKey, -1) AS UrbanAreaKey,
            ُMAX(aps.UPT) AS UPT,
            MAX(aps.PMT) AS PMT,
            MAX(aps.VRM) AS VRM,
            MAX(aps.VRH) AS VRH,
            MAX(aps.VOMS) AS VOMS,
            MAX(aps.DRM) AS DRM,
            MAX(aps.Fares) AS Fares,
            MAX(aps.OperatingExpenseTotal) AS OperatingExpenseTotal,
            @LoadStartTime,
            NULL,
            @BatchID,
            @SourceSystem
        FROM (
            -- Deduplicate staging data on grain: (ReportYear, ntd_id, mode, type_of_service)
            -- If the same grain appears in multiple metric sources, take max of measures
            SELECT
                ReportYear,
                ntd_id,
                uace_code,
                mode,
                type_of_service,
                MAX(UPT) AS UPT,
                MAX(PMT) AS PMT,
                MAX(VRM) AS VRM,
                MAX(VRH) AS VRH,
                MAX(VOMS) AS VOMS,
                MAX(DRM) AS DRM,
                MAX(Fares) AS Fares,
                MAX(OperatingExpenseTotal) AS OperatingExpenseTotal
            FROM #AnnualPerformanceStaging
            GROUP BY ReportYear, ntd_id, uace_code, mode, type_of_service
        ) aps
        LEFT JOIN dw_common.DimDate dd
            ON dd.CalendarYear = aps.ReportYear
            AND dd.CalendarMonth = 1
            AND dd.CalendarDay = 1
        -- CRITIC #3 FIX: Use effective date range instead of CurrentFlag
        -- NOTE: Use dd.FullDate ONLY if dd matched; otherwise use a default date or GETDATE()
        LEFT JOIN dw_common.DimAgency da
            ON da.NTD_ID = aps.ntd_id
            AND COALESCE(dd.FullDate, CAST(CONCAT(aps.ReportYear, '-01-01') AS DATE)) >= da.EffectiveDate
            AND COALESCE(dd.FullDate, CAST(CONCAT(aps.ReportYear, '-01-01') AS DATE)) < da.ExpirationDate
        LEFT JOIN dw_common.DimMode dm
            ON dm.ModeCode = aps.mode
        LEFT JOIN dw_common.DimServiceType dst
            ON dst.TOSCode = aps.type_of_service
        -- CRITIC #3 FIX: Use effective date range for historical accuracy
        LEFT JOIN dw_transport.DimUrbanArea dua
            ON dua.UACECode = aps.uace_code
            AND COALESCE(dd.FullDate, CAST(CONCAT(aps.ReportYear, '-01-01') AS DATE)) >= dua.EffectiveDate
            AND COALESCE(dd.FullDate, CAST(CONCAT(aps.ReportYear, '-01-01') AS DATE)) < dua.ExpirationDate
        GROUP BY
            COALESCE(dd.DateKey, -1),
            COALESCE(da.AgencyKey, -1),
            COALESCE(dm.ModeKey, -1),
            COALESCE(dst.ServiceTypeKey, -1),
            COALESCE(dua.UrbanAreaKey, -1)
        HAVING COALESCE(da.AgencyKey, -1) <> -1  -- Filter out unmatched agencies
            AND (
                (@ReloadIfExists = 1)  -- If reload mode, always insert
                OR (@ReloadIfExists = 0 AND NOT EXISTS (
                    SELECT 1
                    FROM dw_transport.Fact_Annual_Service_Performance fasp
                    WHERE fasp.DateKey = COALESCE(dd.DateKey, -1)
                    AND fasp.AgencyKey = COALESCE(da.AgencyKey, -1)
                    AND fasp.ModeKey = COALESCE(dm.ModeKey, -1)
                    AND fasp.ServiceTypeKey = COALESCE(dst.ServiceTypeKey, -1)
                ))
            );

        SET @RowsInserted = @@ROWCOUNT;

        -- Clean up temporary tables
        DROP TABLE #MasterGrainKeys;
        PRINT CONCAT('Inserted fact records with valid agencies: ', @RowsInserted);

    DROP TABLE #AnnualPerformanceStaging;
        DROP TABLE #UPT;
        DROP TABLE #PMT;
        DROP TABLE #DRM;
        DROP TABLE #Fares;
        DROP TABLE #OpExp;
        DROP TABLE #VRM;
        DROP TABLE #VRH;
        DROP TABLE #VOMS;

        -- Update audit table with success
        UPDATE dw_common.etl_load_audit
        SET load_end_time = SYSDATETIME(),
            rows_processed = @RowsInserted + @RowsDeleted,
            rows_inserted = @RowsInserted,
            rows_deleted = @RowsDeleted,
            status = 'SUCCESS'
        WHERE audit_id = @AuditId;

        IF @TransactionStarted = 1
            COMMIT TRANSACTION;

        PRINT CONCAT(
            'sp_Load_Fact_Annual_Service_Performance: ',
            @RowsInserted, ' rows inserted'
        );

    END TRY
    BEGIN CATCH
        IF @TransactionStarted = 1 AND @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;

        SET @ErrorMsg = ERROR_MESSAGE();

        -- Log failure
        UPDATE dw_common.etl_load_audit
        SET load_end_time = SYSDATETIME(),
            status = 'FAILED',
            error_message = @ErrorMsg
        WHERE audit_id = @AuditId;

        PRINT CONCAT(
            'ERROR in sp_Load_Fact_Annual_Service_Performance: ',
            @ErrorMsg
        );
        THROW;
    END CATCH

END;
GO

-- ============================================================
-- 2. FACT_MAJOR_SAFETY_EVENT ETL
--    Transaction fact table with incident-level metrics
-- ============================================================

IF OBJECT_ID('dw_transport.sp_Load_Fact_Major_Safety_Event', 'P') IS NOT NULL
    DROP PROCEDURE dw_transport.sp_Load_Fact_Major_Safety_Event;
GO

CREATE PROCEDURE dw_transport.sp_Load_Fact_Major_Safety_Event
    @BatchID BIGINT = NULL,
    @SourceSystem VARCHAR(50) = 'NTD_Safety_Events',
    @ReloadIfExists BIT = 0
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    DECLARE @RowsInserted INT = 0;
    DECLARE @RowsDeleted INT = 0;
    DECLARE @LoadStartTime DATETIME2 = SYSDATETIME();
    DECLARE @LoadDate DATE = CAST(GETDATE() AS DATE);
    DECLARE @TransactionStarted BIT = 0;
    DECLARE @AuditId INT;
    DECLARE @ErrorMsg NVARCHAR(MAX) = NULL;

    -- Log start of audit
    INSERT INTO dw_common.etl_load_audit (
        procedure_name, load_date, load_start_time, status
    )
    VALUES ('dw_transport.sp_Load_Fact_Major_Safety_Event', @LoadDate, @LoadStartTime, 'IN_PROGRESS');
    SET @AuditId = SCOPE_IDENTITY();

    BEGIN TRY
        IF @@TRANCOUNT = 0
        BEGIN
            BEGIN TRANSACTION;
            SET @TransactionStarted = 1;
        END

        -- ============================================================
        -- STEP 1: Prepare working table with dimension key lookups
        -- ============================================================

        IF OBJECT_ID('tempdb..#ResolvedSafetyEvents', 'U') IS NOT NULL
            DROP TABLE #ResolvedSafetyEvents;

        CREATE TABLE #ResolvedSafetyEvents (
            incident_number BIGINT,
            event_date_key INT,
            agency_key INT,
            mode_key INT,
            service_type_key INT,
            urban_area_key INT,
            safety_event_type_key INT,
            safety_incident_key INT,
            event_time TIME,
            passenger_fatality_count INT,
            employee_fatality_count INT,
            other_fatality_count INT,
            total_fatality_count INT,
            passenger_injury_count INT,
            employee_injury_count INT,
            other_injury_count INT,
            total_injury_count INT,
            vehicle_involved_count INT,
            evacuation_count INT,
            property_damage_amount DECIMAL(18,2)
        );

        -- ============================================================
        -- STEP 2: Lookup all dimension keys from staging data
        --         CRITIC #3 FIX: Use SCD Type 2 effective date ranges
        --         for DimAgency and DimUrbanArea lookups
        -- ============================================================

        INSERT INTO #ResolvedSafetyEvents (
            incident_number,
            event_date_key,
            agency_key,
            mode_key,
            service_type_key,
            urban_area_key,
            safety_event_type_key,
            safety_incident_key,
            event_time,
            passenger_fatality_count,
            employee_fatality_count,
            other_fatality_count,
            total_fatality_count,
            passenger_injury_count,
            employee_injury_count,
            other_injury_count,
            total_injury_count,
            vehicle_involved_count,
            evacuation_count,
            property_damage_amount
        )
        SELECT
            mse.incident_number,
            COALESCE(dd.DateKey, -1) AS event_date_key,
            -- Use NOT NULL DEFAULT(-1) for foreign keys (Kimball best practice)
            COALESCE(da.AgencyKey, -1) AS agency_key,
            COALESCE(dm.ModeKey, -1) AS mode_key,
            COALESCE(dst.ServiceTypeKey, -1) AS service_type_key,
            COALESCE(dua.UrbanAreaKey, -1) AS urban_area_key,
            COALESCE(dset.SafetyEventTypeKey, -1) AS safety_event_type_key,
            COALESCE(dsi.SafetyIncidentKey, -1) AS safety_incident_key,
            mse.event_time,
            mse.passenger_fatality_count,
            mse.employee_fatality_count,
            mse.other_fatality_count,
            mse.total_fatality_count,                          -- Store from source, not computed
            mse.passenger_injury_count,
            mse.employee_injury_count,
            mse.other_injury_count,
            mse.total_injury_count,                            -- Store from source, not computed
            mse.number_of_transit_vehicles_involved,
            CASE WHEN mse.evacuation = 1 THEN 1 ELSE 0 END AS evacuation_count,
            mse.property_damage_amount
        FROM stg_transport.stg_major_safety_event mse
        LEFT JOIN dw_common.DimDate dd
            ON dd.FullDate = mse.event_date
        -- CRITIC #3 FIX: SCD Type 2 effective date range lookup
        LEFT JOIN dw_common.DimAgency da
            ON da.NTD_ID = mse.ntd_id
            AND mse.event_date >= da.EffectiveDate
            AND mse.event_date < da.ExpirationDate
        LEFT JOIN dw_common.DimMode dm
            ON dm.ModeCode = mse.mode
        LEFT JOIN dw_common.DimServiceType dst
            ON dst.TOSCode = mse.type_of_service_code
        -- CRITIC #3 FIX: SCD Type 2 effective date range lookup
        LEFT JOIN dw_transport.DimUrbanArea dua
            ON dua.UACECode = mse.primary_uza_uace_code
            AND mse.event_date >= dua.EffectiveDate
            AND mse.event_date < dua.ExpirationDate
        LEFT JOIN dw_transport.DimSafetyEventType dset
            ON dset.EventCategory = mse.event_category
            AND dset.EventType = mse.event_type
            AND dset.EventSubType = mse.event_type_group
            AND dset.SeverityLevel = CASE
                WHEN mse.safety_security = 'SFT' THEN 'Safety'
                WHEN mse.safety_security = 'SEC' THEN 'Security'
                ELSE NULL
            END
        LEFT JOIN dw_transport.DimSafetyIncident dsi
            ON dsi.SourceEventID = CAST(mse.incident_number AS VARCHAR(50));

        -- ============================================================
        -- STEP 3: Optional reload handling for data corrections
        --         Added @ReloadIfExists parameter support
        -- ============================================================

        IF @ReloadIfExists = 1 AND @BatchID IS NOT NULL
        BEGIN
            DELETE FROM dw_transport.Fact_Major_Safety_Event
            WHERE ETL_BatchID = @BatchID;
            SET @RowsDeleted = @@ROWCOUNT;
            PRINT CONCAT('Deleted ', @RowsDeleted, ' rows for reload (BatchID: ', @BatchID, ')');
        END

        -- ============================================================
        -- STEP 4: Insert into fact table
        -- ============================================================

        INSERT INTO dw_transport.Fact_Major_Safety_Event (
            EventDateKey,
            AgencyKey,
            ModeKey,
            ServiceTypeKey,
            UrbanAreaKey,
            SafetyEventTypeKey,
            SafetyIncidentDescriptionKey,
            EventTime,
            PassengerFatalityCount,
            EmployeeFatalityCount,
            OtherFatalityCount,
            TotalFatalityCount,
            PassengerInjuryCount,
            EmployeeInjuryCount,
            OtherInjuryCount,
            TotalInjuryCount,
            VehicleInvolvedCount,
            EvacuationCount,
            PropertyDamageAmount,
            SourceIncidentID,
            ETL_InsertDate,
            ETL_UpdateDate,
            ETL_BatchID,
            RecordSourceSystem
        )
        SELECT
            event_date_key,
            agency_key,
            mode_key,                          -- NOT NULL DEFAULT(-1) per DDL
            service_type_key,                  -- NOT NULL DEFAULT(-1) per DDL
            urban_area_key,                    -- NOT NULL DEFAULT(-1) per DDL
            safety_event_type_key,
            safety_incident_key,
            event_time,
            passenger_fatality_count,
            employee_fatality_count,
            other_fatality_count,
            total_fatality_count,              -- Stored from source, not computed
            passenger_injury_count,
            employee_injury_count,
            other_injury_count,
            total_injury_count,                -- Stored from source, not computed
            vehicle_involved_count,
            evacuation_count,
            property_damage_amount,
            CAST(incident_number AS VARCHAR(50)),
            @LoadStartTime,
            NULL,
            @BatchID,
            @SourceSystem
        FROM #ResolvedSafetyEvents r
        -- Use filtered unique index on SourceIncidentID to prevent duplicate loads
        WHERE NOT EXISTS (
            SELECT 1
            FROM dw_transport.Fact_Major_Safety_Event f
            WHERE f.SourceIncidentID = CAST(r.incident_number AS VARCHAR(50))
        );

        SET @RowsInserted = @@ROWCOUNT;

        DROP TABLE #ResolvedSafetyEvents;

        -- Update audit table with success
        UPDATE dw_common.etl_load_audit
        SET load_end_time = SYSDATETIME(),
            rows_processed = @RowsInserted + @RowsDeleted,
            rows_inserted = @RowsInserted,
            rows_deleted = @RowsDeleted,
            status = 'SUCCESS'
        WHERE audit_id = @AuditId;

        IF @TransactionStarted = 1
            COMMIT TRANSACTION;

        PRINT CONCAT(
            'sp_Load_Fact_Major_Safety_Event: ',
            @RowsInserted, ' rows inserted'
        );

    END TRY
    BEGIN CATCH
        IF @TransactionStarted = 1 AND @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;

        SET @ErrorMsg = ERROR_MESSAGE();

        -- Log failure
        UPDATE dw_common.etl_load_audit
        SET load_end_time = SYSDATETIME(),
            status = 'FAILED',
            error_message = @ErrorMsg
        WHERE audit_id = @AuditId;

        PRINT CONCAT(
            'ERROR in sp_Load_Fact_Major_Safety_Event: ',
            @ErrorMsg
        );
        THROW;
    END CATCH

END;
GO

-- ============================================================
-- 3. FACT_SERVICE_AVAILABILITY ETL
--    Factless coverage table: service active periods
-- ============================================================

IF OBJECT_ID('dw_transport.sp_Load_Fact_Service_Availability', 'P') IS NOT NULL
    DROP PROCEDURE dw_transport.sp_Load_Fact_Service_Availability;
GO

CREATE PROCEDURE dw_transport.sp_Load_Fact_Service_Availability
    @BatchID BIGINT = NULL,
    @SourceSystem VARCHAR(50) = 'NTD_Service_Schedule',
    @ReloadIfExists BIT = 0
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    DECLARE @RowsInserted INT = 0;
    DECLARE @RowsDeleted INT = 0;
    DECLARE @LoadStartTime DATETIME2 = SYSDATETIME();
    DECLARE @LoadDate DATE = CAST(GETDATE() AS DATE);
    DECLARE @TransactionStarted BIT = 0;
    DECLARE @AuditId INT;
    DECLARE @ErrorMsg NVARCHAR(MAX) = NULL;

    -- Log start of audit
    INSERT INTO dw_common.etl_load_audit (
        procedure_name, load_date, load_start_time, status
    )
    VALUES ('dw_transport.sp_Load_Fact_Service_Availability', @LoadDate, @LoadStartTime, 'IN_PROGRESS');
    SET @AuditId = SCOPE_IDENTITY();

    BEGIN TRY
        IF @@TRANCOUNT = 0
        BEGIN
            BEGIN TRANSACTION;
            SET @TransactionStarted = 1;
        END

        -- ============================================================
        -- Optional reload handling for data corrections
        -- ============================================================

        IF @ReloadIfExists = 1 AND @BatchID IS NOT NULL
        BEGIN
            DELETE FROM dw_transport.Fact_Service_Availability
            WHERE ETL_BatchID = @BatchID;
            SET @RowsDeleted = @@ROWCOUNT;
            PRINT CONCAT('Deleted ', @RowsDeleted, ' rows for reload (BatchID: ', @BatchID, ')');
        END

        INSERT INTO dw_transport.Fact_Service_Availability (
            AgencyKey,
            ModeKey,
            ServiceTypeKey,
            CommitmentDateKey,
            StartDateKey,
            EndDateKey,
            ServiceActiveFlag,
            ETL_InsertDate,
            ETL_UpdateDate,
            ETL_BatchID,
            RecordSourceSystem
        )
        SELECT
            COALESCE(da.AgencyKey, -1) AS AgencyKey,
            COALESCE(dm.ModeKey, -1) AS ModeKey,
            COALESCE(dst.ServiceTypeKey, -1) AS ServiceTypeKey,
            -- Optional milestone: NULL is valid for missing commitment dates
            dd_commitment.DateKey AS CommitmentDateKey,
            -- Required milestone: must exist (filter in WHERE clause)
            dd_start.DateKey AS StartDateKey,
            -- Ongoing service: use special maximum date (9999-12-31) for open-ended services
            COALESCE(dd_end.DateKey, 99991231) AS EndDateKey,
            -- Store source value: use 1 for 'Active Service', 0 for 'Ending Service'
            -- Don't recompute based on today's date; store what source says
            CASE
                WHEN sams.service_type = 'Active Service' THEN 1
                WHEN sams.service_type = 'Ending Service' THEN 0
                ELSE 1  -- Default to active if unclear
            END AS ServiceActiveFlag,
            @LoadStartTime,
            NULL,
            @BatchID,
            @SourceSystem
        FROM (
            -- Deduplicate staging data: source may contain duplicate service records
            -- Use ROW_NUMBER to keep only the first occurrence of each unique service
            SELECT
                *,
                ROW_NUMBER() OVER (
                    PARTITION BY ntd_id, mode, type_of_service_code, service_type, 
                                 commitment_date, start_service_date, end_service_date
                    ORDER BY CASE WHEN start_service_date IS NULL THEN 1 ELSE 0 END ASC, start_service_date DESC
                ) AS rn
            FROM stg_transport.stg_agency_mode_service
        ) sams
        -- Use SCD Type 2 effective date range instead of CurrentFlag
        LEFT JOIN dw_common.DimAgency da
            ON da.NTD_ID = sams.ntd_id
            AND sams.start_service_date >= da.EffectiveDate
            AND sams.start_service_date < da.ExpirationDate
        LEFT JOIN dw_common.DimMode dm
            ON dm.ModeCode = sams.mode
        LEFT JOIN dw_common.DimServiceType dst
            ON dst.TOSCode = sams.type_of_service_code
        LEFT JOIN dw_common.DimDate dd_commitment
            ON dd_commitment.FullDate = sams.commitment_date
        LEFT JOIN dw_common.DimDate dd_start
            ON dd_start.FullDate = sams.start_service_date
        LEFT JOIN dw_common.DimDate dd_end
            ON dd_end.FullDate = sams.end_service_date
        -- Exclude administrative rows that aren't actual service periods
        -- Require a valid start date (actual service must have known start date)
        -- Require a valid agency (ignore rows where agency cannot be identified)
        -- Deduplicate: keep only first occurrence of each unique service
        WHERE sams.rn = 1
        AND sams.service_type IN ('Active Service','Ending Service')
        AND dd_start.DateKey IS NOT NULL
        AND da.AgencyKey IS NOT NULL
        -- Only insert if not already present (unless reload mode)
        AND ((@ReloadIfExists = 1) OR (@ReloadIfExists = 0 AND NOT EXISTS (
            SELECT 1
            FROM dw_transport.Fact_Service_Availability fsa
            WHERE fsa.AgencyKey = COALESCE(da.AgencyKey, -1)
            AND fsa.ModeKey = COALESCE(dm.ModeKey, -1)
            AND fsa.ServiceTypeKey = COALESCE(dst.ServiceTypeKey, -1)
            AND fsa.CommitmentDateKey = dd_commitment.DateKey
            AND fsa.StartDateKey = dd_start.DateKey
            AND fsa.EndDateKey = COALESCE(dd_end.DateKey, 99991231)
        )));

        SET @RowsInserted = @@ROWCOUNT;

        -- Update audit table with success
        UPDATE dw_common.etl_load_audit
        SET load_end_time = SYSDATETIME(),
            rows_processed = @RowsInserted + @RowsDeleted,
            rows_inserted = @RowsInserted,
            rows_deleted = @RowsDeleted,
            status = 'SUCCESS'
        WHERE audit_id = @AuditId;

        IF @TransactionStarted = 1
            COMMIT TRANSACTION;

        PRINT CONCAT(
            'sp_Load_Fact_Service_Availability: ',
            @RowsInserted, ' rows inserted'
        );

    END TRY
    BEGIN CATCH
        IF @TransactionStarted = 1 AND @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;

        SET @ErrorMsg = ERROR_MESSAGE();

        -- Log failure
        UPDATE dw_common.etl_load_audit
        SET load_end_time = SYSDATETIME(),
            status = 'FAILED',
            error_message = @ErrorMsg
        WHERE audit_id = @AuditId;

        PRINT CONCAT(
            'ERROR in sp_Load_Fact_Service_Availability: ',
            @ErrorMsg
        );
        THROW;
    END CATCH

END;
GO

-- ============================================================
-- 4. FACT_SERVICE_LIFECYCLE_ACCUMULATING ETL
--    Accumulating snapshot: service lifecycle tracking
-- ============================================================

IF OBJECT_ID('dw_transport.sp_Load_Fact_Service_Lifecycle_Accumulating', 'P') IS NOT NULL
    DROP PROCEDURE dw_transport.sp_Load_Fact_Service_Lifecycle_Accumulating;
GO

CREATE PROCEDURE dw_transport.sp_Load_Fact_Service_Lifecycle_Accumulating
    @BatchID BIGINT = NULL,
    @SourceSystem VARCHAR(50) = 'NTD_Lifecycle'
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    DECLARE @RowsInserted INT = 0;
    DECLARE @RowsUpdated INT = 0;
    DECLARE @LoadStartTime DATETIME2 = SYSDATETIME();
    DECLARE @LoadDate DATE = CAST(GETDATE() AS DATE);
    DECLARE @TransactionStarted BIT = 0;
    DECLARE @AuditId INT;
    DECLARE @ErrorMsg NVARCHAR(MAX) = NULL;

    -- Log start of audit
    INSERT INTO dw_common.etl_load_audit (
        procedure_name, load_date, load_start_time, status
    )
    VALUES ('dw_transport.sp_Load_Fact_Service_Lifecycle_Accumulating', @LoadDate, @LoadStartTime, 'IN_PROGRESS');
    SET @AuditId = SCOPE_IDENTITY();

    BEGIN TRY
        IF @@TRANCOUNT = 0
        BEGIN
            BEGIN TRANSACTION;
            SET @TransactionStarted = 1;
        END

        -- ============================================================
        -- STEP 1: Aggregate annual service performance with separate
        --         peak date tracking for each metric (UPT, VRM, VRH, VOMS)
        --         Also compute YearsInService from calendar year span
        -- ============================================================

        IF OBJECT_ID('tempdb..#ServiceLifecycleAgg', 'U') IS NOT NULL
            DROP TABLE #ServiceLifecycleAgg;

        CREATE TABLE #ServiceLifecycleAgg (
            AgencyKey INT,
            ModeKey INT,
            ServiceTypeKey INT,
            UrbanAreaKey INT,
            FirstObservedDateKey INT,
            CommitmentDateKey INT,
            PeakUPTDateKey INT,
            PeakVRMDateKey INT,
            PeakVRHDateKey INT,
            PeakVOMSDateKey INT,
            LatestObservedDateKey INT,
            EndServiceDateKey INT,
            YearsInService INT,
            PeakAnnualUPT BIGINT,
            PeakAnnualVRM BIGINT,
            PeakAnnualVRH BIGINT,
            PeakAnnualVOMS INT,
            LatestAnnualUPT BIGINT,
            LatestAnnualVRM BIGINT,
            LatestAnnualVRH BIGINT,
            LatestAnnualVOMS INT,
            TotalObservedUPT BIGINT,
            TotalObservedVRM BIGINT,
            TotalObservedVRH BIGINT,
            TotalObservedMajorSafetyEvents INT,
            TotalObservedFatalities INT,
            TotalObservedInjuries INT,
            LifecycleCompleteFlag BIT
        );

        -- Aggregate annual performance with separate peak ranking per metric
        WITH AnnualAgg AS (
            SELECT
                aa.AgencyKey,
                aa.ModeKey,
                aa.ServiceTypeKey,
                aa.UrbanAreaKey,
                aa.DateKey,
                dd.CalendarYear,
                aa.UPT,
                aa.VRM,
                aa.VRH,
                aa.VOMS,
                ROW_NUMBER() OVER (
                    PARTITION BY aa.AgencyKey, aa.ModeKey, aa.ServiceTypeKey
                    ORDER BY COALESCE(aa.UPT, 0) DESC, aa.DateKey DESC
                ) AS UTPeakRank,
                ROW_NUMBER() OVER (
                    PARTITION BY aa.AgencyKey, aa.ModeKey, aa.ServiceTypeKey
                    ORDER BY COALESCE(aa.VRM, 0) DESC, aa.DateKey DESC
                ) AS VRMPeakRank,
                ROW_NUMBER() OVER (
                    PARTITION BY aa.AgencyKey, aa.ModeKey, aa.ServiceTypeKey
                    ORDER BY COALESCE(aa.VRH, 0) DESC, aa.DateKey DESC
                ) AS VRHPeakRank,
                ROW_NUMBER() OVER (
                    PARTITION BY aa.AgencyKey, aa.ModeKey, aa.ServiceTypeKey
                    ORDER BY COALESCE(aa.VOMS, 0) DESC, aa.DateKey DESC
                ) AS VOMSPeakRank,
                ROW_NUMBER() OVER (
                    PARTITION BY aa.AgencyKey, aa.ModeKey, aa.ServiceTypeKey
                    ORDER BY aa.DateKey DESC
                ) AS LatestRank,
                ROW_NUMBER() OVER (
                    PARTITION BY aa.AgencyKey, aa.ModeKey, aa.ServiceTypeKey
                    ORDER BY aa.DateKey ASC
                ) AS FirstRank
            FROM dw_transport.Fact_Annual_Service_Performance aa
            JOIN dw_common.DimDate dd
                ON aa.DateKey = dd.DateKey
        ),
        -- Pick primary urban area (most frequently reported)
        PrimaryUrbanArea AS (
            SELECT
                AgencyKey,
                ModeKey,
                ServiceTypeKey,
                UrbanAreaKey AS PrimaryUrbanAreaKey
            FROM (
                SELECT
                    AgencyKey,
                    ModeKey,
                    ServiceTypeKey,
                    UrbanAreaKey,
                    ROW_NUMBER() OVER (
                        PARTITION BY AgencyKey, ModeKey, ServiceTypeKey
                        ORDER BY RecordCount DESC
                    ) AS rn
                FROM (
                    SELECT
                        AgencyKey,
                        ModeKey,
                        ServiceTypeKey,
                        UrbanAreaKey,
                        COUNT(*) AS RecordCount
                    FROM dw_transport.Fact_Annual_Service_Performance
                    WHERE UrbanAreaKey <> -1
                    GROUP BY AgencyKey, ModeKey, ServiceTypeKey, UrbanAreaKey
                ) ua
            ) ranked
            WHERE rn = 1
        )
        INSERT INTO #ServiceLifecycleAgg (
            AgencyKey,
            ModeKey,
            ServiceTypeKey,
            UrbanAreaKey,
            FirstObservedDateKey,
            CommitmentDateKey,
            PeakUPTDateKey,
            PeakVRMDateKey,
            PeakVRHDateKey,
            PeakVOMSDateKey,
            LatestObservedDateKey,
            YearsInService,
            PeakAnnualUPT,
            PeakAnnualVRM,
            PeakAnnualVRH,
            PeakAnnualVOMS,
            LatestAnnualUPT,
            LatestAnnualVRM,
            LatestAnnualVRH,
            LatestAnnualVOMS,
            TotalObservedUPT,
            TotalObservedVRM,
            TotalObservedVRH,
            TotalObservedMajorSafetyEvents,
            TotalObservedFatalities,
            TotalObservedInjuries,
            LifecycleCompleteFlag
        )
        SELECT
            aa.AgencyKey,
            aa.ModeKey,
            aa.ServiceTypeKey,
            COALESCE(pua.PrimaryUrbanAreaKey, -1) AS UrbanAreaKey,
            first_year.DateKey,
            NULL AS CommitmentDateKey,  -- Will be populated from Fact_Service_Availability in STEP 2
            upt_peak.DateKey,
            vrm_peak.DateKey,
            vrh_peak.DateKey,
            voms_peak.DateKey,
            latest_year.DateKey,
            MAX(aa.CalendarYear) - MIN(aa.CalendarYear) + 1 AS YearsInService,  -- FIX #1: Calendar year span
            upt_peak.UPT,
            vrm_peak.VRM,
            vrh_peak.VRH,
            voms_peak.VOMS,
            latest_year.UPT,
            latest_year.VRM,
            latest_year.VRH,
            latest_year.VOMS,
            SUM(COALESCE(aa.UPT, 0)) AS TotalObservedUPT,
            SUM(COALESCE(aa.VRM, 0)) AS TotalObservedVRM,
            SUM(COALESCE(aa.VRH, 0)) AS TotalObservedVRH,
            0 AS TotalObservedMajorSafetyEvents,
            0 AS TotalObservedFatalities,
            0 AS TotalObservedInjuries,
            0 AS LifecycleCompleteFlag
        FROM AnnualAgg aa
        LEFT JOIN PrimaryUrbanArea pua
            ON aa.AgencyKey = pua.AgencyKey
            AND aa.ModeKey = pua.ModeKey
            AND aa.ServiceTypeKey = pua.ServiceTypeKey
        JOIN AnnualAgg first_year
            ON aa.AgencyKey = first_year.AgencyKey
            AND aa.ModeKey = first_year.ModeKey
            AND aa.ServiceTypeKey = first_year.ServiceTypeKey
            AND first_year.FirstRank = 1
        -- FIX #2: Separate peak tracking for each metric
        JOIN AnnualAgg upt_peak
            ON aa.AgencyKey = upt_peak.AgencyKey
            AND aa.ModeKey = upt_peak.ModeKey
            AND aa.ServiceTypeKey = upt_peak.ServiceTypeKey
            AND upt_peak.UTPeakRank = 1
        JOIN AnnualAgg vrm_peak
            ON aa.AgencyKey = vrm_peak.AgencyKey
            AND aa.ModeKey = vrm_peak.ModeKey
            AND aa.ServiceTypeKey = vrm_peak.ServiceTypeKey
            AND vrm_peak.VRMPeakRank = 1
        JOIN AnnualAgg vrh_peak
            ON aa.AgencyKey = vrh_peak.AgencyKey
            AND aa.ModeKey = vrh_peak.ModeKey
            AND aa.ServiceTypeKey = vrh_peak.ServiceTypeKey
            AND vrh_peak.VRHPeakRank = 1
        JOIN AnnualAgg voms_peak
            ON aa.AgencyKey = voms_peak.AgencyKey
            AND aa.ModeKey = voms_peak.ModeKey
            AND aa.ServiceTypeKey = voms_peak.ServiceTypeKey
            AND voms_peak.VOMSPeakRank = 1
        JOIN AnnualAgg latest_year
            ON aa.AgencyKey = latest_year.AgencyKey
            AND aa.ModeKey = latest_year.ModeKey
            AND aa.ServiceTypeKey = latest_year.ServiceTypeKey
            AND latest_year.LatestRank = 1
        GROUP BY
            aa.AgencyKey,
            aa.ModeKey,
            aa.ServiceTypeKey,
            pua.PrimaryUrbanAreaKey,
            first_year.DateKey,
            upt_peak.DateKey,
            vrm_peak.DateKey,
            vrh_peak.DateKey,
            voms_peak.DateKey,
            latest_year.DateKey,
            upt_peak.UPT,
            vrm_peak.VRM,
            vrh_peak.VRH,
            voms_peak.VOMS,
            latest_year.UPT,
            latest_year.VRM,
            latest_year.VRH,
            latest_year.VOMS;

        -- ============================================================
        -- STEP 2: Add commitment date from Fact_Service_Availability
        --         FIX #6 & #7: Derive lifecycle milestones from warehouse data
        --         instead of staging. Use effective date ranges for SCD Type 2.
        -- ============================================================

        UPDATE sla
        SET sla.CommitmentDateKey = COALESCE(sa_commitment.CommitmentDateKey, sla.FirstObservedDateKey),
            sla.EndServiceDateKey = COALESCE(sa_end.EndDateKey, sla.EndServiceDateKey),
            sla.LifecycleCompleteFlag = CASE
                WHEN sa_end.EndDateKey IS NOT NULL
                     AND sa_end.EndDateKey < sla.LatestObservedDateKey
                THEN 1
                ELSE 0
            END
        FROM #ServiceLifecycleAgg sla
        LEFT JOIN (
            -- Get earliest commitment date for each service
            SELECT
                AgencyKey,
                ModeKey,
                ServiceTypeKey,
                MIN(CommitmentDateKey) AS CommitmentDateKey
            FROM dw_transport.Fact_Service_Availability
            WHERE CommitmentDateKey IS NOT NULL
            GROUP BY AgencyKey, ModeKey, ServiceTypeKey
        ) sa_commitment
            ON sla.AgencyKey = sa_commitment.AgencyKey
            AND sla.ModeKey = sa_commitment.ModeKey
            AND sla.ServiceTypeKey = sa_commitment.ServiceTypeKey
        LEFT JOIN (
            -- Get latest end date where service actually ended (before latest report)
            SELECT
                AgencyKey,
                ModeKey,
                ServiceTypeKey,
                MAX(EndDateKey) AS EndDateKey
            FROM dw_transport.Fact_Service_Availability
            WHERE ServiceActiveFlag = 0
            GROUP BY AgencyKey, ModeKey, ServiceTypeKey
        ) sa_end
            ON sla.AgencyKey = sa_end.AgencyKey
            AND sla.ModeKey = sa_end.ModeKey
            AND sla.ServiceTypeKey = sa_end.ServiceTypeKey;

        -- ============================================================
        -- STEP 3: Update safety metrics from Fact_Major_Safety_Event
        --         FIX #5: Use proper three-way JOIN (no ON 1=1 pattern)
        -- ============================================================

        UPDATE sla
        SET sla.TotalObservedMajorSafetyEvents = safety_agg.EventCount,
            sla.TotalObservedFatalities = safety_agg.TotalFatalities,
            sla.TotalObservedInjuries = safety_agg.TotalInjuries
        FROM #ServiceLifecycleAgg sla
        LEFT JOIN (
            SELECT
                AgencyKey,
                ModeKey,
                ServiceTypeKey,
                COUNT(*) AS EventCount,
                COALESCE(SUM(TotalFatalityCount), 0) AS TotalFatalities,
                COALESCE(SUM(TotalInjuryCount), 0) AS TotalInjuries
            FROM dw_transport.Fact_Major_Safety_Event
            GROUP BY AgencyKey, ModeKey, ServiceTypeKey
        ) safety_agg
            ON sla.AgencyKey = safety_agg.AgencyKey
            AND sla.ModeKey = safety_agg.ModeKey
            AND sla.ServiceTypeKey = safety_agg.ServiceTypeKey;

        -- ============================================================
        -- STEP 4: UPSERT into fact table using business key
        --         (AgencyKey, ModeKey, ServiceTypeKey)
        -- ============================================================

        -- UPDATE existing records
        UPDATE dw_transport.Fact_Service_Lifecycle_Accumulating
        SET
            UrbanAreaKey = sla.UrbanAreaKey,
            FirstObservedDateKey = sla.FirstObservedDateKey,
            CommitmentDateKey = sla.CommitmentDateKey,
            PeakUPTDateKey = sla.PeakUPTDateKey,
            PeakVRMDateKey = sla.PeakVRMDateKey,
            PeakVRHDateKey = sla.PeakVRHDateKey,
            PeakVOMSDateKey = sla.PeakVOMSDateKey,
            LatestObservedDateKey = sla.LatestObservedDateKey,
            EndServiceDateKey = sla.EndServiceDateKey,
            YearsInService = sla.YearsInService,
            PeakAnnualUPT = sla.PeakAnnualUPT,
            PeakAnnualVRM = sla.PeakAnnualVRM,
            PeakAnnualVRH = sla.PeakAnnualVRH,
            PeakAnnualVOMS = sla.PeakAnnualVOMS,
            LatestAnnualUPT = sla.LatestAnnualUPT,
            LatestAnnualVRM = sla.LatestAnnualVRM,
            LatestAnnualVRH = sla.LatestAnnualVRH,
            LatestAnnualVOMS = sla.LatestAnnualVOMS,
            TotalObservedUPT = sla.TotalObservedUPT,
            TotalObservedVRM = sla.TotalObservedVRM,
            TotalObservedVRH = sla.TotalObservedVRH,
            TotalObservedMajorSafetyEvents = sla.TotalObservedMajorSafetyEvents,
            TotalObservedFatalities = sla.TotalObservedFatalities,
            TotalObservedInjuries = sla.TotalObservedInjuries,
            LifecycleCompleteFlag = sla.LifecycleCompleteFlag,
            ETL_UpdateDate = @LoadStartTime,
            ETL_BatchID = @BatchID
        FROM #ServiceLifecycleAgg sla
        WHERE dw_transport.Fact_Service_Lifecycle_Accumulating.AgencyKey = sla.AgencyKey
        AND dw_transport.Fact_Service_Lifecycle_Accumulating.ModeKey = sla.ModeKey
        AND dw_transport.Fact_Service_Lifecycle_Accumulating.ServiceTypeKey = sla.ServiceTypeKey;

        SET @RowsUpdated = @@ROWCOUNT;

        -- INSERT new records
        INSERT INTO dw_transport.Fact_Service_Lifecycle_Accumulating (
            AgencyKey,
            ModeKey,
            ServiceTypeKey,
            UrbanAreaKey,
            FirstObservedDateKey,
            CommitmentDateKey,
            PeakUPTDateKey,
            PeakVRMDateKey,
            PeakVRHDateKey,
            PeakVOMSDateKey,
            LatestObservedDateKey,
            EndServiceDateKey,
            YearsInService,
            PeakAnnualUPT,
            PeakAnnualVRM,
            PeakAnnualVRH,
            PeakAnnualVOMS,
            LatestAnnualUPT,
            LatestAnnualVRM,
            LatestAnnualVRH,
            LatestAnnualVOMS,
            TotalObservedUPT,
            TotalObservedVRM,
            TotalObservedVRH,
            TotalObservedMajorSafetyEvents,
            TotalObservedFatalities,
            TotalObservedInjuries,
            LifecycleCompleteFlag,
            ETL_InsertDate,
            ETL_UpdateDate,
            ETL_BatchID,
            RecordSourceSystem
        )
        SELECT
            sla.AgencyKey,
            sla.ModeKey,
            sla.ServiceTypeKey,
            sla.UrbanAreaKey,
            sla.FirstObservedDateKey,
            sla.CommitmentDateKey,
            sla.PeakUPTDateKey,
            sla.PeakVRMDateKey,
            sla.PeakVRHDateKey,
            sla.PeakVOMSDateKey,
            sla.LatestObservedDateKey,
            sla.EndServiceDateKey,
            sla.YearsInService,
            sla.PeakAnnualUPT,
            sla.PeakAnnualVRM,
            sla.PeakAnnualVRH,
            sla.PeakAnnualVOMS,
            sla.LatestAnnualUPT,
            sla.LatestAnnualVRM,
            sla.LatestAnnualVRH,
            sla.LatestAnnualVOMS,
            sla.TotalObservedUPT,
            sla.TotalObservedVRM,
            sla.TotalObservedVRH,
            sla.TotalObservedMajorSafetyEvents,
            sla.TotalObservedFatalities,
            sla.TotalObservedInjuries,
            sla.LifecycleCompleteFlag,
            @LoadStartTime,
            NULL,
            @BatchID,
            @SourceSystem
        FROM #ServiceLifecycleAgg sla
        WHERE NOT EXISTS (
            SELECT 1
            FROM dw_transport.Fact_Service_Lifecycle_Accumulating fsla
            WHERE fsla.AgencyKey = sla.AgencyKey
            AND fsla.ModeKey = sla.ModeKey
            AND fsla.ServiceTypeKey = sla.ServiceTypeKey
        );

        SET @RowsInserted = @@ROWCOUNT;

        DROP TABLE #ServiceLifecycleAgg;

        -- Update audit table with success
        UPDATE dw_common.etl_load_audit
        SET load_end_time = SYSDATETIME(),
            rows_processed = @RowsInserted + @RowsUpdated,
            rows_inserted = @RowsInserted,
            rows_updated = @RowsUpdated,
            status = 'SUCCESS'
        WHERE audit_id = @AuditId;

        IF @TransactionStarted = 1
            COMMIT TRANSACTION;

        PRINT CONCAT(
            'sp_Load_Fact_Service_Lifecycle_Accumulating: Inserted ',
            @RowsInserted, ' rows, updated ',
            @RowsUpdated, ' rows'
        );

    END TRY
    BEGIN CATCH
        IF @TransactionStarted = 1 AND @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;

        SET @ErrorMsg = ERROR_MESSAGE();

        -- Log failure
        UPDATE dw_common.etl_load_audit
        SET load_end_time = SYSDATETIME(),
            status = 'FAILED',
            error_message = @ErrorMsg
        WHERE audit_id = @AuditId;

        PRINT CONCAT(
            'ERROR in sp_Load_Fact_Service_Lifecycle_Accumulating: ',
            @ErrorMsg
        );
        THROW;
    END CATCH

END;
GO

-- ============================================================
-- MASTER PROCEDURE: Load all fact tables
-- ============================================================

IF OBJECT_ID('dw_transport.sp_Load_All_Facts', 'P') IS NOT NULL
    DROP PROCEDURE dw_transport.sp_Load_All_Facts;
GO

CREATE PROCEDURE dw_transport.sp_Load_All_Facts
    @BatchID BIGINT = NULL,
    @ReloadIfExists BIT = 0
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    DECLARE @CurrentBatchID BIGINT = ISNULL(@BatchID, CAST(FORMAT(GETDATE(), 'yyyyMMddHHmmss') AS BIGINT));

    PRINT CONCAT('Starting fact table ETL (BatchID: ', @CurrentBatchID, ')');

    BEGIN TRY

        EXEC dw_transport.sp_Load_Fact_Annual_Service_Performance
            @BatchID = @CurrentBatchID,
            @SourceSystem = 'NTD_Annual_Performance',
            @ReloadIfExists = @ReloadIfExists;

        EXEC dw_transport.sp_Load_Fact_Major_Safety_Event
            @BatchID = @CurrentBatchID,
            @SourceSystem = 'NTD_Safety_Events';

        EXEC dw_transport.sp_Load_Fact_Service_Availability
            @BatchID = @CurrentBatchID,
            @SourceSystem = 'NTD_Service_Schedule';

        EXEC dw_transport.sp_Load_Fact_Service_Lifecycle_Accumulating
            @BatchID = @CurrentBatchID,
            @SourceSystem = 'NTD_Lifecycle';

        PRINT 'All fact tables loaded successfully!';

    END TRY
    BEGIN CATCH
        PRINT CONCAT('ERROR in master ETL: ', ERROR_MESSAGE());
        THROW;
    END CATCH

END;
GO

-- ============================================================
-- EXECUTION EXAMPLES
-- ============================================================

/*

-- Load all facts with auto-generated batch ID
EXEC dw_transport.sp_Load_All_Facts;

-- Full reload (delete and reload current batch)
EXEC dw_transport.sp_Load_All_Facts @ReloadIfExists = 1;

-- Load with specific batch ID
EXEC dw_transport.sp_Load_All_Facts @BatchID = 20240101001;

-- Load individual fact tables for testing
EXEC dw_transport.sp_Load_Fact_Annual_Service_Performance @BatchID = 20240101001, @ReloadIfExists = 1;
EXEC dw_transport.sp_Load_Fact_Major_Safety_Event @BatchID = 20240101001;
EXEC dw_transport.sp_Load_Fact_Service_Availability @BatchID = 20240101001;
EXEC dw_transport.sp_Load_Fact_Service_Lifecycle_Accumulating @BatchID = 20240101001;

*/
