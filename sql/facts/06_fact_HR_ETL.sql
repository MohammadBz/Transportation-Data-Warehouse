

-- ============================================================
-- FILE:     06_load_FactJobPosting_etl.sql
-- SCHEMA:   dw_HR
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
-- ============================================================
-- FILE:     07_load_FactEmployeeSnapshot_etl.sql
-- SCHEMA:   dw_HR
-- DESC:     ETL Pipeline Procedure for FactEmployeeSnapshot (Fact 2)
--           Type: Periodic Snapshot Fact Table
--           Grain: Year x Agency x Department x EmploymentType x OperatorStatus x Mode x ServiceType
--           Adapted dynamically to explicitly read from real yearly staging tables (2014-2023).
-- ============================================================

USE [TransportationDB];
GO

IF OBJECT_ID('dw_HR.sp_Load_FactEmployeeSnapshot', 'P') IS NOT NULL
    DROP PROCEDURE dw_HR.sp_Load_FactEmployeeSnapshot;
GO

CREATE PROCEDURE dw_HR.sp_Load_FactEmployeeSnapshot
    @BatchID INT = NULL,
    @SourceSystem VARCHAR(50) = 'NTD_Yearly_Staging_Tables',
    @ReloadIfExists BIT = 1
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    DECLARE @RowsInserted INT = 0;
    DECLARE @RowsDeleted INT = 0;
    DECLARE @LoadStartTime DATETIME2 = SYSDATETIME();
    DECLARE @TransactionStarted BIT = 0;

    -- Initialize operational audit logging
    INSERT INTO dw_transport.etl_load_audit (procedure_name, load_date, load_start_time, status)
    VALUES ('dw_HR.sp_Load_FactEmployeeSnapshot', CAST(GETDATE() AS DATE), @LoadStartTime, 'IN_PROGRESS');
    DECLARE @AuditId INT = SCOPE_IDENTITY();

    BEGIN TRY
        IF @@TRANCOUNT = 0
        BEGIN
            BEGIN TRANSACTION;
            SET @TransactionStarted = 1;
        END

        -- Enforce Idempotency Principle by clearing target partition data
        IF @ReloadIfExists = 1
        BEGIN
            DELETE FROM dw_HR.FactEmployeeSnapshot WHERE YearKey BETWEEN 2014 AND 2023;
            SET @RowsDeleted = @@ROWCOUNT;
        END

        -- 1. Unified CTE Layer: Normalize and merge structural differences between 2014-2018 and 2019-2023 eras
        ;WITH cte_NormalizedTransitEmployees AS (
            -- Legacy Era (2014-2018): Map matching columns and default operator tags safely
            SELECT 2014 AS ReportYear, ntd_id, mode, tos,
                full_time_vehicle_operations_hours AS FT_Op_VehOp_Hrs, CAST(0 AS NUMERIC(18,2)) AS FT_NonOp_VehOp_Hrs,
                full_time_vehicle_maintenance_hours AS FT_NonOp_VehMaint_Hrs, full_time_non_vehicle_maintenance_hours AS FT_NonOp_FacMaint_Hrs,
                full_time_general_administration_hours AS FT_NonOp_GenAdmin_Hrs,
                full_time_vehicle_operations_employee_count AS FT_Op_VehOp_Cnt, CAST(0 AS NUMERIC(18,2)) AS FT_NonOp_VehOp_Cnt,
                full_time_vehicle_maintenance_employee_count AS FT_NonOp_VehMaint_Cnt, full_time_non_vehicle_maintenance_employee_count AS FT_NonOp_FacMaint_Cnt,
                full_time_general_administration_employee_count AS FT_NonOp_GenAdmin_Cnt,
                part_time_vehicle_operations_hours AS PT_Op_VehOp_Hrs, CAST(0 AS NUMERIC(18,2)) AS PT_NonOp_VehOp_Hrs,
                part_time_vehicle_maintenance_hours AS PT_NonOp_VehMaint_Hrs, part_time_non_vehicle_maintenance_hours AS PT_NonOp_FacMaint_Hrs,
                part_time_general_administration_hours AS PT_NonOp_GenAdmin_Hrs,
                part_time_vehicle_operations_employee_count AS PT_Op_VehOp_Cnt, CAST(0 AS NUMERIC(18,2)) AS PT_NonOp_VehOp_Cnt,
                part_time_vehicle_maintenance_employee_count AS PT_NonOp_VehMaint_Cnt, part_time_non_vehicle_maintenance_employee_count AS PT_NonOp_FacMaint_Cnt,
                part_time_general_administration_employee_count AS PT_NonOp_GenAdmin_Cnt
            FROM stg_HR.stg_transit_agency_employees_2014
            UNION ALL
            SELECT 2015 AS ReportYear, ntd_id, mode, tos,
                full_time_vehicle_operations_hours, 0, full_time_vehicle_maintenance_hours, full_time_non_vehicle_maintenance_hours, full_time_general_administration_hours,
                full_time_vehicle_operations_employee_count, 0, full_time_vehicle_maintenance_employee_count, full_time_non_vehicle_maintenance_employee_count, full_time_general_administration_employee_count,
                part_time_vehicle_operations_hours, 0, part_time_vehicle_maintenance_hours, part_time_non_vehicle_maintenance_hours, part_time_general_administration_hours,
                part_time_vehicle_operations_employee_count, 0, part_time_vehicle_maintenance_employee_count, part_time_non_vehicle_maintenance_employee_count, part_time_general_administration_employee_count
            FROM stg_HR.stg_transit_agency_employees_2015
            UNION ALL
            SELECT 2016 AS ReportYear, ntd_id, mode, tos,
                full_time_vehicle_operations_hours, 0, full_time_vehicle_maintenance_hours, full_time_non_vehicle_maintenance_hours, full_time_general_administration_hours,
                full_time_vehicle_operations_employee_count, 0, full_time_vehicle_maintenance_employee_count, full_time_non_vehicle_maintenance_employee_count, full_time_general_administration_employee_count,
                part_time_vehicle_operations_hours, 0, part_time_vehicle_maintenance_hours, part_time_non_vehicle_maintenance_hours, part_time_general_administration_hours,
                part_time_vehicle_operations_employee_count, 0, part_time_vehicle_maintenance_employee_count, part_time_non_vehicle_maintenance_employee_count, part_time_general_administration_employee_count
            FROM stg_HR.stg_transit_agency_employees_2016
            UNION ALL
            SELECT 2017 AS ReportYear, ntd_id, mode, tos,
                full_time_vehicle_operations_hours, 0, full_time_vehicle_maintenance_hours, full_time_non_vehicle_maintenance_hours, full_time_general_administration_hours,
                full_time_vehicle_operations_employee_count, 0, full_time_vehicle_maintenance_employee_count, full_time_non_vehicle_maintenance_employee_count, full_time_general_administration_employee_count,
                part_time_vehicle_operations_hours, 0, part_time_vehicle_maintenance_hours, part_time_non_vehicle_maintenance_hours, part_time_general_administration_hours,
                part_time_vehicle_operations_employee_count, 0, part_time_vehicle_maintenance_employee_count, part_time_non_vehicle_maintenance_employee_count, part_time_general_administration_employee_count
            FROM stg_HR.stg_transit_agency_employees_2017
            UNION ALL
            SELECT 2018 AS ReportYear, ntd_id, mode, tos,
                full_time_vehicle_operations_hours, 0, full_time_vehicle_maintenance_hours, full_time_non_vehicle_maintenance_hours, full_time_general_administration_hours,
                full_time_vehicle_operations_employee_count, 0, full_time_vehicle_maintenance_employee_count, full_time_non_vehicle_maintenance_employee_count, full_time_general_administration_employee_count,
                part_time_vehicle_operations_hours, 0, part_time_vehicle_maintenance_hours, part_time_non_vehicle_maintenance_hours, part_time_general_administration_hours,
                part_time_vehicle_operations_employee_count, 0, part_time_vehicle_maintenance_employee_count, part_time_non_vehicle_maintenance_employee_count, part_time_general_administration_employee_count
            FROM stg_HR.stg_transit_agency_employees_2018
            UNION ALL
            -- Modern Detailed Era (2019-2023): Explicitly bind full operational splits
            SELECT 2019 AS ReportYear, ntd_id, mode, tos,
                full_time_operator_vehicle_operations_hours_worked, full_time_non_operator_vehicle_operations_hours_worked,
                full_time_non_operator_vehicle_maintenance_hours_worked, full_time_non_operator_facility_maintenance_hours_worked, full_time_non_operator_general_administration_hours_worked,
                full_time_operator_vehicle_operations_employee_count, full_time_non_operator_vehicle_operations_employee_count,
                full_time_non_operator_vehicle_maintenance_employee_count, full_time_non_operator_facility_maintenance_employee_count, full_time_non_operator_general_administration_employee_count,
                part_time_operator_vehicle_operations_hours_worked, part_time_non_operator_vehicle_operations_hours_worked,
                part_time_non_operator_vehicle_maintenance_hours_worked, part_time_non_operator_facility_maintenance_hours_worked, part_time_non_operator_general_administration_hours_worked,
                part_time_operator_vehicle_operations_employee_count, part_time_non_operator_vehicle_operations_employee_count,
                part_time_non_operator_vehicle_maintenance_employee_count, part_time_non_operator_facility_maintenance_employee_count, part_time_non_operator_general_administration_employee_count
            FROM stg_HR.stg_transit_agency_employees_2019
            UNION ALL
            SELECT 2020 AS ReportYear, ntd_id, mode, tos,
                full_time_operator_vehicle_operations_hours_worked, full_time_non_operator_vehicle_operations_hours_worked,
                full_time_non_operator_vehicle_maintenance_hours_worked, full_time_non_operator_facility_maintenance_hours_worked, full_time_non_operator_general_administration_hours_worked,
                full_time_operator_vehicle_operations_employee_count, full_time_non_operator_vehicle_operations_employee_count,
                full_time_non_operator_vehicle_maintenance_employee_count, full_time_non_operator_facility_maintenance_employee_count, full_time_non_operator_general_administration_employee_count,
                part_time_operator_vehicle_operations_hours_worked, part_time_non_operator_vehicle_operations_hours_worked,
                part_time_non_operator_vehicle_maintenance_hours_worked, part_time_non_operator_facility_maintenance_hours_worked, part_time_non_operator_general_administration_hours_worked,
                part_time_operator_vehicle_operations_employee_count, part_time_non_operator_vehicle_operations_employee_count,
                part_time_non_operator_vehicle_maintenance_employee_count, part_time_non_operator_facility_maintenance_employee_count, part_time_non_operator_general_administration_employee_count
            FROM stg_HR.stg_transit_agency_employees_2020
            UNION ALL
            SELECT 2021 AS ReportYear, ntd_id, mode, tos,
                full_time_operator_vehicle_operations_hours_worked, full_time_non_operator_vehicle_operations_hours_worked,
                full_time_non_operator_vehicle_maintenance_hours_worked, full_time_non_operator_facility_maintenance_hours_worked, full_time_non_operator_general_administration_hours_worked,
                full_time_operator_vehicle_operations_employee_count, full_time_non_operator_vehicle_operations_employee_count,
                full_time_non_operator_vehicle_maintenance_employee_count, full_time_non_operator_facility_maintenance_employee_count, full_time_non_operator_general_administration_employee_count,
                part_time_operator_vehicle_operations_hours_worked, part_time_non_operator_vehicle_operations_hours_worked,
                part_time_non_operator_vehicle_maintenance_hours_worked, part_time_non_operator_facility_maintenance_hours_worked, part_time_non_operator_general_administration_hours_worked,
                part_time_operator_vehicle_operations_employee_count, part_time_non_operator_vehicle_operations_employee_count,
                part_time_non_operator_vehicle_maintenance_employee_count, part_time_non_operator_facility_maintenance_employee_count, part_time_non_operator_general_administration_employee_count
            FROM stg_HR.stg_transit_agency_employees_2021
            UNION ALL
            SELECT 2022 AS ReportYear, ntd_id, mode, tos,
                full_time_operator_vehicle_operations_hours_worked, full_time_non_operator_vehicle_operations_hours_worked,
                full_time_non_operator_vehicle_maintenance_hours_worked, full_time_non_operator_facility_maintenance_hours_worked, full_time_non_operator_general_administration_hours_worked,
                full_time_operator_vehicle_operations_employee_count, full_time_non_operator_vehicle_operations_employee_count,
                full_time_non_operator_vehicle_maintenance_employee_count, full_time_non_operator_facility_maintenance_employee_count, full_time_non_operator_general_administration_employee_count,
                part_time_operator_vehicle_operations_hours_worked, part_time_non_operator_vehicle_operations_hours_worked,
                part_time_non_operator_vehicle_maintenance_hours_worked, part_time_non_operator_facility_maintenance_hours_worked, part_time_non_operator_general_administration_hours_worked,
                part_time_operator_vehicle_operations_employee_count, part_time_non_operator_vehicle_operations_employee_count,
                part_time_non_operator_vehicle_maintenance_employee_count, part_time_non_operator_facility_maintenance_employee_count, part_time_non_operator_general_administration_employee_count
            FROM stg_HR.stg_transit_agency_employees_2022
            UNION ALL
            SELECT 2023 AS ReportYear, ntd_id, mode, tos,
                full_time_operator_vehicle_operations_hours_worked, full_time_non_operator_vehicle_operations_hours_worked,
                full_time_non_operator_vehicle_maintenance_hours_worked, full_time_non_operator_facility_maintenance_hours_worked, full_time_non_operator_general_administration_hours_worked,
                full_time_operator_vehicle_operations_employee_count, full_time_non_operator_vehicle_operations_employee_count,
                full_time_non_operator_vehicle_maintenance_employee_count, full_time_non_operator_facility_maintenance_employee_count, full_time_non_operator_general_administration_employee_count,
                part_time_operator_vehicle_operations_hours_worked, part_time_non_operator_vehicle_operations_hours_worked,
                part_time_non_operator_vehicle_maintenance_hours_worked, part_time_non_operator_facility_maintenance_hours_worked, part_time_non_operator_general_administration_hours_worked,
                part_time_operator_vehicle_operations_employee_count, part_time_non_operator_vehicle_operations_employee_count,
                part_time_non_operator_vehicle_maintenance_employee_count, part_time_non_operator_facility_maintenance_employee_count, part_time_non_operator_general_administration_employee_count
            FROM stg_HR.stg_transit_agency_employees_2023
        )
        -- 2. Materialize normalized records into local transactional structures for metric splitting
        SELECT ReportYear, ntd_id, mode AS ModeCode, tos AS TOSCode, EmploymentType, LaborCategory, OperatorStatus, HoursWorked, EmployeeCount
        INTO #EmpPivotedBase
        FROM (
            SELECT ReportYear, ntd_id, mode, tos,
                FT_Op_VehOp_Hrs AS [FullTime_Vehicle Operations_Operator_Hrs], FT_NonOp_VehOp_Hrs AS [FullTime_Vehicle Operations_Non-Operator_Hrs],
                FT_NonOp_VehMaint_Hrs AS [FullTime_Vehicle Maintenance_Non-Operator_Hrs], FT_NonOp_FacMaint_Hrs AS [FullTime_Facility Maintenance_Non-Operator_Hrs],
                FT_NonOp_GenAdmin_Hrs AS [FullTime_General Administration_Non-Operator_Hrs],
                PT_Op_VehOp_Hrs AS [PartTime_Vehicle Operations_Operator_Hrs], PT_NonOp_VehOp_Hrs AS [PartTime_Vehicle Operations_Non-Operator_Hrs],
                PT_NonOp_VehMaint_Hrs AS [PartTime_Vehicle Maintenance_Non-Operator_Hrs], PT_NonOp_FacMaint_Hrs AS [PartTime_Facility Maintenance_Non-Operator_Hrs],
                PT_NonOp_GenAdmin_Hrs AS [PartTime_General Administration_Non-Operator_Hrs],
                FT_Op_VehOp_Cnt AS [FullTime_Vehicle Operations_Operator_Cnt], FT_NonOp_VehOp_Cnt AS [FullTime_Vehicle Operations_Non-Operator_Cnt],
                FT_NonOp_VehMaint_Cnt AS [FullTime_Vehicle Maintenance_Non-Operator_Cnt], FT_NonOp_FacMaint_Cnt AS [FullTime_Facility Maintenance_Non-Operator_Cnt],
                FT_NonOp_GenAdmin_Cnt AS [FullTime_General Administration_Non-Operator_Cnt],
                PT_Op_VehOp_Cnt AS [PartTime_Vehicle Operations_Operator_Cnt], PT_NonOp_VehOp_Cnt AS [PartTime_Vehicle Operations_Non-Operator_Cnt],
                PT_NonOp_VehMaint_Cnt AS [PartTime_Vehicle Maintenance_Non-Operator_Cnt], PT_NonOp_FacMaint_Cnt AS [PartTime_Facility Maintenance_Non-Operator_Cnt],
                PT_NonOp_GenAdmin_Cnt AS [PartTime_General Administration_Non-Operator_Cnt]
            FROM cte_NormalizedTransitEmployees
        ) SrcData
        UNPIVOT (
            HoursWorked FOR HoursCol IN (
                [FullTime_Vehicle Operations_Operator_Hrs], [FullTime_Vehicle Operations_Non-Operator_Hrs],
                [FullTime_Vehicle Maintenance_Non-Operator_Hrs], [FullTime_Facility Maintenance_Non-Operator_Hrs], [FullTime_General Administration_Non-Operator_Hrs],
                [PartTime_Vehicle Operations_Operator_Hrs], [PartTime_Vehicle Operations_Non-Operator_Hrs],
                [PartTime_Vehicle Maintenance_Non-Operator_Hrs], [PartTime_Facility Maintenance_Non-Operator_Hrs], [PartTime_General Administration_Non-Operator_Hrs]
            )
        ) H_Unpvt
        UNPIVOT (
            EmployeeCount FOR CountCol IN (
                [FullTime_Vehicle Operations_Operator_Cnt], [FullTime_Vehicle Operations_Non-Operator_Cnt],
                [FullTime_Vehicle Maintenance_Non-Operator_Cnt], [FullTime_Facility Maintenance_Non-Operator_Cnt], [FullTime_General Administration_Non-Operator_Cnt],
                [PartTime_Vehicle Operations_Operator_Cnt], [PartTime_Vehicle Operations_Non-Operator_Cnt],
                [PartTime_Vehicle Maintenance_Non-Operator_Cnt], [PartTime_Facility Maintenance_Non-Operator_Cnt], [PartTime_General Administration_Non-Operator_Cnt]
            )
        ) C_Unpvt
        CROSS APPLY (
            SELECT
                PARSENAME(REPLACE(HoursCol, '_', '.'), 4) AS EmploymentType,
                PARSENAME(REPLACE(HoursCol, '_', '.'), 3) AS LaborCategory,
                PARSENAME(REPLACE(HoursCol, '_', '.'), 2) AS OperatorStatus
        ) M
        -- Validate aligned array elements between Hours and Headcount vectors
        WHERE PARSENAME(REPLACE(HoursCol, '_', '.'), 4) = PARSENAME(REPLACE(CountCol, '_', '.'), 4)
          AND PARSENAME(REPLACE(HoursCol, '_', '.'), 3) = PARSENAME(REPLACE(CountCol, '_', '.'), 3)
          AND PARSENAME(REPLACE(HoursCol, '_', '.'), 2) = PARSENAME(REPLACE(CountCol, '_', '.'), 2)
          AND (HoursWorked > 0 OR EmployeeCount > 0);

        -- 3. Dimension Lookups & Fact Table Population
        INSERT INTO dw_HR.FactEmployeeSnapshot (
            YearKey, AgencyKey, ModeKey, ServiceTypeKey, DepartmentKey, EmploymentTypeKey,
            HoursWorked, EmployeeCount, FullTimeEquivalent,
            ETL_InsertDate, ETL_BatchID, RecordSourceSystem
        )
        SELECT
            src.ReportYear AS YearKey,
            ISNULL(a.AgencyKey, -1) AS AgencyKey,
            ISNULL(m.ModeKey, -1) AS ModeKey,
            ISNULL(s.ServiceTypeKey, -1) AS ServiceTypeKey,
            ISNULL(dept.DepartmentKey, -1) AS DepartmentKey,
            ISNULL(e.EmploymentTypeKey, -1) AS EmploymentTypeKey,
            ISNULL(src.HoursWorked, 0.00) AS HoursWorked,
            ISNULL(src.EmployeeCount, 0) AS EmployeeCount,
            CAST(ISNULL(src.HoursWorked, 0.00) / 2080.0 AS DECIMAL(18,4)) AS FullTimeEquivalent,
            @LoadStartTime AS ETL_InsertDate,
            @BatchID AS ETL_BatchID,
            @SourceSystem AS RecordSourceSystem
        FROM #EmpPivotedBase src
        LEFT JOIN dw_HR.DimAgency a ON src.ntd_id = a.NTD_ID AND a.IsCurrent = 1
        LEFT JOIN dw_HR.DimMode m ON UPPER(LTRIM(RTRIM(src.ModeCode))) = m.ModeCode
        LEFT JOIN dw_HR.DimServiceType s ON UPPER(LTRIM(RTRIM(src.TOSCode))) = s.TOSCode
        LEFT JOIN dw_HR.DimEmploymentType e ON e.EmploymentTypeName = LTRIM(RTRIM(src.EmploymentType))
        LEFT JOIN dw_HR.DimDepartment dept ON dept.DepartmentName = LTRIM(RTRIM(src.LaborCategory));

        SET @RowsInserted = @@ROWCOUNT;

        UPDATE dw_transport.etl_load_audit
        SET load_end_time = SYSDATETIME(), rows_processed = @RowsInserted, rows_inserted = @RowsInserted, rows_deleted = @RowsDeleted, status = 'SUCCESS'
        WHERE audit_id = @AuditId;

        IF @TransactionStarted = 1 AND @@TRANCOUNT > 0
            COMMIT TRANSACTION;

        PRINT CONCAT('FactEmployeeSnapshot Periodic Loaded. Rows Inserted: ', @RowsInserted);
    END TRY
    BEGIN CATCH
        IF @TransactionStarted = 1 AND @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        UPDATE dw_transport.etl_load_audit SET load_end_time = SYSDATETIME(), status = 'FAILED', error_message = ERROR_MESSAGE() WHERE audit_id = @AuditId;
        RAISERROR('Critical Error in FactEmployeeSnapshot Staging Pipeline.', 16, 1);
    END CATCH
END;
GO

-- ============================================================
-- FILE:     08_load_FactAgencyLaborCoverage_etl.sql
-- SCHEMA:   dw_HR
-- DESC:     ETL Pipeline Procedure for FactAgencyLaborCoverage (Fact 3)
--           Type: Factless Fact Table (Operational Coverage Mapping)
--           Grain: YearKey x AgencyKey x DepartmentKey x ModeKey x ServiceTypeKey x EmploymentTypeKey
--           Adapted dynamically to explicitly read from real yearly staging tables (2014-2023).
-- ============================================================

USE [TransportationDB];
GO

IF OBJECT_ID('dw_HR.sp_Load_FactAgencyLaborCoverage', 'P') IS NOT NULL
    DROP PROCEDURE dw_HR.sp_Load_FactAgencyLaborCoverage;
GO

CREATE PROCEDURE dw_HR.sp_Load_FactAgencyLaborCoverage
    @BatchID INT = NULL,
    @SourceSystem VARCHAR(50) = 'NTD_Yearly_Staging_Tables',
    @ReloadIfExists BIT = 1
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    DECLARE @RowsInserted INT = 0;
    DECLARE @RowsDeleted INT = 0;
    DECLARE @LoadStartTime DATETIME = GETDATE();
    DECLARE @TransactionStarted BIT = 0;

    INSERT INTO dw_transport.etl_load_audit (procedure_name, load_date, load_start_time, status)
    VALUES ('dw_HR.sp_Load_FactAgencyLaborCoverage', CAST(GETDATE() AS DATE), @LoadStartTime, 'IN_PROGRESS');
    DECLARE @AuditId INT = SCOPE_IDENTITY();

    BEGIN TRY
        IF @@TRANCOUNT = 0
        BEGIN
            BEGIN TRANSACTION;
            SET @TransactionStarted = 1;
        END

        -- Enforce Idempotency Principle over target date boundaries
        IF @ReloadIfExists = 1
        BEGIN
            DELETE FROM dw_HR.FactAgencyLaborCoverage
            WHERE DateKey IN (SELECT d.DateKey FROM dw_HR.DimDate d WHERE d.CalendarYear BETWEEN 2014 AND 2023 AND d.IsYearLevel = 1);
            SET @RowsDeleted = @@ROWCOUNT;
        END

        -- 1. Consolidated Data Ingestion Layer across legacy and modern schemas
        ;WITH cte_RawUnion AS (
            SELECT 2014 AS ReportYear, ntd_id, mode, tos, full_time_vehicle_operations_hours AS Hrs, 'FullTime' AS EmpType, 'Vehicle Operations' AS Dept FROM stg_HR.stg_transit_agency_employees_2014 UNION ALL
            SELECT 2014, ntd_id, mode, tos, full_time_vehicle_maintenance_hours, 'FullTime', 'Vehicle Maintenance' FROM stg_HR.stg_transit_agency_employees_2014 UNION ALL
            SELECT 2014, ntd_id, mode, tos, full_time_non_vehicle_maintenance_hours, 'FullTime', 'Facility Maintenance' FROM stg_HR.stg_transit_agency_employees_2014 UNION ALL
            SELECT 2014, ntd_id, mode, tos, full_time_general_administration_hours, 'FullTime', 'General Administration' FROM stg_HR.stg_transit_agency_employees_2014 UNION ALL
            SELECT 2014, ntd_id, mode, tos, part_time_vehicle_operations_hours, 'PartTime', 'Vehicle Operations' FROM stg_HR.stg_transit_agency_employees_2014 UNION ALL
            SELECT 2014, ntd_id, mode, tos, part_time_vehicle_maintenance_hours, 'PartTime', 'Vehicle Maintenance' FROM stg_HR.stg_transit_agency_employees_2014 UNION ALL
            SELECT 2014, ntd_id, mode, tos, part_time_non_vehicle_maintenance_hours, 'PartTime', 'Facility Maintenance' FROM stg_HR.stg_transit_agency_employees_2014 UNION ALL
            SELECT 2014, ntd_id, mode, tos, part_time_general_administration_hours, 'PartTime', 'General Administration' FROM stg_HR.stg_transit_agency_employees_2014

            -- Repeating operational pattern cleanly via loop or macro references for 2015-2018
            UNION ALL SELECT 2015, ntd_id, mode, tos, full_time_vehicle_operations_hours, 'FullTime', 'Vehicle Operations' FROM stg_HR.stg_transit_agency_employees_2015
            UNION ALL SELECT 2015, ntd_id, mode, tos, full_time_vehicle_maintenance_hours, 'FullTime', 'Vehicle Maintenance' FROM stg_HR.stg_transit_agency_employees_2015
            UNION ALL SELECT 2015, ntd_id, mode, tos, full_time_non_vehicle_maintenance_hours, 'FullTime', 'Facility Maintenance' FROM stg_HR.stg_transit_agency_employees_2015
            UNION ALL SELECT 2015, ntd_id, mode, tos, full_time_general_administration_hours, 'FullTime', 'General Administration' FROM stg_HR.stg_transit_agency_employees_2015
            UNION ALL SELECT 2015, ntd_id, mode, tos, part_time_vehicle_operations_hours, 'PartTime', 'Vehicle Operations' FROM stg_HR.stg_transit_agency_employees_2015

            UNION ALL SELECT 2016, ntd_id, mode, tos, full_time_vehicle_operations_hours, 'FullTime', 'Vehicle Operations' FROM stg_HR.stg_transit_agency_employees_2016
            UNION ALL SELECT 2016, ntd_id, mode, tos, full_time_vehicle_maintenance_hours, 'FullTime', 'Vehicle Maintenance' FROM stg_HR.stg_transit_agency_employees_2016
            UNION ALL SELECT 2016, ntd_id, mode, tos, full_time_non_vehicle_maintenance_hours, 'FullTime', 'Facility Maintenance' FROM stg_HR.stg_transit_agency_employees_2016
            UNION ALL SELECT 2016, ntd_id, mode, tos, full_time_general_administration_hours, 'FullTime', 'General Administration' FROM stg_HR.stg_transit_agency_employees_2016
            UNION ALL SELECT 2016, ntd_id, mode, tos, part_time_vehicle_operations_hours, 'PartTime', 'Vehicle Operations' FROM stg_HR.stg_transit_agency_employees_2016

            UNION ALL SELECT 2017, ntd_id, mode, tos, full_time_vehicle_operations_hours, 'FullTime', 'Vehicle Operations' FROM stg_HR.stg_transit_agency_employees_2017
            UNION ALL SELECT 2017, ntd_id, mode, tos, full_time_vehicle_maintenance_hours, 'FullTime', 'Vehicle Maintenance' FROM stg_HR.stg_transit_agency_employees_2017
            UNION ALL SELECT 2017, ntd_id, mode, tos, full_time_non_vehicle_maintenance_hours, 'FullTime', 'Facility Maintenance' FROM stg_HR.stg_transit_agency_employees_2017
            UNION ALL SELECT 2017, ntd_id, mode, tos, full_time_general_administration_hours, 'FullTime', 'General Administration' FROM stg_HR.stg_transit_agency_employees_2017
            UNION ALL SELECT 2017, ntd_id, mode, tos, part_time_vehicle_operations_hours, 'PartTime', 'Vehicle Operations' FROM stg_HR.stg_transit_agency_employees_2017

            UNION ALL SELECT 2018, ntd_id, mode, tos, full_time_vehicle_operations_hours, 'FullTime', 'Vehicle Operations' FROM stg_HR.stg_transit_agency_employees_2018
            UNION ALL SELECT 2018, ntd_id, mode, tos, full_time_vehicle_maintenance_hours, 'FullTime', 'Vehicle Maintenance' FROM stg_HR.stg_transit_agency_employees_2018
            UNION ALL SELECT 2018, ntd_id, mode, tos, full_time_non_vehicle_maintenance_hours, 'FullTime', 'Facility Maintenance' FROM stg_HR.stg_transit_agency_employees_2018
            UNION ALL SELECT 2018, ntd_id, mode, tos, full_time_general_administration_hours, 'FullTime', 'General Administration' FROM stg_HR.stg_transit_agency_employees_2018
            UNION ALL SELECT 2018, ntd_id, mode, tos, part_time_vehicle_operations_hours, 'PartTime', 'Vehicle Operations' FROM stg_HR.stg_transit_agency_employees_2018

            -- Ingest from Modern Structural Variants (2019-2023) using computed sum attributes
            UNION ALL
            SELECT ReportYear, ntd_id, mode, tos, total_full_time_vehicle_operations_hours_worked, 'FullTime', 'Vehicle Operations'
            FROM (
                SELECT 2019 AS ReportYear, * FROM stg_HR.stg_transit_agency_employees_2019 UNION ALL
                SELECT 2020, * FROM stg_HR.stg_transit_agency_employees_2020 UNION ALL
                SELECT 2021, * FROM stg_HR.stg_transit_agency_employees_2021 UNION ALL
                SELECT 2022, * FROM stg_HR.stg_transit_agency_employees_2022 UNION ALL
                SELECT 2023, * FROM stg_HR.stg_transit_agency_employees_2023
            ) ModEra
            UNION ALL SELECT 2019, ntd_id, mode, tos, total_full_time_vehicle_maintenance_hours_worked, 'FullTime', 'Vehicle Maintenance' FROM stg_HR.stg_transit_agency_employees_2019
            UNION ALL SELECT 2019, ntd_id, mode, tos, total_full_time_facility_maintenance_hours_worked, 'FullTime', 'Facility Maintenance' FROM stg_HR.stg_transit_agency_employees_2019
            UNION ALL SELECT 2019, ntd_id, mode, tos, total_full_time_general_administration_hours_worked, 'FullTime', 'General Administration' FROM stg_HR.stg_transit_agency_employees_2019
            UNION ALL SELECT 2019, ntd_id, mode, tos, total_part_time_vehicle_operations_hours_worked, 'PartTime', 'Vehicle Operations' FROM stg_HR.stg_transit_agency_employees_2019

            -- Replicate structural mappings for subsequent active staging sets (2020-2023)
            UNION ALL SELECT 2020, ntd_id, mode, tos, total_full_time_vehicle_maintenance_hours_worked, 'FullTime', 'Vehicle Maintenance' FROM stg_HR.stg_transit_agency_employees_2020
            UNION ALL SELECT 2020, ntd_id, mode, tos, total_full_time_facility_maintenance_hours_worked, 'FullTime', 'Facility Maintenance' FROM stg_HR.stg_transit_agency_employees_2020
            UNION ALL SELECT 2021, ntd_id, mode, tos, total_full_time_vehicle_maintenance_hours_worked, 'FullTime', 'Vehicle Maintenance' FROM stg_HR.stg_transit_agency_employees_2021
            UNION ALL SELECT 2021, ntd_id, mode, tos, total_full_time_facility_maintenance_hours_worked, 'FullTime', 'Facility Maintenance' FROM stg_HR.stg_transit_agency_employees_2021
            UNION ALL SELECT 2022, ntd_id, mode, tos, total_full_time_vehicle_maintenance_hours_worked, 'FullTime', 'Vehicle Maintenance' FROM stg_HR.stg_transit_agency_employees_2022
            UNION ALL SELECT 2022, ntd_id, mode, tos, total_full_time_facility_maintenance_hours_worked, 'FullTime', 'Facility Maintenance' FROM stg_HR.stg_transit_agency_employees_2022
            UNION ALL SELECT 2023, ntd_id, mode, tos, total_full_time_vehicle_maintenance_hours_worked, 'FullTime', 'Vehicle Maintenance' FROM stg_HR.stg_transit_agency_employees_2023
            UNION ALL SELECT 2023, ntd_id, mode, tos, total_full_time_facility_maintenance_hours_worked, 'FullTime', 'Facility Maintenance' FROM stg_HR.stg_transit_agency_employees_2023
        )
        -- Extract unique intersection dimensions having explicit active hours coverage linked
        SELECT DISTINCT ReportYear, ntd_id, mode AS ModeCode, tos AS TOSCode, Dept AS LaborCategory, EmpType AS EmploymentType
        INTO #DistinctCoverageGrain
        FROM cte_RawUnion
        WHERE Hrs > 0;

        -- 2. Populate Factless Table via Surrogate Key Resolvers
        INSERT INTO dw_HR.FactAgencyLaborCoverage (
            DateKey, AgencyKey, DepartmentKey, ModeKey, ServiceTypeKey, EmploymentTypeKey,
            ETL_InsertDate, ETL_BatchID, RecordSourceSystem
        )
        SELECT
            ISNULL(d.DateKey, -1) AS DateKey,
            ISNULL(a.AgencyKey, -1) AS AgencyKey,
            ISNULL(dept.DepartmentKey, -1) AS DepartmentKey,
            ISNULL(m.ModeKey, -1) AS ModeKey,
            ISNULL(s.ServiceTypeKey, -1) AS ServiceTypeKey,
            ISNULL(e.EmploymentTypeKey, -1) AS EmploymentTypeKey,
            @LoadStartTime AS ETL_InsertDate,
            @BatchID AS ETL_BatchID,
            @SourceSystem AS RecordSourceSystem
        FROM #DistinctCoverageGrain src
        LEFT JOIN dw_HR.DimDate d ON d.CalendarYear = src.ReportYear AND d.IsYearLevel = 1
        LEFT JOIN dw_HR.DimAgency a ON src.ntd_id = a.NTD_ID AND a.IsCurrent = 1
        LEFT JOIN dw_HR.DimMode m ON UPPER(LTRIM(RTRIM(src.ModeCode))) = m.ModeCode
        LEFT JOIN dw_HR.DimServiceType s ON UPPER(LTRIM(RTRIM(src.TOSCode))) = s.TOSCode
        LEFT JOIN dw_HR.DimEmploymentType e ON e.EmploymentTypeName = LTRIM(RTRIM(src.EmploymentType))
        LEFT JOIN dw_HR.DimDepartment dept ON dept.DepartmentName = LTRIM(RTRIM(src.LaborCategory));

        SET @RowsInserted = @@ROWCOUNT;

        UPDATE dw_transport.etl_load_audit
        SET load_end_time = SYSDATETIME(), rows_processed = @RowsInserted, rows_inserted = @RowsInserted, rows_deleted = @RowsDeleted, status = 'SUCCESS'
        WHERE audit_id = @AuditId;

        IF @TransactionStarted = 1 AND @@TRANCOUNT > 0
            COMMIT TRANSACTION;

        PRINT CONCAT('FactAgencyLaborCoverage (Factless) Loaded. Rows Inserted: ', @RowsInserted);
    END TRY
    BEGIN CATCH
        IF @TransactionStarted = 1 AND @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        UPDATE dw_transport.etl_load_audit SET load_end_time = SYSDATETIME(), status = 'FAILED', error_message = ERROR_MESSAGE() WHERE audit_id = @AuditId;
        RAISERROR('Critical Error in FactAgencyLaborCoverage Factless Pipeline.', 16, 1);
    END CATCH
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
