-- ============================================================
-- FILE:     load_hr_dimensions_etl.sql
-- SCHEMA:   dw_HR
-- DATABASE: TransportationDB
-- AUTHOR:   Parnian Ghaisari
-- DESC:     Optimized ETL Procedures for Remaining HR Dimensions
--           Processes: DimEmploymentType, DimDepartment, DimJobRole
--           Source: stg_HR.stg_job_openings
-- ============================================================

USE [TransportationDB];
GO

-- ============================================================
-- STEP 1: LOAD DIMEMPLOYMENTTYPE (Dynamic Sync from Staging)
-- ============================================================
CREATE OR ALTER PROCEDURE dw_HR.sp_load_dim_employment_type
    @LoadDate DATE = NULL
AS
BEGIN
    SET NOCOUNT ON;
    IF @LoadDate IS NULL SET @LoadDate = CAST(GETDATE() AS DATE);

    -- استخراج مقادیر یکتا از فیلد EmploymentType جدول استیجینگ و درج در جدول بعد
    INSERT INTO dw_HR.DimEmploymentType (EmploymentTypeCode, EmploymentTypeName, IsFullTime)
    SELECT DISTINCT
        CASE
            WHEN EmploymentType LIKE '%Full%' OR EmploymentType = 'FT' THEN 'FT'
            WHEN EmploymentType LIKE '%Part%' OR EmploymentType = 'PT' THEN 'PT'
            WHEN EmploymentType LIKE '%Contract%' OR EmploymentType = 'CT' THEN 'CT'
            ELSE 'N/A'
        END AS EmploymentTypeCode,
        LTRIM(RTRIM(EmploymentType)) AS EmploymentTypeName,
        CASE
            WHEN EmploymentType LIKE '%Full%' THEN 1
            WHEN EmploymentType LIKE '%Part%' THEN 0
            ELSE NULL
        END AS IsFullTime
    FROM stg_HR.stg_job_openings src
    WHERE src.EmploymentType IS NOT NULL
      AND LTRIM(RTRIM(src.EmploymentType)) != ''
      AND NOT EXISTS (
          SELECT 1
          FROM dw_HR.DimEmploymentType target
          WHERE target.EmploymentTypeName = LTRIM(RTRIM(src.EmploymentType))
      );
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
    IF @LoadDate IS NULL SET @LoadDate = CAST(GETDATE() AS DATE);

    -- استفاده از دستور MERGE برای به‌روزرسانی نام دپارتمان‌ها یا درج ساختارهای جدید
    MERGE dw_HR.DimDepartment AS Target
    USING (
        SELECT DISTINCT
            UPPER(LEFT(LTRIM(RTRIM(Department)), 50)) AS DepartmentCode,
            LEFT(LTRIM(RTRIM(Department)), 255) AS DepartmentName,
            LEFT(LTRIM(RTRIM(ISNULL(NTDLaborObjectClass, 'Unclassified'))), 100) AS NTDLaborObjectClass
        FROM stg_HR.stg_job_openings
        WHERE Department IS NOT NULL AND LTRIM(RTRIM(Department)) != ''
    ) AS Source
    ON (Target.DepartmentCode = Source.DepartmentCode)

    WHEN MATCHED AND (Target.DepartmentName != Source.DepartmentName OR ISNULL(Target.NTDLaborObjectClass,'') != Source.NTDLaborObjectClass) THEN
        UPDATE SET
            Target.DepartmentName = Source.DepartmentName,
            Target.NTDLaborObjectClass = Source.NTDLaborObjectClass

    WHEN NOT MATCHED THEN
        INSERT (DepartmentCode, DepartmentName, NTDLaborObjectClass)
        VALUES (Source.DepartmentCode, Source.DepartmentName, Source.NTDLaborObjectClass);
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
    IF @LoadDate IS NULL SET @LoadDate = CAST(GETDATE() AS DATE);

    -- جدول موقت برای تجمیع اطلاعات حقوق و پوزیشن از لایه استیجینگ
    IF OBJECT_ID('tempdb..#JobRoleCleaned') IS NOT NULL DROP TABLE #JobRoleCleaned;
    CREATE TABLE #JobRoleCleaned (
        PositionTitle VARCHAR(255),
        LaborCategory VARCHAR(100),
        OperatorStatus VARCHAR(50),
        TypicalSalaryMin NUMERIC(18,2),
        TypicalSalaryMax NUMERIC(18,2)
    );

    -- واکشی و متمرکزسازی داده‌ها از استیجینگ
    INSERT INTO #JobRoleCleaned
    SELECT
        LTRIM(RTRIM(PositionTitle)) AS PositionTitle,
        MAX(LEFT(LTRIM(RTRIM(NTDLaborObjectClass)), 100)) AS LaborCategory,
        MAX(LEFT(LTRIM(RTRIM(OperatorStatus)), 50)) AS OperatorStatus,
        MIN(TRY_CAST(SalaryMinHourly AS NUMERIC(18,2))) AS TypicalSalaryMin,
        MAX(TRY_CAST(SalaryMaxHourly AS NUMERIC(18,2))) AS TypicalSalaryMax
    FROM stg_HR.stg_job_openings
    WHERE PositionTitle IS NOT NULL AND LTRIM(RTRIM(PositionTitle)) != ''
    GROUP BY LTRIM(RTRIM(PositionTitle));

    BEGIN TRANSACTION;

    IF OBJECT_ID('tempdb..#JobDelta') IS NOT NULL DROP TABLE #JobDelta;

    -- تشخیص رکوردهای جدید (NEW) و رکوردهایی که دچار تغییرات SCD Type 2 شده‌اند
    SELECT
        src.*,
        dw.JobRoleKey,
        CASE
            WHEN dw.JobRoleKey IS NULL THEN 'NEW'
            WHEN ISNULL(dw.OperatorStatus, '') != ISNULL(src.OperatorStatus, '')
                 OR ISNULL(dw.LaborCategory, '') != ISNULL(src.LaborCategory, '')
                 OR ISNULL(dw.TypicalSalaryMin, 0) != ISNULL(src.TypicalSalaryMin, 0)
                 OR ISNULL(dw.TypicalSalaryMax, 0) != ISNULL(src.TypicalSalaryMax, 0)
            THEN 'CHANGE_SCD2'
            ELSE 'NO_CHANGE'
        END AS ChangeAction
    INTO #JobDelta
    FROM #JobRoleCleaned src
    LEFT JOIN dw_HR.DimJobRole dw ON src.PositionTitle = dw.PositionTitle AND dw.CurrentFlag = 1;

    -- ۱. منقضی کردن تاریخچه قبلی موقعیت‌های شغلی تغییر یافته
    UPDATE dw
    SET dw.CurrentFlag = 0,
        dw.ExpirationDate = DATEADD(day, -1, @LoadDate)
    FROM dw_HR.DimJobRole dw
    INNER JOIN #JobDelta d ON dw.JobRoleKey = d.JobRoleKey
    WHERE d.ChangeAction = 'CHANGE_SCD2';

    -- ۲. درج رکوردهای جدید و نسخه‌های بروزرسانی شده جدید
    INSERT INTO dw_HR.DimJobRole (PositionTitle, LaborCategory, OperatorStatus, TypicalSalaryMin, TypicalSalaryMax, EffectiveDate, ExpirationDate, CurrentFlag)
    SELECT PositionTitle, LaborCategory, OperatorStatus, TypicalSalaryMin, TypicalSalaryMax, @LoadDate, '9999-12-31', 1
    FROM #JobDelta
    WHERE ChangeAction IN ('NEW', 'CHANGE_SCD2');

    COMMIT TRANSACTION;
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
END;
GO
