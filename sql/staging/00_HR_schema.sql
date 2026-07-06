IF NOT EXISTS (SELECT * FROM sys.schemas WHERE name = 'raw_HR')
BEGIN
    EXEC('CREATE SCHEMA raw_HR');
END;
GO

IF NOT EXISTS (SELECT * FROM sys.schemas WHERE name = 'stg_HR')
BEGIN
    EXEC('CREATE SCHEMA stg_HR');
END;
GO

IF NOT EXISTS (SELECT * FROM sys.schemas WHERE name = 'dw_HR')
BEGIN
    EXEC('CREATE SCHEMA dw_HR');
END;
GO
