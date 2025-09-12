use datasets

IF NOT EXISTS(SELECT name FROM sys.tables WHERE name = 'Indice')
    CREATE TABLE Indice (
    idIndice int not null,
    NomeIndice int,
    Descricao Nvarchar(80),
    PRIMARY KEY(idIndice)
    )

IF NOT EXISTS(SELECT name FROM sys.tables WHERE name = 'indiceSP500')
    CREATE TABLE indiceSP500 (
    idSP500 int not null,
    idIndice int not null,
    ValorFechamento decimal(8,6),
    PRIMARY KEY(idSP500),
    FOREIGN KEY (idIndice) REFERENCES Indice(idIndice)
    )

IF NOT EXISTS(SELECT name FROM sys.tables WHERE name = 'Empresas')
    CREATE TABLE Empresas (
    CIK int not null,
    Nome Nvarchar(80),
    Setor Varchar(80),
    DataEntrada Date,
    AnoFundacao smallint,
    Security Nvarchar(80),
    PRIMARY KEY(CIK)
    )

IF NOT EXISTS(SELECT name FROM sys.tables WHERE name = 'SubSetor')
    CREATE TABLE SubSetor(
    idSubSetor int not null,
    CIK int not null,
    Industry Nvarchar(80),
    PRIMARY KEY(idSubSetor),
    FOREIGN KEY (CIK) REFERENCES Empresas(CIK)
    )

IF NOT EXISTS(SELECT name FROM sys.tables WHERE name = 'Localizacao')
    CREATE TABLE Localizacao (
    idLocalizacao int not null,
    CIK int not null,
    Estado Varchar(30),
    Regiao Varchar(80),
    PRIMARY KEY(idLocalizacao),
    FOREIGN KEY (CIK) REFERENCES Empresas(CIK)
    )



IF NOT EXISTS(SELECT name FROM sys.tables WHERE name = 'precoAcao')
    CREATE TABLE precoAcao (
    idPrecoAcao int not null,
    EmpresasId int not null,
    "Open" decimal(8,6),
    High decimal(8,6),
    Low decimal(8,6),
    "Close" decimal(8,6),
    Volume int,
    primary key(idPrecoAcao),
    FOREIGN key(EmpresasId) REFERENCES Empresas(CIK)
    )

IF NOT EXISTS(SELECT name FROM sys.tables WHERE name = 'Tempo')
    CREATE TABLE Tempo (
    idTempo int not null,
    idIndiceSP500 int not null,
    idPrecoAcao int not null,
    DataCompleta date,
    ano smallint,
    mes tinyint,
    trimestre tinyint,
    dia_semana tinyint,
    PRIMARY KEY(idTempo),
    FOREIGN KEY(idIndiceSP500) REFERENCES indiceSP500(idSP500),
    FOREIGN KEY(idPrecoAcao) REFERENCES precoAcao(idPrecoAcao)
    )

IF NOT EXISTS(SELECT name FROM sys.tables WHERE name = 'Dividendos')
    CREATE TABLE Dividendos (
    IdDividendo int not null,
    idCIK int, 
    idTempo int,
    ValorDividendos int
    
    PRIMARY KEY(IdDividendo),
    FOREIGN KEY(idCIK) REFERENCES Empresas(CIK),
    FOREIGN KEY(idTempo) REFERENCES Tempo(idTempo)
    )