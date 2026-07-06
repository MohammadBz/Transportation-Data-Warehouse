-- ============================================================
-- FILE:   03_dim_HR_DDL.sql
-- SCHEMA: dw_HR
-- DESC:   Creates all dimension tables for the HR Data Warehouse
--         following Kimball methodology.
--
-- EXECUTION ORDER: Run after 00_HR_schema.sql
--
-- KIMBALL CONVENTIONS APPLIED:
--   Surrogate keys   : INT IDENTITY(1,1), never exposed to source
--   Natural keys     : retained as NTD_ID / PositionTitle / etc.
--   SCD Type 2       : DimAgency, DimJobRole
--                      (EffectiveDate / ExpirationDate / CurrentFlag)
--   Unknown member   : every dimension carries a row with key = -1
--                      so fact table FKs are never NULL
--   High-date value  : '9999-12-31' marks the currently active SCD row
--
-- DESIGN NOTES:
--   * DimDate is shared with transportation warehouse (if using same DB)
--     or loaded independently with calendar dimensions.
--   * DimAgency is SCD Type 2 to capture name/org type changes over time.
--   * DimJobRole is SCD Type 2 to track role evolution (title changes).
--   * DimEmploymentType, DimEducation, DimDepartment are static reference dims.
--   * VARCHAR(4000) is used instead of VARCHAR(MAX) to keep columns
--     index-eligible and avoid LOB off-row storage.
-- ============================================================

USE [TransportationDB];
GO

-- ============================================================
-- 1. DimDate (Shared with Transportation Warehouse)
--    If DimDate already exists in dw_transport, this table
--    can reference the same calendar. For HR-only environments,
--    load a copy with the same structure.
-- ============================================================

IF OBJECT_ID('dw_HR.DimDate', 'U') IS NULL
BEGIN
    CREATE TABLE dw_HR.DimDate (

        DateKey                         INT         NOT NULL,

        FullDate                        DATE        NOT NULL,

        DayLongName                     VARCHAR(20) NOT NULL,
        DayShortName                    VARCHAR(10) NOT NULL,

        MonthLongName                   VARCHAR(20) NOT NULL,
        MonthShortName                  VARCHAR(10) NOT NULL,

        CalendarDay                     SMALLINT    NOT NULL,
        CalendarDayInWeek               SMALLINT    NOT NULL,

        CalendarWeek                    SMALLINT    NOT NULL,
        CalendarWeekStartDateId         INT         NOT NULL,
        CalendarWeekEndDateId           INT         NOT NULL,

        CalendarMonth                   SMALLINT    NOT NULL,
        CalendarMonthStartDateId        INT         NOT NULL,
        CalendarMonthEndDateId          INT         NOT NULL,
        CalendarNumberOfDaysInMonth     SMALLINT    NOT NULL,
        CalendarDayInMonth              SMALLINT    NOT NULL,

        CalendarQuarter                 SMALLINT    NOT NULL,
        CalendarQuarterStartDateId      INT         NOT NULL,
        CalendarQuarterEndDateId        INT         NOT NULL,
        CalendarNumberOfDaysInQuarter   SMALLINT    NOT NULL,
        CalendarDayInQuarter            SMALLINT    NOT NULL,

        CalendarYear                    SMALLINT    NOT NULL,
        CalendarYearStartDateId         INT         NOT NULL,
        CalendarYearEndDateId           INT         NOT NULL,
        CalendarNumberOfDaysInYear      SMALLINT    NOT NULL,

        -- --------------------------------------------------------
        -- Constraints
        -- --------------------------------------------------------
        CONSTRAINT PK_DimDate_HR
            PRIMARY KEY CLUSTERED (DateKey),

        -- Calendar value range guards (unknown row exempt via DateKey = -1)
        CONSTRAINT CK_DimDate_HR_CalendarDay
            CHECK (DateKey = -1 OR CalendarDay BETWEEN 1 AND 31),
        CONSTRAINT CK_DimDate_HR_CalendarMonth
            CHECK (DateKey = -1 OR CalendarMonth BETWEEN 1 AND 12),
        CONSTRAINT CK_DimDate_HR_CalendarYear
            CHECK (DateKey = -1 OR CalendarYear >= 1900)
    );

    -- Unknown / missing date member
    INSERT INTO dw_HR.DimDate (
        DateKey,        FullDate,
        DayLongName,    DayShortName,   MonthLongName,  MonthShortName,
        CalendarDay,    CalendarDayInWeek,
        CalendarWeek,   CalendarWeekStartDateId,    CalendarWeekEndDateId,
        CalendarMonth,  CalendarMonthStartDateId,   CalendarMonthEndDateId,
        CalendarNumberOfDaysInMonth,    CalendarDayInMonth,
        CalendarQuarter,CalendarQuarterStartDateId, CalendarQuarterEndDateId,
        CalendarNumberOfDaysInQuarter,  CalendarDayInQuarter,
        CalendarYear,   CalendarYearStartDateId,    CalendarYearEndDateId,
        CalendarNumberOfDaysInYear
    )
    VALUES (
        -1,             '1900-01-01',
        'Unknown',      'Unk',          'Unknown',      'Unk',
        -1,             -1,
        -1,             -1,                         -1,
        -1,             -1,                         -1,
        -1,                                         -1,
        -1,             -1,                         -1,
        -1,                                         -1,
        -1,             -1,                         -1,
        -1
    );
END;
GO

-- ============================================================
-- 2. DimAgency
--    SCD Type 2 -- agencies can change name, org type, or location
--    between reporting periods.
--    NTD_ID is the business / natural key.
--    Each new version of a record gets a fresh surrogate key.
-- ============================================================

IF OBJECT_ID('dw_HR.DimAgency', 'U') IS NOT NULL
    DROP TABLE dw_HR.DimAgency;
GO

CREATE TABLE dw_HR.DimAgency (

    -- Surrogate key
    AgencyKey               INT             NOT NULL    IDENTITY(1,1),

    -- Natural / business keys
    NTD_ID                  VARCHAR(50)     NOT NULL,
    LegacyNTD_ID            VARCHAR(50)     NULL,

    -- Descriptive attributes
    AgencyName              VARCHAR(255)    NOT NULL,
    OrganizationType        VARCHAR(255)    NULL,

    City                    VARCHAR(100)    NULL,
    State                   VARCHAR(20)     NULL,
    Region                  SMALLINT        NULL,

    -- Agency-reported service footprint
    ServiceAreaSqMiles      NUMERIC(18,2)   NULL,
    ServiceAreaPopulation   BIGINT          NULL,

    -- SCD Type 2 version-tracking columns
    EffectiveDate           DATE            NOT NULL,
    ExpirationDate          DATE            NOT NULL
        CONSTRAINT DF_DimAgency_HR_ExpirationDate   DEFAULT ('9999-12-31'),
    CurrentFlag             BIT             NOT NULL
        CONSTRAINT DF_DimAgency_HR_CurrentFlag      DEFAULT (1),

    -- --------------------------------------------------------
    -- Constraints
    -- --------------------------------------------------------
    CONSTRAINT PK_DimAgency_HR
        PRIMARY KEY CLUSTERED (AgencyKey),

    -- No two SCD versions for the same agency can start on the same date
    CONSTRAINT UQ_DimAgency_HR_NTD_ID_EffectiveDate
        UNIQUE (NTD_ID, EffectiveDate),

    -- SCD date integrity
    CONSTRAINT CK_DimAgency_HR_ExpirationDate
        CHECK (ExpirationDate >= EffectiveDate),

    -- Region values
    CONSTRAINT CK_DimAgency_HR_Region
        CHECK (Region IS NULL OR Region BETWEEN 1 AND 10),

    -- Service area values must be non-negative when provided
    CONSTRAINT CK_DimAgency_HR_ServiceAreaSqMiles
        CHECK (ServiceAreaSqMiles IS NULL OR ServiceAreaSqMiles >= 0),
    CONSTRAINT CK_DimAgency_HR_ServiceAreaPopulation
        CHECK (ServiceAreaPopulation IS NULL OR ServiceAreaPopulation >= 0)
);
GO

-- Non-clustered index on NTD_ID to speed up ETL lookups
CREATE NONCLUSTERED INDEX IX_DimAgency_HR_NTD_ID
    ON dw_HR.DimAgency (NTD_ID, CurrentFlag)
    INCLUDE (AgencyKey);
GO

-- Unknown / missing agency member
SET IDENTITY_INSERT dw_HR.DimAgency ON;

INSERT INTO dw_HR.DimAgency (
    AgencyKey,  NTD_ID,     LegacyNTD_ID,   AgencyName,
    OrganizationType,       City,   State,  Region,
    ServiceAreaSqMiles,     ServiceAreaPopulation,
    EffectiveDate,          ExpirationDate, CurrentFlag
)
VALUES (
    -1,         'N/A',      NULL,           'Unknown Agency',
    NULL,                   NULL,   NULL,   NULL,
    NULL,                   NULL,
    '1900-01-01',           '9999-12-31',   1
);

SET IDENTITY_INSERT dw_HR.DimAgency OFF;
GO

-- ============================================================
-- 3. DimMode
--    Static reference dimension for transit modes.
--    Pre-populated with standard mode classifications.
-- ============================================================

IF OBJECT_ID('dw_HR.DimMode', 'U') IS NOT NULL
    DROP TABLE dw_HR.DimMode;
GO

CREATE TABLE dw_HR.DimMode (

    ModeKey     INT             NOT NULL    IDENTITY(1,1),

    -- Natural key: mode code
    ModeCode    VARCHAR(10)     NOT NULL,
    ModeName    VARCHAR(100)    NOT NULL,

    CONSTRAINT PK_DimMode_HR           PRIMARY KEY CLUSTERED (ModeKey),
    CONSTRAINT UQ_DimMode_HR_ModeCode  UNIQUE (ModeCode),

    CONSTRAINT CK_DimMode_HR_ModeCode
        CHECK (ModeKey = -1 OR LEN(TRIM(ModeCode)) > 0)
);
GO

-- Unknown member
SET IDENTITY_INSERT dw_HR.DimMode ON;

INSERT INTO dw_HR.DimMode (ModeKey, ModeCode, ModeName)
VALUES (-1, 'N/A', 'Unknown Mode');

SET IDENTITY_INSERT dw_HR.DimMode OFF;
GO

-- Standard transit mode classifications
INSERT INTO dw_HR.DimMode (ModeCode, ModeName)
VALUES
    ('MB',  'Motor Bus'),
    ('HR',  'Heavy Rail'),
    ('LR',  'Light Rail'),
    ('CR',  'Commuter Rail'),
    ('FB',  'Ferryboat'),
    ('DR',  'Demand Response'),
    ('VP',  'Vanpool'),
    ('TB',  'Trolleybus'),
    ('CB',  'Commuter Bus'),
    ('AR',  'Alaska Railroad');
GO

-- ============================================================
-- 4. DimServiceType
--    Static reference dimension for service type classifications.
-- ============================================================

IF OBJECT_ID('dw_HR.DimServiceType', 'U') IS NOT NULL
    DROP TABLE dw_HR.DimServiceType;
GO

CREATE TABLE dw_HR.DimServiceType (

    ServiceTypeKey      INT             NOT NULL    IDENTITY(1,1),

    -- Natural key: service type code
    ServiceTypeCode     VARCHAR(10)     NOT NULL,
    ServiceTypeName     VARCHAR(100)    NOT NULL,
    ServiceCategory     VARCHAR(100)    NULL,

    CONSTRAINT PK_DimServiceType_HR            PRIMARY KEY CLUSTERED (ServiceTypeKey),
    CONSTRAINT UQ_DimServiceType_HR_Code       UNIQUE (ServiceTypeCode),

    CONSTRAINT CK_DimServiceType_HR_Code
        CHECK (ServiceTypeKey = -1 OR LEN(TRIM(ServiceTypeCode)) > 0)
);
GO

-- Unknown member
SET IDENTITY_INSERT dw_HR.DimServiceType ON;

INSERT INTO dw_HR.DimServiceType (ServiceTypeKey, ServiceTypeCode, ServiceTypeName, ServiceCategory)
VALUES (-1, 'N/A', 'Unknown Service Type', NULL);

SET IDENTITY_INSERT dw_HR.DimServiceType OFF;
GO

-- Standard service type classifications
INSERT INTO dw_HR.DimServiceType (ServiceTypeCode, ServiceTypeName, ServiceCategory)
VALUES
    ('DO',  'Directly Operated',         'Direct Operations'),
    ('PT',  'Purchased Transportation',  'Contracted Operations'),
    ('TN',  'Volunteer Driver',          'Non-Traditional'),
    ('TX',  'Taxi',                      'Non-Traditional');
GO

-- ============================================================
-- 5. DimEmploymentType
--    Static reference dimension for employment classifications.
--    (Full-time, Part-time, Contract, Seasonal, etc.)
-- ============================================================

IF OBJECT_ID('dw_HR.DimEmploymentType', 'U') IS NOT NULL
    DROP TABLE dw_HR.DimEmploymentType;
GO

CREATE TABLE dw_HR.DimEmploymentType (

    EmploymentTypeKey   INT             NOT NULL    IDENTITY(1,1),

    -- Natural key: employment type code
    EmploymentTypeCode  VARCHAR(50)     NOT NULL,
    EmploymentTypeName  VARCHAR(100)    NOT NULL,
    IsFullTime          BIT             NULL,

    CONSTRAINT PK_DimEmploymentType_HR          PRIMARY KEY CLUSTERED (EmploymentTypeKey),
    CONSTRAINT UQ_DimEmploymentType_HR_Code     UNIQUE (EmploymentTypeCode),

    CONSTRAINT CK_DimEmploymentType_HR_Code
        CHECK (EmploymentTypeKey = -1 OR LEN(TRIM(EmploymentTypeCode)) > 0)
);
GO

-- Unknown member
SET IDENTITY_INSERT dw_HR.DimEmploymentType ON;

INSERT INTO dw_HR.DimEmploymentType (EmploymentTypeKey, EmploymentTypeCode, EmploymentTypeName, IsFullTime)
VALUES (-1, 'N/A', 'Unknown Employment Type', NULL);

SET IDENTITY_INSERT dw_HR.DimEmploymentType OFF;
GO

-- Standard employment type classifications
INSERT INTO dw_HR.DimEmploymentType (EmploymentTypeCode, EmploymentTypeName, IsFullTime)
VALUES
    ('FT',  'Full-Time',      1),
    ('PT',  'Part-Time',      0),
    ('CT',  'Contract',       NULL),
    ('ST',  'Seasonal',       0),
    ('TE',  'Temporary',      0);
GO

-- ============================================================
-- 6. DimDepartment
--    Static reference dimension for organizational departments.
--    NTDLaborObjectClass maps to NTD labor classification.
-- ============================================================

IF OBJECT_ID('dw_HR.DimDepartment', 'U') IS NOT NULL
    DROP TABLE dw_HR.DimDepartment;
GO

CREATE TABLE dw_HR.DimDepartment (

    DepartmentKey           INT             NOT NULL    IDENTITY(1,1),

    -- Natural key: department code
    DepartmentCode          VARCHAR(50)     NOT NULL,
    DepartmentName          VARCHAR(255)    NOT NULL,

    -- NTD labor object class for cross-reference with transport warehouse
    NTDLaborObjectClass     VARCHAR(100)    NULL,

    CONSTRAINT PK_DimDepartment_HR             PRIMARY KEY CLUSTERED (DepartmentKey),
    CONSTRAINT UQ_DimDepartment_HR_Code        UNIQUE (DepartmentCode),

    CONSTRAINT CK_DimDepartment_HR_Code
        CHECK (DepartmentKey = -1 OR LEN(TRIM(DepartmentCode)) > 0)
);
GO

-- Unknown member
SET IDENTITY_INSERT dw_HR.DimDepartment ON;

INSERT INTO dw_HR.DimDepartment (DepartmentKey, DepartmentCode, DepartmentName, NTDLaborObjectClass)
VALUES (-1, 'N/A', 'Unknown Department', NULL);

SET IDENTITY_INSERT dw_HR.DimDepartment OFF;
GO

-- ============================================================
-- 7. DimJobRole
--    SCD Type 2 -- job roles can evolve (title changes, labor category changes).
--    Tracks the history of position titles and their associated attributes.
--    PositionTitle is the natural key combined with EffectiveDate.
-- ============================================================

IF OBJECT_ID('dw_HR.DimJobRole', 'U') IS NOT NULL
    DROP TABLE dw_HR.DimJobRole;
GO

CREATE TABLE dw_HR.DimJobRole (

    -- Surrogate key
    JobRoleKey              INT             NOT NULL    IDENTITY(1,1),

    -- Natural key: position title
    PositionTitle           VARCHAR(255)    NOT NULL,

    -- Role attributes
    LaborCategory           VARCHAR(100)    NULL,
    OperatorStatus          VARCHAR(50)     NULL,

    TypicalSalaryMin        NUMERIC(18,2)   NULL,
    TypicalSalaryMax        NUMERIC(18,2)   NULL,

    -- SCD Type 2 version-tracking columns
    EffectiveDate           DATE            NOT NULL,
    ExpirationDate          DATE            NOT NULL
        CONSTRAINT DF_DimJobRole_HR_ExpirationDate   DEFAULT ('9999-12-31'),
    CurrentFlag             BIT             NOT NULL
        CONSTRAINT DF_DimJobRole_HR_CurrentFlag      DEFAULT (1),

    -- --------------------------------------------------------
    -- Constraints
    -- --------------------------------------------------------
    CONSTRAINT PK_DimJobRole_HR
        PRIMARY KEY CLUSTERED (JobRoleKey),

    -- No two SCD versions for the same job role can start on the same date
    CONSTRAINT UQ_DimJobRole_HR_PositionTitle_EffectiveDate
        UNIQUE (PositionTitle, EffectiveDate),

    -- SCD date integrity
    CONSTRAINT CK_DimJobRole_HR_ExpirationDate
        CHECK (ExpirationDate >= EffectiveDate),

    -- Salary values must be non-negative when provided
    CONSTRAINT CK_DimJobRole_HR_TypicalSalaryMin
        CHECK (TypicalSalaryMin IS NULL OR TypicalSalaryMin >= 0),
    CONSTRAINT CK_DimJobRole_HR_TypicalSalaryMax
        CHECK (TypicalSalaryMax IS NULL OR TypicalSalaryMax >= 0),
    CONSTRAINT CK_DimJobRole_HR_SalaryRange
        CHECK (TypicalSalaryMin IS NULL OR TypicalSalaryMax IS NULL OR TypicalSalaryMin <= TypicalSalaryMax)
);
GO

-- Non-clustered index on PositionTitle to speed up ETL lookups
CREATE NONCLUSTERED INDEX IX_DimJobRole_HR_PositionTitle
    ON dw_HR.DimJobRole (PositionTitle, CurrentFlag)
    INCLUDE (JobRoleKey);
GO

-- Unknown / missing job role member
SET IDENTITY_INSERT dw_HR.DimJobRole ON;

INSERT INTO dw_HR.DimJobRole (
    JobRoleKey, PositionTitle,  LaborCategory,  OperatorStatus,
    TypicalSalaryMin,   TypicalSalaryMax,
    EffectiveDate,      ExpirationDate, CurrentFlag
)
VALUES (
    -1,         'Unknown Position', NULL,       NULL,
    NULL,       NULL,
    '1900-01-01',       '9999-12-31',   1
);

SET IDENTITY_INSERT dw_HR.DimJobRole OFF;
GO

-- ============================================================
-- 8. DimEducation
--    Static reference dimension for education level classifications.
--    HierarchyLevel supports aggregation (e.g., "HS or Below" vs "Bachelor+").
-- ============================================================

IF OBJECT_ID('dw_HR.DimEducation', 'U') IS NOT NULL
    DROP TABLE dw_HR.DimEducation;
GO

CREATE TABLE dw_HR.DimEducation (

    EducationKey            INT             NOT NULL    IDENTITY(1,1),

    -- Natural key: education level code
    EducationLevelCode      VARCHAR(50)     NOT NULL,
    EducationLevel          VARCHAR(100)    NOT NULL,

    -- Hierarchy level for roll-up queries (lower = less education)
    HierarchyLevel          SMALLINT        NULL,

    CONSTRAINT PK_DimEducation_HR             PRIMARY KEY CLUSTERED (EducationKey),
    CONSTRAINT UQ_DimEducation_HR_Code        UNIQUE (EducationLevelCode),

    CONSTRAINT CK_DimEducation_HR_Code
        CHECK (EducationKey = -1 OR LEN(TRIM(EducationLevelCode)) > 0),
    CONSTRAINT CK_DimEducation_HR_HierarchyLevel
        CHECK (HierarchyLevel IS NULL OR HierarchyLevel > 0)
);
GO

-- Unknown member
SET IDENTITY_INSERT dw_HR.DimEducation ON;

INSERT INTO dw_HR.DimEducation (EducationKey, EducationLevelCode, EducationLevel, HierarchyLevel)
VALUES (-1, 'N/A', 'Unknown Education Level', NULL);

SET IDENTITY_INSERT dw_HR.DimEducation OFF;
GO

-- Standard education level classifications
INSERT INTO dw_HR.DimEducation (EducationLevelCode, EducationLevel, HierarchyLevel)
VALUES
    ('HS',   'High School',              1),
    ('AS',   'Associate''s Degree',     2),
    ('BA',   'Bachelor''s Degree',      3),
    ('MA',   'Master''s Degree',        4),
    ('PhD',  'Doctorate',               5),
    ('HS-',  'Less than High School',   0);
GO

-- ============================================================
-- End of HR Dimension Definitions
-- ============================================================
