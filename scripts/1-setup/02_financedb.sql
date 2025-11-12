IF NOT EXISTS (SELECT name FROM sys.databases WHERE name = 'FinanceDB')
BEGIN
    CREATE DATABASE FinanceDB;
END
GO

USE FinanceDB;
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
END
GO

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
END