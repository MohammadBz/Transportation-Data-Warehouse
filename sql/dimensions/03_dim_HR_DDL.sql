USE [TransportationDB];
GO

-- ============================================================
-- 1. DimDate (Shared with Transportation Warehouse)
-- ============================================================
-- already handled in common
-- ============================================================
-- 2. DimAgency (SCD Type 2)
-- ============================================================
-- already handled in common
-- ============================================================
-- 3. DimMode (Static Reference)
-- ============================================================
-- already handled in common
-- ============================================================
-- 4. DimServiceType (Static Reference)
-- ============================================================
-- already handled in common
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
