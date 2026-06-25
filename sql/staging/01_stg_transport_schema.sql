IF NOT EXISTS (SELECT * FROM sys.schemas WHERE name = 'stg_transport')
BEGIN
    EXEC('CREATE SCHEMA stg_transport');
END;

IF NOT EXISTS (SELECT * FROM sys.schemas WHERE name = 'raw_transport')
BEGIN
    EXEC('CREATE SCHEMA raw_transport');
END;