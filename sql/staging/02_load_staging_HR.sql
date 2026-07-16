-- ============================================================
-- Clean out staging for a fresh load (Truncate and Load pattern)
-- Mart: HR Mart (Kimball Methodology)
-- ============================================================
TRUNCATE TABLE stg_HR.stg_transit_agency_employees_2014;
TRUNCATE TABLE stg_HR.stg_transit_agency_employees_2015;
TRUNCATE TABLE stg_HR.stg_transit_agency_employees_2016;
TRUNCATE TABLE stg_HR.stg_transit_agency_employees_2017;
TRUNCATE TABLE stg_HR.stg_transit_agency_employees_2018;
TRUNCATE TABLE stg_HR.stg_transit_agency_employees_2019;
TRUNCATE TABLE stg_HR.stg_transit_agency_employees_2020;
TRUNCATE TABLE stg_HR.stg_transit_agency_employees_2021;
TRUNCATE TABLE stg_HR.stg_transit_agency_employees_2022;
TRUNCATE TABLE stg_HR.stg_transit_agency_employees_2023;
TRUNCATE TABLE stg_HR.stg_transit_agency_employees_2024;
TRUNCATE TABLE stg_HR.stg_job_openings;

-- ============================================================
-- 1. Load Employees Data for Years 2014 - 2016
-- ============================================================

-- 2014 Data
INSERT INTO stg_HR.stg_transit_agency_employees_2014 (
    ntd_id, reporter_name, reporter_type, mode, tos,
    full_time_vehicle_operations_hours, full_time_vehicle_maintenance_hours, full_time_non_vehicle_maintenance_hours, full_time_general_administration_hours, full_time_total_operating_labor_hours, full_time_total_capital_labor_hours, full_time_total_labor_hours,
    full_time_vehicle_operations_employee_count, full_time_vehicle_maintenance_employee_count, full_time_non_vehicle_maintenance_employee_count, full_time_general_administration_employee_count, full_time_total_operating_labor_employee_count, full_time_total_capital_labor_employee_count, full_time_total_labor_employee_count,
    part_time_vehicle_operations_hours, part_time_vehicle_maintenance_hours, part_time_non_vehicle_maintenance_hours, part_time_general_administration_hours, part_time_total_operating_labor_hours, part_time_total_capital_labor_hours, part_time_total_labor_hours,
    part_time_vehicle_operations_employee_count, part_time_vehicle_maintenance_employee_count, part_time_non_vehicle_maintenance_employee_count, part_time_general_administration_employee_count, part_time_total_operating_labor_employee_count, part_time_total_capital_labor_employee_count, part_time_total_labor_employee_count
)
SELECT
    CAST(TRY_CAST(NULLIF(REPLACE(TRIM([5 Digit NTD ID]), ',', ''), '') AS NUMERIC(18,0)) AS VARCHAR(50)),
    [Agency Name],
    [Reporter Type],
    [Mode],
    [TOS],

    TRY_CAST(TRY_CAST(NULLIF(REPLACE(TRIM([Full Time Vehicle Operations Hours Worked]), ',', ''), '') AS NUMERIC(18,2)) AS INT),
    TRY_CAST(TRY_CAST(NULLIF(REPLACE(TRIM([Full Time Vehicle Maintenance Hours Worked]), ',', ''), '') AS NUMERIC(18,2)) AS INT),
    TRY_CAST(TRY_CAST(NULLIF(REPLACE(TRIM([Full Time Non-Vehicle Maintenance Hours Worked]), ',', ''), '') AS NUMERIC(18,2)) AS INT),
    TRY_CAST(TRY_CAST(NULLIF(REPLACE(TRIM([Full Time General Administration Maintenance Hours Worked]), ',', ''), '') AS NUMERIC(18,2)) AS INT),
    TRY_CAST(TRY_CAST(NULLIF(REPLACE(TRIM([Total Full Time Operating Labor Hours Worked]), ',', ''), '') AS NUMERIC(18,2)) AS INT),
    TRY_CAST(TRY_CAST(NULLIF(REPLACE(TRIM([Total Full Time Capital Labor Hours Worked]), ',', ''), '') AS NUMERIC(18,2)) AS INT),
    TRY_CAST(TRY_CAST(NULLIF(REPLACE(TRIM([Total Full Time Hours Worked]), ',', ''), '') AS NUMERIC(18,2)) AS INT),

    TRY_CAST(NULLIF(REPLACE(TRIM([Full Time Vehicle Operations Employee Count]), ',', ''), '') AS NUMERIC(18,2)),
    TRY_CAST(NULLIF(REPLACE(TRIM([Full Time Vehicle Maintenance Employee Count]), ',', ''), '') AS NUMERIC(18,2)),
    TRY_CAST(NULLIF(REPLACE(TRIM([Full Time Non-Vehicle Maintenance Employee Count]), ',', ''), '') AS NUMERIC(18,2)),
    TRY_CAST(NULLIF(REPLACE(TRIM([Full Time General Administration Employee Count]), ',', ''), '') AS NUMERIC(18,2)),
    TRY_CAST(NULLIF(REPLACE(TRIM([Total Full Time Operating Employee Count]), ',', ''), '') AS NUMERIC(18,2)),
    TRY_CAST(NULLIF(REPLACE(TRIM([Total Full Time Capital Employee Count]), ',', ''), '') AS NUMERIC(18,2)),
    TRY_CAST(NULLIF(REPLACE(TRIM([Total Full Time Employee Count]), ',', ''), '') AS NUMERIC(18,2)),

    TRY_CAST(TRY_CAST(NULLIF(REPLACE(TRIM([Part Time Vehicle Operations Hours Worked]), ',', ''), '') AS NUMERIC(18,2)) AS INT),
    TRY_CAST(TRY_CAST(NULLIF(REPLACE(TRIM([Part Time Vehicle Maintenance Hours Worked]), ',', ''), '') AS NUMERIC(18,2)) AS INT),
    TRY_CAST(TRY_CAST(NULLIF(REPLACE(TRIM([Part Time Non-Vehicle Maintenance Hours Worked]), ',', ''), '') AS NUMERIC(18,2)) AS INT),
    TRY_CAST(TRY_CAST(NULLIF(REPLACE(TRIM([Part Time General Administration Hours Worked]), ',', ''), '') AS NUMERIC(18,2)) AS INT),
    TRY_CAST(TRY_CAST(NULLIF(REPLACE(TRIM([Total Part Time Operating Labor Hours Worked]), ',', ''), '') AS NUMERIC(18,2)) AS INT),
    TRY_CAST(TRY_CAST(NULLIF(REPLACE(TRIM([Total Part Time Capital Labor Hours Worked]), ',', ''), '') AS NUMERIC(18,2)) AS INT),
    TRY_CAST(TRY_CAST(NULLIF(REPLACE(TRIM([Total Part Time Hours Worked]), ',', ''), '') AS NUMERIC(18,2)) AS INT),

    TRY_CAST(NULLIF(REPLACE(TRIM([Part Time Vehicle Operations Employee Count]), ',', ''), '') AS NUMERIC(18,2)),
    TRY_CAST(NULLIF(REPLACE(TRIM([Part Time Vehicle Maintenance Employee Count]), ',', ''), '') AS NUMERIC(18,2)),
    TRY_CAST(NULLIF(REPLACE(TRIM([Part Time Non-Vehicle Maintenance Employee Count]), ',', ''), '') AS NUMERIC(18,2)),
    TRY_CAST(NULLIF(REPLACE(TRIM([Part Time General Administration Employee Count]), ',', ''), '') AS NUMERIC(18,2)),
    TRY_CAST(NULLIF(REPLACE(TRIM([Total Part Time Operating Employee Count]), ',', ''), '') AS NUMERIC(18,2)),
    TRY_CAST(NULLIF(REPLACE(TRIM([Total Part Time Capital Employee Count]), ',', ''), '') AS NUMERIC(18,2)),
    TRY_CAST(NULLIF(REPLACE(TRIM([Total Part Time Employee Count]), ',', ''), '') AS NUMERIC(18,2))
FROM raw_HR.raw_2014_transit_agency_employees;

-- 2015 Data
INSERT INTO stg_HR.stg_transit_agency_employees_2015 (
    ntd_id, reporter_name, reporter_type, mode, tos,
    full_time_vehicle_operations_hours, full_time_vehicle_maintenance_hours, full_time_non_vehicle_maintenance_hours, full_time_general_administration_hours, full_time_total_operating_labor_hours, full_time_total_capital_labor_hours, full_time_total_labor_hours,
    full_time_vehicle_operations_employee_count, full_time_vehicle_maintenance_employee_count, full_time_non_vehicle_maintenance_employee_count, full_time_general_administration_employee_count, full_time_total_operating_labor_employee_count, full_time_total_capital_labor_employee_count, full_time_total_labor_employee_count,
    part_time_vehicle_operations_hours, part_time_vehicle_maintenance_hours, part_time_non_vehicle_maintenance_hours, part_time_general_administration_hours, part_time_total_operating_labor_hours, part_time_total_capital_labor_hours, part_time_total_labor_hours,
    part_time_vehicle_operations_employee_count, part_time_vehicle_maintenance_employee_count, part_time_non_vehicle_maintenance_employee_count, part_time_general_administration_employee_count, part_time_total_operating_labor_employee_count, part_time_total_capital_labor_employee_count, part_time_total_labor_employee_count
)
SELECT
    CAST(TRY_CAST(NULLIF(REPLACE(TRIM([5 Digit NTD ID]), ',', ''), '') AS NUMERIC(18,0)) AS VARCHAR(50)),
    [Agency Name],
    [Reporter Type],
    [Mode],
    [TOS],

    TRY_CAST(TRY_CAST(NULLIF(REPLACE(TRIM([Full Time Vehicle Operations Hours Worked]), ',', ''), '') AS NUMERIC(18,2)) AS INT),
    TRY_CAST(TRY_CAST(NULLIF(REPLACE(TRIM([Full Time Vehicle Maintenance Hours Worked]), ',', ''), '') AS NUMERIC(18,2)) AS INT),
    TRY_CAST(TRY_CAST(NULLIF(REPLACE(TRIM([Full Time Non-Vehicle Maintenance Hours Worked]), ',', ''), '') AS NUMERIC(18,2)) AS INT),
    TRY_CAST(TRY_CAST(NULLIF(REPLACE(TRIM([Full Time General Administration Maintenance Hours Worked]), ',', ''), '') AS NUMERIC(18,2)) AS INT),
    TRY_CAST(TRY_CAST(NULLIF(REPLACE(TRIM([Total Full Time Operating Labor Hours Worked]), ',', ''), '') AS NUMERIC(18,2)) AS INT),
    TRY_CAST(TRY_CAST(NULLIF(REPLACE(TRIM([Total Full Time Capital Labor Hours Worked]), ',', ''), '') AS NUMERIC(18,2)) AS INT),
    TRY_CAST(TRY_CAST(NULLIF(REPLACE(TRIM([Total Full Time Hours Worked]), ',', ''), '') AS NUMERIC(18,2)) AS INT),

    TRY_CAST(NULLIF(REPLACE(TRIM([Full Time Vehicle Operations Employee Count]), ',', ''), '') AS NUMERIC(18,2)),
    TRY_CAST(NULLIF(REPLACE(TRIM([Full Time Vehicle Maintenance Employee Count]), ',', ''), '') AS NUMERIC(18,2)),
    TRY_CAST(NULLIF(REPLACE(TRIM([Full Time Non-Vehicle Maintenance Employee Count]), ',', ''), '') AS NUMERIC(18,2)),
    TRY_CAST(NULLIF(REPLACE(TRIM([Full Time General Administration Employee Count]), ',', ''), '') AS NUMERIC(18,2)),
    TRY_CAST(NULLIF(REPLACE(TRIM([Total Full Time Operating Employee Count]), ',', ''), '') AS NUMERIC(18,2)),
    TRY_CAST(NULLIF(REPLACE(TRIM([Total Full Time Capital Employee Count]), ',', ''), '') AS NUMERIC(18,2)),
    TRY_CAST(NULLIF(REPLACE(TRIM([Total Full Time Employee Count]), ',', ''), '') AS NUMERIC(18,2)),

    TRY_CAST(TRY_CAST(NULLIF(REPLACE(TRIM([Part Time Vehicle Operations Hours Worked]), ',', ''), '') AS NUMERIC(18,2)) AS INT),
    TRY_CAST(TRY_CAST(NULLIF(REPLACE(TRIM([Part Time Vehicle Maintenance Hours Worked]), ',', ''), '') AS NUMERIC(18,2)) AS INT),
    TRY_CAST(TRY_CAST(NULLIF(REPLACE(TRIM([Part Time Non-Vehicle Maintenance Hours Worked]), ',', ''), '') AS NUMERIC(18,2)) AS INT),
    TRY_CAST(TRY_CAST(NULLIF(REPLACE(TRIM([Part Time General Administration Hours Worked]), ',', ''), '') AS NUMERIC(18,2)) AS INT),
    TRY_CAST(TRY_CAST(NULLIF(REPLACE(TRIM([Total Part Time Operating Labor Hours Worked]), ',', ''), '') AS NUMERIC(18,2)) AS INT),
    TRY_CAST(TRY_CAST(NULLIF(REPLACE(TRIM([Total Part Time Capital Labor Hours Worked]), ',', ''), '') AS NUMERIC(18,2)) AS INT),
    TRY_CAST(TRY_CAST(NULLIF(REPLACE(TRIM([Total Part Time Hours Worked]), ',', ''), '') AS NUMERIC(18,2)) AS INT),

    TRY_CAST(NULLIF(REPLACE(TRIM([Part Time Vehicle Operations Employee Count]), ',', ''), '') AS NUMERIC(18,2)),
    TRY_CAST(NULLIF(REPLACE(TRIM([Part Time Vehicle Maintenance Employee Count]), ',', ''), '') AS NUMERIC(18,2)),
    TRY_CAST(NULLIF(REPLACE(TRIM([Part Time Non-Vehicle Maintenance Employee Count]), ',', ''), '') AS NUMERIC(18,2)),
    TRY_CAST(NULLIF(REPLACE(TRIM([Part Time General Administration Employee Count]), ',', ''), '') AS NUMERIC(18,2)),
    TRY_CAST(NULLIF(REPLACE(TRIM([Total Part Time Operating Employee Count]), ',', ''), '') AS NUMERIC(18,2)),
    TRY_CAST(NULLIF(REPLACE(TRIM([Total Part Time Capital Employee Count]), ',', ''), '') AS NUMERIC(18,2)),
    TRY_CAST(NULLIF(REPLACE(TRIM([Total Part Time Employee Count]), ',', ''), '') AS NUMERIC(18,2))
FROM raw_HR.raw_2015_transit_agency_employee;

-- 2016 Data
INSERT INTO stg_HR.stg_transit_agency_employees_2016 (
    ntd_id, reporter_name, reporter_type, mode, tos,
    full_time_vehicle_operations_hours, full_time_vehicle_maintenance_hours, full_time_non_vehicle_maintenance_hours, full_time_general_administration_hours, full_time_total_operating_labor_hours, full_time_total_capital_labor_hours, full_time_total_labor_hours,
    full_time_vehicle_operations_employee_count, full_time_vehicle_maintenance_employee_count, full_time_non_vehicle_maintenance_employee_count, full_time_general_administration_employee_count, full_time_total_operating_labor_employee_count, full_time_total_capital_labor_employee_count, full_time_total_labor_employee_count,
    part_time_vehicle_operations_hours, part_time_vehicle_maintenance_hours, part_time_non_vehicle_maintenance_hours, part_time_general_administration_hours, part_time_total_operating_labor_hours, part_time_total_capital_labor_hours, part_time_total_labor_hours,
    part_time_vehicle_operations_employee_count, part_time_vehicle_maintenance_employee_count, part_time_non_vehicle_maintenance_employee_count, part_time_general_administration_employee_count, part_time_total_operating_labor_employee_count, part_time_total_capital_labor_employee_count, part_time_total_labor_employee_count
)
SELECT
    CAST(TRY_CAST(NULLIF(REPLACE(TRIM([5 Digit NTD ID]), ',', ''), '') AS NUMERIC(18,0)) AS VARCHAR(50)),
    [Agency Name],
    [Reporter Type],
    [Mode],
    [TOS],

    TRY_CAST(TRY_CAST(NULLIF(REPLACE(TRIM([Full Time Vehicle Operations Hours Worked]), ',', ''), '') AS NUMERIC(18,2)) AS INT),
    TRY_CAST(TRY_CAST(NULLIF(REPLACE(TRIM([Full Time Vehicle Maintenance Hours Worked]), ',', ''), '') AS NUMERIC(18,2)) AS INT),
    TRY_CAST(TRY_CAST(NULLIF(REPLACE(TRIM([Full Time Non-Vehicle Maintenance Hours Worked]), ',', ''), '') AS NUMERIC(18,2)) AS INT),
    TRY_CAST(TRY_CAST(NULLIF(REPLACE(TRIM([Full Time General Administration Maintenance Hours Worked]), ',', ''), '') AS NUMERIC(18,2)) AS INT),
    TRY_CAST(TRY_CAST(NULLIF(REPLACE(TRIM([Total Full Time Operating Labor Hours Worked]), ',', ''), '') AS NUMERIC(18,2)) AS INT),
    TRY_CAST(TRY_CAST(NULLIF(REPLACE(TRIM([Total Full Time Capital Labor Hours Worked]), ',', ''), '') AS NUMERIC(18,2)) AS INT),
    TRY_CAST(TRY_CAST(NULLIF(REPLACE(TRIM([Total Full Time Hours Worked]), ',', ''), '') AS NUMERIC(18,2)) AS INT),

    TRY_CAST(NULLIF(REPLACE(TRIM([Full Time Vehicle Operations Employee Count]), ',', ''), '') AS NUMERIC(18,2)),
    TRY_CAST(NULLIF(REPLACE(TRIM([Full Time Vehicle Maintenance Employee Count]), ',', ''), '') AS NUMERIC(18,2)),
    TRY_CAST(NULLIF(REPLACE(TRIM([Full Time Non-Vehicle Maintenance Employee Count]), ',', ''), '') AS NUMERIC(18,2)),
    TRY_CAST(NULLIF(REPLACE(TRIM([Full Time General Administration Employee Count]), ',', ''), '') AS NUMERIC(18,2)),
    TRY_CAST(NULLIF(REPLACE(TRIM([Total Full Time Operating Employee Count]), ',', ''), '') AS NUMERIC(18,2)),
    TRY_CAST(NULLIF(REPLACE(TRIM([Total Full Time Capital Employee Count]), ',', ''), '') AS NUMERIC(18,2)),
    TRY_CAST(NULLIF(REPLACE(TRIM([Total Full Time Employee Count]), ',', ''), '') AS NUMERIC(18,2)),

    TRY_CAST(TRY_CAST(NULLIF(REPLACE(TRIM([Part Time Vehicle Operations Hours Worked]), ',', ''), '') AS NUMERIC(18,2)) AS INT),
    TRY_CAST(TRY_CAST(NULLIF(REPLACE(TRIM([Part Time Vehicle Maintenance Hours Worked]), ',', ''), '') AS NUMERIC(18,2)) AS INT),
    TRY_CAST(TRY_CAST(NULLIF(REPLACE(TRIM([Part Time Non-Vehicle Maintenance Hours Worked]), ',', ''), '') AS NUMERIC(18,2)) AS INT),
    TRY_CAST(TRY_CAST(NULLIF(REPLACE(TRIM([Part Time General Administration Hours Worked]), ',', ''), '') AS NUMERIC(18,2)) AS INT),
    TRY_CAST(TRY_CAST(NULLIF(REPLACE(TRIM([Total Part Time Operating Labor Hours Worked]), ',', ''), '') AS NUMERIC(18,2)) AS INT),
    TRY_CAST(TRY_CAST(NULLIF(REPLACE(TRIM([Total Part Time Capital Labor Hours Worked]), ',', ''), '') AS NUMERIC(18,2)) AS INT),
    TRY_CAST(TRY_CAST(NULLIF(REPLACE(TRIM([Total Part Time Hours Worked]), ',', ''), '') AS NUMERIC(18,2)) AS INT),

    TRY_CAST(NULLIF(REPLACE(TRIM([Part Time Vehicle Operations Employee Count]), ',', ''), '') AS NUMERIC(18,2)),
    TRY_CAST(NULLIF(REPLACE(TRIM([Part Time Vehicle Maintenance Employee Count]), ',', ''), '') AS NUMERIC(18,2)),
    TRY_CAST(NULLIF(REPLACE(TRIM([Part Time Non-Vehicle Maintenance Employee Count]), ',', ''), '') AS NUMERIC(18,2)),
    TRY_CAST(NULLIF(REPLACE(TRIM([Part Time General Administration Employee Count]), ',', ''), '') AS NUMERIC(18,2)),
    TRY_CAST(NULLIF(REPLACE(TRIM([Total Part Time Operating Employee Count]), ',', ''), '') AS NUMERIC(18,2)),
    TRY_CAST(NULLIF(REPLACE(TRIM([Total Part Time Capital Employee Count]), ',', ''), '') AS NUMERIC(18,2)),
    TRY_CAST(NULLIF(REPLACE(TRIM([Total Part Time Employee Count]), ',', ''), '') AS NUMERIC(18,2))
FROM raw_HR.raw_2016_transit_agency_employees;

-- ============================================================
-- 2. Load Employees Data for Years 2017 - 2018
-- ============================================================

-- 2017 Data (Column name changes to 'NTD ID')
INSERT INTO stg_HR.stg_transit_agency_employees_2017 (
    ntd_id, reporter_name, reporter_type, mode, tos,
    full_time_vehicle_operations_hours, full_time_vehicle_maintenance_hours, full_time_non_vehicle_maintenance_hours, full_time_general_administration_hours, full_time_total_operating_labor_hours, full_time_total_capital_labor_hours, full_time_total_labor_hours,
    full_time_vehicle_operations_employee_count, full_time_vehicle_maintenance_employee_count, full_time_non_vehicle_maintenance_employee_count, full_time_general_administration_employee_count, full_time_total_operating_labor_employee_count, full_time_total_capital_labor_employee_count, full_time_total_labor_employee_count,
    part_time_vehicle_operations_hours, part_time_vehicle_maintenance_hours, part_time_non_vehicle_maintenance_hours, part_time_general_administration_hours, part_time_total_operating_labor_hours, part_time_total_capital_labor_hours, part_time_total_labor_hours,
    part_time_vehicle_operations_employee_count, part_time_vehicle_maintenance_employee_count, part_time_non_vehicle_maintenance_employee_count, part_time_general_administration_employee_count, part_time_total_operating_labor_employee_count, part_time_total_capital_labor_employee_count, part_time_total_labor_employee_count
)
SELECT
    CAST(TRY_CAST(NULLIF(REPLACE(TRIM([NTD ID]), ',', ''), '') AS NUMERIC(18,0)) AS VARCHAR(50)),
    [Agency Name],
    [Reporter Type],
    [Mode],
    [TOS],

    TRY_CAST(TRY_CAST(NULLIF(REPLACE(TRIM([Full Time Vehicle Operations Hours Worked]), ',', ''), '') AS NUMERIC(18,2)) AS INT),
    TRY_CAST(TRY_CAST(NULLIF(REPLACE(TRIM([Full Time Vehicle Maintenance Hours Worked]), ',', ''), '') AS NUMERIC(18,2)) AS INT),
    TRY_CAST(TRY_CAST(NULLIF(REPLACE(TRIM([Full Time Non-Vehicle Maintenance Hours Worked]), ',', ''), '') AS NUMERIC(18,2)) AS INT),
    TRY_CAST(TRY_CAST(NULLIF(REPLACE(TRIM([Full Time General Administration Maintenance Hours Worked]), ',', ''), '') AS NUMERIC(18,2)) AS INT),
    TRY_CAST(TRY_CAST(NULLIF(REPLACE(TRIM([Total Full Time Operating Labor Hours Worked]), ',', ''), '') AS NUMERIC(18,2)) AS INT),
    TRY_CAST(TRY_CAST(NULLIF(REPLACE(TRIM([Total Full Time Capital Labor Hours Worked]), ',', ''), '') AS NUMERIC(18,2)) AS INT),
    TRY_CAST(TRY_CAST(NULLIF(REPLACE(TRIM([Total Full Time Hours Worked]), ',', ''), '') AS NUMERIC(18,2)) AS INT),

    TRY_CAST(NULLIF(REPLACE(TRIM([Full Time Vehicle Operations Employee Count]), ',', ''), '') AS NUMERIC(18,2)),
    TRY_CAST(NULLIF(REPLACE(TRIM([Full Time Vehicle Maintenance Employee Count]), ',', ''), '') AS NUMERIC(18,2)),
    TRY_CAST(NULLIF(REPLACE(TRIM([Full Time Non-Vehicle Maintenance Employee Count]), ',', ''), '') AS NUMERIC(18,2)),
    TRY_CAST(NULLIF(REPLACE(TRIM([Full Time General Administration Employee Count]), ',', ''), '') AS NUMERIC(18,2)),
    TRY_CAST(NULLIF(REPLACE(TRIM([Total Full Time Operating Employee Count]), ',', ''), '') AS NUMERIC(18,2)),
    TRY_CAST(NULLIF(REPLACE(TRIM([Total Full Time Capital Employee Count]), ',', ''), '') AS NUMERIC(18,2)),
    TRY_CAST(NULLIF(REPLACE(TRIM([Total Full Time Employee Count]), ',', ''), '') AS NUMERIC(18,2)),

    TRY_CAST(TRY_CAST(NULLIF(REPLACE(TRIM([Part Time Vehicle Operations Hours Worked]), ',', ''), '') AS NUMERIC(18,2)) AS INT),
    TRY_CAST(TRY_CAST(NULLIF(REPLACE(TRIM([Part Time Vehicle Maintenance Hours Worked]), ',', ''), '') AS NUMERIC(18,2)) AS INT),
    TRY_CAST(TRY_CAST(NULLIF(REPLACE(TRIM([Part Time Non-Vehicle Maintenance Hours Worked]), ',', ''), '') AS NUMERIC(18,2)) AS INT),
    TRY_CAST(TRY_CAST(NULLIF(REPLACE(TRIM([Part Time General Administration Hours Worked]), ',', ''), '') AS NUMERIC(18,2)) AS INT),
    TRY_CAST(TRY_CAST(NULLIF(REPLACE(TRIM([Total Part Time Operating Labor Hours Worked]), ',', ''), '') AS NUMERIC(18,2)) AS INT),
    TRY_CAST(TRY_CAST(NULLIF(REPLACE(TRIM([Total Part Time Capital Labor Hours Worked]), ',', ''), '') AS NUMERIC(18,2)) AS INT),
    TRY_CAST(TRY_CAST(NULLIF(REPLACE(TRIM([Total Part Time Hours Worked]), ',', ''), '') AS NUMERIC(18,2)) AS INT),

    TRY_CAST(NULLIF(REPLACE(TRIM([Part Time Vehicle Operations Employee Count]), ',', ''), '') AS NUMERIC(18,2)),
    TRY_CAST(NULLIF(REPLACE(TRIM([Part Time Vehicle Maintenance Employee Count]), ',', ''), '') AS NUMERIC(18,2)),
    TRY_CAST(NULLIF(REPLACE(TRIM([Part Time Non-Vehicle Maintenance Employee Count]), ',', ''), '') AS NUMERIC(18,2)),
    TRY_CAST(NULLIF(REPLACE(TRIM([Part Time General Administration Employee Count]), ',', ''), '') AS NUMERIC(18,2)),
    TRY_CAST(NULLIF(REPLACE(TRIM([Total Part Time Operating Employee Count]), ',', ''), '') AS NUMERIC(18,2)),
    TRY_CAST(NULLIF(REPLACE(TRIM([Total Part Time Capital Employee Count]), ',', ''), '') AS NUMERIC(18,2)),
    TRY_CAST(NULLIF(REPLACE(TRIM([Total Part Time Employee Count]), ',', ''), '') AS NUMERIC(18,2))
FROM raw_HR.raw_2017_transit_agency_employees;

-- 2018 Data (Aggregating operator/non-operator to match earlier schema)
INSERT INTO stg_HR.stg_transit_agency_employees_2018 (
    ntd_id, reporter_name, reporter_type, mode, tos,
    full_time_vehicle_operations_hours, full_time_vehicle_maintenance_hours, full_time_non_vehicle_maintenance_hours, full_time_general_administration_hours, full_time_total_operating_labor_hours, full_time_total_capital_labor_hours, full_time_total_labor_hours,
    full_time_vehicle_operations_employee_count, full_time_vehicle_maintenance_employee_count, full_time_non_vehicle_maintenance_employee_count, full_time_general_administration_employee_count, full_time_total_operating_labor_employee_count, full_time_total_capital_labor_employee_count, full_time_total_labor_employee_count,
    part_time_vehicle_operations_hours, part_time_vehicle_maintenance_hours, part_time_non_vehicle_maintenance_hours, part_time_general_administration_hours, part_time_total_operating_labor_hours, part_time_total_capital_labor_hours, part_time_total_labor_hours,
    part_time_vehicle_operations_employee_count, part_time_vehicle_maintenance_employee_count, part_time_non_vehicle_maintenance_employee_count, part_time_general_administration_employee_count, part_time_total_operating_labor_employee_count, part_time_total_capital_labor_employee_count, part_time_total_labor_employee_count
)
SELECT
    CAST(TRY_CAST(NULLIF(REPLACE(TRIM([NTD ID]), ',', ''), '') AS NUMERIC(18,0)) AS VARCHAR(50)),
    [Agency Name],
    [Reporter Type],
    [Mode],
    [TOS],

    TRY_CAST(TRY_CAST(NULLIF(REPLACE(TRIM([Total Full Time (Vehicle Operations) Hours Worked]), ',', ''), '') AS NUMERIC(18,2)) AS INT),
    TRY_CAST(TRY_CAST(NULLIF(REPLACE(TRIM([Total Full Time (Vehicle Maintenance) Hours Worked]), ',', ''), '') AS NUMERIC(18,2)) AS INT),
    TRY_CAST(TRY_CAST(NULLIF(REPLACE(TRIM([Total Full Time (Facility Maintenance) Hours Worked]), ',', ''), '') AS NUMERIC(18,2)) AS INT),
    TRY_CAST(TRY_CAST(NULLIF(REPLACE(TRIM([Total Full Time (General Administration) Hours Worked]), ',', ''), '') AS NUMERIC(18,2)) AS INT),
    TRY_CAST(TRY_CAST(NULLIF(REPLACE(TRIM([Total Full Time (Operating Labor) Hours Worked]), ',', ''), '') AS NUMERIC(18,2)) AS INT),
    TRY_CAST(TRY_CAST(NULLIF(REPLACE(TRIM([Total Full Time (Capital Labor) Hours Worked]), ',', ''), '') AS NUMERIC(18,2)) AS INT),
    TRY_CAST(TRY_CAST(NULLIF(REPLACE(TRIM([Total Full Time Hours Worked]), ',', ''), '') AS NUMERIC(18,2)) AS INT),

    TRY_CAST(NULLIF(REPLACE(TRIM([Total Full Time (Vehicle Operations) Employee Count]), ',', ''), '') AS NUMERIC(18,2)),
    TRY_CAST(NULLIF(REPLACE(TRIM([Total Full Time (Vehicle Maintenance) Employee Count]), ',', ''), '') AS NUMERIC(18,2)),
    TRY_CAST(NULLIF(REPLACE(TRIM([Total Full Time (Facility Maintenance) Employee Count]), ',', ''), '') AS NUMERIC(18,2)),
    TRY_CAST(NULLIF(REPLACE(TRIM([Total Full Time (General Administration) Employee Count]), ',', ''), '') AS NUMERIC(18,2)),
    TRY_CAST(NULLIF(REPLACE(TRIM([Total Full Time (Operations) Employee Count]), ',', ''), '') AS NUMERIC(18,2)),
    TRY_CAST(NULLIF(REPLACE(TRIM([Total Full Time (Capital Labor) Employee Count]), ',', ''), '') AS NUMERIC(18,2)),
    TRY_CAST(NULLIF(REPLACE(TRIM([Total Full Time Employee Count]), ',', ''), '') AS NUMERIC(18,2)),

    TRY_CAST(TRY_CAST(NULLIF(REPLACE(TRIM([Total Part Time (Vehicle Operations) Hours Worked]), ',', ''), '') AS NUMERIC(18,2)) AS INT),
    TRY_CAST(TRY_CAST(NULLIF(REPLACE(TRIM([Total Part Time (Vehicle Maintenance) Hours Worked]), ',', ''), '') AS NUMERIC(18,2)) AS INT),
    TRY_CAST(TRY_CAST(NULLIF(REPLACE(TRIM([Total Part Time (Facility Maintenance) Hours Worked]), ',', ''), '') AS NUMERIC(18,2)) AS INT),
    TRY_CAST(TRY_CAST(NULLIF(REPLACE(TRIM([Total Part Time (General Administration) Hours Worked]), ',', ''), '') AS NUMERIC(18,2)) AS INT),
    TRY_CAST(TRY_CAST(NULLIF(REPLACE(TRIM([Total Part Time (Operating Labor) Hours Worked]), ',', ''), '') AS NUMERIC(18,2)) AS INT),
    TRY_CAST(TRY_CAST(NULLIF(REPLACE(TRIM([Total Part Time (Capital Labor) Hours Worked]), ',', ''), '') AS NUMERIC(18,2)) AS INT),
    TRY_CAST(TRY_CAST(NULLIF(REPLACE(TRIM([Total Part Time Hours Worked]), ',', ''), '') AS NUMERIC(18,2)) AS INT),

    TRY_CAST(NULLIF(REPLACE(TRIM([Total Part Time (Vehicle Operations) Employee Count]), ',', ''), '') AS NUMERIC(18,2)),
    TRY_CAST(NULLIF(REPLACE(TRIM([Total Part Time (Vehicle Maintenance) Employee Count]), ',', ''), '') AS NUMERIC(18,2)),
    TRY_CAST(NULLIF(REPLACE(TRIM([Total Part Time (Facility Maintenance) Employee Count]), ',', ''), '') AS NUMERIC(18,2)),
    TRY_CAST(NULLIF(REPLACE(TRIM([Total Part Time (General Administration) Employee Count]), ',', ''), '') AS NUMERIC(18,2)),
    TRY_CAST(NULLIF(REPLACE(TRIM([Total Part Time (Operations) Employee Count]), ',', ''), '') AS NUMERIC(18,2)),
    TRY_CAST(NULLIF(REPLACE(TRIM([Total Part Time (Capital Labor) Employee Count]), ',', ''), '') AS NUMERIC(18,2)),
    TRY_CAST(NULLIF(REPLACE(TRIM([Total Part Time Employee Count]), ',', ''), '') AS NUMERIC(18,2))
FROM raw_HR.raw_2018_transit_agency_employees;

-- ============================================================
-- 3. Load Employees Data for Years 2019 - 2024
-- HR Staging Tables Load - 2019-2024
-- NOTE: 2022-2024 raw tables have leading/trailing spaces in column names
-- All staging table columns must match DDL definitions exactly
-- ============================================================

INSERT INTO stg_HR.stg_transit_agency_employees_2019 (
    ntd_id, agency_name, reporter_type, reporting_module, mode, tos,
    full_time_operator_vehicle_operations_hours_worked,
    full_time_non_operator_vehicle_operations_hours_worked,
    total_full_time_vehicle_operations_hours_worked,
    full_time_operator_vehicle_maintenance_hours_worked,
    full_time_non_operator_vehicle_maintenance_hours_worked,
    total_full_time_vehicle_maintenance_hours_worked,
    full_time_operator_facility_maintenance_hours_worked,
    full_time_non_operator_facility_maintenance_hours_worked,
    total_full_time_facility_maintenance_hours_worked,
    full_time_operator_general_administration_hours_worked,
    full_time_non_operator_general_administration_hours_worked,
    total_full_time_general_administration_hours_worked,
    total_full_time_operator_operating_labor_hours_worked,
    total_full_time_non_operator_operating_labor_hours_worked,
    total_full_time_operating_labor_hours_worked,
    total_full_time_operator_capital_labor_hours_worked,
    total_full_time_non_operator_capital_labor_hours_worked,
    total_full_time_capital_labor_hours_worked,
    total_full_time_operator_hours_worked,
    total_full_time_non_operator_hours_worked,
    total_full_time_hours_worked,
    full_time_operator_vehicle_operations_employee_count,
    full_time_non_operator_vehicle_operations_employee_count,
    total_full_time_vehicle_operations_employee_count,
    full_time_operator_vehicle_maintenance_employee_count,
    full_time_non_operator_vehicle_maintenance_employee_count,
    total_full_time_vehicle_maintenance_employee_count,
    full_time_operator_facility_maintenance_employee_count,
    full_time_non_operator_facility_maintenance_employee_count,
    total_full_time_facility_maintenance_employee_count,
    full_time_operator_general_administration_employee_count,
    full_time_non_operator_general_administration_employee_count,
    total_full_time_general_administration_employee_count,
    total_full_time_operator_employee_count,
    total_full_time_non_operator_employee_count,
    total_full_time_employee_count,
    part_time_operator_vehicle_operations_hours_worked,
    part_time_non_operator_vehicle_operations_hours_worked,
    total_part_time_vehicle_operations_hours_worked,
    part_time_operator_vehicle_maintenance_hours_worked,
    part_time_non_operator_vehicle_maintenance_hours_worked,
    total_part_time_vehicle_maintenance_hours_worked,
    part_time_operator_facility_maintenance_hours_worked,
    part_time_non_operator_facility_maintenance_hours_worked,
    total_part_time_facility_maintenance_hours_worked,
    part_time_operator_general_administration_hours_worked,
    part_time_non_operator_general_administration_hours_worked,
    total_part_time_general_administration_hours_worked,
    total_part_time_operator_hours_worked,
    total_part_time_non_operator_hours_worked,
    total_part_time_hours_worked,
    part_time_operator_vehicle_operations_employee_count,
    part_time_non_operator_vehicle_operations_employee_count,
    total_part_time_vehicle_operations_employee_count,
    part_time_operator_vehicle_maintenance_employee_count,
    part_time_non_operator_vehicle_maintenance_employee_count,
    total_part_time_vehicle_maintenance_employee_count,
    part_time_operator_facility_maintenance_employee_count,
    part_time_non_operator_facility_maintenance_employee_count,
    total_part_time_facility_maintenance_employee_count,
    part_time_operator_general_administration_employee_count,
    part_time_non_operator_general_administration_employee_count,
    total_part_time_general_administration_employee_count,
    total_part_time_operator_employee_count,
    total_part_time_non_operator_employee_count,
    total_part_time_employee_count
)
SELECT
    CAST(TRY_CAST(NULLIF(REPLACE(TRIM([NTD ID]), ',', ''), '') AS NUMERIC(18,0)) AS VARCHAR(50)),
    NULLIF(TRIM([Agency Name]), ''),
    NULLIF(TRIM([Reporter Type]), ''),
    NULLIF(TRIM([Reporting Module]), ''),
    NULLIF(TRIM([Mode]), ''),
    NULLIF(TRIM([TOS]), ''),
    TRY_CAST(TRY_CAST(NULLIF(REPLACE(TRIM([Full Time Operator (Vehicle Operations) Hours Worked]), ',', ''), '') AS NUMERIC(18,2)) AS INT),
    TRY_CAST(TRY_CAST(NULLIF(REPLACE(TRIM([Full Time Non-Operator (Vehicle Operations) Hours Worked]), ',', ''), '') AS NUMERIC(18,2)) AS INT),
    TRY_CAST(TRY_CAST(NULLIF(REPLACE(TRIM([Total Full Time (Vehicle Operations) Hours Worked]), ',', ''), '') AS NUMERIC(18,2)) AS INT),
    TRY_CAST(TRY_CAST(NULLIF(REPLACE(TRIM([Full Time Operator (Vehicle Maintenance) Hours Worked]), ',', ''), '') AS NUMERIC(18,2)) AS INT),
    TRY_CAST(TRY_CAST(NULLIF(REPLACE(TRIM([Full Time Non-Operator (Vehicle Maintenance) Hours Worked]), ',', ''), '') AS NUMERIC(18,2)) AS INT),
    TRY_CAST(TRY_CAST(NULLIF(REPLACE(TRIM([Total Full Time (Vehicle Maintenance) Hours Worked]), ',', ''), '') AS NUMERIC(18,2)) AS INT),
    TRY_CAST(TRY_CAST(NULLIF(REPLACE(TRIM([Full Time Operator (Facility Maintenance) Hours Worked]), ',', ''), '') AS NUMERIC(18,2)) AS INT),
    TRY_CAST(TRY_CAST(NULLIF(REPLACE(TRIM([Full Time Non-Operator (Facility Maintenance) Hours Worked]), ',', ''), '') AS NUMERIC(18,2)) AS INT),
    TRY_CAST(TRY_CAST(NULLIF(REPLACE(TRIM([Total Full Time (Facility Maintenance) Hours Worked]), ',', ''), '') AS NUMERIC(18,2)) AS INT),
    TRY_CAST(TRY_CAST(NULLIF(REPLACE(TRIM([Full Time Operator (General Administration) Hours Worked]), ',', ''), '') AS NUMERIC(18,2)) AS INT),
    TRY_CAST(TRY_CAST(NULLIF(REPLACE(TRIM([Full Time Non-Operator (General Administration) Hours Worked]), ',', ''), '') AS NUMERIC(18,2)) AS INT),
    TRY_CAST(TRY_CAST(NULLIF(REPLACE(TRIM([Total Full Time (General Administration) Hours Worked]), ',', ''), '') AS NUMERIC(18,2)) AS INT),
    TRY_CAST(TRY_CAST(NULLIF(REPLACE(TRIM([Total Full Time Operator (Operating Labor) Hours Worked]), ',', ''), '') AS NUMERIC(18,2)) AS INT),
    TRY_CAST(TRY_CAST(NULLIF(REPLACE(TRIM([Total Full Time Non-Operator (Operating Labor) Hours Worked]), ',', ''), '') AS NUMERIC(18,2)) AS INT),
    TRY_CAST(TRY_CAST(NULLIF(REPLACE(TRIM([Total Full Time (Operating Labor) Hours Worked]), ',', ''), '') AS NUMERIC(18,2)) AS INT),
    TRY_CAST(TRY_CAST(NULLIF(REPLACE(TRIM([Full Time Operator (Capital Labor) Hours Worked]), ',', ''), '') AS NUMERIC(18,2)) AS INT),
    TRY_CAST(TRY_CAST(NULLIF(REPLACE(TRIM([Full Time Non-Operator (Capital Labor) Hours Worked]), ',', ''), '') AS NUMERIC(18,2)) AS INT),
    TRY_CAST(TRY_CAST(NULLIF(REPLACE(TRIM([Total Full Time (Capital Labor) Hours Worked]), ',', ''), '') AS NUMERIC(18,2)) AS INT),
    TRY_CAST(TRY_CAST(NULLIF(REPLACE(TRIM([Total Full Time Operator Hours Worked]), ',', ''), '') AS NUMERIC(18,2)) AS INT),
    TRY_CAST(TRY_CAST(NULLIF(REPLACE(TRIM([Total Full Time Non-Operator Hours Worked]), ',', ''), '') AS NUMERIC(18,2)) AS INT),
    TRY_CAST(TRY_CAST(NULLIF(REPLACE(TRIM([Total Full Time Hours Worked]), ',', ''), '') AS NUMERIC(18,2)) AS INT),
    TRY_CAST(NULLIF(REPLACE(TRIM([Full Time Operator (Vehicle Operations) Employee Count]), ',', ''), '') AS NUMERIC(18,2)),
    TRY_CAST(NULLIF(REPLACE(TRIM([Full Time Non-Operator (Vehicle Operations) Employee Count]), ',', ''), '') AS NUMERIC(18,2)),
    TRY_CAST(NULLIF(REPLACE(TRIM([Total Full Time (Vehicle Operations) Employee Count]), ',', ''), '') AS NUMERIC(18,2)),
    TRY_CAST(NULLIF(REPLACE(TRIM([Full Time Operator (Vehicle Maintenance) Employee Count]), ',', ''), '') AS NUMERIC(18,2)),
    TRY_CAST(NULLIF(REPLACE(TRIM([Full Time Non-Operator (Vehicle Maintenance) Employee Count]), ',', ''), '') AS NUMERIC(18,2)),
    TRY_CAST(NULLIF(REPLACE(TRIM([Total Full Time (Vehicle Maintenance) Employee Count]), ',', ''), '') AS NUMERIC(18,2)),
    TRY_CAST(NULLIF(REPLACE(TRIM([Full Time Operator (Facility Maintenance) Employee Count]), ',', ''), '') AS NUMERIC(18,2)),
    TRY_CAST(NULLIF(REPLACE(TRIM([Full Time Non-Operator (Facility Maintenance) Employee Count]), ',', ''), '') AS NUMERIC(18,2)),
    TRY_CAST(NULLIF(REPLACE(TRIM([Total Full Time (Facility Maintenance) Employee Count]), ',', ''), '') AS NUMERIC(18,2)),
    TRY_CAST(NULLIF(REPLACE(TRIM([Full Time Operator (General Administration) Employee Count]), ',', ''), '') AS NUMERIC(18,2)),
    TRY_CAST(NULLIF(REPLACE(TRIM([Full Time Non-Operator (General Administration) Employee Count]), ',', ''), '') AS NUMERIC(18,2)),
    TRY_CAST(NULLIF(REPLACE(TRIM([Total Full Time (General Administration) Employee Count]), ',', ''), '') AS NUMERIC(18,2)),
    TRY_CAST(NULLIF(REPLACE(TRIM([Total Full Time Operator Employee Count]), ',', ''), '') AS NUMERIC(18,2)),
    TRY_CAST(NULLIF(REPLACE(TRIM([Total Full Time Non-Operator Employee Count]), ',', ''), '') AS NUMERIC(18,2)),
    TRY_CAST(NULLIF(REPLACE(TRIM([Total Full Time Employee Count]), ',', ''), '') AS NUMERIC(18,2)),
    TRY_CAST(TRY_CAST(NULLIF(REPLACE(TRIM([Part Time Operator (Vehicle Operations) Hours Worked]), ',', ''), '') AS NUMERIC(18,2)) AS INT),
    TRY_CAST(TRY_CAST(NULLIF(REPLACE(TRIM([Part Time Non-Operator (Vehicle Operations) Hours Worked]), ',', ''), '') AS NUMERIC(18,2)) AS INT),
    TRY_CAST(TRY_CAST(NULLIF(REPLACE(TRIM([Total Part Time (Vehicle Operations) Hours Worked]), ',', ''), '') AS NUMERIC(18,2)) AS INT),
    TRY_CAST(TRY_CAST(NULLIF(REPLACE(TRIM([Part Time Operator (Vehicle Maintenance) Hours Worked]), ',', ''), '') AS NUMERIC(18,2)) AS INT),
    TRY_CAST(TRY_CAST(NULLIF(REPLACE(TRIM([Part Time Non-Operator (Vehicle Maintenance) Hours Worked]), ',', ''), '') AS NUMERIC(18,2)) AS INT),
    TRY_CAST(TRY_CAST(NULLIF(REPLACE(TRIM([Total Part Time (Vehicle Maintenance) Hours Worked]), ',', ''), '') AS NUMERIC(18,2)) AS INT),
    TRY_CAST(TRY_CAST(NULLIF(REPLACE(TRIM([Part Time Operator (Facility Maintenance) Hours Worked]), ',', ''), '') AS NUMERIC(18,2)) AS INT),
    TRY_CAST(TRY_CAST(NULLIF(REPLACE(TRIM([Part Time Non-Operator (Facility Maintenance) Hours Worked]), ',', ''), '') AS NUMERIC(18,2)) AS INT),
    TRY_CAST(TRY_CAST(NULLIF(REPLACE(TRIM([Total Part Time (Facility Maintenance) Hours Worked]), ',', ''), '') AS NUMERIC(18,2)) AS INT),
    TRY_CAST(TRY_CAST(NULLIF(REPLACE(TRIM([Part Time Operator (General Administration) Hours Worked]), ',', ''), '') AS NUMERIC(18,2)) AS INT),
    TRY_CAST(TRY_CAST(NULLIF(REPLACE(TRIM([Part Time Non-Operator (General Administration) Hours Worked]), ',', ''), '') AS NUMERIC(18,2)) AS INT),
    TRY_CAST(TRY_CAST(NULLIF(REPLACE(TRIM([Total Part Time (General Administration) Hours Worked]), ',', ''), '') AS NUMERIC(18,2)) AS INT),
    TRY_CAST(TRY_CAST(NULLIF(REPLACE(TRIM([Total Part Time Operator Hours Worked]), ',', ''), '') AS NUMERIC(18,2)) AS INT),
    TRY_CAST(TRY_CAST(NULLIF(REPLACE(TRIM([Total Part Time Non-Operator Hours Worked]), ',', ''), '') AS NUMERIC(18,2)) AS INT),
    TRY_CAST(TRY_CAST(NULLIF(REPLACE(TRIM([Total Part Time Hours Worked]), ',', ''), '') AS NUMERIC(18,2)) AS INT),
    TRY_CAST(NULLIF(REPLACE(TRIM([Part Time Operator (Vehicle Operations) Employee Count]), ',', ''), '') AS NUMERIC(18,2)),
    TRY_CAST(NULLIF(REPLACE(TRIM([Part Time Non-Operator (Vehicle Operations) Employee Count]), ',', ''), '') AS NUMERIC(18,2)),
    TRY_CAST(NULLIF(REPLACE(TRIM([Total Part Time (Vehicle Operations) Employee Count]), ',', ''), '') AS NUMERIC(18,2)),
    TRY_CAST(NULLIF(REPLACE(TRIM([Part Time Operator (Vehicle Maintenance) Employee Count]), ',', ''), '') AS NUMERIC(18,2)),
    TRY_CAST(NULLIF(REPLACE(TRIM([Part Time Non-Operator (Vehicle Maintenance) Employee Count]), ',', ''), '') AS NUMERIC(18,2)),
    TRY_CAST(NULLIF(REPLACE(TRIM([Total Part Time (Vehicle Maintenance) Employee Count]), ',', ''), '') AS NUMERIC(18,2)),
    TRY_CAST(NULLIF(REPLACE(TRIM([Part Time Operator (Facility Maintenance) Employee Count]), ',', ''), '') AS NUMERIC(18,2)),
    TRY_CAST(NULLIF(REPLACE(TRIM([Part Time Non-Operator (Facility Maintenance) Employee Count]), ',', ''), '') AS NUMERIC(18,2)),
    TRY_CAST(NULLIF(REPLACE(TRIM([Total Part Time (Facility Maintenance) Employee Count]), ',', ''), '') AS NUMERIC(18,2)),
    TRY_CAST(NULLIF(REPLACE(TRIM([Part Time Operator (General Administration) Employee Count]), ',', ''), '') AS NUMERIC(18,2)),
    TRY_CAST(NULLIF(REPLACE(TRIM([Part Time Non-Operator (General Administration) Employee Count]), ',', ''), '') AS NUMERIC(18,2)),
    TRY_CAST(NULLIF(REPLACE(TRIM([Total Part Time (General Administration) Employee Count]), ',', ''), '') AS NUMERIC(18,2)),
    TRY_CAST(NULLIF(REPLACE(TRIM([Total Part Time Operator Employee Count]), ',', ''), '') AS NUMERIC(18,2)),
    TRY_CAST(NULLIF(REPLACE(TRIM([Total Part Time Non-Operator Employee Count]), ',', ''), '') AS NUMERIC(18,2)),
    TRY_CAST(NULLIF(REPLACE(TRIM([Total Part Time Employee Count]), ',', ''), '') AS NUMERIC(18,2))
FROM raw_HR.raw_2019_transit_agency_employees;

-- 2020 Data (Uses raw_2020, not raw_2019)
INSERT INTO stg_HR.stg_transit_agency_employees_2020 (
    ntd_id, agency_name, reporter_type, reporting_module, mode, tos,
    full_time_operator_vehicle_operations_hours_worked,
    full_time_non_operator_vehicle_operations_hours_worked,
    total_full_time_vehicle_operations_hours_worked,
    full_time_operator_vehicle_maintenance_hours_worked,
    full_time_non_operator_vehicle_maintenance_hours_worked,
    total_full_time_vehicle_maintenance_hours_worked,
    full_time_operator_facility_maintenance_hours_worked,
    full_time_non_operator_facility_maintenance_hours_worked,
    total_full_time_facility_maintenance_hours_worked,
    full_time_operator_general_administration_hours_worked,
    full_time_non_operator_general_administration_hours_worked,
    total_full_time_general_administration_hours_worked,
    total_full_time_operator_operating_labor_hours_worked,
    total_full_time_non_operator_operating_labor_hours_worked,
    total_full_time_operating_labor_hours_worked,
    total_full_time_operator_capital_labor_hours_worked,
    total_full_time_non_operator_capital_labor_hours_worked,
    total_full_time_capital_labor_hours_worked,
    total_full_time_operator_hours_worked,
    total_full_time_non_operator_hours_worked,
    total_full_time_hours_worked,
    full_time_operator_vehicle_operations_employee_count,
    full_time_non_operator_vehicle_operations_employee_count,
    total_full_time_vehicle_operations_employee_count,
    full_time_operator_vehicle_maintenance_employee_count,
    full_time_non_operator_vehicle_maintenance_employee_count,
    total_full_time_vehicle_maintenance_employee_count,
    full_time_operator_facility_maintenance_employee_count,
    full_time_non_operator_facility_maintenance_employee_count,
    total_full_time_facility_maintenance_employee_count,
    full_time_operator_general_administration_employee_count,
    full_time_non_operator_general_administration_employee_count,
    total_full_time_general_administration_employee_count,
    total_full_time_operator_employee_count,
    total_full_time_non_operator_employee_count,
    total_full_time_employee_count,
    part_time_operator_vehicle_operations_hours_worked,
    part_time_non_operator_vehicle_operations_hours_worked,
    total_part_time_vehicle_operations_hours_worked,
    part_time_operator_vehicle_maintenance_hours_worked,
    part_time_non_operator_vehicle_maintenance_hours_worked,
    total_part_time_vehicle_maintenance_hours_worked,
    part_time_operator_facility_maintenance_hours_worked,
    part_time_non_operator_facility_maintenance_hours_worked,
    total_part_time_facility_maintenance_hours_worked,
    part_time_operator_general_administration_hours_worked,
    part_time_non_operator_general_administration_hours_worked,
    total_part_time_general_administration_hours_worked,
    total_part_time_operator_hours_worked,
    total_part_time_non_operator_hours_worked,
    total_part_time_hours_worked,
    part_time_operator_vehicle_operations_employee_count,
    part_time_non_operator_vehicle_operations_employee_count,
    total_part_time_vehicle_operations_employee_count,
    part_time_operator_vehicle_maintenance_employee_count,
    part_time_non_operator_vehicle_maintenance_employee_count,
    total_part_time_vehicle_maintenance_employee_count,
    part_time_operator_facility_maintenance_employee_count,
    part_time_non_operator_facility_maintenance_employee_count,
    total_part_time_facility_maintenance_employee_count,
    part_time_operator_general_administration_employee_count,
    part_time_non_operator_general_administration_employee_count,
    total_part_time_general_administration_employee_count,
    total_part_time_operator_employee_count,
    total_part_time_non_operator_employee_count,
    total_part_time_employee_count
)
SELECT
    CAST(TRY_CAST(NULLIF(REPLACE(TRIM([NTD ID]), ',', ''), '') AS NUMERIC(18,0)) AS VARCHAR(50)),
    NULLIF(TRIM([Agency Name]), ''),
    NULLIF(TRIM([Reporter Type]), ''),
    NULLIF(TRIM([Reporting Module]), ''),
    NULLIF(TRIM([Mode]), ''),
    NULLIF(TRIM([TOS]), ''),
    TRY_CAST(TRY_CAST(NULLIF(REPLACE(TRIM([Full Time Operator (Vehicle Operations) Hours Worked]), ',', ''), '') AS NUMERIC(18,2)) AS INT),
    TRY_CAST(TRY_CAST(NULLIF(REPLACE(TRIM([Full Time Non-Operator (Vehicle Operations) Hours Worked]), ',', ''), '') AS NUMERIC(18,2)) AS INT),
    TRY_CAST(TRY_CAST(NULLIF(REPLACE(TRIM([Total Full Time (Vehicle Operations) Hours Worked]), ',', ''), '') AS NUMERIC(18,2)) AS INT),
    TRY_CAST(TRY_CAST(NULLIF(REPLACE(TRIM([Full Time Operator (Vehicle Maintenance) Hours Worked]), ',', ''), '') AS NUMERIC(18,2)) AS INT),
    TRY_CAST(TRY_CAST(NULLIF(REPLACE(TRIM([Full Time Non-Operator (Vehicle Maintenance) Hours Worked]), ',', ''), '') AS NUMERIC(18,2)) AS INT),
    TRY_CAST(TRY_CAST(NULLIF(REPLACE(TRIM([Total Full Time (Vehicle Maintenance) Hours Worked]), ',', ''), '') AS NUMERIC(18,2)) AS INT),
    TRY_CAST(TRY_CAST(NULLIF(REPLACE(TRIM([Full Time Operator (Facility Maintenance) Hours Worked]), ',', ''), '') AS NUMERIC(18,2)) AS INT),
    TRY_CAST(TRY_CAST(NULLIF(REPLACE(TRIM([Full Time Non-Operator (Facility Maintenance) Hours Worked]), ',', ''), '') AS NUMERIC(18,2)) AS INT),
    TRY_CAST(TRY_CAST(NULLIF(REPLACE(TRIM([Total Full Time (Facility Maintenance) Hours Worked]), ',', ''), '') AS NUMERIC(18,2)) AS INT),
    TRY_CAST(TRY_CAST(NULLIF(REPLACE(TRIM([Full Time Operator (General Administration) Hours Worked]), ',', ''), '') AS NUMERIC(18,2)) AS INT),
    TRY_CAST(TRY_CAST(NULLIF(REPLACE(TRIM([Full Time Non-Operator (General Administration) Hours Worked]), ',', ''), '') AS NUMERIC(18,2)) AS INT),
    TRY_CAST(TRY_CAST(NULLIF(REPLACE(TRIM([Total Full Time (General Administration) Hours Worked]), ',', ''), '') AS NUMERIC(18,2)) AS INT),
    TRY_CAST(TRY_CAST(NULLIF(REPLACE(TRIM([Total Full Time Operator (Operating Labor) Hours Worked]), ',', ''), '') AS NUMERIC(18,2)) AS INT),
    TRY_CAST(TRY_CAST(NULLIF(REPLACE(TRIM([Total Full Time Non-Operator (Operating Labor) Hours Worked]), ',', ''), '') AS NUMERIC(18,2)) AS INT),
    TRY_CAST(TRY_CAST(NULLIF(REPLACE(TRIM([Total Full Time (Operating Labor) Hours Worked]), ',', ''), '') AS NUMERIC(18,2)) AS INT),
    TRY_CAST(TRY_CAST(NULLIF(REPLACE(TRIM([Full Time Operator (Capital Labor) Hours Worked]), ',', ''), '') AS NUMERIC(18,2)) AS INT),
    TRY_CAST(TRY_CAST(NULLIF(REPLACE(TRIM([Full Time Non-Operator (Capital Labor) Hours Worked]), ',', ''), '') AS NUMERIC(18,2)) AS INT),
    TRY_CAST(TRY_CAST(NULLIF(REPLACE(TRIM([Total Full Time (Capital Labor) Hours Worked]), ',', ''), '') AS NUMERIC(18,2)) AS INT),
    TRY_CAST(TRY_CAST(NULLIF(REPLACE(TRIM([Total Full Time Operator Hours Worked]), ',', ''), '') AS NUMERIC(18,2)) AS INT),
    TRY_CAST(TRY_CAST(NULLIF(REPLACE(TRIM([Total Full Time Non-Operator Hours Worked]), ',', ''), '') AS NUMERIC(18,2)) AS INT),
    TRY_CAST(TRY_CAST(NULLIF(REPLACE(TRIM([Total Full Time Hours Worked]), ',', ''), '') AS NUMERIC(18,2)) AS INT),
    TRY_CAST(NULLIF(REPLACE(TRIM([Full Time Operator (Vehicle Operations) Employee Count]), ',', ''), '') AS NUMERIC(18,2)),
    TRY_CAST(NULLIF(REPLACE(TRIM([Full Time Non-Operator (Vehicle Operations) Employee Count]), ',', ''), '') AS NUMERIC(18,2)),
    TRY_CAST(NULLIF(REPLACE(TRIM([Total Full Time (Vehicle Operations) Employee Count]), ',', ''), '') AS NUMERIC(18,2)),
    TRY_CAST(NULLIF(REPLACE(TRIM([Full Time Operator (Vehicle Maintenance) Employee Count]), ',', ''), '') AS NUMERIC(18,2)),
    TRY_CAST(NULLIF(REPLACE(TRIM([Full Time Non-Operator (Vehicle Maintenance) Employee Count]), ',', ''), '') AS NUMERIC(18,2)),
    TRY_CAST(NULLIF(REPLACE(TRIM([Total Full Time (Vehicle Maintenance) Employee Count]), ',', ''), '') AS NUMERIC(18,2)),
    TRY_CAST(NULLIF(REPLACE(TRIM([Full Time Operator (Facility Maintenance) Employee Count]), ',', ''), '') AS NUMERIC(18,2)),
    TRY_CAST(NULLIF(REPLACE(TRIM([Full Time Non-Operator (Facility Maintenance) Employee Count]), ',', ''), '') AS NUMERIC(18,2)),
    TRY_CAST(NULLIF(REPLACE(TRIM([Total Full Time (Facility Maintenance) Employee Count]), ',', ''), '') AS NUMERIC(18,2)),
    TRY_CAST(NULLIF(REPLACE(TRIM([Full Time Operator (General Administration) Employee Count]), ',', ''), '' ) AS NUMERIC(18,2)),
    TRY_CAST(NULLIF(REPLACE(TRIM([Full Time Non-Operator (General Administration) Employee Count]), ',', ''), '') AS NUMERIC(18,2)),
    TRY_CAST(NULLIF(REPLACE(TRIM([Total Full Time (General Administration) Employee Count]), ',', ''), '') AS NUMERIC(18,2)),
    TRY_CAST(NULLIF(REPLACE(TRIM([Total Full Time Operator Employee Count]), ',', ''), '') AS NUMERIC(18,2)),
    TRY_CAST(NULLIF(REPLACE(TRIM([Total Full Time Non-Operator Employee Count]), ',', ''), '') AS NUMERIC(18,2)),
    TRY_CAST(NULLIF(REPLACE(TRIM([Total Full Time Employee Count]), ',', ''), '') AS NUMERIC(18,2)),
    TRY_CAST(TRY_CAST(NULLIF(REPLACE(TRIM([Part Time Operator (Vehicle Operations) Hours Worked]), ',', ''), '') AS NUMERIC(18,2)) AS INT),
    TRY_CAST(TRY_CAST(NULLIF(REPLACE(TRIM([Part Time Non-Operator (Vehicle Operations) Hours Worked]), ',', ''), '') AS NUMERIC(18,2)) AS INT),
    TRY_CAST(TRY_CAST(NULLIF(REPLACE(TRIM([Total Part Time (Vehicle Operations) Hours Worked]), ',', ''), '') AS NUMERIC(18,2)) AS INT),
    TRY_CAST(TRY_CAST(NULLIF(REPLACE(TRIM([Part Time Operator (Vehicle Maintenance) Hours Worked]), ',', ''), '') AS NUMERIC(18,2)) AS INT),
    TRY_CAST(TRY_CAST(NULLIF(REPLACE(TRIM([Part Time Non-Operator (Vehicle Maintenance) Hours Worked]), ',', ''), '') AS NUMERIC(18,2)) AS INT),
    TRY_CAST(TRY_CAST(NULLIF(REPLACE(TRIM([Total Part Time (Vehicle Maintenance) Hours Worked]), ',', ''), '') AS NUMERIC(18,2)) AS INT),
    TRY_CAST(TRY_CAST(NULLIF(REPLACE(TRIM([Part Time Operator (Facility Maintenance) Hours Worked]), ',', ''), '') AS NUMERIC(18,2)) AS INT),
    TRY_CAST(TRY_CAST(NULLIF(REPLACE(TRIM([Part Time Non-Operator (Facility Maintenance) Hours Worked]), ',', ''), '') AS NUMERIC(18,2)) AS INT),
    TRY_CAST(TRY_CAST(NULLIF(REPLACE(TRIM([Total Part Time (Facility Maintenance) Hours Worked]), ',', ''), '') AS NUMERIC(18,2)) AS INT),
    TRY_CAST(TRY_CAST(NULLIF(REPLACE(TRIM([Part Time Operator (General Administration) Hours Worked]), ',', ''), '') AS NUMERIC(18,2)) AS INT),
    TRY_CAST(TRY_CAST(NULLIF(REPLACE(TRIM([Part Time Non-Operator (General Administration) Hours Worked]), ',', ''), '') AS NUMERIC(18,2)) AS INT),
    TRY_CAST(TRY_CAST(NULLIF(REPLACE(TRIM([Total Part Time (General Administration) Hours Worked]), ',', ''), '') AS NUMERIC(18,2)) AS INT),
    TRY_CAST(TRY_CAST(NULLIF(REPLACE(TRIM([Total Part Time Operator Hours Worked]), ',', ''), '') AS NUMERIC(18,2)) AS INT),
    TRY_CAST(TRY_CAST(NULLIF(REPLACE(TRIM([Total Part Time Non-Operator Hours Worked]), ',', ''), '') AS NUMERIC(18,2)) AS INT),
    TRY_CAST(TRY_CAST(NULLIF(REPLACE(TRIM([Total Part Time Hours Worked]), ',', ''), '') AS NUMERIC(18,2)) AS INT),
    TRY_CAST(NULLIF(REPLACE(TRIM([Part Time Operator (Vehicle Operations) Employee Count]), ',', ''), '') AS NUMERIC(18,2)),
    TRY_CAST(NULLIF(REPLACE(TRIM([Part Time Non-Operator (Vehicle Operations) Employee Count]), ',', ''), '') AS NUMERIC(18,2)),
    TRY_CAST(NULLIF(REPLACE(TRIM([Total Part Time (Vehicle Operations) Employee Count]), ',', ''), '') AS NUMERIC(18,2)),
    TRY_CAST(NULLIF(REPLACE(TRIM([Part Time Operator (Vehicle Maintenance) Employee Count]), ',', ''), '') AS NUMERIC(18,2)),
    TRY_CAST(NULLIF(REPLACE(TRIM([Part Time Non-Operator (Vehicle Maintenance) Employee Count]), ',', ''), '') AS NUMERIC(18,2)),
    TRY_CAST(NULLIF(REPLACE(TRIM([Total Part Time (Vehicle Maintenance) Employee Count]), ',', ''), '') AS NUMERIC(18,2)),
    TRY_CAST(NULLIF(REPLACE(TRIM([Part Time Operator (Facility Maintenance) Employee Count]), ',', ''), '') AS NUMERIC(18,2)),
    TRY_CAST(NULLIF(REPLACE(TRIM([Part Time Non-Operator (Facility Maintenance) Employee Count]), ',', ''), '') AS NUMERIC(18,2)),
    TRY_CAST(NULLIF(REPLACE(TRIM([Total Part Time (Facility Maintenance) Employee Count]), ',', ''), '') AS NUMERIC(18,2)),
    TRY_CAST(NULLIF(REPLACE(TRIM([Part Time Operator (General Administration) Employee Count]), ',', ''), '') AS NUMERIC(18,2)),
    TRY_CAST(NULLIF(REPLACE(TRIM([Part Time Non-Operator (General Administration) Employee Count]), ',', ''), '') AS NUMERIC(18,2)),
    TRY_CAST(NULLIF(REPLACE(TRIM([Total Part Time (General Administration) Employee Count]), ',', ''), '') AS NUMERIC(18,2)),
    TRY_CAST(NULLIF(REPLACE(TRIM([Total Part Time Operator Employee Count]), ',', ''), '') AS NUMERIC(18,2)),
    TRY_CAST(NULLIF(REPLACE(TRIM([Total Part Time Non-Operator Employee Count]), ',', ''), '') AS NUMERIC(18,2)),
    TRY_CAST(NULLIF(REPLACE(TRIM([Total Part Time Employee Count]), ',', ''), '') AS NUMERIC(18,2))
FROM raw_HR.raw_2020_transit_agency_employees;

-- 2021 Data (Uses raw_2021, not raw_2019)
INSERT INTO stg_HR.stg_transit_agency_employees_2021 (
    ntd_id, agency_name, reporter_type, reporting_module, mode, tos,
    full_time_operator_vehicle_operations_hours_worked,
    full_time_non_operator_vehicle_operations_hours_worked,
    total_full_time_vehicle_operations_hours_worked,
    full_time_operator_vehicle_maintenance_hours_worked,
    full_time_non_operator_vehicle_maintenance_hours_worked,
    total_full_time_vehicle_maintenance_hours_worked,
    full_time_operator_facility_maintenance_hours_worked,
    full_time_non_operator_facility_maintenance_hours_worked,
    total_full_time_facility_maintenance_hours_worked,
    full_time_operator_general_administration_hours_worked,
    full_time_non_operator_general_administration_hours_worked,
    total_full_time_general_administration_hours_worked,
    total_full_time_operator_operating_labor_hours_worked,
    total_full_time_non_operator_operating_labor_hours_worked,
    total_full_time_operating_labor_hours_worked,
    total_full_time_operator_capital_labor_hours_worked,
    total_full_time_non_operator_capital_labor_hours_worked,
    total_full_time_capital_labor_hours_worked,
    total_full_time_operator_hours_worked,
    total_full_time_non_operator_hours_worked,
    total_full_time_hours_worked,
    full_time_operator_vehicle_operations_employee_count,
    full_time_non_operator_vehicle_operations_employee_count,
    total_full_time_vehicle_operations_employee_count,
    full_time_operator_vehicle_maintenance_employee_count,
    full_time_non_operator_vehicle_maintenance_employee_count,
    total_full_time_vehicle_maintenance_employee_count,
    full_time_operator_facility_maintenance_employee_count,
    full_time_non_operator_facility_maintenance_employee_count,
    total_full_time_facility_maintenance_employee_count,
    full_time_operator_general_administration_employee_count,
    full_time_non_operator_general_administration_employee_count,
    total_full_time_general_administration_employee_count,
    total_full_time_operator_employee_count,
    total_full_time_non_operator_employee_count,
    total_full_time_employee_count,
    part_time_operator_vehicle_operations_hours_worked,
    part_time_non_operator_vehicle_operations_hours_worked,
    total_part_time_vehicle_operations_hours_worked,
    part_time_operator_vehicle_maintenance_hours_worked,
    part_time_non_operator_vehicle_maintenance_hours_worked,
    total_part_time_vehicle_maintenance_hours_worked,
    part_time_operator_facility_maintenance_hours_worked,
    part_time_non_operator_facility_maintenance_hours_worked,
    total_part_time_facility_maintenance_hours_worked,
    part_time_operator_general_administration_hours_worked,
    part_time_non_operator_general_administration_hours_worked,
    total_part_time_general_administration_hours_worked,
    total_part_time_operator_hours_worked,
    total_part_time_non_operator_hours_worked,
    total_part_time_hours_worked,
    part_time_operator_vehicle_operations_employee_count,
    part_time_non_operator_vehicle_operations_employee_count,
    total_part_time_vehicle_operations_employee_count,
    part_time_operator_vehicle_maintenance_employee_count,
    part_time_non_operator_vehicle_maintenance_employee_count,
    total_part_time_vehicle_maintenance_employee_count,
    part_time_operator_facility_maintenance_employee_count,
    part_time_non_operator_facility_maintenance_employee_count,
    total_part_time_facility_maintenance_employee_count,
    part_time_operator_general_administration_employee_count,
    part_time_non_operator_general_administration_employee_count,
    total_part_time_general_administration_employee_count,
    total_part_time_operator_employee_count,
    total_part_time_non_operator_employee_count,
    total_part_time_employee_count
)
SELECT
    CAST(TRY_CAST(NULLIF(REPLACE(TRIM([NTD ID]), ',', ''), '') AS NUMERIC(18,0)) AS VARCHAR(50)),
    NULLIF(TRIM([Agency Name]), ''),
    NULLIF(TRIM([Reporter Type]), ''),
    NULLIF(TRIM([Reporting Module]), ''),
    NULLIF(TRIM([Mode]), ''),
    NULLIF(TRIM([TOS]), ''),
    TRY_CAST(TRY_CAST(NULLIF(REPLACE(TRIM([Full Time Operator (Vehicle Operations) Hours Worked]), ',', ''), '') AS NUMERIC(18,2)) AS INT),
    TRY_CAST(TRY_CAST(NULLIF(REPLACE(TRIM([Full Time Non-Operator (Vehicle Operations) Hours Worked]), ',', ''), '') AS NUMERIC(18,2)) AS INT),
    TRY_CAST(TRY_CAST(NULLIF(REPLACE(TRIM([Total Full Time (Vehicle Operations) Hours Worked]), ',', ''), '') AS NUMERIC(18,2)) AS INT),
    TRY_CAST(TRY_CAST(NULLIF(REPLACE(TRIM([Full Time Operator (Vehicle Maintenance) Hours Worked]), ',', ''), '') AS NUMERIC(18,2)) AS INT),
    TRY_CAST(TRY_CAST(NULLIF(REPLACE(TRIM([Full Time Non-Operator (Vehicle Maintenance) Hours Worked]), ',', ''), '') AS NUMERIC(18,2)) AS INT),
    TRY_CAST(TRY_CAST(NULLIF(REPLACE(TRIM([Total Full Time (Vehicle Maintenance) Hours Worked]), ',', ''), '') AS NUMERIC(18,2)) AS INT),
    TRY_CAST(TRY_CAST(NULLIF(REPLACE(TRIM([Full Time Operator (Facility Maintenance) Hours Worked]), ',', ''), '') AS NUMERIC(18,2)) AS INT),
    TRY_CAST(TRY_CAST(NULLIF(REPLACE(TRIM([Full Time Non-Operator (Facility Maintenance) Hours Worked]), ',', ''), '') AS NUMERIC(18,2)) AS INT),
    TRY_CAST(TRY_CAST(NULLIF(REPLACE(TRIM([Total Full Time (Facility Maintenance) Hours Worked]), ',', ''), '') AS NUMERIC(18,2)) AS INT),
    TRY_CAST(TRY_CAST(NULLIF(REPLACE(TRIM([Full Time Operator (General Administration) Hours Worked]), ',', ''), '') AS NUMERIC(18,2)) AS INT),
    TRY_CAST(TRY_CAST(NULLIF(REPLACE(TRIM([Full Time Non-Operator (General Administration) Hours Worked]), ',', ''), '') AS NUMERIC(18,2)) AS INT),
    TRY_CAST(TRY_CAST(NULLIF(REPLACE(TRIM([Total Full Time (General Administration) Hours Worked]), ',', ''), '') AS NUMERIC(18,2)) AS INT),
    TRY_CAST(TRY_CAST(NULLIF(REPLACE(TRIM([Total Full Time Operator (Operating Labor) Hours Worked]), ',', ''), '') AS NUMERIC(18,2)) AS INT),
    TRY_CAST(TRY_CAST(NULLIF(REPLACE(TRIM([Total Full Time Non-Operator (Operating Labor) Hours Worked]), ',', ''), '') AS NUMERIC(18,2)) AS INT),
    TRY_CAST(TRY_CAST(NULLIF(REPLACE(TRIM([Total Full Time (Operating Labor) Hours Worked]), ',', ''), '') AS NUMERIC(18,2)) AS INT),
    TRY_CAST(TRY_CAST(NULLIF(REPLACE(TRIM([Full Time Operator (Capital Labor) Hours Worked]), ',', ''), '') AS NUMERIC(18,2)) AS INT),
    TRY_CAST(TRY_CAST(NULLIF(REPLACE(TRIM([Full Time Non-Operator (Capital Labor) Hours Worked]), ',', ''), '') AS NUMERIC(18,2)) AS INT),
    TRY_CAST(TRY_CAST(NULLIF(REPLACE(TRIM([Total Full Time (Capital Labor) Hours Worked]), ',', ''), '') AS NUMERIC(18,2)) AS INT),
    TRY_CAST(TRY_CAST(NULLIF(REPLACE(TRIM([Total Full Time Operator Hours Worked]), ',', ''), '') AS NUMERIC(18,2)) AS INT),
    TRY_CAST(TRY_CAST(NULLIF(REPLACE(TRIM([Total Full Time Non-Operator Hours Worked]), ',', ''), '') AS NUMERIC(18,2)) AS INT),
    TRY_CAST(TRY_CAST(NULLIF(REPLACE(TRIM([Total Full Time Hours Worked]), ',', ''), '') AS NUMERIC(18,2)) AS INT),
    TRY_CAST(NULLIF(REPLACE(TRIM([Full Time Operator (Vehicle Operations) Employee Count]), ',', ''), '') AS NUMERIC(18,2)),
    TRY_CAST(NULLIF(REPLACE(TRIM([Full Time Non-Operator (Vehicle Operations) Employee Count]), ',', ''), '') AS NUMERIC(18,2)),
    TRY_CAST(NULLIF(REPLACE(TRIM([Total Full Time (Vehicle Operations) Employee Count]), ',', ''), '') AS NUMERIC(18,2)),
    TRY_CAST(NULLIF(REPLACE(TRIM([Full Time Operator (Vehicle Maintenance) Employee Count]), ',', ''), '') AS NUMERIC(18,2)),
    TRY_CAST(NULLIF(REPLACE(TRIM([Full Time Non-Operator (Vehicle Maintenance) Employee Count]), ',', ''), '') AS NUMERIC(18,2)),
    TRY_CAST(NULLIF(REPLACE(TRIM([Total Full Time (Vehicle Maintenance) Employee Count]), ',', ''), '') AS NUMERIC(18,2)),
    TRY_CAST(NULLIF(REPLACE(TRIM([Full Time Operator (Facility Maintenance) Employee Count]), ',', ''), '') AS NUMERIC(18,2)),
    TRY_CAST(NULLIF(REPLACE(TRIM([Full Time Non-Operator (Facility Maintenance) Employee Count]), ',', ''), '') AS NUMERIC(18,2)),
    TRY_CAST(NULLIF(REPLACE(TRIM([Total Full Time (Facility Maintenance) Employee Count]), ',', ''), '') AS NUMERIC(18,2)),
    TRY_CAST(NULLIF(REPLACE(TRIM([Full Time Operator (General Administration) Employee Count]), ',', ''), '') AS NUMERIC(18,2)),
    TRY_CAST(NULLIF(REPLACE(TRIM([Full Time Non-Operator (General Administration) Employee Count]), ',', ''), '') AS NUMERIC(18,2)),
    TRY_CAST(NULLIF(REPLACE(TRIM([Total Full Time (General Administration) Employee Count]), ',', ''), '') AS NUMERIC(18,2)),
    TRY_CAST(NULLIF(REPLACE(TRIM([Total Full Time Operator Employee Count]), ',', ''), '') AS NUMERIC(18,2)),
    TRY_CAST(NULLIF(REPLACE(TRIM([Total Full Time Non-Operator Employee Count]), ',', ''), '') AS NUMERIC(18,2)),
    TRY_CAST(NULLIF(REPLACE(TRIM([Total Full Time Employee Count]), ',', ''), '') AS NUMERIC(18,2)),
    TRY_CAST(TRY_CAST(NULLIF(REPLACE(TRIM([Part Time Operator (Vehicle Operations) Hours Worked]), ',', ''), '') AS NUMERIC(18,2)) AS INT),
    TRY_CAST(TRY_CAST(NULLIF(REPLACE(TRIM([Part Time Non-Operator (Vehicle Operations) Hours Worked]), ',', ''), '') AS NUMERIC(18,2)) AS INT),
    TRY_CAST(TRY_CAST(NULLIF(REPLACE(TRIM([Total Part Time (Vehicle Operations) Hours Worked]), ',', ''), '') AS NUMERIC(18,2)) AS INT),
    TRY_CAST(TRY_CAST(NULLIF(REPLACE(TRIM([Part Time Operator (Vehicle Maintenance) Hours Worked]), ',', ''), '') AS NUMERIC(18,2)) AS INT),
    TRY_CAST(TRY_CAST(NULLIF(REPLACE(TRIM([Part Time Non-Operator (Vehicle Maintenance) Hours Worked]), ',', ''), '') AS NUMERIC(18,2)) AS INT),
    TRY_CAST(TRY_CAST(NULLIF(REPLACE(TRIM([Total Part Time (Vehicle Maintenance) Hours Worked]), ',', ''), '') AS NUMERIC(18,2)) AS INT),
    TRY_CAST(TRY_CAST(NULLIF(REPLACE(TRIM([Part Time Operator (Facility Maintenance) Hours Worked]), ',', ''), '') AS NUMERIC(18,2)) AS INT),
    TRY_CAST(TRY_CAST(NULLIF(REPLACE(TRIM([Part Time Non-Operator (Facility Maintenance) Hours Worked]), ',', ''), '') AS NUMERIC(18,2)) AS INT),
    TRY_CAST(TRY_CAST(NULLIF(REPLACE(TRIM([Total Part Time (Facility Maintenance) Hours Worked]), ',', ''), '') AS NUMERIC(18,2)) AS INT),
    TRY_CAST(TRY_CAST(NULLIF(REPLACE(TRIM([Part Time Operator (General Administration) Hours Worked]), ',', ''), '') AS NUMERIC(18,2)) AS INT),
    TRY_CAST(TRY_CAST(NULLIF(REPLACE(TRIM([Part Time Non-Operator (General Administration) Hours Worked]), ',', ''), '') AS NUMERIC(18,2)) AS INT),
    TRY_CAST(TRY_CAST(NULLIF(REPLACE(TRIM([Total Part Time (General Administration) Hours Worked]), ',', ''), '') AS NUMERIC(18,2)) AS INT),
    TRY_CAST(TRY_CAST(NULLIF(REPLACE(TRIM([Total Part Time Operator Hours Worked]), ',', ''), '') AS NUMERIC(18,2)) AS INT),
    TRY_CAST(TRY_CAST(NULLIF(REPLACE(TRIM([Total Part Time Non-Operator Hours Worked]), ',', ''), '') AS NUMERIC(18,2)) AS INT),
    TRY_CAST(TRY_CAST(NULLIF(REPLACE(TRIM([Total Part Time Hours Worked]), ',', ''), '') AS NUMERIC(18,2)) AS INT),
    TRY_CAST(NULLIF(REPLACE(TRIM([Part Time Operator (Vehicle Operations) Employee Count]), ',', ''), '') AS NUMERIC(18,2)),
    TRY_CAST(NULLIF(REPLACE(TRIM([Part Time Non-Operator (Vehicle Operations) Employee Count]), ',', ''), '') AS NUMERIC(18,2)),
    TRY_CAST(NULLIF(REPLACE(TRIM([Total Part Time (Vehicle Operations) Employee Count]), ',', ''), '') AS NUMERIC(18,2)),
    TRY_CAST(NULLIF(REPLACE(TRIM([Part Time Operator (Vehicle Maintenance) Employee Count]), ',', ''), '') AS NUMERIC(18,2)),
    TRY_CAST(NULLIF(REPLACE(TRIM([Part Time Non-Operator (Vehicle Maintenance) Employee Count]), ',', ''), '') AS NUMERIC(18,2)),
    TRY_CAST(NULLIF(REPLACE(TRIM([Total Part Time (Vehicle Maintenance) Employee Count]), ',', ''), '') AS NUMERIC(18,2)),
    TRY_CAST(NULLIF(REPLACE(TRIM([Part Time Operator (Facility Maintenance) Employee Count]), ',', ''), '') AS NUMERIC(18,2)),
    TRY_CAST(NULLIF(REPLACE(TRIM([Part Time Non-Operator (Facility Maintenance) Employee Count]), ',', ''), '') AS NUMERIC(18,2)),
    TRY_CAST(NULLIF(REPLACE(TRIM([Total Part Time (Facility Maintenance) Employee Count]), ',', ''), '') AS NUMERIC(18,2)),
    TRY_CAST(NULLIF(REPLACE(TRIM([Part Time Operator (General Administration) Employee Count]), ',', ''), '') AS NUMERIC(18,2)),
    TRY_CAST(NULLIF(REPLACE(TRIM([Part Time Non-Operator (General Administration) Employee Count]), ',', ''), '') AS NUMERIC(18,2)),
    TRY_CAST(NULLIF(REPLACE(TRIM([Total Part Time (General Administration) Employee Count]), ',', ''), '') AS NUMERIC(18,2)),
    TRY_CAST(NULLIF(REPLACE(TRIM([Total Part Time Operator Employee Count]), ',', ''), '') AS NUMERIC(18,2)),
    TRY_CAST(NULLIF(REPLACE(TRIM([Total Part Time Non-Operator Employee Count]), ',', ''), '') AS NUMERIC(18,2)),
    TRY_CAST(NULLIF(REPLACE(TRIM([Total Part Time Employee Count]), ',', ''), '') AS NUMERIC(18,2))
FROM raw_HR.raw_2021_transit_agency_employees;

-- 2022 Data (Column names have leading/trailing spaces in raw table)
INSERT INTO stg_HR.stg_transit_agency_employees_2022 (
    ntd_id, agency_name, reporter_type, reporting_module, mode, tos,
    full_time_operator_vehicle_operations_hours_worked,
    full_time_non_operator_vehicle_operations_hours_worked,
    total_full_time_vehicle_operations_hours_worked,
    full_time_operator_vehicle_maintenance_hours_worked,
    full_time_non_operator_vehicle_maintenance_hours_worked,
    total_full_time_vehicle_maintenance_hours_worked,
    full_time_operator_facility_maintenance_hours_worked,
    full_time_non_operator_facility_maintenance_hours_worked,
    total_full_time_facility_maintenance_hours_worked,
    full_time_operator_general_administration_hours_worked,
    full_time_non_operator_general_administration_hours_worked,
    total_full_time_general_administration_hours_worked,
    total_full_time_operator_operating_labor_hours_worked,
    total_full_time_non_operator_operating_labor_hours_worked,
    total_full_time_operating_labor_hours_worked,
    total_full_time_operator_capital_labor_hours_worked,
    total_full_time_non_operator_capital_labor_hours_worked,
    total_full_time_capital_labor_hours_worked,
    total_full_time_operator_hours_worked,
    total_full_time_non_operator_hours_worked,
    total_full_time_hours_worked,
    full_time_operator_vehicle_operations_employee_count,
    full_time_non_operator_vehicle_operations_employee_count,
    total_full_time_vehicle_operations_employee_count,
    full_time_operator_vehicle_maintenance_employee_count,
    full_time_non_operator_vehicle_maintenance_employee_count,
    total_full_time_vehicle_maintenance_employee_count,
    full_time_operator_facility_maintenance_employee_count,
    full_time_non_operator_facility_maintenance_employee_count,
    total_full_time_facility_maintenance_employee_count,
    full_time_operator_general_administration_employee_count,
    full_time_non_operator_general_administration_employee_count,
    total_full_time_general_administration_employee_count,
    total_full_time_operator_employee_count,
    total_full_time_non_operator_employee_count,
    total_full_time_employee_count,
    part_time_operator_vehicle_operations_hours_worked,
    part_time_non_operator_vehicle_operations_hours_worked,
    total_part_time_vehicle_operations_hours_worked,
    part_time_operator_vehicle_maintenance_hours_worked,
    part_time_non_operator_vehicle_maintenance_hours_worked,
    total_part_time_vehicle_maintenance_hours_worked,
    part_time_operator_facility_maintenance_hours_worked,
    part_time_non_operator_facility_maintenance_hours_worked,
    total_part_time_facility_maintenance_hours_worked,
    part_time_operator_general_administration_hours_worked,
    part_time_non_operator_general_administration_hours_worked,
    total_part_time_general_administration_hours_worked,
    total_part_time_operator_hours_worked,
    total_part_time_non_operator_hours_worked,
    total_part_time_hours_worked,
    part_time_operator_vehicle_operations_employee_count,
    part_time_non_operator_vehicle_operations_employee_count,
    total_part_time_vehicle_operations_employee_count,
    part_time_operator_vehicle_maintenance_employee_count,
    part_time_non_operator_vehicle_maintenance_employee_count,
    total_part_time_vehicle_maintenance_employee_count,
    part_time_operator_facility_maintenance_employee_count,
    part_time_non_operator_facility_maintenance_employee_count,
    total_part_time_facility_maintenance_employee_count,
    part_time_operator_general_administration_employee_count,
    part_time_non_operator_general_administration_employee_count,
    total_part_time_general_administration_employee_count,
    total_part_time_operator_employee_count,
    total_part_time_non_operator_employee_count,
    total_part_time_employee_count
)
SELECT
    CAST(TRY_CAST(NULLIF(REPLACE(TRIM([NTD ID]), ',', ''), '') AS NUMERIC(18,0)) AS VARCHAR(50)),
    NULLIF(TRIM([Agency Name]), ''),
    NULLIF(TRIM([Reporter Type]), ''),
    NULLIF(TRIM([Reporting Module]), ''),
    NULLIF(TRIM([Mode]), ''),
    NULLIF(TRIM([TOS]), ''),
    TRY_CAST(TRY_CAST(NULLIF(REPLACE(TRIM([ Full Time Operator (Vehicle Operations) Hours Worked ]), ',', ''), '') AS NUMERIC(18,2)) AS INT),
    TRY_CAST(TRY_CAST(NULLIF(REPLACE(TRIM([ Full Time Non-Operator (Vehicle Operations) Hours Worked ]), ',', ''), '') AS NUMERIC(18,2)) AS INT),
    TRY_CAST(TRY_CAST(NULLIF(REPLACE(TRIM([ Total Full Time (Vehicle Operations) Hours Worked ]), ',', ''), '') AS NUMERIC(18,2)) AS INT),
    TRY_CAST(TRY_CAST(NULLIF(REPLACE(TRIM([ Full Time Operator (Vehicle Maintenance) Hours Worked ]), ',', ''), '') AS NUMERIC(18,2)) AS INT),
    TRY_CAST(TRY_CAST(NULLIF(REPLACE(TRIM([ Full Time Non-Operator (Vehicle Maintenance) Hours Worked ]), ',', ''), '') AS NUMERIC(18,2)) AS INT),
    TRY_CAST(TRY_CAST(NULLIF(REPLACE(TRIM([ Total Full Time (Vehicle Maintenance) Hours Worked ]), ',', ''), '') AS NUMERIC(18,2)) AS INT),
    TRY_CAST(TRY_CAST(NULLIF(REPLACE(TRIM([ Full Time Operator (Facility Maintenance) Hours Worked ]), ',', ''), '') AS NUMERIC(18,2)) AS INT),
    TRY_CAST(TRY_CAST(NULLIF(REPLACE(TRIM([ Full Time Non-Operator (Facility Maintenance) Hours Worked ]), ',', ''), '') AS NUMERIC(18,2)) AS INT),
    TRY_CAST(TRY_CAST(NULLIF(REPLACE(TRIM([ Total Full Time (Facility Maintenance) Hours Worked ]), ',', ''), '') AS NUMERIC(18,2)) AS INT),
    TRY_CAST(TRY_CAST(NULLIF(REPLACE(TRIM([ Full Time Operator (General Administration) Hours Worked ]), ',', ''), '') AS NUMERIC(18,2)) AS INT),
    TRY_CAST(TRY_CAST(NULLIF(REPLACE(TRIM([ Full Time Non-Operator (General Administration) Hours Worked ]), ',', ''), '') AS NUMERIC(18,2)) AS INT),
    TRY_CAST(TRY_CAST(NULLIF(REPLACE(TRIM([ Total Full Time (General Administration) Hours Worked ]), ',', ''), '') AS NUMERIC(18,2)) AS INT),
    TRY_CAST(TRY_CAST(NULLIF(REPLACE(TRIM([ Total Full Time Operator (Operating Labor) Hours Worked ]), ',', ''), '') AS NUMERIC(18,2)) AS INT),
    TRY_CAST(TRY_CAST(NULLIF(REPLACE(TRIM([ Total Full Time Non-Operator (Operating Labor) Hours Worked ]), ',', ''), '') AS NUMERIC(18,2)) AS INT),
    TRY_CAST(TRY_CAST(NULLIF(REPLACE(TRIM([ Total Full Time (Operating Labor) Hours Worked ]), ',', ''), '') AS NUMERIC(18,2)) AS INT),
    TRY_CAST(TRY_CAST(NULLIF(REPLACE(TRIM([ Full Time Operator (Capital Labor) Hours Worked ]), ',', ''), '') AS NUMERIC(18,2)) AS INT),
    TRY_CAST(TRY_CAST(NULLIF(REPLACE(TRIM([ Full Time Non-Operator (Capital Labor) Hours Worked ]), ',', ''), '') AS NUMERIC(18,2)) AS INT),
    TRY_CAST(TRY_CAST(NULLIF(REPLACE(TRIM([ Total Full Time (Capital Labor) Hours Worked ]), ',', ''), '') AS NUMERIC(18,2)) AS INT),
    TRY_CAST(TRY_CAST(NULLIF(REPLACE(TRIM([ Total Full Time Operator Hours Worked ]), ',', ''), '') AS NUMERIC(18,2)) AS INT),
    TRY_CAST(TRY_CAST(NULLIF(REPLACE(TRIM([ Total Full Time Non-Operator Hours Worked ]), ',', ''), '') AS NUMERIC(18,2)) AS INT),
    TRY_CAST(TRY_CAST(NULLIF(REPLACE(TRIM([ Total Full Time Hours Worked ]), ',', ''), '') AS NUMERIC(18,2)) AS INT),
    TRY_CAST(NULLIF(REPLACE(TRIM([ Full Time Operator (Vehicle Operations) Employee Count ]), ',', ''), '') AS NUMERIC(18,2)),
    TRY_CAST(NULLIF(REPLACE(TRIM([ Full Time Non-Operator (Vehicle Operations) Employee Count ]), ',', ''), '') AS NUMERIC(18,2)),
    TRY_CAST(NULLIF(REPLACE(TRIM([ Total Full Time (Vehicle Operations) Employee Count ]), ',', ''), '') AS NUMERIC(18,2)),
    TRY_CAST(NULLIF(REPLACE(TRIM([ Full Time Operator (Vehicle Maintenance) Employee Count ]), ',', ''), '') AS NUMERIC(18,2)),
    TRY_CAST(NULLIF(REPLACE(TRIM([ Full Time Non-Operator (Vehicle Maintenance) Employee Count ]), ',', ''), '') AS NUMERIC(18,2)),
    TRY_CAST(NULLIF(REPLACE(TRIM([ Total Full Time (Vehicle Maintenance) Employee Count ]), ',', ''), '') AS NUMERIC(18,2)),
    TRY_CAST(NULLIF(REPLACE(TRIM([ Full Time Operator (Facility Maintenance) Employee Count ]), ',', ''), '') AS NUMERIC(18,2)),
    TRY_CAST(NULLIF(REPLACE(TRIM([ Full Time Non-Operator (Facility Maintenance) Employee Count ]), ',', ''), '') AS NUMERIC(18,2)),
    TRY_CAST(NULLIF(REPLACE(TRIM([ Total Full Time (Facility Maintenance) Employee Count ]), ',', ''), '') AS NUMERIC(18,2)),
    TRY_CAST(NULLIF(REPLACE(TRIM([ Full Time Operator (General Administration) Employee Count ]), ',', ''), '') AS NUMERIC(18,2)),
    TRY_CAST(NULLIF(REPLACE(TRIM([ Full Time Non-Operator (General Administration) Employee Count ]), ',', ''), '') AS NUMERIC(18,2)),
    TRY_CAST(NULLIF(REPLACE(TRIM([ Total Full Time (General Administration) Employee Count ]), ',', ''), '') AS NUMERIC(18,2)),
    TRY_CAST(NULLIF(REPLACE(TRIM([ Total Full Time Operator Employee Count ]), ',', ''), '') AS NUMERIC(18,2)),
    TRY_CAST(NULLIF(REPLACE(TRIM([ Total Full Time Non-Operator Employee Count ]), ',', ''), '') AS NUMERIC(18,2)),
    TRY_CAST(NULLIF(REPLACE(TRIM([ Total Full Time Employee Count ]), ',', ''), '') AS NUMERIC(18,2)),
    TRY_CAST(TRY_CAST(NULLIF(REPLACE(TRIM([ Part Time Operator (Vehicle Operations) Hours Worked ]), ',', ''), '') AS NUMERIC(18,2)) AS INT),
    TRY_CAST(TRY_CAST(NULLIF(REPLACE(TRIM([ Part Time Non-Operator (Vehicle Operations) Hours Worked ]), ',', ''), '') AS NUMERIC(18,2)) AS INT),
    TRY_CAST(TRY_CAST(NULLIF(REPLACE(TRIM([ Total Part Time (Vehicle Operations) Hours Worked ]), ',', ''), '') AS NUMERIC(18,2)) AS INT),
    TRY_CAST(TRY_CAST(NULLIF(REPLACE(TRIM([ Part Time Operator (Vehicle Maintenance) Hours Worked ]), ',', ''), '') AS NUMERIC(18,2)) AS INT),
    TRY_CAST(TRY_CAST(NULLIF(REPLACE(TRIM([ Part Time Non-Operator (Vehicle Maintenance) Hours Worked ]), ',', ''), '') AS NUMERIC(18,2)) AS INT),
    TRY_CAST(TRY_CAST(NULLIF(REPLACE(TRIM([ Total Part Time (Vehicle Maintenance) Hours Worked ]), ',', ''), '') AS NUMERIC(18,2)) AS INT),
    TRY_CAST(TRY_CAST(NULLIF(REPLACE(TRIM([ Part Time Operator (Facility Maintenance) Hours Worked ]), ',', ''), '') AS NUMERIC(18,2)) AS INT),
    TRY_CAST(TRY_CAST(NULLIF(REPLACE(TRIM([ Part Time Non-Operator (Facility Maintenance) Hours Worked ]), ',', ''), '') AS NUMERIC(18,2)) AS INT),
    TRY_CAST(TRY_CAST(NULLIF(REPLACE(TRIM([ Total Part Time (Facility Maintenance) Hours Worked ]), ',', ''), '') AS NUMERIC(18,2)) AS INT),
    TRY_CAST(TRY_CAST(NULLIF(REPLACE(TRIM([ Part Time Operator (General Administration) Hours Worked ]), ',', ''), '') AS NUMERIC(18,2)) AS INT),
    TRY_CAST(TRY_CAST(NULLIF(REPLACE(TRIM([ Part Time Non-Operator (General Administration) Hours Worked ]), ',', ''), '') AS NUMERIC(18,2)) AS INT),
    TRY_CAST(TRY_CAST(NULLIF(REPLACE(TRIM([ Total Part Time (General Administration) Hours Worked ]), ',', ''), '') AS NUMERIC(18,2)) AS INT),
    TRY_CAST(TRY_CAST(NULLIF(REPLACE(TRIM([ Total Part Time Operator Hours Worked ]), ',', ''), '') AS NUMERIC(18,2)) AS INT),
    TRY_CAST(TRY_CAST(NULLIF(REPLACE(TRIM([ Total Part Time Non-Operator Hours Worked ]), ',', ''), '') AS NUMERIC(18,2)) AS INT),
    TRY_CAST(TRY_CAST(NULLIF(REPLACE(TRIM([ Total Part Time Hours Worked ]), ',', ''), '') AS NUMERIC(18,2)) AS INT),
    TRY_CAST(NULLIF(TRIM([ Part Time Operator (Vehicle Operations) Employee Count ]), '') AS NUMERIC(18,2)),
    TRY_CAST(NULLIF(TRIM([ Part Time Non-Operator (Vehicle Operations) Employee Count ]), '') AS NUMERIC(18,2)),
    TRY_CAST(NULLIF(TRIM([ Total Part Time (Vehicle Operations) Employee Count ]), '') AS NUMERIC(18,2)),
    TRY_CAST(NULLIF(TRIM([ Part Time Operator (Vehicle Maintenance) Employee Count ]), '') AS NUMERIC(18,2)),
    TRY_CAST(NULLIF(TRIM([ Part Time Non-Operator (Vehicle Maintenance) Employee Count ]), '') AS NUMERIC(18,2)),
    TRY_CAST(NULLIF(TRIM([ Total Part Time (Vehicle Maintenance) Employee Count ]), '') AS NUMERIC(18,2)),
    TRY_CAST(NULLIF(TRIM([ Part Time Operator (Facility Maintenance) Employee Count ]), '') AS NUMERIC(18,2)),
    TRY_CAST(NULLIF(TRIM([ Part Time Non-Operator (Facility Maintenance) Employee Count ]), '') AS NUMERIC(18,2)),
    TRY_CAST(NULLIF(TRIM([ Total Part Time (Facility Maintenance) Employee Count ]), '') AS NUMERIC(18,2)),
    TRY_CAST(NULLIF(TRIM([ Part Time Operator (General Administration) Employee Count ]), '') AS NUMERIC(18,2)),
    TRY_CAST(NULLIF(TRIM([ Part Time Non-Operator (General Administration) Employee Count ]), '') AS NUMERIC(18,2)),
    TRY_CAST(NULLIF(TRIM([ Total Part Time (General Administration) Employee Count ]), '') AS NUMERIC(18,2)),
    TRY_CAST(NULLIF(TRIM([ Total Part Time Operator Employee Count ]), '') AS NUMERIC(18,2)),
    TRY_CAST(NULLIF(TRIM([ Total Part Time Non-Operator Employee Count ]), '') AS NUMERIC(18,2)),
    TRY_CAST(NULLIF(REPLACE(TRIM([ Total Part Time Employee Count ]), ',', ''), '') AS NUMERIC(18,2))
FROM raw_HR.raw_2022_transit_agency_employees;

-- 2023 Data (Column names have leading/trailing spaces in raw table)
INSERT INTO stg_HR.stg_transit_agency_employees_2023 (
    ntd_id, agency_name, reporter_type, reporting_module, mode, tos,
    full_time_operator_vehicle_operations_hours_worked,
    full_time_non_operator_vehicle_operations_hours_worked,
    total_full_time_vehicle_operations_hours_worked,
    full_time_operator_vehicle_maintenance_hours_worked,
    full_time_non_operator_vehicle_maintenance_hours_worked,
    total_full_time_vehicle_maintenance_hours_worked,
    full_time_operator_facility_maintenance_hours_worked,
    full_time_non_operator_facility_maintenance_hours_worked,
    total_full_time_facility_maintenance_hours_worked,
    full_time_operator_general_administration_hours_worked,
    full_time_non_operator_general_administration_hours_worked,
    total_full_time_general_administration_hours_worked,
    total_full_time_operator_operating_labor_hours_worked,
    total_full_time_non_operator_operating_labor_hours_worked,
    total_full_time_operating_labor_hours_worked,
    total_full_time_operator_capital_labor_hours_worked,
    total_full_time_non_operator_capital_labor_hours_worked,
    total_full_time_capital_labor_hours_worked,
    total_full_time_operator_hours_worked,
    total_full_time_non_operator_hours_worked,
    total_full_time_hours_worked,
    full_time_operator_vehicle_operations_employee_count,
    full_time_non_operator_vehicle_operations_employee_count,
    total_full_time_vehicle_operations_employee_count,
    full_time_operator_vehicle_maintenance_employee_count,
    full_time_non_operator_vehicle_maintenance_employee_count,
    total_full_time_vehicle_maintenance_employee_count,
    full_time_operator_facility_maintenance_employee_count,
    full_time_non_operator_facility_maintenance_employee_count,
    total_full_time_facility_maintenance_employee_count,
    full_time_operator_general_administration_employee_count,
    full_time_non_operator_general_administration_employee_count,
    total_full_time_general_administration_employee_count,
    total_full_time_operator_employee_count,
    total_full_time_non_operator_employee_count,
    total_full_time_employee_count,
    part_time_operator_vehicle_operations_hours_worked,
    part_time_non_operator_vehicle_operations_hours_worked,
    total_part_time_vehicle_operations_hours_worked,
    part_time_operator_vehicle_maintenance_hours_worked,
    part_time_non_operator_vehicle_maintenance_hours_worked,
    total_part_time_vehicle_maintenance_hours_worked,
    part_time_operator_facility_maintenance_hours_worked,
    part_time_non_operator_facility_maintenance_hours_worked,
    total_part_time_facility_maintenance_hours_worked,
    part_time_operator_general_administration_hours_worked,
    part_time_non_operator_general_administration_hours_worked,
    total_part_time_general_administration_hours_worked,
    total_part_time_operator_hours_worked,
    total_part_time_non_operator_hours_worked,
    total_part_time_hours_worked,
    part_time_operator_vehicle_operations_employee_count,
    part_time_non_operator_vehicle_operations_employee_count,
    total_part_time_vehicle_operations_employee_count,
    part_time_operator_vehicle_maintenance_employee_count,
    part_time_non_operator_vehicle_maintenance_employee_count,
    total_part_time_vehicle_maintenance_employee_count,
    part_time_operator_facility_maintenance_employee_count,
    part_time_non_operator_facility_maintenance_employee_count,
    total_part_time_facility_maintenance_employee_count,
    part_time_operator_general_administration_employee_count,
    part_time_non_operator_general_administration_employee_count,
    total_part_time_general_administration_employee_count,
    total_part_time_operator_employee_count,
    total_part_time_non_operator_employee_count,
    total_part_time_employee_count
)
SELECT
    CAST(TRY_CAST(NULLIF(REPLACE(TRIM([NTD ID]), ',', ''), '') AS NUMERIC(18,0)) AS VARCHAR(50)),
    NULLIF(TRIM([Agency Name]), ''),
    NULLIF(TRIM([Reporter Type]), ''),
    NULLIF(TRIM([Reporting Module]), ''),
    NULLIF(TRIM([Mode]), ''),
    NULLIF(TRIM([TOS]), ''),
    TRY_CAST(TRY_CAST(NULLIF(REPLACE(TRIM([ Full Time Operator (Vehicle Operations) Hours Worked ]), ',', ''), '') AS NUMERIC(18,2)) AS INT),
    TRY_CAST(TRY_CAST(NULLIF(REPLACE(TRIM([ Full Time Non-Operator (Vehicle Operations) Hours Worked ]), ',', ''), '') AS NUMERIC(18,2)) AS INT),
    TRY_CAST(TRY_CAST(NULLIF(REPLACE(TRIM([ Total Full Time (Vehicle Operations) Hours Worked ]), ',', ''), '') AS NUMERIC(18,2)) AS INT),
    TRY_CAST(TRY_CAST(NULLIF(REPLACE(TRIM([ Full Time Operator (Vehicle Maintenance) Hours Worked ]), ',', ''), '') AS NUMERIC(18,2)) AS INT),
    TRY_CAST(TRY_CAST(NULLIF(REPLACE(TRIM([ Full Time Non-Operator (Vehicle Maintenance) Hours Worked ]), ',', ''), '') AS NUMERIC(18,2)) AS INT),
    TRY_CAST(TRY_CAST(NULLIF(REPLACE(TRIM([ Total Full Time (Vehicle Maintenance) Hours Worked ]), ',', ''), '') AS NUMERIC(18,2)) AS INT),
    TRY_CAST(TRY_CAST(NULLIF(REPLACE(TRIM([ Full Time Operator (Facility Maintenance) Hours Worked ]), ',', ''), '') AS NUMERIC(18,2)) AS INT),
    TRY_CAST(TRY_CAST(NULLIF(REPLACE(TRIM([ Full Time Non-Operator (Facility Maintenance) Hours Worked ]), ',', ''), '') AS NUMERIC(18,2)) AS INT),
    TRY_CAST(TRY_CAST(NULLIF(REPLACE(TRIM([ Total Full Time (Facility Maintenance) Hours Worked ]), ',', ''), '') AS NUMERIC(18,2)) AS INT),
    TRY_CAST(TRY_CAST(NULLIF(REPLACE(TRIM([ Full Time Operator (General Administration) Hours Worked ]), ',', ''), '') AS NUMERIC(18,2)) AS INT),
    TRY_CAST(TRY_CAST(NULLIF(REPLACE(TRIM([ Full Time Non-Operator (General Administration) Hours Worked ]), ',', ''), '') AS NUMERIC(18,2)) AS INT),
    TRY_CAST(TRY_CAST(NULLIF(REPLACE(TRIM([ Total Full Time (General Administration) Hours Worked ]), ',', ''), '') AS NUMERIC(18,2)) AS INT),
    TRY_CAST(TRY_CAST(NULLIF(REPLACE(TRIM([ Total Full Time Operator (Operating Labor) Hours Worked ]), ',', ''), '') AS NUMERIC(18,2)) AS INT),
    TRY_CAST(TRY_CAST(NULLIF(REPLACE(TRIM([ Total Full Time Non-Operator (Operating Labor) Hours Worked ]), ',', ''), '') AS NUMERIC(18,2)) AS INT),
    TRY_CAST(TRY_CAST(NULLIF(REPLACE(TRIM([ Total Full Time (Operating Labor) Hours Worked ]), ',', ''), '') AS NUMERIC(18,2)) AS INT),
    TRY_CAST(TRY_CAST(NULLIF(REPLACE(TRIM([ Full Time Operator (Capital Labor) Hours Worked ]), ',', ''), '') AS NUMERIC(18,2)) AS INT),
    TRY_CAST(TRY_CAST(NULLIF(REPLACE(TRIM([ Full Time Non-Operator (Capital Labor) Hours Worked ]), ',', ''), '') AS NUMERIC(18,2)) AS INT),
    TRY_CAST(TRY_CAST(NULLIF(REPLACE(TRIM([ Total Full Time (Capital Labor) Hours Worked ]), ',', ''), '') AS NUMERIC(18,2)) AS INT),
    TRY_CAST(TRY_CAST(NULLIF(REPLACE(TRIM([ Total Full Time Operator Hours Worked ]), ',', ''), '') AS NUMERIC(18,2)) AS INT),
    TRY_CAST(TRY_CAST(NULLIF(REPLACE(TRIM([ Total Full Time Non-Operator Hours Worked ]), ',', ''), '') AS NUMERIC(18,2)) AS INT),
    TRY_CAST(TRY_CAST(NULLIF(REPLACE(TRIM([ Total Full Time Hours Worked ]), ',', ''), '') AS NUMERIC(18,2)) AS INT),
    TRY_CAST(NULLIF(TRIM([ Full Time Operator (Vehicle Operations) Employee Count ]), '') AS NUMERIC(18,2)),
    TRY_CAST(NULLIF(TRIM([ Full Time Non-Operator (Vehicle Operations) Employee Count ]), '') AS NUMERIC(18,2)),
    TRY_CAST(NULLIF(TRIM([ Total Full Time (Vehicle Operations) Employee Count ]), '') AS NUMERIC(18,2)),
    TRY_CAST(NULLIF(TRIM([ Full Time Operator (Vehicle Maintenance) Employee Count ]), '') AS NUMERIC(18,2)),
    TRY_CAST(NULLIF(TRIM([ Full Time Non-Operator (Vehicle Maintenance) Employee Count ]), '') AS NUMERIC(18,2)),
    TRY_CAST(NULLIF(TRIM([ Total Full Time (Vehicle Maintenance) Employee Count ]), '') AS NUMERIC(18,2)),
    TRY_CAST(NULLIF(TRIM([ Full Time Operator (Facility Maintenance) Employee Count ]), '') AS NUMERIC(18,2)),
    TRY_CAST(NULLIF(TRIM([ Full Time Non-Operator (Facility Maintenance) Employee Count ]), '') AS NUMERIC(18,2)),
    TRY_CAST(NULLIF(TRIM([ Total Full Time (Facility Maintenance) Employee Count ]), '') AS NUMERIC(18,2)),
    TRY_CAST(NULLIF(TRIM([ Full Time Operator (General Administration) Employee Count ]), '') AS NUMERIC(18,2)),
    TRY_CAST(NULLIF(TRIM([ Full Time Non-Operator (General Administration) Employee Count ]), '') AS NUMERIC(18,2)),
    TRY_CAST(NULLIF(TRIM([ Total Full Time (General Administration) Employee Count ]), '') AS NUMERIC(18,2)),
    TRY_CAST(NULLIF(TRIM([ Total Full Time Operator Employee Count ]), '') AS NUMERIC(18,2)),
    TRY_CAST(NULLIF(TRIM([ Total Full Time Non-Operator Employee Count ]), '') AS NUMERIC(18,2)),
    TRY_CAST(NULLIF(TRIM([ Total Full Time Employee Count ]), '') AS NUMERIC(18,2)),
    TRY_CAST(TRY_CAST(NULLIF(REPLACE(TRIM([ Part Time Operator (Vehicle Operations) Hours Worked ]), ',', ''), '') AS NUMERIC(18,2)) AS INT),
    TRY_CAST(TRY_CAST(NULLIF(REPLACE(TRIM([ Part Time Non-Operator (Vehicle Operations) Hours Worked ]), ',', ''), '') AS NUMERIC(18,2)) AS INT),
    TRY_CAST(TRY_CAST(NULLIF(REPLACE(TRIM([ Total Part Time (Vehicle Operations) Hours Worked ]), ',', ''), '') AS NUMERIC(18,2)) AS INT),
    TRY_CAST(TRY_CAST(NULLIF(REPLACE(TRIM([ Part Time Operator (Vehicle Maintenance) Hours Worked ]), ',', ''), '') AS NUMERIC(18,2)) AS INT),
    TRY_CAST(TRY_CAST(NULLIF(REPLACE(TRIM([ Part Time Non-Operator (Vehicle Maintenance) Hours Worked ]), ',', ''), '') AS NUMERIC(18,2)) AS INT),
    TRY_CAST(TRY_CAST(NULLIF(REPLACE(TRIM([ Total Part Time (Vehicle Maintenance) Hours Worked ]), ',', ''), '') AS NUMERIC(18,2)) AS INT),
    TRY_CAST(TRY_CAST(NULLIF(REPLACE(TRIM([ Part Time Operator (Facility Maintenance) Hours Worked ]), ',', ''), '') AS NUMERIC(18,2)) AS INT),
    TRY_CAST(TRY_CAST(NULLIF(REPLACE(TRIM([ Part Time Non-Operator (Facility Maintenance) Hours Worked ]), ',', ''), '') AS NUMERIC(18,2)) AS INT),
    TRY_CAST(TRY_CAST(NULLIF(REPLACE(TRIM([ Total Part Time (Facility Maintenance) Hours Worked ]), ',', ''), '') AS NUMERIC(18,2)) AS INT),
    TRY_CAST(TRY_CAST(NULLIF(REPLACE(TRIM([ Part Time Operator (General Administration) Hours Worked ]), ',', ''), '') AS NUMERIC(18,2)) AS INT),
    TRY_CAST(TRY_CAST(NULLIF(REPLACE(TRIM([ Part Time Non-Operator (General Administration) Hours Worked ]), ',', ''), '') AS NUMERIC(18,2)) AS INT),
    TRY_CAST(TRY_CAST(NULLIF(REPLACE(TRIM([ Total Part Time (General Administration) Hours Worked ]), ',', ''), '') AS NUMERIC(18,2)) AS INT),
    TRY_CAST(TRY_CAST(NULLIF(REPLACE(TRIM([ Total Part Time Operator Hours Worked ]), ',', ''), '') AS NUMERIC(18,2)) AS INT),
    TRY_CAST(TRY_CAST(NULLIF(REPLACE(TRIM([ Total Part Time Non-Operator Hours Worked ]), ',', ''), '') AS NUMERIC(18,2)) AS INT),
    TRY_CAST(TRY_CAST(NULLIF(REPLACE(TRIM([ Total Part Time Hours Worked ]), ',', ''), '') AS NUMERIC(18,2)) AS INT),
    TRY_CAST(NULLIF(TRIM([ Part Time Operator (Vehicle Operations) Employee Count ]), '') AS NUMERIC(18,2)),
    TRY_CAST(NULLIF(TRIM([ Part Time Non-Operator (Vehicle Operations) Employee Count ]), '') AS NUMERIC(18,2)),
    TRY_CAST(NULLIF(TRIM([ Total Part Time (Vehicle Operations) Employee Count ]), '') AS NUMERIC(18,2)),
    TRY_CAST(NULLIF(TRIM([ Part Time Operator (Vehicle Maintenance) Employee Count ]), '') AS NUMERIC(18,2)),
    TRY_CAST(NULLIF(TRIM([ Part Time Non-Operator (Vehicle Maintenance) Employee Count ]), '') AS NUMERIC(18,2)),
    TRY_CAST(NULLIF(TRIM([ Total Part Time (Vehicle Maintenance) Employee Count ]), '') AS NUMERIC(18,2)),
    TRY_CAST(NULLIF(TRIM([ Part Time Operator (Facility Maintenance) Employee Count ]), '') AS NUMERIC(18,2)),
    TRY_CAST(NULLIF(TRIM([ Part Time Non-Operator (Facility Maintenance) Employee Count ]), '') AS NUMERIC(18,2)),
    TRY_CAST(NULLIF(TRIM([ Total Part Time (Facility Maintenance) Employee Count ]), '') AS NUMERIC(18,2)),
    TRY_CAST(NULLIF(TRIM([ Part Time Operator (General Administration) Employee Count ]), '') AS NUMERIC(18,2)),
    TRY_CAST(NULLIF(TRIM([ Part Time Non-Operator (General Administration) Employee Count ]), '') AS NUMERIC(18,2)),
    TRY_CAST(NULLIF(TRIM([ Total Part Time (General Administration) Employee Count ]), '') AS NUMERIC(18,2)),
    TRY_CAST(NULLIF(TRIM([ Total Part Time Operator Employee Count ]), '') AS NUMERIC(18,2)),
    TRY_CAST(NULLIF(TRIM([ Total Part Time Non-Operator Employee Count ]), '') AS NUMERIC(18,2)),
    TRY_CAST(NULLIF(REPLACE(TRIM([ Total Part Time Employee Count ]), ',', ''), '') AS NUMERIC(18,2))
FROM raw_HR.raw_2023_transit_agency_employees;

-- 2024 Data (Column names have leading/trailing spaces in raw table)
INSERT INTO stg_HR.stg_transit_agency_employees_2024 (
    ntd_id, agency_name, reporter_type, reporting_module, mode, tos,
    full_time_operator_vehicle_operations_hours_worked,
    full_time_non_operator_vehicle_operations_hours_worked,
    total_full_time_vehicle_operations_hours_worked,
    full_time_operator_vehicle_maintenance_hours_worked,
    full_time_non_operator_vehicle_maintenance_hours_worked,
    total_full_time_vehicle_maintenance_hours_worked,
    full_time_operator_facility_maintenance_hours_worked,
    full_time_non_operator_facility_maintenance_hours_worked,
    total_full_time_facility_maintenance_hours_worked,
    full_time_operator_general_administration_hours_worked,
    full_time_non_operator_general_administration_hours_worked,
    total_full_time_general_administration_hours_worked,
    total_full_time_operator_operating_labor_hours_worked,
    total_full_time_non_operator_operating_labor_hours_worked,
    total_full_time_operating_labor_hours_worked,
    total_full_time_operator_capital_labor_hours_worked,
    total_full_time_non_operator_capital_labor_hours_worked,
    total_full_time_capital_labor_hours_worked,
    total_full_time_operator_hours_worked,
    total_full_time_non_operator_hours_worked,
    total_full_time_hours_worked,
    full_time_operator_vehicle_operations_employee_count,
    full_time_non_operator_vehicle_operations_employee_count,
    total_full_time_vehicle_operations_employee_count,
    full_time_operator_vehicle_maintenance_employee_count,
    full_time_non_operator_vehicle_maintenance_employee_count,
    total_full_time_vehicle_maintenance_employee_count,
    full_time_operator_facility_maintenance_employee_count,
    full_time_non_operator_facility_maintenance_employee_count,
    total_full_time_facility_maintenance_employee_count,
    full_time_operator_general_administration_employee_count,
    full_time_non_operator_general_administration_employee_count,
    total_full_time_general_administration_employee_count,
    total_full_time_operator_employee_count,
    total_full_time_non_operator_employee_count,
    total_full_time_employee_count,
    part_time_operator_vehicle_operations_hours_worked,
    part_time_non_operator_vehicle_operations_hours_worked,
    total_part_time_vehicle_operations_hours_worked,
    part_time_operator_vehicle_maintenance_hours_worked,
    part_time_non_operator_vehicle_maintenance_hours_worked,
    total_part_time_vehicle_maintenance_hours_worked,
    part_time_operator_facility_maintenance_hours_worked,
    part_time_non_operator_facility_maintenance_hours_worked,
    total_part_time_facility_maintenance_hours_worked,
    part_time_operator_general_administration_hours_worked,
    part_time_non_operator_general_administration_hours_worked,
    total_part_time_general_administration_hours_worked,
    total_part_time_operator_hours_worked,
    total_part_time_non_operator_hours_worked,
    total_part_time_hours_worked,
    part_time_operator_vehicle_operations_employee_count,
    part_time_non_operator_vehicle_operations_employee_count,
    total_part_time_vehicle_operations_employee_count,
    part_time_operator_vehicle_maintenance_employee_count,
    part_time_non_operator_vehicle_maintenance_employee_count,
    total_part_time_vehicle_maintenance_employee_count,
    part_time_operator_facility_maintenance_employee_count,
    part_time_non_operator_facility_maintenance_employee_count,
    total_part_time_facility_maintenance_employee_count,
    part_time_operator_general_administration_employee_count,
    part_time_non_operator_general_administration_employee_count,
    total_part_time_general_administration_employee_count,
    total_part_time_operator_employee_count,
    total_part_time_non_operator_employee_count,
    total_part_time_employee_count
)
SELECT
    CAST(TRY_CAST(NULLIF(REPLACE(TRIM([NTD ID]), ',', ''), '') AS NUMERIC(18,0)) AS VARCHAR(50)),
    NULLIF(TRIM([Agency Name]), ''),
    NULLIF(TRIM([Reporter Type]), ''),
    NULLIF(TRIM([Reporting Module]), ''),
    NULLIF(TRIM([Mode]), ''),
    NULLIF(TRIM([TOS]), ''),
    TRY_CAST(TRY_CAST(NULLIF(REPLACE(TRIM([ Full Time Operator (Vehicle Operations) Hours Worked ]), ',', ''), '') AS NUMERIC(18,2)) AS INT),
    TRY_CAST(TRY_CAST(NULLIF(REPLACE(TRIM([ Full Time Non-Operator (Vehicle Operations) Hours Worked ]), ',', ''), '') AS NUMERIC(18,2)) AS INT),
    TRY_CAST(TRY_CAST(NULLIF(REPLACE(TRIM([ Total Full Time (Vehicle Operations) Hours Worked ]), ',', ''), '') AS NUMERIC(18,2)) AS INT),
    TRY_CAST(TRY_CAST(NULLIF(REPLACE(TRIM([ Full Time Operator (Vehicle Maintenance) Hours Worked ]), ',', ''), '') AS NUMERIC(18,2)) AS INT),
    TRY_CAST(TRY_CAST(NULLIF(REPLACE(TRIM([ Full Time Non-Operator (Vehicle Maintenance) Hours Worked ]), ',', ''), '') AS NUMERIC(18,2)) AS INT),
    TRY_CAST(TRY_CAST(NULLIF(REPLACE(TRIM([ Total Full Time (Vehicle Maintenance) Hours Worked ]), ',', ''), '') AS NUMERIC(18,2)) AS INT),
    TRY_CAST(TRY_CAST(NULLIF(REPLACE(TRIM([ Full Time Operator (Facility Maintenance) Hours Worked ]), ',', ''), '') AS NUMERIC(18,2)) AS INT),
    TRY_CAST(TRY_CAST(NULLIF(REPLACE(TRIM([ Full Time Non-Operator (Facility Maintenance) Hours Worked ]), ',', ''), '') AS NUMERIC(18,2)) AS INT),
    TRY_CAST(TRY_CAST(NULLIF(REPLACE(TRIM([ Total Full Time (Facility Maintenance) Hours Worked ]), ',', ''), '') AS NUMERIC(18,2)) AS INT),
    TRY_CAST(TRY_CAST(NULLIF(REPLACE(TRIM([ Full Time Operator (General Administration) Hours Worked ]), ',', ''), '') AS NUMERIC(18,2)) AS INT),
    TRY_CAST(TRY_CAST(NULLIF(REPLACE(TRIM([ Full Time Non-Operator (General Administration) Hours Worked ]), ',', ''), '') AS NUMERIC(18,2)) AS INT),
    TRY_CAST(TRY_CAST(NULLIF(REPLACE(TRIM([ Total Full Time (General Administration) Hours Worked ]), ',', ''), '') AS NUMERIC(18,2)) AS INT),
    TRY_CAST(TRY_CAST(NULLIF(REPLACE(TRIM([ Total Full Time Operator (Operating Labor) Hours Worked ]), ',', ''), '') AS NUMERIC(18,2)) AS INT),
    TRY_CAST(TRY_CAST(NULLIF(REPLACE(TRIM([ Total Full Time Non-Operator (Operating Labor) Hours Worked ]), ',', ''), '') AS NUMERIC(18,2)) AS INT),
    TRY_CAST(TRY_CAST(NULLIF(REPLACE(TRIM([ Total Full Time (Operating Labor) Hours Worked ]), ',', ''), '') AS NUMERIC(18,2)) AS INT),
    TRY_CAST(TRY_CAST(NULLIF(REPLACE(TRIM([ Full Time Operator (Capital Labor) Hours Worked ]), ',', ''), '') AS NUMERIC(18,2)) AS INT),
    TRY_CAST(TRY_CAST(NULLIF(REPLACE(TRIM([ Full Time Non-Operator (Capital Labor) Hours Worked ]), ',', ''), '') AS NUMERIC(18,2)) AS INT),
    TRY_CAST(TRY_CAST(NULLIF(REPLACE(TRIM([ Total Full Time (Capital Labor) Hours Worked ]), ',', ''), '') AS NUMERIC(18,2)) AS INT),
    TRY_CAST(TRY_CAST(NULLIF(REPLACE(TRIM([ Total Full Time Operator Hours Worked ]), ',', ''), '') AS NUMERIC(18,2)) AS INT),
    TRY_CAST(TRY_CAST(NULLIF(REPLACE(TRIM([ Total Full Time Non-Operator Hours Worked ]), ',', ''), '') AS NUMERIC(18,2)) AS INT),
    TRY_CAST(TRY_CAST(NULLIF(REPLACE(TRIM([ Total Full Time Hours Worked ]), ',', ''), '') AS NUMERIC(18,2)) AS INT),
    TRY_CAST(NULLIF(TRIM([ Full Time Operator (Vehicle Operations) Employee Count ]), '') AS NUMERIC(18,2)),
    TRY_CAST(NULLIF(TRIM([ Full Time Non-Operator (Vehicle Operations) Employee Count ]), '') AS NUMERIC(18,2)),
    TRY_CAST(NULLIF(TRIM([ Total Full Time (Vehicle Operations) Employee Count ]), '') AS NUMERIC(18,2)),
    TRY_CAST(NULLIF(TRIM([ Full Time Operator (Vehicle Maintenance) Employee Count ]), '') AS NUMERIC(18,2)),
    TRY_CAST(NULLIF(TRIM([ Full Time Non-Operator (Vehicle Maintenance) Employee Count ]), '') AS NUMERIC(18,2)),
    TRY_CAST(NULLIF(TRIM([ Total Full Time (Vehicle Maintenance) Employee Count ]), '') AS NUMERIC(18,2)),
    TRY_CAST(NULLIF(TRIM([ Full Time Operator (Facility Maintenance) Employee Count ]), '') AS NUMERIC(18,2)),
    TRY_CAST(NULLIF(TRIM([ Full Time Non-Operator (Facility Maintenance) Employee Count ]), '') AS NUMERIC(18,2)),
    TRY_CAST(NULLIF(TRIM([ Total Full Time (Facility Maintenance) Employee Count ]), '') AS NUMERIC(18,2)),
    TRY_CAST(NULLIF(TRIM([ Full Time Operator (General Administration) Employee Count ]), '') AS NUMERIC(18,2)),
    TRY_CAST(NULLIF(TRIM([ Full Time Non-Operator (General Administration) Employee Count ]), '') AS NUMERIC(18,2)),
    TRY_CAST(NULLIF(TRIM([ Total Full Time (General Administration) Employee Count ]), '') AS NUMERIC(18,2)),
    TRY_CAST(NULLIF(TRIM([ Total Full Time Operator Employee Count ]), '') AS NUMERIC(18,2)),
    TRY_CAST(NULLIF(TRIM([ Total Full Time Non-Operator Employee Count ]), '') AS NUMERIC(18,2)),
    TRY_CAST(NULLIF(TRIM([ Total Full Time Employee Count ]), '') AS NUMERIC(18,2)),
    TRY_CAST(TRY_CAST(NULLIF(REPLACE(TRIM([ Part Time Operator (Vehicle Operations) Hours Worked ]), ',', ''), '') AS NUMERIC(18,2)) AS INT),
    TRY_CAST(TRY_CAST(NULLIF(REPLACE(TRIM([ Part Time Non-Operator (Vehicle Operations) Hours Worked ]), ',', ''), '') AS NUMERIC(18,2)) AS INT),
    TRY_CAST(TRY_CAST(NULLIF(REPLACE(TRIM([ Total Part Time (Vehicle Operations) Hours Worked ]), ',', ''), '') AS NUMERIC(18,2)) AS INT),
    TRY_CAST(TRY_CAST(NULLIF(REPLACE(TRIM([ Part Time Operator (Vehicle Maintenance) Hours Worked ]), ',', ''), '') AS NUMERIC(18,2)) AS INT),
    TRY_CAST(TRY_CAST(NULLIF(REPLACE(TRIM([ Part Time Non-Operator (Vehicle Maintenance) Hours Worked ]), ',', ''), '') AS NUMERIC(18,2)) AS INT),
    TRY_CAST(TRY_CAST(NULLIF(REPLACE(TRIM([ Total Part Time (Vehicle Maintenance) Hours Worked ]), ',', ''), '') AS NUMERIC(18,2)) AS INT),
    TRY_CAST(TRY_CAST(NULLIF(REPLACE(TRIM([ Part Time Operator (Facility Maintenance) Hours Worked ]), ',', ''), '') AS NUMERIC(18,2)) AS INT),
    TRY_CAST(TRY_CAST(NULLIF(REPLACE(TRIM([ Part Time Non-Operator (Facility Maintenance) Hours Worked ]), ',', ''), '') AS NUMERIC(18,2)) AS INT),
    TRY_CAST(TRY_CAST(NULLIF(REPLACE(TRIM([ Total Part Time (Facility Maintenance) Hours Worked ]), ',', ''), '') AS NUMERIC(18,2)) AS INT),
    TRY_CAST(TRY_CAST(NULLIF(REPLACE(TRIM([ Part Time Operator (General Administration) Hours Worked ]), ',', ''), '') AS NUMERIC(18,2)) AS INT),
    TRY_CAST(TRY_CAST(NULLIF(REPLACE(TRIM([ Part Time Non-Operator (General Administration) Hours Worked ]), ',', ''), '') AS NUMERIC(18,2)) AS INT),
    TRY_CAST(TRY_CAST(NULLIF(REPLACE(TRIM([ Total Part Time (General Administration) Hours Worked ]), ',', ''), '') AS NUMERIC(18,2)) AS INT),
    TRY_CAST(TRY_CAST(NULLIF(REPLACE(TRIM([ Total Part Time Operator Hours Worked ]), ',', ''), '') AS NUMERIC(18,2)) AS INT),
    TRY_CAST(TRY_CAST(NULLIF(REPLACE(TRIM([ Total Part Time Non-Operator Hours Worked ]), ',', ''), '') AS NUMERIC(18,2)) AS INT),
    TRY_CAST(TRY_CAST(NULLIF(REPLACE(TRIM([ Total Part Time Hours Worked ]), ',', ''), '') AS NUMERIC(18,2)) AS INT),
    TRY_CAST(NULLIF(TRIM([ Part Time Operator (Vehicle Operations) Employee Count ]), '') AS NUMERIC(18,2)),
    TRY_CAST(NULLIF(TRIM([ Part Time Non-Operator (Vehicle Operations) Employee Count ]), '') AS NUMERIC(18,2)),
    TRY_CAST(NULLIF(TRIM([ Total Part Time (Vehicle Operations) Employee Count ]), '') AS NUMERIC(18,2)),
    TRY_CAST(NULLIF(TRIM([ Part Time Operator (Vehicle Maintenance) Employee Count ]), '') AS NUMERIC(18,2)),
    TRY_CAST(NULLIF(TRIM([ Part Time Non-Operator (Vehicle Maintenance) Employee Count ]), '') AS NUMERIC(18,2)),
    TRY_CAST(NULLIF(TRIM([ Total Part Time (Vehicle Maintenance) Employee Count ]), '') AS NUMERIC(18,2)),
    TRY_CAST(NULLIF(TRIM([ Part Time Operator (Facility Maintenance) Employee Count ]), '') AS NUMERIC(18,2)),
    TRY_CAST(NULLIF(TRIM([ Part Time Non-Operator (Facility Maintenance) Employee Count ]), '') AS NUMERIC(18,2)),
    TRY_CAST(NULLIF(TRIM([ Total Part Time (Facility Maintenance) Employee Count ]), '') AS NUMERIC(18,2)),
    TRY_CAST(NULLIF(TRIM([ Part Time Operator (General Administration) Employee Count ]), '') AS NUMERIC(18,2)),
    TRY_CAST(NULLIF(TRIM([ Part Time Non-Operator (General Administration) Employee Count ]), '') AS NUMERIC(18,2)),
    TRY_CAST(NULLIF(TRIM([ Total Part Time (General Administration) Employee Count ]), '') AS NUMERIC(18,2)),
    TRY_CAST(NULLIF(TRIM([ Total Part Time Operator Employee Count ]), '') AS NUMERIC(18,2)),
    TRY_CAST(NULLIF(TRIM([ Total Part Time Non-Operator Employee Count ]), '') AS NUMERIC(18,2)),
    TRY_CAST(NULLIF(REPLACE(TRIM([ Total Part Time Employee Count ]), ',', ''), '') AS NUMERIC(18,2))
FROM raw_HR.raw_2024_transit_agency_employees;

-- ============================================================
-- 4. Load Unified Employee Table (Consolidate 2014-2024)
-- ============================================================
    /* Rebuilt unified load using CROSS APPLY values for clarity and maintainability.
       Consolidates 2014-2018 (no operator split) and 2019-2024 (operator/non-operator).
       Each block inserts rows per department (Vehicle Operations, Vehicle Maintenance,
       Facility Maintenance, General Administration, Operating, Capital, Total) for
       FullTime and PartTime where applicable. */

    TRUNCATE TABLE stg_HR.stg_transit_employee_unified;

    -- 2014-2018: no operator split
    DECLARE @y INT;
    SET @y = 2014;
    WHILE @y <= 2018
    BEGIN
        IF @y = 2014
        BEGIN
            INSERT INTO stg_HR.stg_transit_employee_unified (
                ReportYear, NTD_ID, AgencyName, ReporterType, ReportingModule,
                ModeCode, TOSCode, EmploymentType, DepartmentName, OperatorType,
                HoursWorked, EmployeeCount, OperatingHours, CapitalHours, TotalHours,
                OperatingEmployees, CapitalEmployees, TotalEmployees
            )
            SELECT
                @y,
                s.ntd_id,
                s.reporter_name,
                s.reporter_type,
                NULL,
                s.mode,
                s.tos,
                v.EmploymentType,
                v.DepartmentName,
                NULL,
                ISNULL(v.HoursWorked,0),
                ISNULL(v.EmployeeCount,0),
                ISNULL(v.OperatingHours,0),
                ISNULL(v.CapitalHours,0),
                ISNULL(v.TotalHours,0),
                ISNULL(v.OperatingEmployees,0),
                ISNULL(v.CapitalEmployees,0),
                ISNULL(v.TotalEmployees,0)
            FROM stg_HR.stg_transit_agency_employees_2014 s
            CROSS APPLY (VALUES
                ('FullTime','Vehicle Operations', s.full_time_vehicle_operations_hours, s.full_time_vehicle_operations_employee_count, s.full_time_total_operating_labor_hours, s.full_time_total_capital_labor_hours, s.full_time_total_labor_hours, s.full_time_total_operating_labor_employee_count, s.full_time_total_capital_labor_employee_count, s.full_time_total_labor_employee_count),
                ('FullTime','Vehicle Maintenance', s.full_time_vehicle_maintenance_hours, s.full_time_vehicle_maintenance_employee_count, s.full_time_total_operating_labor_hours, s.full_time_total_capital_labor_hours, s.full_time_total_labor_hours, s.full_time_total_operating_labor_employee_count, s.full_time_total_capital_labor_employee_count, s.full_time_total_labor_employee_count),
                ('FullTime','Facility Maintenance', s.full_time_non_vehicle_maintenance_hours, s.full_time_non_vehicle_maintenance_employee_count, s.full_time_total_operating_labor_hours, s.full_time_total_capital_labor_hours, s.full_time_total_labor_hours, s.full_time_total_operating_labor_employee_count, s.full_time_total_capital_labor_employee_count, s.full_time_total_labor_employee_count),
                ('FullTime','General Administration', s.full_time_general_administration_hours, s.full_time_general_administration_employee_count, s.full_time_total_operating_labor_hours, s.full_time_total_capital_labor_hours, s.full_time_total_labor_hours, s.full_time_total_operating_labor_employee_count, s.full_time_total_capital_labor_employee_count, s.full_time_total_labor_employee_count),
                ('FullTime','Operating', s.full_time_total_operating_labor_hours, s.full_time_total_operating_labor_employee_count, s.full_time_total_operating_labor_hours, s.full_time_total_capital_labor_hours, s.full_time_total_labor_hours, s.full_time_total_operating_labor_employee_count, s.full_time_total_capital_labor_employee_count, s.full_time_total_labor_employee_count),
                ('FullTime','Capital', s.full_time_total_capital_labor_hours, s.full_time_total_capital_labor_employee_count, s.full_time_total_operating_labor_hours, s.full_time_total_capital_labor_hours, s.full_time_total_labor_hours, s.full_time_total_operating_labor_employee_count, s.full_time_total_capital_labor_employee_count, s.full_time_total_labor_employee_count),
                ('FullTime','Total', s.full_time_total_labor_hours, s.full_time_total_labor_employee_count, s.full_time_total_operating_labor_hours, s.full_time_total_capital_labor_hours, s.full_time_total_labor_hours, s.full_time_total_operating_labor_employee_count, s.full_time_total_capital_labor_employee_count, s.full_time_total_labor_employee_count),
                ('PartTime','Vehicle Operations', s.part_time_vehicle_operations_hours, s.part_time_vehicle_operations_employee_count, s.part_time_total_operating_labor_hours, s.part_time_total_capital_labor_hours, s.part_time_total_labor_hours, s.part_time_total_operating_labor_employee_count, s.part_time_total_capital_labor_employee_count, s.part_time_total_labor_employee_count),
                ('PartTime','Vehicle Maintenance', s.part_time_vehicle_maintenance_hours, s.part_time_vehicle_maintenance_employee_count, s.part_time_total_operating_labor_hours, s.part_time_total_capital_labor_hours, s.part_time_total_labor_hours, s.part_time_total_operating_labor_employee_count, s.part_time_total_capital_labor_employee_count, s.part_time_total_labor_employee_count),
                ('PartTime','Facility Maintenance', s.part_time_non_vehicle_maintenance_hours, s.part_time_non_vehicle_maintenance_employee_count, s.part_time_total_operating_labor_hours, s.part_time_total_capital_labor_hours, s.part_time_total_labor_hours, s.part_time_total_operating_labor_employee_count, s.part_time_total_capital_labor_employee_count, s.part_time_total_labor_employee_count),
                ('PartTime','General Administration', s.part_time_general_administration_hours, s.part_time_general_administration_employee_count, s.part_time_total_operating_labor_hours, s.part_time_total_capital_labor_hours, s.part_time_total_labor_hours, s.part_time_total_operating_labor_employee_count, s.part_time_total_capital_labor_employee_count, s.part_time_total_labor_employee_count),
                ('PartTime','Operating', s.part_time_total_operating_labor_hours, s.part_time_total_operating_labor_employee_count, s.part_time_total_operating_labor_hours, s.part_time_total_capital_labor_hours, s.part_time_total_labor_hours, s.part_time_total_operating_labor_employee_count, s.part_time_total_capital_labor_employee_count, s.part_time_total_labor_employee_count),
                ('PartTime','Capital', s.part_time_total_capital_labor_hours, s.part_time_total_capital_labor_employee_count, s.part_time_total_operating_labor_hours, s.part_time_total_capital_labor_hours, s.part_time_total_labor_hours, s.part_time_total_operating_labor_employee_count, s.part_time_total_capital_labor_employee_count, s.part_time_total_labor_employee_count),
                ('PartTime','Total', s.part_time_total_labor_hours, s.part_time_total_labor_employee_count, s.part_time_total_operating_labor_hours, s.part_time_total_capital_labor_hours, s.part_time_total_labor_hours, s.part_time_total_operating_labor_employee_count, s.part_time_total_capital_labor_employee_count, s.part_time_total_labor_employee_count)
            ) v(EmploymentType, DepartmentName, HoursWorked, EmployeeCount, OperatingHours, CapitalHours, TotalHours, OperatingEmployees, CapitalEmployees, TotalEmployees)
            WHERE COALESCE(v.HoursWorked, v.EmployeeCount) IS NOT NULL;
        END
        ELSE IF @y = 2015
        BEGIN
            INSERT INTO stg_HR.stg_transit_employee_unified (
                ReportYear, NTD_ID, AgencyName, ReporterType, ReportingModule,
                ModeCode, TOSCode, EmploymentType, DepartmentName, OperatorType,
                HoursWorked, EmployeeCount, OperatingHours, CapitalHours, TotalHours,
                OperatingEmployees, CapitalEmployees, TotalEmployees
            )
            SELECT
                @y,
                s.ntd_id,
                s.reporter_name,
                s.reporter_type,
                NULL,
                s.mode,
                s.tos,
                v.EmploymentType,
                v.DepartmentName,
                NULL,
                ISNULL(v.HoursWorked,0),
                ISNULL(v.EmployeeCount,0),
                ISNULL(v.OperatingHours,0),
                ISNULL(v.CapitalHours,0),
                ISNULL(v.TotalHours,0),
                ISNULL(v.OperatingEmployees,0),
                ISNULL(v.CapitalEmployees,0),
                ISNULL(v.TotalEmployees,0)
            FROM stg_HR.stg_transit_agency_employees_2015 s
            CROSS APPLY (VALUES
                ('FullTime','Vehicle Operations', s.full_time_vehicle_operations_hours, s.full_time_vehicle_operations_employee_count, s.full_time_total_operating_labor_hours, s.full_time_total_capital_labor_hours, s.full_time_total_labor_hours, s.full_time_total_operating_labor_employee_count, s.full_time_total_capital_labor_employee_count, s.full_time_total_labor_employee_count),
                ('FullTime','Vehicle Maintenance', s.full_time_vehicle_maintenance_hours, s.full_time_vehicle_maintenance_employee_count, s.full_time_total_operating_labor_hours, s.full_time_total_capital_labor_hours, s.full_time_total_labor_hours, s.full_time_total_operating_labor_employee_count, s.full_time_total_capital_labor_employee_count, s.full_time_total_labor_employee_count),
                ('FullTime','Facility Maintenance', s.full_time_non_vehicle_maintenance_hours, s.full_time_non_vehicle_maintenance_employee_count, s.full_time_total_operating_labor_hours, s.full_time_total_capital_labor_hours, s.full_time_total_labor_hours, s.full_time_total_operating_labor_employee_count, s.full_time_total_capital_labor_employee_count, s.full_time_total_labor_employee_count),
                ('FullTime','General Administration', s.full_time_general_administration_hours, s.full_time_general_administration_employee_count, s.full_time_total_operating_labor_hours, s.full_time_total_capital_labor_hours, s.full_time_total_labor_hours, s.full_time_total_operating_labor_employee_count, s.full_time_total_capital_labor_employee_count, s.full_time_total_labor_employee_count),
                ('FullTime','Operating', s.full_time_total_operating_labor_hours, s.full_time_total_operating_labor_employee_count, s.full_time_total_operating_labor_hours, s.full_time_total_capital_labor_hours, s.full_time_total_labor_hours, s.full_time_total_operating_labor_employee_count, s.full_time_total_capital_labor_employee_count, s.full_time_total_labor_employee_count),
                ('FullTime','Capital', s.full_time_total_capital_labor_hours, s.full_time_total_capital_labor_employee_count, s.full_time_total_operating_labor_hours, s.full_time_total_capital_labor_hours, s.full_time_total_labor_hours, s.full_time_total_operating_labor_employee_count, s.full_time_total_capital_labor_employee_count, s.full_time_total_labor_employee_count),
                ('FullTime','Total', s.full_time_total_labor_hours, s.full_time_total_labor_employee_count, s.full_time_total_operating_labor_hours, s.full_time_total_capital_labor_hours, s.full_time_total_labor_hours, s.full_time_total_operating_labor_employee_count, s.full_time_total_capital_labor_employee_count, s.full_time_total_labor_employee_count),
                ('PartTime','Vehicle Operations', s.part_time_vehicle_operations_hours, s.part_time_vehicle_operations_employee_count, s.part_time_total_operating_labor_hours, s.part_time_total_capital_labor_hours, s.part_time_total_labor_hours, s.part_time_total_operating_labor_employee_count, s.part_time_total_capital_labor_employee_count, s.part_time_total_labor_employee_count),
                ('PartTime','Vehicle Maintenance', s.part_time_vehicle_maintenance_hours, s.part_time_vehicle_maintenance_employee_count, s.part_time_total_operating_labor_hours, s.part_time_total_capital_labor_hours, s.part_time_total_labor_hours, s.part_time_total_operating_labor_employee_count, s.part_time_total_capital_labor_employee_count, s.part_time_total_labor_employee_count),
                ('PartTime','Facility Maintenance', s.part_time_non_vehicle_maintenance_hours, s.part_time_non_vehicle_maintenance_employee_count, s.part_time_total_operating_labor_hours, s.part_time_total_capital_labor_hours, s.part_time_total_labor_hours, s.part_time_total_operating_labor_employee_count, s.part_time_total_capital_labor_employee_count, s.part_time_total_labor_employee_count),
                ('PartTime','General Administration', s.part_time_general_administration_hours, s.part_time_general_administration_employee_count, s.part_time_total_operating_labor_hours, s.part_time_total_capital_labor_hours, s.part_time_total_labor_hours, s.part_time_total_operating_labor_employee_count, s.part_time_total_capital_labor_employee_count, s.part_time_total_labor_employee_count),
                ('PartTime','Operating', s.part_time_total_operating_labor_hours, s.part_time_total_operating_labor_employee_count, s.part_time_total_operating_labor_hours, s.part_time_total_capital_labor_hours, s.part_time_total_labor_hours, s.part_time_total_operating_labor_employee_count, s.part_time_total_capital_labor_employee_count, s.part_time_total_labor_employee_count),
                ('PartTime','Capital', s.part_time_total_capital_labor_hours, s.part_time_total_capital_labor_employee_count, s.part_time_total_operating_labor_hours, s.part_time_total_capital_labor_hours, s.part_time_total_labor_hours, s.part_time_total_operating_labor_employee_count, s.part_time_total_capital_labor_employee_count, s.part_time_total_labor_employee_count),
                ('PartTime','Total', s.part_time_total_labor_hours, s.part_time_total_labor_employee_count, s.part_time_total_operating_labor_hours, s.part_time_total_capital_labor_hours, s.part_time_total_labor_hours, s.part_time_total_operating_labor_employee_count, s.part_time_total_capital_labor_employee_count, s.part_time_total_labor_employee_count)
            ) v(EmploymentType, DepartmentName, HoursWorked, EmployeeCount, OperatingHours, CapitalHours, TotalHours, OperatingEmployees, CapitalEmployees, TotalEmployees)
            WHERE COALESCE(v.HoursWorked, v.EmployeeCount) IS NOT NULL;
        END
        ELSE IF @y = 2016
        BEGIN
            INSERT INTO stg_HR.stg_transit_employee_unified (
                ReportYear, NTD_ID, AgencyName, ReporterType, ReportingModule,
                ModeCode, TOSCode, EmploymentType, DepartmentName, OperatorType,
                HoursWorked, EmployeeCount, OperatingHours, CapitalHours, TotalHours,
                OperatingEmployees, CapitalEmployees, TotalEmployees
            )
            SELECT
                @y, s.ntd_id, s.reporter_name, s.reporter_type, NULL, s.mode, s.tos,
                v.EmploymentType, v.DepartmentName, NULL,
                ISNULL(v.HoursWorked,0), ISNULL(v.EmployeeCount,0), ISNULL(v.OperatingHours,0), ISNULL(v.CapitalHours,0), ISNULL(v.TotalHours,0), ISNULL(v.OperatingEmployees,0), ISNULL(v.CapitalEmployees,0), ISNULL(v.TotalEmployees,0)
            FROM stg_HR.stg_transit_agency_employees_2016 s
            CROSS APPLY (VALUES
                ('FullTime','Vehicle Operations', s.full_time_vehicle_operations_hours, s.full_time_vehicle_operations_employee_count, s.full_time_total_operating_labor_hours, s.full_time_total_capital_labor_hours, s.full_time_total_labor_hours, s.full_time_total_operating_labor_employee_count, s.full_time_total_capital_labor_employee_count, s.full_time_total_labor_employee_count),
                ('FullTime','Vehicle Maintenance', s.full_time_vehicle_maintenance_hours, s.full_time_vehicle_maintenance_employee_count, s.full_time_total_operating_labor_hours, s.full_time_total_capital_labor_hours, s.full_time_total_labor_hours, s.full_time_total_operating_labor_employee_count, s.full_time_total_capital_labor_employee_count, s.full_time_total_labor_employee_count),
                ('FullTime','Facility Maintenance', s.full_time_non_vehicle_maintenance_hours, s.full_time_non_vehicle_maintenance_employee_count, s.full_time_total_operating_labor_hours, s.full_time_total_capital_labor_hours, s.full_time_total_labor_hours, s.full_time_total_operating_labor_employee_count, s.full_time_total_capital_labor_employee_count, s.full_time_total_labor_employee_count),
                ('FullTime','General Administration', s.full_time_general_administration_hours, s.full_time_general_administration_employee_count, s.full_time_total_operating_labor_hours, s.full_time_total_capital_labor_hours, s.full_time_total_labor_hours, s.full_time_total_operating_labor_employee_count, s.full_time_total_capital_labor_employee_count, s.full_time_total_labor_employee_count),
                ('FullTime','Operating', s.full_time_total_operating_labor_hours, s.full_time_total_operating_labor_employee_count, s.full_time_total_operating_labor_hours, s.full_time_total_capital_labor_hours, s.full_time_total_labor_hours, s.full_time_total_operating_labor_employee_count, s.full_time_total_capital_labor_employee_count, s.full_time_total_labor_employee_count),
                ('FullTime','Capital', s.full_time_total_capital_labor_hours, s.full_time_total_capital_labor_employee_count, s.full_time_total_operating_labor_hours, s.full_time_total_capital_labor_hours, s.full_time_total_labor_hours, s.full_time_total_operating_labor_employee_count, s.full_time_total_capital_labor_employee_count, s.full_time_total_labor_employee_count),
                ('FullTime','Total', s.full_time_total_labor_hours, s.full_time_total_labor_employee_count, s.full_time_total_operating_labor_hours, s.full_time_total_capital_labor_hours, s.full_time_total_labor_hours, s.full_time_total_operating_labor_employee_count, s.full_time_total_capital_labor_employee_count, s.full_time_total_labor_employee_count),
                ('PartTime','Vehicle Operations', s.part_time_vehicle_operations_hours, s.part_time_vehicle_operations_employee_count, s.part_time_total_operating_labor_hours, s.part_time_total_capital_labor_hours, s.part_time_total_labor_hours, s.part_time_total_operating_labor_employee_count, s.part_time_total_capital_labor_employee_count, s.part_time_total_labor_employee_count),
                ('PartTime','Vehicle Maintenance', s.part_time_vehicle_maintenance_hours, s.part_time_vehicle_maintenance_employee_count, s.part_time_total_operating_labor_hours, s.part_time_total_capital_labor_hours, s.part_time_total_labor_hours, s.part_time_total_operating_labor_employee_count, s.part_time_total_capital_labor_employee_count, s.part_time_total_labor_employee_count),
                ('PartTime','Facility Maintenance', s.part_time_non_vehicle_maintenance_hours, s.part_time_non_vehicle_maintenance_employee_count, s.part_time_total_operating_labor_hours, s.part_time_total_capital_labor_hours, s.part_time_total_labor_hours, s.part_time_total_operating_labor_employee_count, s.part_time_total_capital_labor_employee_count, s.part_time_total_labor_employee_count),
                ('PartTime','General Administration', s.part_time_general_administration_hours, s.part_time_general_administration_employee_count, s.part_time_total_operating_labor_hours, s.part_time_total_capital_labor_hours, s.part_time_total_labor_hours, s.part_time_total_operating_labor_employee_count, s.part_time_total_capital_labor_employee_count, s.part_time_total_labor_employee_count),
                ('PartTime','Operating', s.part_time_total_operating_labor_hours, s.part_time_total_operating_labor_employee_count, s.part_time_total_operating_labor_hours, s.part_time_total_capital_labor_hours, s.part_time_total_labor_hours, s.part_time_total_operating_labor_employee_count, s.part_time_total_capital_labor_employee_count, s.part_time_total_labor_employee_count),
                ('PartTime','Capital', s.part_time_total_capital_labor_hours, s.part_time_total_capital_labor_employee_count, s.part_time_total_operating_labor_hours, s.part_time_total_capital_labor_hours, s.part_time_total_labor_hours, s.part_time_total_operating_labor_employee_count, s.part_time_total_capital_labor_employee_count, s.part_time_total_labor_employee_count),
                ('PartTime','Total', s.part_time_total_labor_hours, s.part_time_total_labor_employee_count, s.part_time_total_operating_labor_hours, s.part_time_total_capital_labor_hours, s.part_time_total_labor_hours, s.part_time_total_operating_labor_employee_count, s.part_time_total_capital_labor_employee_count, s.part_time_total_labor_employee_count)
            ) v(EmploymentType, DepartmentName, HoursWorked, EmployeeCount, OperatingHours, CapitalHours, TotalHours, OperatingEmployees, CapitalEmployees, TotalEmployees)
            WHERE COALESCE(v.HoursWorked, v.EmployeeCount) IS NOT NULL;
        END
        ELSE IF @y = 2017
        BEGIN
            INSERT INTO stg_HR.stg_transit_employee_unified (
                ReportYear, NTD_ID, AgencyName, ReporterType, ReportingModule,
                ModeCode, TOSCode, EmploymentType, DepartmentName, OperatorType,
                HoursWorked, EmployeeCount, OperatingHours, CapitalHours, TotalHours,
                OperatingEmployees, CapitalEmployees, TotalEmployees
            )
            SELECT
                @y, s.ntd_id, s.reporter_name, s.reporter_type, NULL, s.mode, s.tos,
                v.EmploymentType, v.DepartmentName, NULL,
                ISNULL(v.HoursWorked,0), ISNULL(v.EmployeeCount,0), ISNULL(v.OperatingHours,0), ISNULL(v.CapitalHours,0), ISNULL(v.TotalHours,0), ISNULL(v.OperatingEmployees,0), ISNULL(v.CapitalEmployees,0), ISNULL(v.TotalEmployees,0)
            FROM stg_HR.stg_transit_agency_employees_2017 s
            CROSS APPLY (VALUES
                ('FullTime','Vehicle Operations', s.full_time_vehicle_operations_hours, s.full_time_vehicle_operations_employee_count, s.full_time_total_operating_labor_hours, s.full_time_total_capital_labor_hours, s.full_time_total_labor_hours, s.full_time_total_operating_labor_employee_count, s.full_time_total_capital_labor_employee_count, s.full_time_total_labor_employee_count),
                ('FullTime','Vehicle Maintenance', s.full_time_vehicle_maintenance_hours, s.full_time_vehicle_maintenance_employee_count, s.full_time_total_operating_labor_hours, s.full_time_total_capital_labor_hours, s.full_time_total_labor_hours, s.full_time_total_operating_labor_employee_count, s.full_time_total_capital_labor_employee_count, s.full_time_total_labor_employee_count),
                ('FullTime','Facility Maintenance', s.full_time_non_vehicle_maintenance_hours, s.full_time_non_vehicle_maintenance_employee_count, s.full_time_total_operating_labor_hours, s.full_time_total_capital_labor_hours, s.full_time_total_labor_hours, s.full_time_total_operating_labor_employee_count, s.full_time_total_capital_labor_employee_count, s.full_time_total_labor_employee_count),
                ('FullTime','General Administration', s.full_time_general_administration_hours, s.full_time_general_administration_employee_count, s.full_time_total_operating_labor_hours, s.full_time_total_capital_labor_hours, s.full_time_total_labor_hours, s.full_time_total_operating_labor_employee_count, s.full_time_total_capital_labor_employee_count, s.full_time_total_labor_employee_count),
                ('FullTime','Operating', s.full_time_total_operating_labor_hours, s.full_time_total_operating_labor_employee_count, s.full_time_total_operating_labor_hours, s.full_time_total_capital_labor_hours, s.full_time_total_labor_hours, s.full_time_total_operating_labor_employee_count, s.full_time_total_capital_labor_employee_count, s.full_time_total_labor_employee_count),
                ('FullTime','Capital', s.full_time_total_capital_labor_hours, s.full_time_total_capital_labor_employee_count, s.full_time_total_operating_labor_hours, s.full_time_total_capital_labor_hours, s.full_time_total_labor_hours, s.full_time_total_operating_labor_employee_count, s.full_time_total_capital_labor_employee_count, s.full_time_total_labor_employee_count),
                ('FullTime','Total', s.full_time_total_labor_hours, s.full_time_total_labor_employee_count, s.full_time_total_operating_labor_hours, s.full_time_total_capital_labor_hours, s.full_time_total_labor_hours, s.full_time_total_operating_labor_employee_count, s.full_time_total_capital_labor_employee_count, s.full_time_total_labor_employee_count),
                ('PartTime','Vehicle Operations', s.part_time_vehicle_operations_hours, s.part_time_vehicle_operations_employee_count, s.part_time_total_operating_labor_hours, s.part_time_total_capital_labor_hours, s.part_time_total_labor_hours, s.part_time_total_operating_labor_employee_count, s.part_time_total_capital_labor_employee_count, s.part_time_total_labor_employee_count),
                ('PartTime','Vehicle Maintenance', s.part_time_vehicle_maintenance_hours, s.part_time_vehicle_maintenance_employee_count, s.part_time_total_operating_labor_hours, s.part_time_total_capital_labor_hours, s.part_time_total_labor_hours, s.part_time_total_operating_labor_employee_count, s.part_time_total_capital_labor_employee_count, s.part_time_total_labor_employee_count),
                ('PartTime','Facility Maintenance', s.part_time_non_vehicle_maintenance_hours, s.part_time_non_vehicle_maintenance_employee_count, s.part_time_total_operating_labor_hours, s.part_time_total_capital_labor_hours, s.part_time_total_labor_hours, s.part_time_total_operating_labor_employee_count, s.part_time_total_capital_labor_employee_count, s.part_time_total_labor_employee_count),
                ('PartTime','General Administration', s.part_time_general_administration_hours, s.part_time_general_administration_employee_count, s.part_time_total_operating_labor_hours, s.part_time_total_capital_labor_hours, s.part_time_total_labor_hours, s.part_time_total_operating_labor_employee_count, s.part_time_total_capital_labor_employee_count, s.part_time_total_labor_employee_count),
                ('PartTime','Operating', s.part_time_total_operating_labor_hours, s.part_time_total_operating_labor_employee_count, s.part_time_total_operating_labor_hours, s.part_time_total_capital_labor_hours, s.part_time_total_labor_hours, s.part_time_total_operating_labor_employee_count, s.part_time_total_capital_labor_employee_count, s.part_time_total_labor_employee_count),
                ('PartTime','Capital', s.part_time_total_capital_labor_hours, s.part_time_total_capital_labor_employee_count, s.part_time_total_operating_labor_hours, s.part_time_total_capital_labor_hours, s.part_time_total_labor_hours, s.part_time_total_operating_labor_employee_count, s.part_time_total_capital_labor_employee_count, s.part_time_total_labor_employee_count),
                ('PartTime','Total', s.part_time_total_labor_hours, s.part_time_total_labor_employee_count, s.part_time_total_operating_labor_hours, s.part_time_total_capital_labor_hours, s.part_time_total_labor_hours, s.part_time_total_operating_labor_employee_count, s.part_time_total_capital_labor_employee_count, s.part_time_total_labor_employee_count)
            ) v(EmploymentType, DepartmentName, HoursWorked, EmployeeCount, OperatingHours, CapitalHours, TotalHours, OperatingEmployees, CapitalEmployees, TotalEmployees)
            WHERE COALESCE(v.HoursWorked, v.EmployeeCount) IS NOT NULL;
        END
        ELSE IF @y = 2018
        BEGIN
            INSERT INTO stg_HR.stg_transit_employee_unified (
                ReportYear, NTD_ID, AgencyName, ReporterType, ReportingModule,
                ModeCode, TOSCode, EmploymentType, DepartmentName, OperatorType,
                HoursWorked, EmployeeCount, OperatingHours, CapitalHours, TotalHours,
                OperatingEmployees, CapitalEmployees, TotalEmployees
            )
            SELECT
                @y, s.ntd_id, s.reporter_name, s.reporter_type, NULL, s.mode, s.tos,
                v.EmploymentType, v.DepartmentName, NULL,
                ISNULL(v.HoursWorked,0), ISNULL(v.EmployeeCount,0), ISNULL(v.OperatingHours,0), ISNULL(v.CapitalHours,0), ISNULL(v.TotalHours,0), ISNULL(v.OperatingEmployees,0), ISNULL(v.CapitalEmployees,0), ISNULL(v.TotalEmployees,0)
            FROM stg_HR.stg_transit_agency_employees_2018 s
            CROSS APPLY (VALUES
                ('FullTime','Vehicle Operations', s.full_time_vehicle_operations_hours, s.full_time_vehicle_operations_employee_count, s.full_time_total_operating_labor_hours, s.full_time_total_capital_labor_hours, s.full_time_total_labor_hours, s.full_time_total_operating_labor_employee_count, s.full_time_total_capital_labor_employee_count, s.full_time_total_labor_employee_count),
                ('FullTime','Vehicle Maintenance', s.full_time_vehicle_maintenance_hours, s.full_time_vehicle_maintenance_employee_count, s.full_time_total_operating_labor_hours, s.full_time_total_capital_labor_hours, s.full_time_total_labor_hours, s.full_time_total_operating_labor_employee_count, s.full_time_total_capital_labor_employee_count, s.full_time_total_labor_employee_count),
                ('FullTime','Facility Maintenance', s.full_time_non_vehicle_maintenance_hours, s.full_time_non_vehicle_maintenance_employee_count, s.full_time_total_operating_labor_hours, s.full_time_total_capital_labor_hours, s.full_time_total_labor_hours, s.full_time_total_operating_labor_employee_count, s.full_time_total_capital_labor_employee_count, s.full_time_total_labor_employee_count),
                ('FullTime','General Administration', s.full_time_general_administration_hours, s.full_time_general_administration_employee_count, s.full_time_total_operating_labor_hours, s.full_time_total_capital_labor_hours, s.full_time_total_labor_hours, s.full_time_total_operating_labor_employee_count, s.full_time_total_capital_labor_employee_count, s.full_time_total_labor_employee_count),
                ('FullTime','Operating', s.full_time_total_operating_labor_hours, s.full_time_total_operating_labor_employee_count, s.full_time_total_operating_labor_hours, s.full_time_total_capital_labor_hours, s.full_time_total_labor_hours, s.full_time_total_operating_labor_employee_count, s.full_time_total_capital_labor_employee_count, s.full_time_total_labor_employee_count),
                ('FullTime','Capital', s.full_time_total_capital_labor_hours, s.full_time_total_capital_labor_employee_count, s.full_time_total_operating_labor_hours, s.full_time_total_capital_labor_hours, s.full_time_total_labor_hours, s.full_time_total_operating_labor_employee_count, s.full_time_total_capital_labor_employee_count, s.full_time_total_labor_employee_count),
                ('FullTime','Total', s.full_time_total_labor_hours, s.full_time_total_labor_employee_count, s.full_time_total_operating_labor_hours, s.full_time_total_capital_labor_hours, s.full_time_total_labor_hours, s.full_time_total_operating_labor_employee_count, s.full_time_total_capital_labor_employee_count, s.full_time_total_labor_employee_count),
                ('PartTime','Vehicle Operations', s.part_time_vehicle_operations_hours, s.part_time_vehicle_operations_employee_count, s.part_time_total_operating_labor_hours, s.part_time_total_capital_labor_hours, s.part_time_total_labor_hours, s.part_time_total_operating_labor_employee_count, s.part_time_total_capital_labor_employee_count, s.part_time_total_labor_employee_count),
                ('PartTime','Vehicle Maintenance', s.part_time_vehicle_maintenance_hours, s.part_time_vehicle_maintenance_employee_count, s.part_time_total_operating_labor_hours, s.part_time_total_capital_labor_hours, s.part_time_total_labor_hours, s.part_time_total_operating_labor_employee_count, s.part_time_total_capital_labor_employee_count, s.part_time_total_labor_employee_count),
                ('PartTime','Facility Maintenance', s.part_time_non_vehicle_maintenance_hours, s.part_time_non_vehicle_maintenance_employee_count, s.part_time_total_operating_labor_hours, s.part_time_total_capital_labor_hours, s.part_time_total_labor_hours, s.part_time_total_operating_labor_employee_count, s.part_time_total_capital_labor_employee_count, s.part_time_total_labor_employee_count),
                ('PartTime','General Administration', s.part_time_general_administration_hours, s.part_time_general_administration_employee_count, s.part_time_total_operating_labor_hours, s.part_time_total_capital_labor_hours, s.part_time_total_labor_hours, s.part_time_total_operating_labor_employee_count, s.part_time_total_capital_labor_employee_count, s.part_time_total_labor_employee_count),
                ('PartTime','Operating', s.part_time_total_operating_labor_hours, s.part_time_total_operating_labor_employee_count, s.part_time_total_operating_labor_hours, s.part_time_total_capital_labor_hours, s.part_time_total_labor_hours, s.part_time_total_operating_labor_employee_count, s.part_time_total_capital_labor_employee_count, s.part_time_total_labor_employee_count),
                ('PartTime','Capital', s.part_time_total_capital_labor_hours, s.part_time_total_capital_labor_employee_count, s.part_time_total_operating_labor_hours, s.part_time_total_capital_labor_hours, s.part_time_total_labor_hours, s.part_time_total_operating_labor_employee_count, s.part_time_total_capital_labor_employee_count, s.part_time_total_labor_employee_count),
                ('PartTime','Total', s.part_time_total_labor_hours, s.part_time_total_labor_employee_count, s.part_time_total_operating_labor_hours, s.part_time_total_capital_labor_hours, s.part_time_total_labor_hours, s.part_time_total_operating_labor_employee_count, s.part_time_total_capital_labor_employee_count, s.part_time_total_labor_employee_count)
            ) v(EmploymentType, DepartmentName, HoursWorked, EmployeeCount, OperatingHours, CapitalHours, TotalHours, OperatingEmployees, CapitalEmployees, TotalEmployees)
            WHERE COALESCE(v.HoursWorked, v.EmployeeCount) IS NOT NULL;
        END
        SET @y = @y + 1;
    END

    -- 2019-2024: operator/non-operator split. Repeat pattern for each year.
    DECLARE @yr INT = 2019;
    WHILE @yr <= 2024
    BEGIN
        IF @yr = 2019
        BEGIN
            INSERT INTO stg_HR.stg_transit_employee_unified (
                ReportYear, NTD_ID, AgencyName, ReporterType, ReportingModule,
                ModeCode, TOSCode, EmploymentType, DepartmentName, OperatorType,
                HoursWorked, EmployeeCount, OperatingHours, CapitalHours, TotalHours,
                OperatingEmployees, CapitalEmployees, TotalEmployees
            )
            SELECT
                @yr, s.ntd_id, s.agency_name, s.reporter_type, s.reporting_module, s.mode, s.tos,
                v.EmploymentType, v.DepartmentName, v.OperatorType,
                ISNULL(v.HoursWorked,0), ISNULL(v.EmployeeCount,0), ISNULL(v.OperatingHours,0), ISNULL(v.CapitalHours,0), ISNULL(v.TotalHours,0), ISNULL(v.OperatingEmployees,0), ISNULL(v.CapitalEmployees,0), ISNULL(v.TotalEmployees,0)
            FROM stg_HR.stg_transit_agency_employees_2019 s
            CROSS APPLY (VALUES
                ('FullTime','Vehicle Operations','Operator', s.full_time_operator_vehicle_operations_hours_worked, s.full_time_operator_vehicle_operations_employee_count, s.total_full_time_operator_operating_labor_hours_worked, s.total_full_time_operator_capital_labor_hours_worked, s.total_full_time_operator_hours_worked, s.total_full_time_operator_employee_count, s.total_full_time_operator_employee_count, s.total_full_time_employee_count),
                ('FullTime','Vehicle Operations','Non Operator', s.full_time_non_operator_vehicle_operations_hours_worked, s.full_time_non_operator_vehicle_operations_employee_count, s.total_full_time_non_operator_operating_labor_hours_worked, s.total_full_time_non_operator_capital_labor_hours_worked, s.total_full_time_non_operator_hours_worked, s.total_full_time_non_operator_employee_count, s.total_full_time_non_operator_employee_count, s.total_full_time_employee_count),
                ('FullTime','Vehicle Maintenance','Operator', s.full_time_operator_vehicle_maintenance_hours_worked, s.full_time_operator_vehicle_maintenance_employee_count, s.total_full_time_operator_operating_labor_hours_worked, s.total_full_time_operator_capital_labor_hours_worked, s.total_full_time_operator_hours_worked, s.total_full_time_operator_employee_count, s.total_full_time_operator_employee_count, s.total_full_time_employee_count),
                ('FullTime','Vehicle Maintenance','Non Operator', s.full_time_non_operator_vehicle_maintenance_hours_worked, s.full_time_non_operator_vehicle_maintenance_employee_count, s.total_full_time_non_operator_operating_labor_hours_worked, s.total_full_time_non_operator_capital_labor_hours_worked, s.total_full_time_non_operator_hours_worked, s.total_full_time_non_operator_employee_count, s.total_full_time_non_operator_employee_count, s.total_full_time_employee_count),
                ('FullTime','Facility Maintenance','Operator', s.full_time_operator_facility_maintenance_hours_worked, s.full_time_operator_facility_maintenance_employee_count, s.total_full_time_operator_operating_labor_hours_worked, s.total_full_time_operator_capital_labor_hours_worked, s.total_full_time_operator_hours_worked, s.total_full_time_operator_employee_count, s.total_full_time_operator_employee_count, s.total_full_time_employee_count),
                ('FullTime','Facility Maintenance','Non Operator', s.full_time_non_operator_facility_maintenance_hours_worked, s.full_time_non_operator_facility_maintenance_employee_count, s.total_full_time_non_operator_operating_labor_hours_worked, s.total_full_time_non_operator_capital_labor_hours_worked, s.total_full_time_non_operator_hours_worked, s.total_full_time_non_operator_employee_count, s.total_full_time_non_operator_employee_count, s.total_full_time_employee_count),
                ('FullTime','General Administration','Operator', s.full_time_operator_general_administration_hours_worked, s.full_time_operator_general_administration_employee_count, s.total_full_time_operator_operating_labor_hours_worked, s.total_full_time_operator_capital_labor_hours_worked, s.total_full_time_operator_hours_worked, s.total_full_time_operator_employee_count, s.total_full_time_operator_employee_count, s.total_full_time_employee_count),
                ('FullTime','General Administration','Non Operator', s.full_time_non_operator_general_administration_hours_worked, s.full_time_non_operator_general_administration_employee_count, s.total_full_time_non_operator_operating_labor_hours_worked, s.total_full_time_non_operator_capital_labor_hours_worked, s.total_full_time_non_operator_hours_worked, s.total_full_time_non_operator_employee_count, s.total_full_time_non_operator_employee_count, s.total_full_time_employee_count),
                ('PartTime','Vehicle Operations','Operator', s.part_time_operator_vehicle_operations_hours_worked, s.part_time_operator_vehicle_operations_employee_count, s.total_part_time_operator_hours_worked, s.total_part_time_operator_hours_worked, s.total_part_time_hours_worked, s.total_part_time_operator_employee_count, s.total_part_time_operator_employee_count, s.total_part_time_employee_count),
                ('PartTime','Vehicle Operations','Non Operator', s.part_time_non_operator_vehicle_operations_hours_worked, s.part_time_non_operator_vehicle_operations_employee_count, s.total_part_time_non_operator_hours_worked, s.total_part_time_non_operator_hours_worked, s.total_part_time_hours_worked, s.total_part_time_non_operator_employee_count, s.total_part_time_non_operator_employee_count, s.total_part_time_employee_count)
            ) v(EmploymentType, DepartmentName, OperatorType, HoursWorked, EmployeeCount, OperatingHours, CapitalHours, TotalHours, OperatingEmployees, CapitalEmployees, TotalEmployees)
            WHERE COALESCE(v.HoursWorked, v.EmployeeCount) IS NOT NULL;
        END
        ELSE
        BEGIN
            -- For years 2020-2024 we assume the same stg table shape as 2019; replace table name dynamically
            DECLARE @tbl NVARCHAR(200) = QUOTENAME('stg_HR') + '.' + QUOTENAME('stg_transit_agency_employees_' + CAST(@yr AS VARCHAR(4)));
            DECLARE @sql NVARCHAR(MAX) = N'
            INSERT INTO stg_HR.stg_transit_employee_unified (
                ReportYear, NTD_ID, AgencyName, ReporterType, ReportingModule,
                ModeCode, TOSCode, EmploymentType, DepartmentName, OperatorType,
                HoursWorked, EmployeeCount, OperatingHours, CapitalHours, TotalHours,
                OperatingEmployees, CapitalEmployees, TotalEmployees
            )
            SELECT
                ' + CAST(@yr AS NVARCHAR(4)) + N', s.ntd_id, s.agency_name, s.reporter_type, s.reporting_module, s.mode, s.tos,
                v.EmploymentType, v.DepartmentName, v.OperatorType,
                ISNULL(v.HoursWorked,0), ISNULL(v.EmployeeCount,0), ISNULL(v.OperatingHours,0), ISNULL(v.CapitalHours,0), ISNULL(v.TotalHours,0), ISNULL(v.OperatingEmployees,0), ISNULL(v.CapitalEmployees,0), ISNULL(v.TotalEmployees,0)
            FROM ' + @tbl + N' s
            CROSS APPLY (VALUES
                (''FullTime'',''Vehicle Operations'',''Operator'', s.full_time_operator_vehicle_operations_hours_worked, s.full_time_operator_vehicle_operations_employee_count, s.total_full_time_operator_operating_labor_hours_worked, s.total_full_time_operator_capital_labor_hours_worked, s.total_full_time_operator_hours_worked, s.total_full_time_operator_employee_count, s.total_full_time_operator_employee_count, s.total_full_time_employee_count),
                (''FullTime'',''Vehicle Operations'',''Non Operator'', s.full_time_non_operator_vehicle_operations_hours_worked, s.full_time_non_operator_vehicle_operations_employee_count, s.total_full_time_non_operator_operating_labor_hours_worked, s.total_full_time_non_operator_capital_labor_hours_worked, s.total_full_time_non_operator_hours_worked, s.total_full_time_non_operator_employee_count, s.total_full_time_non_operator_employee_count, s.total_full_time_employee_count),
                (''FullTime'',''Vehicle Maintenance'',''Operator'', s.full_time_operator_vehicle_maintenance_hours_worked, s.full_time_operator_vehicle_maintenance_employee_count, s.total_full_time_operator_operating_labor_hours_worked, s.total_full_time_operator_capital_labor_hours_worked, s.total_full_time_operator_hours_worked, s.total_full_time_operator_employee_count, s.total_full_time_operator_employee_count, s.total_full_time_employee_count),
                (''FullTime'',''Vehicle Maintenance'',''Non Operator'', s.full_time_non_operator_vehicle_maintenance_hours_worked, s.full_time_non_operator_vehicle_maintenance_employee_count, s.total_full_time_non_operator_operating_labor_hours_worked, s.total_full_time_non_operator_capital_labor_hours_worked, s.total_full_time_non_operator_hours_worked, s.total_full_time_non_operator_employee_count, s.total_full_time_non_operator_employee_count, s.total_full_time_employee_count),
                (''FullTime'',''Facility Maintenance'',''Operator'', s.full_time_operator_facility_maintenance_hours_worked, s.full_time_operator_facility_maintenance_employee_count, s.total_full_time_operator_operating_labor_hours_worked, s.total_full_time_operator_capital_labor_hours_worked, s.total_full_time_operator_hours_worked, s.total_full_time_operator_employee_count, s.total_full_time_operator_employee_count, s.total_full_time_employee_count),
                (''FullTime'',''Facility Maintenance'',''Non Operator'', s.full_time_non_operator_facility_maintenance_hours_worked, s.full_time_non_operator_facility_maintenance_employee_count, s.total_full_time_non_operator_operating_labor_hours_worked, s.total_full_time_non_operator_capital_labor_hours_worked, s.total_full_time_non_operator_hours_worked, s.total_full_time_non_operator_employee_count, s.total_full_time_non_operator_employee_count, s.total_full_time_employee_count),
                (''FullTime'',''General Administration'',''Operator'', s.full_time_operator_general_administration_hours_worked, s.full_time_operator_general_administration_employee_count, s.total_full_time_operator_operating_labor_hours_worked, s.total_full_time_operator_capital_labor_hours_worked, s.total_full_time_operator_hours_worked, s.total_full_time_operator_employee_count, s.total_full_time_operator_employee_count, s.total_full_time_employee_count),
                (''FullTime'',''General Administration'',''Non Operator'', s.full_time_non_operator_general_administration_hours_worked, s.full_time_non_operator_general_administration_employee_count, s.total_full_time_non_operator_operating_labor_hours_worked, s.total_full_time_non_operator_capital_labor_hours_worked, s.total_full_time_non_operator_hours_worked, s.total_full_time_non_operator_employee_count, s.total_full_time_non_operator_employee_count, s.total_full_time_employee_count),
                (''PartTime'',''Vehicle Operations'',''Operator'', s.part_time_operator_vehicle_operations_hours_worked, s.part_time_operator_vehicle_operations_employee_count, s.total_part_time_operator_hours_worked, s.total_part_time_operator_hours_worked, s.total_part_time_hours_worked, s.total_part_time_operator_employee_count, s.total_part_time_operator_employee_count, s.total_part_time_employee_count),
                (''PartTime'',''Vehicle Operations'',''Non Operator'', s.part_time_non_operator_vehicle_operations_hours_worked, s.part_time_non_operator_vehicle_operations_employee_count, s.total_part_time_non_operator_hours_worked, s.total_part_time_non_operator_hours_worked, s.total_part_time_hours_worked, s.total_part_time_non_operator_employee_count, s.total_part_time_non_operator_employee_count, s.total_part_time_employee_count),
                (''PartTime'',''Vehicle Maintenance'',''Operator'', s.part_time_operator_vehicle_maintenance_hours_worked, s.part_time_operator_vehicle_maintenance_employee_count, s.total_part_time_operator_hours_worked, s.total_part_time_operator_hours_worked, s.total_part_time_hours_worked, s.total_part_time_operator_employee_count, s.total_part_time_operator_employee_count, s.total_part_time_employee_count),
                (''PartTime'',''Vehicle Maintenance'',''Non Operator'', s.part_time_non_operator_vehicle_maintenance_hours_worked, s.part_time_non_operator_vehicle_maintenance_employee_count, s.total_part_time_non_operator_hours_worked, s.total_part_time_non_operator_hours_worked, s.total_part_time_hours_worked, s.total_part_time_non_operator_employee_count, s.total_part_time_non_operator_employee_count, s.total_part_time_employee_count),
                (''PartTime'',''Facility Maintenance'',''Operator'', s.part_time_operator_facility_maintenance_hours_worked, s.part_time_operator_facility_maintenance_employee_count, s.total_part_time_operator_hours_worked, s.total_part_time_operator_hours_worked, s.total_part_time_hours_worked, s.total_part_time_operator_employee_count, s.total_part_time_operator_employee_count, s.total_part_time_employee_count),
                (''PartTime'',''Facility Maintenance'',''Non Operator'', s.part_time_non_operator_facility_maintenance_hours_worked, s.part_time_non_operator_facility_maintenance_employee_count, s.total_part_time_non_operator_hours_worked, s.total_part_time_non_operator_hours_worked, s.total_part_time_hours_worked, s.total_part_time_non_operator_employee_count, s.total_part_time_non_operator_employee_count, s.total_part_time_employee_count),
                (''PartTime'',''General Administration'',''Operator'', s.part_time_operator_general_administration_hours_worked, s.part_time_operator_general_administration_employee_count, s.total_part_time_operator_hours_worked, s.total_part_time_operator_hours_worked, s.total_part_time_hours_worked, s.total_part_time_operator_employee_count, s.total_part_time_operator_employee_count, s.total_part_time_employee_count),
                (''PartTime'',''General Administration'',''Non Operator'', s.part_time_non_operator_general_administration_hours_worked, s.part_time_non_operator_general_administration_employee_count, s.total_part_time_non_operator_hours_worked, s.total_part_time_non_operator_hours_worked, s.total_part_time_hours_worked, s.total_part_time_non_operator_employee_count, s.total_part_time_non_operator_employee_count, s.total_part_time_employee_count)
            ) v(EmploymentType, DepartmentName, OperatorType, HoursWorked, EmployeeCount, OperatingHours, CapitalHours, TotalHours, OperatingEmployees, CapitalEmployees, TotalEmployees)
            WHERE COALESCE(v.HoursWorked, v.EmployeeCount) IS NOT NULL;';
            EXEC sp_executesql @sql;
        END
        SET @yr = @yr + 1;
    END

    -- Unified load complete


   -- ============================================================================
-- STORED PROCEDURE: sp_load_stg_job_openings
-- PURPOSE: Load and cleanse raw job openings data into stage table
--          following Kimball dimensional modeling principles
-- AUTHOR: Data Engineering
-- CREATED: 2026-07-16
-- PRINCIPLES APPLIED:
--   1. Conformed dimensions (dates, geographies, organizations)
--   2. Surrogate key generation (posting_date_key from dates)
--   3. Data quality validation and cleansing
--   4. Null handling and defaults
--   5. Type 2 SCD tracking (audit columns for future use)
-- ============================================================================

CREATE OR ALTER PROCEDURE stg_HR.sp_load_stg_job_openings
    @LoadDate DATETIME = NULL,
    @TruncateBeforeLoad BIT = 1,
    @ThrowErrorOnFailure BIT = 1
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @RowsProcessed INT = 0,
            @RowsRejected INT = 0,
            @ErrorMsg NVARCHAR(MAX),
            @ProcedureName NVARCHAR(128) = OBJECT_NAME(@@PROCID);

    -- Use current datetime if not provided
    IF @LoadDate IS NULL
        SET @LoadDate = CAST(GETDATE() AS DATE);

    BEGIN TRY
        -- ====================================================================
        -- STEP 1: TRUNCATE STAGE TABLE (if requested)
        -- ====================================================================
        IF @TruncateBeforeLoad = 1
        BEGIN
            TRUNCATE TABLE stg_HR.stg_job_openings;
            PRINT 'Stage table truncated successfully.';
        END

        -- ====================================================================
        -- STEP 2: DATA QUALITY LAYER - CTEs for cleansing
        -- ====================================================================

        ;WITH raw_data AS (
            -- Load raw data from source
            SELECT
                CAST(OpeningID AS VARCHAR(100)) AS opening_id,
                PostingDate,
                NTD_ID,
                AgencyName,
                ReporterType,
                ReportingModule,
                OrganizationType,
                City,
                State,
                Region,
                ModeCode,
                ModeName,
                TOS,
                TypeOfServiceName,
                NTDLaborObjectClass,
                OperatorStatus,
                EmploymentType,
                PositionTitle,
                Department,
                OpenPositions,
                SalaryMinHourly,
                SalaryMaxHourly,
                SalaryMidHourly,
                SalaryType,
                PostingStatus,
                ClosingDate,
                FilledDate,
                DaysOpen,
                HiredCount,
                VacancyReason,
                SourceSystem,
                SyntheticDataFlag,
                SourceBasisURL,
                SourceBasisNote
            FROM raw_HR.raw_synthetic_ntd_job_openings_1_2m
            -- Add WHERE clause if needed to filter to recent loads
            -- WHERE CAST(PostingDate AS DATE) >= @LoadDate - 365
        ),

        cleaned_data AS (
            -- KIMBALL PRINCIPLE: Cleanse and standardize all dimensions
            SELECT
                -- Keys and IDs
                COALESCE(NULLIF(TRIM(opening_id), ''), 'UNKNOWN') AS opening_id,

                -- Date handling with validation
                CASE
                    WHEN ISDATE(PostingDate) = 1 AND PostingDate NOT IN ('1900-01-01', '1899-12-30')
                        THEN CAST(PostingDate AS DATE)
                    ELSE NULL
                END AS posting_date,

                CASE
                    WHEN ISDATE(ClosingDate) = 1 AND ClosingDate NOT IN ('1900-01-01', '1899-12-30')
                        THEN CAST(ClosingDate AS DATE)
                    ELSE NULL
                END AS closing_date,

                CASE
                    WHEN ISDATE(FilledDate) = 1 AND FilledDate NOT IN ('1900-01-01', '1899-12-30')
                        THEN CAST(FilledDate AS DATE)
                    ELSE NULL
                END AS filled_date,

                -- Numeric fields with validation
                CASE
                    WHEN ISNUMERIC(OpenPositions) = 1 AND CAST(OpenPositions AS INT) > 0
                        THEN CAST(OpenPositions AS INT)
                    ELSE NULL
                END AS open_positions,

                CASE
                    WHEN ISNUMERIC(DaysOpen) = 1 AND CAST(DaysOpen AS INT) >= 0
                        THEN CAST(DaysOpen AS INT)
                    ELSE NULL
                END AS days_open,

                CASE
                    WHEN ISNUMERIC(HiredCount) = 1 AND CAST(HiredCount AS INT) >= 0
                        THEN CAST(HiredCount AS INT)
                    ELSE NULL
                END AS hired_count,

                -- Salary fields - validate numeric and non-negative
                CASE
                    WHEN ISNUMERIC(SalaryMinHourly) = 1
                         AND CAST(SalaryMinHourly AS NUMERIC(18,2)) >= 0
                        THEN CAST(SalaryMinHourly AS NUMERIC(18,2))
                    ELSE NULL
                END AS salary_min_hourly,

                CASE
                    WHEN ISNUMERIC(SalaryMaxHourly) = 1
                         AND CAST(SalaryMaxHourly AS NUMERIC(18,2)) >= 0
                        THEN CAST(SalaryMaxHourly AS NUMERIC(18,2))
                    ELSE NULL
                END AS salary_max_hourly,

                CASE
                    WHEN ISNUMERIC(SalaryMidHourly) = 1
                         AND CAST(SalaryMidHourly AS NUMERIC(18,2)) >= 0
                        THEN CAST(SalaryMidHourly AS NUMERIC(18,2))
                    ELSE NULL
                END AS salary_mid_hourly,

                -- Conformed Dimensions - Standardize values
                COALESCE(NULLIF(TRIM(NTD_ID), ''), NULL) AS ntd_id,
                UPPER(COALESCE(NULLIF(TRIM(AgencyName), ''), 'Unknown')) AS agency_name,
                UPPER(COALESCE(NULLIF(TRIM(ReporterType), ''), 'Unknown')) AS reporter_type,
                UPPER(COALESCE(NULLIF(TRIM(ReportingModule), ''), 'Unknown')) AS reporting_module,
                COALESCE(NULLIF(TRIM(OrganizationType), ''), 'Unknown') AS organization_type,
                UPPER(COALESCE(NULLIF(TRIM(City), ''), 'Unknown')) AS city,
                UPPER(COALESCE(NULLIF(TRIM(State), ''), 'Unknown')) AS state,
                UPPER(COALESCE(NULLIF(TRIM(Region), ''), 'Unknown')) AS region,

                -- Mode (transport) dimension
                COALESCE(NULLIF(TRIM(ModeCode), ''), 'UNKNOWN') AS mode_code,
                COALESCE(NULLIF(TRIM(ModeName), ''), 'Unknown') AS mode_name,

                -- Type of Service (TOS) dimension
                COALESCE(NULLIF(TRIM(TOS), ''), 'UNKNOWN') AS tos,
                COALESCE(NULLIF(TRIM(TypeOfServiceName), ''), 'Unknown') AS type_of_service_name,

                -- Labor object class (conformed to constraint values)
                CASE
                    WHEN TRIM(NTDLaborObjectClass) IN (
                        'Vehicle Operations',
                        'Vehicle Maintenance',
                        'Facility Maintenance',
                        'General Administration'
                    )
                        THEN TRIM(NTDLaborObjectClass)
                    ELSE 'General Administration'
                END AS ntd_labor_object_class,

                -- Operator Status
                COALESCE(NULLIF(TRIM(OperatorStatus), ''), 'Unknown') AS operator_status,

                -- Employment type (conformed to constraint values)
                CASE
                    WHEN UPPER(TRIM(EmploymentType)) IN (
                        'FULL-TIME', 'FULL TIME', 'FT'
                    )
                        THEN 'Full-Time'
                    WHEN UPPER(TRIM(EmploymentType)) IN (
                        'PART-TIME', 'PART TIME', 'PT'
                    )
                        THEN 'Part-Time'
                    WHEN UPPER(TRIM(EmploymentType)) IN (
                        'TEMPORARY', 'TEMP'
                    )
                        THEN 'Temporary'
                    WHEN UPPER(TRIM(EmploymentType)) IN (
                        'SEASONAL', 'SEASON'
                    )
                        THEN 'Seasonal'
                    WHEN UPPER(TRIM(EmploymentType)) IN (
                        'CONTRACT', 'CTR'
                    )
                        THEN 'Contract'
                    ELSE 'Full-Time'
                END AS employment_type,

                -- Position information
                COALESCE(NULLIF(TRIM(PositionTitle), ''), 'Unknown Position') AS position_title,
                COALESCE(NULLIF(TRIM(Department), ''), 'Unknown Department') AS department,

                -- Salary type
                COALESCE(NULLIF(TRIM(SalaryType), ''), 'Hourly') AS salary_type,

                -- Posting Status (conformed to constraint values)
                CASE
                    WHEN UPPER(TRIM(PostingStatus)) IN ('OPEN')
                        THEN 'Open'
                    WHEN UPPER(TRIM(PostingStatus)) IN ('CLOSED')
                        THEN 'Closed'
                    WHEN UPPER(TRIM(PostingStatus)) IN ('FILLED')
                        THEN 'Filled'
                    WHEN UPPER(TRIM(PostingStatus)) IN ('WITHDRAWN')
                        THEN 'Withdrawn'
                    WHEN UPPER(TRIM(PostingStatus)) IN ('CANCELLED', 'CANCELED')
                        THEN 'Cancelled'
                    ELSE 'Open'
                END AS posting_status,

                -- Vacancy reason
                COALESCE(NULLIF(TRIM(VacancyReason), ''), NULL) AS vacancy_reason,

                -- System and audit fields
                COALESCE(NULLIF(TRIM(SourceSystem), ''), 'Unknown') AS source_system,
                COALESCE(UPPER(NULLIF(TRIM(SyntheticDataFlag), '')), 'N') AS synthetic_data_flag,
                NULLIF(TRIM(SourceBasisURL), '') AS source_basis_url,
                NULLIF(TRIM(SourceBasisNote), '') AS source_basis_note
            FROM raw_data
        ),

        validated_data AS (
            -- KIMBALL PRINCIPLE: Apply business rules and generate derived columns
            SELECT
                opening_id,
                posting_date,
                closing_date,
                filled_date,
                open_positions,
                days_open,
                hired_count,
                salary_min_hourly,
                salary_max_hourly,
                salary_mid_hourly,
                ntd_id,
                agency_name,
                reporter_type,
                reporting_module,
                organization_type,
                city,
                state,
                region,
                mode_code,
                mode_name,
                tos,
                type_of_service_name,
                ntd_labor_object_class,
                operator_status,
                employment_type,
                position_title,
                department,
                salary_type,
                posting_status,
                vacancy_reason,
                source_system,
                synthetic_data_flag,
                source_basis_url,
                source_basis_note,

                -- Surrogate Key: Posting Date Key (YYYYMMDD format as integer)
                CASE
                    WHEN posting_date IS NOT NULL
                        THEN CAST(FORMAT(posting_date, 'yyyyMMdd') AS INT)
                    ELSE -1  -- NULL key for missing dates
                END AS posting_date_key,

                -- Derived: Report Year from posting date
                CASE
                    WHEN posting_date IS NOT NULL
                        THEN YEAR(posting_date)
                    ELSE NULL
                END AS report_year,

                -- Data Quality Flags for tracking
                CASE
                    WHEN posting_date IS NULL THEN 1
                    ELSE 0
                END AS is_posting_date_invalid,

                CASE
                    WHEN salary_min_hourly IS NOT NULL
                         AND salary_max_hourly IS NOT NULL
                         AND salary_min_hourly > salary_max_hourly
                        THEN 1
                    ELSE 0
                END AS is_salary_range_invalid,

                CASE
                    WHEN closing_date IS NOT NULL
                         AND posting_date IS NOT NULL
                         AND closing_date < posting_date
                        THEN 1
                    ELSE 0
                END AS is_date_sequence_invalid
            FROM cleaned_data
        ),

        final_load AS (
            -- KIMBALL PRINCIPLE: Only load valid records; separate rejects for audit
            SELECT
                opening_id,
                posting_date,
                posting_date_key,
                report_year,
                ntd_id,
                agency_name,
                reporter_type,
                reporting_module,
                organization_type,
                city,
                state,
                region,
                mode_code,
                mode_name,
                tos,
                type_of_service_name,
                ntd_labor_object_class,
                operator_status,
                employment_type,
                position_title,
                department,
                open_positions,
                salary_min_hourly,
                salary_max_hourly,
                salary_mid_hourly,
                salary_type,
                posting_status,
                closing_date,
                filled_date,
                days_open,
                hired_count,
                vacancy_reason,
                source_system,
                synthetic_data_flag,
                source_basis_url,
                source_basis_note
            FROM validated_data
            WHERE is_posting_date_invalid = 0
              AND is_salary_range_invalid = 0
              AND is_date_sequence_invalid = 0
        )

        -- ====================================================================
        -- STEP 3: INSERT INTO STAGE TABLE
        -- ====================================================================
        INSERT INTO stg_HR.stg_job_openings
        (
            opening_id,
            posting_date,
            posting_date_key,
            report_year,
            ntd_id,
            agency_name,
            reporter_type,
            reporting_module,
            organization_type,
            city,
            state,
            region,
            mode_code,
            mode_name,
            tos,
            type_of_service_name,
            ntd_labor_object_class,
            operator_status,
            employment_type,
            position_title,
            department,
            open_positions,
            salary_min_hourly,
            salary_max_hourly,
            salary_mid_hourly,
            salary_type,
            posting_status,
            closing_date,
            filled_date,
            days_open,
            hired_count,
            vacancy_reason,
            source_system,
            synthetic_data_flag,
            source_basis_url,
            source_basis_note
        )
        SELECT * FROM final_load;

        SET @RowsProcessed = @@ROWCOUNT;

        -- ====================================================================
        -- STEP 4: LOG RESULTS
        -- ====================================================================
        PRINT '================================================================================';
        PRINT 'LOAD COMPLETED SUCCESSFULLY';
        PRINT '================================================================================';
        PRINT 'Procedure: ' + @ProcedureName;
        PRINT 'Load Date: ' + CAST(@LoadDate AS NVARCHAR(50));
        PRINT 'Rows Loaded: ' + CAST(@RowsProcessed AS NVARCHAR(20));
        PRINT '================================================================================';

    END TRY
    BEGIN CATCH
        SET @ErrorMsg = ERROR_MESSAGE();

        PRINT '================================================================================';
        PRINT 'ERROR OCCURRED DURING LOAD';
        PRINT '================================================================================';
        PRINT 'Error: ' + @ErrorMsg;
        PRINT 'Line: ' + CAST(ERROR_LINE() AS NVARCHAR(20));
        PRINT '================================================================================';

        IF @ThrowErrorOnFailure = 1
        BEGIN
            THROW;
        END
    END CATCH
END;

-- ============================================================================
-- EXECUTION EXAMPLES
-- ============================================================================
/*

-- Example 1: Basic execution (truncate and load)
EXEC stg_HR.sp_load_stg_job_openings;

-- Example 2: Load without truncating (append mode)
EXEC stg_HR.sp_load_stg_job_openings
    @TruncateBeforeLoad = 0;

-- Example 3: With specific load date
EXEC stg_HR.sp_load_stg_job_openings
    @LoadDate = '2026-07-16',
    @TruncateBeforeLoad = 1;

-- Example 4: Non-throwing (for scheduled jobs)
EXEC stg_HR.sp_load_stg_job_openings
    @ThrowErrorOnFailure = 0;

*/

-- ============================================================================
-- DATA QUALITY VALIDATION QUERIES (Run after load)
-- ============================================================================
/*

-- Check for NULL critical fields
SELECT
    'NULL opening_id' AS IssueType,
    COUNT(*) AS RecordCount
FROM stg_HR.stg_job_openings
WHERE opening_id IS NULL OR opening_id = 'UNKNOWN'
UNION ALL
SELECT
    'NULL posting_date' AS IssueType,
    COUNT(*) AS RecordCount
FROM stg_HR.stg_job_openings
WHERE posting_date IS NULL

-- Check salary data quality
SELECT
    'Salary Range Issues' AS IssueType,
    COUNT(*) AS RecordCount
FROM stg_HR.stg_job_openings
WHERE salary_min_hourly IS NOT NULL
  AND salary_max_hourly IS NOT NULL
  AND salary_min_hourly > salary_max_hourly

-- Check date sequence violations
SELECT
    'Date Sequence Violations' AS IssueType,
    COUNT(*) AS RecordCount
FROM stg_HR.stg_job_openings
WHERE posting_date IS NOT NULL
  AND closing_date IS NOT NULL
  AND posting_date > closing_date

-- Load summary by employment type
SELECT
    employment_type,
    COUNT(*) AS RecordCount,
    AVG(CAST(open_positions AS FLOAT)) AS AvgOpenPositions,
    AVG(salary_mid_hourly) AS AvgMidSalary
FROM stg_HR.stg_job_openings
GROUP BY employment_type
ORDER BY RecordCount DESC

*/