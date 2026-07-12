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
TRUNCATE TABLE stg_HR.stg_transit_agency_employees_2025;
TRUNCATE TABLE stg_HR.stg_job_openings;

-- ============================================================
-- 1. Load Employees Data for Years 2014 - 2018
-- ============================================================


INSERT INTO stg_HR.stg_transit_agency_employees_2014 (
    ntd_id, reporter_name, reporter_type, mode, tos,
    full_time_vehicle_operations_hours, full_time_vehicle_maintenance_hours, full_time_non_vehicle_maintenance_hours, full_time_general_administration_hours, full_time_total_operating_labor_hours, full_time_total_capital_labor_hours, full_time_total_labor_hours,
    full_time_vehicle_operations_employee_count, full_time_vehicle_maintenance_employee_count, full_time_non_vehicle_maintenance_employee_count, full_time_general_administration_employee_count, full_time_total_operating_labor_employee_count, full_time_total_capital_labor_employee_count, full_time_total_labor_employee_count,
    part_time_vehicle_operations_hours, part_time_vehicle_maintenance_hours, part_time_non_vehicle_maintenance_hours, part_time_general_administration_hours, part_time_total_operating_labor_hours, part_time_total_capital_labor_hours, part_time_total_labor_hours,
    part_time_vehicle_operations_employee_count, part_time_vehicle_maintenance_employee_count, part_time_non_vehicle_maintenance_employee_count, part_time_general_administration_employee_count, part_time_total_operating_labor_employee_count, part_time_total_capital_labor_employee_count, part_time_total_labor_employee_count
)
SELECT
    -- Identification & Text Fields
    LEFT(NULLIF(TRIM([5 Digit NTDID]), 'None'), 50),
    LEFT(NULLIF(TRIM([Reporter Name]), 'None'), 255),
    LEFT(NULLIF(TRIM([Reporter Type]), 'None'), 100),
    LEFT(NULLIF(TRIM([Mode]), 'None'), 50),
    LEFT(NULLIF(TRIM([TOS]), 'None'), 50),

    -- Full-Time Hours (Safe Double Cast for potential float representations)
    TRY_CAST(TRY_CAST(NULLIF(TRIM([Vehicle Operations]), 'None') AS FLOAT) AS INT),
    TRY_CAST(TRY_CAST(NULLIF(TRIM([Vehicle Maintenance]), 'None') AS FLOAT) AS INT),
    TRY_CAST(TRY_CAST(NULLIF(TRIM([Non-vehicle Maintenance]), 'None') AS FLOAT) AS INT),
    TRY_CAST(TRY_CAST(NULLIF(TRIM([General Administration]), 'None') AS FLOAT) AS INT),
    TRY_CAST(TRY_CAST(NULLIF(TRIM([Total Operating Labor]), 'None') AS FLOAT) AS INT),
    TRY_CAST(TRY_CAST(NULLIF(TRIM([Total Capital Labor]), 'None') AS FLOAT) AS INT),
    TRY_CAST(TRY_CAST(NULLIF(TRIM([Total Labor]), 'None') AS FLOAT) AS INT),

    -- Full-Time Employee Counts (High-Precision Numeric)
    TRY_CAST(NULLIF(TRIM([Vehicle Operations_1]), 'None') AS NUMERIC(18,2)),
    TRY_CAST(NULLIF(TRIM([Vehicle Maintenance_1]), 'None') AS NUMERIC(18,2)),
    TRY_CAST(NULLIF(TRIM([Non-vehicle Maintenance_1]), 'None') AS NUMERIC(18,2)),
    TRY_CAST(NULLIF(TRIM([General Administration_1]), 'None') AS NUMERIC(18,2)),
    TRY_CAST(NULLIF(TRIM([Total Operating Labor_1]), 'None') AS NUMERIC(18,2)),
    TRY_CAST(NULLIF(TRIM([Total Capital Labor_1]), 'None') AS NUMERIC(18,2)),
    TRY_CAST(NULLIF(TRIM([Total Labor_1]), 'None') AS NUMERIC(18,2)),

    -- Part-Time Hours
    TRY_CAST(TRY_CAST(NULLIF(TRIM([Vehicle Operations_2]), 'None') AS FLOAT) AS INT),
    TRY_CAST(TRY_CAST(NULLIF(TRIM([Vehicle Maintenance_2]), 'None') AS FLOAT) AS INT),
    TRY_CAST(TRY_CAST(NULLIF(TRIM([Non-vehicle Maintenance_2]), 'None') AS FLOAT) AS INT),
    TRY_CAST(TRY_CAST(NULLIF(TRIM([General Administration_2]), 'None') AS FLOAT) AS INT),
    TRY_CAST(TRY_CAST(NULLIF(TRIM([Total Operating Labor_2]), 'None') AS FLOAT) AS INT),
    TRY_CAST(TRY_CAST(NULLIF(TRIM([Total Capital Labor_2]), 'None') AS FLOAT) AS INT),
    TRY_CAST(TRY_CAST(NULLIF(TRIM([Total Labor_2]), 'None') AS FLOAT) AS INT),

    -- Part-Time Employee Counts
    TRY_CAST(NULLIF(TRIM([Vehicle Operations_3]), 'None') AS NUMERIC(18,2)),
    TRY_CAST(NULLIF(TRIM([Vehicle Maintenance_3]), 'None') AS NUMERIC(18,2)),
    TRY_CAST(NULLIF(TRIM([Non-vehicle Maintenance_3]), 'None') AS NUMERIC(18,2)),
    TRY_CAST(NULLIF(TRIM([General Administration_3]), 'None') AS NUMERIC(18,2)),
    TRY_CAST(NULLIF(TRIM([Total Operating Labor_3]), 'None') AS NUMERIC(18,2)),
    TRY_CAST(NULLIF(TRIM([Total Capital Labor_3]), 'None') AS NUMERIC(18,2)),
    TRY_CAST(NULLIF(TRIM([Total Labor_3]), 'None') AS NUMERIC(18,2))
FROM raw_HR.raw_transit_agency_employees_2014;


INSERT INTO stg_HR.stg_transit_agency_employees_2015 (
    ntd_id, reporter_name, reporter_type, mode, tos,
    full_time_vehicle_operations_hours, full_time_vehicle_maintenance_hours, full_time_non_vehicle_maintenance_hours, full_time_general_administration_hours, full_time_total_operating_labor_hours, full_time_total_capital_labor_hours, full_time_total_labor_hours,
    full_time_vehicle_operations_employee_count, full_time_vehicle_maintenance_employee_count, full_time_non_vehicle_maintenance_employee_count, full_time_general_administration_employee_count, full_time_total_operating_labor_employee_count, full_time_total_capital_labor_employee_count, full_time_total_labor_employee_count,
    part_time_vehicle_operations_hours, part_time_vehicle_maintenance_hours, part_time_non_vehicle_maintenance_hours, part_time_general_administration_hours, part_time_total_operating_labor_hours, part_time_total_capital_labor_hours, part_time_total_labor_hours,
    part_time_vehicle_operations_employee_count, part_time_vehicle_maintenance_employee_count, part_time_non_vehicle_maintenance_employee_count, part_time_general_administration_employee_count, part_time_total_operating_labor_employee_count, part_time_total_capital_labor_employee_count, part_time_total_labor_employee_count
)
SELECT
    -- Identification & Text Fields
    LEFT(NULLIF(TRIM([5 Digit NTDID]), 'None'), 50),
    LEFT(NULLIF(TRIM([Reporter Name]), 'None'), 255),
    LEFT(NULLIF(TRIM([Reporter Type]), 'None'), 100),
    LEFT(NULLIF(TRIM([Mode]), 'None'), 50),
    LEFT(NULLIF(TRIM([TOS]), 'None'), 50),

    -- Full-Time Hours (Safe Double Cast for potential float representations)
    TRY_CAST(TRY_CAST(NULLIF(TRIM([Vehicle Operations]), 'None') AS FLOAT) AS INT),
    TRY_CAST(TRY_CAST(NULLIF(TRIM([Vehicle Maintenance]), 'None') AS FLOAT) AS INT),
    TRY_CAST(TRY_CAST(NULLIF(TRIM([Non-vehicle Maintenance]), 'None') AS FLOAT) AS INT),
    TRY_CAST(TRY_CAST(NULLIF(TRIM([General Administration]), 'None') AS FLOAT) AS INT),
    TRY_CAST(TRY_CAST(NULLIF(TRIM([Total Operating Labor]), 'None') AS FLOAT) AS INT),
    TRY_CAST(TRY_CAST(NULLIF(TRIM([Total Capital Labor]), 'None') AS FLOAT) AS INT),
    TRY_CAST(TRY_CAST(NULLIF(TRIM([Total Labor]), 'None') AS FLOAT) AS INT),

    -- Full-Time Employee Counts (High-Precision Numeric)
    TRY_CAST(NULLIF(TRIM([Vehicle Operations_1]), 'None') AS NUMERIC(18,2)),
    TRY_CAST(NULLIF(TRIM([Vehicle Maintenance_1]), 'None') AS NUMERIC(18,2)),
    TRY_CAST(NULLIF(TRIM([Non-vehicle Maintenance_1]), 'None') AS NUMERIC(18,2)),
    TRY_CAST(NULLIF(TRIM([General Administration_1]), 'None') AS NUMERIC(18,2)),
    TRY_CAST(NULLIF(TRIM([Total Operating Labor_1]), 'None') AS NUMERIC(18,2)),
    TRY_CAST(NULLIF(TRIM([Total Capital Labor_1]), 'None') AS NUMERIC(18,2)),
    TRY_CAST(NULLIF(TRIM([Total Labor_1]), 'None') AS NUMERIC(18,2)),

    -- Part-Time Hours
    TRY_CAST(TRY_CAST(NULLIF(TRIM([Vehicle Operations_2]), 'None') AS FLOAT) AS INT),
    TRY_CAST(TRY_CAST(NULLIF(TRIM([Vehicle Maintenance_2]), 'None') AS FLOAT) AS INT),
    TRY_CAST(TRY_CAST(NULLIF(TRIM([Non-vehicle Maintenance_2]), 'None') AS FLOAT) AS INT),
    TRY_CAST(TRY_CAST(NULLIF(TRIM([General Administration_2]), 'None') AS FLOAT) AS INT),
    TRY_CAST(TRY_CAST(NULLIF(TRIM([Total Operating Labor_2]), 'None') AS FLOAT) AS INT),
    TRY_CAST(TRY_CAST(NULLIF(TRIM([Total Capital Labor_2]), 'None') AS FLOAT) AS INT),
    TRY_CAST(TRY_CAST(NULLIF(TRIM([Total Labor_2]), 'None') AS FLOAT) AS INT),

    -- Part-Time Employee Counts
    TRY_CAST(NULLIF(TRIM([Vehicle Operations_3]), 'None') AS NUMERIC(18,2)),
    TRY_CAST(NULLIF(TRIM([Vehicle Maintenance_3]), 'None') AS NUMERIC(18,2)),
    TRY_CAST(NULLIF(TRIM([Non-vehicle Maintenance_3]), 'None') AS NUMERIC(18,2)),
    TRY_CAST(NULLIF(TRIM([General Administration_3]), 'None') AS NUMERIC(18,2)),
    TRY_CAST(NULLIF(TRIM([Total Operating Labor_3]), 'None') AS NUMERIC(18,2)),
    TRY_CAST(NULLIF(TRIM([Total Capital Labor_3]), 'None') AS NUMERIC(18,2)),
    TRY_CAST(NULLIF(TRIM([Total Labor_3]), 'None') AS NUMERIC(18,2))
FROM raw_HR.raw_transit_agency_employees_2015;

INSERT INTO stg_HR.stg_transit_agency_employees_2016 (
    ntd_id, reporter_name, reporter_type, mode, tos,
    full_time_vehicle_operations_hours, full_time_vehicle_maintenance_hours, full_time_non_vehicle_maintenance_hours, full_time_general_administration_hours, full_time_total_operating_labor_hours, full_time_total_capital_labor_hours, full_time_total_labor_hours,
    full_time_vehicle_operations_employee_count, full_time_vehicle_maintenance_employee_count, full_time_non_vehicle_maintenance_employee_count, full_time_general_administration_employee_count, full_time_total_operating_labor_employee_count, full_time_total_capital_labor_employee_count, full_time_total_labor_employee_count,
    part_time_vehicle_operations_hours, part_time_vehicle_maintenance_hours, part_time_non_vehicle_maintenance_hours, part_time_general_administration_hours, part_time_total_operating_labor_hours, part_time_total_capital_labor_hours, part_time_total_labor_hours,
    part_time_vehicle_operations_employee_count, part_time_vehicle_maintenance_employee_count, part_time_non_vehicle_maintenance_employee_count, part_time_general_administration_employee_count, part_time_total_operating_labor_employee_count, part_time_total_capital_labor_employee_count, part_time_total_labor_employee_count
)
SELECT
    -- Identification & Text Fields
    LEFT(NULLIF(TRIM([5 Digit NTDID]), 'None'), 50),
    LEFT(NULLIF(TRIM([Reporter Name]), 'None'), 255),
    LEFT(NULLIF(TRIM([Reporter Type]), 'None'), 100),
    LEFT(NULLIF(TRIM([Mode]), 'None'), 50),
    LEFT(NULLIF(TRIM([TOS]), 'None'), 50),

    -- Full-Time Hours (Safe Double Cast for potential float representations)
    TRY_CAST(TRY_CAST(NULLIF(TRIM([Vehicle Operations]), 'None') AS FLOAT) AS INT),
    TRY_CAST(TRY_CAST(NULLIF(TRIM([Vehicle Maintenance]), 'None') AS FLOAT) AS INT),
    TRY_CAST(TRY_CAST(NULLIF(TRIM([Non-vehicle Maintenance]), 'None') AS FLOAT) AS INT),
    TRY_CAST(TRY_CAST(NULLIF(TRIM([General Administration]), 'None') AS FLOAT) AS INT),
    TRY_CAST(TRY_CAST(NULLIF(TRIM([Total Operating Labor]), 'None') AS FLOAT) AS INT),
    TRY_CAST(TRY_CAST(NULLIF(TRIM([Total Capital Labor]), 'None') AS FLOAT) AS INT),
    TRY_CAST(TRY_CAST(NULLIF(TRIM([Total Labor]), 'None') AS FLOAT) AS INT),

    -- Full-Time Employee Counts (High-Precision Numeric)
    TRY_CAST(NULLIF(TRIM([Vehicle Operations_1]), 'None') AS NUMERIC(18,2)),
    TRY_CAST(NULLIF(TRIM([Vehicle Maintenance_1]), 'None') AS NUMERIC(18,2)),
    TRY_CAST(NULLIF(TRIM([Non-vehicle Maintenance_1]), 'None') AS NUMERIC(18,2)),
    TRY_CAST(NULLIF(TRIM([General Administration_1]), 'None') AS NUMERIC(18,2)),
    TRY_CAST(NULLIF(TRIM([Total Operating Labor_1]), 'None') AS NUMERIC(18,2)),
    TRY_CAST(NULLIF(TRIM([Total Capital Labor_1]), 'None') AS NUMERIC(18,2)),
    TRY_CAST(NULLIF(TRIM([Total Labor_1]), 'None') AS NUMERIC(18,2)),

    -- Part-Time Hours
    TRY_CAST(TRY_CAST(NULLIF(TRIM([Vehicle Operations_2]), 'None') AS FLOAT) AS INT),
    TRY_CAST(TRY_CAST(NULLIF(TRIM([Vehicle Maintenance_2]), 'None') AS FLOAT) AS INT),
    TRY_CAST(TRY_CAST(NULLIF(TRIM([Non-vehicle Maintenance_2]), 'None') AS FLOAT) AS INT),
    TRY_CAST(TRY_CAST(NULLIF(TRIM([General Administration_2]), 'None') AS FLOAT) AS INT),
    TRY_CAST(TRY_CAST(NULLIF(TRIM([Total Operating Labor_2]), 'None') AS FLOAT) AS INT),
    TRY_CAST(TRY_CAST(NULLIF(TRIM([Total Capital Labor_2]), 'None') AS FLOAT) AS INT),
    TRY_CAST(TRY_CAST(NULLIF(TRIM([Total Labor_2]), 'None') AS FLOAT) AS INT),

    -- Part-Time Employee Counts
    TRY_CAST(NULLIF(TRIM([Vehicle Operations_3]), 'None') AS NUMERIC(18,2)),
    TRY_CAST(NULLIF(TRIM([Vehicle Maintenance_3]), 'None') AS NUMERIC(18,2)),
    TRY_CAST(NULLIF(TRIM([Non-vehicle Maintenance_3]), 'None') AS NUMERIC(18,2)),
    TRY_CAST(NULLIF(TRIM([General Administration_3]), 'None') AS NUMERIC(18,2)),
    TRY_CAST(NULLIF(TRIM([Total Operating Labor_3]), 'None') AS NUMERIC(18,2)),
    TRY_CAST(NULLIF(TRIM([Total Capital Labor_3]), 'None') AS NUMERIC(18,2)),
    TRY_CAST(NULLIF(TRIM([Total Labor_3]), 'None') AS NUMERIC(18,2))
FROM raw_HR.raw_transit_agency_employees_2016;

INSERT INTO stg_HR.stg_transit_agency_employees_2017 (
    ntd_id, reporter_name, reporter_type, mode, tos,
    full_time_vehicle_operations_hours, full_time_vehicle_maintenance_hours, full_time_non_vehicle_maintenance_hours, full_time_general_administration_hours, full_time_total_operating_labor_hours, full_time_total_capital_labor_hours, full_time_total_labor_hours,
    full_time_vehicle_operations_employee_count, full_time_vehicle_maintenance_employee_count, full_time_non_vehicle_maintenance_employee_count, full_time_general_administration_employee_count, full_time_total_operating_labor_employee_count, full_time_total_capital_labor_employee_count, full_time_total_labor_employee_count,
    part_time_vehicle_operations_hours, part_time_vehicle_maintenance_hours, part_time_non_vehicle_maintenance_hours, part_time_general_administration_hours, part_time_total_operating_labor_hours, part_time_total_capital_labor_hours, part_time_total_labor_hours,
    part_time_vehicle_operations_employee_count, part_time_vehicle_maintenance_employee_count, part_time_non_vehicle_maintenance_employee_count, part_time_general_administration_employee_count, part_time_total_operating_labor_employee_count, part_time_total_capital_labor_employee_count, part_time_total_labor_employee_count
)
SELECT
    -- Identification & Text Fields
    LEFT(NULLIF(TRIM([5 Digit NTDID]), 'None'), 50),
    LEFT(NULLIF(TRIM([Reporter Name]), 'None'), 255),
    LEFT(NULLIF(TRIM([Reporter Type]), 'None'), 100),
    LEFT(NULLIF(TRIM([Mode]), 'None'), 50),
    LEFT(NULLIF(TRIM([TOS]), 'None'), 50),

    -- Full-Time Hours (Safe Double Cast for potential float representations)
    TRY_CAST(TRY_CAST(NULLIF(TRIM([Vehicle Operations]), 'None') AS FLOAT) AS INT),
    TRY_CAST(TRY_CAST(NULLIF(TRIM([Vehicle Maintenance]), 'None') AS FLOAT) AS INT),
    TRY_CAST(TRY_CAST(NULLIF(TRIM([Non-vehicle Maintenance]), 'None') AS FLOAT) AS INT),
    TRY_CAST(TRY_CAST(NULLIF(TRIM([General Administration]), 'None') AS FLOAT) AS INT),
    TRY_CAST(TRY_CAST(NULLIF(TRIM([Total Operating Labor]), 'None') AS FLOAT) AS INT),
    TRY_CAST(TRY_CAST(NULLIF(TRIM([Total Capital Labor]), 'None') AS FLOAT) AS INT),
    TRY_CAST(TRY_CAST(NULLIF(TRIM([Total Labor]), 'None') AS FLOAT) AS INT),

    -- Full-Time Employee Counts (High-Precision Numeric)
    TRY_CAST(NULLIF(TRIM([Vehicle Operations_1]), 'None') AS NUMERIC(18,2)),
    TRY_CAST(NULLIF(TRIM([Vehicle Maintenance_1]), 'None') AS NUMERIC(18,2)),
    TRY_CAST(NULLIF(TRIM([Non-vehicle Maintenance_1]), 'None') AS NUMERIC(18,2)),
    TRY_CAST(NULLIF(TRIM([General Administration_1]), 'None') AS NUMERIC(18,2)),
    TRY_CAST(NULLIF(TRIM([Total Operating Labor_1]), 'None') AS NUMERIC(18,2)),
    TRY_CAST(NULLIF(TRIM([Total Capital Labor_1]), 'None') AS NUMERIC(18,2)),
    TRY_CAST(NULLIF(TRIM([Total Labor_1]), 'None') AS NUMERIC(18,2)),

    -- Part-Time Hours
    TRY_CAST(TRY_CAST(NULLIF(TRIM([Vehicle Operations_2]), 'None') AS FLOAT) AS INT),
    TRY_CAST(TRY_CAST(NULLIF(TRIM([Vehicle Maintenance_2]), 'None') AS FLOAT) AS INT),
    TRY_CAST(TRY_CAST(NULLIF(TRIM([Non-vehicle Maintenance_2]), 'None') AS FLOAT) AS INT),
    TRY_CAST(TRY_CAST(NULLIF(TRIM([General Administration_2]), 'None') AS FLOAT) AS INT),
    TRY_CAST(TRY_CAST(NULLIF(TRIM([Total Operating Labor_2]), 'None') AS FLOAT) AS INT),
    TRY_CAST(TRY_CAST(NULLIF(TRIM([Total Capital Labor_2]), 'None') AS FLOAT) AS INT),
    TRY_CAST(TRY_CAST(NULLIF(TRIM([Total Labor_2]), 'None') AS FLOAT) AS INT),

    -- Part-Time Employee Counts
    TRY_CAST(NULLIF(TRIM([Vehicle Operations_3]), 'None') AS NUMERIC(18,2)),
    TRY_CAST(NULLIF(TRIM([Vehicle Maintenance_3]), 'None') AS NUMERIC(18,2)),
    TRY_CAST(NULLIF(TRIM([Non-vehicle Maintenance_3]), 'None') AS NUMERIC(18,2)),
    TRY_CAST(NULLIF(TRIM([General Administration_3]), 'None') AS NUMERIC(18,2)),
    TRY_CAST(NULLIF(TRIM([Total Operating Labor_3]), 'None') AS NUMERIC(18,2)),
    TRY_CAST(NULLIF(TRIM([Total Capital Labor_3]), 'None') AS NUMERIC(18,2)),
    TRY_CAST(NULLIF(TRIM([Total Labor_3]), 'None') AS NUMERIC(18,2))
FROM raw_HR.raw_transit_agency_employees_2017;

INSERT INTO stg_HR.stg_transit_agency_employees_2018 (
    ntd_id, reporter_name, reporter_type, mode, tos,
    full_time_vehicle_operations_hours, full_time_vehicle_maintenance_hours, full_time_non_vehicle_maintenance_hours, full_time_general_administration_hours, full_time_total_operating_labor_hours, full_time_total_capital_labor_hours, full_time_total_labor_hours,
    full_time_vehicle_operations_employee_count, full_time_vehicle_maintenance_employee_count, full_time_non_vehicle_maintenance_employee_count, full_time_general_administration_employee_count, full_time_total_operating_labor_employee_count, full_time_total_capital_labor_employee_count, full_time_total_labor_employee_count,
    part_time_vehicle_operations_hours, part_time_vehicle_maintenance_hours, part_time_non_vehicle_maintenance_hours, part_time_general_administration_hours, part_time_total_operating_labor_hours, part_time_total_capital_labor_hours, part_time_total_labor_hours,
    part_time_vehicle_operations_employee_count, part_time_vehicle_maintenance_employee_count, part_time_non_vehicle_maintenance_employee_count, part_time_general_administration_employee_count, part_time_total_operating_labor_employee_count, part_time_total_capital_labor_employee_count, part_time_total_labor_employee_count
)
SELECT
    -- Identification & Text Fields
    LEFT(NULLIF(TRIM([5 Digit NTDID]), 'None'), 50),
    LEFT(NULLIF(TRIM([Reporter Name]), 'None'), 255),
    LEFT(NULLIF(TRIM([Reporter Type]), 'None'), 100),
    LEFT(NULLIF(TRIM([Mode]), 'None'), 50),
    LEFT(NULLIF(TRIM([TOS]), 'None'), 50),

    -- Full-Time Hours (Safe Double Cast for potential float representations)
    TRY_CAST(TRY_CAST(NULLIF(TRIM([Vehicle Operations]), 'None') AS FLOAT) AS INT),
    TRY_CAST(TRY_CAST(NULLIF(TRIM([Vehicle Maintenance]), 'None') AS FLOAT) AS INT),
    TRY_CAST(TRY_CAST(NULLIF(TRIM([Non-vehicle Maintenance]), 'None') AS FLOAT) AS INT),
    TRY_CAST(TRY_CAST(NULLIF(TRIM([General Administration]), 'None') AS FLOAT) AS INT),
    TRY_CAST(TRY_CAST(NULLIF(TRIM([Total Operating Labor]), 'None') AS FLOAT) AS INT),
    TRY_CAST(TRY_CAST(NULLIF(TRIM([Total Capital Labor]), 'None') AS FLOAT) AS INT),
    TRY_CAST(TRY_CAST(NULLIF(TRIM([Total Labor]), 'None') AS FLOAT) AS INT),

    -- Full-Time Employee Counts (High-Precision Numeric)
    TRY_CAST(NULLIF(TRIM([Vehicle Operations_1]), 'None') AS NUMERIC(18,2)),
    TRY_CAST(NULLIF(TRIM([Vehicle Maintenance_1]), 'None') AS NUMERIC(18,2)),
    TRY_CAST(NULLIF(TRIM([Non-vehicle Maintenance_1]), 'None') AS NUMERIC(18,2)),
    TRY_CAST(NULLIF(TRIM([General Administration_1]), 'None') AS NUMERIC(18,2)),
    TRY_CAST(NULLIF(TRIM([Total Operating Labor_1]), 'None') AS NUMERIC(18,2)),
    TRY_CAST(NULLIF(TRIM([Total Capital Labor_1]), 'None') AS NUMERIC(18,2)),
    TRY_CAST(NULLIF(TRIM([Total Labor_1]), 'None') AS NUMERIC(18,2)),

    -- Part-Time Hours
    TRY_CAST(TRY_CAST(NULLIF(TRIM([Vehicle Operations_2]), 'None') AS FLOAT) AS INT),
    TRY_CAST(TRY_CAST(NULLIF(TRIM([Vehicle Maintenance_2]), 'None') AS FLOAT) AS INT),
    TRY_CAST(TRY_CAST(NULLIF(TRIM([Non-vehicle Maintenance_2]), 'None') AS FLOAT) AS INT),
    TRY_CAST(TRY_CAST(NULLIF(TRIM([General Administration_2]), 'None') AS FLOAT) AS INT),
    TRY_CAST(TRY_CAST(NULLIF(TRIM([Total Operating Labor_2]), 'None') AS FLOAT) AS INT),
    TRY_CAST(TRY_CAST(NULLIF(TRIM([Total Capital Labor_2]), 'None') AS FLOAT) AS INT),
    TRY_CAST(TRY_CAST(NULLIF(TRIM([Total Labor_2]), 'None') AS FLOAT) AS INT),

    -- Part-Time Employee Counts
    TRY_CAST(NULLIF(TRIM([Vehicle Operations_3]), 'None') AS NUMERIC(18,2)),
    TRY_CAST(NULLIF(TRIM([Vehicle Maintenance_3]), 'None') AS NUMERIC(18,2)),
    TRY_CAST(NULLIF(TRIM([Non-vehicle Maintenance_3]), 'None') AS NUMERIC(18,2)),
    TRY_CAST(NULLIF(TRIM([General Administration_3]), 'None') AS NUMERIC(18,2)),
    TRY_CAST(NULLIF(TRIM([Total Operating Labor_3]), 'None') AS NUMERIC(18,2)),
    TRY_CAST(NULLIF(TRIM([Total Capital Labor_3]), 'None') AS NUMERIC(18,2)),
    TRY_CAST(NULLIF(TRIM([Total Labor_3]), 'None') AS NUMERIC(18,2))
FROM raw_HR.raw_transit_agency_employees_2018;


-- ============================================================
-- 2. Load Employees Data for Years 2019 - 2025
-- ============================================================


INSERT INTO stg_HR.stg_transit_agency_employees_2019 (
    ntd_id, agency_name, reporter_type, reporting_module, mode, tos,
    full_time_operator_vehicle_operations_hours_worked, full_time_non_operator_vehicle_operations_hours_worked, total_full_time_vehicle_operations_hours_worked,
    full_time_operator_vehicle_maintenance_hours_worked, full_time_non_operator_vehicle_maintenance_hours_worked, total_full_time_vehicle_maintenance_hours_worked,
    full_time_operator_facility_maintenance_hours_worked, full_time_non_operator_facility_maintenance_hours_worked, total_full_time_facility_maintenance_hours_worked,
    full_time_operator_general_administration_hours_worked, full_time_non_operator_general_administration_hours_worked, total_full_time_general_administration_hours_worked,
    total_full_time_operator_operating_labor_hours_worked, total_full_time_non_operator_operating_labor_hours_worked, total_full_time_operating_labor_hours_worked,
    total_full_time_operator_capital_labor_hours_worked, total_full_time_non_operator_capital_labor_hours_worked, total_full_time_capital_labor_hours_worked,
    total_full_time_operator_hours_worked, total_full_time_non_operator_hours_worked, total_full_time_hours_worked,
    full_time_operator_vehicle_operations_employee_count, full_time_non_operator_vehicle_operations_employee_count, total_full_time_vehicle_operations_employee_count,
    full_time_operator_vehicle_maintenance_employee_count, full_time_non_operator_vehicle_maintenance_employee_count, total_full_time_vehicle_maintenance_employee_count,
    full_time_operator_facility_maintenance_employee_count, full_time_non_operator_facility_maintenance_employee_count, total_full_time_facility_maintenance_employee_count,
    full_time_operator_general_administration_employee_count, full_time_non_operator_general_administration_employee_count, total_full_time_general_administration_employee_count,
    total_full_time_operator_employee_count, total_full_time_non_operator_employee_count, total_full_time_employee_count,
    part_time_operator_vehicle_operations_hours_worked, part_time_non_operator_vehicle_operations_hours_worked, total_part_time_vehicle_operations_hours_worked,
    part_time_operator_vehicle_maintenance_hours_worked, part_time_non_operator_vehicle_maintenance_hours_worked, total_part_time_vehicle_maintenance_hours_worked,
    part_time_operator_facility_maintenance_hours_worked, part_time_non_operator_facility_maintenance_hours_worked, total_part_time_facility_maintenance_hours_worked,
    part_time_operator_general_administration_hours_worked, part_time_non_operator_general_administration_hours_worked, total_part_time_general_administration_hours_worked,
    total_part_time_operator_hours_worked, total_part_time_non_operator_hours_worked, total_part_time_hours_worked,
    part_time_operator_vehicle_operations_employee_count, part_time_non_operator_vehicle_operations_employee_count, total_part_time_vehicle_operations_employee_count,
    part_time_operator_vehicle_maintenance_employee_count, part_time_non_operator_vehicle_maintenance_employee_count, total_part_time_vehicle_maintenance_employee_count,
    part_time_operator_facility_maintenance_employee_count, part_time_non_operator_facility_maintenance_employee_count, total_part_time_facility_maintenance_employee_count,
    part_time_operator_general_administration_employee_count, part_time_non_operator_general_administration_employee_count, total_part_time_general_administration_employee_count,
    total_part_time_operator_employee_count, total_part_time_non_operator_employee_count, total_part_time_employee_count
)
SELECT
    LEFT(NULLIF(TRIM([NTD ID]), 'None'), 50),
    LEFT(NULLIF(TRIM([Agency Name]), 'None'), 255),
    LEFT(NULLIF(TRIM([Reporter Type]), 'None'), 100),
    LEFT(NULLIF(TRIM([Reporting Module]), 'None'), 100),
    LEFT(NULLIF(TRIM([Mode]), 'None'), 50),
    LEFT(NULLIF(TRIM([TOS]), 'None'), 50),

    -- Numeric Precision Mapping for 2019+ columns
    TRY_CAST(NULLIF(TRIM([Full Time Operator (Vehicle Operations) Hours Worked]), 'None') AS NUMERIC(18,2)),
    TRY_CAST(NULLIF(TRIM([Full Time Non-Operator (Vehicle Operations) Hours Worked]), 'None') AS NUMERIC(18,2)),
    TRY_CAST(NULLIF(TRIM([Total Full Time (Vehicle Operations) Hours Worked]), 'None') AS NUMERIC(18,2)),

    TRY_CAST(NULLIF(TRIM([Full Time Operator (Vehicle Maintenance) Hours Worked]), 'None') AS NUMERIC(18,2)),
    TRY_CAST(NULLIF(TRIM([Full Time Non-Operator (Vehicle Maintenance) Hours Worked]), 'None') AS NUMERIC(18,2)),
    TRY_CAST(NULLIF(TRIM([Total Full Time (Vehicle Maintenance) Hours Worked]), 'None') AS NUMERIC(18,2)),

    TRY_CAST(NULLIF(TRIM([Full Time Operator (Facility Maintenance) Hours Worked]), 'None') AS NUMERIC(18,2)),
    TRY_CAST(NULLIF(TRIM([Full Time Non-Operator (Facility Maintenance) Hours Worked]), 'None') AS NUMERIC(18,2)),
    TRY_CAST(NULLIF(TRIM([Total Full Time (Facility Maintenance) Hours Worked]), 'None') AS NUMERIC(18,2)),

    TRY_CAST(NULLIF(TRIM([Full Time Operator (General Administration) Hours Worked]), 'None') AS NUMERIC(18,2)),
    TRY_CAST(NULLIF(TRIM([Full Time Non-Operator (General Administration) Hours Worked]), 'None') AS NUMERIC(18,2)),
    TRY_CAST(NULLIF(TRIM([Total Full Time (General Administration) Hours Worked]), 'None') AS NUMERIC(18,2)),

    TRY_CAST(NULLIF(TRIM([Total Full Time Operator (Operating Labor) Hours Worked]), 'None') AS NUMERIC(18,2)),
    TRY_CAST(NULLIF(TRIM([Total Full Time Non-Operator (Operating Labor) Hours Worked]), 'None') AS NUMERIC(18,2)),
    TRY_CAST(NULLIF(TRIM([Total Full Time (Operating Labor) Hours Worked]), 'None') AS NUMERIC(18,2)),

    TRY_CAST(NULLIF(TRIM([Total Full Time Operator (Capital Labor) Hours Worked]), 'None') AS NUMERIC(18,2)),
    TRY_CAST(NULLIF(TRIM([Total Full Time Non-Operator (Capital Labor) Hours Worked]), 'None') AS NUMERIC(18,2)),
    TRY_CAST(NULLIF(TRIM([Total Full Time (Capital Labor) Hours Worked]), 'None') AS NUMERIC(18,2)),

    TRY_CAST(NULLIF(TRIM([Total Full Time Operator Hours Worked]), 'None') AS NUMERIC(18,2)),
    TRY_CAST(NULLIF(TRIM([Total Full Time Non-Operator Hours Worked]), 'None') AS NUMERIC(18,2)),
    TRY_CAST(NULLIF(TRIM([Total Full Time Hours Worked]), 'None') AS NUMERIC(18,2)),

    -- Employee Counts
    TRY_CAST(NULLIF(TRIM([Full Time Operator (Vehicle Operations) Employee Count]), 'None') AS NUMERIC(18,2)),
    TRY_CAST(NULLIF(TRIM([Full Time Non-Operator (Vehicle Operations) Employee Count]), 'None') AS NUMERIC(18,2)),
    TRY_CAST(NULLIF(TRIM([Total Full Time (Vehicle Operations) Employee Count]), 'None') AS NUMERIC(18,2)),

    TRY_CAST(NULLIF(TRIM([Full Time Operator (Vehicle Maintenance) Employee Count]), 'None') AS NUMERIC(18,2)),
    TRY_CAST(NULLIF(TRIM([Full Time Non-Operator (Vehicle Maintenance) Employee Count]), 'None') AS NUMERIC(18,2)),
    TRY_CAST(NULLIF(TRIM([Total Full Time (Vehicle Maintenance) Employee Count]), 'None') AS NUMERIC(18,2)),

    -- Part Time Sections
    TRY_CAST(NULLIF(TRIM([Part Time Operator (Vehicle Operations) Hours Worked]), 'None') AS NUMERIC(18,2)),
    TRY_CAST(NULLIF(TRIM([Part Time Non-Operator (Vehicle Operations) Hours Worked]), 'None') AS NUMERIC(18,2)),
    TRY_CAST(NULLIF(TRIM([Total Part Time (Vehicle Operations) Hours Worked]), 'None') AS NUMERIC(18,2)),

    TRY_CAST(NULLIF(TRIM([Part Time Operator (Vehicle Maintenance) Employee Count]), 'None') AS NUMERIC(18,2)),
    TRY_CAST(NULLIF(TRIM([Part Time Non-Operator (Vehicle Maintenance) Employee Count]), 'None') AS NUMERIC(18,2)),
    TRY_CAST(NULLIF(TRIM([Total Part Time (Vehicle Maintenance) Employee Count]), 'None') AS NUMERIC(18,2))

FROM raw_HR.raw_transit_agency_employees_2019;

INSERT INTO stg_HR.stg_transit_agency_employees_2020 (
    ntd_id, agency_name, reporter_type, reporting_module, mode, tos,
    full_time_operator_vehicle_operations_hours_worked, full_time_non_operator_vehicle_operations_hours_worked, total_full_time_vehicle_operations_hours_worked,
    full_time_operator_vehicle_maintenance_hours_worked, full_time_non_operator_vehicle_maintenance_hours_worked, total_full_time_vehicle_maintenance_hours_worked,
    full_time_operator_facility_maintenance_hours_worked, full_time_non_operator_facility_maintenance_hours_worked, total_full_time_facility_maintenance_hours_worked,
    full_time_operator_general_administration_hours_worked, full_time_non_operator_general_administration_hours_worked, total_full_time_general_administration_hours_worked,
    total_full_time_operator_operating_labor_hours_worked, total_full_time_non_operator_operating_labor_hours_worked, total_full_time_operating_labor_hours_worked,
    total_full_time_operator_capital_labor_hours_worked, total_full_time_non_operator_capital_labor_hours_worked, total_full_time_capital_labor_hours_worked,
    total_full_time_operator_hours_worked, total_full_time_non_operator_hours_worked, total_full_time_hours_worked,
    full_time_operator_vehicle_operations_employee_count, full_time_non_operator_vehicle_operations_employee_count, total_full_time_vehicle_operations_employee_count,
    full_time_operator_vehicle_maintenance_employee_count, full_time_non_operator_vehicle_maintenance_employee_count, total_full_time_vehicle_maintenance_employee_count,
    full_time_operator_facility_maintenance_employee_count, full_time_non_operator_facility_maintenance_employee_count, total_full_time_facility_maintenance_employee_count,
    full_time_operator_general_administration_employee_count, full_time_non_operator_general_administration_employee_count, total_full_time_general_administration_employee_count,
    total_full_time_operator_employee_count, total_full_time_non_operator_employee_count, total_full_time_employee_count,
    part_time_operator_vehicle_operations_hours_worked, part_time_non_operator_vehicle_operations_hours_worked, total_part_time_vehicle_operations_hours_worked,
    part_time_operator_vehicle_maintenance_hours_worked, part_time_non_operator_vehicle_maintenance_hours_worked, total_part_time_vehicle_maintenance_hours_worked,
    part_time_operator_facility_maintenance_hours_worked, part_time_non_operator_facility_maintenance_hours_worked, total_part_time_facility_maintenance_hours_worked,
    part_time_operator_general_administration_hours_worked, part_time_non_operator_general_administration_hours_worked, total_part_time_general_administration_hours_worked,
    total_part_time_operator_hours_worked, total_part_time_non_operator_hours_worked, total_part_time_hours_worked,
    part_time_operator_vehicle_operations_employee_count, part_time_non_operator_vehicle_operations_employee_count, total_part_time_vehicle_operations_employee_count,
    part_time_operator_vehicle_maintenance_employee_count, part_time_non_operator_vehicle_maintenance_employee_count, total_part_time_vehicle_maintenance_employee_count,
    part_time_operator_facility_maintenance_employee_count, part_time_non_operator_facility_maintenance_employee_count, total_part_time_facility_maintenance_employee_count,
    part_time_operator_general_administration_employee_count, part_time_non_operator_general_administration_employee_count, total_part_time_general_administration_employee_count,
    total_part_time_operator_employee_count, total_part_time_non_operator_employee_count, total_part_time_employee_count
)
SELECT
    LEFT(NULLIF(TRIM([NTD ID]), 'None'), 50),
    LEFT(NULLIF(TRIM([Agency Name]), 'None'), 255),
    LEFT(NULLIF(TRIM([Reporter Type]), 'None'), 100),
    LEFT(NULLIF(TRIM([Reporting Module]), 'None'), 100),
    LEFT(NULLIF(TRIM([Mode]), 'None'), 50),
    LEFT(NULLIF(TRIM([TOS]), 'None'), 50),

    -- Numeric Precision Mapping for 2019+ columns
    TRY_CAST(NULLIF(TRIM([Full Time Operator (Vehicle Operations) Hours Worked]), 'None') AS NUMERIC(18,2)),
    TRY_CAST(NULLIF(TRIM([Full Time Non-Operator (Vehicle Operations) Hours Worked]), 'None') AS NUMERIC(18,2)),
    TRY_CAST(NULLIF(TRIM([Total Full Time (Vehicle Operations) Hours Worked]), 'None') AS NUMERIC(18,2)),

    TRY_CAST(NULLIF(TRIM([Full Time Operator (Vehicle Maintenance) Hours Worked]), 'None') AS NUMERIC(18,2)),
    TRY_CAST(NULLIF(TRIM([Full Time Non-Operator (Vehicle Maintenance) Hours Worked]), 'None') AS NUMERIC(18,2)),
    TRY_CAST(NULLIF(TRIM([Total Full Time (Vehicle Maintenance) Hours Worked]), 'None') AS NUMERIC(18,2)),

    TRY_CAST(NULLIF(TRIM([Full Time Operator (Facility Maintenance) Hours Worked]), 'None') AS NUMERIC(18,2)),
    TRY_CAST(NULLIF(TRIM([Full Time Non-Operator (Facility Maintenance) Hours Worked]), 'None') AS NUMERIC(18,2)),
    TRY_CAST(NULLIF(TRIM([Total Full Time (Facility Maintenance) Hours Worked]), 'None') AS NUMERIC(18,2)),

    TRY_CAST(NULLIF(TRIM([Full Time Operator (General Administration) Hours Worked]), 'None') AS NUMERIC(18,2)),
    TRY_CAST(NULLIF(TRIM([Full Time Non-Operator (General Administration) Hours Worked]), 'None') AS NUMERIC(18,2)),
    TRY_CAST(NULLIF(TRIM([Total Full Time (General Administration) Hours Worked]), 'None') AS NUMERIC(18,2)),

    TRY_CAST(NULLIF(TRIM([Total Full Time Operator (Operating Labor) Hours Worked]), 'None') AS NUMERIC(18,2)),
    TRY_CAST(NULLIF(TRIM([Total Full Time Non-Operator (Operating Labor) Hours Worked]), 'None') AS NUMERIC(18,2)),
    TRY_CAST(NULLIF(TRIM([Total Full Time (Operating Labor) Hours Worked]), 'None') AS NUMERIC(18,2)),

    TRY_CAST(NULLIF(TRIM([Total Full Time Operator (Capital Labor) Hours Worked]), 'None') AS NUMERIC(18,2)),
    TRY_CAST(NULLIF(TRIM([Total Full Time Non-Operator (Capital Labor) Hours Worked]), 'None') AS NUMERIC(18,2)),
    TRY_CAST(NULLIF(TRIM([Total Full Time (Capital Labor) Hours Worked]), 'None') AS NUMERIC(18,2)),

    TRY_CAST(NULLIF(TRIM([Total Full Time Operator Hours Worked]), 'None') AS NUMERIC(18,2)),
    TRY_CAST(NULLIF(TRIM([Total Full Time Non-Operator Hours Worked]), 'None') AS NUMERIC(18,2)),
    TRY_CAST(NULLIF(TRIM([Total Full Time Hours Worked]), 'None') AS NUMERIC(18,2)),

    -- Employee Counts
    TRY_CAST(NULLIF(TRIM([Full Time Operator (Vehicle Operations) Employee Count]), 'None') AS NUMERIC(18,2)),
    TRY_CAST(NULLIF(TRIM([Full Time Non-Operator (Vehicle Operations) Employee Count]), 'None') AS NUMERIC(18,2)),
    TRY_CAST(NULLIF(TRIM([Total Full Time (Vehicle Operations) Employee Count]), 'None') AS NUMERIC(18,2)),

    TRY_CAST(NULLIF(TRIM([Full Time Operator (Vehicle Maintenance) Employee Count]), 'None') AS NUMERIC(18,2)),
    TRY_CAST(NULLIF(TRIM([Full Time Non-Operator (Vehicle Maintenance) Employee Count]), 'None') AS NUMERIC(18,2)),
    TRY_CAST(NULLIF(TRIM([Total Full Time (Vehicle Maintenance) Employee Count]), 'None') AS NUMERIC(18,2)),

    -- Part Time Sections
    TRY_CAST(NULLIF(TRIM([Part Time Operator (Vehicle Operations) Hours Worked]), 'None') AS NUMERIC(18,2)),
    TRY_CAST(NULLIF(TRIM([Part Time Non-Operator (Vehicle Operations) Hours Worked]), 'None') AS NUMERIC(18,2)),
    TRY_CAST(NULLIF(TRIM([Total Part Time (Vehicle Operations) Hours Worked]), 'None') AS NUMERIC(18,2)),

    TRY_CAST(NULLIF(TRIM([Part Time Operator (Vehicle Maintenance) Employee Count]), 'None') AS NUMERIC(18,2)),
    TRY_CAST(NULLIF(TRIM([Part Time Non-Operator (Vehicle Maintenance) Employee Count]), 'None') AS NUMERIC(18,2)),
    TRY_CAST(NULLIF(TRIM([Total Part Time (Vehicle Maintenance) Employee Count]), 'None') AS NUMERIC(18,2))

FROM raw_HR.raw_transit_agency_employees_2020;


INSERT INTO stg_HR.stg_transit_agency_employees_2021 (
    ntd_id, agency_name, reporter_type, reporting_module, mode, tos,
    full_time_operator_vehicle_operations_hours_worked, full_time_non_operator_vehicle_operations_hours_worked, total_full_time_vehicle_operations_hours_worked,
    full_time_operator_vehicle_maintenance_hours_worked, full_time_non_operator_vehicle_maintenance_hours_worked, total_full_time_vehicle_maintenance_hours_worked,
    full_time_operator_facility_maintenance_hours_worked, full_time_non_operator_facility_maintenance_hours_worked, total_full_time_facility_maintenance_hours_worked,
    full_time_operator_general_administration_hours_worked, full_time_non_operator_general_administration_hours_worked, total_full_time_general_administration_hours_worked,
    total_full_time_operator_operating_labor_hours_worked, total_full_time_non_operator_operating_labor_hours_worked, total_full_time_operating_labor_hours_worked,
    total_full_time_operator_capital_labor_hours_worked, total_full_time_non_operator_capital_labor_hours_worked, total_full_time_capital_labor_hours_worked,
    total_full_time_operator_hours_worked, total_full_time_non_operator_hours_worked, total_full_time_hours_worked,
    full_time_operator_vehicle_operations_employee_count, full_time_non_operator_vehicle_operations_employee_count, total_full_time_vehicle_operations_employee_count,
    full_time_operator_vehicle_maintenance_employee_count, full_time_non_operator_vehicle_maintenance_employee_count, total_full_time_vehicle_maintenance_employee_count,
    full_time_operator_facility_maintenance_employee_count, full_time_non_operator_facility_maintenance_employee_count, total_full_time_facility_maintenance_employee_count,
    full_time_operator_general_administration_employee_count, full_time_non_operator_general_administration_employee_count, total_full_time_general_administration_employee_count,
    total_full_time_operator_employee_count, total_full_time_non_operator_employee_count, total_full_time_employee_count,
    part_time_operator_vehicle_operations_hours_worked, part_time_non_operator_vehicle_operations_hours_worked, total_part_time_vehicle_operations_hours_worked,
    part_time_operator_vehicle_maintenance_hours_worked, part_time_non_operator_vehicle_maintenance_hours_worked, total_part_time_vehicle_maintenance_hours_worked,
    part_time_operator_facility_maintenance_hours_worked, part_time_non_operator_facility_maintenance_hours_worked, total_part_time_facility_maintenance_hours_worked,
    part_time_operator_general_administration_hours_worked, part_time_non_operator_general_administration_hours_worked, total_part_time_general_administration_hours_worked,
    total_part_time_operator_hours_worked, total_part_time_non_operator_hours_worked, total_part_time_hours_worked,
    part_time_operator_vehicle_operations_employee_count, part_time_non_operator_vehicle_operations_employee_count, total_part_time_vehicle_operations_employee_count,
    part_time_operator_vehicle_maintenance_employee_count, part_time_non_operator_vehicle_maintenance_employee_count, total_part_time_vehicle_maintenance_employee_count,
    part_time_operator_facility_maintenance_employee_count, part_time_non_operator_facility_maintenance_employee_count, total_part_time_facility_maintenance_employee_count,
    part_time_operator_general_administration_employee_count, part_time_non_operator_general_administration_employee_count, total_part_time_general_administration_employee_count,
    total_part_time_operator_employee_count, total_part_time_non_operator_employee_count, total_part_time_employee_count
)
SELECT
    LEFT(NULLIF(TRIM([NTD ID]), 'None'), 50),
    LEFT(NULLIF(TRIM([Agency Name]), 'None'), 255),
    LEFT(NULLIF(TRIM([Reporter Type]), 'None'), 100),
    LEFT(NULLIF(TRIM([Reporting Module]), 'None'), 100),
    LEFT(NULLIF(TRIM([Mode]), 'None'), 50),
    LEFT(NULLIF(TRIM([TOS]), 'None'), 50),

    -- Numeric Precision Mapping for 2019+ columns
    TRY_CAST(NULLIF(TRIM([Full Time Operator (Vehicle Operations) Hours Worked]), 'None') AS NUMERIC(18,2)),
    TRY_CAST(NULLIF(TRIM([Full Time Non-Operator (Vehicle Operations) Hours Worked]), 'None') AS NUMERIC(18,2)),
    TRY_CAST(NULLIF(TRIM([Total Full Time (Vehicle Operations) Hours Worked]), 'None') AS NUMERIC(18,2)),

    TRY_CAST(NULLIF(TRIM([Full Time Operator (Vehicle Maintenance) Hours Worked]), 'None') AS NUMERIC(18,2)),
    TRY_CAST(NULLIF(TRIM([Full Time Non-Operator (Vehicle Maintenance) Hours Worked]), 'None') AS NUMERIC(18,2)),
    TRY_CAST(NULLIF(TRIM([Total Full Time (Vehicle Maintenance) Hours Worked]), 'None') AS NUMERIC(18,2)),

    TRY_CAST(NULLIF(TRIM([Full Time Operator (Facility Maintenance) Hours Worked]), 'None') AS NUMERIC(18,2)),
    TRY_CAST(NULLIF(TRIM([Full Time Non-Operator (Facility Maintenance) Hours Worked]), 'None') AS NUMERIC(18,2)),
    TRY_CAST(NULLIF(TRIM([Total Full Time (Facility Maintenance) Hours Worked]), 'None') AS NUMERIC(18,2)),

    TRY_CAST(NULLIF(TRIM([Full Time Operator (General Administration) Hours Worked]), 'None') AS NUMERIC(18,2)),
    TRY_CAST(NULLIF(TRIM([Full Time Non-Operator (General Administration) Hours Worked]), 'None') AS NUMERIC(18,2)),
    TRY_CAST(NULLIF(TRIM([Total Full Time (General Administration) Hours Worked]), 'None') AS NUMERIC(18,2)),

    TRY_CAST(NULLIF(TRIM([Total Full Time Operator (Operating Labor) Hours Worked]), 'None') AS NUMERIC(18,2)),
    TRY_CAST(NULLIF(TRIM([Total Full Time Non-Operator (Operating Labor) Hours Worked]), 'None') AS NUMERIC(18,2)),
    TRY_CAST(NULLIF(TRIM([Total Full Time (Operating Labor) Hours Worked]), 'None') AS NUMERIC(18,2)),

    TRY_CAST(NULLIF(TRIM([Total Full Time Operator (Capital Labor) Hours Worked]), 'None') AS NUMERIC(18,2)),
    TRY_CAST(NULLIF(TRIM([Total Full Time Non-Operator (Capital Labor) Hours Worked]), 'None') AS NUMERIC(18,2)),
    TRY_CAST(NULLIF(TRIM([Total Full Time (Capital Labor) Hours Worked]), 'None') AS NUMERIC(18,2)),

    TRY_CAST(NULLIF(TRIM([Total Full Time Operator Hours Worked]), 'None') AS NUMERIC(18,2)),
    TRY_CAST(NULLIF(TRIM([Total Full Time Non-Operator Hours Worked]), 'None') AS NUMERIC(18,2)),
    TRY_CAST(NULLIF(TRIM([Total Full Time Hours Worked]), 'None') AS NUMERIC(18,2)),

    -- Employee Counts
    TRY_CAST(NULLIF(TRIM([Full Time Operator (Vehicle Operations) Employee Count]), 'None') AS NUMERIC(18,2)),
    TRY_CAST(NULLIF(TRIM([Full Time Non-Operator (Vehicle Operations) Employee Count]), 'None') AS NUMERIC(18,2)),
    TRY_CAST(NULLIF(TRIM([Total Full Time (Vehicle Operations) Employee Count]), 'None') AS NUMERIC(18,2)),

    TRY_CAST(NULLIF(TRIM([Full Time Operator (Vehicle Maintenance) Employee Count]), 'None') AS NUMERIC(18,2)),
    TRY_CAST(NULLIF(TRIM([Full Time Non-Operator (Vehicle Maintenance) Employee Count]), 'None') AS NUMERIC(18,2)),
    TRY_CAST(NULLIF(TRIM([Total Full Time (Vehicle Maintenance) Employee Count]), 'None') AS NUMERIC(18,2)),

    -- Part Time Sections
    TRY_CAST(NULLIF(TRIM([Part Time Operator (Vehicle Operations) Hours Worked]), 'None') AS NUMERIC(18,2)),
    TRY_CAST(NULLIF(TRIM([Part Time Non-Operator (Vehicle Operations) Hours Worked]), 'None') AS NUMERIC(18,2)),
    TRY_CAST(NULLIF(TRIM([Total Part Time (Vehicle Operations) Hours Worked]), 'None') AS NUMERIC(18,2)),

    TRY_CAST(NULLIF(TRIM([Part Time Operator (Vehicle Maintenance) Employee Count]), 'None') AS NUMERIC(18,2)),
    TRY_CAST(NULLIF(TRIM([Part Time Non-Operator (Vehicle Maintenance) Employee Count]), 'None') AS NUMERIC(18,2)),
    TRY_CAST(NULLIF(TRIM([Total Part Time (Vehicle Maintenance) Employee Count]), 'None') AS NUMERIC(18,2))

FROM raw_HR.raw_transit_agency_employees_2021;

INSERT INTO stg_HR.stg_transit_agency_employees_2022 (
    ntd_id, agency_name, reporter_type, reporting_module, mode, tos,
    full_time_operator_vehicle_operations_hours_worked, full_time_non_operator_vehicle_operations_hours_worked, total_full_time_vehicle_operations_hours_worked,
    full_time_operator_vehicle_maintenance_hours_worked, full_time_non_operator_vehicle_maintenance_hours_worked, total_full_time_vehicle_maintenance_hours_worked,
    full_time_operator_facility_maintenance_hours_worked, full_time_non_operator_facility_maintenance_hours_worked, total_full_time_facility_maintenance_hours_worked,
    full_time_operator_general_administration_hours_worked, full_time_non_operator_general_administration_hours_worked, total_full_time_general_administration_hours_worked,
    total_full_time_operator_operating_labor_hours_worked, total_full_time_non_operator_operating_labor_hours_worked, total_full_time_operating_labor_hours_worked,
    total_full_time_operator_capital_labor_hours_worked, total_full_time_non_operator_capital_labor_hours_worked, total_full_time_capital_labor_hours_worked,
    total_full_time_operator_hours_worked, total_full_time_non_operator_hours_worked, total_full_time_hours_worked,
    full_time_operator_vehicle_operations_employee_count, full_time_non_operator_vehicle_operations_employee_count, total_full_time_vehicle_operations_employee_count,
    full_time_operator_vehicle_maintenance_employee_count, full_time_non_operator_vehicle_maintenance_employee_count, total_full_time_vehicle_maintenance_employee_count,
    full_time_operator_facility_maintenance_employee_count, full_time_non_operator_facility_maintenance_employee_count, total_full_time_facility_maintenance_employee_count,
    full_time_operator_general_administration_employee_count, full_time_non_operator_general_administration_employee_count, total_full_time_general_administration_employee_count,
    total_full_time_operator_employee_count, total_full_time_non_operator_employee_count, total_full_time_employee_count,
    part_time_operator_vehicle_operations_hours_worked, part_time_non_operator_vehicle_operations_hours_worked, total_part_time_vehicle_operations_hours_worked,
    part_time_operator_vehicle_maintenance_hours_worked, part_time_non_operator_vehicle_maintenance_hours_worked, total_part_time_vehicle_maintenance_hours_worked,
    part_time_operator_facility_maintenance_hours_worked, part_time_non_operator_facility_maintenance_hours_worked, total_part_time_facility_maintenance_hours_worked,
    part_time_operator_general_administration_hours_worked, part_time_non_operator_general_administration_hours_worked, total_part_time_general_administration_hours_worked,
    total_part_time_operator_hours_worked, total_part_time_non_operator_hours_worked, total_part_time_hours_worked,
    part_time_operator_vehicle_operations_employee_count, part_time_non_operator_vehicle_operations_employee_count, total_part_time_vehicle_operations_employee_count,
    part_time_operator_vehicle_maintenance_employee_count, part_time_non_operator_vehicle_maintenance_employee_count, total_part_time_vehicle_maintenance_employee_count,
    part_time_operator_facility_maintenance_employee_count, part_time_non_operator_facility_maintenance_employee_count, total_part_time_facility_maintenance_employee_count,
    part_time_operator_general_administration_employee_count, part_time_non_operator_general_administration_employee_count, total_part_time_general_administration_employee_count,
    total_part_time_operator_employee_count, total_part_time_non_operator_employee_count, total_part_time_employee_count
)
SELECT
    LEFT(NULLIF(TRIM([NTD ID]), 'None'), 50),
    LEFT(NULLIF(TRIM([Agency Name]), 'None'), 255),
    LEFT(NULLIF(TRIM([Reporter Type]), 'None'), 100),
    LEFT(NULLIF(TRIM([Reporting Module]), 'None'), 100),
    LEFT(NULLIF(TRIM([Mode]), 'None'), 50),
    LEFT(NULLIF(TRIM([TOS]), 'None'), 50),

    -- Numeric Precision Mapping for 2019+ columns
    TRY_CAST(NULLIF(TRIM([Full Time Operator (Vehicle Operations) Hours Worked]), 'None') AS NUMERIC(18,2)),
    TRY_CAST(NULLIF(TRIM([Full Time Non-Operator (Vehicle Operations) Hours Worked]), 'None') AS NUMERIC(18,2)),
    TRY_CAST(NULLIF(TRIM([Total Full Time (Vehicle Operations) Hours Worked]), 'None') AS NUMERIC(18,2)),

    TRY_CAST(NULLIF(TRIM([Full Time Operator (Vehicle Maintenance) Hours Worked]), 'None') AS NUMERIC(18,2)),
    TRY_CAST(NULLIF(TRIM([Full Time Non-Operator (Vehicle Maintenance) Hours Worked]), 'None') AS NUMERIC(18,2)),
    TRY_CAST(NULLIF(TRIM([Total Full Time (Vehicle Maintenance) Hours Worked]), 'None') AS NUMERIC(18,2)),

    TRY_CAST(NULLIF(TRIM([Full Time Operator (Facility Maintenance) Hours Worked]), 'None') AS NUMERIC(18,2)),
    TRY_CAST(NULLIF(TRIM([Full Time Non-Operator (Facility Maintenance) Hours Worked]), 'None') AS NUMERIC(18,2)),
    TRY_CAST(NULLIF(TRIM([Total Full Time (Facility Maintenance) Hours Worked]), 'None') AS NUMERIC(18,2)),

    TRY_CAST(NULLIF(TRIM([Full Time Operator (General Administration) Hours Worked]), 'None') AS NUMERIC(18,2)),
    TRY_CAST(NULLIF(TRIM([Full Time Non-Operator (General Administration) Hours Worked]), 'None') AS NUMERIC(18,2)),
    TRY_CAST(NULLIF(TRIM([Total Full Time (General Administration) Hours Worked]), 'None') AS NUMERIC(18,2)),

    TRY_CAST(NULLIF(TRIM([Total Full Time Operator (Operating Labor) Hours Worked]), 'None') AS NUMERIC(18,2)),
    TRY_CAST(NULLIF(TRIM([Total Full Time Non-Operator (Operating Labor) Hours Worked]), 'None') AS NUMERIC(18,2)),
    TRY_CAST(NULLIF(TRIM([Total Full Time (Operating Labor) Hours Worked]), 'None') AS NUMERIC(18,2)),

    TRY_CAST(NULLIF(TRIM([Total Full Time Operator (Capital Labor) Hours Worked]), 'None') AS NUMERIC(18,2)),
    TRY_CAST(NULLIF(TRIM([Total Full Time Non-Operator (Capital Labor) Hours Worked]), 'None') AS NUMERIC(18,2)),
    TRY_CAST(NULLIF(TRIM([Total Full Time (Capital Labor) Hours Worked]), 'None') AS NUMERIC(18,2)),

    TRY_CAST(NULLIF(TRIM([Total Full Time Operator Hours Worked]), 'None') AS NUMERIC(18,2)),
    TRY_CAST(NULLIF(TRIM([Total Full Time Non-Operator Hours Worked]), 'None') AS NUMERIC(18,2)),
    TRY_CAST(NULLIF(TRIM([Total Full Time Hours Worked]), 'None') AS NUMERIC(18,2)),

    -- Employee Counts
    TRY_CAST(NULLIF(TRIM([Full Time Operator (Vehicle Operations) Employee Count]), 'None') AS NUMERIC(18,2)),
    TRY_CAST(NULLIF(TRIM([Full Time Non-Operator (Vehicle Operations) Employee Count]), 'None') AS NUMERIC(18,2)),
    TRY_CAST(NULLIF(TRIM([Total Full Time (Vehicle Operations) Employee Count]), 'None') AS NUMERIC(18,2)),

    TRY_CAST(NULLIF(TRIM([Full Time Operator (Vehicle Maintenance) Employee Count]), 'None') AS NUMERIC(18,2)),
    TRY_CAST(NULLIF(TRIM([Full Time Non-Operator (Vehicle Maintenance) Employee Count]), 'None') AS NUMERIC(18,2)),
    TRY_CAST(NULLIF(TRIM([Total Full Time (Vehicle Maintenance) Employee Count]), 'None') AS NUMERIC(18,2)),

    -- Part Time Sections
    TRY_CAST(NULLIF(TRIM([Part Time Operator (Vehicle Operations) Hours Worked]), 'None') AS NUMERIC(18,2)),
    TRY_CAST(NULLIF(TRIM([Part Time Non-Operator (Vehicle Operations) Hours Worked]), 'None') AS NUMERIC(18,2)),
    TRY_CAST(NULLIF(TRIM([Total Part Time (Vehicle Operations) Hours Worked]), 'None') AS NUMERIC(18,2)),

    TRY_CAST(NULLIF(TRIM([Part Time Operator (Vehicle Maintenance) Employee Count]), 'None') AS NUMERIC(18,2)),
    TRY_CAST(NULLIF(TRIM([Part Time Non-Operator (Vehicle Maintenance) Employee Count]), 'None') AS NUMERIC(18,2)),
    TRY_CAST(NULLIF(TRIM([Total Part Time (Vehicle Maintenance) Employee Count]), 'None') AS NUMERIC(18,2))

FROM raw_HR.raw_transit_agency_employees_2022;

INSERT INTO stg_HR.stg_transit_agency_employees_2023 (
    ntd_id, agency_name, reporter_type, reporting_module, mode, tos,
    full_time_operator_vehicle_operations_hours_worked, full_time_non_operator_vehicle_operations_hours_worked, total_full_time_vehicle_operations_hours_worked,
    full_time_operator_vehicle_maintenance_hours_worked, full_time_non_operator_vehicle_maintenance_hours_worked, total_full_time_vehicle_maintenance_hours_worked,
    full_time_operator_facility_maintenance_hours_worked, full_time_non_operator_facility_maintenance_hours_worked, total_full_time_facility_maintenance_hours_worked,
    full_time_operator_general_administration_hours_worked, full_time_non_operator_general_administration_hours_worked, total_full_time_general_administration_hours_worked,
    total_full_time_operator_operating_labor_hours_worked, total_full_time_non_operator_operating_labor_hours_worked, total_full_time_operating_labor_hours_worked,
    total_full_time_operator_capital_labor_hours_worked, total_full_time_non_operator_capital_labor_hours_worked, total_full_time_capital_labor_hours_worked,
    total_full_time_operator_hours_worked, total_full_time_non_operator_hours_worked, total_full_time_hours_worked,
    full_time_operator_vehicle_operations_employee_count, full_time_non_operator_vehicle_operations_employee_count, total_full_time_vehicle_operations_employee_count,
    full_time_operator_vehicle_maintenance_employee_count, full_time_non_operator_vehicle_maintenance_employee_count, total_full_time_vehicle_maintenance_employee_count,
    full_time_operator_facility_maintenance_employee_count, full_time_non_operator_facility_maintenance_employee_count, total_full_time_facility_maintenance_employee_count,
    full_time_operator_general_administration_employee_count, full_time_non_operator_general_administration_employee_count, total_full_time_general_administration_employee_count,
    total_full_time_operator_employee_count, total_full_time_non_operator_employee_count, total_full_time_employee_count,
    part_time_operator_vehicle_operations_hours_worked, part_time_non_operator_vehicle_operations_hours_worked, total_part_time_vehicle_operations_hours_worked,
    part_time_operator_vehicle_maintenance_hours_worked, part_time_non_operator_vehicle_maintenance_hours_worked, total_part_time_vehicle_maintenance_hours_worked,
    part_time_operator_facility_maintenance_hours_worked, part_time_non_operator_facility_maintenance_hours_worked, total_part_time_facility_maintenance_hours_worked,
    part_time_operator_general_administration_hours_worked, part_time_non_operator_general_administration_hours_worked, total_part_time_general_administration_hours_worked,
    total_part_time_operator_hours_worked, total_part_time_non_operator_hours_worked, total_part_time_hours_worked,
    part_time_operator_vehicle_operations_employee_count, part_time_non_operator_vehicle_operations_employee_count, total_part_time_vehicle_operations_employee_count,
    part_time_operator_vehicle_maintenance_employee_count, part_time_non_operator_vehicle_maintenance_employee_count, total_part_time_vehicle_maintenance_employee_count,
    part_time_operator_facility_maintenance_employee_count, part_time_non_operator_facility_maintenance_employee_count, total_part_time_facility_maintenance_employee_count,
    part_time_operator_general_administration_employee_count, part_time_non_operator_general_administration_employee_count, total_part_time_general_administration_employee_count,
    total_part_time_operator_employee_count, total_part_time_non_operator_employee_count, total_part_time_employee_count
)
SELECT
    LEFT(NULLIF(TRIM([NTD ID]), 'None'), 50),
    LEFT(NULLIF(TRIM([Agency Name]), 'None'), 255),
    LEFT(NULLIF(TRIM([Reporter Type]), 'None'), 100),
    LEFT(NULLIF(TRIM([Reporting Module]), 'None'), 100),
    LEFT(NULLIF(TRIM([Mode]), 'None'), 50),
    LEFT(NULLIF(TRIM([TOS]), 'None'), 50),

    -- Numeric Precision Mapping for 2019+ columns
    TRY_CAST(NULLIF(TRIM([Full Time Operator (Vehicle Operations) Hours Worked]), 'None') AS NUMERIC(18,2)),
    TRY_CAST(NULLIF(TRIM([Full Time Non-Operator (Vehicle Operations) Hours Worked]), 'None') AS NUMERIC(18,2)),
    TRY_CAST(NULLIF(TRIM([Total Full Time (Vehicle Operations) Hours Worked]), 'None') AS NUMERIC(18,2)),

    TRY_CAST(NULLIF(TRIM([Full Time Operator (Vehicle Maintenance) Hours Worked]), 'None') AS NUMERIC(18,2)),
    TRY_CAST(NULLIF(TRIM([Full Time Non-Operator (Vehicle Maintenance) Hours Worked]), 'None') AS NUMERIC(18,2)),
    TRY_CAST(NULLIF(TRIM([Total Full Time (Vehicle Maintenance) Hours Worked]), 'None') AS NUMERIC(18,2)),

    TRY_CAST(NULLIF(TRIM([Full Time Operator (Facility Maintenance) Hours Worked]), 'None') AS NUMERIC(18,2)),
    TRY_CAST(NULLIF(TRIM([Full Time Non-Operator (Facility Maintenance) Hours Worked]), 'None') AS NUMERIC(18,2)),
    TRY_CAST(NULLIF(TRIM([Total Full Time (Facility Maintenance) Hours Worked]), 'None') AS NUMERIC(18,2)),

    TRY_CAST(NULLIF(TRIM([Full Time Operator (General Administration) Hours Worked]), 'None') AS NUMERIC(18,2)),
    TRY_CAST(NULLIF(TRIM([Full Time Non-Operator (General Administration) Hours Worked]), 'None') AS NUMERIC(18,2)),
    TRY_CAST(NULLIF(TRIM([Total Full Time (General Administration) Hours Worked]), 'None') AS NUMERIC(18,2)),

    TRY_CAST(NULLIF(TRIM([Total Full Time Operator (Operating Labor) Hours Worked]), 'None') AS NUMERIC(18,2)),
    TRY_CAST(NULLIF(TRIM([Total Full Time Non-Operator (Operating Labor) Hours Worked]), 'None') AS NUMERIC(18,2)),
    TRY_CAST(NULLIF(TRIM([Total Full Time (Operating Labor) Hours Worked]), 'None') AS NUMERIC(18,2)),

    TRY_CAST(NULLIF(TRIM([Total Full Time Operator (Capital Labor) Hours Worked]), 'None') AS NUMERIC(18,2)),
    TRY_CAST(NULLIF(TRIM([Total Full Time Non-Operator (Capital Labor) Hours Worked]), 'None') AS NUMERIC(18,2)),
    TRY_CAST(NULLIF(TRIM([Total Full Time (Capital Labor) Hours Worked]), 'None') AS NUMERIC(18,2)),

    TRY_CAST(NULLIF(TRIM([Total Full Time Operator Hours Worked]), 'None') AS NUMERIC(18,2)),
    TRY_CAST(NULLIF(TRIM([Total Full Time Non-Operator Hours Worked]), 'None') AS NUMERIC(18,2)),
    TRY_CAST(NULLIF(TRIM([Total Full Time Hours Worked]), 'None') AS NUMERIC(18,2)),

    -- Employee Counts
    TRY_CAST(NULLIF(TRIM([Full Time Operator (Vehicle Operations) Employee Count]), 'None') AS NUMERIC(18,2)),
    TRY_CAST(NULLIF(TRIM([Full Time Non-Operator (Vehicle Operations) Employee Count]), 'None') AS NUMERIC(18,2)),
    TRY_CAST(NULLIF(TRIM([Total Full Time (Vehicle Operations) Employee Count]), 'None') AS NUMERIC(18,2)),

    TRY_CAST(NULLIF(TRIM([Full Time Operator (Vehicle Maintenance) Employee Count]), 'None') AS NUMERIC(18,2)),
    TRY_CAST(NULLIF(TRIM([Full Time Non-Operator (Vehicle Maintenance) Employee Count]), 'None') AS NUMERIC(18,2)),
    TRY_CAST(NULLIF(TRIM([Total Full Time (Vehicle Maintenance) Employee Count]), 'None') AS NUMERIC(18,2)),

    -- Part Time Sections
    TRY_CAST(NULLIF(TRIM([Part Time Operator (Vehicle Operations) Hours Worked]), 'None') AS NUMERIC(18,2)),
    TRY_CAST(NULLIF(TRIM([Part Time Non-Operator (Vehicle Operations) Hours Worked]), 'None') AS NUMERIC(18,2)),
    TRY_CAST(NULLIF(TRIM([Total Part Time (Vehicle Operations) Hours Worked]), 'None') AS NUMERIC(18,2)),

    TRY_CAST(NULLIF(TRIM([Part Time Operator (Vehicle Maintenance) Employee Count]), 'None') AS NUMERIC(18,2)),
    TRY_CAST(NULLIF(TRIM([Part Time Non-Operator (Vehicle Maintenance) Employee Count]), 'None') AS NUMERIC(18,2)),
    TRY_CAST(NULLIF(TRIM([Total Part Time (Vehicle Maintenance) Employee Count]), 'None') AS NUMERIC(18,2))

FROM raw_HR.raw_transit_agency_employees_2023;

INSERT INTO stg_HR.stg_transit_agency_employees_2024 (
    ntd_id, agency_name, reporter_type, reporting_module, mode, tos,
    full_time_operator_vehicle_operations_hours_worked, full_time_non_operator_vehicle_operations_hours_worked, total_full_time_vehicle_operations_hours_worked,
    full_time_operator_vehicle_maintenance_hours_worked, full_time_non_operator_vehicle_maintenance_hours_worked, total_full_time_vehicle_maintenance_hours_worked,
    full_time_operator_facility_maintenance_hours_worked, full_time_non_operator_facility_maintenance_hours_worked, total_full_time_facility_maintenance_hours_worked,
    full_time_operator_general_administration_hours_worked, full_time_non_operator_general_administration_hours_worked, total_full_time_general_administration_hours_worked,
    total_full_time_operator_operating_labor_hours_worked, total_full_time_non_operator_operating_labor_hours_worked, total_full_time_operating_labor_hours_worked,
    total_full_time_operator_capital_labor_hours_worked, total_full_time_non_operator_capital_labor_hours_worked, total_full_time_capital_labor_hours_worked,
    total_full_time_operator_hours_worked, total_full_time_non_operator_hours_worked, total_full_time_hours_worked,
    full_time_operator_vehicle_operations_employee_count, full_time_non_operator_vehicle_operations_employee_count, total_full_time_vehicle_operations_employee_count,
    full_time_operator_vehicle_maintenance_employee_count, full_time_non_operator_vehicle_maintenance_employee_count, total_full_time_vehicle_maintenance_employee_count,
    full_time_operator_facility_maintenance_employee_count, full_time_non_operator_facility_maintenance_employee_count, total_full_time_facility_maintenance_employee_count,
    full_time_operator_general_administration_employee_count, full_time_non_operator_general_administration_employee_count, total_full_time_general_administration_employee_count,
    total_full_time_operator_employee_count, total_full_time_non_operator_employee_count, total_full_time_employee_count,
    part_time_operator_vehicle_operations_hours_worked, part_time_non_operator_vehicle_operations_hours_worked, total_part_time_vehicle_operations_hours_worked,
    part_time_operator_vehicle_maintenance_hours_worked, part_time_non_operator_vehicle_maintenance_hours_worked, total_part_time_vehicle_maintenance_hours_worked,
    part_time_operator_facility_maintenance_hours_worked, part_time_non_operator_facility_maintenance_hours_worked, total_part_time_facility_maintenance_hours_worked,
    part_time_operator_general_administration_hours_worked, part_time_non_operator_general_administration_hours_worked, total_part_time_general_administration_hours_worked,
    total_part_time_operator_hours_worked, total_part_time_non_operator_hours_worked, total_part_time_hours_worked,
    part_time_operator_vehicle_operations_employee_count, part_time_non_operator_vehicle_operations_employee_count, total_part_time_vehicle_operations_employee_count,
    part_time_operator_vehicle_maintenance_employee_count, part_time_non_operator_vehicle_maintenance_employee_count, total_part_time_vehicle_maintenance_employee_count,
    part_time_operator_facility_maintenance_employee_count, part_time_non_operator_facility_maintenance_employee_count, total_part_time_facility_maintenance_employee_count,
    part_time_operator_general_administration_employee_count, part_time_non_operator_general_administration_employee_count, total_part_time_general_administration_employee_count,
    total_part_time_operator_employee_count, total_part_time_non_operator_employee_count, total_part_time_employee_count
)
SELECT
    LEFT(NULLIF(TRIM([NTD ID]), 'None'), 50),
    LEFT(NULLIF(TRIM([Agency Name]), 'None'), 255),
    LEFT(NULLIF(TRIM([Reporter Type]), 'None'), 100),
    LEFT(NULLIF(TRIM([Reporting Module]), 'None'), 100),
    LEFT(NULLIF(TRIM([Mode]), 'None'), 50),
    LEFT(NULLIF(TRIM([TOS]), 'None'), 50),

    -- Numeric Precision Mapping for 2019+ columns
    TRY_CAST(NULLIF(TRIM([Full Time Operator (Vehicle Operations) Hours Worked]), 'None') AS NUMERIC(18,2)),
    TRY_CAST(NULLIF(TRIM([Full Time Non-Operator (Vehicle Operations) Hours Worked]), 'None') AS NUMERIC(18,2)),
    TRY_CAST(NULLIF(TRIM([Total Full Time (Vehicle Operations) Hours Worked]), 'None') AS NUMERIC(18,2)),

    TRY_CAST(NULLIF(TRIM([Full Time Operator (Vehicle Maintenance) Hours Worked]), 'None') AS NUMERIC(18,2)),
    TRY_CAST(NULLIF(TRIM([Full Time Non-Operator (Vehicle Maintenance) Hours Worked]), 'None') AS NUMERIC(18,2)),
    TRY_CAST(NULLIF(TRIM([Total Full Time (Vehicle Maintenance) Hours Worked]), 'None') AS NUMERIC(18,2)),

    TRY_CAST(NULLIF(TRIM([Full Time Operator (Facility Maintenance) Hours Worked]), 'None') AS NUMERIC(18,2)),
    TRY_CAST(NULLIF(TRIM([Full Time Non-Operator (Facility Maintenance) Hours Worked]), 'None') AS NUMERIC(18,2)),
    TRY_CAST(NULLIF(TRIM([Total Full Time (Facility Maintenance) Hours Worked]), 'None') AS NUMERIC(18,2)),

    TRY_CAST(NULLIF(TRIM([Full Time Operator (General Administration) Hours Worked]), 'None') AS NUMERIC(18,2)),
    TRY_CAST(NULLIF(TRIM([Full Time Non-Operator (General Administration) Hours Worked]), 'None') AS NUMERIC(18,2)),
    TRY_CAST(NULLIF(TRIM([Total Full Time (General Administration) Hours Worked]), 'None') AS NUMERIC(18,2)),

    TRY_CAST(NULLIF(TRIM([Total Full Time Operator (Operating Labor) Hours Worked]), 'None') AS NUMERIC(18,2)),
    TRY_CAST(NULLIF(TRIM([Total Full Time Non-Operator (Operating Labor) Hours Worked]), 'None') AS NUMERIC(18,2)),
    TRY_CAST(NULLIF(TRIM([Total Full Time (Operating Labor) Hours Worked]), 'None') AS NUMERIC(18,2)),

    TRY_CAST(NULLIF(TRIM([Total Full Time Operator (Capital Labor) Hours Worked]), 'None') AS NUMERIC(18,2)),
    TRY_CAST(NULLIF(TRIM([Total Full Time Non-Operator (Capital Labor) Hours Worked]), 'None') AS NUMERIC(18,2)),
    TRY_CAST(NULLIF(TRIM([Total Full Time (Capital Labor) Hours Worked]), 'None') AS NUMERIC(18,2)),

    TRY_CAST(NULLIF(TRIM([Total Full Time Operator Hours Worked]), 'None') AS NUMERIC(18,2)),
    TRY_CAST(NULLIF(TRIM([Total Full Time Non-Operator Hours Worked]), 'None') AS NUMERIC(18,2)),
    TRY_CAST(NULLIF(TRIM([Total Full Time Hours Worked]), 'None') AS NUMERIC(18,2)),

    -- Employee Counts
    TRY_CAST(NULLIF(TRIM([Full Time Operator (Vehicle Operations) Employee Count]), 'None') AS NUMERIC(18,2)),
    TRY_CAST(NULLIF(TRIM([Full Time Non-Operator (Vehicle Operations) Employee Count]), 'None') AS NUMERIC(18,2)),
    TRY_CAST(NULLIF(TRIM([Total Full Time (Vehicle Operations) Employee Count]), 'None') AS NUMERIC(18,2)),

    TRY_CAST(NULLIF(TRIM([Full Time Operator (Vehicle Maintenance) Employee Count]), 'None') AS NUMERIC(18,2)),
    TRY_CAST(NULLIF(TRIM([Full Time Non-Operator (Vehicle Maintenance) Employee Count]), 'None') AS NUMERIC(18,2)),
    TRY_CAST(NULLIF(TRIM([Total Full Time (Vehicle Maintenance) Employee Count]), 'None') AS NUMERIC(18,2)),

    -- Part Time Sections
    TRY_CAST(NULLIF(TRIM([Part Time Operator (Vehicle Operations) Hours Worked]), 'None') AS NUMERIC(18,2)),
    TRY_CAST(NULLIF(TRIM([Part Time Non-Operator (Vehicle Operations) Hours Worked]), 'None') AS NUMERIC(18,2)),
    TRY_CAST(NULLIF(TRIM([Total Part Time (Vehicle Operations) Hours Worked]), 'None') AS NUMERIC(18,2)),

    TRY_CAST(NULLIF(TRIM([Part Time Operator (Vehicle Maintenance) Employee Count]), 'None') AS NUMERIC(18,2)),
    TRY_CAST(NULLIF(TRIM([Part Time Non-Operator (Vehicle Maintenance) Employee Count]), 'None') AS NUMERIC(18,2)),
    TRY_CAST(NULLIF(TRIM([Total Part Time (Vehicle Maintenance) Employee Count]), 'None') AS NUMERIC(18,2))

FROM raw_HR.raw_transit_agency_employees_2024;


INSERT INTO stg_HR.stg_transit_agency_employees_2019 (
    ntd_id, agency_name, reporter_type, reporting_module, mode, tos,
    full_time_operator_vehicle_operations_hours_worked, full_time_non_operator_vehicle_operations_hours_worked, total_full_time_vehicle_operations_hours_worked,
    full_time_operator_vehicle_maintenance_hours_worked, full_time_non_operator_vehicle_maintenance_hours_worked, total_full_time_vehicle_maintenance_hours_worked,
    full_time_operator_facility_maintenance_hours_worked, full_time_non_operator_facility_maintenance_hours_worked, total_full_time_facility_maintenance_hours_worked,
    full_time_operator_general_administration_hours_worked, full_time_non_operator_general_administration_hours_worked, total_full_time_general_administration_hours_worked,
    total_full_time_operator_operating_labor_hours_worked, total_full_time_non_operator_operating_labor_hours_worked, total_full_time_operating_labor_hours_worked,
    total_full_time_operator_capital_labor_hours_worked, total_full_time_non_operator_capital_labor_hours_worked, total_full_time_capital_labor_hours_worked,
    total_full_time_operator_hours_worked, total_full_time_non_operator_hours_worked, total_full_time_hours_worked,
    full_time_operator_vehicle_operations_employee_count, full_time_non_operator_vehicle_operations_employee_count, total_full_time_vehicle_operations_employee_count,
    full_time_operator_vehicle_maintenance_employee_count, full_time_non_operator_vehicle_maintenance_employee_count, total_full_time_vehicle_maintenance_employee_count,
    full_time_operator_facility_maintenance_employee_count, full_time_non_operator_facility_maintenance_employee_count, total_full_time_facility_maintenance_employee_count,
    full_time_operator_general_administration_employee_count, full_time_non_operator_general_administration_employee_count, total_full_time_general_administration_employee_count,
    total_full_time_operator_employee_count, total_full_time_non_operator_employee_count, total_full_time_employee_count,
    part_time_operator_vehicle_operations_hours_worked, part_time_non_operator_vehicle_operations_hours_worked, total_part_time_vehicle_operations_hours_worked,
    part_time_operator_vehicle_maintenance_hours_worked, part_time_non_operator_vehicle_maintenance_hours_worked, total_part_time_vehicle_maintenance_hours_worked,
    part_time_operator_facility_maintenance_hours_worked, part_time_non_operator_facility_maintenance_hours_worked, total_part_time_facility_maintenance_hours_worked,
    part_time_operator_general_administration_hours_worked, part_time_non_operator_general_administration_hours_worked, total_part_time_general_administration_hours_worked,
    total_part_time_operator_hours_worked, total_part_time_non_operator_hours_worked, total_part_time_hours_worked,
    part_time_operator_vehicle_operations_employee_count, part_time_non_operator_vehicle_operations_employee_count, total_part_time_vehicle_operations_employee_count,
    part_time_operator_vehicle_maintenance_employee_count, part_time_non_operator_vehicle_maintenance_employee_count, total_part_time_vehicle_maintenance_employee_count,
    part_time_operator_facility_maintenance_employee_count, part_time_non_operator_facility_maintenance_employee_count, total_part_time_facility_maintenance_employee_count,
    part_time_operator_general_administration_employee_count, part_time_non_operator_general_administration_employee_count, total_part_time_general_administration_employee_count,
    total_part_time_operator_employee_count, total_part_time_non_operator_employee_count, total_part_time_employee_count
)
SELECT
    LEFT(NULLIF(TRIM([NTD ID]), 'None'), 50),
    LEFT(NULLIF(TRIM([Agency Name]), 'None'), 255),
    LEFT(NULLIF(TRIM([Reporter Type]), 'None'), 100),
    LEFT(NULLIF(TRIM([Reporting Module]), 'None'), 100),
    LEFT(NULLIF(TRIM([Mode]), 'None'), 50),
    LEFT(NULLIF(TRIM([TOS]), 'None'), 50),

    -- Numeric Precision Mapping for 2019+ columns
    TRY_CAST(NULLIF(TRIM([Full Time Operator (Vehicle Operations) Hours Worked]), 'None') AS NUMERIC(18,2)),
    TRY_CAST(NULLIF(TRIM([Full Time Non-Operator (Vehicle Operations) Hours Worked]), 'None') AS NUMERIC(18,2)),
    TRY_CAST(NULLIF(TRIM([Total Full Time (Vehicle Operations) Hours Worked]), 'None') AS NUMERIC(18,2)),

    TRY_CAST(NULLIF(TRIM([Full Time Operator (Vehicle Maintenance) Hours Worked]), 'None') AS NUMERIC(18,2)),
    TRY_CAST(NULLIF(TRIM([Full Time Non-Operator (Vehicle Maintenance) Hours Worked]), 'None') AS NUMERIC(18,2)),
    TRY_CAST(NULLIF(TRIM([Total Full Time (Vehicle Maintenance) Hours Worked]), 'None') AS NUMERIC(18,2)),

    TRY_CAST(NULLIF(TRIM([Full Time Operator (Facility Maintenance) Hours Worked]), 'None') AS NUMERIC(18,2)),
    TRY_CAST(NULLIF(TRIM([Full Time Non-Operator (Facility Maintenance) Hours Worked]), 'None') AS NUMERIC(18,2)),
    TRY_CAST(NULLIF(TRIM([Total Full Time (Facility Maintenance) Hours Worked]), 'None') AS NUMERIC(18,2)),

    TRY_CAST(NULLIF(TRIM([Full Time Operator (General Administration) Hours Worked]), 'None') AS NUMERIC(18,2)),
    TRY_CAST(NULLIF(TRIM([Full Time Non-Operator (General Administration) Hours Worked]), 'None') AS NUMERIC(18,2)),
    TRY_CAST(NULLIF(TRIM([Total Full Time (General Administration) Hours Worked]), 'None') AS NUMERIC(18,2)),

    TRY_CAST(NULLIF(TRIM([Total Full Time Operator (Operating Labor) Hours Worked]), 'None') AS NUMERIC(18,2)),
    TRY_CAST(NULLIF(TRIM([Total Full Time Non-Operator (Operating Labor) Hours Worked]), 'None') AS NUMERIC(18,2)),
    TRY_CAST(NULLIF(TRIM([Total Full Time (Operating Labor) Hours Worked]), 'None') AS NUMERIC(18,2)),

    TRY_CAST(NULLIF(TRIM([Total Full Time Operator (Capital Labor) Hours Worked]), 'None') AS NUMERIC(18,2)),
    TRY_CAST(NULLIF(TRIM([Total Full Time Non-Operator (Capital Labor) Hours Worked]), 'None') AS NUMERIC(18,2)),
    TRY_CAST(NULLIF(TRIM([Total Full Time (Capital Labor) Hours Worked]), 'None') AS NUMERIC(18,2)),

    TRY_CAST(NULLIF(TRIM([Total Full Time Operator Hours Worked]), 'None') AS NUMERIC(18,2)),
    TRY_CAST(NULLIF(TRIM([Total Full Time Non-Operator Hours Worked]), 'None') AS NUMERIC(18,2)),
    TRY_CAST(NULLIF(TRIM([Total Full Time Hours Worked]), 'None') AS NUMERIC(18,2)),

    -- Employee Counts
    TRY_CAST(NULLIF(TRIM([Full Time Operator (Vehicle Operations) Employee Count]), 'None') AS NUMERIC(18,2)),
    TRY_CAST(NULLIF(TRIM([Full Time Non-Operator (Vehicle Operations) Employee Count]), 'None') AS NUMERIC(18,2)),
    TRY_CAST(NULLIF(TRIM([Total Full Time (Vehicle Operations) Employee Count]), 'None') AS NUMERIC(18,2)),

    TRY_CAST(NULLIF(TRIM([Full Time Operator (Vehicle Maintenance) Employee Count]), 'None') AS NUMERIC(18,2)),
    TRY_CAST(NULLIF(TRIM([Full Time Non-Operator (Vehicle Maintenance) Employee Count]), 'None') AS NUMERIC(18,2)),
    TRY_CAST(NULLIF(TRIM([Total Full Time (Vehicle Maintenance) Employee Count]), 'None') AS NUMERIC(18,2)),

    -- Part Time Sections
    TRY_CAST(NULLIF(TRIM([Part Time Operator (Vehicle Operations) Hours Worked]), 'None') AS NUMERIC(18,2)),
    TRY_CAST(NULLIF(TRIM([Part Time Non-Operator (Vehicle Operations) Hours Worked]), 'None') AS NUMERIC(18,2)),
    TRY_CAST(NULLIF(TRIM([Total Part Time (Vehicle Operations) Hours Worked]), 'None') AS NUMERIC(18,2)),

    TRY_CAST(NULLIF(TRIM([Part Time Operator (Vehicle Maintenance) Employee Count]), 'None') AS NUMERIC(18,2)),
    TRY_CAST(NULLIF(TRIM([Part Time Non-Operator (Vehicle Maintenance) Employee Count]), 'None') AS NUMERIC(18,2)),
    TRY_CAST(NULLIF(TRIM([Total Part Time (Vehicle Maintenance) Employee Count]), 'None') AS NUMERIC(18,2))

FROM raw_HR.raw_transit_agency_employees_2025;


-- ============================================================
-- 3. Load Job Openings Data (Transaction Source)
-- ============================================================
INSERT INTO stg_HR.stg_job_openings (
    OpeningID, PostingDate, PostingDateKey, ReportYear, NTD_ID, AgencyName,
    ReporterType, ReportingModule, OrganizationType, City, State, Region,
    ModeCode, ModeName, TOS, TypeOfServiceName, NTDLaborObjectClass,
    OperatorStatus, EmploymentType, PositionTitle, Department, OpenPositions,
    SalaryMinHourly, SalaryMaxHourly, SalaryMidHourly, SalaryType,
    PostingStatus, ClosingDate, FilledDate, DaysOpen, HiredCount,
    VacancyReason, SourceSystem, SyntheticDataFlag, SourceBasisURL, SourceBasisNote
)
SELECT
    LEFT(NULLIF(TRIM(OpeningID), 'None'), 50),
    TRY_CAST(NULLIF(TRIM(PostingDate), 'None') AS DATE),
    TRY_CAST(TRY_CAST(NULLIF(TRIM(PostingDateKey), 'None') AS FLOAT) AS INT),
    TRY_CAST(TRY_CAST(NULLIF(TRIM(ReportYear), 'None') AS FLOAT) AS INT),
    LEFT(NULLIF(TRIM(NTD_ID), 'None'), 50),
    LEFT(NULLIF(TRIM(AgencyName), 'None'), 255),
    LEFT(NULLIF(TRIM(ReporterType), 'None'), 100),
    LEFT(NULLIF(TRIM(ReportingModule), 'None'), 100),
    LEFT(NULLIF(TRIM(OrganizationType), 'None'), 255),
    LEFT(NULLIF(TRIM(City), 'None'), 100),
    LEFT(NULLIF(TRIM(State), 'None'), 50),
    LEFT(NULLIF(TRIM(Region), 'None'), 50),
    LEFT(NULLIF(TRIM(ModeCode), 'None'), 20),
    LEFT(NULLIF(TRIM(ModeName), 'None'), 100),
    LEFT(NULLIF(TRIM(TOS), 'None'), 20),
    LEFT(NULLIF(TRIM(TypeOfServiceName), 'None'), 100),
    LEFT(NULLIF(TRIM(NTDLaborObjectClass), 'None'), 100),
    LEFT(NULLIF(TRIM(OperatorStatus), 'None'), 50),
    LEFT(NULLIF(TRIM(EmploymentType), 'None'), 50),
    LEFT(NULLIF(TRIM(PositionTitle), 'None'), 255),
    LEFT(NULLIF(TRIM(Department), 'None'), 255),

    TRY_CAST(TRY_CAST(NULLIF(TRIM(OpenPositions), 'None') AS FLOAT) AS INT),
    TRY_CAST(NULLIF(TRIM(SalaryMinHourly), 'None') AS NUMERIC(18,2)),
    TRY_CAST(NULLIF(TRIM(SalaryMaxHourly), 'None') AS NUMERIC(18,2)),
    TRY_CAST(NULLIF(TRIM(SalaryMidHourly), 'None') AS NUMERIC(18,2)),

    LEFT(NULLIF(TRIM(SalaryType), 'None'), 50),
    LEFT(NULLIF(TRIM(PostingStatus), 'None'), 50),
    TRY_CAST(NULLIF(TRIM(ClosingDate), 'None') AS DATE),
    TRY_CAST(NULLIF(TRIM(FilledDate), 'None') AS DATE),
    TRY_CAST(TRY_CAST(NULLIF(TRIM(DaysOpen), 'None') AS FLOAT) AS INT),
    TRY_CAST(TRY_CAST(NULLIF(TRIM(HiredCount), 'None') AS FLOAT) AS INT),

    LEFT(NULLIF(TRIM(VacancyReason), 'None'), 255),
    LEFT(NULLIF(TRIM(SourceSystem), 'None'), 100),
    LEFT(NULLIF(TRIM(SyntheticDataFlag), 'None'), 5),
    LEFT(NULLIF(TRIM(SourceBasisURL), 'None'), 500),
    LEFT(NULLIF(TRIM(SourceBasisNote), 'None'), 500)
FROM raw_HR.raw_job_openings;
