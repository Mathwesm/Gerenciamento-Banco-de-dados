CREATE TABLE CSI500_import
(
    codigo_empresa NVARCHAR(100),
    data_cotacao NVARCHAR(100),
    preco_abertura NVARCHAR(100),
    preco_maximo NVARCHAR(100),
    preco_minimo NVARCHAR(100),
    preco_fechamento NVARCHAR(100),
    volume NVARCHAR(100),
    amount NVARCHAR(100),
    outstanding_share NVARCHAR(100),
    turnover NVARCHAR(100),
    nome_empresa_en NVARCHAR(200),
    region_en NVARCHAR(100),
    industry_en NVARCHAR(100),
    subindustry_en NVARCHAR(100)
);


CREATE TABLE sp500companies_import
(
    Symbol VARCHAR(20),
    Security NVARCHAR(100),
    GICSSector NVARCHAR(100),
    GICSSubIndustry NVARCHAR(100),
    HeadquartersLocation NVARCHAR(100),
    DateAdded NVARCHAR(20),
    CIK NVARCHAR(20),
    Founded NVARCHAR(50)
);



CREATE TABLE sp500fred_import
(
    Data NVARCHAR(20),
    ClosePrice NVARCHAR(20)
);

BULK INSERT sp500companies_import
FROM '/datasets/S&P-500-companies.csv'
WITH (
    FIRSTROW = 2,
    FIELDTERMINATOR = ',',
    ROWTERMINATOR = '\n',
    TABLOCK,
    FORMAT='CSV'
);

BULK INSERT CSI500_import
FROM '/datasets/CSI500-part-1.csv'
WITH (
    FIRSTROW = 2,
    FIELDTERMINATOR = ',',
    ROWTERMINATOR = '\n',
    TABLOCK,
    FORMAT='CSV'
);

BULK INSERT CSI500_import
FROM '/datasets/CSI500-part-2.csv'
WITH (
    FIRSTROW = 2,
    FIELDTERMINATOR = ',',
    ROWTERMINATOR = '\n',
    TABLOCK,
    FORMAT='CSV'
);


BULK INSERT sp500fred_import
FROM '/datasets/S&P500-fred.csv'
WITH (
    FIRSTROW = 2,
    FIELDTERMINATOR = ',',
    ROWTERMINATOR = '\n',
    TABLOCK,
    FORMAT='CSV'
);
