-- ========================================
-- SCRIPT DE CRIAÇÃO DAS TABELAS - VERSÃO MELHORADA
-- Database: master
-- Descrição: Modelo dimensional para análise de ações S&P 500
-- ========================================

USE master;
GO

-- ========================================
-- TABELA: Indice
-- Descrição: Armazena informações sobre índices financeiros (S&P 500, etc)
-- ========================================
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
    PRINT 'Tabela Indice criada com sucesso.';
END
GO

-- ========================================
-- TABELA: IndiceSP500
-- Descrição: Valores históricos do índice S&P 500
-- ========================================
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
    PRINT 'Tabela IndiceSP500 criada com sucesso.';
END
GO

-- ========================================
-- TABELA: Empresas
-- Descrição: Cadastro de empresas listadas no S&P 500
-- ========================================
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
    PRINT 'Tabela Empresas criada com sucesso.';
END
GO

-- ========================================
-- TABELA: SubSetor
-- Descrição: Classificação de indústrias/subsetores das empresas
-- ========================================
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
    PRINT 'Tabela SubSetor criada com sucesso.';
END
GO

-- ========================================
-- TABELA: Localizacao
-- Descrição: Localização geográfica das empresas
-- ========================================
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
    PRINT 'Tabela Localizacao criada com sucesso.';
END
GO

-- ========================================
-- TABELA: Tempo (Dimensão Temporal)
-- Descrição: Dimensão de tempo para análises temporais
-- ========================================
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
    PRINT 'Tabela Tempo criada com sucesso.';
END
GO

-- ========================================
-- TABELA: PrecoAcao
-- Descrição: Preços históricos das ações das empresas
-- ========================================
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
    PRINT 'Tabela PrecoAcao criada com sucesso.';
END
GO

-- ========================================
-- TABELA: Dividendos
-- Descrição: Histórico de dividendos pagos pelas empresas
-- ========================================
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
    PRINT 'Tabela Dividendos criada com sucesso.';
END
GO

-- ========================================
-- CRIAR ÍNDICES PARA MELHORAR PERFORMANCE
-- ========================================

-- Índices para consultas frequentes por data
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

PRINT '========================================';
PRINT 'TODAS AS TABELAS FORAM CRIADAS COM SUCESSO!';
PRINT '========================================';
GO
