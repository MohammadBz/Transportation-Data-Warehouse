TRUNCATE TABLE stg_transport.stg_agency_information;

-- Clean out staging for a fresh load (Truncate and Load pattern)
TRUNCATE TABLE stg_transport.stg_agency_information;

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
    LEFT(NULLIF(TRIM([Primary UZA UACE Code]), 'None'), 50),
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

FROM raw_transport.[raw_2024_agency_information_250922];

-- Clean out staging for a fresh load
TRUNCATE TABLE stg_transport.stg_agency_mode_service;

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
    total_injuries,
    total_fatalities,
    number_of_transit_vehicles_involved,
    evacuation,
    property_damage
)
SELECT
    TRY_CAST([Incident Number] AS BIGINT),

    LEFT(NULLIF(TRIM([NTD ID]), ''), 50),
    LEFT(NULLIF(TRIM([Agency]), ''), 255),

    LEFT(NULLIF(TRIM([Primary UZA UACE Code]), ''), 50),

    LEFT(NULLIF(TRIM([Mode]), ''), 20),
    LEFT(NULLIF(TRIM([TOS]), ''), 20),

    TRY_PARSE([Event Date] AS DATE USING 'en-US'),

    TRY_CAST([Event Time] AS TIME),

    TRY_CAST([Year] AS INT),

    LEFT(NULLIF(TRIM([Event Category]), ''), 100),
    LEFT(NULLIF(TRIM([Event Type]), ''), 200),
    LEFT(NULLIF(TRIM([Event Type Group]), ''), 100),

    LEFT(NULLIF(TRIM([Safety/Security]), ''), 20),

    [Event Description],

    TRY_CAST([Total Injuries] AS INT),
    TRY_CAST([Total Fatalities] AS INT),

    TRY_CAST([Number of Transit Vehicles Involved] AS INT),

    CASE
        WHEN LOWER(TRIM([Evacuation])) = 'true' THEN 1
        WHEN LOWER(TRIM([Evacuation])) = 'false' THEN 0
        ELSE NULL
    END,

    LEFT(NULLIF(TRIM([Property Damage]), ''), 100)

FROM raw_transport.raw_major_safety_and_security_events_20260607;
