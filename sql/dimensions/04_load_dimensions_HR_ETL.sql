-- ============================================================
-- FILE:     load_hr_dimensions_etl.sql
-- SCHEMA:   dw_HR
-- DATABASE: TransportationDB
-- AUTHOR:   Parnian Ghaisari
-- DESC:     Optimized ETL Procedures for Remaining HR Dimensions
--           Processes: DimEmploymentType, DimDepartment, DimJobRole
--           Source: stg_HR.stg_job_openings
--           Uses: dw_common.etl_load_audit for audit logging
-- ============================================================

USE [TransportationDB];
GO

-- ============================================================
-- STEP 1: LOAD DIMEMPLOYMENTTYPE (Dynamic Sync from Staging)
-- ============================================================
-- ============================================================
-- STEP 1: LOAD DIMEMPLOYMENTTYPE
-- Dynamic Sync from Staging
-- One row per EmploymentTypeCode
-- ============================================================

CREATE OR ALTER PROCEDURE dw_HR.sp_load_dim_employment_type
    @LoadDate DATE = NULL
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @AuditId INT;
    DECLARE @StartTime DATETIME2 = SYSDATETIME();
    DECLARE @RowsInserted INT = 0;
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
        'sp_load_dim_employment_type',
        @LoadDate,
        @StartTime,
        'IN_PROGRESS'
    );

    SET @AuditId = SCOPE_IDENTITY();

    BEGIN TRY

        /*
            Normalize and classify source employment types.

            The final result contains exactly one row
            for each EmploymentTypeCode.
        */
        ;WITH ClassifiedEmploymentTypes AS
        (
            SELECT
                EmploymentTypeCode,
                EmploymentTypeName,
                IsFullTime,

                ROW_NUMBER() OVER
                (
                    PARTITION BY EmploymentTypeCode
                    ORDER BY EmploymentTypeName
                ) AS RowNum

            FROM
            (
                SELECT
                    CASE
                        WHEN UPPER(LTRIM(RTRIM(employment_type)))
                                LIKE '%FULL%'
                             OR UPPER(LTRIM(RTRIM(employment_type))) = 'FT'
                            THEN 'FT'

                        WHEN UPPER(LTRIM(RTRIM(employment_type)))
                                LIKE '%PART%'
                             OR UPPER(LTRIM(RTRIM(employment_type))) = 'PT'
                            THEN 'PT'

                        WHEN UPPER(LTRIM(RTRIM(employment_type)))
                                LIKE '%TEMP%'
                             OR UPPER(LTRIM(RTRIM(employment_type))) = 'T'
                            THEN 'T'

                        WHEN UPPER(LTRIM(RTRIM(employment_type)))
                                LIKE '%SEASONAL%'
                             OR UPPER(LTRIM(RTRIM(employment_type))) = 'S'
                            THEN 'S'

                        WHEN UPPER(LTRIM(RTRIM(employment_type)))
                                LIKE '%CONTRACT%'
                             OR UPPER(LTRIM(RTRIM(employment_type))) = 'C'
                            THEN 'C'

                        ELSE 'N/A'
                    END AS EmploymentTypeCode,

                    LTRIM(RTRIM(employment_type))
                        AS EmploymentTypeName,

                    CASE
                        WHEN UPPER(LTRIM(RTRIM(employment_type)))
                                LIKE '%FULL%'
                            THEN 1

                        WHEN UPPER(LTRIM(RTRIM(employment_type)))
                                LIKE '%PART%'
                            THEN 0

                        ELSE NULL
                    END AS IsFullTime

                FROM stg_HR.stg_job_openings

                WHERE employment_type IS NOT NULL
                  AND LTRIM(RTRIM(employment_type)) <> ''
            ) SourceData
        )

        INSERT INTO dw_HR.DimEmploymentType
        (
            EmploymentTypeCode,
            EmploymentTypeName,
            IsFullTime
        )
        SELECT
            src.EmploymentTypeCode,
            src.EmploymentTypeName,
            src.IsFullTime

        FROM ClassifiedEmploymentTypes src

        WHERE src.RowNum = 1

          AND NOT EXISTS
          (
              SELECT 1
              FROM dw_HR.DimEmploymentType target
              WHERE target.EmploymentTypeCode =
                    src.EmploymentTypeCode
          );

        SET @RowsInserted = @@ROWCOUNT;

        -- Log success
        UPDATE dw_common.etl_load_audit
        SET
            load_end_time = SYSDATETIME(),
            rows_inserted = @RowsInserted,
            status = 'SUCCESS'
        WHERE audit_id = @AuditId;

    END TRY

    BEGIN CATCH

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
-- STEP 2: LOAD DIMDEPARTMENT (SCD Type 1 Merge from Staging)
-- ============================================================
CREATE OR ALTER PROCEDURE dw_HR.sp_load_dim_department
    @LoadDate DATE = NULL
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @AuditId INT;
    DECLARE @StartTime DATETIME2 = SYSDATETIME();
    DECLARE @RowsInserted INT = 0;
    DECLARE @ErrorMsg NVARCHAR(4000);

    IF @LoadDate IS NULL
        SET @LoadDate = CAST(GETDATE() AS DATE);

    -- Audit start
    INSERT INTO dw_common.etl_load_audit
    (
        procedure_name,
        load_date,
        load_start_time,
        status
    )
    VALUES
    (
        'sp_load_dim_department_hardcoded',
        @LoadDate,
        @StartTime,
        'IN_PROGRESS'
    );
    SET @AuditId = SCOPE_IDENTITY();

    BEGIN TRY
        -- Hardcoded department names using UNION ALL
        ;WITH DepartmentList AS (
            SELECT 'Administration' AS DepartmentName
            UNION ALL
            SELECT 'Capital'
            UNION ALL
            SELECT 'Customer Service'
            UNION ALL
            SELECT 'Facility Maintenance'
            UNION ALL
            SELECT 'Finance'
            UNION ALL
            SELECT 'General Administration'
            UNION ALL
            SELECT 'Human Resources'
            UNION ALL
            SELECT 'Information Technology'
            UNION ALL
            SELECT 'Maintenance'
            UNION ALL
            SELECT 'Operating'
            UNION ALL
            SELECT 'Operations'
            UNION ALL
            SELECT 'Planning'
            UNION ALL
            SELECT 'Safety'
            UNION ALL
            SELECT 'Total'
            UNION ALL
            SELECT 'Vehicle Maintenance'
            UNION ALL
            SELECT 'Vehicle Operations'
        ),
        Prepared AS (
            SELECT
                DepartmentName,
                UPPER(LEFT(LTRIM(RTRIM(DepartmentName)), 50)) AS DepartmentCode
            FROM DepartmentList
            WHERE LTRIM(RTRIM(DepartmentName)) <> ''
        )
        MERGE INTO dw_HR.DimDepartment AS Target
        USING Prepared AS Source
        ON Target.DepartmentCode = Source.DepartmentCode
        WHEN NOT MATCHED BY TARGET THEN
            INSERT (DepartmentCode, DepartmentName)
            VALUES (Source.DepartmentCode, Source.DepartmentName);

        SET @RowsInserted = @@ROWCOUNT;

        -- Audit success
        UPDATE dw_common.etl_load_audit
        SET
            load_end_time = SYSDATETIME(),
            rows_inserted = @RowsInserted,
            status = 'SUCCESS'
        WHERE audit_id = @AuditId;

    END TRY
    BEGIN CATCH
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
-- STEP 3: LOAD DIMJOBROLE (SCD Type 2 with Metrics Cleansing)
-- ============================================================
CREATE OR ALTER PROCEDURE dw_HR.sp_load_dim_job_role
    @LoadDate DATE = NULL
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    DECLARE @AuditId INT;
    DECLARE @StartTime DATETIME2 = SYSDATETIME();
    DECLARE @RowsInserted INT = 0;
    DECLARE @RowsUpdated INT = 0;
    DECLARE @RowsProcessed INT = 0;
    DECLARE @ErrorMsg NVARCHAR(4000);

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
        'sp_load_dim_job_role',
        @LoadDate,
        @StartTime,
        'IN_PROGRESS'
    );

    SET @AuditId = SCOPE_IDENTITY();

    BEGIN TRY

        BEGIN TRANSACTION;

        /* ============================================================
           1. Clean and aggregate staging data
           ============================================================ */

        IF OBJECT_ID('tempdb..#JobRoleCleaned') IS NOT NULL
            DROP TABLE #JobRoleCleaned;

        CREATE TABLE #JobRoleCleaned
        (
            PositionTitle VARCHAR(255) NOT NULL,
            LaborCategory VARCHAR(100),
            OperatorStatus VARCHAR(50),
            TypicalSalaryMin NUMERIC(18,2),
            TypicalSalaryMax NUMERIC(18,2)
        );

        INSERT INTO #JobRoleCleaned
        (
            PositionTitle,
            LaborCategory,
            OperatorStatus,
            TypicalSalaryMin,
            TypicalSalaryMax
        )
        SELECT
            LTRIM(RTRIM(position_title)) AS PositionTitle,

            MAX(
                LEFT(
                    LTRIM(RTRIM(ntd_labor_object_class)),
                    100
                )
            ) AS LaborCategory,

            MAX(
                LEFT(
                    LTRIM(RTRIM(operator_status)),
                    50
                )
            ) AS OperatorStatus,

            MIN(
                TRY_CAST(
                    salary_min_hourly AS NUMERIC(18,2)
                )
            ) AS TypicalSalaryMin,

            MAX(
                TRY_CAST(
                    salary_max_hourly AS NUMERIC(18,2)
                )
            ) AS TypicalSalaryMax

        FROM stg_HR.stg_job_openings

        WHERE position_title IS NOT NULL
          AND LTRIM(RTRIM(position_title)) <> ''

        GROUP BY
            LTRIM(RTRIM(position_title));


        /* ============================================================
           2. Identify new and changed roles
           ============================================================ */

        IF OBJECT_ID('tempdb..#JobDelta') IS NOT NULL
            DROP TABLE #JobDelta;

        SELECT
            src.PositionTitle,
            src.LaborCategory,
            src.OperatorStatus,
            src.TypicalSalaryMin,
            src.TypicalSalaryMax,

            dw.JobRoleKey,

            CASE
                WHEN dw.JobRoleKey IS NULL
                    THEN 'NEW'

                WHEN ISNULL(dw.OperatorStatus, '') <>
                     ISNULL(src.OperatorStatus, '')

                  OR ISNULL(dw.LaborCategory, '') <>
                     ISNULL(src.LaborCategory, '')

                  OR ISNULL(dw.TypicalSalaryMin, 0) <>
                     ISNULL(src.TypicalSalaryMin, 0)

                  OR ISNULL(dw.TypicalSalaryMax, 0) <>
                     ISNULL(src.TypicalSalaryMax, 0)

                    THEN 'CHANGE_SCD2'

                ELSE 'NO_CHANGE'
            END AS ChangeAction

        INTO #JobDelta

        FROM #JobRoleCleaned src

        LEFT JOIN dw_HR.DimJobRole dw
            ON UPPER(LTRIM(RTRIM(dw.PositionTitle))) =
               UPPER(LTRIM(RTRIM(src.PositionTitle)))

           AND dw.CurrentFlag = 1;


        /* ============================================================
           3. Expire changed current versions
           ============================================================ */

        UPDATE dw
        SET
            dw.CurrentFlag = 0,
            dw.ExpirationDate = DATEADD(DAY, -1, @LoadDate)

        FROM dw_HR.DimJobRole dw

        INNER JOIN #JobDelta d
            ON dw.JobRoleKey = d.JobRoleKey

        WHERE d.ChangeAction = 'CHANGE_SCD2'
          AND dw.CurrentFlag = 1;

        SET @RowsUpdated = @@ROWCOUNT;


        /* ============================================================
           4. Insert new SCD versions
           ============================================================ */

        INSERT INTO dw_HR.DimJobRole
        (
            PositionTitle,
            LaborCategory,
            OperatorStatus,
            TypicalSalaryMin,
            TypicalSalaryMax,
            EffectiveDate,
            ExpirationDate,
            CurrentFlag
        )
        SELECT
            PositionTitle,
            LaborCategory,
            OperatorStatus,
            TypicalSalaryMin,
            TypicalSalaryMax,
                @LoadDate AS EffectiveDate,
            CAST('9999-12-31' AS DATE) AS ExpirationDate,

            1 AS CurrentFlag

        FROM #JobDelta

        WHERE ChangeAction IN
        (
            'NEW',
            'CHANGE_SCD2'
        );

        SET @RowsInserted = @@ROWCOUNT;


        /* ============================================================
           5. Commit
           ============================================================ */

        COMMIT TRANSACTION;


        /* ============================================================
           6. Audit success
           ============================================================ */

        SELECT @RowsProcessed = COUNT(*)
        FROM #JobRoleCleaned;

        UPDATE dw_common.etl_load_audit
        SET
            load_end_time = SYSDATETIME(),
            rows_processed = @RowsProcessed,
            rows_inserted = @RowsInserted,
            rows_updated = @RowsUpdated,
            status = 'SUCCESS'

        WHERE audit_id = @AuditId;


        DROP TABLE #JobDelta;
        DROP TABLE #JobRoleCleaned;

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

        IF OBJECT_ID('tempdb..#JobDelta') IS NOT NULL
            DROP TABLE #JobDelta;

        IF OBJECT_ID('tempdb..#JobRoleCleaned') IS NOT NULL
            DROP TABLE #JobRoleCleaned;

        THROW;

    END CATCH;

END;
GO

-- ============================================================
-- MASTER PIPELINE EXECUTION ORCHESTRATOR
-- ============================================================
CREATE OR ALTER PROCEDURE dw_HR.sp_execute_hr_dimensions_etl
    @ExecutionDate DATE = NULL
AS
BEGIN
    SET NOCOUNT ON;
    IF @ExecutionDate IS NULL SET @ExecutionDate = CAST(GETDATE() AS DATE);

    PRINT 'Starting ETL Execution for Active HR Dimensions...';

    EXEC dw_HR.sp_load_dim_employment_type @LoadDate = @ExecutionDate;
    EXEC dw_HR.sp_load_dim_department @LoadDate = @ExecutionDate;
    EXEC dw_HR.sp_load_dim_job_role @LoadDate = @ExecutionDate;

    PRINT 'ETL Pipeline Executed Successfully for Specified Dimensions.';
    
    -- Display audit summary
    SELECT 
        procedure_name,
        load_date,
        CONVERT(VARCHAR(19), load_start_time, 121) AS start_time,
        CONVERT(VARCHAR(19), load_end_time, 121) AS end_time,
        rows_inserted,
        rows_updated,
        status
    FROM dw_common.etl_load_audit
    WHERE load_date = @ExecutionDate
      AND procedure_name IN ('sp_load_dim_employment_type', 'sp_load_dim_department', 'sp_load_dim_job_role')
    ORDER BY audit_id DESC;
END;
GO
