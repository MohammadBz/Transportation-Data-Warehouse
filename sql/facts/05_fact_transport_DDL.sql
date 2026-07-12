
USE [TransportationDB];
GO

-- ============================================================
-- 1. FactJobPosting (Transaction Fact Table)
-- GRAIN: One row per unique OpeningID transaction
-- ============================================================
IF OBJECT_ID('dw_HR.FactJobPosting', 'U') IS NOT NULL
    DROP TABLE dw_HR.FactJobPosting;
GO

CREATE TABLE dw_HR.FactJobPosting (
    -- Surrogate fact key
    JobPostingFactKey           BIGINT          NOT NULL    IDENTITY(1,1),

    -- Foreign keys to dimensions (Kimball Pattern: DEFAULT -1 for unknown alignment)
    DateKey                     INT             NOT NULL    DEFAULT(-1),
    AgencyKey                   INT             NOT NULL    DEFAULT(-1),
    ModeKey                     INT             NOT NULL    DEFAULT(-1),
    ServiceTypeKey              INT             NOT NULL    DEFAULT(-1),
    EmploymentTypeKey           INT             NOT NULL    DEFAULT(-1),
    DepartmentKey               INT             NOT NULL    DEFAULT(-1),
    JobRoleKey                  INT             NOT NULL    DEFAULT(-1),

    -- Degenerate Dimension
    OpeningID                   VARCHAR(50)     NOT NULL,

    -- Additive Measures
    OpenPositions               INT             NOT NULL    DEFAULT(1),
    SalaryMinHourly             DECIMAL(18,2)   NULL,
    SalaryMaxHourly             DECIMAL(18,2)   NULL,
    SalaryMidHourly             DECIMAL(18,2)   NULL,
    DaysOpen                    INT             NULL,
    HiredCount                  INT             NOT NULL    DEFAULT(0),

    -- Degenerate Attributes
    PostingStatus               VARCHAR(50)     NULL,
    VacancyReason               VARCHAR(255)    NULL,

    -- ETL audit columns
    ETL_InsertDate              DATETIME        NOT NULL    DEFAULT(GETDATE()),
    ETL_UpdateDate              DATETIME        NULL,
    ETL_BatchID                 INT             NULL,
    RecordSourceSystem          VARCHAR(50)     NULL,

    CONSTRAINT PK_FactJobPosting PRIMARY KEY CLUSTERED (JobPostingFactKey),
    CONSTRAINT UQ_FactJobPosting_Grain UNIQUE (OpeningID),

    -- Foreign key constraints
    CONSTRAINT FK_FactJobPosting_DimDate FOREIGN KEY (DateKey) REFERENCES dw_HR.DimDate(DateKey),
    CONSTRAINT FK_FactJobPosting_DimAgency FOREIGN KEY (AgencyKey) REFERENCES dw_HR.DimAgency(AgencyKey),
    CONSTRAINT FK_FactJobPosting_DimMode FOREIGN KEY (ModeKey) REFERENCES dw_HR.DimMode(ModeKey),
    CONSTRAINT FK_FactJobPosting_DimServiceType FOREIGN KEY (ServiceTypeKey) REFERENCES dw_HR.DimServiceType(ServiceTypeKey),
    CONSTRAINT FK_FactJobPosting_DimEmploymentType FOREIGN KEY (EmploymentTypeKey) REFERENCES dw_HR.DimEmploymentType(EmploymentTypeKey),
    CONSTRAINT FK_FactJobPosting_DimDepartment FOREIGN KEY (DepartmentKey) REFERENCES dw_HR.DimDepartment(DepartmentKey),
    CONSTRAINT FK_FactJobPosting_DimJobRole FOREIGN KEY (JobRoleKey) REFERENCES dw_HR.DimJobRole(JobRoleKey),

    -- Value Range Constraints
    CONSTRAINT CK_FactJobPosting_OpenPositions CHECK (OpenPositions >= 0),
    CONSTRAINT CK_FactJobPosting_SalaryMin CHECK (SalaryMinHourly IS NULL OR SalaryMinHourly >= 0),
    CONSTRAINT CK_FactJobPosting_SalaryMax CHECK (SalaryMaxHourly IS NULL OR SalaryMaxHourly >= 0),
    CONSTRAINT CK_FactJobPosting_SalaryMid CHECK (SalaryMidHourly IS NULL OR SalaryMidHourly >= 0),
    CONSTRAINT CK_FactJobPosting_DaysOpen CHECK (DaysOpen IS NULL OR DaysOpen >= 0),
    CONSTRAINT CK_FactJobPosting_HiredCount CHECK (HiredCount >= 0)
);
GO

-- NCI Grain Index for Reporting Efficiency
CREATE NONCLUSTERED INDEX IX_FactJobPosting_Reporting
ON dw_HR.FactJobPosting (DateKey, AgencyKey, JobRoleKey)
INCLUDE (OpenPositions, HiredCount, SalaryMidHourly);
GO


-- ============================================================
-- 2. FactEmployeeSnapshot (Periodic Snapshot Fact Table)
-- GRAIN: One row per Year * Agency * Mode * ServiceType * EmploymentType * Department * JobRole
-- ============================================================
IF OBJECT_ID('dw_HR.FactEmployeeSnapshot', 'U') IS NOT NULL
    DROP TABLE dw_HR.FactEmployeeSnapshot;
GO

CREATE TABLE dw_HR.FactEmployeeSnapshot (
    SnapshotFactKey             BIGINT          NOT NULL    IDENTITY(1,1),
    DateKey                     INT             NOT NULL, -- Sourced from Year/ReportYear mapping
    AgencyKey                   INT             NOT NULL    DEFAULT(-1),
    ModeKey                     INT             NOT NULL    DEFAULT(-1),
    ServiceTypeKey              INT             NOT NULL    DEFAULT(-1),
    EmploymentTypeKey           INT             NOT NULL    DEFAULT(-1),
    DepartmentKey               INT             NOT NULL    DEFAULT(-1),
    JobRoleKey                  INT             NOT NULL    DEFAULT(-1),

    -- Semi-Additive Measures
    EmployeeCount               INT             NOT NULL,
    TotalHoursWorked            DECIMAL(18,2)   NOT NULL,

    -- ETL audit columns
    ETL_InsertDate              DATETIME        NOT NULL    DEFAULT(GETDATE()),
    ETL_UpdateDate              DATETIME        NULL,
    ETL_BatchID                 INT             NULL,
    RecordSourceSystem          VARCHAR(50)     NULL,

    CONSTRAINT PK_FactEmployeeSnapshot PRIMARY KEY CLUSTERED (SnapshotFactKey),
    CONSTRAINT UQ_FactEmployeeSnapshot_Grain UNIQUE (DateKey, AgencyKey, ModeKey, ServiceTypeKey, EmploymentTypeKey, DepartmentKey, JobRoleKey),

    -- Foreign key constraints
    CONSTRAINT FK_FactEmployeeSnapshot_DimDate FOREIGN KEY (DateKey) REFERENCES dw_HR.DimDate(DateKey),
    CONSTRAINT FK_FactEmployeeSnapshot_DimAgency FOREIGN KEY (AgencyKey) REFERENCES dw_HR.DimAgency(AgencyKey),
    CONSTRAINT FK_FactEmployeeSnapshot_DimMode FOREIGN KEY (ModeKey) REFERENCES dw_HR.DimMode(ModeKey),
    CONSTRAINT FK_FactEmployeeSnapshot_DimServiceType FOREIGN KEY (ServiceTypeKey) REFERENCES dw_HR.DimServiceType(ServiceTypeKey),
    CONSTRAINT FK_FactEmployeeSnapshot_DimEmploymentType FOREIGN KEY (EmploymentTypeKey) REFERENCES dw_HR.DimEmploymentType(EmploymentTypeKey),
    CONSTRAINT FK_FactEmployeeSnapshot_DimDepartment FOREIGN KEY (DepartmentKey) REFERENCES dw_HR.DimDepartment(DepartmentKey),
    CONSTRAINT FK_FactEmployeeSnapshot_DimJobRole FOREIGN KEY (JobRoleKey) REFERENCES dw_HR.DimJobRole(JobRoleKey),

    CONSTRAINT CK_FactEmployeeSnapshot_EmpCount CHECK (EmployeeCount >= 0),
    CONSTRAINT CK_FactEmployeeSnapshot_Hours CHECK (TotalHoursWorked >= 0)
);
GO


-- ============================================================
-- 3. FactAgencyLaborCoverage (Factless Coverage Fact Table)
-- GRAIN: One row per Unique Workforce Coverage mapping (Presence Indicator)
-- ============================================================
IF OBJECT_ID('dw_HR.FactAgencyLaborCoverage', 'U') IS NOT NULL
    DROP TABLE dw_HR.FactAgencyLaborCoverage;
GO

CREATE TABLE dw_HR.FactAgencyLaborCoverage (
    CoverageFactKey             BIGINT          NOT NULL    IDENTITY(1,1),
    DateKey                     INT             NOT NULL,
    AgencyKey                   INT             NOT NULL    DEFAULT(-1),
    DepartmentKey               INT             NOT NULL    DEFAULT(-1),
    ModeKey                     INT             NOT NULL    DEFAULT(-1),
    ServiceTypeKey              INT             NOT NULL    DEFAULT(-1),
    EmploymentTypeKey           INT             NOT NULL    DEFAULT(-1),

    -- ETL audit columns
    ETL_InsertDate              DATETIME        NOT NULL    DEFAULT(GETDATE()),
    ETL_UpdateDate              DATETIME        NULL,
    ETL_BatchID                 INT             NULL,
    RecordSourceSystem          VARCHAR(50)     NULL,

    CONSTRAINT PK_FactAgencyLaborCoverage PRIMARY KEY CLUSTERED (CoverageFactKey),
    CONSTRAINT UQ_FactAgencyLaborCoverage_Grain UNIQUE (DateKey, AgencyKey, DepartmentKey, ModeKey, ServiceTypeKey, EmploymentTypeKey),

    -- Foreign key constraints
    CONSTRAINT FK_FactAgencyLaborCoverage_DimDate FOREIGN KEY (DateKey) REFERENCES dw_HR.DimDate(DateKey),
    CONSTRAINT FK_FactAgencyLaborCoverage_DimAgency FOREIGN KEY (AgencyKey) REFERENCES dw_HR.DimAgency(AgencyKey),
    CONSTRAINT FK_FactAgencyLaborCoverage_DimDepartment FOREIGN KEY (DepartmentKey) REFERENCES dw_HR.DimDepartment(DepartmentKey),
    CONSTRAINT FK_FactAgencyLaborCoverage_DimMode FOREIGN KEY (ModeKey) REFERENCES dw_HR.DimMode(ModeKey),
    CONSTRAINT FK_FactAgencyLaborCoverage_DimServiceType FOREIGN KEY (ServiceTypeKey) REFERENCES dw_HR.DimServiceType(ServiceTypeKey),
    CONSTRAINT FK_FactAgencyLaborCoverage_DimEmploymentType FOREIGN KEY (EmploymentTypeKey) REFERENCES dw_HR.DimEmploymentType(EmploymentTypeKey)
);
GO


-- ============================================================
-- 4. FactJobPostingLifecycle (Accumulating Snapshot Fact Table)
-- GRAIN: One row per unique OpeningID (Updated dynamically throughout milestones)
-- ============================================================
IF OBJECT_ID('dw_HR.FactJobPostingLifecycle', 'U') IS NOT NULL
    DROP TABLE dw_HR.FactJobPostingLifecycle;
GO

CREATE TABLE dw_HR.FactJobPostingLifecycle (
    LifecycleFactKey            BIGINT          NOT NULL    IDENTITY(1,1),
    AgencyKey                   INT             NOT NULL    DEFAULT(-1),
    ModeKey                     INT             NOT NULL    DEFAULT(-1),
    ServiceTypeKey              INT             NOT NULL    DEFAULT(-1),
    EmploymentTypeKey           INT             NOT NULL    DEFAULT(-1),
    DepartmentKey               INT             NOT NULL    DEFAULT(-1),
    JobRoleKey                  INT             NOT NULL    DEFAULT(-1),

    -- Business Key
    OpeningID                   VARCHAR(50)     NOT NULL,

    -- Milestone Role-Playing Dates
    PostingDateKey              INT             NOT NULL    DEFAULT(-1),
    FilledDateKey               INT             NOT NULL    DEFAULT(-1),
    ClosingDateKey              INT             NOT NULL    DEFAULT(-1),

    -- Measures
    DaysOpen                    INT             NULL,
    HiredCount                  INT             NOT NULL    DEFAULT(0),
    PostingStatus               VARCHAR(50)     NULL,

    -- ETL audit columns
    ETL_InsertDate              DATETIME        NOT NULL    DEFAULT(GETDATE()),
    ETL_UpdateDate              DATETIME        NULL,
    ETL_BatchID                 INT             NULL,
    RecordSourceSystem          VARCHAR(50)     NULL,

    CONSTRAINT PK_FactJobPostingLifecycle PRIMARY KEY CLUSTERED (LifecycleFactKey),
    CONSTRAINT UQ_FactJobPostingLifecycle_Grain UNIQUE (OpeningID),

    -- Foreign key constraints
    CONSTRAINT FK_FactJobPostingLifecycle_DimAgency FOREIGN KEY (AgencyKey) REFERENCES dw_HR.DimAgency(AgencyKey),
    CONSTRAINT FK_FactJobPostingLifecycle_DimMode FOREIGN KEY (ModeKey) REFERENCES dw_HR.DimMode(ModeKey),
    CONSTRAINT FK_FactJobPostingLifecycle_DimServiceType FOREIGN KEY (ServiceTypeKey) REFERENCES dw_HR.DimServiceType(ServiceTypeKey),
    CONSTRAINT FK_FactJobPostingLifecycle_DimEmploymentType FOREIGN KEY (EmploymentTypeKey) REFERENCES dw_HR.DimEmploymentType(EmploymentTypeKey),
    CONSTRAINT FK_FactJobPostingLifecycle_DimDepartment FOREIGN KEY (DepartmentKey) REFERENCES dw_HR.DimDepartment(DepartmentKey),
    CONSTRAINT FK_FactJobPostingLifecycle_DimJobRole FOREIGN KEY (JobRoleKey) REFERENCES dw_HR.DimJobRole(JobRoleKey),
    CONSTRAINT FK_FactJobPostingLifecycle_PostingDate FOREIGN KEY (PostingDateKey) REFERENCES dw_HR.DimDate(DateKey),
    CONSTRAINT FK_FactJobPostingLifecycle_FilledDate FOREIGN KEY (FilledDateKey) REFERENCES dw_HR.DimDate(DateKey),
    CONSTRAINT FK_FactJobPostingLifecycle_ClosingDate FOREIGN KEY (ClosingDateKey) REFERENCES dw_HR.DimDate(DateKey),

    CONSTRAINT CK_FactJobPostingLifecycle_Days CHECK (DaysOpen IS NULL OR DaysOpen >= 0),
    CONSTRAINT CK_FactJobPostingLifecycle_Hired CHECK (HiredCount >= 0)
);
GO

-- Index for Incremental Updates and Lookups on Accumulating Snapshot
CREATE NONCLUSTERED INDEX IX_FactJobPostingLifecycle_ETL
ON dw_HR.FactJobPostingLifecycle (OpeningID)
INCLUDE (PostingStatus, HiredCount, DaysOpen);
GO
