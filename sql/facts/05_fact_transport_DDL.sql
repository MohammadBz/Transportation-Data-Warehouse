-- ============================================================
-- FILE:   05_fact_transport_DDL.sql
-- SCHEMA: dw_transport
-- DESC:   Creates all fact tables for the Transportation
--         Data Warehouse following Kimball methodology.
--
-- EXECUTION ORDER: Run after 03_dim_transport_DDL.sql
--
-- KIMBALL CONVENTIONS APPLIED:
--   Fact keys       : BIGINT IDENTITY(1,1) for grain uniqueness
--   Foreign keys    : INT (matching dimension surrogate keys)
--   Additive facts  : sum, count, and aggregate measures supported
--   Semi-additive   : VOMS (semi-additive: time-sensitive)
--   Non-additive    : Fares, PropertyDamage (aggregate carefully)
--   Grain           : explicit in CREATE TABLE comments + UNIQUE constraints
--   Snapshot types  : Transaction (MSE), Accumulating (SLA), Factless (SA)
--   ETL audit cols  : All fact tables include ETL_InsertDate, ETL_UpdateDate,
--                     ETL_BatchID, RecordSourceSystem for lineage tracking
--
-- DESIGN NOTES:
--   * VOMS = Vehicles Operated in Maximum Service (vehicle count, semi-additive)
--   * UrbanAreaKey is NOT NULL DEFAULT(-1) to enforce grain uniqueness
--   * Fact tables reference dimension unknown members (-1) when source lacks value
--   * Grain uniqueness enforced via UNIQUE constraints
--
-- ============================================================

USE [TransportationDB];
GO

-- ============================================================
-- 1. Fact_Annual_Service_Performance (Periodic Snapshot Fact)
--
-- GRAIN: One row per Agency + Mode + ServiceType + Date (per reporting period)
--
-- MEASURES (Additive):
--   * UPT: Unlinked Passenger Trips
--   * PMT: Passenger Miles Traveled
--   * VRM: Vehicle Revenue Miles
--   * VRH: Vehicle Revenue Hours
--   * VOMS: Vehicles Operated in Maximum Service (semi-additive: time-sensitive count)
--   * DRM: Deadhead Revenue Miles
--   * Fares: Fare Revenue (non-additive: depends on unit price)
--   * OperatingExpenseTotal: Total Operating Expenses (additive within period)
--
-- FACT SOURCE: stg_annual_performance data (NTD annual reporting)
-- ============================================================

IF OBJECT_ID('dw_transport.Fact_Annual_Service_Performance', 'U') IS NOT NULL
    DROP TABLE dw_transport.Fact_Annual_Service_Performance;
GO

CREATE TABLE dw_transport.Fact_Annual_Service_Performance (

    -- Surrogate fact key
    AnnualServicePerformanceKey BIGINT          NOT NULL    IDENTITY(1,1),

    -- Foreign keys to dimensions
    -- Use NOT NULL DEFAULT(-1) with Unknown dimension members (Kimball best practice)
    -- This prevents NULL foreign keys which complicate joins and aggregations
    DateKey                     INT             NOT NULL,
    AgencyKey                   INT             NOT NULL,
    ModeKey                     INT             NOT NULL    DEFAULT(-1),
    ServiceTypeKey              INT             NOT NULL    DEFAULT(-1),
    UrbanAreaKey                INT             NOT NULL    DEFAULT(-1),

    -- Additive measures
    UPT                         BIGINT          NULL,       -- Unlinked Passenger Trips
    PMT                         BIGINT          NULL,       -- Passenger Miles Traveled

    VRM                         BIGINT          NULL,       -- Vehicle Revenue Miles
    VRH                         BIGINT          NULL,       -- Vehicle Revenue Hours
    VOMS                        INT             NULL,       -- Vehicles Operated in Maximum Service (semi-additive)
    DRM                         BIGINT          NULL,       -- Deadhead Revenue Miles

    -- Financial measures
    Fares                       DECIMAL(18,2)   NULL,       -- Fare Revenue (non-additive)
    OperatingExpenseTotal       DECIMAL(18,2)   NULL,       -- Total Operating Expenses

    -- ETL audit columns
    ETL_InsertDate              DATETIME        NOT NULL    DEFAULT(GETDATE()),
    ETL_UpdateDate              DATETIME        NULL,
    ETL_BatchID                 BIGINT          NULL,
    RecordSourceSystem          VARCHAR(50)     NULL,

    -- --------------------------------------------------------
    -- Constraints
    -- --------------------------------------------------------
    CONSTRAINT PK_Fact_Annual_Service_Performance
        PRIMARY KEY CLUSTERED (AnnualServicePerformanceKey),

    -- GRAIN UNIQUENESS: One row per Agency + Mode + ServiceType + Date
        -- Grain does NOT include UrbanArea because an agency may report:
        --   * One primary UZA
        --   * Multiple service areas
        --   * None (UZA unknown)
        -- Grain does NOT include RecordSourceSystem (ETL metadata, not business grain)
        --   If source changes (CSV→API), same business record should not duplicate
        CONSTRAINT UQ_Fact_ASP_Grain
            UNIQUE (DateKey, AgencyKey, ModeKey, ServiceTypeKey),
    -- Foreign key constraints to dimensions
    CONSTRAINT FK_Fact_ASP_DateKey
        FOREIGN KEY (DateKey)
        REFERENCES dw_transport.DimDate (DateKey),
    CONSTRAINT FK_Fact_ASP_AgencyKey
        FOREIGN KEY (AgencyKey)
        REFERENCES dw_transport.DimAgency (AgencyKey),
    CONSTRAINT FK_Fact_ASP_ModeKey
        FOREIGN KEY (ModeKey)
        REFERENCES dw_transport.DimMode (ModeKey),
    CONSTRAINT FK_Fact_ASP_ServiceTypeKey
        FOREIGN KEY (ServiceTypeKey)
        REFERENCES dw_transport.DimServiceType (ServiceTypeKey),
    CONSTRAINT FK_Fact_ASP_UrbanAreaKey
        FOREIGN KEY (UrbanAreaKey)
        REFERENCES dw_transport.DimUrbanArea (UrbanAreaKey),

    -- Measure value constraints (non-negative)
    CONSTRAINT CK_Fact_ASP_UPT
        CHECK (UPT IS NULL OR UPT >= 0),
    CONSTRAINT CK_Fact_ASP_PMT
        CHECK (PMT IS NULL OR PMT >= 0),
    CONSTRAINT CK_Fact_ASP_VRM
        CHECK (VRM IS NULL OR VRM >= 0),
    CONSTRAINT CK_Fact_ASP_VRH
        CHECK (VRH IS NULL OR VRH >= 0),
    CONSTRAINT CK_Fact_ASP_VOMS
        CHECK (VOMS IS NULL OR VOMS >= 0),
    CONSTRAINT CK_Fact_ASP_DRM
        CHECK (DRM IS NULL OR DRM >= 0),
    CONSTRAINT CK_Fact_ASP_Fares
        CHECK (Fares IS NULL OR Fares >= 0),
    CONSTRAINT CK_Fact_ASP_OperatingExpenseTotal
        CHECK (OperatingExpenseTotal IS NULL OR OperatingExpenseTotal >= 0)
);
GO

-- Index on grain dimensions for ETL/reporting efficiency
CREATE NONCLUSTERED INDEX IX_Fact_ASP_Grain
    ON dw_transport.Fact_Annual_Service_Performance (DateKey, AgencyKey, ModeKey, ServiceTypeKey)
    INCLUDE (UPT, PMT, VRM, VRH, VOMS, DRM, Fares, OperatingExpenseTotal);
GO

-- Index for incremental ETL loading by batch
CREATE NONCLUSTERED INDEX IX_Fact_ASP_ETL_Load
    ON dw_transport.Fact_Annual_Service_Performance (ETL_BatchID)
    INCLUDE (AnnualServicePerformanceKey);
GO

-- ============================================================
-- 2. Fact_Major_Safety_Event (Transaction Fact)
--
-- GRAIN: One row per Major Safety Incident recorded in NTD
--
-- MEASURES (Additive):
--   * EventCount: Number of distinct incidents
--   * Fatality counts by category (Passenger, Employee, Other, Total)
--   * Injury counts by category (Passenger, Employee, Other, Total)
--   * VehicleInvolvedCount: Number of vehicles in incident
--   * EvacuationCount: Number of persons evacuated
--   * PropertyDamageAmount: Financial loss (non-additive)
--
-- FACT SOURCE: stg_major_safety_event (one NTD safety record = one row)
-- ============================================================

IF OBJECT_ID('dw_transport.Fact_Major_Safety_Event', 'U') IS NOT NULL
    DROP TABLE dw_transport.Fact_Major_Safety_Event;
GO

CREATE TABLE dw_transport.Fact_Major_Safety_Event (

    -- Surrogate fact key
    MajorSafetyEventKey         BIGINT          NOT NULL    IDENTITY(1,1),

    -- Foreign keys to dimensions
    -- Use NOT NULL DEFAULT(-1) with Unknown dimension members (Kimball best practice)
    -- This prevents NULL foreign keys which complicate joins and aggregations
    EventDateKey                INT             NOT NULL,
    AgencyKey                   INT             NOT NULL,
    ModeKey                     INT             NOT NULL    DEFAULT(-1),
    ServiceTypeKey              INT             NOT NULL    DEFAULT(-1),
    UrbanAreaKey                INT             NOT NULL    DEFAULT(-1),

    SafetyEventTypeKey          INT             NOT NULL,
    SafetyIncidentDescriptionKey INT             NULL,       -- References DimSafetyIncident for narrative description

    -- Degenerate dimensions: natural key and time of incident
    SourceIncidentID            VARCHAR(50)     NULL,       -- NTD's unique incident identifier (from source data)
    EventTime                   TIME            NULL,


    -- Fatality measures (additive)
    -- Store authoritative Total from source; do NOT compute from categories
    -- because source categories may not include all types (e.g., Suicide, Trespasser, etc.)
    -- Passenger + Employee + Other ≠ Reported Total if categories are incomplete
    PassengerFatalityCount      INT             NULL,
    EmployeeFatalityCount       INT             NULL,
    OtherFatalityCount          INT             NULL,
    TotalFatalityCount          INT             NULL,       -- From source, not computed

    -- Injury measures (additive)
    -- Store authoritative Total from source; do NOT compute from categories
    -- Source provides ~20 injury types (Passenger, Employee, Other, etc.)
    -- Categories shown here are subset; sum of subset ≠ Reported Total
    PassengerInjuryCount        INT             NULL,
    EmployeeInjuryCount         INT             NULL,
    OtherInjuryCount            INT             NULL,
    TotalInjuryCount            INT             NULL,       -- From source, not computed

    -- Other impact measures
    VehicleInvolvedCount        INT             NULL,
    EvacuationCount             INT             NULL,

    -- Financial impact (non-additive)
    PropertyDamageAmount        DECIMAL(18,2)   NULL,

    -- ETL audit columns
    ETL_InsertDate              DATETIME        NOT NULL    DEFAULT(GETDATE()),
    ETL_UpdateDate              DATETIME        NULL,
    ETL_BatchID                 BIGINT          NULL,
    RecordSourceSystem          VARCHAR(50)     NULL,

    -- --------------------------------------------------------
    -- Constraints
    -- --------------------------------------------------------
    CONSTRAINT PK_Fact_Major_Safety_Event
        PRIMARY KEY CLUSTERED (MajorSafetyEventKey),

    -- GRAIN UNIQUENESS: One row per NTD incident
    -- SourceIncidentID alone identifies the business fact
    -- Do NOT include RecordSourceSystem (ETL metadata, not business grain)
    -- If source changes (CSV→API), same business record should not duplicate

    -- Foreign key constraints
    CONSTRAINT FK_Fact_MSE_EventDateKey
        FOREIGN KEY (EventDateKey)
        REFERENCES dw_transport.DimDate (DateKey),
    CONSTRAINT FK_Fact_MSE_AgencyKey
        FOREIGN KEY (AgencyKey)
        REFERENCES dw_transport.DimAgency (AgencyKey),
    CONSTRAINT FK_Fact_MSE_ModeKey
        FOREIGN KEY (ModeKey)
        REFERENCES dw_transport.DimMode (ModeKey),
    CONSTRAINT FK_Fact_MSE_ServiceTypeKey
        FOREIGN KEY (ServiceTypeKey)
        REFERENCES dw_transport.DimServiceType (ServiceTypeKey),
    CONSTRAINT FK_Fact_MSE_UrbanAreaKey
        FOREIGN KEY (UrbanAreaKey)
        REFERENCES dw_transport.DimUrbanArea (UrbanAreaKey),
    CONSTRAINT FK_Fact_MSE_SafetyEventTypeKey
        FOREIGN KEY (SafetyEventTypeKey)
        REFERENCES dw_transport.DimSafetyEventType (SafetyEventTypeKey),
    CONSTRAINT FK_Fact_MSE_SafetyIncidentDescriptionKey
        FOREIGN KEY (SafetyIncidentDescriptionKey)
        REFERENCES dw_transport.DimSafetyIncident (SafetyIncidentKey),

    -- Measure value constraints (non-negative)
    CONSTRAINT CK_Fact_MSE_PassengerFatalityCount
        CHECK (PassengerFatalityCount IS NULL OR PassengerFatalityCount >= 0),
    CONSTRAINT CK_Fact_MSE_EmployeeFatalityCount
        CHECK (EmployeeFatalityCount IS NULL OR EmployeeFatalityCount >= 0),
    CONSTRAINT CK_Fact_MSE_OtherFatalityCount
        CHECK (OtherFatalityCount IS NULL OR OtherFatalityCount >= 0),
    CONSTRAINT CK_Fact_MSE_PassengerInjuryCount
        CHECK (PassengerInjuryCount IS NULL OR PassengerInjuryCount >= 0),
    CONSTRAINT CK_Fact_MSE_EmployeeInjuryCount
        CHECK (EmployeeInjuryCount IS NULL OR EmployeeInjuryCount >= 0),
    CONSTRAINT CK_Fact_MSE_OtherInjuryCount
        CHECK (OtherInjuryCount IS NULL OR OtherInjuryCount >= 0),
    CONSTRAINT CK_Fact_MSE_TotalFatalityCount
        CHECK (TotalFatalityCount IS NULL OR TotalFatalityCount >= 0),
    CONSTRAINT CK_Fact_MSE_TotalInjuryCount
        CHECK (TotalInjuryCount IS NULL OR TotalInjuryCount >= 0),
    CONSTRAINT CK_Fact_MSE_VehicleInvolvedCount
        CHECK (VehicleInvolvedCount IS NULL OR VehicleInvolvedCount >= 0),
    CONSTRAINT CK_Fact_MSE_EvacuationCount
        CHECK (EvacuationCount IS NULL OR EvacuationCount >= 0),
    CONSTRAINT CK_Fact_MSE_PropertyDamageAmount
        CHECK (PropertyDamageAmount IS NULL OR PropertyDamageAmount >= 0)
);
GO

-- Filtered unique index on source incident for ETL idempotent loading
-- Only enforces uniqueness where SourceIncidentID is NOT NULL
-- (Allows multiple rows with NULL SourceIncidentID if source didn't provide one)
CREATE UNIQUE NONCLUSTERED INDEX IX_Fact_MSE_SourceIncident
    ON dw_transport.Fact_Major_Safety_Event (SourceIncidentID)
    WHERE SourceIncidentID IS NOT NULL;
GO

-- Index on event date and agency for common drill-down queries
CREATE NONCLUSTERED INDEX IX_Fact_MSE_EventDate_Agency
    ON dw_transport.Fact_Major_Safety_Event (EventDateKey, AgencyKey)
    INCLUDE (SafetyEventTypeKey, TotalFatalityCount, TotalInjuryCount);
GO

-- Index on safety type for incident classification analysis
CREATE NONCLUSTERED INDEX IX_Fact_MSE_SafetyEventType
    ON dw_transport.Fact_Major_Safety_Event (SafetyEventTypeKey)
    INCLUDE (SafetyIncidentDescriptionKey, TotalFatalityCount, TotalInjuryCount, PropertyDamageAmount);
GO

-- Index for incremental ETL loading
CREATE NONCLUSTERED INDEX IX_Fact_MSE_ETL_Load
    ON dw_transport.Fact_Major_Safety_Event (ETL_BatchID, RecordSourceSystem)
    INCLUDE (MajorSafetyEventKey);
GO

-- ============================================================
-- 3. Fact_Service_Availability (Factless Coverage Table)
--
-- GRAIN: One row per Agency + Mode + ServiceType + StartDate + EndDate
--        representing each period when a service is actively offered.
--
-- This is a FACTLESS COVERAGE table (bridge table) that tracks
-- which services are covered/available across which date ranges.
--
-- USAGE: Determines service coverage windows for compliance reporting,
--        point-in-time service availability queries, service gap analysis.
--
-- FACT SOURCE: FACT SOURCE:
--stg_agency_mode_service
-- One row represents one declared service period
-- published by the NTD.
--
-- NOTE: Multiple non-overlapping periods are allowed for the same
--       service (start → stop → restart scenario).
-- ============================================================

IF OBJECT_ID('dw_transport.Fact_Service_Availability', 'U') IS NOT NULL
    DROP TABLE dw_transport.Fact_Service_Availability;
GO

CREATE TABLE dw_transport.Fact_Service_Availability (

    -- Surrogate fact key
    ServiceAvailabilityKey      BIGINT          NOT NULL    IDENTITY(1,1),

    -- Foreign keys to dimensions (required)
    AgencyKey                   INT             NOT NULL,
    ModeKey                     INT             NOT NULL,
    ServiceTypeKey              INT             NOT NULL,

    -- Role-playing dimensions: service lifecycle milestones
    -- (NOT degenerate dimensions - they reference DimDate)
    CommitmentDateKey           INT             NULL,       -- When service was committed/planned
    StartDateKey                INT             NOT NULL,   -- When service actually started
    EndDateKey                  INT             NOT NULL,   -- When service ended (or max date if ongoing)

    -- Indicator flag (stored from source, not computed)
    -- Values from source: 'Active Service', 'Ending Service', 'Reported Separately'
    ServiceActiveFlag           BIT             NOT NULL    DEFAULT(1),

    -- ETL audit columns
    ETL_InsertDate              DATETIME        NOT NULL    DEFAULT(GETDATE()),
    ETL_UpdateDate              DATETIME        NULL,
    ETL_BatchID                 BIGINT          NULL,
    RecordSourceSystem          VARCHAR(50)     NULL,

    -- --------------------------------------------------------
    -- Constraints
    -- --------------------------------------------------------
    CONSTRAINT PK_Fact_Service_Availability
        PRIMARY KEY CLUSTERED (ServiceAvailabilityKey),

    -- GRAIN UNIQUENESS: Prevents duplicate coverage records
    -- One row per unique Agency + Mode + ServiceType + period (StartDate + EndDate)
    CONSTRAINT UQ_Fact_SA_Grain
        UNIQUE (AgencyKey, ModeKey, ServiceTypeKey, StartDateKey, EndDateKey),

    -- Foreign key constraints
    CONSTRAINT FK_Fact_SA_AgencyKey
        FOREIGN KEY (AgencyKey)
        REFERENCES dw_transport.DimAgency (AgencyKey),
    CONSTRAINT FK_Fact_SA_ModeKey
        FOREIGN KEY (ModeKey)
        REFERENCES dw_transport.DimMode (ModeKey),
    CONSTRAINT FK_Fact_SA_ServiceTypeKey
        FOREIGN KEY (ServiceTypeKey)
        REFERENCES dw_transport.DimServiceType (ServiceTypeKey),
    CONSTRAINT FK_Fact_SA_CommitmentDateKey
        FOREIGN KEY (CommitmentDateKey)
        REFERENCES dw_transport.DimDate (DateKey),
    CONSTRAINT FK_Fact_SA_StartDateKey
        FOREIGN KEY (StartDateKey)
        REFERENCES dw_transport.DimDate (DateKey),
    CONSTRAINT FK_Fact_SA_EndDateKey
        FOREIGN KEY (EndDateKey)
        REFERENCES dw_transport.DimDate (DateKey),

    -- Date range integrity: commitment <= start <= end
    CONSTRAINT CK_Fact_SA_DateRange
        CHECK (StartDateKey <= EndDateKey AND
               (CommitmentDateKey IS NULL OR CommitmentDateKey <= StartDateKey)),

    -- ServiceActiveFlag validation
    CONSTRAINT CK_Fact_SA_ServiceActiveFlag
        CHECK (ServiceActiveFlag IN (0, 1))
);
GO

-- Index on grain dimensions for service timeline queries
CREATE NONCLUSTERED INDEX IX_Fact_SA_Grain
    ON dw_transport.Fact_Service_Availability (AgencyKey, ModeKey, ServiceTypeKey)
    INCLUDE (CommitmentDateKey, StartDateKey, EndDateKey, ServiceActiveFlag);
GO

-- Index for point-in-time service status lookups
-- Allows efficient queries like "was service X active on date Y"
CREATE NONCLUSTERED INDEX IX_Fact_SA_DateRange
    ON dw_transport.Fact_Service_Availability (StartDateKey, EndDateKey)
    INCLUDE (CommitmentDateKey, AgencyKey, ModeKey, ServiceTypeKey, ServiceActiveFlag);
GO

-- Index for incremental ETL loading
CREATE NONCLUSTERED INDEX IX_Fact_SA_ETL_Load
    ON dw_transport.Fact_Service_Availability (ETL_BatchID, RecordSourceSystem)
    INCLUDE (ServiceAvailabilityKey);
GO

-- ============================================================
-- 4. Fact_Service_Lifecycle_Accumulating (Accumulating Snapshot)
--
-- GRAIN: One row per Agency + Mode + ServiceType (entire service lifetime)
--
-- This is an ACCUMULATING SNAPSHOT fact that gets UPDATED over time
-- as service lifecycle milestones are reached (first report, peak,
-- latest report, end of service).
--
-- BRIDGE MEASURES: Each key points to a year in DimDate to enable
--                  drill-down to Fact_Annual_Service_Performance for details.
--
-- MEASURES (cumulative, updated in place):
--   * YearsInService: Duration in service
--   * Peak metrics: Annual UPT, VRM, VRH, VOMS at best year
--   * Latest metrics: Most recent annual figures
--   * Total observed: Cumulative UPT, VRM, VRH
--   * Safety metrics: Cumulative major safety events, fatalities, injuries
--   * LifecycleCompleteFlag: Service has ceased (0 = ongoing, 1 = ended)
--
-- FACT SOURCE: Aggregated from Fact_Annual_Service_Performance
--              and Fact_Major_Safety_Event (accumulated via ETL)
--
-- ETL PATTERN: Upsert on (AgencyKey, ModeKey, ServiceTypeKey) business key
--              Update audit columns on each ETL run to track changes
-- ============================================================

IF OBJECT_ID('dw_transport.Fact_Service_Lifecycle_Accumulating', 'U') IS NOT NULL
    DROP TABLE dw_transport.Fact_Service_Lifecycle_Accumulating;
GO

CREATE TABLE dw_transport.Fact_Service_Lifecycle_Accumulating (

    -- Surrogate fact key
    ServiceLifecycleKey         BIGINT          NOT NULL    IDENTITY(1,1),

    -- Foreign keys to dimensions (required)
    AgencyKey                   INT             NOT NULL,
    ModeKey                     INT             NOT NULL,
    ServiceTypeKey              INT             NOT NULL,

    -- Optional dimension reference
    UrbanAreaKey                INT             NULL,

    -- Bridge foreign keys: each points to a specific date in DimDate
    -- Used to drill down to Fact_Annual_Service_Performance for full details
    FirstObservedDateKey        INT             NULL,       -- First year service was reported
    CommitmentDateKey           INT             NULL,       -- When service was committed/planned
    PeakUPTDateKey              INT             NULL,       -- Year with highest UPT
    PeakVRMDateKey              INT             NULL,       -- Year with highest VRM
    PeakVRHDateKey              INT             NULL,       -- Year with highest VRH
    PeakVOMSDateKey             INT             NULL,       -- Year with highest VOMS
    LatestObservedDateKey       INT             NULL,       -- Most recent reporting year
    EndServiceDateKey           INT             NULL,       -- Year service ended (NULL if ongoing)

    -- Duration measure
    YearsInService              INT             NULL,

    -- Peak performance snapshot (from best-performing year for each metric)
    PeakAnnualUPT               BIGINT          NULL,
    PeakAnnualVRM               BIGINT          NULL,
    PeakAnnualVRH               BIGINT          NULL,
    PeakAnnualVOMS              INT             NULL,

    -- Latest performance snapshot (from most recent year)
    LatestAnnualUPT             BIGINT          NULL,
    LatestAnnualVRM             BIGINT          NULL,
    LatestAnnualVRH             BIGINT          NULL,
    LatestAnnualVOMS            INT             NULL,

    -- Cumulative / aggregate measures across entire observed lifetime
    TotalObservedUPT            BIGINT          NULL,
    TotalObservedVRM            BIGINT          NULL,
    TotalObservedVRH            BIGINT          NULL,

    -- Accumulated safety metrics
    TotalObservedMajorSafetyEvents  INT         NULL,
    TotalObservedFatalities         INT         NULL,
    TotalObservedInjuries           INT         NULL,

    -- Lifecycle completion flag (0 = ongoing, 1 = service has ended)
    LifecycleCompleteFlag       BIT             NOT NULL    DEFAULT(0),

    -- ETL audit columns (critical for accumulating snapshots)
    -- Track when this record was created and last updated
    ETL_InsertDate              DATETIME        NOT NULL    DEFAULT(GETDATE()),
    ETL_UpdateDate              DATETIME        NULL,
    ETL_BatchID                 BIGINT          NULL,
    RecordSourceSystem          VARCHAR(50)     NULL,

    -- --------------------------------------------------------
    -- Constraints
    -- --------------------------------------------------------
    CONSTRAINT PK_Fact_Service_Lifecycle_Accumulating
        PRIMARY KEY CLUSTERED (ServiceLifecycleKey),

    -- GRAIN UNIQUENESS: One row per Agency + Mode + ServiceType (business key)
    -- Used by ETL to identify which row to update
    CONSTRAINT UQ_Fact_SLA_BusinessKey
        UNIQUE (AgencyKey, ModeKey, ServiceTypeKey),

    -- Foreign key constraints
    CONSTRAINT FK_Fact_SLA_AgencyKey
        FOREIGN KEY (AgencyKey)
        REFERENCES dw_transport.DimAgency (AgencyKey),
    CONSTRAINT FK_Fact_SLA_ModeKey
        FOREIGN KEY (ModeKey)
        REFERENCES dw_transport.DimMode (ModeKey),
    CONSTRAINT FK_Fact_SLA_ServiceTypeKey
        FOREIGN KEY (ServiceTypeKey)
        REFERENCES dw_transport.DimServiceType (ServiceTypeKey),
    CONSTRAINT FK_Fact_SLA_UrbanAreaKey
        FOREIGN KEY (UrbanAreaKey)
        REFERENCES dw_transport.DimUrbanArea (UrbanAreaKey),
    CONSTRAINT FK_Fact_SLA_FirstObservedDateKey
        FOREIGN KEY (FirstObservedDateKey)
        REFERENCES dw_transport.DimDate (DateKey),
    CONSTRAINT FK_Fact_SLA_CommitmentDateKey
        FOREIGN KEY (CommitmentDateKey)
        REFERENCES dw_transport.DimDate (DateKey),
    CONSTRAINT FK_Fact_SLA_PeakUPTDateKey
        FOREIGN KEY (PeakUPTDateKey)
        REFERENCES dw_transport.DimDate (DateKey),
    CONSTRAINT FK_Fact_SLA_PeakVRMDateKey
        FOREIGN KEY (PeakVRMDateKey)
        REFERENCES dw_transport.DimDate (DateKey),
    CONSTRAINT FK_Fact_SLA_PeakVRHDateKey
        FOREIGN KEY (PeakVRHDateKey)
        REFERENCES dw_transport.DimDate (DateKey),
    CONSTRAINT FK_Fact_SLA_PeakVOMSDateKey
        FOREIGN KEY (PeakVOMSDateKey)
        REFERENCES dw_transport.DimDate (DateKey),
    CONSTRAINT FK_Fact_SLA_LatestObservedDateKey
        FOREIGN KEY (LatestObservedDateKey)
        REFERENCES dw_transport.DimDate (DateKey),
    CONSTRAINT FK_Fact_SLA_EndServiceDateKey
        FOREIGN KEY (EndServiceDateKey)
        REFERENCES dw_transport.DimDate (DateKey),

    -- Measure value constraints (non-negative)
    CONSTRAINT CK_Fact_SLA_YearsInService
        CHECK (YearsInService IS NULL OR YearsInService >= 0),
    CONSTRAINT CK_Fact_SLA_PeakAnnualUPT
        CHECK (PeakAnnualUPT IS NULL OR PeakAnnualUPT >= 0),
    CONSTRAINT CK_Fact_SLA_PeakAnnualVRM
        CHECK (PeakAnnualVRM IS NULL OR PeakAnnualVRM >= 0),
    CONSTRAINT CK_Fact_SLA_PeakAnnualVRH
        CHECK (PeakAnnualVRH IS NULL OR PeakAnnualVRH >= 0),
    CONSTRAINT CK_Fact_SLA_PeakAnnualVOMS
        CHECK (PeakAnnualVOMS IS NULL OR PeakAnnualVOMS >= 0),
    CONSTRAINT CK_Fact_SLA_LatestAnnualUPT
        CHECK (LatestAnnualUPT IS NULL OR LatestAnnualUPT >= 0),
    CONSTRAINT CK_Fact_SLA_LatestAnnualVRM
        CHECK (LatestAnnualVRM IS NULL OR LatestAnnualVRM >= 0),
    CONSTRAINT CK_Fact_SLA_LatestAnnualVRH
        CHECK (LatestAnnualVRH IS NULL OR LatestAnnualVRH >= 0),
    CONSTRAINT CK_Fact_SLA_LatestAnnualVOMS
        CHECK (LatestAnnualVOMS IS NULL OR LatestAnnualVOMS >= 0),
    CONSTRAINT CK_Fact_SLA_TotalObservedUPT
        CHECK (TotalObservedUPT IS NULL OR TotalObservedUPT >= 0),
    CONSTRAINT CK_Fact_SLA_TotalObservedVRM
        CHECK (TotalObservedVRM IS NULL OR TotalObservedVRM >= 0),
    CONSTRAINT CK_Fact_SLA_TotalObservedVRH
        CHECK (TotalObservedVRH IS NULL OR TotalObservedVRH >= 0),
    CONSTRAINT CK_Fact_SLA_TotalObservedMajorSafetyEvents
        CHECK (TotalObservedMajorSafetyEvents IS NULL OR TotalObservedMajorSafetyEvents >= 0),
    CONSTRAINT CK_Fact_SLA_TotalObservedFatalities
        CHECK (TotalObservedFatalities IS NULL OR TotalObservedFatalities >= 0),
    CONSTRAINT CK_Fact_SLA_TotalObservedInjuries
        CHECK (TotalObservedInjuries IS NULL OR TotalObservedInjuries >= 0),

    -- Lifecycle flag validation
    CONSTRAINT CK_Fact_SLA_LifecycleCompleteFlag
        CHECK (LifecycleCompleteFlag IN (0, 1))
);
GO

-- The UNIQUE constraint above already creates the index needed for ETL lookups.
-- No separate index creation needed.

-- Index on lifecycle status for active/discontinued service analysis
CREATE NONCLUSTERED INDEX IX_Fact_SLA_LifecycleStatus
    ON dw_transport.Fact_Service_Lifecycle_Accumulating (LifecycleCompleteFlag, LatestObservedDateKey)
    INCLUDE (AgencyKey, YearsInService, TotalObservedUPT);
GO

-- Index on bridge date keys for drill-down to annual data
CREATE NONCLUSTERED INDEX IX_Fact_SLA_BridgeDates
    ON dw_transport.Fact_Service_Lifecycle_Accumulating (FirstObservedDateKey, CommitmentDateKey, PeakUPTDateKey, PeakVRMDateKey, PeakVRHDateKey, PeakVOMSDateKey, LatestObservedDateKey);
GO

-- Index for incremental ETL loading and change tracking
CREATE NONCLUSTERED INDEX IX_Fact_SLA_ETL_Load
    ON dw_transport.Fact_Service_Lifecycle_Accumulating (ETL_UpdateDate, ETL_BatchID)
    INCLUDE (ServiceLifecycleKey, LifecycleCompleteFlag);
GO

-- ============================================================
-- END OF FACT TABLE DEFINITIONS
-- ============================================================
