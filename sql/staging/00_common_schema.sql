-- ============================================================
-- FILE:   00_common_schema.sql
-- SCHEMA: dw_common
-- DESC:   Creates the dw_common schema for shared dimensions
--         used across HR and Transport data marts.
--         
--         This schema contains universal dimensions that are
--         referenced by multiple fact tables in different
--         business domains:
--         - DimDate: Calendar dimension (shared by all marts)
--         - DimAgency: Organization reference (SCD Type 2)
--         - DimMode: Transit mode codes (static reference)
--         - DimServiceType: Service type codes (static reference)
--
-- EXECUTION ORDER: Run first, before any dimension DDL scripts
-- ============================================================

IF NOT EXISTS (SELECT * FROM sys.schemas WHERE name = 'dw_common')
BEGIN
    EXEC('CREATE SCHEMA dw_common');
END;
GO
