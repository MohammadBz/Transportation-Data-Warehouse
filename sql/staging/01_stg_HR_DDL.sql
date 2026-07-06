-- ========================================
-- HR STAGING TABLES
-- ========================================
-- These staging tables serve as an intermediate layer between
-- source data and the data warehouse dimensional model.
-- They maintain the structure and grain of the source data.

-- ========================================
-- JOB OPENINGS STAGING TABLE
-- ========================================
-- Grain: One row per job opening

CREATE TABLE stg_HR.stg_job_openings (
    opening_id VARCHAR(100) NOT NULL,

    ntd_id VARCHAR(50),
    agency_name VARCHAR(255),

    position_title VARCHAR(255),
    position_description VARCHAR(MAX),

    employment_type VARCHAR(100),
    labor_category VARCHAR(100),
    department VARCHAR(255),

    mode VARCHAR(20),
    service_type VARCHAR(100),

    posting_date DATE,
    closing_date DATE,
    filled_date DATE,

    open_positions INTEGER,
    hired_count INTEGER,

    salary_min_hourly NUMERIC(18,2),
    salary_max_hourly NUMERIC(18,2),
    salary_min_annual NUMERIC(18,2),
    salary_max_annual NUMERIC(18,2),

    posting_status VARCHAR(50),
    vacancy_reason VARCHAR(255),

    requirements_summary VARCHAR(MAX),
    education_required VARCHAR(100),

    benefits_summary VARCHAR(MAX),
    schedule VARCHAR(100),

    location_city VARCHAR(100),
    location_state VARCHAR(20),

    -- Unique constraint ensures no duplicate opening records at source
    CONSTRAINT UQ_stg_job_openings_opening_id UNIQUE (opening_id)
);

-- ========================================
-- EMPLOYEES STAGING TABLE
-- ========================================
-- Grain: One row per employee record (snapshot)

CREATE TABLE stg_HR.stg_employees (
    employee_id VARCHAR(100) NOT NULL,

    ntd_id VARCHAR(50),
    agency_name VARCHAR(255),

    first_name VARCHAR(100),
    last_name VARCHAR(100),
    full_name VARCHAR(255),

    employment_type VARCHAR(100),
    job_title VARCHAR(255),
    job_classification VARCHAR(100),
    labor_category VARCHAR(100),

    department VARCHAR(255),
    division VARCHAR(255),

    mode VARCHAR(20),
    service_type VARCHAR(100),

    hire_date DATE,
    termination_date DATE,

    salary_hourly NUMERIC(18,2),
    salary_annual NUMERIC(18,2),

    hours_per_week NUMERIC(18,2),
    hours_per_year NUMERIC(18,2),

    location_city VARCHAR(100),
    location_state VARCHAR(20),

    education_level VARCHAR(100),

    employment_status VARCHAR(50),

    years_of_service NUMERIC(10,2),

    -- Unique constraint ensures no duplicate employee records
    CONSTRAINT UQ_stg_employees_employee_id UNIQUE (employee_id)
);

-- ========================================
-- EMPLOYEE MONTHLY SNAPSHOT STAGING TABLE
-- ========================================
-- Grain: One row per month per employee per labor category
-- This table represents periodic snapshots of employee data

CREATE TABLE stg_HR.stg_employee_monthly_snapshot (
    snapshot_id VARCHAR(100),

    snapshot_month DATE,
    snapshot_year INTEGER,

    ntd_id VARCHAR(50),
    agency_name VARCHAR(255),

    labor_category VARCHAR(100),

    mode VARCHAR(20),
    service_type VARCHAR(100),

    employment_type VARCHAR(100),

    department VARCHAR(255),

    employee_count INTEGER,

    average_hourly_wage NUMERIC(18,2),

    total_hours_worked NUMERIC(18,2),
    total_overtime_hours NUMERIC(18,2),
    total_paid_hours NUMERIC(18,2),

    average_hours_per_employee NUMERIC(18,2),

    turnover_count INTEGER
);

-- ========================================
-- JOB POSTINGS PERFORMANCE STAGING TABLE
-- ========================================
-- Grain: One row per job opening with performance metrics

CREATE TABLE stg_HR.stg_job_posting_performance (
    opening_id VARCHAR(100) NOT NULL,

    ntd_id VARCHAR(50),
    agency_name VARCHAR(255),

    position_title VARCHAR(255),
    employment_type VARCHAR(100),
    labor_category VARCHAR(100),

    posting_date DATE,
    closing_date DATE,
    filled_date DATE,

    days_open INTEGER,

    open_positions INTEGER,
    hired_count INTEGER,
    filled_percentage NUMERIC(18,2),

    applicant_count INTEGER,
    applicant_to_hire_ratio NUMERIC(18,2),

    mode VARCHAR(20),
    service_type VARCHAR(100),

    salary_midpoint_hourly NUMERIC(18,2),

    posting_status VARCHAR(50),

    CONSTRAINT UQ_stg_job_posting_performance_opening_id UNIQUE (opening_id)
);

-- ========================================
-- LABOR CATEGORY STAGING TABLE
-- ========================================
-- Grain: One row per unique labor category per agency

CREATE TABLE stg_HR.stg_labor_category (
    labor_category_code VARCHAR(50) NOT NULL,
    labor_category_name VARCHAR(255),

    category_type VARCHAR(100),
    category_description VARCHAR(MAX),

    operator_status VARCHAR(50),

    is_active BIT
);

-- ========================================
-- EMPLOYMENT TYPE STAGING TABLE
-- ========================================
-- Grain: One row per unique employment type

CREATE TABLE stg_HR.stg_employment_type (
    employment_type_code VARCHAR(50) NOT NULL,
    employment_type_name VARCHAR(100),

    employment_type_description VARCHAR(MAX),

    is_full_time BIT,
    is_active BIT
);

-- ========================================
-- JOB ROLE STAGING TABLE
-- ========================================
-- Grain: One row per unique position title

CREATE TABLE stg_HR.stg_job_role (
    position_title VARCHAR(255) NOT NULL,

    position_description VARCHAR(MAX),

    labor_category VARCHAR(100),
    employment_type VARCHAR(100),

    operator_status VARCHAR(50),

    typical_salary_min NUMERIC(18,2),
    typical_salary_max NUMERIC(18,2),

    is_active BIT
);

-- ========================================
-- EDUCATION LEVEL STAGING TABLE
-- ========================================
-- Grain: One row per unique education level

CREATE TABLE stg_HR.stg_education_level (
    education_level_code VARCHAR(50) NOT NULL,
    education_level_name VARCHAR(100),

    education_level_description VARCHAR(MAX),

    hierarchy_level INTEGER,

    is_active BIT
);

-- ========================================
-- AGENCY LABOR COVERAGE STAGING TABLE
-- ========================================
-- Grain: One row per agency per labor category combination
-- Shows which agencies provide workforce for which labor categories

CREATE TABLE stg_HR.stg_agency_labor_coverage (
    coverage_id VARCHAR(100),

    ntd_id VARCHAR(50) NOT NULL,
    agency_name VARCHAR(255),

    labor_category VARCHAR(100) NOT NULL,

    mode VARCHAR(20),
    service_type VARCHAR(100),

    employment_type VARCHAR(100),

    effective_date DATE,
    end_date DATE,

    is_active BIT,

    CONSTRAINT UQ_stg_agency_labor_coverage UNIQUE (ntd_id, labor_category, mode, service_type, employment_type)
);

-- ========================================
-- EMPLOYEE ATTRITION STAGING TABLE
-- ========================================
-- Grain: One row per historical employee with attrition indicators

CREATE TABLE stg_HR.stg_employee_attrition (
    employee_id VARCHAR(100) NOT NULL,

    ntd_id VARCHAR(50),
    agency_name VARCHAR(255),

    full_name VARCHAR(255),

    department VARCHAR(255),
    job_title VARCHAR(255),

    employment_type VARCHAR(100),
    labor_category VARCHAR(100),

    hire_date DATE,
    termination_date DATE,

    tenure_years NUMERIC(10,2),

    attrition_flag BIT,
    attrition_reason VARCHAR(255),

    education_level VARCHAR(100),
    monthly_income NUMERIC(18,2),

    years_at_company NUMERIC(10,2),

    job_involvement VARCHAR(50),
    performance_rating NUMERIC(10,2),

    age INTEGER,

    CONSTRAINT UQ_stg_employee_attrition_employee_id UNIQUE (employee_id)
);

-- ========================================
-- DEPARTMENT STAGING TABLE
-- ========================================
-- Grain: One row per unique department

CREATE TABLE stg_HR.stg_department (
    department_code VARCHAR(50) NOT NULL,
    department_name VARCHAR(255),

    ntd_labor_object_class VARCHAR(100),

    department_description VARCHAR(MAX),

    is_active BIT
);
