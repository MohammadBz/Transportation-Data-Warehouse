-- ============================================================
-- FILE:     06_fact_HR_ETL.sql
-- SCHEMA:   dw_HR
-- DESC:     ETL Pipeline Procedures for HR Data Mart
--           Grain: FactJobPosting (1 row per OpeningID)
--                  FactEmployeeSnapshot (periodic snapshot)
--                  FactAgencyLaborCoverage (factless fact)
--                  FactJobPostingLifecycle (accumulating snapshot)
--           Kimball Principle: Fact ETL performs LOOKUPS ONLY.
--           All cleansing happens in staging.
-- ============================================================

USE [TransportationDB];
GO

-- ============================================================
-- sp_Load_FactJobPosting
-- Grain: One row per OpeningID
-- Type: Transaction Fact (one row = one job posting)
-- ============================================================

IF OBJECT_ID('dw_HR.sp_Load_FactJobPosting', 'P') IS NOT NULL
    DROP PROCEDURE dw_HR.sp_Load_FactJobPosting;
GO

CREATE PROCEDURE dw_HR.sp_Load_FactJobPosting
    @BatchID INT = NULL,
    @SourceSystem VARCHAR(50) = 'NTD_Job_Openings'
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    DECLARE @RowsProcessed INT = 0;
    DECLARE @RowsInserted INT = 0;
    DECLARE @LoadStartTime DATETIME2 = SYSDATETIME();
    DECLARE @AuditId INT;

    BEGIN TRY
        WITH RankedPostings AS (
            SELECT
                sp.opening_id,
                sp.posting_date_key,
                sp.ntd_id,
                sp.posting_date,
                sp.mode_code,
                sp.tos,
                sp.employment_type,
                sp.ntd_labor_object_class,
                sp.position_title,
                sp.open_positions,
                sp.salary_min_hourly,
                sp.salary_max_hourly,
                sp.salary_mid_hourly,
                sp.days_open,
                sp.hired_count,
                sp.posting_status,
                sp.vacancy_reason,
                ROW_NUMBER() OVER (
                    PARTITION BY sp.opening_id
                    ORDER BY sp.posting_date DESC, sp.posting_date_key DESC
                ) AS rn
            FROM stg_HR.stg_job_openings sp
        ),
        DedupedPostings AS (
            SELECT
                opening_id,
                posting_date_key,
                ntd_id,
                posting_date,
                mode_code,
                tos,
                employment_type,
                ntd_labor_object_class,
                position_title,
                open_positions,
                salary_min_hourly,
                salary_max_hourly,
                salary_mid_hourly,
                days_open,
                hired_count,
                posting_status,
                vacancy_reason
            FROM RankedPostings
            WHERE rn = 1
        )
        SELECT @RowsProcessed = COUNT(*) FROM DedupedPostings;

        INSERT INTO dw_transport.etl_load_audit (procedure_name, load_date, load_start_time, status)
        VALUES ('dw_HR.sp_Load_FactJobPosting', CAST(GETDATE() AS DATE), @LoadStartTime, 'IN_PROGRESS');
        SET @AuditId = SCOPE_IDENTITY();

        BEGIN TRANSACTION;

        INSERT INTO dw_HR.FactJobPosting (
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
            VacancyReason,
            ETL_InsertDate,
            ETL_UpdateDate,
            ETL_BatchID,
            RecordSourceSystem
        )
        SELECT
            ISNULL(d.DateKey, -1) AS DateKey,
            ISNULL(a.AgencyKey, -1) AS AgencyKey,
            ISNULL(m.ModeKey, -1) AS ModeKey,
            ISNULL(s.ServiceTypeKey, -1) AS ServiceTypeKey,
            ISNULL(e.EmploymentTypeKey, -1) AS EmploymentTypeKey,
            ISNULL(dept.DepartmentKey, -1) AS DepartmentKey,
            ISNULL(jr.JobRoleKey, -1) AS JobRoleKey,
            dp.opening_id,
            dp.open_positions,
            dp.salary_min_hourly,
            dp.salary_max_hourly,
            dp.salary_mid_hourly,
            dp.days_open,
            dp.hired_count,
            dp.posting_status,
            dp.vacancy_reason,
            @LoadStartTime AS ETL_InsertDate,
            NULL AS ETL_UpdateDate,
            @BatchID AS ETL_BatchID,
            @SourceSystem AS RecordSourceSystem
        FROM DedupedPostings dp
        LEFT JOIN dw_HR.DimDate d
            ON d.DateKey = dp.posting_date_key
        LEFT JOIN dw_HR.DimAgency a
            ON a.NTD_ID = dp.ntd_id
            AND dp.posting_date >= a.EffectiveDate
            AND dp.posting_date <= a.ExpirationDate
        LEFT JOIN dw_HR.DimMode m
            ON m.ModeCode = dp.mode_code
        LEFT JOIN dw_HR.DimServiceType s
            ON s.TOSCode = dp.tos
        LEFT JOIN dw_HR.DimEmploymentType e
            ON e.EmploymentTypeName = dp.employment_type
        LEFT JOIN dw_HR.DimDepartment dept
            ON dept.DepartmentName = dp.ntd_labor_object_class
        LEFT JOIN dw_HR.DimJobRole jr
            ON jr.PositionTitle = dp.position_title
            AND dp.posting_date >= jr.EffectiveDate
            AND dp.posting_date <= jr.ExpirationDate
        WHERE NOT EXISTS (
            SELECT 1
            FROM dw_HR.FactJobPosting f
            WHERE f.OpeningID = dp.opening_id
        );

        SET @RowsInserted = @@ROWCOUNT;

        UPDATE dw_transport.etl_load_audit
        SET
            load_end_time = SYSDATETIME(),
            rows_processed = @RowsProcessed,
            rows_inserted = @RowsInserted,
            status = 'SUCCESS'
        WHERE audit_id = @AuditId;

        COMMIT TRANSACTION;

    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;

        UPDATE dw_transport.etl_load_audit
        SET
            load_end_time = SYSDATETIME(),
            status = 'FAILED',
            error_message = ERROR_MESSAGE()
        WHERE audit_id = @AuditId;

        THROW;
    END CATCH
END;
GO
-- FILE:     07_load_FactEmployeeSnapshot_etl.sql
-- SCHEMA:   dw_HR
-- DESC:     ETL Pipeline Procedure for FactEmployeeSnapshot (Fact 2)
--           Type: Periodic Snapshot Fact Table
--           Grain: Year × Agency × Mode × ServiceType × EmploymentType × Department
--
-- DESIGN PRINCIPLES:
--   ✓ Fact ETL performs LOOKUPS only (no cleansing)
--   ✓ All business rules enforced in staging layer
--   ✓ Incremental loading using NOT EXISTS (no DELETE/INSERT)
--   ✓ Dimension surrogates with -1 for unknown members
--   ✓ Department-level grain: each row = ONE department
--   ✓ Production-grade error handling and audit logging
--   ✓ Explicit transaction management
--
-- EXECUTION: Execute after all dimensions are loaded
-- ============================================================

USE [TransportationDB];
GO

IF OBJECT_ID('dw_HR.sp_Load_FactEmployeeSnapshot', 'P') IS NOT NULL
    DROP PROCEDURE dw_HR.sp_Load_FactEmployeeSnapshot;
GO

CREATE PROCEDURE dw_HR.sp_Load_FactEmployeeSnapshot
    @BatchID INT = NULL,
    @SourceSystem VARCHAR(50) = 'NTD_Employee_Data'
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    DECLARE @LoadStartTime DATETIME2 = SYSDATETIME();
    DECLARE @AuditID INT;
    DECLARE @RowsInserted INT = 0;
    DECLARE @RowsProcessed INT = 0;
    DECLARE @ErrorMessage NVARCHAR(MAX);
    DECLARE @ErrorSeverity INT;
    DECLARE @ErrorState INT;

    BEGIN TRY
        BEGIN TRANSACTION;

        -- ============================================================
        -- PHASE 1: AUDIT LOG INITIALIZATION
        -- ============================================================
        INSERT INTO dw_transport.etl_load_audit
        (
            procedure_name,
            load_date,
            load_start_time,
            status
        )
        VALUES
        (
            'dw_HR.sp_Load_FactEmployeeSnapshot',
            CAST(GETDATE() AS DATE),
            @LoadStartTime,
            'IN_PROGRESS'
        );

        SET @AuditID = SCOPE_IDENTITY();

        -- ============================================================
        -- PHASE 2: DATA STAGING & DIMENSION LOOKUPS
        -- ============================================================
        -- Build consolidated fact records with dimension surrogates
        -- All dimension lookups with -1 for unknown members
        -- Calculate derived measures and apply grain logic
        -- Count actual rows going through NOT EXISTS before insert

        ;WITH FactPayload AS (
            SELECT
                ISNULL(dd.DateKey, -1) AS DateKey,
                ISNULL(da.AgencyKey, -1) AS AgencyKey,
                ISNULL(dm.ModeKey, -1) AS ModeKey,
                ISNULL(dst.ServiceTypeKey, -1) AS ServiceTypeKey,
                ISNULL(det.EmploymentTypeKey, -1) AS EmploymentTypeKey,
                ISNULL(ddpt.DepartmentKey, -1) AS DepartmentKey,
                stg.HoursWorked,
                stg.EmployeeCount,
                stg.OperatingHours,
                stg.CapitalHours,
                stg.TotalHours,
                stg.OperatingEmployees,
                stg.CapitalEmployees,
                stg.TotalEmployees,
                CASE
                    WHEN stg.EmployeeCount > 0
                    THEN CAST(stg.HoursWorked AS DECIMAL(18,4)) /
                         CAST(stg.EmployeeCount AS DECIMAL(18,4))
                    ELSE NULL
                END AS HoursPerEmployee,
                @SourceSystem AS SourceSystem,
                @LoadStartTime AS CreatedDate
            FROM stg_HR.stg_transit_employee_unified stg
            LEFT JOIN dw_HR.DimDate dd
                ON dd.CalendarYear = stg.ReportYear
                AND dd.IsYearLevel = 1
            LEFT JOIN dw_HR.DimAgency da
                ON da.NTD_ID = stg.NTD_ID
                AND dd.FullDate >= da.EffectiveDate
                AND dd.FullDate <= da.ExpirationDate
            LEFT JOIN dw_HR.DimMode dm
                ON dm.ModeCode = stg.ModeCode
            LEFT JOIN dw_HR.DimServiceType dst
                ON dst.TOSCode = stg.TOSCode
            LEFT JOIN dw_HR.DimEmploymentType det
                ON det.EmploymentTypeName =
                   CASE
                       WHEN stg.EmploymentType = 'FullTime' THEN 'Full-Time'
                       WHEN stg.EmploymentType = 'PartTime' THEN 'Part-Time'
                       ELSE 'Unknown Employment Type'
                   END
            LEFT JOIN dw_HR.DimDepartment ddpt
                ON ddpt.DepartmentName = stg.DepartmentName
        ),
        FilteredFacts AS (
            SELECT *
            FROM FactPayload fp
            WHERE NOT EXISTS
            (
                SELECT 1
                FROM dw_HR.FactEmployeeSnapshot fes
                WHERE fes.DateKey = fp.DateKey
                AND fes.AgencyKey = fp.AgencyKey
                AND fes.ModeKey = fp.ModeKey
                AND fes.ServiceTypeKey = fp.ServiceTypeKey
                AND fes.EmploymentTypeKey = fp.EmploymentTypeKey
                AND fes.DepartmentKey = fp.DepartmentKey
            )
        )
        INSERT INTO dw_HR.FactEmployeeSnapshot
        (
            DateKey,
            AgencyKey,
            ModeKey,
            ServiceTypeKey,
            EmploymentTypeKey,
            DepartmentKey,
            HoursWorked,
            EmployeeCount,
            OperatingHours,
            CapitalHours,
            TotalHours,
            OperatingEmployees,
            CapitalEmployees,
            TotalEmployees,
            HoursPerEmployee,
            ETL_InsertDate,
            ETL_BatchID,
            RecordSourceSystem
        )
        SELECT
            ff.DateKey,
            ff.AgencyKey,
            ff.ModeKey,
            ff.ServiceTypeKey,
            ff.EmploymentTypeKey,
            ff.DepartmentKey,
            ff.HoursWorked,
            ff.EmployeeCount,
            ff.OperatingHours,
            ff.CapitalHours,
            ff.TotalHours,
            ff.OperatingEmployees,
            ff.CapitalEmployees,
            ff.TotalEmployees,
            ff.HoursPerEmployee,
            ff.CreatedDate,
            @BatchID,
            @SourceSystem
        FROM FilteredFacts ff;

        SET @RowsInserted = @@ROWCOUNT;
        SET @RowsProcessed = @@ROWCOUNT;

        -- ============================================================
        -- PHASE 3: AUDIT & COMMIT
        -- ============================================================
        UPDATE dw_transport.etl_load_audit
        SET
            load_end_time = SYSDATETIME(),
            rows_processed = @RowsProcessed,
            rows_inserted = @RowsInserted,
            status = 'SUCCESS'
        WHERE audit_id = @AuditID;

        COMMIT TRANSACTION;

        PRINT CONCAT
        (
            'FactEmployeeSnapshot: Load completed. Rows processed: ',
            @RowsProcessed,
            ', Rows inserted: ',
            @RowsInserted
        );

    END TRY
    BEGIN CATCH
        -- ============================================================
        -- ERROR HANDLING
        -- ============================================================
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;

        SET @ErrorMessage = ERROR_MESSAGE();
        SET @ErrorSeverity = ERROR_SEVERITY();
        SET @ErrorState = ERROR_STATE();

        UPDATE dw_transport.etl_load_audit
        SET
            load_end_time = SYSDATETIME(),
            status = 'FAILED',
            error_message = @ErrorMessage
        WHERE audit_id = @AuditID;

        THROW @ErrorSeverity, @ErrorMessage, @ErrorState;

    END CATCH;

END;
GO

-- ============================================================
-- FILE:     08_load_FactAgencyLaborCoverage_etl.sql
-- SCHEMA:   dw_HR
-- DESC:     ETL Pipeline Procedure for FactAgencyLaborCoverage (Fact 3)
--           Type: Factless Fact Table (Operational Coverage Mapping)
--           Grain: DateKey × AgencyKey × DepartmentKey × ModeKey ×
--                  ServiceTypeKey × EmploymentTypeKey
--
-- DESIGN PRINCIPLES:
--   ✓ Fact ETL performs LOOKUPS only (no cleansing)
--   ✓ All business rules enforced in staging layer
--   ✓ Uses unified staging table (2014-2023 already consolidated)
--   ✓ Dimension surrogates with -1 for unknown members
--   ✓ No TRIM/UPPER (staging data already clean)
--   ✓ Correct SCD Type 2 lookup using effective/expiration dates
--   ✓ Production-grade error handling and audit logging
--   ✓ Efficient single-pass distinct aggregation
--
-- EXECUTION: Execute after all dimensions are loaded
-- ============================================================

USE [TransportationDB];
GO

IF OBJECT_ID('dw_HR.sp_Load_FactAgencyLaborCoverage', 'P') IS NOT NULL
    DROP PROCEDURE dw_HR.sp_Load_FactAgencyLaborCoverage;
GO

CREATE PROCEDURE dw_HR.sp_Load_FactAgencyLaborCoverage
    @BatchID INT = NULL,
    @SourceSystem VARCHAR(50) = 'NTD_Employee_Data'
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    DECLARE @LoadStartTime DATETIME2 = SYSDATETIME();
    DECLARE @AuditID INT;
    DECLARE @RowsInserted INT = 0;
    DECLARE @RowsProcessed INT = 0;
    DECLARE @ErrorMessage NVARCHAR(MAX);

    BEGIN TRY
        BEGIN TRANSACTION;

        -- ============================================================
        -- PHASE 1: AUDIT LOG INITIALIZATION
        -- ============================================================
        INSERT INTO dw_transport.etl_load_audit
        (
            procedure_name,
            load_date,
            load_start_time,
            status
        )
        VALUES
        (
            'dw_HR.sp_Load_FactAgencyLaborCoverage',
            CAST(GETDATE() AS DATE),
            @LoadStartTime,
            'IN_PROGRESS'
        );

        SET @AuditID = SCOPE_IDENTITY();

        -- ============================================================
        -- PHASE 2: DATA STAGING & DIMENSION LOOKUPS
        -- ============================================================
        -- Extract distinct grain combinations where hours > 0
        -- (indicating workforce coverage for that dimension intersection)

        ;WITH CoverageGrain AS (
            SELECT DISTINCT
                stg.ReportYear,
                stg.NTD_ID,
                stg.ModeCode,
                stg.TOSCode,
                stg.DepartmentName,
                stg.EmploymentType
            FROM stg_HR.stg_transit_employee_unified stg
            WHERE stg.HoursWorked > 0
        ),
        ResolvedCoverage AS (
            SELECT
                ISNULL(dd.DateKey, -1) AS DateKey,
                ISNULL(da.AgencyKey, -1) AS AgencyKey,
                ISNULL(ddpt.DepartmentKey, -1) AS DepartmentKey,
                ISNULL(dm.ModeKey, -1) AS ModeKey,
                ISNULL(dst.ServiceTypeKey, -1) AS ServiceTypeKey,
                ISNULL(det.EmploymentTypeKey, -1) AS EmploymentTypeKey,
                @LoadStartTime AS ETL_InsertDate,
                @BatchID AS ETL_BatchID,
                @SourceSystem AS RecordSourceSystem
            FROM CoverageGrain cg
            LEFT JOIN dw_HR.DimDate dd
                ON dd.CalendarYear = cg.ReportYear
                AND dd.IsYearLevel = 1
            LEFT JOIN dw_HR.DimAgency da
                ON da.NTD_ID = cg.NTD_ID
                AND dd.FullDate >= da.EffectiveDate
                AND dd.FullDate <= da.ExpirationDate
            LEFT JOIN dw_HR.DimMode dm
                ON dm.ModeCode = cg.ModeCode
            LEFT JOIN dw_HR.DimServiceType dst
                ON dst.TOSCode = cg.TOSCode
            LEFT JOIN dw_HR.DimEmploymentType det
                ON det.EmploymentTypeName = cg.EmploymentType
            LEFT JOIN dw_HR.DimDepartment ddpt
                ON ddpt.DepartmentName = cg.DepartmentName
        ),
        FilteredCoverage AS (
            SELECT *
            FROM ResolvedCoverage rc
            WHERE NOT EXISTS (
                SELECT 1
                FROM dw_HR.FactAgencyLaborCoverage fac
                WHERE fac.DateKey = rc.DateKey
                AND fac.AgencyKey = rc.AgencyKey
                AND fac.DepartmentKey = rc.DepartmentKey
                AND fac.ModeKey = rc.ModeKey
                AND fac.ServiceTypeKey = rc.ServiceTypeKey
                AND fac.EmploymentTypeKey = rc.EmploymentTypeKey
            )
        )
        INSERT INTO dw_HR.FactAgencyLaborCoverage
        (
            DateKey,
            AgencyKey,
            DepartmentKey,
            ModeKey,
            ServiceTypeKey,
            EmploymentTypeKey,
            ETL_InsertDate,
            ETL_BatchID,
            RecordSourceSystem
        )
        SELECT
            fc.DateKey,
            fc.AgencyKey,
            fc.DepartmentKey,
            fc.ModeKey,
            fc.ServiceTypeKey,
            fc.EmploymentTypeKey,
            fc.ETL_InsertDate,
            fc.ETL_BatchID,
            fc.RecordSourceSystem
        FROM FilteredCoverage fc;

        SET @RowsInserted = @@ROWCOUNT;

        SELECT @RowsProcessed = COUNT(*) FROM CoverageGrain;

        -- ============================================================
        -- PHASE 3: AUDIT & COMMIT
        -- ============================================================
        UPDATE dw_transport.etl_load_audit
        SET
            load_end_time = SYSDATETIME(),
            rows_processed = @RowsProcessed,
            rows_inserted = @RowsInserted,
            status = 'SUCCESS'
        WHERE audit_id = @AuditID;

        COMMIT TRANSACTION;

        PRINT CONCAT
        (
            'FactAgencyLaborCoverage (Factless): Load completed. '
            'Rows processed: ', @RowsProcessed,
            ', Rows inserted: ', @RowsInserted
        );

    END TRY
    BEGIN CATCH
        -- ============================================================
        -- ERROR HANDLING
        -- ============================================================
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;

        UPDATE dw_transport.etl_load_audit
        SET
            load_end_time = SYSDATETIME(),
            status = 'FAILED',
            error_message = ERROR_MESSAGE()
        WHERE audit_id = @AuditID;

        THROW;

    END CATCH;

END;
GO

-- ============================================================
-- FILE:     09_load_FactJobPostingLifecycle_etl.sql
-- SCHEMA:   dw_HR
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
    @SourceSystem VARCHAR(50) = 'NTD_Job_Openings'
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    DECLARE @RowsProcessed INT = 0;
    DECLARE @RowsInserted INT = 0;
    DECLARE @RowsUpdated INT = 0;
    DECLARE @LoadStartTime DATETIME2 = SYSDATETIME();
    DECLARE @AuditId INT;

    INSERT INTO dw_transport.etl_load_audit (procedure_name, load_date, load_start_time, status)
    VALUES ('dw_HR.sp_Load_FactJobPostingLifecycle', CAST(GETDATE() AS DATE), @LoadStartTime, 'IN_PROGRESS');
    SET @AuditId = SCOPE_IDENTITY();

    BEGIN TRY
        BEGIN TRANSACTION;

        WITH StagedPostings AS (
            SELECT
                src.opening_id,
                src.posting_date,
                src.filled_date,
                src.closing_date,
                src.ntd_id,
                src.mode_code,
                src.tos,
                src.employment_type,
                src.ntd_labor_object_class,
                src.position_title,
                src.days_open,
                src.hired_count,
                src.posting_status,
                ROW_NUMBER() OVER (PARTITION BY src.opening_id ORDER BY src.posting_date DESC) AS rn
            FROM stg_HR.stg_job_openings src
            WHERE src.opening_id IS NOT NULL
        ),
        DedupedPostings AS (
            SELECT
                sp.opening_id,
                sp.posting_date,
                sp.filled_date,
                sp.closing_date,
                sp.ntd_id,
                sp.mode_code,
                sp.tos,
                sp.employment_type,
                sp.ntd_labor_object_class,
                sp.position_title,
                sp.days_open,
                sp.hired_count,
                sp.posting_status
            FROM StagedPostings sp
            WHERE sp.rn = 1
        ),
        ResolvedDimensions AS (
            SELECT
                dp.opening_id,
                ISNULL(a.AgencyKey, -1) AS AgencyKey,
                ISNULL(m.ModeKey, -1) AS ModeKey,
                ISNULL(s.ServiceTypeKey, -1) AS ServiceTypeKey,
                ISNULL(e.EmploymentTypeKey, -1) AS EmploymentTypeKey,
                ISNULL(d.DepartmentKey, -1) AS DepartmentKey,
                ISNULL(jr.JobRoleKey, -1) AS JobRoleKey,
                ISNULL(d_post.DateKey, -1) AS PostingDateKey,
                ISNULL(d_fill.DateKey, -1) AS FilledDateKey,
                ISNULL(d_close.DateKey, -1) AS ClosingDateKey,
                dp.days_open,
                dp.hired_count,
                dp.posting_status
            FROM DedupedPostings dp
            LEFT JOIN dw_HR.DimDate d_post
                ON d_post.FullDate = dp.posting_date
            LEFT JOIN dw_HR.DimDate d_fill
                ON d_fill.FullDate = dp.filled_date
            LEFT JOIN dw_HR.DimDate d_close
                ON d_close.FullDate = dp.closing_date
            LEFT JOIN dw_HR.DimAgency a
                ON a.NTD_ID = dp.ntd_id
                AND dp.posting_date >= a.EffectiveDate
                AND dp.posting_date <= a.ExpirationDate
            LEFT JOIN dw_HR.DimMode m
                ON m.ModeCode = dp.mode_code
            LEFT JOIN dw_HR.DimServiceType s
                ON s.TOSCode = dp.tos
            LEFT JOIN dw_HR.DimEmploymentType e
                ON e.EmploymentTypeName = dp.employment_type
            LEFT JOIN dw_HR.DimDepartment d
                ON d.DepartmentName = dp.ntd_labor_object_class
            LEFT JOIN dw_HR.DimJobRole jr
                ON jr.PositionTitle = dp.position_title
                AND dp.posting_date >= jr.EffectiveDate
                AND dp.posting_date <= jr.ExpirationDate
        )
        SELECT @RowsProcessed = COUNT(*) FROM ResolvedDimensions;

        INSERT INTO dw_HR.FactJobPostingLifecycle (
            AgencyKey, ModeKey, ServiceTypeKey, EmploymentTypeKey, DepartmentKey, JobRoleKey,
            OpeningID, PostingDateKey, FilledDateKey, ClosingDateKey,
            DaysOpen, HiredCount, PostingStatus,
            ETL_InsertDate, ETL_UpdateDate, ETL_BatchID, RecordSourceSystem
        )
        SELECT
            rd.AgencyKey,
            rd.ModeKey,
            rd.ServiceTypeKey,
            rd.EmploymentTypeKey,
            rd.DepartmentKey,
            rd.JobRoleKey,
            rd.opening_id,
            rd.PostingDateKey,
            rd.FilledDateKey,
            rd.ClosingDateKey,
            rd.days_open,
            rd.hired_count,
            rd.posting_status,
            @LoadStartTime,
            NULL,
            @BatchID,
            @SourceSystem
        FROM ResolvedDimensions rd
        WHERE NOT EXISTS (
            SELECT 1 FROM dw_HR.FactJobPostingLifecycle f
            WHERE f.OpeningID = rd.opening_id
        );
        SET @RowsInserted = @@ROWCOUNT;

        UPDATE f
        SET
            f.PostingDateKey = CASE WHEN rd.PostingDateKey != -1 THEN rd.PostingDateKey ELSE f.PostingDateKey END,
            f.FilledDateKey = CASE WHEN rd.FilledDateKey != -1 THEN rd.FilledDateKey ELSE f.FilledDateKey END,
            f.ClosingDateKey = CASE WHEN rd.ClosingDateKey != -1 THEN rd.ClosingDateKey ELSE f.ClosingDateKey END,
            f.DaysOpen = rd.days_open,
            f.HiredCount = rd.hired_count,
            f.PostingStatus = rd.posting_status,
            f.ETL_UpdateDate = @LoadStartTime,
            f.ETL_BatchID = @BatchID
        FROM dw_HR.FactJobPostingLifecycle f
        INNER JOIN ResolvedDimensions rd
            ON f.OpeningID = rd.opening_id
        WHERE f.FilledDateKey IS NULL
           OR f.ClosingDateKey = -1
           OR f.HiredCount != rd.hired_count
           OR f.DaysOpen != rd.days_open
           OR f.PostingStatus != rd.posting_status;
        SET @RowsUpdated = @@ROWCOUNT;

        UPDATE dw_transport.etl_load_audit
        SET
            load_end_time = SYSDATETIME(),
            rows_processed = @RowsProcessed,
            rows_inserted = @RowsInserted,
            rows_updated = @RowsUpdated,
            status = 'SUCCESS'
        WHERE audit_id = @AuditId;

        COMMIT TRANSACTION;

    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;

        UPDATE dw_transport.etl_load_audit
        SET
            load_end_time = SYSDATETIME(),
            status = 'FAILED',
            error_message = ERROR_MESSAGE()
        WHERE audit_id = @AuditId;

        THROW;
    END CATCH
END;
GO
