-- ============================================================
-- FILE:   03_dim_transport_DDL.sql
-- SCHEMA: dw_transport
-- DESC:   Creates all dimension tables for the Transportation
--         Data Warehouse following Kimball methodology.
--
-- EXECUTION ORDER: Run after 00_transport_schema.sql
--
-- KIMBALL CONVENTIONS APPLIED:
--   Surrogate keys  : INT IDENTITY(1,1), never exposed to source
--   Natural keys    : retained as NTD_ID / UACECode / etc.
--   SCD Type 2      : DimAgency, DimUrbanArea
--                     (EffectiveDate / ExpirationDate / CurrentFlag)
--   Unknown member  : every dimension has a row with key = -1
--                     so fact table FKs never need to be NULL
--   High-date value : '9999-12-31' marks the currently active row
--                     in SCD Type 2 dimensions
-- ============================================================

USE [TransportationDB];
GO

-- ============================================================
-- 1. DimDate
--    Loaded directly from dimdates.csv via stg_dim_date.
--    No IDENTITY -- DateKey is a pre-computed YYYYMMDD integer.
--    No SCD -- calendar attributes never change.
--    Unknown row uses DateKey = -1.
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

    CONSTRAINT PK_DimDate PRIMARY KEY CLUSTERED (DateKey)
);
GO

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

-- ============================================================
-- 2. DimAgency
--    SCD Type 2 -- agencies can change name, city, org type,
--    or region between reporting years.
--    NTD_ID is the business / natural key from the NTD source.
--    Each version of an agency record gets a new surrogate key.
-- ============================================================

IF OBJECT_ID('dw_transport.DimAgency', 'U') IS NOT NULL
    DROP TABLE dw_transport.DimAgency;
GO

CREATE TABLE dw_transport.DimAgency (

    -- Surrogate key
    AgencyKey           INT             NOT NULL    IDENTITY(1,1),

    -- Natural / business keys
    NTD_ID              VARCHAR(50)     NOT NULL,
    LegacyNTD_ID        VARCHAR(50)     NULL,

    -- Descriptive attributes
    AgencyName          VARCHAR(255)    NOT NULL,
    OrganizationType    VARCHAR(255)    NULL,

    City                VARCHAR(100)    NULL,
    State               VARCHAR(20)     NULL,
    Region              SMALLINT        NULL,

    -- SCD Type 2 version-tracking columns
    EffectiveDate       DATE            NOT NULL,
    ExpirationDate      DATE            NOT NULL
        CONSTRAINT DF_DimAgency_ExpirationDate  DEFAULT ('9999-12-31'),
    CurrentFlag         BIT             NOT NULL
        CONSTRAINT DF_DimAgency_CurrentFlag     DEFAULT (1),

    CONSTRAINT PK_DimAgency PRIMARY KEY CLUSTERED (AgencyKey)
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
    AgencyKey,  NTD_ID,     LegacyNTD_ID,   AgencyName,
    OrganizationType,       City,   State,  Region,
    EffectiveDate,          ExpirationDate, CurrentFlag
)
VALUES (
    -1,         'N/A',      NULL,           'Unknown Agency',
    NULL,                   NULL,   NULL,   NULL,
    '1900-01-01',           '9999-12-31',   1
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
    CONSTRAINT UQ_DimMode_ModeCode  UNIQUE (ModeCode)
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
--    ServiceCategory groups DO/PT into broad operational buckets
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
    CONSTRAINT UQ_DimServiceType_TOSCode    UNIQUE (TOSCode)
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
--    SCD Type 2 -- UZA populations, boundaries, and density
--    values are revised between decennial Census cycles.
--    UACECode is the Census Urbanized Area Code (natural key).
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

    -- Transit service area attributes (reported by agencies)
    ServiceAreaSqMiles      NUMERIC(18,2)   NULL,
    ServiceAreaPopulation   BIGINT          NULL,

    -- SCD Type 2 version-tracking columns
    EffectiveDate           DATE            NOT NULL,
    ExpirationDate          DATE            NOT NULL
        CONSTRAINT DF_DimUrbanArea_ExpirationDate   DEFAULT ('9999-12-31'),
    CurrentFlag             BIT             NOT NULL
        CONSTRAINT DF_DimUrbanArea_CurrentFlag      DEFAULT (1),

    CONSTRAINT PK_DimUrbanArea PRIMARY KEY CLUSTERED (UrbanAreaKey)
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
    UrbanAreaKey,       UACECode,   UZAName,
    UZASqMiles,         UZAPopulation,  UZADensity,
    ServiceAreaSqMiles, ServiceAreaPopulation,
    EffectiveDate,      ExpirationDate, CurrentFlag
)
VALUES (
    -1,                 'N/A',      'Unknown Urban Area',
    NULL,               NULL,           NULL,
    NULL,               NULL,
    '1900-01-01',       '9999-12-31',   1
);

SET IDENTITY_INSERT dw_transport.DimUrbanArea OFF;
GO

-- ============================================================
-- 6. DimSafetyEventType
--    Static classification dimension derived from the
--    event_category, event_type, and event_type_group columns
--    in stg_major_safety_event.
--    SeverityLevel captures the Safety vs Security classification
--    stored in the safety_security column of staging.
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

    CONSTRAINT PK_DimSafetyEventType PRIMARY KEY CLUSTERED (SafetyEventTypeKey)
);
GO

-- Index to support ETL lookups on the natural composite key
CREATE NONCLUSTERED INDEX IX_DimSafetyEventType_Lookup
    ON dw_transport.DimSafetyEventType (EventCategory, EventType, EventSubType);
GO

-- Unknown member
SET IDENTITY_INSERT dw_transport.DimSafetyEventType ON;

INSERT INTO dw_transport.DimSafetyEventType (SafetyEventTypeKey, EventCategory, EventType, EventSubType, SeverityLevel)
VALUES (-1, 'Unknown', 'Unknown', NULL, NULL);

SET IDENTITY_INSERT dw_transport.DimSafetyEventType OFF;
GO

-- ============================================================
-- 7. DimSafetyEvent
--    Descriptive dimension for individual safety incidents.
--    SourceEventID maps to incident_number in stg_major_safety_event.
--    EventDescription carries the free-text narrative from the NTD.
--    This is a Type 1 dimension -- descriptions are corrected
--    in place if the source re-reports them.
-- ============================================================

IF OBJECT_ID('dw_transport.DimSafetyEvent', 'U') IS NOT NULL
    DROP TABLE dw_transport.DimSafetyEvent;
GO

CREATE TABLE dw_transport.DimSafetyEvent (

    SafetyEventKey      INT             NOT NULL    IDENTITY(1,1),

    -- Natural key: incident_number from the NTD safety dataset
    SourceEventID       VARCHAR(50)     NOT NULL,
    EventDescription    VARCHAR(MAX)    NULL,

    CONSTRAINT PK_DimSafetyEvent PRIMARY KEY CLUSTERED (SafetyEventKey)
);
GO

CREATE NONCLUSTERED INDEX IX_DimSafetyEvent_SourceEventID
    ON dw_transport.DimSafetyEvent (SourceEventID)
    INCLUDE (SafetyEventKey);
GO

-- Unknown member
SET IDENTITY_INSERT dw_transport.DimSafetyEvent ON;

INSERT INTO dw_transport.DimSafetyEvent (SafetyEventKey, SourceEventID, EventDescription)
VALUES (-1, 'N/A', 'Unknown Safety Event');

SET IDENTITY_INSERT dw_transport.DimSafetyEvent OFF;
GO
