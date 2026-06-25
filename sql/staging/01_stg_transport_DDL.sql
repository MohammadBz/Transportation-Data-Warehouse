CREATE TABLE stg_transport.stg_agency_information (
    state_parent_ntd_id VARCHAR(50),
    ntd_id VARCHAR(50),
    legacy_ntd_id VARCHAR(50),
    agency_name VARCHAR(255),
    division_department VARCHAR(255),
    reporter_acronym VARCHAR(50),
    doing_business_as VARCHAR(255),
    reporter_type VARCHAR(100),
    reporting_module VARCHAR(50),
    organization_type VARCHAR(255),
    reported_by_ntd_id VARCHAR(50),
    reported_by_name VARCHAR(255),
    public_sponsor VARCHAR(255),
    subrecipient_type VARCHAR(100),

    fy_end_date DATE,
    original_due_date DATE,

    address_line_1 VARCHAR(255),
    address_line_2 VARCHAR(255),
    po_box VARCHAR(100),

    city VARCHAR(100),
    state VARCHAR(20),

    zip_code VARCHAR(20),
    zip_code_ext VARCHAR(20),

    region INTEGER,

    url VARCHAR(500),

    fta_recipient_id VARCHAR(50),
    ueid VARCHAR(50),

    service_area_sq_miles NUMERIC(18,2),
    service_area_pop BIGINT,

    primary_uza_uace_code VARCHAR(50),
    uza_name VARCHAR(255),

    tribal_area_name VARCHAR(255),

    population BIGINT,
    density NUMERIC(18,2),
    sq_miles NUMERIC(18,2),

    voms_do NUMERIC(18,2),
    voms_pt NUMERIC(18,2),
    total_voms NUMERIC(18,2),

    volunteer_drivers NUMERIC(18,2),
    personal_vehicles NUMERIC(18,2),

    tam_tier VARCHAR(100),

    number_of_state_counties NUMERIC(18,2),
    number_of_counties_with_service NUMERIC(18,2),

    state_admin_funds_expended NUMERIC(18,2)
);

CREATE TABLE stg_transport.stg_agency_mode_service (
    state_parent_ntd_id VARCHAR(50),

    ntd_id VARCHAR(50),

    agency_name VARCHAR(255),

    reporter_type VARCHAR(100),
    reporting_module VARCHAR(50),

    mode VARCHAR(20),
    type_of_service_code VARCHAR(20),

    voms NUMERIC(18,2),
    vams NUMERIC(18,2),

    rail VARCHAR(5),
    fixed_route VARCHAR(5),
    seasonal_segment VARCHAR(5),
    fixed_guideway_high_intensity VARCHAR(5),

    service_type VARCHAR(100),

    commitment_date DATE,
    start_service_date DATE,
    end_service_date DATE
);

CREATE TABLE stg_transport.stg_ts21_drm (
    last_report_year INTEGER,
    ntd_id VARCHAR(50),
    agency_name VARCHAR(255),
    agency_status VARCHAR(50),
    reporter_type VARCHAR(100),
    reporting_module VARCHAR(50),

    city VARCHAR(100),
    state VARCHAR(20),

    census_year VARCHAR(20),

    primary_uza_name VARCHAR(255),
    uace_code VARCHAR(50),
    uza_area_sq_miles NUMERIC(18,2),
    uza_population BIGINT,

    mode_status VARCHAR(50),
    mode VARCHAR(20),
    type_of_service VARCHAR(20),

    y2015 NUMERIC(18,2),
    y2016 NUMERIC(18,2),
    y2017 NUMERIC(18,2),
    y2018 NUMERIC(18,2),
    y2019 NUMERIC(18,2),
    y2020 NUMERIC(18,2),
    y2021 NUMERIC(18,2),
    y2022 NUMERIC(18,2),
    y2023 NUMERIC(18,2),
    y2024 NUMERIC(18,2)
);
CREATE TABLE stg_transport.stg_ts21_fares (
    last_report_year INTEGER,
    ntd_id VARCHAR(50),
    agency_name VARCHAR(255),
    agency_status VARCHAR(50),
    reporter_type VARCHAR(100),
    reporting_module VARCHAR(50),

    city VARCHAR(100),
    state VARCHAR(20),

    census_year VARCHAR(20),

    primary_uza_name VARCHAR(255),
    uace_code VARCHAR(50),
    uza_area_sq_miles NUMERIC(18,2),
    uza_population BIGINT,

    mode_status VARCHAR(50),
    mode VARCHAR(20),
    type_of_service VARCHAR(20),

    y2015 NUMERIC(18,2),
    y2016 NUMERIC(18,2),
    y2017 NUMERIC(18,2),
    y2018 NUMERIC(18,2),
    y2019 NUMERIC(18,2),
    y2020 NUMERIC(18,2),
    y2021 NUMERIC(18,2),
    y2022 NUMERIC(18,2),
    y2023 NUMERIC(18,2),
    y2024 NUMERIC(18,2)
);
CREATE TABLE stg_transport.stg_ts21_opexp_total(
    last_report_year INTEGER,
    ntd_id VARCHAR(50),
    agency_name VARCHAR(255),
    agency_status VARCHAR(50),
    reporter_type VARCHAR(100),
    reporting_module VARCHAR(50),

    city VARCHAR(100),
    state VARCHAR(20),

    census_year VARCHAR(20),

    primary_uza_name VARCHAR(255),
    uace_code VARCHAR(50),
    uza_area_sq_miles NUMERIC(18,2),
    uza_population BIGINT,

    mode_status VARCHAR(50),
    mode VARCHAR(20),
    type_of_service VARCHAR(20),

    y2015 NUMERIC(18,2),
    y2016 NUMERIC(18,2),
    y2017 NUMERIC(18,2),
    y2018 NUMERIC(18,2),
    y2019 NUMERIC(18,2),
    y2020 NUMERIC(18,2),
    y2021 NUMERIC(18,2),
    y2022 NUMERIC(18,2),
    y2023 NUMERIC(18,2),
    y2024 NUMERIC(18,2)
);
CREATE TABLE stg_transport.stg_ts21_upt (
    last_report_year INTEGER,
    ntd_id VARCHAR(50),
    agency_name VARCHAR(255),
    agency_status VARCHAR(50),
    reporter_type VARCHAR(100),
    reporting_module VARCHAR(50),

    city VARCHAR(100),
    state VARCHAR(20),

    census_year VARCHAR(20),

    primary_uza_name VARCHAR(255),
    uace_code VARCHAR(50),
    uza_area_sq_miles NUMERIC(18,2),
    uza_population BIGINT,

    mode_status VARCHAR(50),
    mode VARCHAR(20),
    type_of_service VARCHAR(20),

    y2015 NUMERIC(18,2),
    y2016 NUMERIC(18,2),
    y2017 NUMERIC(18,2),
    y2018 NUMERIC(18,2),
    y2019 NUMERIC(18,2),
    y2020 NUMERIC(18,2),
    y2021 NUMERIC(18,2),
    y2022 NUMERIC(18,2),
    y2023 NUMERIC(18,2),
    y2024 NUMERIC(18,2)
);
CREATE TABLE stg_transport.stg_ts21_pmt (
    last_report_year INTEGER,
    ntd_id VARCHAR(50),
    agency_name VARCHAR(255),
    agency_status VARCHAR(50),
    reporter_type VARCHAR(100),
    reporting_module VARCHAR(50),

    city VARCHAR(100),
    state VARCHAR(20),

    census_year VARCHAR(20),

    primary_uza_name VARCHAR(255),
    uace_code VARCHAR(50),
    uza_area_sq_miles NUMERIC(18,2),
    uza_population BIGINT,

    mode_status VARCHAR(50),
    mode VARCHAR(20),
    type_of_service VARCHAR(20),

    y2015 NUMERIC(18,2),
    y2016 NUMERIC(18,2),
    y2017 NUMERIC(18,2),
    y2018 NUMERIC(18,2),
    y2019 NUMERIC(18,2),
    y2020 NUMERIC(18,2),
    y2021 NUMERIC(18,2),
    y2022 NUMERIC(18,2),
    y2023 NUMERIC(18,2),
    y2024 NUMERIC(18,2)
);
CREATE TABLE stg_transport.stg_ts21_vrm(
    last_report_year INTEGER,
    ntd_id VARCHAR(50),
    agency_name VARCHAR(255),
    agency_status VARCHAR(50),
    reporter_type VARCHAR(100),
    reporting_module VARCHAR(50),

    city VARCHAR(100),
    state VARCHAR(20),

    census_year VARCHAR(20),

    primary_uza_name VARCHAR(255),
    uace_code VARCHAR(50),
    uza_area_sq_miles NUMERIC(18,2),
    uza_population BIGINT,

    mode_status VARCHAR(50),
    mode VARCHAR(20),
    type_of_service VARCHAR(20),

    y2015 NUMERIC(18,2),
    y2016 NUMERIC(18,2),
    y2017 NUMERIC(18,2),
    y2018 NUMERIC(18,2),
    y2019 NUMERIC(18,2),
    y2020 NUMERIC(18,2),
    y2021 NUMERIC(18,2),
    y2022 NUMERIC(18,2),
    y2023 NUMERIC(18,2),
    y2024 NUMERIC(18,2)
);
CREATE TABLE stg_transport.stg_ts21_vrh (
    last_report_year INTEGER,
    ntd_id VARCHAR(50),
    agency_name VARCHAR(255),
    agency_status VARCHAR(50),
    reporter_type VARCHAR(100),
    reporting_module VARCHAR(50),

    city VARCHAR(100),
    state VARCHAR(20),

    census_year VARCHAR(20),

    primary_uza_name VARCHAR(255),
    uace_code VARCHAR(50),
    uza_area_sq_miles NUMERIC(18,2),
    uza_population BIGINT,

    mode_status VARCHAR(50),
    mode VARCHAR(20),
    type_of_service VARCHAR(20),

    y2015 NUMERIC(18,2),
    y2016 NUMERIC(18,2),
    y2017 NUMERIC(18,2),
    y2018 NUMERIC(18,2),
    y2019 NUMERIC(18,2),
    y2020 NUMERIC(18,2),
    y2021 NUMERIC(18,2),
    y2022 NUMERIC(18,2),
    y2023 NUMERIC(18,2),
    y2024 NUMERIC(18,2)
);
CREATE TABLE stg_transport.stg_ts21_voms (
    last_report_year INTEGER,
    ntd_id VARCHAR(50),
    agency_name VARCHAR(255),
    agency_status VARCHAR(50),
    reporter_type VARCHAR(100),
    reporting_module VARCHAR(50),

    city VARCHAR(100),
    state VARCHAR(20),

    census_year VARCHAR(20),

    primary_uza_name VARCHAR(255),
    uace_code VARCHAR(50),
    uza_area_sq_miles NUMERIC(18,2),
    uza_population BIGINT,

    mode_status VARCHAR(50),
    mode VARCHAR(20),
    type_of_service VARCHAR(20),

    y2015 NUMERIC(18,2),
    y2016 NUMERIC(18,2),
    y2017 NUMERIC(18,2),
    y2018 NUMERIC(18,2),
    y2019 NUMERIC(18,2),
    y2020 NUMERIC(18,2),
    y2021 NUMERIC(18,2),
    y2022 NUMERIC(18,2),
    y2023 NUMERIC(18,2),
    y2024 NUMERIC(18,2)
);
CREATE TABLE stg_transport.stg_ts21_archive_drm (
    ntd_id VARCHAR(50),
    legacy_ntd_id VARCHAR(50),

    agency_name VARCHAR(255),

    reporter_type VARCHAR(100),
    reporting_module VARCHAR(50),

    city VARCHAR(100),
    state VARCHAR(20),

    census_year INTEGER,

    primary_uza_name VARCHAR(255),
    uace_code VARCHAR(50),

    uza_area_sq_miles NUMERIC(18,2),
    uza_population BIGINT,

    mode VARCHAR(20),
    service VARCHAR(20),
    mode_status VARCHAR(50),

    y1991 NUMERIC(18,2),
    y1992 NUMERIC(18,2),
    y1993 NUMERIC(18,2),
    y1994 NUMERIC(18,2),
    y1995 NUMERIC(18,2),
    y1996 NUMERIC(18,2),
    y1997 NUMERIC(18,2),
    y1998 NUMERIC(18,2),
    y1999 NUMERIC(18,2),
    y2000 NUMERIC(18,2),
    y2001 NUMERIC(18,2),
    y2002 NUMERIC(18,2),
    y2003 NUMERIC(18,2),
    y2004 NUMERIC(18,2),
    y2005 NUMERIC(18,2),
    y2006 NUMERIC(18,2),
    y2007 NUMERIC(18,2),
    y2008 NUMERIC(18,2),
    y2009 NUMERIC(18,2),
    y2010 NUMERIC(18,2),
    y2011 NUMERIC(18,2),
    y2012 NUMERIC(18,2),
    y2013 NUMERIC(18,2),
    y2014 NUMERIC(18,2)
);
CREATE TABLE stg_transport.stg_ts21_archive_upt (
    ntd_id VARCHAR(50),
    legacy_ntd_id VARCHAR(50),

    agency_name VARCHAR(255),

    reporter_type VARCHAR(100),
    reporting_module VARCHAR(50),

    city VARCHAR(100),
    state VARCHAR(20),

    census_year INTEGER,

    primary_uza_name VARCHAR(255),
    uace_code VARCHAR(50),

    uza_area_sq_miles NUMERIC(18,2),
    uza_population BIGINT,

    mode VARCHAR(20),
    service VARCHAR(20),
    mode_status VARCHAR(50),

    y1991 NUMERIC(18,2),
    y1992 NUMERIC(18,2),
    y1993 NUMERIC(18,2),
    y1994 NUMERIC(18,2),
    y1995 NUMERIC(18,2),
    y1996 NUMERIC(18,2),
    y1997 NUMERIC(18,2),
    y1998 NUMERIC(18,2),
    y1999 NUMERIC(18,2),
    y2000 NUMERIC(18,2),
    y2001 NUMERIC(18,2),
    y2002 NUMERIC(18,2),
    y2003 NUMERIC(18,2),
    y2004 NUMERIC(18,2),
    y2005 NUMERIC(18,2),
    y2006 NUMERIC(18,2),
    y2007 NUMERIC(18,2),
    y2008 NUMERIC(18,2),
    y2009 NUMERIC(18,2),
    y2010 NUMERIC(18,2),
    y2011 NUMERIC(18,2),
    y2012 NUMERIC(18,2),
    y2013 NUMERIC(18,2),
    y2014 NUMERIC(18,2)
);
CREATE TABLE stg_transport.stg_ts21_archive_pmt (
    ntd_id VARCHAR(50),
    legacy_ntd_id VARCHAR(50),

    agency_name VARCHAR(255),

    reporter_type VARCHAR(100),
    reporting_module VARCHAR(50),

    city VARCHAR(100),
    state VARCHAR(20),

    census_year INTEGER,

    primary_uza_name VARCHAR(255),
    uace_code VARCHAR(50),

    uza_area_sq_miles NUMERIC(18,2),
    uza_population BIGINT,

    mode VARCHAR(20),
    service VARCHAR(20),
    mode_status VARCHAR(50),

    y1991 NUMERIC(18,2),
    y1992 NUMERIC(18,2),
    y1993 NUMERIC(18,2),
    y1994 NUMERIC(18,2),
    y1995 NUMERIC(18,2),
    y1996 NUMERIC(18,2),
    y1997 NUMERIC(18,2),
    y1998 NUMERIC(18,2),
    y1999 NUMERIC(18,2),
    y2000 NUMERIC(18,2),
    y2001 NUMERIC(18,2),
    y2002 NUMERIC(18,2),
    y2003 NUMERIC(18,2),
    y2004 NUMERIC(18,2),
    y2005 NUMERIC(18,2),
    y2006 NUMERIC(18,2),
    y2007 NUMERIC(18,2),
    y2008 NUMERIC(18,2),
    y2009 NUMERIC(18,2),
    y2010 NUMERIC(18,2),
    y2011 NUMERIC(18,2),
    y2012 NUMERIC(18,2),
    y2013 NUMERIC(18,2),
    y2014 NUMERIC(18,2)
);
CREATE TABLE stg_transport.stg_ts21_archive_vrm (
    ntd_id VARCHAR(50),
    legacy_ntd_id VARCHAR(50),

    agency_name VARCHAR(255),

    reporter_type VARCHAR(100),
    reporting_module VARCHAR(50),

    city VARCHAR(100),
    state VARCHAR(20),

    census_year INTEGER,

    primary_uza_name VARCHAR(255),
    uace_code VARCHAR(50),

    uza_area_sq_miles NUMERIC(18,2),
    uza_population BIGINT,

    mode VARCHAR(20),
    service VARCHAR(20),
    mode_status VARCHAR(50),

    y1991 NUMERIC(18,2),
    y1992 NUMERIC(18,2),
    y1993 NUMERIC(18,2),
    y1994 NUMERIC(18,2),
    y1995 NUMERIC(18,2),
    y1996 NUMERIC(18,2),
    y1997 NUMERIC(18,2),
    y1998 NUMERIC(18,2),
    y1999 NUMERIC(18,2),
    y2000 NUMERIC(18,2),
    y2001 NUMERIC(18,2),
    y2002 NUMERIC(18,2),
    y2003 NUMERIC(18,2),
    y2004 NUMERIC(18,2),
    y2005 NUMERIC(18,2),
    y2006 NUMERIC(18,2),
    y2007 NUMERIC(18,2),
    y2008 NUMERIC(18,2),
    y2009 NUMERIC(18,2),
    y2010 NUMERIC(18,2),
    y2011 NUMERIC(18,2),
    y2012 NUMERIC(18,2),
    y2013 NUMERIC(18,2),
    y2014 NUMERIC(18,2)
);
CREATE TABLE stg_transport.stg_ts21_archive_vrh(
    ntd_id VARCHAR(50),
    legacy_ntd_id VARCHAR(50),

    agency_name VARCHAR(255),

    reporter_type VARCHAR(100),
    reporting_module VARCHAR(50),

    city VARCHAR(100),
    state VARCHAR(20),

    census_year INTEGER,

    primary_uza_name VARCHAR(255),
    uace_code VARCHAR(50),

    uza_area_sq_miles NUMERIC(18,2),
    uza_population BIGINT,

    mode VARCHAR(20),
    service VARCHAR(20),
    mode_status VARCHAR(50),

    y1991 NUMERIC(18,2),
    y1992 NUMERIC(18,2),
    y1993 NUMERIC(18,2),
    y1994 NUMERIC(18,2),
    y1995 NUMERIC(18,2),
    y1996 NUMERIC(18,2),
    y1997 NUMERIC(18,2),
    y1998 NUMERIC(18,2),
    y1999 NUMERIC(18,2),
    y2000 NUMERIC(18,2),
    y2001 NUMERIC(18,2),
    y2002 NUMERIC(18,2),
    y2003 NUMERIC(18,2),
    y2004 NUMERIC(18,2),
    y2005 NUMERIC(18,2),
    y2006 NUMERIC(18,2),
    y2007 NUMERIC(18,2),
    y2008 NUMERIC(18,2),
    y2009 NUMERIC(18,2),
    y2010 NUMERIC(18,2),
    y2011 NUMERIC(18,2),
    y2012 NUMERIC(18,2),
    y2013 NUMERIC(18,2),
    y2014 NUMERIC(18,2)
);
CREATE TABLE stg_transport.stg_ts21_archive_voms (
    ntd_id VARCHAR(50),
    legacy_ntd_id VARCHAR(50),

    agency_name VARCHAR(255),

    reporter_type VARCHAR(100),
    reporting_module VARCHAR(50),

    city VARCHAR(100),
    state VARCHAR(20),

    census_year INTEGER,

    primary_uza_name VARCHAR(255),
    uace_code VARCHAR(50),

    uza_area_sq_miles NUMERIC(18,2),
    uza_population BIGINT,

    mode VARCHAR(20),
    service VARCHAR(20),
    mode_status VARCHAR(50),

    y1991 NUMERIC(18,2),
    y1992 NUMERIC(18,2),
    y1993 NUMERIC(18,2),
    y1994 NUMERIC(18,2),
    y1995 NUMERIC(18,2),
    y1996 NUMERIC(18,2),
    y1997 NUMERIC(18,2),
    y1998 NUMERIC(18,2),
    y1999 NUMERIC(18,2),
    y2000 NUMERIC(18,2),
    y2001 NUMERIC(18,2),
    y2002 NUMERIC(18,2),
    y2003 NUMERIC(18,2),
    y2004 NUMERIC(18,2),
    y2005 NUMERIC(18,2),
    y2006 NUMERIC(18,2),
    y2007 NUMERIC(18,2),
    y2008 NUMERIC(18,2),
    y2009 NUMERIC(18,2),
    y2010 NUMERIC(18,2),
    y2011 NUMERIC(18,2),
    y2012 NUMERIC(18,2),
    y2013 NUMERIC(18,2),
    y2014 NUMERIC(18,2)
);

CREATE TABLE stg_transport.stg_ts21_archive_fares (
    ntd_id VARCHAR(50),
    legacy_ntd_id VARCHAR(50),

    agency_name VARCHAR(255),

    reporter_type VARCHAR(100),
    reporting_module VARCHAR(50),

    city VARCHAR(100),
    state VARCHAR(20),

    census_year INTEGER,

    primary_uza_name VARCHAR(255),
    uace_code VARCHAR(50),

    uza_area_sq_miles NUMERIC(18,2),
    uza_population BIGINT,

    mode VARCHAR(20),
    service VARCHAR(20),
    mode_status VARCHAR(50),

    y1991 NUMERIC(18,2),
    y1992 NUMERIC(18,2),
    y1993 NUMERIC(18,2),
    y1994 NUMERIC(18,2),
    y1995 NUMERIC(18,2),
    y1996 NUMERIC(18,2),
    y1997 NUMERIC(18,2),
    y1998 NUMERIC(18,2),
    y1999 NUMERIC(18,2),
    y2000 NUMERIC(18,2),
    y2001 NUMERIC(18,2),
    y2002 NUMERIC(18,2),
    y2003 NUMERIC(18,2),
    y2004 NUMERIC(18,2),
    y2005 NUMERIC(18,2),
    y2006 NUMERIC(18,2),
    y2007 NUMERIC(18,2),
    y2008 NUMERIC(18,2),
    y2009 NUMERIC(18,2),
    y2010 NUMERIC(18,2),
    y2011 NUMERIC(18,2),
    y2012 NUMERIC(18,2),
    y2013 NUMERIC(18,2),
    y2014 NUMERIC(18,2)
);
CREATE TABLE stg_transport.stg_ts21_archive_opexp_total(
    ntd_id VARCHAR(50),
    legacy_ntd_id VARCHAR(50),

    agency_name VARCHAR(255),

    reporter_type VARCHAR(100),
    reporting_module VARCHAR(50),

    city VARCHAR(100),
    state VARCHAR(20),

    census_year INTEGER,

    primary_uza_name VARCHAR(255),
    uace_code VARCHAR(50),

    uza_area_sq_miles NUMERIC(18,2),
    uza_population BIGINT,

    mode VARCHAR(20),
    service VARCHAR(20),
    mode_status VARCHAR(50),

    y1991 NUMERIC(18,2),
    y1992 NUMERIC(18,2),
    y1993 NUMERIC(18,2),
    y1994 NUMERIC(18,2),
    y1995 NUMERIC(18,2),
    y1996 NUMERIC(18,2),
    y1997 NUMERIC(18,2),
    y1998 NUMERIC(18,2),
    y1999 NUMERIC(18,2),
    y2000 NUMERIC(18,2),
    y2001 NUMERIC(18,2),
    y2002 NUMERIC(18,2),
    y2003 NUMERIC(18,2),
    y2004 NUMERIC(18,2),
    y2005 NUMERIC(18,2),
    y2006 NUMERIC(18,2),
    y2007 NUMERIC(18,2),
    y2008 NUMERIC(18,2),
    y2009 NUMERIC(18,2),
    y2010 NUMERIC(18,2),
    y2011 NUMERIC(18,2),
    y2012 NUMERIC(18,2),
    y2013 NUMERIC(18,2),
    y2014 NUMERIC(18,2)
);

CREATE TABLE stg_transport.stg_major_safety_event (
    incident_number BIGINT,

    ntd_id VARCHAR(50),
    agency_name VARCHAR(255),

    primary_uza_uace_code VARCHAR(50),

    mode VARCHAR(20),
    type_of_service_code VARCHAR(20),

    event_date DATE,
    event_time TIME,
    year INTEGER,

    event_category VARCHAR(100),
    event_type VARCHAR(200),
    event_type_group VARCHAR(100),

    safety_security VARCHAR(20),

    event_description VARCHAR(MAX),

    total_injuries INTEGER,
    total_fatalities INTEGER,

    number_of_transit_vehicles_involved INTEGER,

    evacuation BIT,

    property_damage VARCHAR(100)
);
CREATE TABLE stg_transport.stg_dim_date (
    date_key INTEGER,
    full_date DATE,

    day_long_name VARCHAR(20),
    day_short_name VARCHAR(10),

    month_long_name VARCHAR(20),
    month_short_name VARCHAR(10),

    calendar_day INTEGER,
    calendar_week INTEGER,

    calendar_week_start_date_id INTEGER,
    calendar_week_end_date_id INTEGER,

    calendar_day_in_week INTEGER,

    calendar_month INTEGER,
    calendar_month_start_date_id INTEGER,
    calendar_month_end_date_id INTEGER,

    calendar_number_of_days_in_month INTEGER,
    calendar_day_in_month INTEGER,

    calendar_quarter INTEGER,
    calendar_quarter_start_date_id INTEGER,
    calendar_quarter_end_date_id INTEGER,

    calendar_number_of_days_in_quarter INTEGER,
    calendar_day_in_quarter INTEGER,

    calendar_year INTEGER,
    calendar_year_start_date_id INTEGER,
    calendar_year_end_date_id INTEGER,

    calendar_number_of_days_in_year INTEGER
);
