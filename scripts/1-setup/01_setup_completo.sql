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

-- Tabela SP500_data (consolidada)
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
        stock_price DECIMAL(18,2),
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
    PRINT 'Tabela SP500_data já existe.';
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

-- Importar SP500_data part-1
BEGIN TRY
    BULK INSERT SP500_data
    FROM '/datasets/sp500_data_part1.csv'
    WITH (
        FORMAT = 'CSV',
        FIRSTROW = 2,
        FIELDTERMINATOR = ',',
        ROWTERMINATOR = '\n',
        FIELDQUOTE = '"',
        TABLOCK
    );
    PRINT 'SP500_data part-1: Dados importados com sucesso!';
END TRY
BEGIN CATCH
    PRINT 'Erro ao importar SP500_data part-1: ' + ERROR_MESSAGE();
END CATCH
GO

-- Importar SP500_data part-2
BEGIN TRY
    BULK INSERT SP500_data
    FROM '/datasets/sp500_data_part2.csv'
    WITH (
        FORMAT = 'CSV',
        FIRSTROW = 2,
        FIELDTERMINATOR = ',',
        ROWTERMINATOR = '\n',
        FIELDQUOTE = '"',
        TABLOCK
    );
    PRINT 'SP500_data part-2: Dados importados com sucesso!';
END TRY
BEGIN CATCH
    PRINT 'Erro ao importar SP500_data part-2: ' + ERROR_MESSAGE();
END CATCH
GO

-- Importar CSI500 part-1
BEGIN TRY
    BULK INSERT CSI500
    FROM '/datasets/CSI500-part-1.csv'
    WITH (
        FORMAT = 'CSV',
        FIRSTROW = 2,
        FIELDTERMINATOR = ',',
        ROWTERMINATOR = '\n',
        FIELDQUOTE = '"',
        TABLOCK
    );
    PRINT 'CSI500 part-1: Dados importados com sucesso!';
END TRY
BEGIN CATCH
    PRINT 'Erro ao importar CSI500 part-1: ' + ERROR_MESSAGE();
END CATCH
GO

-- Importar CSI500 part-2
BEGIN TRY
    BULK INSERT CSI500
    FROM '/datasets/CSI500-part-2.csv'
    WITH (
        FORMAT = 'CSV',
        FIRSTROW = 2,
        FIELDTERMINATOR = ',',
        ROWTERMINATOR = '\n',
        FIELDQUOTE = '"',
        TABLOCK
    );
    PRINT 'CSI500 part-2: Dados importados com sucesso!';
END TRY
BEGIN CATCH
    PRINT 'Erro ao importar CSI500 part-2: ' + ERROR_MESSAGE();
END CATCH
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

-- Tabela: Indice
IF NOT EXISTS(SELECT name FROM sys.tables WHERE name = 'Indice')
BEGIN
    CREATE TABLE Indice (
        IdIndice INT NOT NULL IDENTITY(1,1),
        NomeIndice NVARCHAR(100) NOT NULL,
        Descricao NVARCHAR(255),
        Simbolo NVARCHAR(20),
        PaisOrigem NVARCHAR(50),
        DataCriacao DATE,
        PRIMARY KEY(IdIndice)
    );
    PRINT 'Tabela Indice criada.';
END
GO

-- Tabela: IndiceSP500
IF NOT EXISTS(SELECT name FROM sys.tables WHERE name = 'IndiceSP500')
BEGIN
    CREATE TABLE IndiceSP500 (
        IdIndiceSP500 INT NOT NULL IDENTITY(1,1),
        IdIndice INT NOT NULL,
        DataReferencia DATE NOT NULL,
        ValorFechamento DECIMAL(18,4),
        ValorAbertura DECIMAL(18,4),
        ValorMaximo DECIMAL(18,4),
        ValorMinimo DECIMAL(18,4),
        VolumeNegociado BIGINT,
        PRIMARY KEY(IdIndiceSP500),
        FOREIGN KEY (IdIndice) REFERENCES Indice(IdIndice)
    );
    PRINT 'Tabela IndiceSP500 criada.';
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
