-- ============================================================
-- FILE:   05_fact_transport_DDL.sql
-- SCHEMA: dw_transport
-- DESC:   Creates all fact tables for the Transportation
--         Data Warehouse following Kimball methodology.
--
-- EXECUTION ORDER: Run after 03_dim_transport_DDL.sql
--
-- KIMBALL CONVENTIONS APPLIED:
--   Fact keys       : BIGINT IDENTITY(1,1) for fact grain uniqueness
--   Foreign keys    : INT (matching dimension surrogate keys)
--   Additive facts  : sum, count, and aggregate measures supported
--   Semi-additive   : VOMS and other inventory measures (careful with time)
--   Non-additive    : Fares, rates, per-unit costs (aggregate carefully)
--   Grain           : explicit in CREATE TABLE comments
--   Slowly Changing : Fact tables are Type 1 (no history / versions)
--   Nullability     : FK columns NOT NULL for required dimensions,
--                     NULL for optional/degenerate dimensions
--
-- DESIGN NOTES:
--   * Fact tables reference dimension unknown members (-1) when
--     source data lacks a valid dimension value.
--   * Numeric measures use BIGINT (counts), DECIMAL(18,2) (money/distance),
--     SMALLINT (vehicle counts), or INT (derived counts).
--   * Fact keys are not exposed to ETL; they are internal surrogates.
--   * Grain is explicit per fact table to prevent double-counting.
--
-- ============================================================

USE [TransportationDB];
GO

-- ============================================================
-- 1. Fact_Annual_Service_Performance
--
-- GRAIN: One row per Agency + Mode + ServiceType + FiscalYear
--
-- MEASURES (Additive):
--   * UPT: Unlinked Passenger Trips
--   * PMT: Passenger Miles Traveled
--   * VRM: Vehicle Revenue Miles
--   * VRH: Vehicle Revenue Hours
--   * VOMS: Vehicle Operating and Maintenance Spend (semi-additive: time-sensitive)
--   * DRM: Deadhead Revenue Miles
--   * Fares: Fare Revenue (non-additive: depends on unit price)
--   * OperatingExpenseTotal: Total Operating Expenses (additive within year)
--
-- FACT SOURCE: Aggregated from stg_annual_performance data
-- ============================================================

IF OBJECT_ID('dw_transport.Fact_Annual_Service_Performance', 'U') IS NOT NULL
    DROP TABLE dw_transport.Fact_Annual_Service_Performance;
GO

CREATE TABLE dw_transport.Fact_Annual_Service_Performance (

    -- Surrogate fact key
    AnnualServicePerformanceKey BIGINT          NOT NULL    IDENTITY(1,1),

    -- Foreign keys to dimensions (NOT NULL for required dimensions)
    DateKey                     INT             NOT NULL,
    AgencyKey                   INT             NOT NULL,
    ModeKey                     INT             NOT NULL,
    ServiceTypeKey              INT             NOT NULL,

    -- Optional dimension reference (can be NULL if service not in urban area)
    UrbanAreaKey                INT             NULL,

    -- Additive measures
    UPT                         BIGINT          NULL,       -- Unlinked Passenger Trips
    PMT                         BIGINT          NULL,       -- Passenger Miles Traveled

    VRM                         BIGINT          NULL,       -- Vehicle Revenue Miles
    VRH                         BIGINT          NULL,       -- Vehicle Revenue Hours
    VOMS                        INT             NULL,       -- Vehicle Operating and Maintenance Spend (semi-additive)
    DRM                         BIGINT          NULL,       -- Deadhead Revenue Miles

    -- Financial measures
    Fares                       DECIMAL(18,2)   NULL,       -- Fare Revenue (non-additive)
    OperatingExpenseTotal       DECIMAL(18,2)   NULL,       -- Total Operating Expenses

    -- --------------------------------------------------------
    -- Constraints
    -- --------------------------------------------------------
    CONSTRAINT PK_Fact_Annual_Service_Performance
        PRIMARY KEY CLUSTERED (AnnualServicePerformanceKey),

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

-- Clustered index on grain dimensions for ETL/reporting efficiency
CREATE NONCLUSTERED INDEX IX_Fact_ASP_Grain
    ON dw_transport.Fact_Annual_Service_Performance (DateKey, AgencyKey, ModeKey, ServiceTypeKey)
    INCLUDE (UPT, PMT, VRM, VRH, VOMS, DRM, Fares, OperatingExpenseTotal);
GO

-- Index for UrbanArea joins
CREATE NONCLUSTERED INDEX IX_Fact_ASP_UrbanAreaKey
    ON dw_transport.Fact_Annual_Service_Performance (UrbanAreaKey)
    INCLUDE (UPT, PMT);
GO

-- ============================================================
-- 2. Fact_Major_Safety_Event
--
-- GRAIN: One row per Major Safety Incident (with rollups for
--        Fatality and Injury counts by role: Passenger, Employee, Other)
--
-- MEASURES (Additive):
--   * EventCount: Number of distinct incidents reported
--   * Fatality counts by category (Passenger, Employee, Other, Total)
--   * Injury counts by category (Passenger, Employee, Other, Total)
--   * VehicleInvolvedCount: Number of vehicles in incident
--   * EvacuationCount: Number of persons evacuated
--   * PropertyDamageAmount: Financial loss (non-additive: depends on frequency/severity)
--
-- FACT SOURCE: stg_major_safety_event (one NTD record = one row)
-- ============================================================

IF OBJECT_ID('dw_transport.Fact_Major_Safety_Event', 'U') IS NOT NULL
    DROP TABLE dw_transport.Fact_Major_Safety_Event;
GO

CREATE TABLE dw_transport.Fact_Major_Safety_Event (

    -- Surrogate fact key
    MajorSafetyEventKey         BIGINT          NOT NULL    IDENTITY(1,1),

    -- Foreign keys to dimensions (EventDateKey is required; others optional)
    EventDateKey                INT             NOT NULL,
    AgencyKey                   INT             NOT NULL,

    ModeKey                     INT             NULL,       -- May not always be recorded
    ServiceTypeKey              INT             NULL,       -- May not always be recorded
    UrbanAreaKey                INT             NULL,       -- Optional

    SafetyEventTypeKey          INT             NOT NULL,
    SafetyIncidentKey           INT             NULL,       -- Optional narrative

    -- Degenerate dimension: time of incident
    EventTime                   TIME            NULL,

    -- Additive event count measure
    EventCount                  INT             NOT NULL    DEFAULT(1),

    -- Fatality measures (additive)
    PassengerFatalityCount      INT             NULL,
    EmployeeFatalityCount       INT             NULL,
    OtherFatalityCount          INT             NULL,
    TotalFatalityCount          INT             NULL,

    -- Injury measures (additive)
    PassengerInjuryCount        INT             NULL,
    EmployeeInjuryCount         INT             NULL,
    OtherInjuryCount            INT             NULL,
    TotalInjuryCount            INT             NULL,

    -- Other impact measures
    VehicleInvolvedCount        INT             NULL,
    EvacuationCount             INT             NULL,

    -- Financial impact (non-additive)
    PropertyDamageAmount        DECIMAL(18,2)   NULL,

    -- --------------------------------------------------------
    -- Constraints
    -- --------------------------------------------------------
    CONSTRAINT PK_Fact_Major_Safety_Event
        PRIMARY KEY CLUSTERED (MajorSafetyEventKey),

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
    CONSTRAINT FK_Fact_MSE_SafetyIncidentKey
        FOREIGN KEY (SafetyIncidentKey)
        REFERENCES dw_transport.DimSafetyIncident (SafetyIncidentKey),

    -- Measure value constraints (non-negative)
    CONSTRAINT CK_Fact_MSE_EventCount
        CHECK (EventCount >= 0),
    CONSTRAINT CK_Fact_MSE_PassengerFatalityCount
        CHECK (PassengerFatalityCount IS NULL OR PassengerFatalityCount >= 0),
    CONSTRAINT CK_Fact_MSE_EmployeeFatalityCount
        CHECK (EmployeeFatalityCount IS NULL OR EmployeeFatalityCount >= 0),
    CONSTRAINT CK_Fact_MSE_OtherFatalityCount
        CHECK (OtherFatalityCount IS NULL OR OtherFatalityCount >= 0),
    CONSTRAINT CK_Fact_MSE_TotalFatalityCount
        CHECK (TotalFatalityCount IS NULL OR TotalFatalityCount >= 0),
    CONSTRAINT CK_Fact_MSE_PassengerInjuryCount
        CHECK (PassengerInjuryCount IS NULL OR PassengerInjuryCount >= 0),
    CONSTRAINT CK_Fact_MSE_EmployeeInjuryCount
        CHECK (EmployeeInjuryCount IS NULL OR EmployeeInjuryCount >= 0),
    CONSTRAINT CK_Fact_MSE_OtherInjuryCount
        CHECK (OtherInjuryCount IS NULL OR OtherInjuryCount >= 0),
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

-- Index on event date and agency for common drill-down queries
CREATE NONCLUSTERED INDEX IX_Fact_MSE_EventDate_Agency
    ON dw_transport.Fact_Major_Safety_Event (EventDateKey, AgencyKey)
    INCLUDE (SafetyEventTypeKey, TotalFatalityCount, TotalInjuryCount);
GO

-- Index on safety type for incident classification analysis
CREATE NONCLUSTERED INDEX IX_Fact_MSE_SafetyEventType
    ON dw_transport.Fact_Major_Safety_Event (SafetyEventTypeKey)
    INCLUDE (TotalFatalityCount, TotalInjuryCount, PropertyDamageAmount);
GO

-- ============================================================
-- 3. Fact_Service_Availability
--
-- GRAIN: One row per Agency + Mode + ServiceType availability period.
--        Tracks when services are offered (start/end date range).
--
-- MEASURES:
--   * ServiceActiveFlag: Indicates if service is currently active (1/0)
--
-- USAGE: Determines service coverage windows for compliance,
--        service anniversary analysis, and geographic expansion trends.
--
-- FACT SOURCE: stg_annual_performance, inferred from year-over-year records
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

    -- Degenerate dimensions: service active period
    StartDateKey                INT             NULL,
    EndDateKey                  INT             NULL,

    -- Indicator flag
    ServiceActiveFlag           BIT             NOT NULL    DEFAULT(1),

    -- --------------------------------------------------------
    -- Constraints
    -- --------------------------------------------------------
    CONSTRAINT PK_Fact_Service_Availability
        PRIMARY KEY CLUSTERED (ServiceAvailabilityKey),

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
    CONSTRAINT FK_Fact_SA_StartDateKey
        FOREIGN KEY (StartDateKey)
        REFERENCES dw_transport.DimDate (DateKey),
    CONSTRAINT FK_Fact_SA_EndDateKey
        FOREIGN KEY (EndDateKey)
        REFERENCES dw_transport.DimDate (DateKey),

    -- Date range integrity check (end >= start when both provided)
    CONSTRAINT CK_Fact_SA_DateRange
        CHECK (StartDateKey IS NULL OR EndDateKey IS NULL OR EndDateKey >= StartDateKey),

    -- ServiceActiveFlag validation
    CONSTRAINT CK_Fact_SA_ServiceActiveFlag
        CHECK (ServiceActiveFlag IN (0, 1))
);
GO

-- Index on grain dimensions for service timeline queries
CREATE NONCLUSTERED INDEX IX_Fact_SA_Grain
    ON dw_transport.Fact_Service_Availability (AgencyKey, ModeKey, ServiceTypeKey)
    INCLUDE (StartDateKey, EndDateKey, ServiceActiveFlag);
GO

-- Index for point-in-time service status lookups
CREATE NONCLUSTERED INDEX IX_Fact_SA_DateRange
    ON dw_transport.Fact_Service_Availability (StartDateKey, EndDateKey)
    INCLUDE (AgencyKey, ModeKey, ServiceTypeKey, ServiceActiveFlag);
GO

-- ============================================================
-- 4. Fact_Service_Lifecycle_Accumulating
--
-- GRAIN: One row per Agency + Mode + ServiceType (across entire lifetime)
--        Captures the complete service lifecycle from inception to closure.
--
-- MEASURES (Additive in aggregate only):
--   * YearsInService: Duration in service
--   * Peak metrics: Annual UPT, VRM, VRH, VOMS at best year
--   * Latest metrics: Most recent annual figures
--   * Total observed: Cumulative UPT, VRM, VRH
--   * Safety metrics: Cumulative major safety events, fatalities, injuries
--   * LifecycleCompleteFlag: Indicates service has ceased (Type 1: 0/1)
--
-- BRIDGE MEASURES: Each measure uses a date key (first, peak, latest, end)
--                  to enable drill-down to Fact_Annual_Service_Performance.
--
-- USAGE: Service lifecycle analysis, long-term performance trends,
--        service discontinuation tracking, durability metrics.
--
-- FACT SOURCE: Aggregated from Fact_Annual_Service_Performance
--              and Fact_Major_Safety_Event (accumulated joins)
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

    -- Bridge foreign keys: each points to a specific year in DimDate
    -- Used to drill down to Fact_Annual_Service_Performance
    FirstObservedDateKey        INT             NULL,       -- First year service was reported
    PeakPerformanceDateKey      INT             NULL,       -- Year with highest UPT/VRM/VRH/VOMS
    LatestObservedDateKey       INT             NULL,       -- Most recent reporting year
    EndServiceDateKey           INT             NULL,       -- Year service ended (NULL if ongoing)

    -- Duration measure
    YearsInService              INT             NULL,

    -- Peak performance snapshot (from best-performing year)
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

    -- --------------------------------------------------------
    -- Constraints
    -- --------------------------------------------------------
    CONSTRAINT PK_Fact_Service_Lifecycle_Accumulating
        PRIMARY KEY CLUSTERED (ServiceLifecycleKey),

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
    CONSTRAINT FK_Fact_SLA_PeakPerformanceDateKey
        FOREIGN KEY (PeakPerformanceDateKey)
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

-- Index on grain dimensions for service lifecycle queries
CREATE NONCLUSTERED INDEX IX_Fact_SLA_Grain
    ON dw_transport.Fact_Service_Lifecycle_Accumulating (AgencyKey, ModeKey, ServiceTypeKey)
    INCLUDE (YearsInService, LifecycleCompleteFlag, TotalObservedUPT, TotalObservedVRM);
GO

-- Index on lifecycle status for active/discontinued service analysis
CREATE NONCLUSTERED INDEX IX_Fact_SLA_LifecycleStatus
    ON dw_transport.Fact_Service_Lifecycle_Accumulating (LifecycleCompleteFlag, LatestObservedDateKey)
    INCLUDE (AgencyKey, YearsInService, TotalObservedUPT);
GO

-- Index on bridge date keys for drill-down to annual data
CREATE NONCLUSTERED INDEX IX_Fact_SLA_BridgeDates
    ON dw_transport.Fact_Service_Lifecycle_Accumulating (FirstObservedDateKey, PeakPerformanceDateKey, LatestObservedDateKey);
GO

-- ============================================================
-- END OF FACT TABLE DEFINITIONS
-- ============================================================
