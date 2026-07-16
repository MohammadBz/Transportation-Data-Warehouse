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
    @BatchID BIGINT = NULL,
    @SourceSystem VARCHAR(50) = 'NTD_Job_Openings'
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    DECLARE @RowsProcessed INT = 0;
    DECLARE @RowsInserted INT = 0;
    DECLARE @LoadStartTime DATETIME2 = SYSDATETIME();
    DECLARE @AuditId INT;
    DECLARE @ErrorMsg NVARCHAR(MAX) = NULL;
    DECLARE @LoadDate DATE = CAST(GETDATE() AS DATE);

    -- Log start of audit
    INSERT INTO dw_common.etl_load_audit (
        procedure_name, load_date, load_start_time, status
    )
    VALUES ('dw_HR.sp_Load_FactJobPosting', @LoadDate, @LoadStartTime, 'IN_PROGRESS');
    SET @AuditId = SCOPE_IDENTITY();

    BEGIN TRY
        -- Use a temp table to store deduplicated records once
        CREATE TABLE #DedupedPostings (
            opening_id VARCHAR(100),          -- ✅ Fixed: changed from INT to VARCHAR
            posting_date_key INT,
            ntd_id VARCHAR(100),                       -- keep as INT if source is numeric; if not, change to VARCHAR
            posting_date DATE,
            mode_code VARCHAR(50),
            tos VARCHAR(50),
            employment_type VARCHAR(100),
            Department VARCHAR(100),
            position_title VARCHAR(200),
            open_positions INT,
            salary_min_hourly DECIMAL(18,2),
            salary_max_hourly DECIMAL(18,2),
            salary_mid_hourly DECIMAL(18,2),
            days_open INT,
            hired_count INT,
            posting_status VARCHAR(50),
            vacancy_reason VARCHAR(100)
        );

        -- Populate the temp table with the latest row per opening_id
        ;WITH RankedPostings AS (
            SELECT
                sp.opening_id,
                sp.posting_date_key,
                sp.ntd_id,
                sp.posting_date,
                sp.mode_code,
                sp.tos,
                sp.employment_type,
                sp.department,
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
            WHERE sp.opening_id IS NOT NULL   -- ensure no NULLs
        )
        INSERT INTO #DedupedPostings
        SELECT
            opening_id,
            posting_date_key,
            ntd_id,
            posting_date,
            mode_code,
            tos,
            employment_type,
            department,
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
        WHERE rn = 1;

        -- Now we can use the temp table multiple times
        SELECT @RowsProcessed = COUNT(*) FROM #DedupedPostings;

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
            VacancyReason
        )
        SELECT
            ISNULL(d.DateKey, -1) AS DateKey,
            ISNULL(a.AgencyKey, -1) AS AgencyKey,
            ISNULL(m.ModeKey, -1) AS ModeKey,
            ISNULL(s.ServiceTypeKey, -1) AS ServiceTypeKey,
            ISNULL(e.EmploymentTypeKey, -1) AS EmploymentTypeKey,
            ISNULL(dept.DepartmentKey, -1) AS DepartmentKey,
            ISNULL(jr.JobRoleKey, -1) AS JobRoleKey,
            dp.opening_id,                    -- now VARCHAR, matches fact table
            dp.open_positions,
            dp.salary_min_hourly,
            dp.salary_max_hourly,
            dp.salary_mid_hourly,
            dp.days_open,
            dp.hired_count,
            dp.posting_status,
            dp.vacancy_reason
        FROM #DedupedPostings dp
            LEFT JOIN dw_common.DimDate d ON d.FullDate = dp.posting_date
        LEFT JOIN dw_common.DimAgency a
            ON a.NTD_ID = dp.ntd_id
            AND dp.posting_date >= a.EffectiveDate
            AND dp.posting_date <= a.ExpirationDate
        LEFT JOIN dw_common.DimMode m
            ON m.ModeCode = dp.mode_code
        LEFT JOIN dw_common.DimServiceType s
            ON s.TOSCode = dp.tos
        LEFT JOIN dw_HR.DimEmploymentType e
            ON e.EmploymentTypeName = dp.employment_type
        LEFT JOIN dw_HR.DimDepartment dept
             ON UPPER(LTRIM(RTRIM(dept.DepartmentName))) = UPPER(LTRIM(RTRIM(dp.Department)))
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

        UPDATE dw_common.etl_load_audit
        SET
            load_end_time = SYSDATETIME(),
            rows_processed = @RowsProcessed,
            rows_inserted = @RowsInserted,
            status = 'SUCCESS'
        WHERE audit_id = @AuditId;

        COMMIT TRANSACTION;

        -- Clean up temp table
        DROP TABLE #DedupedPostings;

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

        IF OBJECT_ID('tempdb..#DedupedPostings') IS NOT NULL
            DROP TABLE #DedupedPostings;

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
    @BatchID BIGINT = NULL,
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

        -- Audit log
        INSERT INTO dw_common.etl_load_audit
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

        -- Main CTE with dimension lookups and safe conversions
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

                -- Derived measure
                CASE
                    WHEN TRY_CAST(stg.EmployeeCount AS DECIMAL(18,4)) > 0
                         AND TRY_CAST(stg.HoursWorked AS DECIMAL(18,4)) IS NOT NULL
                    THEN TRY_CAST(stg.HoursWorked AS DECIMAL(18,4)) /
                         TRY_CAST(stg.EmployeeCount AS DECIMAL(18,4))
                    ELSE NULL
                END AS HoursPerEmployee,

                @SourceSystem AS SourceSystem,
                @LoadStartTime AS CreatedDate

            FROM stg_HR.stg_transit_employee_unified stg
                LEFT JOIN dw_common.DimDate dd
                    ON dd.CalendarYear = TRY_CAST(stg.ReportYear AS INT)   -- ✅ safe conversion
                    AND dd.CalendarDay = 1
                LEFT JOIN dw_common.DimAgency da
                    ON da.NTD_ID = stg.NTD_ID
                    AND dd.FullDate >= da.EffectiveDate
                    AND dd.FullDate <= da.ExpirationDate
                LEFT JOIN dw_common.DimMode dm
                    ON dm.ModeCode = stg.ModeCode
                LEFT JOIN dw_common.DimServiceType dst
                    ON dst.TOSCode = stg.TOSCode
                LEFT JOIN dw_HR.DimEmploymentType det
                    ON det.EmploymentTypeName =
                       CASE
                           WHEN stg.EmploymentType = 'FullTime' THEN 'Full-Time'
                           WHEN stg.EmploymentType = 'PartTime' THEN 'Part-Time'
                           ELSE 'Unknown Employment Type'
                       END
                LEFT JOIN dw_HR.DimDepartment ddpt
                    ON UPPER(LTRIM(RTRIM(ddpt.DepartmentName))) = UPPER(LTRIM(RTRIM(stg.DepartmentName)))
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

        -- Update audit
        UPDATE dw_common.etl_load_audit
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
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;

        SET @ErrorMessage = ERROR_MESSAGE();

        UPDATE dw_common.etl_load_audit
        SET
            load_end_time = SYSDATETIME(),
            status = 'FAILED',
            error_message = @ErrorMessage
        WHERE audit_id = @AuditID;

        THROW;   -- ✅ rethrows original error
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

CREATE OR ALTER PROCEDURE dw_HR.sp_Load_FactAgencyLaborCoverage
    @BatchID BIGINT = NULL,
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

        -- ============================================================
        -- Audit log
        -- ============================================================
        INSERT INTO dw_common.etl_load_audit
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

        BEGIN TRANSACTION;

        -- ============================================================
        -- Build and deduplicate the final fact grain
        -- ============================================================
        ;WITH CoverageGrain AS
        (
            SELECT DISTINCT
                stg.ReportYear,
                stg.NTD_ID,
                stg.ModeCode,
                stg.TOSCode,
                stg.DepartmentName,
                stg.EmploymentType
            FROM stg_HR.stg_transit_employee_unified stg
            WHERE TRY_CAST(stg.HoursWorked AS DECIMAL(18,4)) > 0
        ),
        ResolvedCoverage AS
        (
            SELECT
                ISNULL(dd.DateKey, -1) AS DateKey,
                ISNULL(da.AgencyKey, -1) AS AgencyKey,
                ISNULL(ddpt.DepartmentKey, -1) AS DepartmentKey,
                ISNULL(dm.ModeKey, -1) AS ModeKey,
                ISNULL(dst.ServiceTypeKey, -1) AS ServiceTypeKey,
                ISNULL(det.EmploymentTypeKey, -1) AS EmploymentTypeKey
            FROM CoverageGrain cg

            LEFT JOIN dw_common.DimDate dd
                ON dd.FullDate = DATEFROMPARTS
                (
                    TRY_CAST(cg.ReportYear AS INT),
                    1,
                    1
                )

            LEFT JOIN dw_common.DimAgency da
                ON da.NTD_ID = cg.NTD_ID
                AND dd.FullDate >= da.EffectiveDate
                AND dd.FullDate <= da.ExpirationDate

            LEFT JOIN dw_common.DimMode dm
                ON dm.ModeCode = cg.ModeCode

            LEFT JOIN dw_common.DimServiceType dst
                ON dst.TOSCode = cg.TOSCode

            LEFT JOIN dw_HR.DimEmploymentType det
                ON det.EmploymentTypeName =
                    CASE
                        WHEN cg.EmploymentType = 'FullTime'
                            THEN 'Full-Time'

                        WHEN cg.EmploymentType = 'PartTime'
                            THEN 'Part-Time'

                        ELSE cg.EmploymentType
                    END

            LEFT JOIN dw_HR.DimDepartment ddpt
                ON UPPER(LTRIM(RTRIM(ddpt.DepartmentName)))
                 =
                   UPPER(LTRIM(RTRIM(cg.DepartmentName)))
        ),
        DeduplicatedCoverage AS
        (
            SELECT
                rc.*,
                ROW_NUMBER() OVER
                (
                    PARTITION BY
                        rc.DateKey,
                        rc.AgencyKey,
                        rc.DepartmentKey,
                        rc.ModeKey,
                        rc.ServiceTypeKey,
                        rc.EmploymentTypeKey
                    ORDER BY
                        rc.DateKey
                ) AS rn
            FROM ResolvedCoverage rc
        ),
        FilteredCoverage AS
        (
            SELECT
                dc.DateKey,
                dc.AgencyKey,
                dc.DepartmentKey,
                dc.ModeKey,
                dc.ServiceTypeKey,
                dc.EmploymentTypeKey
            FROM DeduplicatedCoverage dc
            WHERE dc.rn = 1
              AND dc.AgencyKey <> -1
        )
        INSERT INTO dw_HR.FactAgencyLaborCoverage
        (
            DateKey,
            AgencyKey,
            DepartmentKey,
            ModeKey,
            ServiceTypeKey,
            EmploymentTypeKey
        )
        SELECT
            fc.DateKey,
            fc.AgencyKey,
            fc.DepartmentKey,
            fc.ModeKey,
            fc.ServiceTypeKey,
            fc.EmploymentTypeKey
        FROM FilteredCoverage fc
        WHERE NOT EXISTS
        (
            SELECT 1
            FROM dw_HR.FactAgencyLaborCoverage fac
            WHERE fac.DateKey = fc.DateKey
              AND fac.AgencyKey = fc.AgencyKey
              AND fac.DepartmentKey = fc.DepartmentKey
              AND fac.ModeKey = fc.ModeKey
              AND fac.ServiceTypeKey = fc.ServiceTypeKey
              AND fac.EmploymentTypeKey = fc.EmploymentTypeKey
        );

        SET @RowsInserted = @@ROWCOUNT;

        -- Since the CTE is no longer available here,
        -- use the number of inserted rows as the processed count.
        SET @RowsProcessed = @RowsInserted;

        -- ============================================================
        -- Audit success
        -- ============================================================
        UPDATE dw_common.etl_load_audit
        SET
            load_end_time = SYSDATETIME(),
            rows_processed = @RowsProcessed,
            rows_inserted = @RowsInserted,
            status = 'SUCCESS'
        WHERE audit_id = @AuditID;

        COMMIT TRANSACTION;

        PRINT CONCAT
        (
            'FactAgencyLaborCoverage: Load completed. ',
            'Rows processed: ', @RowsProcessed,
            ', Rows inserted: ', @RowsInserted
        );

    END TRY
    BEGIN CATCH

        IF XACT_STATE() <> 0
            ROLLBACK TRANSACTION;

        SET @ErrorMessage = ERROR_MESSAGE();

        UPDATE dw_common.etl_load_audit
        SET
            load_end_time = SYSDATETIME(),
            status = 'FAILED',
            error_message = @ErrorMessage
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
    @BatchID BIGINT = NULL,
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
    DECLARE @ErrorMsg NVARCHAR(MAX) = NULL;
    DECLARE @LoadDate DATE = CAST(GETDATE() AS DATE);

    -- Log start of audit
    INSERT INTO dw_common.etl_load_audit (procedure_name, load_date, load_start_time, status)
    VALUES ('dw_HR.sp_Load_FactJobPostingLifecycle', @LoadDate, @LoadStartTime, 'IN_PROGRESS');
    SET @AuditId = SCOPE_IDENTITY();

    BEGIN TRY
        BEGIN TRANSACTION;

        -- Temp table: FilledDateKey and ClosingDateKey allow NULL
        CREATE TABLE #ResolvedDimensions (
            OpeningID VARCHAR(100) NOT NULL,
            AgencyKey INT NOT NULL,
            ModeKey INT NOT NULL,
            ServiceTypeKey INT NOT NULL,
            EmploymentTypeKey INT NOT NULL,
            DepartmentKey INT NOT NULL,
            JobRoleKey INT NOT NULL,
            PostingDateKey INT NOT NULL,          -- -1 if unknown
            FilledDateKey INT NULL,               -- NULL allowed
            ClosingDateKey INT NULL,              -- NULL allowed
            DaysOpen INT NULL,                    -- now NULLable to handle bad data
            HiredCount INT NULL,                  -- now NULLable
            PostingStatus VARCHAR(50)
        );

        -- Populate with deduplicated postings and resolved dimension keys
        ;WITH StagedPostings AS (
            SELECT
                src.opening_id,
                src.posting_date,
                src.filled_date,
                src.closing_date,
                src.ntd_id,
                src.mode_code,
                src.tos,
                src.employment_type,
                src.department,
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
                sp.department,
                sp.position_title,
                sp.days_open,
                sp.hired_count,
                sp.posting_status
            FROM StagedPostings sp
            WHERE sp.rn = 1
        )
        INSERT INTO #ResolvedDimensions (
            OpeningID,
            AgencyKey,
            ModeKey,
            ServiceTypeKey,
            EmploymentTypeKey,
            DepartmentKey,
            JobRoleKey,
            PostingDateKey,
            FilledDateKey,
            ClosingDateKey,
            DaysOpen,
            HiredCount,
            PostingStatus
        )
        SELECT
            dp.opening_id,
            ISNULL(a.AgencyKey, -1) AS AgencyKey,
            ISNULL(m.ModeKey, -1) AS ModeKey,
            ISNULL(s.ServiceTypeKey, -1) AS ServiceTypeKey,
            ISNULL(e.EmploymentTypeKey, -1) AS EmploymentTypeKey,
            ISNULL(d.DepartmentKey, -1) AS DepartmentKey,
            ISNULL(jr.JobRoleKey, -1) AS JobRoleKey,
            ISNULL(d_post.DateKey, -1) AS PostingDateKey,
            CASE
                WHEN d_fill.DateKey IS NOT NULL
                 AND d_post.DateKey IS NOT NULL
                 AND d_fill.DateKey >= d_post.DateKey
                THEN d_fill.DateKey
                ELSE NULL
            END AS FilledDateKey,
            d_close.DateKey AS ClosingDateKey,
            TRY_CAST(dp.days_open AS INT) AS DaysOpen,      -- ✅ safe cast
            TRY_CAST(dp.hired_count AS INT) AS HiredCount,  -- ✅ safe cast
            dp.posting_status
        FROM DedupedPostings dp
        LEFT JOIN dw_common.DimDate d_post
            ON d_post.FullDate = dp.posting_date
        LEFT JOIN dw_common.DimDate d_fill
            ON d_fill.FullDate = dp.filled_date
        LEFT JOIN dw_common.DimDate d_close
            ON d_close.FullDate = dp.closing_date
        LEFT JOIN dw_common.DimAgency a
            ON a.NTD_ID = dp.ntd_id
            AND dp.posting_date >= a.EffectiveDate
            AND dp.posting_date <= a.ExpirationDate
        LEFT JOIN dw_common.DimMode m
            ON m.ModeCode = dp.mode_code
        LEFT JOIN dw_common.DimServiceType s
            ON s.TOSCode = dp.tos
        LEFT JOIN dw_HR.DimEmploymentType e
            ON e.EmploymentTypeName = dp.employment_type
        LEFT JOIN dw_HR.DimDepartment d
            ON UPPER(LTRIM(RTRIM(d.DepartmentName))) = UPPER(LTRIM(RTRIM(dp.department)))
        LEFT JOIN dw_HR.DimJobRole jr
            ON jr.PositionTitle = dp.position_title
            AND dp.posting_date >= jr.EffectiveDate
            AND dp.posting_date <= jr.ExpirationDate;

        -- Rest of the procedure remains unchanged
        SELECT @RowsProcessed = COUNT(*) FROM #ResolvedDimensions;

        INSERT INTO dw_HR.FactJobPostingLifecycle (
            AgencyKey, ModeKey, ServiceTypeKey, EmploymentTypeKey, DepartmentKey, JobRoleKey,
            OpeningID, PostingDateKey, FilledDateKey, ClosingDateKey,
            DaysOpen, HiredCount, PostingStatus
        )
        SELECT
            rd.AgencyKey,
            rd.ModeKey,
            rd.ServiceTypeKey,
            rd.EmploymentTypeKey,
            rd.DepartmentKey,
            rd.JobRoleKey,
            rd.OpeningID,
            rd.PostingDateKey,
            rd.FilledDateKey,
            rd.ClosingDateKey,
            rd.DaysOpen,
            rd.HiredCount,
            rd.PostingStatus
        FROM #ResolvedDimensions rd
        WHERE NOT EXISTS (
            SELECT 1 FROM dw_HR.FactJobPostingLifecycle f
            WHERE f.OpeningID = rd.OpeningID
        );
        SET @RowsInserted = @@ROWCOUNT;

        UPDATE f
        SET
            f.PostingDateKey = CASE WHEN rd.PostingDateKey != -1 THEN rd.PostingDateKey ELSE f.PostingDateKey END,
            f.FilledDateKey = CASE WHEN rd.FilledDateKey IS NOT NULL THEN rd.FilledDateKey ELSE f.FilledDateKey END,
            f.ClosingDateKey = CASE WHEN rd.ClosingDateKey IS NOT NULL THEN rd.ClosingDateKey ELSE f.ClosingDateKey END,
            f.DaysOpen = rd.DaysOpen,
            f.HiredCount = rd.HiredCount,
            f.PostingStatus = rd.PostingStatus
        FROM dw_HR.FactJobPostingLifecycle f
        INNER JOIN #ResolvedDimensions rd
            ON f.OpeningID = rd.OpeningID
        WHERE
            f.FilledDateKey IS NULL
            OR f.ClosingDateKey = -1
            OR f.HiredCount != rd.HiredCount
            OR f.DaysOpen != rd.DaysOpen
            OR f.PostingStatus != rd.PostingStatus;
        SET @RowsUpdated = @@ROWCOUNT;

        UPDATE dw_common.etl_load_audit
        SET
            load_end_time = SYSDATETIME(),
            rows_processed = @RowsProcessed,
            rows_inserted = @RowsInserted,
            rows_updated = @RowsUpdated,
            status = 'SUCCESS'
        WHERE audit_id = @AuditId;

        COMMIT TRANSACTION;
        DROP TABLE #ResolvedDimensions;

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

        IF OBJECT_ID('tempdb..#ResolvedDimensions') IS NOT NULL
            DROP TABLE #ResolvedDimensions;

        THROW;
    END CATCH
END;
GO
-- ============================================================
-- Master Facts Orchestrator for HR Data Mart
-- ============================================================
IF OBJECT_ID('dw_HR.sp_Load_All_Facts', 'P') IS NOT NULL
    DROP PROCEDURE dw_HR.sp_Load_All_Facts;
GO

CREATE PROCEDURE dw_HR.sp_Load_All_Facts
    @BatchID BIGINT = NULL,
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

    -- ============================================================
    -- Initialize default values
    -- ============================================================
    IF @BatchID IS NULL
        SET @CurrentBatchID = CAST(FORMAT(GETDATE(), 'yyyyMMddHHmmss') AS BIGINT);
    ELSE
        SET @CurrentBatchID = @BatchID;

    -- ============================================================
    -- Print header
    -- ============================================================
    PRINT REPLICATE('=', 80);
    PRINT '   HR DATA MART - FACTS LOAD ORCHESTRATION';
    PRINT REPLICATE('=', 80);
    PRINT '';
    PRINT CONCAT('Batch ID:            ', @CurrentBatchID);
    PRINT CONCAT('Start Time:          ', FORMAT(@StartTime, 'yyyy-MM-dd HH:mm:ss.fff'));
    PRINT CONCAT('Reload If Exists:    ', CASE WHEN @ReloadIfExists = 1 THEN 'YES' ELSE 'NO' END);
    PRINT '';
    PRINT 'Processing Fact Tables:';
    PRINT '  1. FactJobPosting (Transaction)';
    PRINT '  2. FactEmployeeSnapshot (Periodic Snapshot)';
    PRINT '  3. FactAgencyLaborCoverage (Factless Coverage)';
    PRINT '  4. FactJobPostingLifecycle (Accumulating Snapshot)';
    PRINT '';
    PRINT REPLICATE('=', 80);
    PRINT '';

    BEGIN TRY

        -- ============================================================
        -- LOAD FACT TABLES
        -- ============================================================
        PRINT CHAR(10) + REPLICATE('-', 80);
        PRINT 'LOADING FACT TABLES';
        PRINT REPLICATE('-', 80);
        PRINT '';

        BEGIN TRY
            PRINT 'Loading FactJobPosting...';
            EXEC dw_HR.sp_Load_FactJobPosting
                @BatchID = @CurrentBatchID,
                @SourceSystem = 'NTD_Job_Openings';
            PRINT CONCAT('  ✓ Completed at ', FORMAT(SYSDATETIME(), 'HH:mm:ss.fff'));
            PRINT '';

        END TRY
        BEGIN CATCH
            PRINT '  ✗ ERROR LOADING FactJobPosting';
            PRINT ERROR_MESSAGE();
            SET @ErrorOccurred = 1;
        END CATCH

        BEGIN TRY
            PRINT 'Loading FactEmployeeSnapshot...';
            EXEC dw_HR.sp_Load_FactEmployeeSnapshot
                @BatchID = @CurrentBatchID,
                @SourceSystem = 'NTD_Employee_Data';
            PRINT CONCAT('  ✓ Completed at ', FORMAT(SYSDATETIME(), 'HH:mm:ss.fff'));
            PRINT '';

        END TRY
        BEGIN CATCH
            PRINT '  ✗ ERROR LOADING FactEmployeeSnapshot';
            PRINT ERROR_MESSAGE();
            SET @ErrorOccurred = 1;
        END CATCH

        BEGIN TRY
            PRINT 'Loading FactAgencyLaborCoverage...';
            EXEC dw_HR.sp_Load_FactAgencyLaborCoverage
                @BatchID = @CurrentBatchID,
                @SourceSystem = 'NTD_Employee_Data';
            PRINT CONCAT('  ✓ Completed at ', FORMAT(SYSDATETIME(), 'HH:mm:ss.fff'));
            PRINT '';

        END TRY
        BEGIN CATCH
            PRINT '  ✗ ERROR LOADING FactAgencyLaborCoverage';
            PRINT ERROR_MESSAGE();
            SET @ErrorOccurred = 1;
        END CATCH

        BEGIN TRY
            PRINT 'Loading FactJobPostingLifecycle...';
            EXEC dw_HR.sp_Load_FactJobPostingLifecycle
                @BatchID = @CurrentBatchID,
                @SourceSystem = 'NTD_Job_Openings';
            PRINT CONCAT('  ✓ Completed at ', FORMAT(SYSDATETIME(), 'HH:mm:ss.fff'));
            PRINT '';

        END TRY
        BEGIN CATCH
            PRINT '  ✗ ERROR LOADING FactJobPostingLifecycle';
            PRINT ERROR_MESSAGE();
            SET @ErrorOccurred = 1;
        END CATCH

    END TRY
    BEGIN CATCH
        PRINT '';
        PRINT REPLICATE('=', 80);
        PRINT '*** FATAL ERROR IN HR FACTS LOAD ***';
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
        PRINT '   HR FACTS LOAD COMPLETED SUCCESSFULLY';
    END
    ELSE
    BEGIN
        PRINT '   HR FACTS LOAD COMPLETED WITH ERRORS';
    END
    PRINT REPLICATE('=', 80);
    PRINT '';
    PRINT CONCAT('End Time:            ', FORMAT(@EndTime, 'yyyy-MM-dd HH:mm:ss.fff'));
    PRINT CONCAT('Elapsed Time:        ', CONCAT(@ElapsedSeconds, ' seconds'));
    PRINT '';

    -- Return error status
    IF @ErrorOccurred = 1
    BEGIN
        THROW 50001, 'HR Facts load process encountered errors. Review messages above.', 1;
    END

END;
GO
