-- ========================================
-- SCRIPT 01: SETUP COMPLETO DO PROJETO
-- ========================================
-- Descrição: Cria todas as tabelas necessárias no projeto
-- Database master: Tabelas do modelo dimensional (8 tabelas)
-- Database datasets: Tabelas com dados brutos dos CSVs (3 tabelas)
-- ========================================
-- IMPORTANTE: Execute este script via LINHA DE COMANDO (não no DataGrip)
-- Comando (Linux):
-- docker exec sqlserverCC /opt/mssql-tools18/bin/sqlcmd \
--   -S localhost -U SA -P "Cc202505!" -i /tmp/01_setup_completo.sql -C
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
-- PARTE 2: CRIAR TABELAS BRUTAS NO DATABASE DATASETS
-- (1 coluna "registro" para cada CSV)
-- ========================================
USE datasets;
GO

PRINT 'Criando tabelas brutas no database datasets...';
GO

----------------------------------------------------
-- Tabela SP500_companies (1 coluna = linha inteira)
----------------------------------------------------
IF OBJECT_ID('dbo.SP500_companies','U') IS NOT NULL
BEGIN
    DROP TABLE dbo.SP500_companies;
    PRINT 'Tabela SP500_companies anterior removida.';
END;
GO

CREATE TABLE dbo.SP500_companies (
    registro NVARCHAR(MAX) NOT NULL
);
PRINT 'Tabela SP500_companies criada.';
GO

----------------------------------------------------
-- Tabela SP500_fred (1 coluna = linha inteira)
----------------------------------------------------
IF OBJECT_ID('dbo.SP500_fred','U') IS NOT NULL
BEGIN
    DROP TABLE dbo.SP500_fred;
    PRINT 'Tabela SP500_fred anterior removida.';
END;
GO

CREATE TABLE dbo.SP500_fred (
    registro NVARCHAR(MAX) NOT NULL
);
PRINT 'Tabela SP500_fred criada.';
GO

----------------------------------------------------
-- Tabela CSI500 (1 coluna = linha inteira)
----------------------------------------------------
IF OBJECT_ID('dbo.CSI500','U') IS NOT NULL
BEGIN
    DROP TABLE dbo.CSI500;
    PRINT 'Tabela CSI500 anterior removida.';
END;
GO

CREATE TABLE dbo.CSI500 (
    registro NVARCHAR(MAX) NOT NULL
);
PRINT 'Tabela CSI500 criada.';
GO

PRINT 'Tabelas brutas do datasets criadas com sucesso!';
GO

-- ========================================
-- PARTE 3: IMPORTAR DADOS DOS CSVs (BULK INSERT)
-- ========================================

PRINT 'Iniciando importação dos dados...';
GO

----------------------------------------------------
-- Importar SP500_companies
-- Cada linha inteira vai para a coluna "registro"
----------------------------------------------------
BEGIN TRY
    TRUNCATE TABLE dbo.SP500_companies;

    BULK INSERT dbo.SP500_companies
    FROM '/datasets/S&P-500-companies.csv'
    WITH (
        FIRSTROW       = 2,      -- pular header
        FIELDTERMINATOR = '\t',  -- TAB (não existe no arquivo) => linha inteira vira 1 campo
        ROWTERMINATOR   = '\n',  -- LF (padrão dos arquivos)
        DATAFILETYPE    = 'char',
        TABLOCK
    );

    PRINT 'SP500_companies: Dados importados com sucesso!';
END TRY
BEGIN CATCH
    PRINT 'Erro ao importar SP500_companies: ' + ERROR_MESSAGE();
END CATCH;
GO

----------------------------------------------------
-- Importar SP500_fred
----------------------------------------------------
BEGIN TRY
    TRUNCATE TABLE dbo.SP500_fred;

    BULK INSERT dbo.SP500_fred
    FROM '/datasets/S&P500-fred.csv'
    WITH (
        FIRSTROW       = 2,
        FIELDTERMINATOR = '\t',
        ROWTERMINATOR   = '\n',
        DATAFILETYPE    = 'char',
        TABLOCK
    );

    PRINT 'SP500_fred: Dados importados com sucesso!';
END TRY
BEGIN CATCH
    PRINT 'Erro ao importar SP500_fred: ' + ERROR_MESSAGE();
END CATCH;
GO

----------------------------------------------------
-- Importar CSI500 part-1
----------------------------------------------------
BEGIN TRY
    TRUNCATE TABLE dbo.CSI500;  -- limpar antes da primeira parte

    BULK INSERT dbo.CSI500
    FROM '/datasets/CSI500-part-1.csv'
    WITH (
        FIRSTROW       = 2,
        FIELDTERMINATOR = '\t',
        ROWTERMINATOR   = '\n',
        DATAFILETYPE    = 'char',
        TABLOCK
    );

    PRINT 'CSI500 part-1: Dados importados com sucesso!';
END TRY
BEGIN CATCH
    PRINT 'Erro ao importar CSI500 part-1: ' + ERROR_MESSAGE();
END CATCH;
GO

----------------------------------------------------
-- Importar CSI500 part-2 (append)
----------------------------------------------------
BEGIN TRY
    BULK INSERT dbo.CSI500
    FROM '/datasets/CSI500-part-2.csv'
    WITH (
        FIRSTROW       = 2,
        FIELDTERMINATOR = '\t',
        ROWTERMINATOR   = '\n',
        DATAFILETYPE    = 'char',
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
-- PARTE 4: CRIAR TABELAS NO DATABASE MASTER
-- (modelo dimensional – igual ao que você já tinha)
-- ========================================
USE master;
GO

PRINT 'Criando tabelas do modelo dimensional no database master...';
GO

----------------------------------------------------
-- Tabela: Indice
----------------------------------------------------
IF NOT EXISTS(SELECT name FROM sys.tables WHERE name = 'Indice')
BEGIN
    CREATE TABLE Indice (
        IdIndice    INT           NOT NULL IDENTITY(1,1),
        NomeIndice  NVARCHAR(100) NOT NULL,
        Descricao   NVARCHAR(255),
        Simbolo     NVARCHAR(20),
        PaisOrigem  NVARCHAR(50),
        DataCriacao DATE,
        PRIMARY KEY(IdIndice)
    );
    PRINT 'Tabela Indice criada.';
END
GO

----------------------------------------------------
-- Tabela: IndiceSP500 (fato índice)
----------------------------------------------------
IF NOT EXISTS(SELECT name FROM sys.tables WHERE name = 'IndiceSP500')
BEGIN
    CREATE TABLE IndiceSP500 (
        IdIndiceSP500     INT NOT NULL IDENTITY(1,1),
        IdIndice          INT NOT NULL,
        DataReferencia    DATE NOT NULL,
        ValorFechamento   DECIMAL(18,4),
        ValorAbertura     DECIMAL(18,4),
        ValorMaximo       DECIMAL(18,4),
        ValorMinimo       DECIMAL(18,4),
        VolumeNegociado   BIGINT,
        PRIMARY KEY(IdIndiceSP500),
        FOREIGN KEY (IdIndice) REFERENCES Indice(IdIndice)
    );
    PRINT 'Tabela IndiceSP500 criada.';
END
GO

----------------------------------------------------
-- Tabela: Empresas
----------------------------------------------------
IF NOT EXISTS(SELECT name FROM sys.tables WHERE name = 'Empresas')
BEGIN
    CREATE TABLE Empresas (
        CIK           INT           NOT NULL,
        NomeEmpresa   NVARCHAR(150) NOT NULL,
        Ticker        NVARCHAR(10),
        Setor         NVARCHAR(100),
        DataEntrada   DATE,
        AnoFundacao   SMALLINT,
        TipoSeguranca NVARCHAR(100),
        Site          NVARCHAR(255),
        PRIMARY KEY(CIK)
    );
    PRINT 'Tabela Empresas criada.';
END
GO

----------------------------------------------------
-- Tabela: SubSetor
----------------------------------------------------
IF NOT EXISTS(SELECT name FROM sys.tables WHERE name = 'SubSetor')
BEGIN
    CREATE TABLE SubSetor (
        IdSubSetor   INT NOT NULL IDENTITY(1,1),
        CIK          INT NOT NULL,
        Industria    NVARCHAR(150),
        SubIndustria NVARCHAR(150),
        Categoria    NVARCHAR(100),
        PRIMARY KEY(IdSubSetor),
        FOREIGN KEY (CIK) REFERENCES Empresas(CIK)
    );
    PRINT 'Tabela SubSetor criada.';
END
GO

----------------------------------------------------
-- Tabela: Localizacao
----------------------------------------------------
IF NOT EXISTS(SELECT name FROM sys.tables WHERE name = 'Localizacao')
BEGIN
    CREATE TABLE Localizacao (
        IdLocalizacao INT NOT NULL IDENTITY(1,1),
        CIK           INT NOT NULL,
        Cidade        NVARCHAR(100),
        Estado        NVARCHAR(50),
        Pais          NVARCHAR(50) DEFAULT 'Estados Unidos',
        Regiao        NVARCHAR(100),
        CodigoPostal  NVARCHAR(20),
        PRIMARY KEY(IdLocalizacao),
        FOREIGN KEY (CIK) REFERENCES Empresas(CIK)
    );
    PRINT 'Tabela Localizacao criada.';
END
GO

----------------------------------------------------
-- Tabela: Tempo
----------------------------------------------------
IF NOT EXISTS(SELECT name FROM sys.tables WHERE name = 'Tempo')
BEGIN
    CREATE TABLE Tempo (
        IdTempo        INT NOT NULL IDENTITY(1,1),
        DataCompleta   DATE NOT NULL UNIQUE,
        Ano            SMALLINT NOT NULL,
        Mes            TINYINT NOT NULL,
        Dia            TINYINT NOT NULL,
        Trimestre      TINYINT NOT NULL,
        Semestre       TINYINT NOT NULL,
        DiaSemana      TINYINT NOT NULL,
        NomeDiaSemana  NVARCHAR(20),
        NomeMes        NVARCHAR(20),
        EhFimDeSemana  BIT DEFAULT 0,
        EhFeriado      BIT DEFAULT 0,
        PRIMARY KEY(IdTempo)
    );
    PRINT 'Tabela Tempo criada.';
END
GO

----------------------------------------------------
-- Tabela: PrecoAcao
----------------------------------------------------
IF NOT EXISTS(SELECT name FROM sys.tables WHERE name = 'PrecoAcao')
BEGIN
    CREATE TABLE PrecoAcao (
        IdPrecoAcao             INT NOT NULL IDENTITY(1,1),
        CIK                     INT NOT NULL,
        IdTempo                 INT NOT NULL,
        PrecoAbertura           DECIMAL(18,4),
        PrecoMaximo             DECIMAL(18,4),
        PrecoMinimo             DECIMAL(18,4),
        PrecoFechamento         DECIMAL(18,4),
        PrecoFechamentoAjustado DECIMAL(18,4),
        Volume                  BIGINT,
        VariacaoDiaria          DECIMAL(10,4),
        VariacaoPercentual      DECIMAL(10,4),
        PRIMARY KEY(IdPrecoAcao),
        FOREIGN KEY (CIK) REFERENCES Empresas(CIK),
        FOREIGN KEY (IdTempo) REFERENCES Tempo(IdTempo)
    );
    PRINT 'Tabela PrecoAcao criada.';
END
GO

----------------------------------------------------
-- Tabela: Dividendos
----------------------------------------------------
IF NOT EXISTS(SELECT name FROM sys.tables WHERE name = 'Dividendos')
BEGIN
    CREATE TABLE Dividendos (
        IdDividendo        INT NOT NULL IDENTITY(1,1),
        CIK                INT NOT NULL,
        IdTempo            INT NOT NULL,
        ValorDividendo     DECIMAL(18,4),
        TipoDividendo      NVARCHAR(50),
        FrequenciaPagamento NVARCHAR(50),
        DataExDividendo    DATE,
        DataPagamento      DATE,
        PRIMARY KEY(IdDividendo),
        FOREIGN KEY (CIK) REFERENCES Empresas(CIK),
        FOREIGN KEY (IdTempo) REFERENCES Tempo(IdTempo)
    );
    PRINT 'Tabela Dividendos criada.';
END
GO

-- ========================================
-- PARTE 5: CRIAR ÍNDICES PARA PERFORMANCE
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
-- PARTE 6: VERIFICAÇÃO FINAL
-- ========================================

PRINT '';
PRINT '========================================';
PRINT 'VERIFICAÇÃO FINAL';
PRINT '========================================';
GO

-- Verificar tabelas do master
USE master;
GO

PRINT 'Tabelas no database MASTER:';
SELECT name as TabelaMaster
FROM sys.tables
WHERE type = 'U'
  AND name NOT LIKE 'spt%'
  AND name NOT LIKE 'MS%'
ORDER BY name;
GO

-- Verificar tabelas do datasets
USE datasets;
GO

PRINT 'Tabelas no database DATASETS:';
SELECT name as TabelaDatasets
FROM sys.tables
WHERE type = 'U'
ORDER BY name;
GO

PRINT 'Contagem de registros no DATASETS:';
SELECT 'SP500_companies' as Tabela, COUNT(*) as Total FROM dbo.SP500_companies
UNION ALL
SELECT 'SP500_fred', COUNT(*) FROM dbo.SP500_fred
UNION ALL
SELECT 'CSI500', COUNT(*) FROM dbo.CSI500;
GO

PRINT '';
PRINT '========================================';
PRINT 'SETUP COMPLETO FINALIZADO COM SUCESSO!';
PRINT '========================================';
PRINT '';
PRINT 'Databases criados:';
PRINT '  - master: 8 tabelas (modelo dimensional)';
PRINT '  - datasets: 3 tabelas (dados brutos em 1 coluna registro)';
PRINT '';
PRINT 'Próximos passos:';
PRINT '  1. Atualize o DataGrip (F5)';
PRINT '  2. Rode o script 02_processar_dados_etl.sql para quebrar as colunas';
PRINT '  3. Depois rode as views e consultas analíticas';
PRINT '========================================';
GO
