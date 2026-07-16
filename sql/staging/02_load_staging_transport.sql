-- ============================================================
-- Clean out staging for a fresh load (Truncate and Load pattern)
-- ============================================================
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

INSERT INTO stg_transport.stg_agency_information (
    state_parent_ntd_id,
    ntd_id,
    legacy_ntd_id,
    agency_name,
    division_department,
    reporter_acronym,
    doing_business_as,
    reporter_type,
    reporting_module,
    organization_type,
    reported_by_ntd_id,
    reported_by_name,
    public_sponsor,
    subrecipient_type,
    fy_end_date,
    original_due_date,
    address_line_1,
    address_line_2,
    po_box,
    city,
    state,
    zip_code,
    zip_code_ext,
    region,
    url,
    fta_recipient_id,
    ueid,
    service_area_sq_miles,
    service_area_pop,
    primary_uza_uace_code,
    uza_name,
    tribal_area_name,
    population,
    density,
    sq_miles,
    voms_do,
    voms_pt,
    total_voms,
    volunteer_drivers,
    personal_vehicles,
    tam_tier,
    number_of_state_counties,
    number_of_counties_with_service,
    state_admin_funds_expended
)
SELECT
    -- 1. Standard String Conversions & Trimming
    LEFT(NULLIF(TRIM([State/Parent NTD ID]), 'None'), 50),
    LEFT(NULLIF(TRIM([NTD ID]), 'None'), 50),
    LEFT(NULLIF(TRIM([Legacy NTD ID]), 'None'), 50),
    LEFT(NULLIF(TRIM([Agency Name]), 'None'), 255),
    LEFT(NULLIF(TRIM([Division/Department]), 'None'), 255),
    LEFT(NULLIF(TRIM([Reporter Acronym]), 'None'), 50),
    LEFT(NULLIF(TRIM([Doing Business As]), 'None'), 255),
    LEFT(NULLIF(TRIM([Reporter Type]), 'None'), 100),
    LEFT(NULLIF(TRIM([Reporting Module]), 'None'), 50),
    LEFT(NULLIF(TRIM([Organization Type]), 'None'), 255),
    LEFT(NULLIF(TRIM([Reported By NTD ID]), 'None'), 50),
    LEFT(NULLIF(TRIM([Reported by Name]), 'None'), 255),
    LEFT(NULLIF(TRIM([Public Sponsor]), 'None'), 255),
    LEFT(NULLIF(TRIM([Subrecipient Type]), 'None'), 100),

    -- 2. Clean Date Parsing (Safely handles standard ISO formats like YYYY-MM-DD)
    TRY_CAST(NULLIF(TRIM([FY End Date]), 'None') AS DATE),
    TRY_CAST(NULLIF(TRIM([Original Due Date]), 'None') AS DATE),

    -- 3. Address and Metadata Fields
    LEFT(NULLIF(TRIM([Address Line 1]), 'None'), 255),
    LEFT(NULLIF(TRIM([Address Line 2]), 'None'), 255),
    LEFT(NULLIF(TRIM([P.O. Box]), 'None'), 100),
    LEFT(NULLIF(TRIM([City]), 'None'), 100),
    LEFT(NULLIF(TRIM([State]), 'None'), 20),

    -- 4. Clean Zip Codes (Stripping out decimal notations like '98104.0' -> '98104')
    CASE
        WHEN CHARINDEX('.', [Zip Code]) > 0
        THEN LEFT([Zip Code], CHARINDEX('.', [Zip Code]) - 1)
        ELSE NULLIF(TRIM([Zip Code]), 'None')
    END,
    CASE
        WHEN CHARINDEX('.', [Zip Code Ext]) > 0
        THEN LEFT([Zip Code Ext], CHARINDEX('.', [Zip Code Ext]) - 1)
        ELSE NULLIF(TRIM([Zip Code Ext]), 'None')
    END,

    -- 5. Safe Integer Transformations
    TRY_CAST(TRY_CAST(NULLIF(TRIM([Region]), 'None') AS FLOAT) AS INT),

    -- 6. Direct Text Fields
    LEFT(NULLIF(TRIM([URL]), 'None'), 500),
    LEFT(NULLIF(TRIM([FTA Recipient ID]), 'None'), 50),
    LEFT(NULLIF(TRIM([UEID]), 'None'), 50),

    -- 7. High-Precision Numeric Columns
    TRY_CAST(NULLIF(TRIM([Service Area Sq Miles]), 'None') AS NUMERIC(18,2)),
    TRY_CAST(TRY_CAST(NULLIF(TRIM([Service Area Pop]), 'None') AS FLOAT) AS BIGINT),

    -- 8. Core Location and Demographic Fields
    CASE WHEN CHARINDEX('.', TRIM([Primary UZA UACE Code])) > 0 THEN LEFT(TRIM([Primary UZA UACE Code]), CHARINDEX('.', TRIM([Primary UZA UACE Code])) - 1) ELSE LEFT(NULLIF(TRIM([Primary UZA UACE Code]), 'None'), 50) END,
    LEFT(NULLIF(TRIM([UZA Name]), 'None'), 255),
    LEFT(NULLIF(TRIM([Tribal Area Name]), 'None'), 255),
    TRY_CAST(TRY_CAST(NULLIF(TRIM([Population]), 'None') AS FLOAT) AS BIGINT),
    TRY_CAST(NULLIF(TRIM([Density]), 'None') AS NUMERIC(18,2)),
    TRY_CAST(NULLIF(TRIM([Sq Miles]), 'None') AS NUMERIC(18,2)),

    -- 9. Fleet Metrics and Asset Counts (VOMS)
    TRY_CAST(NULLIF(TRIM([VOMS DO]), 'None') AS NUMERIC(18,2)),
    TRY_CAST(NULLIF(TRIM([VOMS PT]), 'None') AS NUMERIC(18,2)),
    TRY_CAST(NULLIF(TRIM([Total VOMS]), 'None') AS NUMERIC(18,2)),
    TRY_CAST(NULLIF(TRIM([Volunteer Drivers]), 'None') AS NUMERIC(18,2)),
    TRY_CAST(NULLIF(TRIM([Personal Vehicles]), 'None') AS NUMERIC(18,2)),

    -- 10. Final Strategy Metrics
    LEFT(NULLIF(TRIM([TAM Tier]), 'None'), 100),
    TRY_CAST(NULLIF(TRIM([Number of State Counties]), 'None') AS NUMERIC(18,2)),
    TRY_CAST(NULLIF(TRIM([Number of Counties with Service]), 'None') AS NUMERIC(18,2)),
    TRY_CAST(NULLIF(TRIM([State Admin Funds Expended]), 'None') AS NUMERIC(18,2))

FROM (
    SELECT
        *,
        ROW_NUMBER() OVER (PARTITION BY TRIM([NTD ID]) ORDER BY (SELECT NULL)) AS rn
    FROM raw_transport.[raw_2024_agency_information_250922]
) src
WHERE src.rn = 1;

INSERT INTO stg_transport.stg_agency_mode_service (
    state_parent_ntd_id,
    ntd_id,
    agency_name,
    reporter_type,
    reporting_module,
    mode,
    type_of_service_code,
    voms,
    vams,
    rail,
    fixed_route,
    seasonal_segment,
    fixed_guideway_high_intensity,
    service_type,
    commitment_date,
    start_service_date,
    end_service_date
)
SELECT
    -- 1. Metadata and Identification Fields
    LEFT(NULLIF(TRIM([State/Parent NTD ID]), 'None'), 50),
    LEFT(NULLIF(TRIM([NTD ID]), 'None'), 50),
    LEFT(NULLIF(TRIM([Agency Name]), 'None'), 255),
    LEFT(NULLIF(TRIM([Reporter Type]), 'None'), 100),
    LEFT(NULLIF(TRIM([Reporting Module]), 'None'), 50),

    -- 2. Transit Metrics (Mapping 'TOS' to 'type_of_service_code')
    LEFT(NULLIF(TRIM([Mode]), 'None'), 20),
    LEFT(NULLIF(TRIM([TOS]), 'None'), 20),

    -- 3. Vehicle Counts (Safely handling strings with float decimals e.g. '416.0')
    TRY_CAST(TRY_CAST(NULLIF(TRIM([Vehicles Operated at Maximum Service (VOMS)]), 'None') AS FLOAT) AS NUMERIC(18,2)),
    TRY_CAST(TRY_CAST(NULLIF(TRIM([Vehicles Available at Maximum Service (VAMS)]), 'None') AS FLOAT) AS NUMERIC(18,2)),

    -- 4. Operational Flags
    LEFT(NULLIF(TRIM([Rail]), 'None'), 5),
    LEFT(NULLIF(TRIM([Fixed Route]), 'None'), 5),
    LEFT(NULLIF(TRIM([Seasonal Segment]), 'None'), 5),
    LEFT(NULLIF(TRIM([Fixed Guideway/High Intensity]), 'None'), 5),

    -- 5. Service Categorization
    LEFT(NULLIF(TRIM([Service Type]), 'None'), 100),

    -- 6. Date Transformations (TRY_CAST handles standard 'YYYY-MM-DD' cleanly)
    TRY_CAST(NULLIF(TRIM([Commitment Date]), 'None') AS DATE),
    TRY_CAST(NULLIF(TRIM([Start Service Date]), 'None') AS DATE),
    TRY_CAST(NULLIF(TRIM([End Service Date]), 'None') AS DATE)

FROM [raw_transport].[raw_2024_agency_mode_type_of_service_250828];

INSERT INTO stg_transport.stg_ts21_drm (
    last_report_year,
    ntd_id,
    agency_name,
    agency_status,
    reporter_type,
    reporting_module,
    city,
    state,
    census_year,
    primary_uza_name,
    uace_code,
    uza_area_sq_miles,
    uza_population,
    mode_status,
    mode,
    type_of_service,
    y2015,
    y2016,
    y2017,
    y2018,
    y2019,
    y2020,
    y2021,
    y2022,
    y2023,
    y2024
)
SELECT
    TRY_CAST(NULLIF(TRIM([Last Report Year]), '') AS INT),

    LEFT(NULLIF(TRIM([NTD ID]), ''), 50),

    LEFT(NULLIF(TRIM([Agency Name]), ''), 255),
    LEFT(NULLIF(TRIM([Agency Status]), ''), 50),
    LEFT(NULLIF(TRIM([Reporter Type]), ''), 100),
    LEFT(NULLIF(TRIM([Reporting Module]), ''), 50),

    LEFT(NULLIF(TRIM([City]), ''), 100),
    LEFT(NULLIF(TRIM([State]), ''), 20),

    LEFT(NULLIF(TRIM([Census Year]), ''), 20),

    LEFT(NULLIF(TRIM([Primary UZA Name]), ''), 255),

    CAST(
        TRY_CAST(
            TRY_CAST(NULLIF(TRIM([UACE Code]), '') AS FLOAT)
        AS BIGINT)
    AS VARCHAR(50)),

    TRY_CAST(
        TRY_CAST(NULLIF(TRIM([UZA Area SQ Miles]), '') AS FLOAT)
    AS NUMERIC(18,2)),

    TRY_CAST(
        TRY_CAST(NULLIF(TRIM([UZA Population]), '') AS FLOAT)
    AS BIGINT),

    LEFT(NULLIF(TRIM([Mode_Status]), ''), 50),
    LEFT(NULLIF(TRIM([Mode]), ''), 20),
    LEFT(NULLIF(TRIM([Type of Service]), ''), 20),

    TRY_CAST(TRY_CAST(NULLIF(TRIM([2015]), '') AS FLOAT) AS NUMERIC(18,2)),
    TRY_CAST(TRY_CAST(NULLIF(TRIM([2016]), '') AS FLOAT) AS NUMERIC(18,2)),
    TRY_CAST(TRY_CAST(NULLIF(TRIM([2017]), '') AS FLOAT) AS NUMERIC(18,2)),
    TRY_CAST(TRY_CAST(NULLIF(TRIM([2018]), '') AS FLOAT) AS NUMERIC(18,2)),
    TRY_CAST(TRY_CAST(NULLIF(TRIM([2019]), '') AS FLOAT) AS NUMERIC(18,2)),
    TRY_CAST(TRY_CAST(NULLIF(TRIM([2020]), '') AS FLOAT) AS NUMERIC(18,2)),
    TRY_CAST(TRY_CAST(NULLIF(TRIM([2021]), '') AS FLOAT) AS NUMERIC(18,2)),
    TRY_CAST(TRY_CAST(NULLIF(TRIM([2022]), '') AS FLOAT) AS NUMERIC(18,2)),
    TRY_CAST(TRY_CAST(NULLIF(TRIM([2023]), '') AS FLOAT) AS NUMERIC(18,2)),
    TRY_CAST(TRY_CAST(NULLIF(TRIM([2024]), '') AS FLOAT) AS NUMERIC(18,2))

FROM raw_transport.raw_2024_ts2_1_service_data_and_operating_expenses_time_series_by_mode_drm;

INSERT INTO stg_transport.stg_ts21_fares (
    last_report_year,
    ntd_id,
    agency_name,
    agency_status,
    reporter_type,
    reporting_module,
    city,
    state,
    census_year,
    primary_uza_name,
    uace_code,
    uza_area_sq_miles,
    uza_population,
    mode_status,
    mode,
    type_of_service,
    y2015,
    y2016,
    y2017,
    y2018,
    y2019,
    y2020,
    y2021,
    y2022,
    y2023,
    y2024
)
SELECT
    TRY_CAST(NULLIF(TRIM([Last Report Year]), '') AS INT),

    LEFT(NULLIF(TRIM([NTD ID]), ''), 50),

    LEFT(NULLIF(TRIM([Agency Name]), ''), 255),
    LEFT(NULLIF(TRIM([Agency Status]), ''), 50),
    LEFT(NULLIF(TRIM([Reporter Type]), ''), 100),
    LEFT(NULLIF(TRIM([Reporting Module]), ''), 50),

    LEFT(NULLIF(TRIM([City]), ''), 100),
    LEFT(NULLIF(TRIM([State]), ''), 20),

    LEFT(NULLIF(TRIM([Census Year]), ''), 20),

    LEFT(NULLIF(TRIM([Primary UZA Name]), ''), 255),

    CAST(
        TRY_CAST(
            TRY_CAST(NULLIF(TRIM([UACE Code]), '') AS FLOAT)
        AS BIGINT)
    AS VARCHAR(50)),

    TRY_CAST(
        TRY_CAST(NULLIF(TRIM([UZA Area SQ Miles]), '') AS FLOAT)
    AS NUMERIC(18,2)),

    TRY_CAST(
        TRY_CAST(NULLIF(TRIM([UZA Population]), '') AS FLOAT)
    AS BIGINT),

    LEFT(NULLIF(TRIM([Mode_Status]), ''), 50),
    LEFT(NULLIF(TRIM([Mode]), ''), 20),
    LEFT(NULLIF(TRIM([Type of Service]), ''), 20),

    TRY_CAST(TRY_CAST(NULLIF(TRIM([2015]), '') AS FLOAT) AS NUMERIC(18,2)),
    TRY_CAST(TRY_CAST(NULLIF(TRIM([2016]), '') AS FLOAT) AS NUMERIC(18,2)),
    TRY_CAST(TRY_CAST(NULLIF(TRIM([2017]), '') AS FLOAT) AS NUMERIC(18,2)),
    TRY_CAST(TRY_CAST(NULLIF(TRIM([2018]), '') AS FLOAT) AS NUMERIC(18,2)),
    TRY_CAST(TRY_CAST(NULLIF(TRIM([2019]), '') AS FLOAT) AS NUMERIC(18,2)),
    TRY_CAST(TRY_CAST(NULLIF(TRIM([2020]), '') AS FLOAT) AS NUMERIC(18,2)),
    TRY_CAST(TRY_CAST(NULLIF(TRIM([2021]), '') AS FLOAT) AS NUMERIC(18,2)),
    TRY_CAST(TRY_CAST(NULLIF(TRIM([2022]), '') AS FLOAT) AS NUMERIC(18,2)),
    TRY_CAST(TRY_CAST(NULLIF(TRIM([2023]), '') AS FLOAT) AS NUMERIC(18,2)),
    TRY_CAST(TRY_CAST(NULLIF(TRIM([2024]), '') AS FLOAT) AS NUMERIC(18,2))

FROM raw_transport.raw_2024_ts2_1_service_data_and_operating_expenses_time_series_by_mode_fares;

INSERT INTO stg_transport.stg_ts21_opexp_total (
    last_report_year,
    ntd_id,
    agency_name,
    agency_status,
    reporter_type,
    reporting_module,
    city,
    state,
    census_year,
    primary_uza_name,
    uace_code,
    uza_area_sq_miles,
    uza_population,
    mode_status,
    mode,
    type_of_service,
    y2015,
    y2016,
    y2017,
    y2018,
    y2019,
    y2020,
    y2021,
    y2022,
    y2023,
    y2024
)
SELECT
    TRY_CAST(NULLIF(TRIM([Last Report Year]), '') AS INT),

    LEFT(NULLIF(TRIM([NTD ID]), ''), 50),

    LEFT(NULLIF(TRIM([Agency Name]), ''), 255),
    LEFT(NULLIF(TRIM([Agency Status]), ''), 50),
    LEFT(NULLIF(TRIM([Reporter Type]), ''), 100),
    LEFT(NULLIF(TRIM([Reporting Module]), ''), 50),

    LEFT(NULLIF(TRIM([City]), ''), 100),
    LEFT(NULLIF(TRIM([State]), ''), 20),

    LEFT(NULLIF(TRIM([Census Year]), ''), 20),

    LEFT(NULLIF(TRIM([Primary UZA Name]), ''), 255),

    CAST(
        TRY_CAST(
            TRY_CAST(NULLIF(TRIM([UACE Code]), '') AS FLOAT)
        AS BIGINT)
    AS VARCHAR(50)),

    TRY_CAST(
        TRY_CAST(NULLIF(TRIM([UZA Area SQ Miles]), '') AS FLOAT)
    AS NUMERIC(18,2)),

    TRY_CAST(
        TRY_CAST(NULLIF(TRIM([UZA Population]), '') AS FLOAT)
    AS BIGINT),

    LEFT(NULLIF(TRIM([Mode_Status]), ''), 50),
    LEFT(NULLIF(TRIM([Mode]), ''), 20),
    LEFT(NULLIF(TRIM([Type of Service]), ''), 20),

    TRY_CAST(TRY_CAST(NULLIF(TRIM([2015]), '') AS FLOAT) AS NUMERIC(18,2)),
    TRY_CAST(TRY_CAST(NULLIF(TRIM([2016]), '') AS FLOAT) AS NUMERIC(18,2)),
    TRY_CAST(TRY_CAST(NULLIF(TRIM([2017]), '') AS FLOAT) AS NUMERIC(18,2)),
    TRY_CAST(TRY_CAST(NULLIF(TRIM([2018]), '') AS FLOAT) AS NUMERIC(18,2)),
    TRY_CAST(TRY_CAST(NULLIF(TRIM([2019]), '') AS FLOAT) AS NUMERIC(18,2)),
    TRY_CAST(TRY_CAST(NULLIF(TRIM([2020]), '') AS FLOAT) AS NUMERIC(18,2)),
    TRY_CAST(TRY_CAST(NULLIF(TRIM([2021]), '') AS FLOAT) AS NUMERIC(18,2)),
    TRY_CAST(TRY_CAST(NULLIF(TRIM([2022]), '') AS FLOAT) AS NUMERIC(18,2)),
    TRY_CAST(TRY_CAST(NULLIF(TRIM([2023]), '') AS FLOAT) AS NUMERIC(18,2)),
    TRY_CAST(TRY_CAST(NULLIF(TRIM([2024]), '') AS FLOAT) AS NUMERIC(18,2))

FROM raw_transport.raw_2024_ts2_1_service_data_and_operating_expenses_time_series_by_mode_opexp_total;

INSERT INTO stg_transport.stg_ts21_upt (
    last_report_year,
    ntd_id,
    agency_name,
    agency_status,
    reporter_type,
    reporting_module,
    city,
    state,
    census_year,
    primary_uza_name,
    uace_code,
    uza_area_sq_miles,
    uza_population,
    mode_status,
    mode,
    type_of_service,
    y2015,
    y2016,
    y2017,
    y2018,
    y2019,
    y2020,
    y2021,
    y2022,
    y2023,
    y2024
)
SELECT
    TRY_CAST(NULLIF(TRIM([Last Report Year]), '') AS INT),

    LEFT(NULLIF(TRIM([NTD ID]), ''), 50),

    LEFT(NULLIF(TRIM([Agency Name]), ''), 255),
    LEFT(NULLIF(TRIM([Agency Status]), ''), 50),
    LEFT(NULLIF(TRIM([Reporter Type]), ''), 100),
    LEFT(NULLIF(TRIM([Reporting Module]), ''), 50),

    LEFT(NULLIF(TRIM([City]), ''), 100),
    LEFT(NULLIF(TRIM([State]), ''), 20),

    LEFT(NULLIF(TRIM([Census Year]), ''), 20),

    LEFT(NULLIF(TRIM([Primary UZA Name]), ''), 255),

    CAST(
        TRY_CAST(
            TRY_CAST(NULLIF(TRIM([UACE Code]), '') AS FLOAT)
        AS BIGINT)
    AS VARCHAR(50)),

    TRY_CAST(
        TRY_CAST(NULLIF(TRIM([UZA Area SQ Miles]), '') AS FLOAT)
    AS NUMERIC(18,2)),

    TRY_CAST(
        TRY_CAST(NULLIF(TRIM([UZA Population]), '') AS FLOAT)
    AS BIGINT),

    LEFT(NULLIF(TRIM([Mode_Status]), ''), 50),
    LEFT(NULLIF(TRIM([Mode]), ''), 20),
    LEFT(NULLIF(TRIM([Type of Service]), ''), 20),

    TRY_CAST(TRY_CAST(NULLIF(TRIM([2015]), '') AS FLOAT) AS NUMERIC(18,2)),
    TRY_CAST(TRY_CAST(NULLIF(TRIM([2016]), '') AS FLOAT) AS NUMERIC(18,2)),
    TRY_CAST(TRY_CAST(NULLIF(TRIM([2017]), '') AS FLOAT) AS NUMERIC(18,2)),
    TRY_CAST(TRY_CAST(NULLIF(TRIM([2018]), '') AS FLOAT) AS NUMERIC(18,2)),
    TRY_CAST(TRY_CAST(NULLIF(TRIM([2019]), '') AS FLOAT) AS NUMERIC(18,2)),
    TRY_CAST(TRY_CAST(NULLIF(TRIM([2020]), '') AS FLOAT) AS NUMERIC(18,2)),
    TRY_CAST(TRY_CAST(NULLIF(TRIM([2021]), '') AS FLOAT) AS NUMERIC(18,2)),
    TRY_CAST(TRY_CAST(NULLIF(TRIM([2022]), '') AS FLOAT) AS NUMERIC(18,2)),
    TRY_CAST(TRY_CAST(NULLIF(TRIM([2023]), '') AS FLOAT) AS NUMERIC(18,2)),
    TRY_CAST(TRY_CAST(NULLIF(TRIM([2024]), '') AS FLOAT) AS NUMERIC(18,2))

FROM raw_transport.raw_2024_ts2_1_service_data_and_operating_expenses_time_series_by_mode_upt;

INSERT INTO stg_transport.stg_ts21_pmt (
    last_report_year,
    ntd_id,
    agency_name,
    agency_status,
    reporter_type,
    reporting_module,
    city,
    state,
    census_year,
    primary_uza_name,
    uace_code,
    uza_area_sq_miles,
    uza_population,
    mode_status,
    mode,
    type_of_service,
    y2015,
    y2016,
    y2017,
    y2018,
    y2019,
    y2020,
    y2021,
    y2022,
    y2023,
    y2024
)
SELECT
    TRY_CAST(NULLIF(TRIM([Last Report Year]), '') AS INT),

    LEFT(NULLIF(TRIM([NTD ID]), ''), 50),

    LEFT(NULLIF(TRIM([Agency Name]), ''), 255),
    LEFT(NULLIF(TRIM([Agency Status]), ''), 50),
    LEFT(NULLIF(TRIM([Reporter Type]), ''), 100),
    LEFT(NULLIF(TRIM([Reporting Module]), ''), 50),

    LEFT(NULLIF(TRIM([City]), ''), 100),
    LEFT(NULLIF(TRIM([State]), ''), 20),

    LEFT(NULLIF(TRIM([Census Year]), ''), 20),

    LEFT(NULLIF(TRIM([Primary UZA Name]), ''), 255),

    CAST(
        TRY_CAST(
            TRY_CAST(NULLIF(TRIM([UACE Code]), '') AS FLOAT)
        AS BIGINT)
    AS VARCHAR(50)),

    TRY_CAST(
        TRY_CAST(NULLIF(TRIM([UZA Area SQ Miles]), '') AS FLOAT)
    AS NUMERIC(18,2)),

    TRY_CAST(
        TRY_CAST(NULLIF(TRIM([UZA Population]), '') AS FLOAT)
    AS BIGINT),

    LEFT(NULLIF(TRIM([Mode_Status]), ''), 50),
    LEFT(NULLIF(TRIM([Mode]), ''), 20),
    LEFT(NULLIF(TRIM([Type of Service]), ''), 20),

    TRY_CAST(TRY_CAST(NULLIF(TRIM([2015]), '') AS FLOAT) AS NUMERIC(18,2)),
    TRY_CAST(TRY_CAST(NULLIF(TRIM([2016]), '') AS FLOAT) AS NUMERIC(18,2)),
    TRY_CAST(TRY_CAST(NULLIF(TRIM([2017]), '') AS FLOAT) AS NUMERIC(18,2)),
    TRY_CAST(TRY_CAST(NULLIF(TRIM([2018]), '') AS FLOAT) AS NUMERIC(18,2)),
    TRY_CAST(TRY_CAST(NULLIF(TRIM([2019]), '') AS FLOAT) AS NUMERIC(18,2)),
    TRY_CAST(TRY_CAST(NULLIF(TRIM([2020]), '') AS FLOAT) AS NUMERIC(18,2)),
    TRY_CAST(TRY_CAST(NULLIF(TRIM([2021]), '') AS FLOAT) AS NUMERIC(18,2)),
    TRY_CAST(TRY_CAST(NULLIF(TRIM([2022]), '') AS FLOAT) AS NUMERIC(18,2)),
    TRY_CAST(TRY_CAST(NULLIF(TRIM([2023]), '') AS FLOAT) AS NUMERIC(18,2)),
    TRY_CAST(TRY_CAST(NULLIF(TRIM([2024]), '') AS FLOAT) AS NUMERIC(18,2))

FROM raw_transport.raw_2024_ts2_1_service_data_and_operating_expenses_time_series_by_mode_pmt;

INSERT INTO stg_transport.stg_ts21_vrm(
    last_report_year,
    ntd_id,
    agency_name,
    agency_status,
    reporter_type,
    reporting_module,
    city,
    state,
    census_year,
    primary_uza_name,
    uace_code,
    uza_area_sq_miles,
    uza_population,
    mode_status,
    mode,
    type_of_service,
    y2015,
    y2016,
    y2017,
    y2018,
    y2019,
    y2020,
    y2021,
    y2022,
    y2023,
    y2024
)
SELECT
    TRY_CAST(NULLIF(TRIM([Last Report Year]), '') AS INT),

    LEFT(NULLIF(TRIM([NTD ID]), ''), 50),

    LEFT(NULLIF(TRIM([Agency Name]), ''), 255),
    LEFT(NULLIF(TRIM([Agency Status]), ''), 50),
    LEFT(NULLIF(TRIM([Reporter Type]), ''), 100),
    LEFT(NULLIF(TRIM([Reporting Module]), ''), 50),

    LEFT(NULLIF(TRIM([City]), ''), 100),
    LEFT(NULLIF(TRIM([State]), ''), 20),

    LEFT(NULLIF(TRIM([Census Year]), ''), 20),

    LEFT(NULLIF(TRIM([Primary UZA Name]), ''), 255),

    CAST(
        TRY_CAST(
            TRY_CAST(NULLIF(TRIM([UACE Code]), '') AS FLOAT)
        AS BIGINT)
    AS VARCHAR(50)),

    TRY_CAST(
        TRY_CAST(NULLIF(TRIM([UZA Area SQ Miles]), '') AS FLOAT)
    AS NUMERIC(18,2)),

    TRY_CAST(
        TRY_CAST(NULLIF(TRIM([UZA Population]), '') AS FLOAT)
    AS BIGINT),

    LEFT(NULLIF(TRIM([Mode_Status]), ''), 50),
    LEFT(NULLIF(TRIM([Mode]), ''), 20),
    LEFT(NULLIF(TRIM([Type of Service]), ''), 20),

    TRY_CAST(TRY_CAST(NULLIF(TRIM([2015]), '') AS FLOAT) AS NUMERIC(18,2)),
    TRY_CAST(TRY_CAST(NULLIF(TRIM([2016]), '') AS FLOAT) AS NUMERIC(18,2)),
    TRY_CAST(TRY_CAST(NULLIF(TRIM([2017]), '') AS FLOAT) AS NUMERIC(18,2)),
    TRY_CAST(TRY_CAST(NULLIF(TRIM([2018]), '') AS FLOAT) AS NUMERIC(18,2)),
    TRY_CAST(TRY_CAST(NULLIF(TRIM([2019]), '') AS FLOAT) AS NUMERIC(18,2)),
    TRY_CAST(TRY_CAST(NULLIF(TRIM([2020]), '') AS FLOAT) AS NUMERIC(18,2)),
    TRY_CAST(TRY_CAST(NULLIF(TRIM([2021]), '') AS FLOAT) AS NUMERIC(18,2)),
    TRY_CAST(TRY_CAST(NULLIF(TRIM([2022]), '') AS FLOAT) AS NUMERIC(18,2)),
    TRY_CAST(TRY_CAST(NULLIF(TRIM([2023]), '') AS FLOAT) AS NUMERIC(18,2)),
    TRY_CAST(TRY_CAST(NULLIF(TRIM([2024]), '') AS FLOAT) AS NUMERIC(18,2))

FROM raw_transport.raw_2024_ts2_1_service_data_and_operating_expenses_time_series_by_mode_vrm;

INSERT INTO stg_transport.stg_ts21_vrh (
    last_report_year,
    ntd_id,
    agency_name,
    agency_status,
    reporter_type,
    reporting_module,
    city,
    state,
    census_year,
    primary_uza_name,
    uace_code,
    uza_area_sq_miles,
    uza_population,
    mode_status,
    mode,
    type_of_service,
    y2015,
    y2016,
    y2017,
    y2018,
    y2019,
    y2020,
    y2021,
    y2022,
    y2023,
    y2024
)
SELECT
    TRY_CAST(NULLIF(TRIM([Last Report Year]), '') AS INT),

    LEFT(NULLIF(TRIM([NTD ID]), ''), 50),

    LEFT(NULLIF(TRIM([Agency Name]), ''), 255),
    LEFT(NULLIF(TRIM([Agency Status]), ''), 50),
    LEFT(NULLIF(TRIM([Reporter Type]), ''), 100),
    LEFT(NULLIF(TRIM([Reporting Module]), ''), 50),

    LEFT(NULLIF(TRIM([City]), ''), 100),
    LEFT(NULLIF(TRIM([State]), ''), 20),

    LEFT(NULLIF(TRIM([Census Year]), ''), 20),

    LEFT(NULLIF(TRIM([Primary UZA Name]), ''), 255),

    CAST(
        TRY_CAST(
            TRY_CAST(NULLIF(TRIM([UACE Code]), '') AS FLOAT)
        AS BIGINT)
    AS VARCHAR(50)),

    TRY_CAST(
        TRY_CAST(NULLIF(TRIM([UZA Area SQ Miles]), '') AS FLOAT)
    AS NUMERIC(18,2)),

    TRY_CAST(
        TRY_CAST(NULLIF(TRIM([UZA Population]), '') AS FLOAT)
    AS BIGINT),

    LEFT(NULLIF(TRIM([Mode_Status]), ''), 50),
    LEFT(NULLIF(TRIM([Mode]), ''), 20),
    LEFT(NULLIF(TRIM([Type of Service]), ''), 20),

    TRY_CAST(TRY_CAST(NULLIF(TRIM([2015]), '') AS FLOAT) AS NUMERIC(18,2)),
    TRY_CAST(TRY_CAST(NULLIF(TRIM([2016]), '') AS FLOAT) AS NUMERIC(18,2)),
    TRY_CAST(TRY_CAST(NULLIF(TRIM([2017]), '') AS FLOAT) AS NUMERIC(18,2)),
    TRY_CAST(TRY_CAST(NULLIF(TRIM([2018]), '') AS FLOAT) AS NUMERIC(18,2)),
    TRY_CAST(TRY_CAST(NULLIF(TRIM([2019]), '') AS FLOAT) AS NUMERIC(18,2)),
    TRY_CAST(TRY_CAST(NULLIF(TRIM([2020]), '') AS FLOAT) AS NUMERIC(18,2)),
    TRY_CAST(TRY_CAST(NULLIF(TRIM([2021]), '') AS FLOAT) AS NUMERIC(18,2)),
    TRY_CAST(TRY_CAST(NULLIF(TRIM([2022]), '') AS FLOAT) AS NUMERIC(18,2)),
    TRY_CAST(TRY_CAST(NULLIF(TRIM([2023]), '') AS FLOAT) AS NUMERIC(18,2)),
    TRY_CAST(TRY_CAST(NULLIF(TRIM([2024]), '') AS FLOAT) AS NUMERIC(18,2))

FROM raw_transport.raw_2024_ts2_1_service_data_and_operating_expenses_time_series_by_mode_vrh;

INSERT INTO stg_transport.stg_ts21_voms (
    last_report_year,
    ntd_id,
    agency_name,
    agency_status,
    reporter_type,
    reporting_module,
    city,
    state,
    census_year,
    primary_uza_name,
    uace_code,
    uza_area_sq_miles,
    uza_population,
    mode_status,
    mode,
    type_of_service,
    y2015,
    y2016,
    y2017,
    y2018,
    y2019,
    y2020,
    y2021,
    y2022,
    y2023,
    y2024
)
SELECT
    TRY_CAST(NULLIF(TRIM([Last Report Year]), '') AS INT),

    LEFT(NULLIF(TRIM([NTD ID]), ''), 50),

    LEFT(NULLIF(TRIM([Agency Name]), ''), 255),
    LEFT(NULLIF(TRIM([Agency Status]), ''), 50),
    LEFT(NULLIF(TRIM([Reporter Type]), ''), 100),
    LEFT(NULLIF(TRIM([Reporting Module]), ''), 50),

    LEFT(NULLIF(TRIM([City]), ''), 100),
    LEFT(NULLIF(TRIM([State]), ''), 20),

    LEFT(NULLIF(TRIM([Census Year]), ''), 20),

    LEFT(NULLIF(TRIM([Primary UZA Name]), ''), 255),

    CAST(
        TRY_CAST(
            TRY_CAST(NULLIF(TRIM([UACE Code]), '') AS FLOAT)
        AS BIGINT)
    AS VARCHAR(50)),

    TRY_CAST(
        TRY_CAST(NULLIF(TRIM([UZA Area SQ Miles]), '') AS FLOAT)
    AS NUMERIC(18,2)),

    TRY_CAST(
        TRY_CAST(NULLIF(TRIM([UZA Population]), '') AS FLOAT)
    AS BIGINT),

    LEFT(NULLIF(TRIM([Mode_Status]), ''), 50),
    LEFT(NULLIF(TRIM([Mode]), ''), 20),
    LEFT(NULLIF(TRIM([Type of Service]), ''), 20),

    TRY_CAST(TRY_CAST(NULLIF(TRIM([2015]), '') AS FLOAT) AS NUMERIC(18,2)),
    TRY_CAST(TRY_CAST(NULLIF(TRIM([2016]), '') AS FLOAT) AS NUMERIC(18,2)),
    TRY_CAST(TRY_CAST(NULLIF(TRIM([2017]), '') AS FLOAT) AS NUMERIC(18,2)),
    TRY_CAST(TRY_CAST(NULLIF(TRIM([2018]), '') AS FLOAT) AS NUMERIC(18,2)),
    TRY_CAST(TRY_CAST(NULLIF(TRIM([2019]), '') AS FLOAT) AS NUMERIC(18,2)),
    TRY_CAST(TRY_CAST(NULLIF(TRIM([2020]), '') AS FLOAT) AS NUMERIC(18,2)),
    TRY_CAST(TRY_CAST(NULLIF(TRIM([2021]), '') AS FLOAT) AS NUMERIC(18,2)),
    TRY_CAST(TRY_CAST(NULLIF(TRIM([2022]), '') AS FLOAT) AS NUMERIC(18,2)),
    TRY_CAST(TRY_CAST(NULLIF(TRIM([2023]), '') AS FLOAT) AS NUMERIC(18,2)),
    TRY_CAST(TRY_CAST(NULLIF(TRIM([2024]), '') AS FLOAT) AS NUMERIC(18,2))

FROM raw_transport.raw_2024_ts2_1_service_data_and_operating_expenses_time_series_by_mode_voms;

INSERT INTO stg_transport.stg_ts21_archive_drm (
    ntd_id,
    legacy_ntd_id,
    agency_name,
    reporter_type,
    reporting_module,
    city,
    state,
    census_year,
    primary_uza_name,
    uace_code,
    uza_area_sq_miles,
    uza_population,
    mode,
    service,
    mode_status,
    y1991,y1992,y1993,y1994,y1995,
    y1996,y1997,y1998,y1999,y2000,
    y2001,y2002,y2003,y2004,y2005,
    y2006,y2007,y2008,y2009,y2010,
    y2011,y2012,y2013,y2014
)
SELECT
    CAST(
        TRY_CAST(
            TRY_CAST(NULLIF(TRIM([NTD ID]), '') AS FLOAT)
        AS BIGINT)
    AS VARCHAR(50)),

    LEFT(NULLIF(TRIM([Legacy NTD ID]), ''), 50),

    LEFT(NULLIF(TRIM([Agency Name]), ''), 255),

    LEFT(NULLIF(TRIM([Reporter Type]), ''), 100),
    LEFT(NULLIF(TRIM([Reporting Module]), ''), 50),

    LEFT(NULLIF(TRIM([City]), ''), 100),
    LEFT(NULLIF(TRIM([State]), ''), 20),

    TRY_CAST(NULLIF(TRIM([Census Year]), '') AS INT),

    LEFT(NULLIF(TRIM([Primary UZA Name]), ''), 255),

    CAST(
        TRY_CAST(
            TRY_CAST(NULLIF(TRIM([UACE Code]), '') AS FLOAT)
        AS BIGINT)
    AS VARCHAR(50)),

    TRY_CAST(
        TRY_CAST(NULLIF(TRIM([UZA Area SQ Miles]), '') AS FLOAT)
    AS NUMERIC(18,2)),

    TRY_CAST(
        TRY_CAST(NULLIF(TRIM([UZA Population]), '') AS FLOAT)
    AS BIGINT),

    LEFT(NULLIF(TRIM([Mode]), ''), 20),
    LEFT(NULLIF(TRIM([Service]), ''), 20),
    LEFT(NULLIF(TRIM([Mode Status]), ''), 50),

    TRY_CAST(TRY_CAST(NULLIF(TRIM([1991]), '') AS FLOAT) AS NUMERIC(18,2)),
    TRY_CAST(TRY_CAST(NULLIF(TRIM([1992]), '') AS FLOAT) AS NUMERIC(18,2)),
    TRY_CAST(TRY_CAST(NULLIF(TRIM([1993]), '') AS FLOAT) AS NUMERIC(18,2)),
    TRY_CAST(TRY_CAST(NULLIF(TRIM([1994]), '') AS FLOAT) AS NUMERIC(18,2)),
    TRY_CAST(TRY_CAST(NULLIF(TRIM([1995]), '') AS FLOAT) AS NUMERIC(18,2)),
    TRY_CAST(TRY_CAST(NULLIF(TRIM([1996]), '') AS FLOAT) AS NUMERIC(18,2)),
    TRY_CAST(TRY_CAST(NULLIF(TRIM([1997]), '') AS FLOAT) AS NUMERIC(18,2)),
    TRY_CAST(TRY_CAST(NULLIF(TRIM([1998]), '') AS FLOAT) AS NUMERIC(18,2)),
    TRY_CAST(TRY_CAST(NULLIF(TRIM([1999]), '') AS FLOAT) AS NUMERIC(18,2)),
    TRY_CAST(TRY_CAST(NULLIF(TRIM([2000]), '') AS FLOAT) AS NUMERIC(18,2)),
    TRY_CAST(TRY_CAST(NULLIF(TRIM([2001]), '') AS FLOAT) AS NUMERIC(18,2)),
    TRY_CAST(TRY_CAST(NULLIF(TRIM([2002]), '') AS FLOAT) AS NUMERIC(18,2)),
    TRY_CAST(TRY_CAST(NULLIF(TRIM([2003]), '') AS FLOAT) AS NUMERIC(18,2)),
    TRY_CAST(TRY_CAST(NULLIF(TRIM([2004]), '') AS FLOAT) AS NUMERIC(18,2)),
    TRY_CAST(TRY_CAST(NULLIF(TRIM([2005]), '') AS FLOAT) AS NUMERIC(18,2)),
    TRY_CAST(TRY_CAST(NULLIF(TRIM([2006]), '') AS FLOAT) AS NUMERIC(18,2)),
    TRY_CAST(TRY_CAST(NULLIF(TRIM([2007]), '') AS FLOAT) AS NUMERIC(18,2)),
    TRY_CAST(TRY_CAST(NULLIF(TRIM([2008]), '') AS FLOAT) AS NUMERIC(18,2)),
    TRY_CAST(TRY_CAST(NULLIF(TRIM([2009]), '') AS FLOAT) AS NUMERIC(18,2)),
    TRY_CAST(TRY_CAST(NULLIF(TRIM([2010]), '') AS FLOAT) AS NUMERIC(18,2)),
    TRY_CAST(TRY_CAST(NULLIF(TRIM([2011]), '') AS FLOAT) AS NUMERIC(18,2)),
    TRY_CAST(TRY_CAST(NULLIF(TRIM([2012]), '') AS FLOAT) AS NUMERIC(18,2)),
    TRY_CAST(TRY_CAST(NULLIF(TRIM([2013]), '') AS FLOAT) AS NUMERIC(18,2)),
    TRY_CAST(TRY_CAST(NULLIF(TRIM([2014]), '') AS FLOAT) AS NUMERIC(18,2))

FROM raw_transport.raw_archive_1991_2014_ts2_1_service_data_and_operating_expenses_time_series_by_mode_drm;

INSERT INTO stg_transport.stg_ts21_archive_upt (
    ntd_id,
    legacy_ntd_id,
    agency_name,
    reporter_type,
    reporting_module,
    city,
    state,
    census_year,
    primary_uza_name,
    uace_code,
    uza_area_sq_miles,
    uza_population,
    mode,
    service,
    mode_status,
    y1991,y1992,y1993,y1994,y1995,
    y1996,y1997,y1998,y1999,y2000,
    y2001,y2002,y2003,y2004,y2005,
    y2006,y2007,y2008,y2009,y2010,
    y2011,y2012,y2013,y2014
)
SELECT
    CAST(
        TRY_CAST(
            TRY_CAST(NULLIF(TRIM([NTD ID]), '') AS FLOAT)
        AS BIGINT)
    AS VARCHAR(50)),

    LEFT(NULLIF(TRIM([Legacy NTD ID]), ''), 50),

    LEFT(NULLIF(TRIM([Agency Name]), ''), 255),

    LEFT(NULLIF(TRIM([Reporter Type]), ''), 100),
    LEFT(NULLIF(TRIM([Reporting Module]), ''), 50),

    LEFT(NULLIF(TRIM([City]), ''), 100),
    LEFT(NULLIF(TRIM([State]), ''), 20),

    TRY_CAST(NULLIF(TRIM([Census Year]), '') AS INT),

    LEFT(NULLIF(TRIM([Primary UZA Name]), ''), 255),

    CAST(
        TRY_CAST(
            TRY_CAST(NULLIF(TRIM([UACE Code]), '') AS FLOAT)
        AS BIGINT)
    AS VARCHAR(50)),

    TRY_CAST(
        TRY_CAST(NULLIF(TRIM([UZA Area SQ Miles]), '') AS FLOAT)
    AS NUMERIC(18,2)),

    TRY_CAST(
        TRY_CAST(NULLIF(TRIM([UZA Population]), '') AS FLOAT)
    AS BIGINT),

    LEFT(NULLIF(TRIM([Mode]), ''), 20),
    LEFT(NULLIF(TRIM([Service]), ''), 20),
    LEFT(NULLIF(TRIM([Mode Status]), ''), 50),

    TRY_CAST(TRY_CAST(NULLIF(TRIM([1991]), '') AS FLOAT) AS NUMERIC(18,2)),
    TRY_CAST(TRY_CAST(NULLIF(TRIM([1992]), '') AS FLOAT) AS NUMERIC(18,2)),
    TRY_CAST(TRY_CAST(NULLIF(TRIM([1993]), '') AS FLOAT) AS NUMERIC(18,2)),
    TRY_CAST(TRY_CAST(NULLIF(TRIM([1994]), '') AS FLOAT) AS NUMERIC(18,2)),
    TRY_CAST(TRY_CAST(NULLIF(TRIM([1995]), '') AS FLOAT) AS NUMERIC(18,2)),
    TRY_CAST(TRY_CAST(NULLIF(TRIM([1996]), '') AS FLOAT) AS NUMERIC(18,2)),
    TRY_CAST(TRY_CAST(NULLIF(TRIM([1997]), '') AS FLOAT) AS NUMERIC(18,2)),
    TRY_CAST(TRY_CAST(NULLIF(TRIM([1998]), '') AS FLOAT) AS NUMERIC(18,2)),
    TRY_CAST(TRY_CAST(NULLIF(TRIM([1999]), '') AS FLOAT) AS NUMERIC(18,2)),
    TRY_CAST(TRY_CAST(NULLIF(TRIM([2000]), '') AS FLOAT) AS NUMERIC(18,2)),
    TRY_CAST(TRY_CAST(NULLIF(TRIM([2001]), '') AS FLOAT) AS NUMERIC(18,2)),
    TRY_CAST(TRY_CAST(NULLIF(TRIM([2002]), '') AS FLOAT) AS NUMERIC(18,2)),
    TRY_CAST(TRY_CAST(NULLIF(TRIM([2003]), '') AS FLOAT) AS NUMERIC(18,2)),
    TRY_CAST(TRY_CAST(NULLIF(TRIM([2004]), '') AS FLOAT) AS NUMERIC(18,2)),
    TRY_CAST(TRY_CAST(NULLIF(TRIM([2005]), '') AS FLOAT) AS NUMERIC(18,2)),
    TRY_CAST(TRY_CAST(NULLIF(TRIM([2006]), '') AS FLOAT) AS NUMERIC(18,2)),
    TRY_CAST(TRY_CAST(NULLIF(TRIM([2007]), '') AS FLOAT) AS NUMERIC(18,2)),
    TRY_CAST(TRY_CAST(NULLIF(TRIM([2008]), '') AS FLOAT) AS NUMERIC(18,2)),
    TRY_CAST(TRY_CAST(NULLIF(TRIM([2009]), '') AS FLOAT) AS NUMERIC(18,2)),
    TRY_CAST(TRY_CAST(NULLIF(TRIM([2010]), '') AS FLOAT) AS NUMERIC(18,2)),
    TRY_CAST(TRY_CAST(NULLIF(TRIM([2011]), '') AS FLOAT) AS NUMERIC(18,2)),
    TRY_CAST(TRY_CAST(NULLIF(TRIM([2012]), '') AS FLOAT) AS NUMERIC(18,2)),
    TRY_CAST(TRY_CAST(NULLIF(TRIM([2013]), '') AS FLOAT) AS NUMERIC(18,2)),
    TRY_CAST(TRY_CAST(NULLIF(TRIM([2014]), '') AS FLOAT) AS NUMERIC(18,2))

FROM raw_transport.raw_archive_1991_2014_ts2_1_service_data_and_operating_expenses_time_series_by_mode_upt;

INSERT INTO stg_transport.stg_ts21_archive_pmt (
    ntd_id,
    legacy_ntd_id,
    agency_name,
    reporter_type,
    reporting_module,
    city,
    state,
    census_year,
    primary_uza_name,
    uace_code,
    uza_area_sq_miles,
    uza_population,
    mode,
    service,
    mode_status,
    y1991,y1992,y1993,y1994,y1995,
    y1996,y1997,y1998,y1999,y2000,
    y2001,y2002,y2003,y2004,y2005,
    y2006,y2007,y2008,y2009,y2010,
    y2011,y2012,y2013,y2014
)
SELECT
    CAST(
        TRY_CAST(
            TRY_CAST(NULLIF(TRIM([NTD ID]), '') AS FLOAT)
        AS BIGINT)
    AS VARCHAR(50)),

    LEFT(NULLIF(TRIM([Legacy NTD ID]), ''), 50),

    LEFT(NULLIF(TRIM([Agency Name]), ''), 255),

    LEFT(NULLIF(TRIM([Reporter Type]), ''), 100),
    LEFT(NULLIF(TRIM([Reporting Module]), ''), 50),

    LEFT(NULLIF(TRIM([City]), ''), 100),
    LEFT(NULLIF(TRIM([State]), ''), 20),

    TRY_CAST(NULLIF(TRIM([Census Year]), '') AS INT),

    LEFT(NULLIF(TRIM([Primary UZA Name]), ''), 255),

    CAST(
        TRY_CAST(
            TRY_CAST(NULLIF(TRIM([UACE Code]), '') AS FLOAT)
        AS BIGINT)
    AS VARCHAR(50)),

    TRY_CAST(
        TRY_CAST(NULLIF(TRIM([UZA Area SQ Miles]), '') AS FLOAT)
    AS NUMERIC(18,2)),

    TRY_CAST(
        TRY_CAST(NULLIF(TRIM([UZA Population]), '') AS FLOAT)
    AS BIGINT),

    LEFT(NULLIF(TRIM([Mode]), ''), 20),
    LEFT(NULLIF(TRIM([Service]), ''), 20),
    LEFT(NULLIF(TRIM([Mode Status]), ''), 50),

    TRY_CAST(TRY_CAST(NULLIF(TRIM([1991]), '') AS FLOAT) AS NUMERIC(18,2)),
    TRY_CAST(TRY_CAST(NULLIF(TRIM([1992]), '') AS FLOAT) AS NUMERIC(18,2)),
    TRY_CAST(TRY_CAST(NULLIF(TRIM([1993]), '') AS FLOAT) AS NUMERIC(18,2)),
    TRY_CAST(TRY_CAST(NULLIF(TRIM([1994]), '') AS FLOAT) AS NUMERIC(18,2)),
    TRY_CAST(TRY_CAST(NULLIF(TRIM([1995]), '') AS FLOAT) AS NUMERIC(18,2)),
    TRY_CAST(TRY_CAST(NULLIF(TRIM([1996]), '') AS FLOAT) AS NUMERIC(18,2)),
    TRY_CAST(TRY_CAST(NULLIF(TRIM([1997]), '') AS FLOAT) AS NUMERIC(18,2)),
    TRY_CAST(TRY_CAST(NULLIF(TRIM([1998]), '') AS FLOAT) AS NUMERIC(18,2)),
    TRY_CAST(TRY_CAST(NULLIF(TRIM([1999]), '') AS FLOAT) AS NUMERIC(18,2)),
    TRY_CAST(TRY_CAST(NULLIF(TRIM([2000]), '') AS FLOAT) AS NUMERIC(18,2)),
    TRY_CAST(TRY_CAST(NULLIF(TRIM([2001]), '') AS FLOAT) AS NUMERIC(18,2)),
    TRY_CAST(TRY_CAST(NULLIF(TRIM([2002]), '') AS FLOAT) AS NUMERIC(18,2)),
    TRY_CAST(TRY_CAST(NULLIF(TRIM([2003]), '') AS FLOAT) AS NUMERIC(18,2)),
    TRY_CAST(TRY_CAST(NULLIF(TRIM([2004]), '') AS FLOAT) AS NUMERIC(18,2)),
    TRY_CAST(TRY_CAST(NULLIF(TRIM([2005]), '') AS FLOAT) AS NUMERIC(18,2)),
    TRY_CAST(TRY_CAST(NULLIF(TRIM([2006]), '') AS FLOAT) AS NUMERIC(18,2)),
    TRY_CAST(TRY_CAST(NULLIF(TRIM([2007]), '') AS FLOAT) AS NUMERIC(18,2)),
    TRY_CAST(TRY_CAST(NULLIF(TRIM([2008]), '') AS FLOAT) AS NUMERIC(18,2)),
    TRY_CAST(TRY_CAST(NULLIF(TRIM([2009]), '') AS FLOAT) AS NUMERIC(18,2)),
    TRY_CAST(TRY_CAST(NULLIF(TRIM([2010]), '') AS FLOAT) AS NUMERIC(18,2)),
    TRY_CAST(TRY_CAST(NULLIF(TRIM([2011]), '') AS FLOAT) AS NUMERIC(18,2)),
    TRY_CAST(TRY_CAST(NULLIF(TRIM([2012]), '') AS FLOAT) AS NUMERIC(18,2)),
    TRY_CAST(TRY_CAST(NULLIF(TRIM([2013]), '') AS FLOAT) AS NUMERIC(18,2)),
    TRY_CAST(TRY_CAST(NULLIF(TRIM([2014]), '') AS FLOAT) AS NUMERIC(18,2))

FROM raw_transport.raw_archive_1991_2014_ts2_1_service_data_and_operating_expenses_time_series_by_mode_pmt;

INSERT INTO stg_transport.stg_ts21_archive_vrm (
    ntd_id,
    legacy_ntd_id,
    agency_name,
    reporter_type,
    reporting_module,
    city,
    state,
    census_year,
    primary_uza_name,
    uace_code,
    uza_area_sq_miles,
    uza_population,
    mode,
    service,
    mode_status,
    y1991,y1992,y1993,y1994,y1995,
    y1996,y1997,y1998,y1999,y2000,
    y2001,y2002,y2003,y2004,y2005,
    y2006,y2007,y2008,y2009,y2010,
    y2011,y2012,y2013,y2014
)
SELECT
    CAST(
        TRY_CAST(
            TRY_CAST(NULLIF(TRIM([NTD ID]), '') AS FLOAT)
        AS BIGINT)
    AS VARCHAR(50)),

    LEFT(NULLIF(TRIM([Legacy NTD ID]), ''), 50),

    LEFT(NULLIF(TRIM([Agency Name]), ''), 255),

    LEFT(NULLIF(TRIM([Reporter Type]), ''), 100),
    LEFT(NULLIF(TRIM([Reporting Module]), ''), 50),

    LEFT(NULLIF(TRIM([City]), ''), 100),
    LEFT(NULLIF(TRIM([State]), ''), 20),

    TRY_CAST(NULLIF(TRIM([Census Year]), '') AS INT),

    LEFT(NULLIF(TRIM([Primary UZA Name]), ''), 255),

    CAST(
        TRY_CAST(
            TRY_CAST(NULLIF(TRIM([UACE Code]), '') AS FLOAT)
        AS BIGINT)
    AS VARCHAR(50)),

    TRY_CAST(
        TRY_CAST(NULLIF(TRIM([UZA Area SQ Miles]), '') AS FLOAT)
    AS NUMERIC(18,2)),

    TRY_CAST(
        TRY_CAST(NULLIF(TRIM([UZA Population]), '') AS FLOAT)
    AS BIGINT),

    LEFT(NULLIF(TRIM([Mode]), ''), 20),
    LEFT(NULLIF(TRIM([Service]), ''), 20),
    LEFT(NULLIF(TRIM([Mode Status]), ''), 50),

    TRY_CAST(TRY_CAST(NULLIF(TRIM([1991]), '') AS FLOAT) AS NUMERIC(18,2)),
    TRY_CAST(TRY_CAST(NULLIF(TRIM([1992]), '') AS FLOAT) AS NUMERIC(18,2)),
    TRY_CAST(TRY_CAST(NULLIF(TRIM([1993]), '') AS FLOAT) AS NUMERIC(18,2)),
    TRY_CAST(TRY_CAST(NULLIF(TRIM([1994]), '') AS FLOAT) AS NUMERIC(18,2)),
    TRY_CAST(TRY_CAST(NULLIF(TRIM([1995]), '') AS FLOAT) AS NUMERIC(18,2)),
    TRY_CAST(TRY_CAST(NULLIF(TRIM([1996]), '') AS FLOAT) AS NUMERIC(18,2)),
    TRY_CAST(TRY_CAST(NULLIF(TRIM([1997]), '') AS FLOAT) AS NUMERIC(18,2)),
    TRY_CAST(TRY_CAST(NULLIF(TRIM([1998]), '') AS FLOAT) AS NUMERIC(18,2)),
    TRY_CAST(TRY_CAST(NULLIF(TRIM([1999]), '') AS FLOAT) AS NUMERIC(18,2)),
    TRY_CAST(TRY_CAST(NULLIF(TRIM([2000]), '') AS FLOAT) AS NUMERIC(18,2)),
    TRY_CAST(TRY_CAST(NULLIF(TRIM([2001]), '') AS FLOAT) AS NUMERIC(18,2)),
    TRY_CAST(TRY_CAST(NULLIF(TRIM([2002]), '') AS FLOAT) AS NUMERIC(18,2)),
    TRY_CAST(TRY_CAST(NULLIF(TRIM([2003]), '') AS FLOAT) AS NUMERIC(18,2)),
    TRY_CAST(TRY_CAST(NULLIF(TRIM([2004]), '') AS FLOAT) AS NUMERIC(18,2)),
    TRY_CAST(TRY_CAST(NULLIF(TRIM([2005]), '') AS FLOAT) AS NUMERIC(18,2)),
    TRY_CAST(TRY_CAST(NULLIF(TRIM([2006]), '') AS FLOAT) AS NUMERIC(18,2)),
    TRY_CAST(TRY_CAST(NULLIF(TRIM([2007]), '') AS FLOAT) AS NUMERIC(18,2)),
    TRY_CAST(TRY_CAST(NULLIF(TRIM([2008]), '') AS FLOAT) AS NUMERIC(18,2)),
    TRY_CAST(TRY_CAST(NULLIF(TRIM([2009]), '') AS FLOAT) AS NUMERIC(18,2)),
    TRY_CAST(TRY_CAST(NULLIF(TRIM([2010]), '') AS FLOAT) AS NUMERIC(18,2)),
    TRY_CAST(TRY_CAST(NULLIF(TRIM([2011]), '') AS FLOAT) AS NUMERIC(18,2)),
    TRY_CAST(TRY_CAST(NULLIF(TRIM([2012]), '') AS FLOAT) AS NUMERIC(18,2)),
    TRY_CAST(TRY_CAST(NULLIF(TRIM([2013]), '') AS FLOAT) AS NUMERIC(18,2)),
    TRY_CAST(TRY_CAST(NULLIF(TRIM([2014]), '') AS FLOAT) AS NUMERIC(18,2))

FROM raw_transport.raw_archive_1991_2014_ts2_1_service_data_and_operating_expenses_time_series_by_mode_vrm;

INSERT INTO stg_transport.stg_ts21_archive_vrh (
    ntd_id,
    legacy_ntd_id,
    agency_name,
    reporter_type,
    reporting_module,
    city,
    state,
    census_year,
    primary_uza_name,
    uace_code,
    uza_area_sq_miles,
    uza_population,
    mode,
    service,
    mode_status,
    y1991,y1992,y1993,y1994,y1995,
    y1996,y1997,y1998,y1999,y2000,
    y2001,y2002,y2003,y2004,y2005,
    y2006,y2007,y2008,y2009,y2010,
    y2011,y2012,y2013,y2014
)
SELECT
    CAST(
        TRY_CAST(
            TRY_CAST(NULLIF(TRIM([NTD ID]), '') AS FLOAT)
        AS BIGINT)
    AS VARCHAR(50)),

    LEFT(NULLIF(TRIM([Legacy NTD ID]), ''), 50),

    LEFT(NULLIF(TRIM([Agency Name]), ''), 255),

    LEFT(NULLIF(TRIM([Reporter Type]), ''), 100),
    LEFT(NULLIF(TRIM([Reporting Module]), ''), 50),

    LEFT(NULLIF(TRIM([City]), ''), 100),
    LEFT(NULLIF(TRIM([State]), ''), 20),

    TRY_CAST(NULLIF(TRIM([Census Year]), '') AS INT),

    LEFT(NULLIF(TRIM([Primary UZA Name]), ''), 255),

    CAST(
        TRY_CAST(
            TRY_CAST(NULLIF(TRIM([UACE Code]), '') AS FLOAT)
        AS BIGINT)
    AS VARCHAR(50)),

    TRY_CAST(
        TRY_CAST(NULLIF(TRIM([UZA Area SQ Miles]), '') AS FLOAT)
    AS NUMERIC(18,2)),

    TRY_CAST(
        TRY_CAST(NULLIF(TRIM([UZA Population]), '') AS FLOAT)
    AS BIGINT),

    LEFT(NULLIF(TRIM([Mode]), ''), 20),
    LEFT(NULLIF(TRIM([Service]), ''), 20),
    LEFT(NULLIF(TRIM([Mode Status]), ''), 50),

    TRY_CAST(TRY_CAST(NULLIF(TRIM([1991]), '') AS FLOAT) AS NUMERIC(18,2)),
    TRY_CAST(TRY_CAST(NULLIF(TRIM([1992]), '') AS FLOAT) AS NUMERIC(18,2)),
    TRY_CAST(TRY_CAST(NULLIF(TRIM([1993]), '') AS FLOAT) AS NUMERIC(18,2)),
    TRY_CAST(TRY_CAST(NULLIF(TRIM([1994]), '') AS FLOAT) AS NUMERIC(18,2)),
    TRY_CAST(TRY_CAST(NULLIF(TRIM([1995]), '') AS FLOAT) AS NUMERIC(18,2)),
    TRY_CAST(TRY_CAST(NULLIF(TRIM([1996]), '') AS FLOAT) AS NUMERIC(18,2)),
    TRY_CAST(TRY_CAST(NULLIF(TRIM([1997]), '') AS FLOAT) AS NUMERIC(18,2)),
    TRY_CAST(TRY_CAST(NULLIF(TRIM([1998]), '') AS FLOAT) AS NUMERIC(18,2)),
    TRY_CAST(TRY_CAST(NULLIF(TRIM([1999]), '') AS FLOAT) AS NUMERIC(18,2)),
    TRY_CAST(TRY_CAST(NULLIF(TRIM([2000]), '') AS FLOAT) AS NUMERIC(18,2)),
    TRY_CAST(TRY_CAST(NULLIF(TRIM([2001]), '') AS FLOAT) AS NUMERIC(18,2)),
    TRY_CAST(TRY_CAST(NULLIF(TRIM([2002]), '') AS FLOAT) AS NUMERIC(18,2)),
    TRY_CAST(TRY_CAST(NULLIF(TRIM([2003]), '') AS FLOAT) AS NUMERIC(18,2)),
    TRY_CAST(TRY_CAST(NULLIF(TRIM([2004]), '') AS FLOAT) AS NUMERIC(18,2)),
    TRY_CAST(TRY_CAST(NULLIF(TRIM([2005]), '') AS FLOAT) AS NUMERIC(18,2)),
    TRY_CAST(TRY_CAST(NULLIF(TRIM([2006]), '') AS FLOAT) AS NUMERIC(18,2)),
    TRY_CAST(TRY_CAST(NULLIF(TRIM([2007]), '') AS FLOAT) AS NUMERIC(18,2)),
    TRY_CAST(TRY_CAST(NULLIF(TRIM([2008]), '') AS FLOAT) AS NUMERIC(18,2)),
    TRY_CAST(TRY_CAST(NULLIF(TRIM([2009]), '') AS FLOAT) AS NUMERIC(18,2)),
    TRY_CAST(TRY_CAST(NULLIF(TRIM([2010]), '') AS FLOAT) AS NUMERIC(18,2)),
    TRY_CAST(TRY_CAST(NULLIF(TRIM([2011]), '') AS FLOAT) AS NUMERIC(18,2)),
    TRY_CAST(TRY_CAST(NULLIF(TRIM([2012]), '') AS FLOAT) AS NUMERIC(18,2)),
    TRY_CAST(TRY_CAST(NULLIF(TRIM([2013]), '') AS FLOAT) AS NUMERIC(18,2)),
    TRY_CAST(TRY_CAST(NULLIF(TRIM([2014]), '') AS FLOAT) AS NUMERIC(18,2))

FROM raw_transport.raw_archive_1991_2014_ts2_1_service_data_and_operating_expenses_time_series_by_mode_vrh;

INSERT INTO stg_transport.stg_ts21_archive_opexp_total(
    ntd_id,
    legacy_ntd_id,
    agency_name,
    reporter_type,
    reporting_module,
    city,
    state,
    census_year,
    primary_uza_name,
    uace_code,
    uza_area_sq_miles,
    uza_population,
    mode,
    service,
    mode_status,
    y1991,y1992,y1993,y1994,y1995,
    y1996,y1997,y1998,y1999,y2000,
    y2001,y2002,y2003,y2004,y2005,
    y2006,y2007,y2008,y2009,y2010,
    y2011,y2012,y2013,y2014
)
SELECT
    CAST(
        TRY_CAST(
            TRY_CAST(NULLIF(TRIM([NTD ID]), '') AS FLOAT)
        AS BIGINT)
    AS VARCHAR(50)),

    LEFT(NULLIF(TRIM([Legacy NTD ID]), ''), 50),

    LEFT(NULLIF(TRIM([Agency Name]), ''), 255),

    LEFT(NULLIF(TRIM([Reporter Type]), ''), 100),
    LEFT(NULLIF(TRIM([Reporting Module]), ''), 50),

    LEFT(NULLIF(TRIM([City]), ''), 100),
    LEFT(NULLIF(TRIM([State]), ''), 20),

    TRY_CAST(NULLIF(TRIM([Census Year]), '') AS INT),

    LEFT(NULLIF(TRIM([Primary UZA Name]), ''), 255),

    CAST(
        TRY_CAST(
            TRY_CAST(NULLIF(TRIM([UACE Code]), '') AS FLOAT)
        AS BIGINT)
    AS VARCHAR(50)),

    TRY_CAST(
        TRY_CAST(NULLIF(TRIM([UZA Area SQ Miles]), '') AS FLOAT)
    AS NUMERIC(18,2)),

    TRY_CAST(
        TRY_CAST(NULLIF(TRIM([UZA Population]), '') AS FLOAT)
    AS BIGINT),

    LEFT(NULLIF(TRIM([Mode]), ''), 20),
    LEFT(NULLIF(TRIM([Service]), ''), 20),
    LEFT(NULLIF(TRIM([Mode Status]), ''), 50),

    TRY_CAST(TRY_CAST(NULLIF(TRIM([1991]), '') AS FLOAT) AS NUMERIC(18,2)),
    TRY_CAST(TRY_CAST(NULLIF(TRIM([1992]), '') AS FLOAT) AS NUMERIC(18,2)),
    TRY_CAST(TRY_CAST(NULLIF(TRIM([1993]), '') AS FLOAT) AS NUMERIC(18,2)),
    TRY_CAST(TRY_CAST(NULLIF(TRIM([1994]), '') AS FLOAT) AS NUMERIC(18,2)),
    TRY_CAST(TRY_CAST(NULLIF(TRIM([1995]), '') AS FLOAT) AS NUMERIC(18,2)),
    TRY_CAST(TRY_CAST(NULLIF(TRIM([1996]), '') AS FLOAT) AS NUMERIC(18,2)),
    TRY_CAST(TRY_CAST(NULLIF(TRIM([1997]), '') AS FLOAT) AS NUMERIC(18,2)),
    TRY_CAST(TRY_CAST(NULLIF(TRIM([1998]), '') AS FLOAT) AS NUMERIC(18,2)),
    TRY_CAST(TRY_CAST(NULLIF(TRIM([1999]), '') AS FLOAT) AS NUMERIC(18,2)),
    TRY_CAST(TRY_CAST(NULLIF(TRIM([2000]), '') AS FLOAT) AS NUMERIC(18,2)),
    TRY_CAST(TRY_CAST(NULLIF(TRIM([2001]), '') AS FLOAT) AS NUMERIC(18,2)),
    TRY_CAST(TRY_CAST(NULLIF(TRIM([2002]), '') AS FLOAT) AS NUMERIC(18,2)),
    TRY_CAST(TRY_CAST(NULLIF(TRIM([2003]), '') AS FLOAT) AS NUMERIC(18,2)),
    TRY_CAST(TRY_CAST(NULLIF(TRIM([2004]), '') AS FLOAT) AS NUMERIC(18,2)),
    TRY_CAST(TRY_CAST(NULLIF(TRIM([2005]), '') AS FLOAT) AS NUMERIC(18,2)),
    TRY_CAST(TRY_CAST(NULLIF(TRIM([2006]), '') AS FLOAT) AS NUMERIC(18,2)),
    TRY_CAST(TRY_CAST(NULLIF(TRIM([2007]), '') AS FLOAT) AS NUMERIC(18,2)),
    TRY_CAST(TRY_CAST(NULLIF(TRIM([2008]), '') AS FLOAT) AS NUMERIC(18,2)),
    TRY_CAST(TRY_CAST(NULLIF(TRIM([2009]), '') AS FLOAT) AS NUMERIC(18,2)),
    TRY_CAST(TRY_CAST(NULLIF(TRIM([2010]), '') AS FLOAT) AS NUMERIC(18,2)),
    TRY_CAST(TRY_CAST(NULLIF(TRIM([2011]), '') AS FLOAT) AS NUMERIC(18,2)),
    TRY_CAST(TRY_CAST(NULLIF(TRIM([2012]), '') AS FLOAT) AS NUMERIC(18,2)),
    TRY_CAST(TRY_CAST(NULLIF(TRIM([2013]), '') AS FLOAT) AS NUMERIC(18,2)),
    TRY_CAST(TRY_CAST(NULLIF(TRIM([2014]), '') AS FLOAT) AS NUMERIC(18,2))

FROM raw_transport.raw_archive_1991_2014_ts2_1_service_data_and_operating_expenses_time_series_by_mode_opexp_total;

INSERT INTO stg_transport.stg_major_safety_event (
    incident_number,
    ntd_id,
    agency_name,
    primary_uza_uace_code,
    mode,
    type_of_service_code,
    event_date,
    event_time,
    year,
    event_category,
    event_type,
    event_type_group,
    safety_security,
    event_description,
    passenger_fatality_count,
    employee_fatality_count,
    other_fatality_count,
    total_fatality_count,
    passenger_injury_count,
    employee_injury_count,
    other_injury_count,
    total_injury_count,
    number_of_transit_vehicles_involved,
    evacuation,
    property_damage_amount
)
SELECT
    TRY_CAST(src_mse.[Incident Number] AS BIGINT),

    LEFT(NULLIF(TRIM(src_mse.[NTD ID]), ''), 50),
    LEFT(NULLIF(TRIM(src_mse.[Agency]), ''), 255),

    LEFT(NULLIF(TRIM(src_mse.[Primary UZA UACE Code]), ''), 50),

    LEFT(NULLIF(TRIM(src_mse.[Mode]), ''), 20),
    LEFT(NULLIF(TRIM(src_mse.[TOS]), ''), 20),

    TRY_PARSE(src_mse.[Event Date] AS DATE USING 'en-US'),

    TRY_CAST(src_mse.[Event Time] AS TIME),

    TRY_CAST(src_mse.[Year] AS INT),

    LEFT(NULLIF(TRIM(src_mse.[Event Category]), ''), 100),
    LEFT(NULLIF(TRIM(src_mse.[Event Type]), ''), 200),
    LEFT(NULLIF(TRIM(src_mse.[Event Type Group]), ''), 100),

    LEFT(NULLIF(TRIM(src_mse.[Safety/Security]), ''), 20),

    src_mse.[Event Description],

    -- ===== Fatalities: 3-way split + authoritative total =====
    -- Passenger  = Transit Vehicle Riders + People Waiting/Leaving
    -- Employee   = Operators + Non-Operator Employees + Other Workers
    -- Other      = Total - Passenger - Employee (clamped >= 0, since source
    --              component columns can over-count vs the reported total)
    fat.passenger_fatality_count,
    fat.employee_fatality_count,
    fat_other.other_fatality_count,
    fat.total_fatality_count,

    -- ===== Injuries: same 3-way split logic =====
    inj.passenger_injury_count,
    inj.employee_injury_count,
    inj_other.other_injury_count,
    inj.total_injury_count,

    TRY_CAST(src_mse.[Number of Transit Vehicles Involved] AS INT),

    CASE
        WHEN LOWER(TRIM(src_mse.[Evacuation])) = 'true' THEN 1
        WHEN LOWER(TRIM(src_mse.[Evacuation])) = 'false' THEN 0
        ELSE NULL
    END,

    -- Property Damage is numeric-with-commas in the source (e.g. '1,000'),
    -- so strip the thousands separators before casting to a decimal amount.
    TRY_CAST(REPLACE(src_mse.[Property Damage], ',', '') AS NUMERIC(18,2))

FROM (
    SELECT
        *,
        ROW_NUMBER() OVER (PARTITION BY TRY_CAST([Incident Number] AS BIGINT) ORDER BY (SELECT NULL)) AS rn
    FROM raw_transport.raw_major_safety_and_security_events_20260607
) src_mse

-- ------------------------------------------------------------
-- Fatality bucketing
-- ------------------------------------------------------------
CROSS APPLY (
    SELECT
        -- Passenger fatalities
        ISNULL(TRY_CAST(src_mse.[Transit Vehicle Rider Fatalities] AS INT), 0)
        + ISNULL(TRY_CAST(src_mse.[People Waiting or Leaving Fatalities] AS INT), 0)
            AS passenger_fatality_count,
        -- Employee fatalities
        ISNULL(TRY_CAST(src_mse.[Transit Vehicle Operator Fatalities] AS INT), 0)
        + ISNULL(TRY_CAST(src_mse.[Non-Operator Transit Employee Fatalities] AS INT), 0)
        + ISNULL(TRY_CAST(src_mse.[Other Worker Fatalities] AS INT), 0)
            AS employee_fatality_count,
        -- Authoritative total
        TRY_CAST(src_mse.[Total Fatalities] AS INT) AS total_fatality_count
) fat
CROSS APPLY (
    -- Other = Total - Passenger - Employee, clamped to a minimum of 0
    -- (the source's granular pedestrian/suicide/trespasser columns sometimes
    --  sum to more than Total, so Other is derived rather than summed directly)
    SELECT
        CASE
            WHEN fat.total_fatality_count IS NULL THEN NULL
            WHEN fat.total_fatality_count - fat.passenger_fatality_count
                                       - fat.employee_fatality_count < 0
                THEN 0
            ELSE fat.total_fatality_count - fat.passenger_fatality_count
                                        - fat.employee_fatality_count
        END AS other_fatality_count
) fat_other

-- ------------------------------------------------------------
-- Injury bucketing (same logic as fatalities)
-- ------------------------------------------------------------
CROSS APPLY (
    SELECT
        ISNULL(TRY_CAST(src_mse.[Transit Vehicle Rider Injuries] AS INT), 0)
        + ISNULL(TRY_CAST(src_mse.[People Waiting or Leaving Injuries] AS INT), 0)
            AS passenger_injury_count,
        ISNULL(TRY_CAST(src_mse.[Transit Vehicle Operator Injuries] AS INT), 0)
        + ISNULL(TRY_CAST(src_mse.[Non-Operator Transit Employee Injuries] AS INT), 0)
        + ISNULL(TRY_CAST(src_mse.[Other Worker Injuries] AS INT), 0)
            AS employee_injury_count,
        TRY_CAST(src_mse.[Total Injuries] AS INT) AS total_injury_count
) inj
CROSS APPLY (
    SELECT
        CASE
            WHEN inj.total_injury_count IS NULL THEN NULL
            WHEN inj.total_injury_count - inj.passenger_injury_count
                                      - inj.employee_injury_count < 0
                THEN 0
            ELSE inj.total_injury_count - inj.passenger_injury_count
                                       - inj.employee_injury_count
        END AS other_injury_count
) inj_other
WHERE src_mse.rn = 1;
