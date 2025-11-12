-- ========================================
-- PARTE 1: CRIAR DATABASE DATASETS
-- ========================================

IF NOT EXISTS (SELECT name
FROM sys.databases
WHERE name = 'datasets')
BEGIN
    CREATE DATABASE datasets;
    PRINT 'Database datasets criado com sucesso!';
END
ELSE
BEGIN
    PRINT 'Database datasets já existe.';
END
GO

-- ========================================
-- PARTE 2: CRIAR TABELAS NO DATABASE DATASETS
-- ========================================
USE datasets;
GO

PRINT 'Criando tabelas no database datasets...';
go

IF NOT EXISTS (SELECT 1
FROM sys.tables
WHERE name = 'SP500' AND schema_id = SCHEMA_ID('dbo'))
BEGIN
    CREATE TABLE SP500
    (
        id INT,
        symbol NVARCHAR(10),
        company_name NVARCHAR(150),
        sector NVARCHAR(100),
        sub_industry NVARCHAR(150),
        headquarters NVARCHAR(200),
        founded_year NVARCHAR(50),
        cik INT,
        date_added_sp500 DATE,
        observation_date DATE,
        sp500_index DECIMAL(18,2),
        open_price DECIMAL(18,2),
        high_price DECIMAL(18,2),
        low_price DECIMAL(18,2),
        close_price DECIMAL(18,2),
        volume BIGINT,
        price_change_percent DECIMAL(10,4),
        market_cap DECIMAL(20,2),
        pe_ratio DECIMAL(10,2),
        dividend_yield DECIMAL(10,2),
        beta DECIMAL(10,3),
        year INT,
        month INT,
        quarter INT,
        day_of_week NVARCHAR(20),
        timestamp DATETIME
    );
    PRINT 'Tabela SP500 criada.';
END
GO

BEGIN TRY
    BULK INSERT SP500
        FROM '/datasets/sp500_part1.csv'
        WITH (
            FIRSTROW        = 2,
            FIELDTERMINATOR = ',',
            ROWTERMINATOR   = '\n',
            TABLOCK,
            MAXERRORS       = 0,
            FORMAT          = 'CSV'
        );

    BULK INSERT SP500
        FROM '/datasets/sp500_part2.csv'
        WITH (
            FIRSTROW        = 2,
            FIELDTERMINATOR = ',',
            ROWTERMINATOR   = '\n',
            TABLOCK,
            MAXERRORS       = 0,
            FORMAT          = 'CSV'
        );

    PRINT 'Importação concluída com sucesso!';
END TRY
BEGIN CATCH
    PRINT 'Ocorreu um erro durante a importação!';
    PRINT 'Mensagem de erro: ' + ERROR_MESSAGE();
    PRINT 'Linha do erro: ' + CAST(ERROR_LINE() AS VARCHAR);
    PRINT 'Procedimento: ' + ISNULL(ERROR_PROCEDURE(), 'N/A');
END CATCH;
GO

-- Tabela CSI500 (índice chinês)
IF NOT EXISTS (SELECT 1
FROM sys.tables
WHERE name = 'CSI500' AND schema_id = SCHEMA_ID('dbo'))
BEGIN
    CREATE TABLE CSI500
    (
        codigo_empresa INT PRIMARY KEY,
        date DATE,
        [open] DECIMAL(12,2),
        high DECIMAL(12,2),
        low DECIMAL(12,2),
        [close] DECIMAL(12,2),
        volume DECIMAL(16,2),
        amount DECIMAL(20,2),
        outstanding_share NVARCHAR(50),
        turnover NVARCHAR(50),
        nome_empresa_en NVARCHAR(200),
        region_en NVARCHAR(100),
        industry_en NVARCHAR(150),
        subindustry_en NVARCHAR(150)
    );
    PRINT 'Tabela CSI500 criada.';
END
ELSE
BEGIN
    PRINT 'Tabela CSI500 já existe.';
END
GO

BEGIN TRY
    BULK INSERT CSI500
        FROM '/datasets/CSI500-part-1.csv'
        WITH (
            FIRSTROW        = 2,
            FIELDTERMINATOR = ',',
            ROWTERMINATOR   = '\n',
            TABLOCK,
            MAXERRORS       = 0,
            FORMAT          = 'CSV'
        );

    BULK INSERT CSI500
        FROM '/datasets/CSI500-part-2.csv'
        WITH (
            FIRSTROW        = 2,
            FIELDTERMINATOR = ',',
            ROWTERMINATOR   = '\n',
            TABLOCK,
            MAXERRORS       = 0,
            FORMAT          = 'CSV'
        );

    PRINT 'Importação concluída com sucesso!';
END TRY
BEGIN CATCH
    PRINT 'Ocorreu um erro durante a importação!';
    PRINT 'Mensagem de erro: ' + ERROR_MESSAGE();
    PRINT 'Linha do erro: ' + CAST(ERROR_LINE() AS VARCHAR);
    PRINT 'Procedimento: ' + ISNULL(ERROR_PROCEDURE(), 'N/A');
END CATCH;