USE [TransportationDB];
GO

-- ============================================================
-- 1. DimDate (Shared with Transportation Warehouse)
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

        CONSTRAINT PK_DimDate_HR PRIMARY KEY CLUSTERED (DateKey),
        CONSTRAINT CK_DimDate_HR_CalendarDay CHECK (DateKey = -1 OR CalendarDay BETWEEN 1 AND 31),
        CONSTRAINT CK_DimDate_HR_CalendarMonth CHECK (DateKey = -1 OR CalendarMonth BETWEEN 1 AND 12),
        CONSTRAINT CK_DimDate_HR_CalendarYear CHECK (DateKey = -1 OR CalendarYear >= 1900)
    );

    -- رکورد Unknown پیش‌فرض برای سناریوی عدم تطابق تاریخ‌ها
    INSERT INTO dw_HR.DimDate (
        DateKey, FullDate, DayLongName, DayShortName, MonthLongName, MonthShortName,
        CalendarDay, CalendarDayInWeek, CalendarWeek, CalendarWeekStartDateId, CalendarWeekEndDateId,
        CalendarMonth, CalendarMonthStartDateId, CalendarMonthEndDateId, CalendarNumberOfDaysInMonth, CalendarDayInMonth,
        CalendarQuarter, CalendarQuarterStartDateId, CalendarQuarterEndDateId, CalendarNumberOfDaysInQuarter, CalendarDayInQuarter,
        CalendarYear, CalendarYearStartDateId, CalendarYearEndDateId, CalendarNumberOfDaysInYear
    )
    VALUES (
        -1, '1900-01-01', 'Unknown', 'Unk', 'Unknown', 'Unk',
        -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1
    );
END;
GO

-- ============================================================
-- 2. DimAgency (SCD Type 2)
-- ============================================================

IF OBJECT_ID('dw_HR.DimAgency', 'U') IS NOT NULL
    DROP TABLE dw_HR.DimAgency;
GO

CREATE TABLE dw_HR.DimAgency (
    AgencyKey               INT             NOT NULL    IDENTITY(1,1),
    NTD_ID                  VARCHAR(50)     NOT NULL,
    LegacyNTD_ID            VARCHAR(50)     NULL,
    AgencyName              VARCHAR(255)    NOT NULL,
    OrganizationType        VARCHAR(255)    NULL,
    City                    VARCHAR(100)    NULL,
    State                   CHAR(2)         NULL, -- هماهنگ شده با کدهای ۲ حرفی فایل Staging (مثلا WA, NY)
    Region                  SMALLINT        NULL,
    ServiceAreaSqMiles      NUMERIC(18,2)   NULL,
    ServiceAreaPopulation   BIGINT          NULL,
    EffectiveDate           DATE            NOT NULL,
    ExpirationDate          DATE            NOT NULL CONSTRAINT DF_DimAgency_HR_ExpirationDate DEFAULT ('9999-12-31'),
    CurrentFlag             BIT             NOT NULL CONSTRAINT DF_DimAgency_HR_CurrentFlag DEFAULT (1),

    CONSTRAINT PK_DimAgency_HR PRIMARY KEY CLUSTERED (AgencyKey),
    CONSTRAINT UQ_DimAgency_HR_NTD_ID_EffectiveDate UNIQUE (NTD_ID, EffectiveDate),
    CONSTRAINT CK_DimAgency_HR_ExpirationDate CHECK (ExpirationDate >= EffectiveDate),
    CONSTRAINT CK_DimAgency_HR_Region CHECK (Region IS NULL OR Region BETWEEN 1 AND 10),
    CONSTRAINT CK_DimAgency_HR_ServiceAreaSqMiles CHECK (ServiceAreaSqMiles IS NULL OR ServiceAreaSqMiles >= 0),
    CONSTRAINT CK_DimAgency_HR_ServiceAreaPopulation CHECK (ServiceAreaPopulation IS NULL OR ServiceAreaPopulation >= 0)
);
GO

CREATE NONCLUSTERED INDEX IX_DimAgency_HR_NTD_ID ON dw_HR.DimAgency (NTD_ID, CurrentFlag) INCLUDE (AgencyKey);
GO

SET IDENTITY_INSERT dw_HR.DimAgency ON;
INSERT INTO dw_HR.DimAgency (
    AgencyKey, NTD_ID, LegacyNTD_ID, AgencyName, OrganizationType, City, State, Region,
    ServiceAreaSqMiles, ServiceAreaPopulation, EffectiveDate, ExpirationDate, CurrentFlag
)
VALUES (
    -1, 'N/A', NULL, 'Unknown Agency', NULL, NULL, NULL, NULL, NULL, NULL, '1900-01-01', '9999-12-31', 1
);
SET IDENTITY_INSERT dw_HR.DimAgency OFF;
GO

-- ============================================================
-- 3. DimMode (Static Reference)
-- ============================================================

IF OBJECT_ID('dw_HR.DimMode', 'U') IS NOT NULL
    DROP TABLE dw_HR.DimMode;
GO

CREATE TABLE dw_HR.DimMode (
    ModeKey     INT             NOT NULL    IDENTITY(1,1),
    ModeCode    VARCHAR(10)     NOT NULL,
    ModeName    VARCHAR(100)    NOT NULL,

    CONSTRAINT PK_DimMode_HR PRIMARY KEY CLUSTERED (ModeKey),
    CONSTRAINT UQ_DimMode_HR_ModeCode UNIQUE (ModeCode),
    CONSTRAINT CK_DimMode_HR_ModeCode CHECK (ModeKey = -1 OR LEN(TRIM(ModeCode)) > 0)
);
GO

SET IDENTITY_INSERT dw_HR.DimMode ON;
INSERT INTO dw_HR.DimMode (ModeKey, ModeCode, ModeName) VALUES (-1, 'N/A', 'Unknown Mode');
SET IDENTITY_INSERT dw_HR.DimMode OFF;
GO

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
-- 4. DimServiceType (Static Reference)
-- ============================================================

IF OBJECT_ID('dw_HR.DimServiceType', 'U') IS NOT NULL
    DROP TABLE dw_HR.DimServiceType;
GO

CREATE TABLE dw_HR.DimServiceType (
    ServiceTypeKey   INT             NOT NULL    IDENTITY(1,1),
    TOSCode          VARCHAR(10)     NOT NULL, -- برای هماهنگی با نام‌گذاری ساختار DBML تغییر یافت
    ServiceTypeName  VARCHAR(100)    NOT NULL,
    ServiceCategory  VARCHAR(100)    NULL,

    CONSTRAINT PK_DimServiceType_HR PRIMARY KEY CLUSTERED (ServiceTypeKey),
    CONSTRAINT UQ_DimServiceType_HR_TOSCode UNIQUE (TOSCode),
    CONSTRAINT CK_DimServiceType_HR_TOSCode CHECK (ServiceTypeKey = -1 OR LEN(TRIM(TOSCode)) > 0)
);
GO

SET IDENTITY_INSERT dw_HR.DimServiceType ON;
INSERT INTO dw_HR.DimServiceType (ServiceTypeKey, TOSCode, ServiceTypeName, ServiceCategory)
VALUES (-1, 'N/A', 'Unknown Service Type', NULL);
SET IDENTITY_INSERT dw_HR.DimServiceType OFF;
GO

INSERT INTO dw_HR.DimServiceType (TOSCode, ServiceTypeName, ServiceCategory)
VALUES
    ('DO',  'Directly Operated',         'Direct Operations'),
    ('PT',  'Purchased Transportation',  'Contracted Operations'),
    ('TN',  'Volunteer Driver',          'Non-Traditional'),
    ('TX',  'Taxi',                      'Non-Traditional');
GO

-- ============================================================
-- 5. DimEmploymentType
-- ============================================================

IF OBJECT_ID('dw_HR.DimEmploymentType', 'U') IS NOT NULL
    DROP TABLE dw_HR.DimEmploymentType;
GO

CREATE TABLE dw_HR.DimEmploymentType (
    EmploymentTypeKey   INT             NOT NULL    IDENTITY(1,1),
    EmploymentTypeCode  VARCHAR(50)     NOT NULL,
    EmploymentTypeName  VARCHAR(100)    NOT NULL,
    IsFullTime          BIT             NULL,

    CONSTRAINT PK_DimEmploymentType_HR PRIMARY KEY CLUSTERED (EmploymentTypeKey),
    CONSTRAINT UQ_DimEmploymentType_HR_Code UNIQUE (EmploymentTypeCode),
    CONSTRAINT CK_DimEmploymentType_HR_Code CHECK (EmploymentTypeKey = -1 OR LEN(TRIM(EmploymentTypeCode)) > 0)
);
GO

SET IDENTITY_INSERT dw_HR.DimEmploymentType ON;
INSERT INTO dw_HR.DimEmploymentType (EmploymentTypeKey, EmploymentTypeCode, EmploymentTypeName, IsFullTime)
VALUES (-1, 'N/A', 'Unknown Employment Type', NULL);
SET IDENTITY_INSERT dw_HR.DimEmploymentType OFF;
GO

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
-- ============================================================

IF OBJECT_ID('dw_HR.DimDepartment', 'U') IS NOT NULL
    DROP TABLE dw_HR.DimDepartment;
GO

CREATE TABLE dw_HR.DimDepartment (
    DepartmentKey        INT             NOT NULL    IDENTITY(1,1),
    DepartmentCode       VARCHAR(50)     NOT NULL,
    DepartmentName       VARCHAR(255)    NOT NULL,
    NTDLaborObjectClass  VARCHAR(100)    NULL, -- نگاشت فیلدهای دسته‌بندی مشاغل NTD جهت ارتباط با پورتال ترنزیت

    CONSTRAINT PK_DimDepartment_HR PRIMARY KEY CLUSTERED (DepartmentKey),
    CONSTRAINT UQ_DimDepartment_HR_Code UNIQUE (DepartmentCode),
    CONSTRAINT CK_DimDepartment_HR_Code CHECK (DepartmentKey = -1 OR LEN(TRIM(DepartmentCode)) > 0)
);
GO

SET IDENTITY_INSERT dw_HR.DimDepartment ON;
INSERT INTO dw_HR.DimDepartment (DepartmentKey, DepartmentCode, DepartmentName, NTDLaborObjectClass)
VALUES (-1, 'N/A', 'Unknown Department', NULL);
SET IDENTITY_INSERT dw_HR.DimDepartment OFF;
GO

-- ============================================================
-- 7. DimJobRole (SCD Type 2)
-- ============================================================

IF OBJECT_ID('dw_HR.DimJobRole', 'U') IS NOT NULL
    DROP TABLE dw_HR.DimJobRole;
GO

CREATE TABLE dw_HR.DimJobRole (
    JobRoleKey          INT             NOT NULL    IDENTITY(1,1),
    PositionTitle       VARCHAR(255)    NOT NULL,
    LaborCategory       VARCHAR(100)    NULL,
    OperatorStatus      VARCHAR(50)     NULL,
    TypicalSalaryMin    NUMERIC(18,2)   NULL, -- کاملا بهینه برای دیتای دستمزد ساعتی لایه Staging
    TypicalSalaryMax    NUMERIC(18,2)   NULL,
    EffectiveDate       DATE            NOT NULL,
    ExpirationDate      DATE            NOT NULL CONSTRAINT DF_DimJobRole_HR_ExpirationDate DEFAULT ('9999-12-31'),
    CurrentFlag         BIT             NOT NULL CONSTRAINT DF_DimJobRole_HR_CurrentFlag DEFAULT (1),

    CONSTRAINT PK_DimJobRole_HR PRIMARY KEY CLUSTERED (JobRoleKey),
    CONSTRAINT UQ_DimJobRole_HR_PositionTitle_EffectiveDate UNIQUE (PositionTitle, EffectiveDate),
    CONSTRAINT CK_DimJobRole_HR_ExpirationDate CHECK (ExpirationDate >= EffectiveDate),
    CONSTRAINT CK_DimJobRole_HR_TypicalSalaryMin CHECK (TypicalSalaryMin IS NULL OR TypicalSalaryMin >= 0),
    CONSTRAINT CK_DimJobRole_HR_TypicalSalaryMax CHECK (TypicalSalaryMax IS NULL OR TypicalSalaryMax >= 0),
    CONSTRAINT CK_DimJobRole_HR_SalaryRange CHECK (TypicalSalaryMin IS NULL OR TypicalSalaryMax IS NULL OR TypicalSalaryMin <= TypicalSalaryMax)
);
GO

CREATE NONCLUSTERED INDEX IX_DimJobRole_HR_PositionTitle ON dw_HR.DimJobRole (PositionTitle, CurrentFlag) INCLUDE (JobRoleKey);
GO

SET IDENTITY_INSERT dw_HR.DimJobRole ON;
INSERT INTO dw_HR.DimJobRole (
    JobRoleKey, PositionTitle, LaborCategory, OperatorStatus, TypicalSalaryMin, TypicalSalaryMax, EffectiveDate, ExpirationDate, CurrentFlag
)
VALUES (
    -1, 'Unknown Position', NULL, NULL, NULL, NULL, '1900-01-01', '9999-12-31', 1
);
SET IDENTITY_INSERT dw_HR.DimJobRole OFF;
GO
