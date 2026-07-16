-- ============================================================
-- FILE:   03_dim_transport_DDL.sql
-- SCHEMA: dw_transport
-- DESC:   Creates transport-specific dimension tables for the
--         Transportation Data Warehouse following Kimball methodology.
--
--         NOTE: Common dimensions (DimDate, DimAgency, DimMode,
--         DimServiceType) are now in dw_common schema, created by
--         00_common_schema.sql and 01_dim_common_DDL.sql
--
-- EXECUTION ORDER: Run after 00_transport_schema.sql and
--                  01_dim_common_DDL.sql (common dimensions)
--
-- KIMBALL CONVENTIONS APPLIED:
--   Surrogate keys   : INT IDENTITY(1,1), never exposed to source
--   Natural keys     : retained as NTD_ID / UACECode / etc.
--   SCD Type 2       : DimUrbanArea
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
--       UrbanAreaKey = -1  OR  <business rule>
--     so the sentinel row is always allowed through.
-- ============================================================

USE [TransportationDB];
GO

-- ============================================================
-- TRANSPORT-SPECIFIC DIMENSIONS START HERE
-- (Common dimensions are in dw_common schema)
-- ============================================================

-- ============================================================
-- 1. DimUrbanArea
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
