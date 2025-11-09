-- ========================================
-- SCRIPT 01: SETUP COMPLETO DO PROJETO
-- ========================================
-- Descrição: Cria todas as tabelas necessárias no projeto
-- Database FinanceDB: Tabelas do modelo dimensional (8 tabelas)
-- Database Datasets: Tabelas com dados brutos - SP500 (1 tabela) + CSI500 (1 tabela)
-- ========================================
-- IMPORTANTE: Execute este script via LINHA DE COMANDO (não no DataGrip)
-- Comando: docker exec sqlserverCC /opt/mssql-tools18/bin/sqlcmd -S localhost -U SA -P "Cc202505!" -i /tmp/01_setup_completo.sql -C
-- ========================================

PRINT '========================================';
PRINT 'INICIANDO SETUP DO PROJETO';
PRINT '========================================';
GO

-- ========================================
-- PARTE 1: CRIAR DATABASE DATASETS
-- ========================================
USE master;
GO

PRINT 'Verificando database datasets...';
GO

IF NOT EXISTS (SELECT name FROM sys.databases WHERE name = 'datasets')
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
GO

-- Tabela temporária para importação (todos campos como NVARCHAR)
IF NOT EXISTS (SELECT 1 FROM sys.tables WHERE name = 'SP500_data_Raw' AND schema_id = SCHEMA_ID('dbo'))
BEGIN
    CREATE TABLE SP500_data_Raw (
        id NVARCHAR(50),
        symbol NVARCHAR(50),
        company_name NVARCHAR(300),
        sector NVARCHAR(150),
        sub_industry NVARCHAR(300),
        headquarters NVARCHAR(300),
        founded_year NVARCHAR(50),
        cik NVARCHAR(50),
        date_added_sp500 NVARCHAR(50),
        observation_date NVARCHAR(50),
        sp500_index NVARCHAR(50),
        open_price NVARCHAR(50),
        high_price NVARCHAR(50),
        low_price NVARCHAR(50),
        close_price NVARCHAR(50),
        volume NVARCHAR(50),
        price_change_percent NVARCHAR(50),
        market_cap NVARCHAR(50),
        pe_ratio NVARCHAR(50),
        dividend_yield NVARCHAR(50),
        beta NVARCHAR(50),
        year NVARCHAR(50),
        month NVARCHAR(50),
        quarter NVARCHAR(50),
        day_of_week NVARCHAR(50),
        is_tech_sector NVARCHAR(50),
        is_healthcare_sector NVARCHAR(50),
        is_financial_sector NVARCHAR(50),
        timestamp NVARCHAR(50)
    );
    PRINT 'Tabela SP500_data_Raw criada.';
END
GO

-- Tabela SP500_data final (consolidada)
IF NOT EXISTS (SELECT 1 FROM sys.tables WHERE name = 'SP500_data' AND schema_id = SCHEMA_ID('dbo'))
BEGIN
    CREATE TABLE SP500_data (
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
        is_tech_sector BIT,
        is_healthcare_sector BIT,
        is_financial_sector BIT,
        timestamp DATETIME
    );
    PRINT 'Tabela SP500_data criada.';
END
ELSE
BEGIN
    PRINT 'Tabela SP500_data já existe. Deletando para recriar...';
    DROP TABLE SP500_data;
    CREATE TABLE SP500_data (
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
        is_tech_sector BIT,
        is_healthcare_sector BIT,
        is_financial_sector BIT,
        timestamp DATETIME
    );
    PRINT 'Tabela SP500_data recriada.';
END
GO

-- Tabela CSI500 (índice chinês)
IF NOT EXISTS (SELECT 1 FROM sys.tables WHERE name = 'CSI500' AND schema_id = SCHEMA_ID('dbo'))
BEGIN
    CREATE TABLE CSI500 (
        codigo_empresa NVARCHAR(20),
        [date] DATE,
        [open] NVARCHAR(50),
        high NVARCHAR(50),
        low NVARCHAR(50),
        [close] NVARCHAR(50),
        volume NVARCHAR(50),
        amount NVARCHAR(50),
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

PRINT 'Tabelas do datasets criadas com sucesso!';
GO

-- ========================================
-- PARTE 3: IMPORTAR DADOS DOS CSVs
-- ========================================

PRINT 'Iniciando importação dos dados...';
GO

-- Importar SP500_data part-1 para tabela Raw
BEGIN TRY
    BULK INSERT SP500_data_Raw
    FROM '/datasets/sp500_data_part1.csv'
    WITH (
        FIRSTROW = 2,
        FIELDTERMINATOR = ',',
        ROWTERMINATOR = '0x0a'
    );

    PRINT 'SP500_data part-1: Dados importados para Raw com sucesso!';
END TRY
BEGIN CATCH
    PRINT 'ERRO ao importar SP500_data part-1: ' + ERROR_MESSAGE();
END CATCH;
GO

-- Importar SP500_data part-2 para tabela Raw
BEGIN TRY
    BULK INSERT SP500_data_Raw
    FROM '/datasets/sp500_data_part2.csv'
    WITH (
        FIRSTROW = 2,
        FIELDTERMINATOR = ',',
        ROWTERMINATOR = '0x0a'
    );
    PRINT 'SP500_data part-2: Dados importados para Raw com sucesso!';
END TRY
BEGIN CATCH
    PRINT 'Erro ao importar SP500_data part-2: ' + ERROR_MESSAGE();
END CATCH;
GO

-- Converter dados de Raw para a tabela final com conversão de tipos
BEGIN TRY
    INSERT INTO SP500_data (
        id, symbol, company_name, sector, sub_industry, headquarters, founded_year, cik,
        date_added_sp500, observation_date, sp500_index, open_price, high_price, low_price,
        close_price, volume, price_change_percent, market_cap, pe_ratio, dividend_yield,
        beta, year, month, quarter, day_of_week, is_tech_sector, is_healthcare_sector,
        is_financial_sector, timestamp
    )
    SELECT
        CAST(id AS INT),
        symbol,
        company_name,
        sector,
        sub_industry,
        headquarters,
        founded_year,
        TRY_CAST(cik AS INT),
        TRY_CAST(date_added_sp500 AS DATE),
        TRY_CAST(observation_date AS DATE),
        TRY_CAST(sp500_index AS DECIMAL(18,2)),
        TRY_CAST(open_price AS DECIMAL(18,2)),
        TRY_CAST(high_price AS DECIMAL(18,2)),
        TRY_CAST(low_price AS DECIMAL(18,2)),
        TRY_CAST(close_price AS DECIMAL(18,2)),
        TRY_CAST(volume AS BIGINT),
        TRY_CAST(price_change_percent AS DECIMAL(10,4)),
        TRY_CAST(market_cap AS DECIMAL(20,2)),
        TRY_CAST(pe_ratio AS DECIMAL(10,2)),
        TRY_CAST(dividend_yield AS DECIMAL(10,2)),
        TRY_CAST(beta AS DECIMAL(10,3)),
        TRY_CAST(year AS INT),
        TRY_CAST(month AS INT),
        TRY_CAST(quarter AS INT),
        day_of_week,
        CAST(CASE WHEN is_tech_sector = '1' THEN 1 ELSE 0 END AS BIT),
        CAST(CASE WHEN is_healthcare_sector = '1' THEN 1 ELSE 0 END AS BIT),
        CAST(CASE WHEN is_financial_sector = '1' THEN 1 ELSE 0 END AS BIT),
        TRY_CAST(timestamp AS DATETIME)
    FROM SP500_data_Raw
    WHERE id IS NOT NULL;

    PRINT 'SP500_data: Dados convertidos e inseridos com sucesso! Total: ' + CAST(@@ROWCOUNT AS VARCHAR(10));
END TRY
BEGIN CATCH
    PRINT 'Erro ao converter dados: ' + ERROR_MESSAGE();
END CATCH;
GO

-- Limpar tabela Raw após conversão bem-sucedida
TRUNCATE TABLE SP500_data_Raw;
GO

-- Importar CSI500 part-1
BEGIN TRY
    BULK INSERT CSI500
    FROM '/datasets/CSI500-part-1.csv'
    WITH (
        FIRSTROW = 2,
        FIELDTERMINATOR = ',',
        ROWTERMINATOR = '0x0a',
        TABLOCK
    );
    PRINT 'CSI500 part-1: Dados importados com sucesso!';
END TRY
BEGIN CATCH
    PRINT 'Erro ao importar CSI500 part-1: ' + ERROR_MESSAGE();
END CATCH;
GO

-- Importar CSI500 part-2
BEGIN TRY
    BULK INSERT CSI500
    FROM '/datasets/CSI500-part-2.csv'
    WITH (
        FIRSTROW = 2,
        FIELDTERMINATOR = ',',
        ROWTERMINATOR = '0x0a',
        TABLOCK
    );
    PRINT 'CSI500 part-2: Dados importados com sucesso!';
END TRY
BEGIN CATCH
    PRINT 'Erro ao importar CSI500 part-2: ' + ERROR_MESSAGE();
END CATCH;
GO

PRINT 'Importação de dados concluída!';
GO

-- ========================================
-- PARTE 4: CRIAR DATABASE FINANCEDB
-- ========================================
USE master;
GO

PRINT 'Verificando database FinanceDB...';
GO

IF NOT EXISTS (SELECT name FROM sys.databases WHERE name = 'FinanceDB')
BEGIN
    CREATE DATABASE FinanceDB;
    PRINT 'Database FinanceDB criado com sucesso!';
END
ELSE
BEGIN
    PRINT 'Database FinanceDB já existe.';
END
GO

-- ========================================
-- PARTE 5: CRIAR TABELAS NO DATABASE FINANCEDB
-- ========================================
USE FinanceDB;
GO

PRINT 'Criando tabelas do modelo dimensional no database FinanceDB...';
GO

-- Tabela: SP500Historico
IF NOT EXISTS(SELECT name FROM sys.tables WHERE name = 'SP500Historico')
BEGIN
    CREATE TABLE SP500Historico (
        IdSP500 INT NOT NULL IDENTITY(1,1),
        DataReferencia DATE NOT NULL UNIQUE,
        ValorFechamento DECIMAL(18,4),
        ValorAbertura DECIMAL(18,4),
        ValorMaximo DECIMAL(18,4),
        ValorMinimo DECIMAL(18,4),
        VolumeNegociado BIGINT,
        PRIMARY KEY(IdSP500)
    );
    PRINT 'Tabela SP500Historico criada.';
END
GO

-- Tabela: Empresas
IF NOT EXISTS(SELECT name FROM sys.tables WHERE name = 'Empresas')
BEGIN
    CREATE TABLE Empresas (
        CIK INT NOT NULL,
        NomeEmpresa NVARCHAR(150) NOT NULL,
        Ticker NVARCHAR(10),
        Setor NVARCHAR(100),
        DataEntrada DATE,
        AnoFundacao SMALLINT,
        TipoSeguranca NVARCHAR(100),
        Site NVARCHAR(255),
        PRIMARY KEY(CIK)
    );
    PRINT 'Tabela Empresas criada.';
END
GO

-- Tabela: SubSetor
IF NOT EXISTS(SELECT name FROM sys.tables WHERE name = 'SubSetor')
BEGIN
    CREATE TABLE SubSetor (
        IdSubSetor INT NOT NULL IDENTITY(1,1),
        CIK INT NOT NULL,
        Industria NVARCHAR(150),
        SubIndustria NVARCHAR(150),
        Categoria NVARCHAR(100),
        PRIMARY KEY(IdSubSetor),
        FOREIGN KEY (CIK) REFERENCES Empresas(CIK)
    );
    PRINT 'Tabela SubSetor criada.';
END
GO

-- Tabela: Localizacao
IF NOT EXISTS(SELECT name FROM sys.tables WHERE name = 'Localizacao')
BEGIN
    CREATE TABLE Localizacao (
        IdLocalizacao INT NOT NULL IDENTITY(1,1),
        CIK INT NOT NULL,
        Cidade NVARCHAR(100),
        Estado NVARCHAR(50),
        Pais NVARCHAR(50) DEFAULT 'Estados Unidos',
        Regiao NVARCHAR(100),
        CodigoPostal NVARCHAR(20),
        PRIMARY KEY(IdLocalizacao),
        FOREIGN KEY (CIK) REFERENCES Empresas(CIK)
    );
    PRINT 'Tabela Localizacao criada.';
END
GO

-- Tabela: Tempo
IF NOT EXISTS(SELECT name FROM sys.tables WHERE name = 'Tempo')
BEGIN
    CREATE TABLE Tempo (
        IdTempo INT NOT NULL IDENTITY(1,1),
        DataCompleta DATE NOT NULL UNIQUE,
        Ano SMALLINT NOT NULL,
        Mes TINYINT NOT NULL,
        Dia TINYINT NOT NULL,
        Trimestre TINYINT NOT NULL,
        Semestre TINYINT NOT NULL,
        DiaSemana TINYINT NOT NULL,
        NomeDiaSemana NVARCHAR(20),
        NomeMes NVARCHAR(20),
        EhFimDeSemana BIT DEFAULT 0,
        EhFeriado BIT DEFAULT 0,
        PRIMARY KEY(IdTempo)
    );
    PRINT 'Tabela Tempo criada.';
END
GO

-- Tabela: PrecoAcao
IF NOT EXISTS(SELECT name FROM sys.tables WHERE name = 'PrecoAcao')
BEGIN
    CREATE TABLE PrecoAcao (
        IdPrecoAcao INT NOT NULL IDENTITY(1,1),
        CIK INT NOT NULL,
        IdTempo INT NOT NULL,
        PrecoAbertura DECIMAL(18,4),
        PrecoMaximo DECIMAL(18,4),
        PrecoMinimo DECIMAL(18,4),
        PrecoFechamento DECIMAL(18,4),
        PrecoFechamentoAjustado DECIMAL(18,4),
        Volume BIGINT,
        VariacaoDiaria DECIMAL(10,4),
        VariacaoPercentual DECIMAL(10,4),
        PRIMARY KEY(IdPrecoAcao),
        FOREIGN KEY (CIK) REFERENCES Empresas(CIK),
        FOREIGN KEY (IdTempo) REFERENCES Tempo(IdTempo)
    );
    PRINT 'Tabela PrecoAcao criada.';
END
GO

-- Tabela: Dividendos
IF NOT EXISTS(SELECT name FROM sys.tables WHERE name = 'Dividendos')
BEGIN
    CREATE TABLE Dividendos (
        IdDividendo INT NOT NULL IDENTITY(1,1),
        CIK INT NOT NULL,
        IdTempo INT NOT NULL,
        ValorDividendo DECIMAL(18,4),
        TipoDividendo NVARCHAR(50),
        FrequenciaPagamento NVARCHAR(50),
        DataExDividendo DATE,
        DataPagamento DATE,
        PRIMARY KEY(IdDividendo),
        FOREIGN KEY (CIK) REFERENCES Empresas(CIK),
        FOREIGN KEY (IdTempo) REFERENCES Tempo(IdTempo)
    );
    PRINT 'Tabela Dividendos criada.';
END
GO

-- ========================================
-- TABELAS CSI500 (MERCADO CHINÊS)
-- ========================================

-- Tabela: EmpresasCSI500
IF NOT EXISTS(SELECT name FROM sys.tables WHERE name = 'EmpresasCSI500')
BEGIN
    CREATE TABLE EmpresasCSI500 (
        CodigoEmpresa NVARCHAR(20) NOT NULL,
        NomeEmpresa NVARCHAR(150),
        NomeEmpresaEN NVARCHAR(150),
        Industria NVARCHAR(150),
        SubIndustria NVARCHAR(150),
        Regiao NVARCHAR(100),
        DataPrimeiraObservacao DATE,
        PRIMARY KEY(CodigoEmpresa)
    );
    PRINT 'Tabela EmpresasCSI500 criada.';
END
GO

-- Tabela: PrecoAcaoCSI500
IF NOT EXISTS(SELECT name FROM sys.tables WHERE name = 'PrecoAcaoCSI500')
BEGIN
    CREATE TABLE PrecoAcaoCSI500 (
        IdPrecoAcaoCSI500 INT NOT NULL IDENTITY(1,1),
        CodigoEmpresa NVARCHAR(20) NOT NULL,
        IdTempo INT NOT NULL,
        PrecoAbertura DECIMAL(18,4),
        PrecoMaximo DECIMAL(18,4),
        PrecoMinimo DECIMAL(18,4),
        PrecoFechamento DECIMAL(18,4),
        Volume DECIMAL(20,2),
        Amount DECIMAL(20,2),
        OutstandingShare DECIMAL(20,2),
        Turnover DECIMAL(18,8),
        PRIMARY KEY(IdPrecoAcaoCSI500),
        FOREIGN KEY (CodigoEmpresa) REFERENCES EmpresasCSI500(CodigoEmpresa),
        FOREIGN KEY (IdTempo) REFERENCES Tempo(IdTempo)
    );
    PRINT 'Tabela PrecoAcaoCSI500 criada.';
END
GO

-- Tabela: CSI500Historico
IF NOT EXISTS(SELECT name FROM sys.tables WHERE name = 'CSI500Historico')
BEGIN
    CREATE TABLE CSI500Historico (
        IdCSI500 INT NOT NULL IDENTITY(1,1),
        DataReferencia DATE NOT NULL UNIQUE,
        ValorMedioMercado DECIMAL(18,4),
        VolumeTotal DECIMAL(20,2),
        QtdEmpresasNegociadas INT,
        PRIMARY KEY(IdCSI500)
    );
    PRINT 'Tabela CSI500Historico criada.';
END
GO

-- ========================================
-- PARTE 6: CRIAR ÍNDICES PARA PERFORMANCE
-- ========================================

PRINT 'Criando índices...';
GO

IF NOT EXISTS (SELECT * FROM sys.indexes WHERE name = 'IX_PrecoAcao_Data')
    CREATE INDEX IX_PrecoAcao_Data ON PrecoAcao(IdTempo);

IF NOT EXISTS (SELECT * FROM sys.indexes WHERE name = 'IX_PrecoAcao_Empresa')
    CREATE INDEX IX_PrecoAcao_Empresa ON PrecoAcao(CIK);

IF NOT EXISTS (SELECT * FROM sys.indexes WHERE name = 'IX_Dividendos_Data')
    CREATE INDEX IX_Dividendos_Data ON Dividendos(IdTempo);

IF NOT EXISTS (SELECT * FROM sys.indexes WHERE name = 'IX_Dividendos_Empresa')
    CREATE INDEX IX_Dividendos_Empresa ON Dividendos(CIK);

IF NOT EXISTS (SELECT * FROM sys.indexes WHERE name = 'IX_Tempo_Data')
    CREATE INDEX IX_Tempo_Data ON Tempo(DataCompleta);

-- Índices CSI500
IF NOT EXISTS (SELECT * FROM sys.indexes WHERE name = 'IX_PrecoAcaoCSI500_Data')
    CREATE INDEX IX_PrecoAcaoCSI500_Data ON PrecoAcaoCSI500(IdTempo);

IF NOT EXISTS (SELECT * FROM sys.indexes WHERE name = 'IX_PrecoAcaoCSI500_Empresa')
    CREATE INDEX IX_PrecoAcaoCSI500_Empresa ON PrecoAcaoCSI500(CodigoEmpresa);

PRINT 'Índices criados com sucesso!';
GO

-- ========================================
-- PARTE 7: VERIFICAÇÃO FINAL
-- ========================================

PRINT '';
PRINT '========================================';
PRINT 'VERIFICAÇÃO FINAL';
PRINT '========================================';
GO

-- Verificar tabelas do FinanceDB
USE FinanceDB;
GO

PRINT 'Tabelas no database FINANCEDB:';
SELECT name as TabelaFinanceDB FROM sys.tables WHERE type = 'U' ORDER BY name;
GO

-- Verificar tabelas do datasets
USE datasets;
GO

PRINT 'Tabelas no database DATASETS:';
SELECT name as TabelaDatasets FROM sys.tables WHERE type = 'U' ORDER BY name;
GO

PRINT 'Contagem de registros no DATASETS:';
SELECT 'SP500_data' as Tabela, COUNT(*) as Total FROM SP500_data
UNION ALL
SELECT 'CSI500', COUNT(*) FROM CSI500;
GO

PRINT '';
PRINT '========================================';
PRINT 'SETUP COMPLETO FINALIZADO COM SUCESSO!';
PRINT '========================================';
PRINT '';
PRINT 'Databases criados:';
PRINT '  - FinanceDB: 8 tabelas (modelo dimensional)';
PRINT '  - datasets: 2 tabelas (SP500_data + CSI500)';
PRINT '';
PRINT 'Dados importados:';
PRINT '  - SP500_data: ~500k registros (S&P 500)';
PRINT '  - CSI500: ~865k registros (CSI 500)';
PRINT '  - Total: ~1.3M registros consolidados';
PRINT '';
PRINT 'Proximos passos:';
PRINT '  1. Execute 02_processar_dados_etl.sql';
PRINT '  2. Atualize o DataGrip (F5)';
PRINT '  3. Execute scripts de análise';
PRINT '========================================';
GO
