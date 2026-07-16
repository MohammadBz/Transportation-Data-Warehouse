-- ============================================================
-- FILE:   01_dim_common_DDL.sql
-- SCHEMA: dw_common
-- DESC:   Creates common dimension tables shared across HR and
--         Transport marts. These dimensions are referenced by
--         multiple fact tables across different business domains.
--
-- TABLES:
--   - DimDate: Universal calendar dimension
--   - DimAgency: Organization reference (SCD Type 2)
--   - DimMode: Transit mode codes (static reference)
--   - DimServiceType: Type-of-Service codes (static reference)
--
-- EXECUTION ORDER: Run after 00_common_schema.sql
--
-- KIMBALL CONVENTIONS APPLIED:
--   Surrogate keys   : INT IDENTITY(1,1), never exposed to source
--   Natural keys     : retained as NTD_ID / ModeCode / TOSCode / etc.
--   SCD Type 2       : DimAgency
--                      (EffectiveDate / ExpirationDate / CurrentFlag)
--   Unknown member   : every dimension carries a row with key = -1
--                      so fact table FKs are never NULL
--   High-date value  : '9999-12-31' marks the currently active SCD row
--
-- DESIGN NOTES:
--   * ServiceAreaSqMiles / ServiceAreaPopulation live in DimAgency
--     (NOT DimUrbanArea) because they are agency-reported attributes
--     sourced from stg_agency_information, not Census geography.
--   * VARCHAR(MAX) is avoided in dimension tables; VARCHAR(4000) is
--     used instead to keep columns index-eligible and avoid LOB storage.
--   * CHECK constraints on the unknown member row (-1) use the pattern:
--       [Key] = -1  OR  <business rule>
--     so the sentinel row is always allowed through.
-- ============================================================

USE [TransportationDB];
GO

-- ============================================================
-- ETL Audit & Data Quality Logging Table
-- ============================================================

IF NOT EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_SCHEMA = 'dw_common' AND TABLE_NAME = 'etl_load_audit')
BEGIN
    CREATE TABLE dw_common.etl_load_audit (
        audit_id INT IDENTITY(1,1) PRIMARY KEY,
        procedure_name NVARCHAR(128) NOT NULL,
        load_date DATE NOT NULL,
        load_start_time DATETIME2 NOT NULL,
        load_end_time DATETIME2 NULL,
        rows_processed INT DEFAULT 0,
        rows_inserted INT DEFAULT 0,
        rows_updated INT DEFAULT 0,
        rows_deleted INT DEFAULT 0,
        duplicate_count INT DEFAULT 0,
        validation_errors NVARCHAR(MAX),
        status NVARCHAR(20) NOT NULL DEFAULT 'IN_PROGRESS', -- IN_PROGRESS, SUCCESS, FAILED
        error_message NVARCHAR(MAX),
        created_at DATETIME2 DEFAULT SYSDATETIME()
    );

    CREATE INDEX IX_etl_audit_procedure_date ON dw_common.etl_load_audit(procedure_name, load_date DESC);
END
GO

-- ============================================================
-- 1. DimDate
--    Loaded from dimdates.csv via stg_dim_date.
--    No IDENTITY -- DateKey is a pre-computed YYYYMMDD integer.
--    No SCD      -- calendar attributes never change.
--    Unknown row : DateKey = -1  (calendar values set to -1)
-- ============================================================

IF OBJECT_ID('dw_common.DimDate', 'U') IS NOT NULL
    DROP TABLE dw_common.DimDate;
GO

CREATE TABLE dw_common.DimDate (

    DateKey                         INT         NOT NULL,

    FullDate                        DATE        NOT NULL,

    DayLongName                     VARCHAR(20) NOT NULL,
    DayShortName                    VARCHAR(10) NOT NULL,

    MonthLongName                   VARCHAR(20) NOT NULL,
    MonthShortName                  VARCHAR(10) NOT NULL,

    CalendarDay                     SMALLINT    NULL,
    CalendarDayInWeek               SMALLINT    NULL,

    CalendarWeek                    SMALLINT    NULL,
    CalendarWeekStartDateId         INT         NULL,
    CalendarWeekEndDateId           INT         NULL,

    CalendarMonth                   SMALLINT    NULL,
    CalendarMonthStartDateId        INT         NULL,
    CalendarMonthEndDateId          INT         NULL,
    CalendarNumberOfDaysInMonth     SMALLINT    NULL,
    CalendarDayInMonth              SMALLINT    NULL,

    CalendarQuarter                 SMALLINT    NULL,
    CalendarQuarterStartDateId      INT         NULL,
    CalendarQuarterEndDateId        INT         NULL,
    CalendarNumberOfDaysInQuarter   SMALLINT    NULL,
    CalendarDayInQuarter            SMALLINT    NULL,

    CalendarYear                    SMALLINT    NULL,
    CalendarYearStartDateId         INT         NULL,
    CalendarYearEndDateId           INT         NOT NULL,
    CalendarNumberOfDaysInYear      SMALLINT    NOT NULL,

    -- --------------------------------------------------------
    -- Constraints
    -- --------------------------------------------------------
    CONSTRAINT PK_DimDate
        PRIMARY KEY CLUSTERED (DateKey),

    -- Each real calendar date appears exactly once.
    -- The unknown row (DateKey = -1) maps to '1900-01-01' and is
    -- excluded from uniqueness via a filtered unique index below.

    -- Calendar value range guards (unknown row exempt via DateKey = -1)
    -- CalendarDay is day-of-year: 1-366
    CONSTRAINT CK_DimDate_CalendarDay
        CHECK (DateKey = -1 OR CalendarDay IS NULL OR CalendarDay BETWEEN 1 AND 366),
    -- CalendarDayInWeek is day-of-week: 1-7
    CONSTRAINT CK_DimDate_CalendarDayInWeek
        CHECK (DateKey = -1 OR CalendarDayInWeek IS NULL OR CalendarDayInWeek BETWEEN 1 AND 7),
    -- CalendarDayInMonth is day-of-month: 1-31
    CONSTRAINT CK_DimDate_CalendarDayInMonth
        CHECK (DateKey = -1 OR CalendarDayInMonth IS NULL OR CalendarDayInMonth BETWEEN 1 AND 31),
    -- CalendarDayInQuarter is day-of-quarter: 1-92
    CONSTRAINT CK_DimDate_CalendarDayInQuarter
        CHECK (DateKey = -1 OR CalendarDayInQuarter IS NULL OR CalendarDayInQuarter BETWEEN 1 AND 92),
    -- CalendarWeek is week-of-year: 1-53
    CONSTRAINT CK_DimDate_CalendarWeek
        CHECK (DateKey = -1 OR CalendarWeek IS NULL OR CalendarWeek BETWEEN 1 AND 53),
    -- CalendarMonth is month-of-year: 1-12
    CONSTRAINT CK_DimDate_CalendarMonth
        CHECK (DateKey = -1 OR CalendarMonth IS NULL OR CalendarMonth BETWEEN 1 AND 12),
    -- CalendarQuarter is quarter-of-year: 1-4
    CONSTRAINT CK_DimDate_CalendarQuarter
        CHECK (DateKey = -1 OR CalendarQuarter IS NULL OR CalendarQuarter BETWEEN 1 AND 4),
    -- CalendarYear must be >= 1900
    CONSTRAINT CK_DimDate_CalendarYear
        CHECK (DateKey = -1 OR CalendarYear IS NULL OR CalendarYear >= 1900),
    -- CalendarNumberOfDaysInMonth: days in a month (28-31)
    CONSTRAINT CK_DimDate_DaysInMonth
        CHECK (DateKey = -1 OR CalendarNumberOfDaysInMonth IS NULL OR CalendarNumberOfDaysInMonth BETWEEN 28 AND 31),
    -- CalendarNumberOfDaysInQuarter: days in a quarter (89-92)
    CONSTRAINT CK_DimDate_DaysInQuarter
        CHECK (DateKey = -1 OR CalendarNumberOfDaysInQuarter IS NULL OR CalendarNumberOfDaysInQuarter BETWEEN 89 AND 92),
    -- CalendarNumberOfDaysInYear: days in a year (365-366)
    CONSTRAINT CK_DimDate_DaysInYear
        CHECK (DateKey = -1 OR CalendarNumberOfDaysInYear IS NULL OR CalendarNumberOfDaysInYear BETWEEN 365 AND 366),
    -- Date range constraints allow NULL on either side
    CONSTRAINT CK_DimDate_WeekStartEnd
        CHECK (DateKey = -1 OR CalendarWeekStartDateId IS NULL OR CalendarWeekEndDateId IS NULL OR CalendarWeekEndDateId >= CalendarWeekStartDateId),
    CONSTRAINT CK_DimDate_MonthStartEnd
        CHECK (DateKey = -1 OR CalendarMonthStartDateId IS NULL OR CalendarMonthEndDateId IS NULL OR CalendarMonthEndDateId >= CalendarMonthStartDateId),
    CONSTRAINT CK_DimDate_QuarterStartEnd
        CHECK (DateKey = -1 OR CalendarQuarterStartDateId IS NULL OR CalendarQuarterEndDateId IS NULL OR CalendarQuarterEndDateId >= CalendarQuarterStartDateId),
    CONSTRAINT CK_DimDate_YearStartEnd
        CHECK (DateKey = -1 OR CalendarYearStartDateId IS NULL OR CalendarYearEndDateId >= CalendarYearStartDateId)
);
GO

-- Filtered unique index: every real date row must be unique;
-- the unknown sentinel row (DateKey = -1) is excluded.
CREATE UNIQUE NONCLUSTERED INDEX UQ_DimDate_FullDate
    ON dw_common.DimDate (FullDate)
    WHERE DateKey > -1;
GO

-- ============================================================
-- Date Dimension Data Load
-- Includes special members: Unknown (-1) and Ongoing (99991231)
-- ============================================================

-- Unknown / missing date member
INSERT INTO dw_common.DimDate (
    DateKey,        FullDate,
    DayLongName,    DayShortName,   MonthLongName,              MonthShortName,
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
    'Unknown',      'Unk',          'Unknown',                  'Unk',
    -1,             -1,
    -1,             -1,                         -1,
    -1,             -1,                         -1,
    -1,                                         -1,
    -1,             -1,                         -1,
    -1,                                         -1,
    -1,             -1,                         -1,
    -1
);
GO

-- Special date member for open-ended/ongoing dates (e.g., active services with no end date)
INSERT INTO dw_common.DimDate (
    DateKey,        FullDate,
    DayLongName,    DayShortName,   MonthLongName,              MonthShortName,
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
    99991231,       '9999-12-31',
    'December',     'Dec',          'December',                 'Dec',
    365,            3,
    53,             99991224,                   99991231,
    12,             99991201,                   99991231,
    31,                                         31,
    4,              99991001,                   99991231,
    92,             92,
    9999,           99990101,                   99991231,
    365
);
GO

-- ============================================================
-- 2. DimAgency
--    SCD Type 2 -- agencies can change name, city, org type,
--    or service area between reporting years.
--    NTD_ID is the business / natural key from NTD.
--    Each new version of a record gets a fresh surrogate key.
--
--    ServiceAreaSqMiles and ServiceAreaPopulation are placed here
--    (not in DimUrbanArea) because they are agency-self-reported
--    values from stg_agency_information -- not Census geography.
-- ============================================================

IF OBJECT_ID('dw_common.DimAgency', 'U') IS NOT NULL
    DROP TABLE dw_common.DimAgency;
GO

CREATE TABLE dw_common.DimAgency (

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
    -- (sourced from stg_agency_information.service_area_sq_miles / service_area_pop)
    ServiceAreaSqMiles      NUMERIC(18,2)   NULL,
    ServiceAreaPopulation   BIGINT          NULL,

    -- SCD Type 2 version-tracking columns
    EffectiveDate           DATE            NOT NULL,
    ExpirationDate          DATE            NOT NULL
        CONSTRAINT DF_DimAgency_ExpirationDate  DEFAULT ('9999-12-31'),
    CurrentFlag             BIT             NOT NULL
        CONSTRAINT DF_DimAgency_CurrentFlag     DEFAULT (1),

    -- --------------------------------------------------------
    -- Constraints
    -- --------------------------------------------------------
    CONSTRAINT PK_DimAgency
        PRIMARY KEY CLUSTERED (AgencyKey),

    -- No two SCD versions for the same agency can start on the same date
    CONSTRAINT UQ_DimAgency_NTD_ID_EffectiveDate
        UNIQUE (NTD_ID, EffectiveDate),

    -- SCD date integrity
    CONSTRAINT CK_DimAgency_ExpirationDate
        CHECK (ExpirationDate >= EffectiveDate),

    -- FTA defines regions 1-10
    CONSTRAINT CK_DimAgency_Region
        CHECK (Region IS NULL OR Region BETWEEN 1 AND 10),

    -- Service area values must be non-negative when provided
    CONSTRAINT CK_DimAgency_ServiceAreaSqMiles
        CHECK (ServiceAreaSqMiles IS NULL OR ServiceAreaSqMiles >= 0),
    CONSTRAINT CK_DimAgency_ServiceAreaPopulation
        CHECK (ServiceAreaPopulation IS NULL OR ServiceAreaPopulation >= 0)
);
GO

-- Non-clustered index on NTD_ID to speed up ETL lookups
CREATE NONCLUSTERED INDEX IX_DimAgency_NTD_ID
    ON dw_common.DimAgency (NTD_ID, CurrentFlag)
    INCLUDE (AgencyKey);
GO

-- Unknown / missing agency member
SET IDENTITY_INSERT dw_common.DimAgency ON;

INSERT INTO dw_common.DimAgency (
    AgencyKey,  NTD_ID,         LegacyNTD_ID,   AgencyName,
    OrganizationType,           City,   State,  Region,
    ServiceAreaSqMiles,         ServiceAreaPopulation,
    EffectiveDate,              ExpirationDate, CurrentFlag
)
VALUES (
    -1,         'N/A',          NULL,           'Unknown Agency',
    NULL,                       NULL,   NULL,   NULL,
    NULL,                       NULL,
    '1900-01-01',               '9999-12-31',   1
);

SET IDENTITY_INSERT dw_common.DimAgency OFF;
GO

-- ============================================================
-- 3. DimMode
--    Static reference dimension for NTD transit mode codes.
--    Pre-populated with all published NTD mode codes so ETL
--    never needs to INSERT new modes mid-load.
-- ============================================================

IF OBJECT_ID('dw_common.DimMode', 'U') IS NOT NULL
    DROP TABLE dw_common.DimMode;
GO

CREATE TABLE dw_common.DimMode (

    ModeKey     INT             NOT NULL    IDENTITY(1,1),

    -- Natural key: 2-letter NTD mode code
    ModeCode    VARCHAR(10)     NOT NULL,
    ModeName    VARCHAR(100)    NOT NULL,

    CONSTRAINT PK_DimMode           PRIMARY KEY CLUSTERED (ModeKey),
    CONSTRAINT UQ_DimMode_ModeCode  UNIQUE (ModeCode),

    CONSTRAINT CK_DimMode_ModeCode
        CHECK (ModeKey = -1 OR LEN(TRIM(ModeCode)) > 0)
);
GO

-- Unknown member
SET IDENTITY_INSERT dw_common.DimMode ON;

INSERT INTO dw_common.DimMode (ModeKey, ModeCode, ModeName)
VALUES (-1, 'N/A', 'Unknown Mode');

SET IDENTITY_INSERT dw_common.DimMode OFF;
GO

-- All published NTD mode codes
INSERT INTO dw_common.DimMode (ModeCode, ModeName)
VALUES
    ('AR',  'Alaska Railroad'),
    ('CB',  'Commuter Bus'),
    ('CC',  'Cable Car'),
    ('CR',  'Commuter Rail'),
    ('DR',  'Demand Response'),
    ('DT',  'Demand Response Taxi'),
    ('EB',  'Electric Bus'),
    ('FB',  'Ferryboat'),
    ('HR',  'Heavy Rail'),
    ('IP',  'Inclined Plane'),
    ('LR',  'Light Rail'),
    ('MB',  'Motor Bus'),
    ('MG',  'Monorail / Automated Guideway'),
    ('OR',  'Other Rail'),
    ('PB',  'Publico'),
    ('RB',  'Bus Rapid Transit'),
    ('SR',  'Streetcar Rail'),
    ('TB',  'Trolleybus'),
    ('TR',  'Aerial Tramway'),
    ('VP',  'Vanpool'),
    ('YR',  'Hybrid Rail');
GO

-- ============================================================
-- 4. DimServiceType
--    Static reference dimension for NTD Type-of-Service codes.
--    ServiceCategory groups codes into broad operational buckets
--    to support roll-up analysis.
-- ============================================================

IF OBJECT_ID('dw_common.DimServiceType', 'U') IS NOT NULL
    DROP TABLE dw_common.DimServiceType;
GO

CREATE TABLE dw_common.DimServiceType (

    ServiceTypeKey      INT             NOT NULL    IDENTITY(1,1),

    -- Natural key: 2-letter NTD TOS code
    TOSCode             VARCHAR(10)     NOT NULL,
    ServiceTypeName     VARCHAR(100)    NOT NULL,
    ServiceCategory     VARCHAR(100)    NULL,

    CONSTRAINT PK_DimServiceType            PRIMARY KEY CLUSTERED (ServiceTypeKey),
    CONSTRAINT UQ_DimServiceType_TOSCode    UNIQUE (TOSCode),

    CONSTRAINT CK_DimServiceType_TOSCode
        CHECK (ServiceTypeKey = -1 OR LEN(TRIM(TOSCode)) > 0)
);
GO

-- Unknown member
SET IDENTITY_INSERT dw_common.DimServiceType ON;

INSERT INTO dw_common.DimServiceType (ServiceTypeKey, TOSCode, ServiceTypeName, ServiceCategory)
VALUES (-1, 'N/A', 'Unknown Service Type', NULL);

SET IDENTITY_INSERT dw_common.DimServiceType OFF;
GO

-- Known NTD type-of-service codes
INSERT INTO dw_common.DimServiceType (TOSCode, ServiceTypeName, ServiceCategory)
VALUES
    ('DO', 'Directly Operated',         'Direct Operations'),
    ('PT', 'Purchased Transportation',  'Contracted Operations'),
    ('TN', 'Volunteer Driver',          'Non-Traditional'),
    ('TX', 'Taxi',                      'Non-Traditional');
GO
