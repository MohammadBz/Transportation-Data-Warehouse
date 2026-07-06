-- ============================================================
-- FILE:   05_fact_HR_DDL.sql
-- SCHEMA: dw_HR
-- DESC:   Creates all fact tables for the HR Data Warehouse
--         following Kimball methodology.
--
-- EXECUTION ORDER: Run after 03_dim_HR_DDL.sql
--
-- KIMBALL CONVENTIONS APPLIED:
--   Fact keys       : BIGINT IDENTITY(1,1) for fact grain uniqueness
--   Foreign keys    : INT (matching dimension surrogate keys)
--   Additive facts  : sum, count, and aggregate measures supported
--   Non-additive    : Salary, rates, per-unit wages (aggregate carefully)
--   Grain           : explicit in CREATE TABLE comments
--   Slowly Changing : Fact tables are Type 1 (no history / versions)
--   Nullability     : FK columns NOT NULL for required dimensions,
--                     NULL for optional dimensions
--
-- DESIGN NOTES:
--   * Fact tables reference dimension unknown members (-1) when
--     source data lacks a valid dimension value.
--   * Numeric measures use BIGINT (counts), DECIMAL(18,2) (money/hours),
--     SMALLINT (employee counts), or INT (derived metrics).
--   * Fact keys are not exposed to ETL; they are internal surrogates.
--   * Grain is explicit per fact table to prevent double-counting.
--
-- ============================================================

USE [TransportationDB];
GO

-- ============================================================
-- 1. FactJobPosting
--
-- GRAIN: One row per OpeningID
--
-- MEASURES (Additive):
--   * OpenPositions: Number of positions to fill
--   * DaysOpen: Duration posting was open (cumulative; use caution)
--   * HiredCount: Number successfully hired
--   * SalaryMinHourly: Minimum hourly rate offered (non-additive)
--   * SalaryMaxHourly: Maximum hourly rate offered (non-additive)
--   * SalaryMidHourly: Midpoint hourly rate (non-additive)
--
-- FACT SOURCE: stg_job_openings (one posting = one row)
-- ============================================================

IF OBJECT_ID('dw_HR.FactJobPosting', 'U') IS NOT NULL
    DROP TABLE dw_HR.FactJobPosting;
GO

CREATE TABLE dw_HR.FactJobPosting (

    -- Surrogate fact key
    JobPostingFactKey           BIGINT          NOT NULL    IDENTITY(1,1),

    -- Foreign keys to dimensions (NOT NULL for required dimensions)
    DateKey                     INT             NOT NULL,    -- Posting date
    AgencyKey                   INT             NOT NULL,
    ModeKey                     INT             NOT NULL,
    ServiceTypeKey              INT             NOT NULL,
    EmploymentTypeKey           INT             NOT NULL,
    DepartmentKey               INT             NOT NULL,
    JobRoleKey                  INT             NOT NULL,

    -- Degenerate dimension: natural key from source
    OpeningID                   VARCHAR(100)    NOT NULL,

    -- Additive measures
    OpenPositions               INT             NULL,       -- Number of positions to fill
    DaysOpen                    INT             NULL,       -- Duration posting was open
    HiredCount                  INT             NULL,       -- Number successfully hired

    -- Non-additive salary measures
    SalaryMinHourly             DECIMAL(18,2)   NULL,
    SalaryMaxHourly             DECIMAL(18,2)   NULL,
    SalaryMidHourly             DECIMAL(18,2)   NULL,

    -- Status and reason
    PostingStatus               VARCHAR(50)     NULL,
    VacancyReason               VARCHAR(255)    NULL,

    -- --------------------------------------------------------
    -- Constraints
    -- --------------------------------------------------------
    CONSTRAINT PK_FactJobPosting
        PRIMARY KEY CLUSTERED (JobPostingFactKey),

    -- Foreign key constraints
    CONSTRAINT FK_FactJobPosting_DateKey
        FOREIGN KEY (DateKey)
        REFERENCES dw_HR.DimDate (DateKey),
    CONSTRAINT FK_FactJobPosting_AgencyKey
        FOREIGN KEY (AgencyKey)
        REFERENCES dw_HR.DimAgency (AgencyKey),
    CONSTRAINT FK_FactJobPosting_ModeKey
        FOREIGN KEY (ModeKey)
        REFERENCES dw_HR.DimMode (ModeKey),
    CONSTRAINT FK_FactJobPosting_ServiceTypeKey
        FOREIGN KEY (ServiceTypeKey)
        REFERENCES dw_HR.DimServiceType (ServiceTypeKey),
    CONSTRAINT FK_FactJobPosting_EmploymentTypeKey
        FOREIGN KEY (EmploymentTypeKey)
        REFERENCES dw_HR.DimEmploymentType (EmploymentTypeKey),
    CONSTRAINT FK_FactJobPosting_DepartmentKey
        FOREIGN KEY (DepartmentKey)
        REFERENCES dw_HR.DimDepartment (DepartmentKey),
    CONSTRAINT FK_FactJobPosting_JobRoleKey
        FOREIGN KEY (JobRoleKey)
        REFERENCES dw_HR.DimJobRole (JobRoleKey),

    -- Measure value constraints (non-negative)
    CONSTRAINT CK_FactJobPosting_OpenPositions
        CHECK (OpenPositions IS NULL OR OpenPositions >= 0),
    CONSTRAINT CK_FactJobPosting_DaysOpen
        CHECK (DaysOpen IS NULL OR DaysOpen >= 0),
    CONSTRAINT CK_FactJobPosting_HiredCount
        CHECK (HiredCount IS NULL OR HiredCount >= 0),
    CONSTRAINT CK_FactJobPosting_Salaries
        CHECK (SalaryMinHourly IS NULL OR SalaryMinHourly >= 0),
    CONSTRAINT CK_FactJobPosting_SalaryRange
        CHECK (SalaryMinHourly IS NULL OR SalaryMaxHourly IS NULL OR SalaryMinHourly <= SalaryMaxHourly)
);
GO

-- Index on grain dimensions for ETL/reporting efficiency
CREATE NONCLUSTERED INDEX IX_FactJobPosting_Grain
    ON dw_HR.FactJobPosting (AgencyKey, ModeKey, ServiceTypeKey, EmploymentTypeKey, JobRoleKey)
    INCLUDE (OpenPositions, DaysOpen, HiredCount, SalaryMidHourly);
GO

-- Index on degenerate dimension (OpeningID) for direct lookups
CREATE NONCLUSTERED INDEX IX_FactJobPosting_OpeningID
    ON dw_HR.FactJobPosting (OpeningID)
    INCLUDE (OpenPositions, HiredCount, SalaryMinHourly, SalaryMaxHourly);
GO

-- Index on posting date for time-series analysis
CREATE NONCLUSTERED INDEX IX_FactJobPosting_DateKey
    ON dw_HR.FactJobPosting (DateKey)
    INCLUDE (OpenPositions, HiredCount, DaysOpen);
GO

-- ============================================================
-- 2. FactEmployeeSnapshot
--
-- GRAIN: One row per SnapshotMonth × Agency × LaborCategory
--        × EmploymentType × Mode × ServiceType
--
-- MEASURES (Additive):
--   * EmployeeCount: Headcount at snapshot date (semi-additive: time-sensitive)
--   * AverageHourlyWage: Mean wage for period (semi-additive: non-additive)
--   * TotalHoursWorked: Cumulative hours (additive within period)
--   * TotalOvertimeHours: Cumulative OT hours (additive within period)
--   * TotalPaidHours: Total paid (additive within period)
--
-- FACT SOURCE: stg_employee_monthly_snapshot (one snapshot = one row)
--              Aggregated from detailed employee records
-- ============================================================

IF OBJECT_ID('dw_HR.FactEmployeeSnapshot', 'U') IS NOT NULL
    DROP TABLE dw_HR.FactEmployeeSnapshot;
GO

CREATE TABLE dw_HR.FactEmployeeSnapshot (

    -- Surrogate fact key
    SnapshotFactKey             BIGINT          NOT NULL    IDENTITY(1,1),

    -- Foreign keys to dimensions (NOT NULL for required dimensions)
    DateKey                     INT             NOT NULL,    -- Snapshot month/year
    AgencyKey                   INT             NOT NULL,
    ModeKey                     INT             NOT NULL,
    ServiceTypeKey              INT             NOT NULL,
    EmploymentTypeKey           INT             NOT NULL,
    DepartmentKey               INT             NOT NULL,

    -- Optional dimension reference (JobRole may not apply to all workforce)
    JobRoleKey                  INT             NULL,

    -- Semi-additive headcount measure
    EmployeeCount               INT             NULL,       -- Headcount at snapshot date

    -- Semi-additive wage measure (use average aggregation)
    AverageHourlyWage           DECIMAL(18,2)   NULL,

    -- Additive hour measures (within time period)
    TotalHoursWorked            DECIMAL(18,2)   NULL,
    TotalOvertimeHours          DECIMAL(18,2)   NULL,
    TotalPaidHours              DECIMAL(18,2)   NULL,

    -- --------------------------------------------------------
    -- Constraints
    -- --------------------------------------------------------
    CONSTRAINT PK_FactEmployeeSnapshot
        PRIMARY KEY CLUSTERED (SnapshotFactKey),

    -- Foreign key constraints
    CONSTRAINT FK_FactEmployeeSnapshot_DateKey
        FOREIGN KEY (DateKey)
        REFERENCES dw_HR.DimDate (DateKey),
    CONSTRAINT FK_FactEmployeeSnapshot_AgencyKey
        FOREIGN KEY (AgencyKey)
        REFERENCES dw_HR.DimAgency (AgencyKey),
    CONSTRAINT FK_FactEmployeeSnapshot_ModeKey
        FOREIGN KEY (ModeKey)
        REFERENCES dw_HR.DimMode (ModeKey),
    CONSTRAINT FK_FactEmployeeSnapshot_ServiceTypeKey
        FOREIGN KEY (ServiceTypeKey)
        REFERENCES dw_HR.DimServiceType (ServiceTypeKey),
    CONSTRAINT FK_FactEmployeeSnapshot_EmploymentTypeKey
        FOREIGN KEY (EmploymentTypeKey)
        REFERENCES dw_HR.DimEmploymentType (EmploymentTypeKey),
    CONSTRAINT FK_FactEmployeeSnapshot_DepartmentKey
        FOREIGN KEY (DepartmentKey)
        REFERENCES dw_HR.DimDepartment (DepartmentKey),
    CONSTRAINT FK_FactEmployeeSnapshot_JobRoleKey
        FOREIGN KEY (JobRoleKey)
        REFERENCES dw_HR.DimJobRole (JobRoleKey),

    -- Measure value constraints (non-negative)
    CONSTRAINT CK_FactEmployeeSnapshot_EmployeeCount
        CHECK (EmployeeCount IS NULL OR EmployeeCount >= 0),
    CONSTRAINT CK_FactEmployeeSnapshot_AverageHourlyWage
        CHECK (AverageHourlyWage IS NULL OR AverageHourlyWage >= 0),
    CONSTRAINT CK_FactEmployeeSnapshot_TotalHoursWorked
        CHECK (TotalHoursWorked IS NULL OR TotalHoursWorked >= 0),
    CONSTRAINT CK_FactEmployeeSnapshot_TotalOvertimeHours
        CHECK (TotalOvertimeHours IS NULL OR TotalOvertimeHours >= 0),
    CONSTRAINT CK_FactEmployeeSnapshot_TotalPaidHours
        CHECK (TotalPaidHours IS NULL OR TotalPaidHours >= 0)
);
GO

-- Index on grain dimensions for snapshot queries
CREATE NONCLUSTERED INDEX IX_FactEmployeeSnapshot_Grain
    ON dw_HR.FactEmployeeSnapshot (DateKey, AgencyKey, EmploymentTypeKey, DepartmentKey)
    INCLUDE (EmployeeCount, AverageHourlyWage, TotalHoursWorked, TotalPaidHours);
GO

-- Index for agency-level HR analytics
CREATE NONCLUSTERED INDEX IX_FactEmployeeSnapshot_Agency
    ON dw_HR.FactEmployeeSnapshot (AgencyKey, DateKey)
    INCLUDE (EmployeeCount, AverageHourlyWage, TotalPaidHours);
GO

-- Index for mode/service type coverage analysis
CREATE NONCLUSTERED INDEX IX_FactEmployeeSnapshot_ModeService
    ON dw_HR.FactEmployeeSnapshot (ModeKey, ServiceTypeKey, DateKey)
    INCLUDE (EmployeeCount, TotalHoursWorked);
GO

-- ============================================================
-- 3. FactAgencyLaborCoverage
--
-- GRAIN: One row per Agency × Department × Mode × ServiceType
--        × EmploymentType combination where workforce is provided
--
-- TYPE: Factless Fact Table (bridges dimensions to show coverage)
--       No measure columns; existence of row indicates workforce provision
--
-- USAGE: Determines workforce availability by classification,
--        identifies service gaps, supports capacity planning analysis.
--
-- FACT SOURCE: stg_agency_labor_coverage (one combination = one row)
-- ============================================================

IF OBJECT_ID('dw_HR.FactAgencyLaborCoverage', 'U') IS NOT NULL
    DROP TABLE dw_HR.FactAgencyLaborCoverage;
GO

CREATE TABLE dw_HR.FactAgencyLaborCoverage (

    -- Surrogate fact key (used for unique row identification)
    CoverageFactKey             BIGINT          NOT NULL    IDENTITY(1,1),

    -- Foreign keys to dimensions (all required for factless fact grain)
    DateKey                     INT             NOT NULL,    -- Effective date of coverage
    AgencyKey                   INT             NOT NULL,
    DepartmentKey               INT             NOT NULL,
    ModeKey                     INT             NOT NULL,
    ServiceTypeKey              INT             NOT NULL,
    EmploymentTypeKey           INT             NOT NULL,

    -- No measure columns in a factless fact table
    -- Existence of row = coverage exists

    -- --------------------------------------------------------
    -- Constraints
    -- --------------------------------------------------------
    CONSTRAINT PK_FactAgencyLaborCoverage
        PRIMARY KEY CLUSTERED (CoverageFactKey),

    -- Foreign key constraints
    CONSTRAINT FK_FactAgencyLaborCoverage_DateKey
        FOREIGN KEY (DateKey)
        REFERENCES dw_HR.DimDate (DateKey),
    CONSTRAINT FK_FactAgencyLaborCoverage_AgencyKey
        FOREIGN KEY (AgencyKey)
        REFERENCES dw_HR.DimAgency (AgencyKey),
    CONSTRAINT FK_FactAgencyLaborCoverage_DepartmentKey
        FOREIGN KEY (DepartmentKey)
        REFERENCES dw_HR.DimDepartment (DepartmentKey),
    CONSTRAINT FK_FactAgencyLaborCoverage_ModeKey
        FOREIGN KEY (ModeKey)
        REFERENCES dw_HR.DimMode (ModeKey),
    CONSTRAINT FK_FactAgencyLaborCoverage_ServiceTypeKey
        FOREIGN KEY (ServiceTypeKey)
        REFERENCES dw_HR.DimServiceType (ServiceTypeKey),
    CONSTRAINT FK_FactAgencyLaborCoverage_EmploymentTypeKey
        FOREIGN KEY (EmploymentTypeKey)
        REFERENCES dw_HR.DimEmploymentType (EmploymentTypeKey),

    -- Unique composite key ensures no duplicate coverage records
    CONSTRAINT UQ_FactAgencyLaborCoverage_Coverage
        UNIQUE (AgencyKey, DepartmentKey, ModeKey, ServiceTypeKey, EmploymentTypeKey)
);
GO

-- Index on grain dimensions for coverage lookups
CREATE NONCLUSTERED INDEX IX_FactAgencyLaborCoverage_Agency
    ON dw_HR.FactAgencyLaborCoverage (AgencyKey, DateKey)
    INCLUDE (DepartmentKey, ModeKey, ServiceTypeKey, EmploymentTypeKey);
GO

-- Index for mode/service availability analysis
CREATE NONCLUSTERED INDEX IX_FactAgencyLaborCoverage_ModeService
    ON dw_HR.FactAgencyLaborCoverage (ModeKey, ServiceTypeKey)
    INCLUDE (AgencyKey, EmploymentTypeKey);
GO

-- ============================================================
-- 4. FactJobPostingLifecycle
--
-- GRAIN: One row per OpeningID (accumulating snapshot)
--        Tracks complete job posting lifecycle from creation to closure
--
-- MEASURES (Additive in aggregate only; use with caution):
--   * DaysOpen: Duration from posting to closure
--   * OpenPositions: Target headcount (non-additive)
--   * HiredCount: Successfully placed candidates (additive within hiring cycle)
--   * PostingStatus: Current state (Open, Filled, Closed, etc.)
--
-- BRIDGE MEASURES: Each key (PostingDateKey, FilledDateKey, ClosingDateKey)
--                  enables drill-down to FactJobPosting for date-specific metrics
--
-- USAGE: Job posting funnel analysis, hiring cycle metrics,
--        vacancy duration trends, recruitment effectiveness.
--
-- FACT SOURCE: stg_job_posting_performance (one posting = one row)
--              Updated as posting lifecycle progresses
-- ============================================================

IF OBJECT_ID('dw_HR.FactJobPostingLifecycle', 'U') IS NOT NULL
    DROP TABLE dw_HR.FactJobPostingLifecycle;
GO

CREATE TABLE dw_HR.FactJobPostingLifecycle (

    -- Surrogate fact key
    LifecycleFactKey            BIGINT          NOT NULL    IDENTITY(1,1),

    -- Foreign keys to dimensions (required)
    AgencyKey                   INT             NOT NULL,
    ModeKey                     INT             NOT NULL,
    ServiceTypeKey              INT             NOT NULL,
    EmploymentTypeKey           INT             NOT NULL,
    DepartmentKey               INT             NOT NULL,
    JobRoleKey                  INT             NOT NULL,

    -- Degenerate dimension: natural key from source
    OpeningID                   VARCHAR(100)    NOT NULL,

    -- Bridge foreign keys: each points to a specific date in DimDate
    -- Used to drill down to FactJobPosting for date-specific details
    PostingDateKey              INT             NULL,       -- When posting was created
    FilledDateKey               INT             NULL,       -- When position was filled
    ClosingDateKey              INT             NULL,       -- When posting closed

    -- Lifecycle measures (additive with caution)
    DaysOpen                    INT             NULL,       -- Duration open
    OpenPositions               INT             NULL,       -- Target headcount (non-additive)
    HiredCount                  INT             NULL,       -- Successfully hired

    -- Status indicator
    PostingStatus               VARCHAR(50)     NULL,

    -- --------------------------------------------------------
    -- Constraints
    -- --------------------------------------------------------
    CONSTRAINT PK_FactJobPostingLifecycle
        PRIMARY KEY CLUSTERED (LifecycleFactKey),

    -- Foreign key constraints
    CONSTRAINT FK_FactJobPostingLifecycle_AgencyKey
        FOREIGN KEY (AgencyKey)
        REFERENCES dw_HR.DimAgency (AgencyKey),
    CONSTRAINT FK_FactJobPostingLifecycle_ModeKey
        FOREIGN KEY (ModeKey)
        REFERENCES dw_HR.DimMode (ModeKey),
    CONSTRAINT FK_FactJobPostingLifecycle_ServiceTypeKey
        FOREIGN KEY (ServiceTypeKey)
        REFERENCES dw_HR.DimServiceType (ServiceTypeKey),
    CONSTRAINT FK_FactJobPostingLifecycle_EmploymentTypeKey
        FOREIGN KEY (EmploymentTypeKey)
        REFERENCES dw_HR.DimEmploymentType (EmploymentTypeKey),
    CONSTRAINT FK_FactJobPostingLifecycle_DepartmentKey
        FOREIGN KEY (DepartmentKey)
        REFERENCES dw_HR.DimDepartment (DepartmentKey),
    CONSTRAINT FK_FactJobPostingLifecycle_JobRoleKey
        FOREIGN KEY (JobRoleKey)
        REFERENCES dw_HR.DimJobRole (JobRoleKey),
    CONSTRAINT FK_FactJobPostingLifecycle_PostingDateKey
        FOREIGN KEY (PostingDateKey)
        REFERENCES dw_HR.DimDate (DateKey),
    CONSTRAINT FK_FactJobPostingLifecycle_FilledDateKey
        FOREIGN KEY (FilledDateKey)
        REFERENCES dw_HR.DimDate (DateKey),
    CONSTRAINT FK_FactJobPostingLifecycle_ClosingDateKey
        FOREIGN KEY (ClosingDateKey)
        REFERENCES dw_HR.DimDate (DateKey),

    -- Measure value constraints (non-negative)
    CONSTRAINT CK_FactJobPostingLifecycle_DaysOpen
        CHECK (DaysOpen IS NULL OR DaysOpen >= 0),
    CONSTRAINT CK_FactJobPostingLifecycle_OpenPositions
        CHECK (OpenPositions IS NULL OR OpenPositions >= 0),
    CONSTRAINT CK_FactJobPostingLifecycle_HiredCount
        CHECK (HiredCount IS NULL OR HiredCount >= 0),

    -- Date range logic: FilledDate and ClosingDate should follow PostingDate
    CONSTRAINT CK_FactJobPostingLifecycle_DateSequence
        CHECK (
            PostingDateKey IS NULL
            OR FilledDateKey IS NULL
            OR FilledDateKey >= PostingDateKey
        )
);
GO

-- Index on degenerate dimension (OpeningID) for direct lookups
CREATE NONCLUSTERED INDEX IX_FactJobPostingLifecycle_OpeningID
    ON dw_HR.FactJobPostingLifecycle (OpeningID)
    INCLUDE (PostingDateKey, FilledDateKey, ClosingDateKey, DaysOpen, HiredCount);
GO

-- Index on grain dimensions for lifecycle analysis
CREATE NONCLUSTERED INDEX IX_FactJobPostingLifecycle_Grain
    ON dw_HR.FactJobPostingLifecycle (AgencyKey, EmploymentTypeKey, JobRoleKey, PostingDateKey)
    INCLUDE (DaysOpen, OpenPositions, HiredCount, PostingStatus);
GO

-- Index on date keys for time-series analysis
CREATE NONCLUSTERED INDEX IX_FactJobPostingLifecycle_Dates
    ON dw_HR.FactJobPostingLifecycle (PostingDateKey, FilledDateKey, ClosingDateKey)
    INCLUDE (DaysOpen, HiredCount);
GO

-- ============================================================
-- End of HR Fact Tables
-- ============================================================
