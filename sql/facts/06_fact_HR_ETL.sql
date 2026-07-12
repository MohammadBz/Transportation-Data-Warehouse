

-- ============================================================
-- FILE:     06_load_FactJobPosting_etl.sql
-- SCHEMA:   dw_HR
-- DATABASE: TransportationDB
-- AUTHOR:   Parnian Ghaisari
-- DESC:     ETL Pipeline Procedure for FactJobPosting (Fact 1)
--           Matches grain: One row per unique OpeningID transaction.
-- ============================================================

USE [TransportationDB];
GO

IF OBJECT_ID('dw_HR.sp_Load_FactJobPosting', 'P') IS NOT NULL
    DROP PROCEDURE dw_HR.sp_Load_FactJobPosting;
GO

CREATE PROCEDURE dw_HR.sp_Load_FactJobPosting
    @BatchID INT = NULL,
    @SourceSystem VARCHAR(50) = 'NTD_Job_Openings_Generator',
    @ReloadIfExists BIT = 1
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    DECLARE @RowsInserted INT = 0;
    DECLARE @RowsDeleted INT = 0;
    DECLARE @LoadStartTime DATETIME2 = SYSDATETIME();
    DECLARE @TransactionStarted BIT = 0;

    -- Initialize ETL audit log for tracking execution metrics
    INSERT INTO dw_transport.etl_load_audit (procedure_name, load_date, load_start_time, status)
    VALUES ('dw_HR.sp_Load_FactJobPosting', CAST(GETDATE() AS DATE), @LoadStartTime, 'IN_PROGRESS');
    DECLARE @AuditId INT = SCOPE_IDENTITY();

    BEGIN TRY
        -- Open a secure transaction block
        IF @@TRANCOUNT = 0
        BEGIN
            BEGIN TRANSACTION;
            SET @TransactionStarted = 1;
        END

        -- Enforce Idempotency: Clear previously loaded data for the same business keys if reload is requested
        IF @ReloadIfExists = 1
        BEGIN
            DELETE FROM dw_HR.FactJobPosting
            WHERE OpeningID IN (SELECT DISTINCT OpeningID FROM stg_HR.stg_job_openings);
            SET @RowsDeleted = @@ROWCOUNT;
        END

        -- Ingest transactional data via Surrogate Key lookups, defaulting missing values to -1
        INSERT INTO dw_HR.FactJobPosting (
            DateKey, AgencyKey, ModeKey, ServiceTypeKey, EmploymentTypeKey, DepartmentKey, JobRoleKey,
            OpeningID, OpenPositions, SalaryMinHourly, SalaryMaxHourly, SalaryMidHourly, DaysOpen, HiredCount,
            PostingStatus, VacancyReason, ETL_InsertDate, ETL_UpdateDate, ETL_BatchID, RecordSourceSystem
        )
        SELECT
            -- 1. Date Dimension Lookup (maps integer key format or assigns unknown default)
            ISNULL(d.DateKey, -1) AS DateKey,

            -- 2. Agency Dimension Lookup governed by SCD Type 2 temporal parameters
            ISNULL(a.AgencyKey, -1) AS AgencyKey,

            -- 3. Transit Mode Dimension Lookup
            ISNULL(m.ModeKey, -1) AS ModeKey,

            -- 4. Type of Service (TOS) Dimension Lookup
            ISNULL(s.ServiceTypeKey, -1) AS ServiceTypeKey,

            -- 5. Employment Type Dimension Lookup
            ISNULL(e.EmploymentTypeKey, -1) AS EmploymentTypeKey,

            -- 6. Organizational Department Dimension Lookup
            ISNULL(dept.DepartmentKey, -1) AS DepartmentKey,

            -- 7. Job Role Dimension Lookup governed by active SCD Type 2 intervals
            ISNULL(jr.JobRoleKey, -1) AS JobRoleKey,

            -- Transaction Business Keys and Numeric Metric Quantities (Measures)
            src.OpeningID,
            ISNULL(TRY_CAST(src.OpenPositions AS INT), 1) AS OpenPositions,
            TRY_CAST(src.SalaryMinHourly AS DECIMAL(18,2)) AS SalaryMinHourly,
            TRY_CAST(src.SalaryMaxHourly AS DECIMAL(18,2)) AS SalaryMaxHourly,
            TRY_CAST(src.SalaryMidHourly AS DECIMAL(18,2)) AS SalaryMidHourly,
            TRY_CAST(src.DaysOpen AS INT) AS DaysOpen,
            ISNULL(TRY_CAST(src.HiredCount AS INT), 0) AS HiredCount,
            src.PostingStatus,
            src.VacancyReason,

            -- Metadata and Data Warehouse Lineage Audit Attributes
            @LoadStartTime AS ETL_InsertDate,
            NULL AS ETL_UpdateDate,
            @BatchID AS ETL_BatchID,
            @SourceSystem AS RecordSourceSystem

        FROM stg_HR.stg_job_openings src

        -- Date Dimension Mapping
        LEFT JOIN dw_HR.DimDate d
            ON d.DateKey = src.PostingDateKey

        -- Agency Dimension Mapping with transactional date validation (SCD Type 2)
        LEFT JOIN dw_HR.DimAgency a
            ON src.NTD_ID = a.NTD_ID
            AND CAST(src.PostingDate AS DATE) >= a.EffectiveDate
            AND CAST(src.PostingDate AS DATE) <= a.ExpirationDate

        -- Public Transit Mode Mapping
        LEFT JOIN dw_HR.DimMode m
            ON UPPER(LTRIM(RTRIM(src.ModeCode))) = m.ModeCode

        -- Type of Service Code Mapping
        LEFT JOIN dw_HR.DimServiceType s
            ON UPPER(LTRIM(RTRIM(src.TOS))) = s.TOSCode

        -- Personnel Employment Status Mapping
        LEFT JOIN dw_HR.DimEmploymentType e
            ON e.EmploymentTypeName = LTRIM(RTRIM(src.EmploymentType))

        -- Structured Department Identification Mapping
        LEFT JOIN dw_HR.DimDepartment dept
            ON dept.DepartmentCode = UPPER(LEFT(LTRIM(RTRIM(src.Department)), 50))

        -- Job Title and Active Recruitment Position Mapping (SCD Type 2)
        LEFT JOIN dw_HR.DimJobRole jr
            ON jr.PositionTitle = LTRIM(RTRIM(src.PositionTitle))
            AND CAST(src.PostingDate AS DATE) >= jr.EffectiveDate
            AND CAST(src.PostingDate AS DATE) <= jr.ExpirationDate

        WHERE src.OpeningID IS NOT NULL AND LTRIM(RTRIM(src.OpeningID)) != '';

        SET @RowsInserted = @@ROWCOUNT;

        -- Finalize operational audit log entry with success metrics
        UPDATE dw_transport.etl_load_audit
        SET load_end_time = SYSDATETIME(),
            rows_processed = @RowsInserted,
            rows_inserted = @RowsInserted,
            rows_deleted = @RowsDeleted,
            status = 'SUCCESS'
        WHERE audit_id = @AuditId;

        IF @TransactionStarted = 1 AND @@TRANCOUNT > 0
            COMMIT TRANSACTION;

        PRINT CONCAT('FactJobPosting Loaded Successfully. Rows Inserted: ', @RowsInserted);
    END TRY
    BEGIN CATCH
        -- Invalidate and rollback transaction on runtime errors
        IF @TransactionStarted = 1 AND @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;

        -- Capture execution failure within audit schema
        UPDATE dw_transport.etl_load_audit
        SET load_end_time = SYSDATETIME(),
            status = 'FAILED',
            error_message = ERROR_MESSAGE()
        WHERE audit_id = @AuditId;

        RAISERROR('Critical Error in FactJobPosting Transactional Ingestion.', 16, 1);
    END CATCH
END;
GO

-- ============================================================
-- FILE:     07_load_FactEmployeeSnapshot_etl.sql
-- SCHEMA:   dw_HR
-- DATABASE: TransportationDB
-- AUTHOR:   Parnian Ghaisari
-- DESC:     ETL Pipeline Procedure for FactEmployeeSnapshot (Fact 2)
--           Type: Periodic Snapshot Fact Table
--           Grain: One row per Year x Agency x Labor Category x Employment Type x Mode x Service Type
-- ============================================================

USE [TransportationDB];
GO

IF OBJECT_ID('dw_HR.sp_Load_FactEmployeeSnapshot', 'P') IS NOT NULL
    DROP PROCEDURE dw_HR.sp_Load_FactEmployeeSnapshot;
GO

CREATE PROCEDURE dw_HR.sp_Load_FactEmployeeSnapshot
    @BatchID INT = NULL,
    @SourceSystem VARCHAR(50) = 'NTD_Agency_Employees_Staging',
    @ReloadIfExists BIT = 1
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    DECLARE @RowsInserted INT = 0;
    DECLARE @RowsDeleted INT = 0;
    DECLARE @LoadStartTime DATETIME2 = SYSDATETIME();
    DECLARE @TransactionStarted BIT = 0;

    -- 1. Initialize ETL Audit Log Entry for Periodic Tracking
    INSERT INTO dw_transport.etl_load_audit (procedure_name, load_date, load_start_time, status)
    VALUES ('dw_HR.sp_Load_FactEmployeeSnapshot', CAST(GETDATE() AS DATE), @LoadStartTime, 'IN_PROGRESS');
    DECLARE @AuditId INT = SCOPE_IDENTITY();

    BEGIN TRY
        -- Establish transactional context
        IF @@TRANCOUNT = 0
        BEGIN
            BEGIN TRANSACTION;
            SET @TransactionStarted = 1;
        END

        -- 2. Enforce Idempotency Principle (Clear existing snapshot data for years undergoing a reload)
        IF @ReloadIfExists = 1
        BEGIN
            DELETE FROM dw_HR.FactEmployeeSnapshot
            WHERE YearKey IN (SELECT DISTINCT ReportYear FROM stg_HR.stg_transit_employees);
            SET @RowsDeleted = @@ROWCOUNT;
        END

        -- 3. Provision volatile temporary storage structures to pivot wide staging attributes to tabular format
        -- Segregating staging employee dimensions across Hours Worked and Employee Count properties

        IF OBJECT_ID('tempdb..#EmpHoursUnpvt', 'U') IS NOT NULL DROP TABLE #EmpHoursUnpvt;
        IF OBJECT_ID('tempdb..#EmpCountUnpvt', 'U') IS NOT NULL DROP TABLE #EmpCountUnpvt;

        -- Unpivot operation mapping wide operational structures to structured Labor Metrics (Hours)
        SELECT
            ReportYear, NTD_ID, ModeCode, TOSCode,
            LaborCategory, EmploymentType, OperatorStatus,
            CAST(HoursValue AS DECIMAL(18,2)) AS HoursWorked
        INTO #EmpHoursUnpvt
        FROM (
            SELECT
                ReportYear, NTD_ID, Mode AS ModeCode, TOS AS TOSCode,
                -- Map explicit structural database columns from original Excel staging boundaries
                [Full_Time_Op_Hours] AS [FullTime_Vehicle Operations_Operator],
                [Full_Time_NonOp_Hours] AS [FullTime_Vehicle Operations_Non-Operator],
                [Full_Time_Maint_Hours] AS [FullTime_Vehicle Maintenance_Non-Operator],
                [Part_Time_Op_Hours] AS [PartTime_Vehicle Operations_Operator],
                [Part_Time_NonOp_Hours] AS [PartTime_Vehicle Operations_Non-Operator]
            FROM stg_HR.stg_transit_employees
        ) p
        UNPIVOT (
            HoursValue FOR HoursColumn IN (
                [FullTime_Vehicle Operations_Operator],
                [FullTime_Vehicle Operations_Non-Operator],
                [FullTime_Vehicle Maintenance_Non-Operator],
                [PartTime_Vehicle Operations_Operator],
                [PartTime_Vehicle Operations_Non-Operator]
            )
        ) AS unpvt
        -- Parse string variables to extract dimensional parameters
        CROSS APPLY (
            SELECT
                PARSENAME(REPLACE(HoursColumn, '_', '.'), 3) AS EmploymentType,
                PARSENAME(REPLACE(HoursColumn, '_', '.'), 2) AS LaborCategory,
                PARSENAME(REPLACE(HoursColumn, '_', '.'), 1) AS OperatorStatus
        ) M;

        -- Unpivot operation mapping wide headcount attributes to operational Headcounts (Counts)
        SELECT
            ReportYear, NTD_ID, ModeCode, TOSCode,
            LaborCategory, EmploymentType, OperatorStatus,
            CAST(CountValue AS INT) AS EmployeeCount
        INTO #EmpCountUnpvt
        FROM (
            SELECT
                ReportYear, NTD_ID, Mode AS ModeCode, TOS AS TOSCode,
                [Full_Time_Op_Count] AS [FullTime_Vehicle Operations_Operator],
                [Full_Time_NonOp_Count] AS [FullTime_Vehicle Operations_Non-Operator],
                [Full_Time_Maint_Count] AS [FullTime_Vehicle Maintenance_Non-Operator],
                [Part_Time_Op_Count] AS [PartTime_Vehicle Operations_Operator],
                [Part_Time_NonOp_Count] AS [PartTime_Vehicle Operations_Non-Operator]
            FROM stg_HR.stg_transit_employees
        ) p
        UNPIVOT (
            CountValue FOR CountColumn IN (
                [FullTime_Vehicle Operations_Operator],
                [FullTime_Vehicle Operations_Non-Operator],
                [FullTime_Vehicle Maintenance_Non-Operator],
                [PartTime_Vehicle Operations_Operator],
                [PartTime_Vehicle Operations_Non-Operator]
            )
        ) AS unpvt
        CROSS APPLY (
            SELECT
                PARSENAME(REPLACE(CountColumn, '_', '.'), 3) AS EmploymentType,
                PARSENAME(REPLACE(CountColumn, '_', '.'), 2) AS LaborCategory,
                PARSENAME(REPLACE(CountColumn, '_', '.'), 1) AS OperatorStatus
        ) M;

        -- 4. Construct Consolidated Composite Master Grain to bind structural columns seamlessly
        IF OBJECT_ID('tempdb..#SnapshotMasterGrain', 'U') IS NOT NULL DROP TABLE #SnapshotMasterGrain;

        SELECT DISTINCT ReportYear, NTD_ID, ModeCode, TOSCode, LaborCategory, EmploymentType, OperatorStatus
            INTO #SnapshotMasterGrain
        FROM #EmpHoursUnpvt
        UNION
        SELECT DISTINCT ReportYear, NTD_ID, ModeCode, TOSCode, LaborCategory, EmploymentType, OperatorStatus
        FROM #EmpCountUnpvt;

        -- 5. Ingest granular measures into target fact tables with dimensional connections
        INSERT INTO dw_HR.FactEmployeeSnapshot (
            YearKey, AgencyKey, ModeKey, ServiceTypeKey, DepartmentKey, EmploymentTypeKey,
            HoursWorked, EmployeeCount, FullTimeEquivalent,
            ETL_InsertDate, ETL_BatchID, RecordSourceSystem
        )
        SELECT
            -- Mapping Foreign Keys to Star Schema Dimensions
            src.ReportYear AS YearKey,
            ISNULL(a.AgencyKey, -1) AS AgencyKey,
            ISNULL(m.ModeKey, -1) AS ModeKey,
            ISNULL(s.ServiceTypeKey, -1) AS ServiceTypeKey,
            ISNULL(dept.DepartmentKey, -1) AS DepartmentKey,
            ISNULL(e.EmploymentTypeKey, -1) AS EmploymentTypeKey,

            -- Consolidate numeric properties extracted from localized temporary staging transformations
            ISNULL(h.HoursWorked, 0.00) AS HoursWorked,
            ISNULL(c.EmployeeCount, 0) AS EmployeeCount,

            -- Derivation metric: Compute Full-Time Equivalent (FTE) based on standard 2080 annual working hour baseline
            CAST(ISNULL(h.HoursWorked, 0.00) / 2080.0 AS DECIMAL(18,4)) AS FullTimeEquivalent,

            -- Pipeline Audit Lineage Metadata attributes
            @LoadStartTime AS ETL_InsertDate,
            @BatchID AS ETL_BatchID,
            @SourceSystem AS RecordSourceSystem

        FROM #SnapshotMasterGrain src

        -- Relational Left Joins against granular temporary staging subsets
        LEFT JOIN #EmpHoursUnpvt h
            ON src.ReportYear = h.ReportYear AND src.NTD_ID = h.NTD_ID
            AND src.ModeCode = h.ModeCode AND src.TOSCode = h.TOSCode
            AND src.LaborCategory = h.LaborCategory AND src.EmploymentType = h.EmploymentType
            AND src.OperatorStatus = h.OperatorStatus

        LEFT JOIN #EmpCountUnpvt c
            ON src.ReportYear = c.ReportYear AND src.NTD_ID = c.NTD_ID
            AND src.ModeCode = c.ModeCode AND src.TOSCode = c.TOSCode
            AND src.LaborCategory = c.LaborCategory AND src.EmploymentType = c.EmploymentType
            AND src.OperatorStatus = c.OperatorStatus

        -- Evaluate Natural Keys to establish Dimension Surrogate Relationships
        LEFT JOIN dw_HR.DimAgency a
            ON src.NTD_ID = a.NTD_ID
            AND a.IsCurrent = 1 -- Enforces lookup validation using the latest active version (SCD)

        LEFT JOIN dw_HR.DimMode m
            ON UPPER(LTRIM(RTRIM(src.ModeCode))) = m.ModeCode

        LEFT JOIN dw_HR.DimServiceType s
            ON UPPER(LTRIM(RTRIM(src.TOSCode))) = s.TOSCode

        LEFT JOIN dw_HR.DimEmploymentType e
            ON e.EmploymentTypeName = LTRIM(RTRIM(src.EmploymentType))

        LEFT JOIN dw_HR.DimDepartment dept
            ON dept.DepartmentName = LTRIM(RTRIM(src.LaborCategory));

        SET @RowsInserted = @@ROWCOUNT;

        -- Record pipeline success transaction status within centralized auditing layout
        UPDATE dw_transport.etl_load_audit
        SET load_end_time = SYSDATETIME(),
            rows_processed = @RowsInserted,
            rows_inserted = @RowsInserted,
            rows_deleted = @RowsDeleted,
            status = 'SUCCESS'
        WHERE audit_id = @AuditId;

        IF @TransactionStarted = 1 AND @@TRANCOUNT > 0
            COMMIT TRANSACTION;

        PRINT CONCAT('FactEmployeeSnapshot Periodic Loaded Successfully. Rows Inserted: ', @RowsInserted);
    END TRY
    BEGIN CATCH
        -- Restructure environment status through explicit data rollbacks on exception handling
        IF @TransactionStarted = 1 AND @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;

        -- Document explicit runtime exception properties to database error audit layout
        UPDATE dw_transport.etl_load_audit
        SET load_end_time = SYSDATETIME(),
            status = 'FAILED',
            error_message = ERROR_MESSAGE()
        WHERE audit_id = @AuditId;

        RAISERROR('Critical Error in FactEmployeeSnapshot Periodic Ingestion.', 16, 1);
    END CATCH
END;
GO

USE [TransportationDB];
GO

IF OBJECT_ID('dw_HR.sp_Load_FactAgencyLaborCoverage', 'P') IS NOT NULL
    DROP PROCEDURE dw_HR.sp_Load_FactAgencyLaborCoverage;
GO

CREATE PROCEDURE dw_HR.sp_Load_FactAgencyLaborCoverage
    @BatchID INT = NULL,
    @SourceSystem VARCHAR(50) = 'NTD_Agency_Employees_Staging',
    @ReloadIfExists BIT = 1
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    DECLARE @RowsInserted INT = 0;
    DECLARE @RowsDeleted INT = 0;
    DECLARE @LoadStartTime DATETIME = GETDATE();
    DECLARE @TransactionStarted BIT = 0;

    -- 1. Initialize ETL Audit Log Entry
    INSERT INTO dw_transport.etl_load_audit (procedure_name, load_date, load_start_time, status)
    VALUES ('dw_HR.sp_Load_FactAgencyLaborCoverage', CAST(GETDATE() AS DATE), @LoadStartTime, 'IN_PROGRESS');
    DECLARE @AuditId INT = SCOPE_IDENTITY();

    BEGIN TRY
        -- Open Transaction Context
        IF @@TRANCOUNT = 0
        BEGIN
            BEGIN TRANSACTION;
            SET @TransactionStarted = 1;
        END

        -- 2. Enforce Idempotency Principle (Clear existing coverage records for years being reloaded)
        IF @ReloadIfExists = 1
        BEGIN
            DELETE FROM dw_HR.FactAgencyLaborCoverage
            WHERE DateKey IN (
                SELECT DISTINCT d.DateKey
                FROM stg_HR.stg_transit_employees src
                JOIN dw_HR.DimDate d ON d.CalendarYear = src.ReportYear AND d.IsYearLevel = 1
            );
            SET @RowsDeleted = @@ROWCOUNT;
        END

        -- 3. Extract and Unpivot Distinct Operational Combinations from Staging Layer
        IF OBJECT_ID('tempdb..#StgDistinctCoverage', 'U') IS NOT NULL DROP TABLE #StgDistinctCoverage;

        SELECT DISTINCT
            ReportYear, NTD_ID, ModeCode, TOSCode, LaborCategory, EmploymentType
        INTO #StgDistinctCoverage
        FROM (
            SELECT
                ReportYear, NTD_ID, Mode AS ModeCode, TOS AS TOSCode,
                -- Verify explicit labor metrics to ensure a valid operational coverage link exists
                CASE WHEN ISNULL([Full_Time_Op_Hours], 0) > 0 OR ISNULL([Full_Time_Op_Count], 0) > 0 THEN 'Vehicle Operations_Full Time' ELSE NULL END AS V_Op_FT,
                CASE WHEN ISNULL([Full_Time_NonOp_Hours], 0) > 0 OR ISNULL([Full_Time_NonOp_Count], 0) > 0 THEN 'Vehicle Operations_Full Time' ELSE NULL END AS V_NonOp_FT,
                CASE WHEN ISNULL([Full_Time_Maint_Hours], 0) > 0 OR ISNULL([Full_Time_Maint_Count], 0) > 0 THEN 'Vehicle Maintenance_Full Time' ELSE NULL END AS V_Maint_FT,
                CASE WHEN ISNULL([Part_Time_Op_Hours], 0) > 0 OR ISNULL([Part_Time_Op_Count], 0) > 0 THEN 'Vehicle Operations_Part Time' ELSE NULL END AS V_Op_PT,
                CASE WHEN ISNULL([Part_Time_NonOp_Hours], 0) > 0 OR ISNULL([Part_Time_NonOp_Count], 0) > 0 THEN 'Vehicle Operations_Part Time' ELSE NULL END AS V_NonOp_PT
            FROM stg_HR.stg_transit_employees
        ) p
        UNPIVOT (
            CoverageString FOR CoverageColumn IN (V_Op_FT, V_NonOp_FT, V_Maint_FT, V_Op_PT, V_NonOp_PT)
        ) AS unpvt
        CROSS APPLY (
            SELECT
                PARSENAME(REPLACE(CoverageString, '_', '.'), 2) AS LaborCategory,
                PARSENAME(REPLACE(CoverageString, '_', '.'), 1) AS EmploymentType
        ) M
        WHERE CoverageString IS NOT NULL;

        -- 4. Ingest Distinct Dimensions into Factless Destination via Surrogate Key Lookups
        INSERT INTO dw_HR.FactAgencyLaborCoverage (
            DateKey, AgencyKey, DepartmentKey, ModeKey, ServiceTypeKey, EmploymentTypeKey,
            ETL_InsertDate, ETL_BatchID, RecordSourceSystem
        )
        SELECT
            -- Map to Date Dimension using Year-Level granularity
            ISNULL(d.DateKey, -1) AS DateKey,

            -- Resolve Dimension Foreign Keys with Default -1 for missing relations
            ISNULL(a.AgencyKey, -1) AS AgencyKey,
            ISNULL(dept.DepartmentKey, -1) AS DepartmentKey,
            ISNULL(m.ModeKey, -1) AS ModeKey,
            ISNULL(s.ServiceTypeKey, -1) AS ServiceTypeKey,
            ISNULL(e.EmploymentTypeKey, -1) AS EmploymentTypeKey,

            -- System Audit Metadata
            @LoadStartTime AS ETL_InsertDate,
            @BatchID AS ETL_BatchID,
            @SourceSystem AS RecordSourceSystem

        FROM #StgDistinctCoverage src

        -- Date Lookup based on matching Calendar Year
        LEFT JOIN dw_HR.DimDate d
            ON d.CalendarYear = src.ReportYear
            AND d.IsYearLevel = 1

        -- Agency Lookup based on Natural Business Keys
        LEFT JOIN dw_HR.DimAgency a
            ON src.NTD_ID = a.NTD_ID
            AND a.IsCurrent = 1

        -- Transit Mode Lookup
        LEFT JOIN dw_HR.DimMode m
            ON UPPER(LTRIM(RTRIM(src.ModeCode))) = m.ModeCode

        -- Type of Service (TOS) Lookup
        LEFT JOIN dw_HR.DimServiceType s
            ON UPPER(LTRIM(RTRIM(src.TOSCode))) = s.TOSCode

        -- Employment Type Lookup
        LEFT JOIN dw_HR.DimEmploymentType e
            ON e.EmploymentTypeName = LTRIM(RTRIM(src.EmploymentType))

        -- Department Grouping Lookup
        LEFT JOIN dw_HR.DimDepartment dept
            ON dept.DepartmentName = LTRIM(RTRIM(src.LaborCategory));

        SET @RowsInserted = @@ROWCOUNT;

        -- 5. Finalize Audit Record Log Status to Success
        UPDATE dw_transport.etl_load_audit
        SET load_end_time = SYSDATETIME(),
            rows_processed = @RowsInserted,
            rows_inserted = @RowsInserted,
            rows_deleted = @RowsDeleted,
            status = 'SUCCESS'
        WHERE audit_id = @AuditId;

        IF @TransactionStarted = 1 AND @@TRANCOUNT > 0
            COMMIT TRANSACTION;

        PRINT CONCAT('FactAgencyLaborCoverage (Factless) Loaded. Rows Inserted: ', @RowsInserted);
    END TRY
    BEGIN CATCH
        -- Rollback context in case of runtime exceptions
        IF @TransactionStarted = 1 AND @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;

        -- Log failure to operational metrics table
        UPDATE dw_transport.etl_load_audit
        SET load_end_time = SYSDATETIME(),
            status = 'FAILED',
            error_message = ERROR_MESSAGE()
        WHERE audit_id = @AuditId;

        RAISERROR('Critical Error in FactAgencyLaborCoverage ETL Pipeline.', 16, 1);
    END CATCH
END;
GO


-- ============================================================
-- FILE:     09_load_FactJobPostingLifecycle_etl.sql
-- SCHEMA:   dw_HR
-- DATABASE: TransportationDB
-- AUTHOR:   Parnian Ghaisari
-- DESC:     ETL Pipeline Procedure for FactJobPostingLifecycle (Fact 4)
--           Type: Accumulating Snapshot Fact Table
--           Grain: One row per unique OpeningID lifecycle instance.
-- ============================================================

USE [TransportationDB];
GO

IF OBJECT_ID('dw_HR.sp_Load_FactJobPostingLifecycle', 'P') IS NOT NULL
    DROP PROCEDURE dw_HR.sp_Load_FactJobPostingLifecycle;
GO

CREATE PROCEDURE dw_HR.sp_Load_FactJobPostingLifecycle
    @BatchID INT = NULL,
    @SourceSystem VARCHAR(50) = 'NTD_Job_Openings_Lifecycle',
    @ReloadIfExists BIT = 1
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    DECLARE @RowsInserted INT = 0;
    DECLARE @RowsDeleted INT = 0;
    DECLARE @LoadStartTime DATETIME2 = SYSDATETIME();
    DECLARE @TransactionStarted BIT = 0;

    -- 1. Initialize ETL Audit Log Entry for Monitoring
    INSERT INTO dw_transport.etl_load_audit (procedure_name, load_date, load_start_time, status)
    VALUES ('dw_HR.sp_Load_FactJobPostingLifecycle', CAST(GETDATE() AS DATE), @LoadStartTime, 'IN_PROGRESS');
    DECLARE @AuditId INT = SCOPE_IDENTITY();

    BEGIN TRY
        -- Establish transactional scope
        IF @@TRANCOUNT = 0
        BEGIN
            BEGIN TRANSACTION;
            SET @TransactionStarted = 1;
        END

        -- 2. Enforce Idempotency Principle (Clear existing lifecycle facts if reload is triggered)
        IF @ReloadIfExists = 1
        BEGIN
            DELETE FROM dw_HR.FactJobPostingLifecycle
            WHERE OpeningID IN (SELECT DISTINCT OpeningID FROM stg_HR.stg_job_openings);
            SET @RowsDeleted = @@ROWCOUNT;
        END

        -- 3. Ingest Accumulating Snapshot Milestones and Measures via Dimension Lookups
        INSERT INTO dw_HR.FactJobPostingLifecycle (
            AgencyKey, ModeKey, ServiceTypeKey, EmploymentTypeKey, DepartmentKey, JobRoleKey,
            OpeningID, PostingDateKey, FilledDateKey, ClosingDateKey, DaysOpen, HiredCount, PostingStatus,
            ETL_InsertDate, ETL_UpdateDate, ETL_BatchID, RecordSourceSystem
        )
        SELECT
            -- Resolve Dimension Foreign Keys with Default -1 for Missing Relations
            ISNULL(a.AgencyKey, -1) AS AgencyKey,
            ISNULL(m.ModeKey, -1) AS ModeKey,
            ISNULL(s.ServiceTypeKey, -1) AS ServiceTypeKey,
            ISNULL(e.EmploymentTypeKey, -1) AS EmploymentTypeKey,
            ISNULL(dept.DepartmentKey, -1) AS DepartmentKey,
            ISNULL(jr.JobRoleKey, -1) AS JobRoleKey,

            -- Natural Business Key
            src.OpeningID,

            -- Multiple Milestone Date Keys (Accumulating Snapshot Pattern)
            ISNULL(d_post.DateKey, -1) AS PostingDateKey,
            d_fill.DateKey AS FilledDateKey,     -- Keeps NULL if job opening is not filled yet
            ISNULL(d_close.DateKey, -1) AS ClosingDateKey,

            -- Numeric Metric Quantities and Status Attributes
            TRY_CAST(src.DaysOpen AS INT) AS DaysOpen,
            ISNULL(TRY_CAST(src.HiredCount AS INT), 0) AS HiredCount,
            src.PostingStatus,

            -- DW Lineage and Auditing Metadata fields
            @LoadStartTime AS ETL_InsertDate,
            NULL AS ETL_UpdateDate,
            @BatchID AS ETL_BatchID,
            @SourceSystem AS RecordSourceSystem

        FROM stg_HR.stg_job_openings src

        -- Multiple Date Lookups for distinct lifecycle milestones (Role-Playing Dimensions)
        LEFT JOIN dw_HR.DimDate d_post
            ON d_post.DateKey = src.PostingDateKey

        LEFT JOIN dw_HR.DimDate d_fill
            ON d_fill.DateKey = TRY_CAST(CONVERT(VARCHAR(8), CAST(src.FilledDate AS DATE), 112) AS INT)

        LEFT JOIN dw_HR.DimDate d_close
            ON d_close.DateKey = TRY_CAST(CONVERT(VARCHAR(8), CAST(src.ClosingDate AS DATE), 112) AS INT)

        -- Agency Dimension Mapping governed by SCD Type 2 active intervals
        LEFT JOIN dw_HR.DimAgency a
            ON src.NTD_ID = a.NTD_ID
            AND CAST(src.PostingDate AS DATE) >= a.EffectiveDate
            AND CAST(src.PostingDate AS DATE) <= a.ExpirationDate

        -- Public Transit Mode Dimension Mapping
        LEFT JOIN dw_HR.DimMode m
            ON UPPER(LTRIM(RTRIM(src.ModeCode))) = m.ModeCode

        -- Type of Service (TOS) Dimension Mapping
        LEFT JOIN dw_HR.DimServiceType s
            ON UPPER(LTRIM(RTRIM(src.TOS))) = s.TOSCode

        -- Personnel Employment Status Mapping
        LEFT JOIN dw_HR.DimEmploymentType e
            ON e.EmploymentTypeName = LTRIM(RTRIM(src.EmploymentType))

        -- Department Configuration Mapping
        LEFT JOIN dw_HR.DimDepartment dept
            ON dept.DepartmentCode = UPPER(LEFT(LTRIM(RTRIM(src.Department)), 50))

        -- Job Role Identification Mapping with active SCD Type 2 check
        LEFT JOIN dw_HR.DimJobRole jr
            ON jr.PositionTitle = LTRIM(RTRIM(src.PositionTitle))
            AND CAST(src.PostingDate AS DATE) >= jr.EffectiveDate
            AND CAST(src.PostingDate AS DATE) <= jr.ExpirationDate

        WHERE src.OpeningID IS NOT NULL AND LTRIM(RTRIM(src.OpeningID)) != '';

        SET @RowsInserted = @@ROWCOUNT;

        -- 4. Finalize Audit Entry Metrics to Success Status
        UPDATE dw_transport.etl_load_audit
        SET load_end_time = SYSDATETIME(),
            rows_processed = @RowsInserted,
            rows_inserted = @RowsInserted,
            rows_deleted = @RowsDeleted,
            status = 'SUCCESS'
        WHERE audit_id = @AuditId;

        IF @TransactionStarted = 1 AND @@TRANCOUNT > 0
            COMMIT TRANSACTION;

        PRINT CONCAT('FactJobPostingLifecycle Loaded Successfully. Rows Inserted: ', @RowsInserted);
    END TRY
    BEGIN CATCH
        -- Invalidate and rollback data context modifications on failures
        IF @TransactionStarted = 1 AND @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;

        -- Capture runtime exception details within audit framework
        UPDATE dw_transport.etl_load_audit
        SET load_end_time = SYSDATETIME(),
            status = 'FAILED',
            error_message = ERROR_MESSAGE()
        WHERE audit_id = @AuditId;

        RAISERROR('Critical Error in FactJobPostingLifecycle Accumulating Ingestion Pipeline.', 16, 1);
    END CATCH
END;
GO
