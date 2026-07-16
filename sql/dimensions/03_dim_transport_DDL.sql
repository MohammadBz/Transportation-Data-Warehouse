-- ============================================================
-- FILE:   03_dim_transport_DDL.sql
-- SCHEMA: dw_transport
-- DESC:   Creates all dimension tables for the Transportation
--         Data Warehouse following Kimball methodology.
--
-- EXECUTION ORDER: Run after 00_transport_schema.sql
--
-- KIMBALL CONVENTIONS APPLIED:
--   Surrogate keys   : INT IDENTITY(1,1), never exposed to source
--   Natural keys     : retained as NTD_ID / UACECode / etc.
--   SCD Type 2       : DimAgency, DimUrbanArea
--                      (EffectiveDate / ExpirationDate / CurrentFlag)
--   Unknown member   : every dimension carries a row with key = -1
--                      so fact table FKs are never NULL
--   High-date value  : '9999-12-31' marks the currently active SCD row
--
-- DESIGN NOTES:
--   * ServiceAreaSqMiles / ServiceAreaPopulation live in DimAgency
--     (NOT DimUrbanArea) because they are agency-reported attributes
--     sourced from stg_agency_information, not Census geography.
--   * DimSafetyIncident (formerly DimSafetyEvent) holds the free-text
--     narrative for each incident.  The name was changed to avoid
--     confusion with DimSafetyEventType.
--   * VARCHAR(MAX) is avoided in dimension tables; VARCHAR(4000) is
--     used instead to keep columns index-eligible and avoid LOB storage.
--   * CHECK constraints on the unknown member row (-1) use the pattern:
--       AgencyKey = -1  OR  <business rule>
--     so the sentinel row is always allowed through.
-- ============================================================

USE [TransportationDB];
GO

-- ============================================================
-- 1. DimDate
--    Loaded from dimdates.csv via stg_dim_date.
--    No IDENTITY -- DateKey is a pre-computed YYYYMMDD integer.
--    No SCD      -- calendar attributes never change.
--    Unknown row : DateKey = -1  (calendar values set to -1)
-- ============================================================

IF OBJECT_ID('dw_transport.DimDate', 'U') IS NOT NULL
    DROP TABLE dw_transport.DimDate;
GO

CREATE TABLE dw_transport.DimDate (

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
    ON dw_transport.DimDate (FullDate)
    WHERE DateKey > -1;
GO

-- ============================================================
-- Date Dimension Data Load
-- Includes special members: Unknown (-1) and Ongoing (99991231)
-- ============================================================

-- Unknown / missing date member
INSERT INTO dw_transport.DimDate (
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
INSERT INTO dw_transport.DimDate (
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

IF OBJECT_ID('dw_transport.DimAgency', 'U') IS NOT NULL
    DROP TABLE dw_transport.DimAgency;
GO

CREATE TABLE dw_transport.DimAgency (

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
    ON dw_transport.DimAgency (NTD_ID, CurrentFlag)
    INCLUDE (AgencyKey);
GO

-- Unknown / missing agency member
SET IDENTITY_INSERT dw_transport.DimAgency ON;

INSERT INTO dw_transport.DimAgency (
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

SET IDENTITY_INSERT dw_transport.DimAgency OFF;
GO

-- ============================================================
-- 3. DimMode
--    Static reference dimension for NTD transit mode codes.
--    Pre-populated with all published NTD mode codes so ETL
--    never needs to INSERT new modes mid-load.
-- ============================================================

IF OBJECT_ID('dw_transport.DimMode', 'U') IS NOT NULL
    DROP TABLE dw_transport.DimMode;
GO

CREATE TABLE dw_transport.DimMode (

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
SET IDENTITY_INSERT dw_transport.DimMode ON;

INSERT INTO dw_transport.DimMode (ModeKey, ModeCode, ModeName)
VALUES (-1, 'N/A', 'Unknown Mode');

SET IDENTITY_INSERT dw_transport.DimMode OFF;
GO

-- All published NTD mode codes
INSERT INTO dw_transport.DimMode (ModeCode, ModeName)
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

IF OBJECT_ID('dw_transport.DimServiceType', 'U') IS NOT NULL
    DROP TABLE dw_transport.DimServiceType;
GO

CREATE TABLE dw_transport.DimServiceType (

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
SET IDENTITY_INSERT dw_transport.DimServiceType ON;

INSERT INTO dw_transport.DimServiceType (ServiceTypeKey, TOSCode, ServiceTypeName, ServiceCategory)
VALUES (-1, 'N/A', 'Unknown Service Type', NULL);

SET IDENTITY_INSERT dw_transport.DimServiceType OFF;
GO

-- Known NTD type-of-service codes
INSERT INTO dw_transport.DimServiceType (TOSCode, ServiceTypeName, ServiceCategory)
VALUES
    ('DO', 'Directly Operated',         'Direct Operations'),
    ('PT', 'Purchased Transportation',  'Contracted Operations'),
    ('TN', 'Volunteer Driver',          'Non-Traditional'),
    ('TX', 'Taxi',                      'Non-Traditional');
GO

-- ============================================================
-- 5. DimUrbanArea
--    SCD Type 2 -- UZA Census boundaries and population figures
--    are revised each decennial Census cycle.
--    UACECode is the Census Urbanized Area Code (natural key).
--
--    NOTE: ServiceAreaSqMiles / ServiceAreaPopulation have been
--    intentionally moved to DimAgency.  This table holds only
--    Census-defined geographic attributes of the UZA itself.
-- ============================================================

IF OBJECT_ID('dw_transport.DimUrbanArea', 'U') IS NOT NULL
    DROP TABLE dw_transport.DimUrbanArea;
GO

CREATE TABLE dw_transport.DimUrbanArea (

    -- Surrogate key
    UrbanAreaKey            INT             NOT NULL    IDENTITY(1,1),

    -- Natural key: Census UACE code
    UACECode                VARCHAR(50)     NOT NULL,
    UZAName                 VARCHAR(255)    NOT NULL,

    -- Census geographic attributes (revised per census cycle)
    UZASqMiles              NUMERIC(18,2)   NULL,
    UZAPopulation           BIGINT          NULL,
    UZADensity              NUMERIC(18,2)   NULL,

    -- SCD Type 2 version-tracking columns
    EffectiveDate           DATE            NOT NULL,
    ExpirationDate          DATE            NOT NULL
        CONSTRAINT DF_DimUrbanArea_ExpirationDate   DEFAULT ('9999-12-31'),
    CurrentFlag             BIT             NOT NULL
        CONSTRAINT DF_DimUrbanArea_CurrentFlag      DEFAULT (1),

    -- --------------------------------------------------------
    -- Constraints
    -- --------------------------------------------------------
    CONSTRAINT PK_DimUrbanArea
        PRIMARY KEY CLUSTERED (UrbanAreaKey),

    -- No two SCD versions for the same UZA can start on the same date
    CONSTRAINT UQ_DimUrbanArea_UACECode_EffectiveDate
        UNIQUE (UACECode, EffectiveDate),

    -- SCD date integrity
    CONSTRAINT CK_DimUrbanArea_ExpirationDate
        CHECK (ExpirationDate >= EffectiveDate),

    -- Census values must be non-negative when provided
    CONSTRAINT CK_DimUrbanArea_UZASqMiles
        CHECK (UZASqMiles IS NULL OR UZASqMiles >= 0),
    CONSTRAINT CK_DimUrbanArea_UZAPopulation
        CHECK (UZAPopulation IS NULL OR UZAPopulation >= 0),
    CONSTRAINT CK_DimUrbanArea_UZADensity
        CHECK (UZADensity IS NULL OR UZADensity >= 0)
);
GO

-- Non-clustered index on UACE code to speed up ETL lookups
CREATE NONCLUSTERED INDEX IX_DimUrbanArea_UACECode
    ON dw_transport.DimUrbanArea (UACECode, CurrentFlag)
    INCLUDE (UrbanAreaKey);
GO

-- Unknown member
SET IDENTITY_INSERT dw_transport.DimUrbanArea ON;

INSERT INTO dw_transport.DimUrbanArea (
    UrbanAreaKey,   UACECode,   UZAName,
    UZASqMiles,     UZAPopulation,  UZADensity,
    EffectiveDate,  ExpirationDate, CurrentFlag
)
VALUES (
    -1,             'N/A',      'Unknown Urban Area',
    NULL,           NULL,           NULL,
    '1900-01-01',   '9999-12-31',   1
);

SET IDENTITY_INSERT dw_transport.DimUrbanArea OFF;
GO

-- ============================================================
-- 6. DimSafetyEventType
--    Static classification dimension for incident types.
--    Derived from event_category, event_type, event_type_group,
--    and safety_security columns in stg_major_safety_event.
--    SeverityLevel = 'Safety' | 'Security' (NTD classification).
-- ============================================================

IF OBJECT_ID('dw_transport.DimSafetyEventType', 'U') IS NOT NULL
    DROP TABLE dw_transport.DimSafetyEventType;
GO

CREATE TABLE dw_transport.DimSafetyEventType (

    SafetyEventTypeKey  INT             NOT NULL    IDENTITY(1,1),

    -- Sourced from stg_major_safety_event
    EventCategory       VARCHAR(100)    NOT NULL,   -- event_category
    EventType           VARCHAR(200)    NOT NULL,   -- event_type
    EventSubType        VARCHAR(200)    NULL,       -- event_type_group
    SeverityLevel       VARCHAR(50)     NULL,       -- safety_security ('Safety' / 'Security')

    CONSTRAINT PK_DimSafetyEventType PRIMARY KEY CLUSTERED (SafetyEventTypeKey),

    CONSTRAINT CK_DimSafetyEventType_SeverityLevel
        CHECK (SeverityLevel IS NULL OR SeverityLevel IN ('Safety', 'Security'))
);
GO

-- Filtered unique index on the natural composite key.
-- A standard UNIQUE constraint is insufficient here because SQL Server
-- treats each NULL as distinct, which would allow duplicate rows that
-- differ only in NULL sub-type/severity columns.
-- The filter (SafetyEventTypeKey > 0) cleanly excludes the unknown member.
CREATE UNIQUE NONCLUSTERED INDEX UQ_DimSafetyEventType_Composite
    ON dw_transport.DimSafetyEventType (EventCategory, EventType, EventSubType, SeverityLevel)
    WHERE SafetyEventTypeKey > 0;
GO

-- ETL lookup index on Category + Type (the two most commonly joined columns)
CREATE NONCLUSTERED INDEX IX_DimSafetyEventType_Lookup
    ON dw_transport.DimSafetyEventType (EventCategory, EventType);
GO

-- Unknown member
SET IDENTITY_INSERT dw_transport.DimSafetyEventType ON;

INSERT INTO dw_transport.DimSafetyEventType (SafetyEventTypeKey, EventCategory, EventType, EventSubType, SeverityLevel)
VALUES (-1, 'Unknown', 'Unknown', NULL, NULL);

SET IDENTITY_INSERT dw_transport.DimSafetyEventType OFF;
GO

-- ============================================================
-- 7. DimSafetyIncident
--    Descriptive dimension for individual safety incidents.
--    Renamed from DimSafetyEvent to avoid confusion with
--    DimSafetyEventType.
--
--    SourceEventID  : maps to incident_number in stg_major_safety_event
--    EventDescription: free-text narrative from NTD
--
--    Type 1 dimension -- descriptions are corrected in place if
--    the NTD re-reports them (no history needed for a narrative).
--    VARCHAR(4000) instead of VARCHAR(MAX) keeps the column
--    index-eligible and avoids LOB off-row storage.
-- ============================================================

IF OBJECT_ID('dw_transport.DimSafetyIncident', 'U') IS NOT NULL
    DROP TABLE dw_transport.DimSafetyIncident;
GO

CREATE TABLE dw_transport.DimSafetyIncident (

    SafetyIncidentKey   INT             NOT NULL    IDENTITY(1,1),

    -- Natural key: incident_number from the NTD safety dataset
    SourceEventID       VARCHAR(50)     NOT NULL,
    EventDescription    VARCHAR(4000)   NULL,

    CONSTRAINT PK_DimSafetyIncident PRIMARY KEY CLUSTERED (SafetyIncidentKey),

    -- Each source incident ID must be unique (Type 1: one row per incident)
    CONSTRAINT UQ_DimSafetyIncident_SourceEventID UNIQUE (SourceEventID),

    CONSTRAINT CK_DimSafetyIncident_SourceEventID
        CHECK (SafetyIncidentKey = -1 OR LEN(TRIM(SourceEventID)) > 0)
);
GO

CREATE NONCLUSTERED INDEX IX_DimSafetyIncident_SourceEventID
    ON dw_transport.DimSafetyIncident (SourceEventID)
    INCLUDE (SafetyIncidentKey);
GO

-- Unknown member
SET IDENTITY_INSERT dw_transport.DimSafetyIncident ON;

INSERT INTO dw_transport.DimSafetyIncident (SafetyIncidentKey, SourceEventID, EventDescription)
VALUES (-1, 'N/A', 'Unknown Safety Incident');

SET IDENTITY_INSERT dw_transport.DimSafetyIncident OFF;
GO
