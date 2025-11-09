-- =============================================
-- Script: Criar Tabelas Normalizadas para Análise
-- Descrição: Cria estrutura otimizada para análises de mercado
-- Autor: Sistema de Análise Financeira
-- Data: 2025-11-07
-- =============================================

USE datasets;
GO

-- =============================================
-- LIMPAR TABELAS EXISTENTES (SE NECESSÁRIO)
-- =============================================

IF OBJECT_ID('dbo.PrecoAcao', 'U') IS NOT NULL DROP TABLE dbo.PrecoAcao;
IF OBJECT_ID('dbo.Empresas', 'U') IS NOT NULL DROP TABLE dbo.Empresas;
IF OBJECT_ID('dbo.IndiceSP500', 'U') IS NOT NULL DROP TABLE dbo.IndiceSP500;
IF OBJECT_ID('dbo.AcoesChinesas', 'U') IS NOT NULL DROP TABLE dbo.AcoesChinesas;
GO

-- =============================================
-- TABELA: Empresas (S&P 500)
-- =============================================
CREATE TABLE dbo.Empresas (
    EmpresaID INT IDENTITY(1,1) PRIMARY KEY,
    Symbol NVARCHAR(10) NOT NULL UNIQUE,
    Security NVARCHAR(255) NOT NULL,
    GICSSector NVARCHAR(100),
    GICSSubIndustry NVARCHAR(150),
    HeadquartersLocation NVARCHAR(255),
    DateAdded DATE,
    CIK INT,
    Founded INT,
    INDEX IX_Empresas_Symbol (Symbol),
    INDEX IX_Empresas_Sector (GICSSector)
);
GO

-- =============================================
-- TABELA: IndiceSP500 (Valores históricos do índice)
-- =============================================
CREATE TABLE dbo.IndiceSP500 (
    IndiceID INT IDENTITY(1,1) PRIMARY KEY,
    ObservationDate DATE NOT NULL UNIQUE,
    SP500Value DECIMAL(10, 2) NOT NULL,
    INDEX IX_IndiceSP500_Date (ObservationDate)
);
GO

-- =============================================
-- TABELA: AcoesChinesas (CSI500)
-- =============================================
CREATE TABLE dbo.AcoesChinesas (
    AcaoChinesaID INT IDENTITY(1,1) PRIMARY KEY,
    Symbol NVARCHAR(10) NOT NULL,
    TradeDate DATE NOT NULL,
    OpenPrice DECIMAL(18, 4),
    HighPrice DECIMAL(18, 4),
    LowPrice DECIMAL(18, 4),
    ClosePrice DECIMAL(18, 4),
    Volume DECIMAL(18, 2),
    Amount DECIMAL(18, 2),
    SharesOutstanding DECIMAL(18, 2),
    TurnoverRate DECIMAL(10, 8),
    CompanyName NVARCHAR(255),
    CompanyNameEnglish NVARCHAR(255),
    Industry NVARCHAR(100),
    Observations NVARCHAR(MAX),
    INDEX IX_AcoesChinesas_Symbol_Date (Symbol, TradeDate),
    INDEX IX_AcoesChinesas_Date (TradeDate),
    INDEX IX_AcoesChinesas_Industry (Industry)
);
GO

-- =============================================
-- POPULAR TABELA: Empresas
-- =============================================
PRINT 'Populando tabela Empresas...';
GO

WITH EmpresasRaw AS (
    SELECT
        -- Symbol
        LTRIM(RTRIM(SUBSTRING(registro, 1, c1 - 1)))                                       AS Symbol,

        -- Security
        LTRIM(RTRIM(SUBSTRING(registro, c1 + 1, c2 - c1 - 1)))                             AS Security,

        -- GICS Sector
        LTRIM(RTRIM(SUBSTRING(registro, c2 + 1, c3 - c2 - 1)))                             AS GICSSector,

        -- GICS Sub-Industry
        LTRIM(RTRIM(SUBSTRING(registro, c3 + 1, c4 - c3 - 1)))                             AS GICSSubIndustry,

        -- Headquarters Location
        LTRIM(RTRIM(SUBSTRING(registro, c4 + 1, c5 - c4 - 1)))                             AS HeadquartersLocation,

        -- Date Added
        TRY_CAST(LTRIM(RTRIM(SUBSTRING(registro, c5 + 1, c6 - c5 - 1))) AS DATE)          AS DateAdded,

        -- CIK
        TRY_CAST(LTRIM(RTRIM(SUBSTRING(registro, c6 + 1, c7 - c6 - 1))) AS INT)           AS CIK,

        -- Founded
        TRY_CAST(LTRIM(RTRIM(SUBSTRING(registro, c7 + 1, LEN(registro) - c7))) AS INT)    AS Founded
    FROM dbo.SP500_companies AS s
    CROSS APPLY (
        SELECT
            CHARINDEX(',', registro)                                                              AS c1,
            CHARINDEX(',', registro, CHARINDEX(',', registro) + 1)                                AS c2,
            CHARINDEX(',', registro, CHARINDEX(',', registro, CHARINDEX(',', registro) + 1) + 1)  AS c3,
            CHARINDEX(',', registro, CHARINDEX(',', registro, CHARINDEX(',', registro, CHARINDEX(',', registro) + 1) + 1) + 1) AS c4,
            CHARINDEX(',', registro, CHARINDEX(',', registro, CHARINDEX(',', registro, CHARINDEX(',', registro, CHARINDEX(',', registro) + 1) + 1) + 1) + 1) AS c5,
            CHARINDEX(',', registro, CHARINDEX(',', registro, CHARINDEX(',', registro, CHARINDEX(',', registro, CHARINDEX(',', registro, CHARINDEX(',', registro) + 1) + 1) + 1) + 1) + 1) AS c6,
            CHARINDEX(',', registro, CHARINDEX(',', registro, CHARINDEX(',', registro, CHARINDEX(',', registro, CHARINDEX(',', registro, CHARINDEX(',', registro, CHARINDEX(',', registro) + 1) + 1) + 1) + 1) + 1) + 1) AS c7
    ) p
    WHERE
        registro NOT LIKE 'Symbol,Security%'   -- ignorar header
        AND registro IS NOT NULL
        AND LEN(registro) > 0
        AND c1 > 0 AND c2 > c1 AND c3 > c2 AND c4 > c3 AND c5 > c4 AND c6 > c5 AND c7 > c6
        AND (LEN(registro) - LEN(REPLACE(registro, ',', ''))) >= 7  -- pelo menos 8 colunas
),
EmpresasDedup AS (
    SELECT
        *,
        ROW_NUMBER() OVER (
            PARTITION BY Symbol
            ORDER BY DateAdded DESC, Security
        ) AS rn
    FROM EmpresasRaw
)
INSERT INTO dbo.Empresas (Symbol, Security, GICSSector, GICSSubIndustry, HeadquartersLocation, DateAdded, CIK, Founded)
SELECT
    Symbol,
    Security,
    GICSSector,
    GICSSubIndustry,
    HeadquartersLocation,
    DateAdded,
    CIK,
    Founded
FROM EmpresasDedup
WHERE rn = 1;   -- mantém apenas 1 linha por Symbol

PRINT 'Empresas populadas: ' + CAST(@@ROWCOUNT AS VARCHAR(10));
GO

-- =============================================
-- POPULAR TABELA: IndiceSP500
-- =============================================
PRINT 'Populando tabela IndiceSP500...';
GO

WITH RawIndice AS (
    SELECT
        LTRIM(RTRIM(SUBSTRING(registro, 1, CHARINDEX(',', registro) - 1)))              AS DateStr,
        LTRIM(RTRIM(SUBSTRING(registro, CHARINDEX(',', registro) + 1, LEN(registro)))) AS ValueStr
    FROM dbo.SP500_fred
    WHERE registro NOT LIKE 'observation_date%'   -- ignorar header
      AND registro IS NOT NULL
      AND LEN(registro) > 0
      AND CHARINDEX(',', registro) > 0
),
ParsedIndice AS (
    SELECT
        TRY_CAST(DateStr  AS DATE)          AS ObservationDate,
        TRY_CAST(ValueStr AS DECIMAL(10,2)) AS SP500Value
    FROM RawIndice
    WHERE TRY_CAST(DateStr  AS DATE)          IS NOT NULL
      AND TRY_CAST(ValueStr AS DECIMAL(10,2)) IS NOT NULL
),
DedupIndice AS (
    SELECT
        ObservationDate,
        SP500Value,
        ROW_NUMBER() OVER (
            PARTITION BY ObservationDate
            ORDER BY SP500Value DESC   -- se houver duplicadas, fica com o maior valor
        ) AS rn
    FROM ParsedIndice
)
INSERT INTO dbo.IndiceSP500 (ObservationDate, SP500Value)
SELECT
    ObservationDate,
    SP500Value
FROM DedupIndice
WHERE rn = 1;   -- garante 1 linha por data

PRINT 'Índice S&P500 populado: ' + CAST(@@ROWCOUNT AS VARCHAR(10));
GO

-- =============================================
-- POPULAR TABELA: AcoesChinesas
-- =============================================
PRINT 'Populando tabela AcoesChinesas...';
GO

INSERT INTO dbo.AcoesChinesas (
    Symbol, TradeDate, OpenPrice, HighPrice, LowPrice, ClosePrice,
    Volume, Amount, SharesOutstanding, TurnoverRate,
    CompanyName, CompanyNameEnglish, Industry, Observations
)
SELECT
    -- Symbol
    LTRIM(RTRIM(SUBSTRING(registro, 1, CHARINDEX(',', registro) - 1))) as Symbol,

    -- Date
    TRY_CAST(
        LTRIM(RTRIM(
            SUBSTRING(registro,
                CHARINDEX(',', registro) + 1,
                CHARINDEX(',', registro, CHARINDEX(',', registro) + 1) - CHARINDEX(',', registro) - 1
            )
        )) as DATE
    ) as TradeDate,

    -- Open
    TRY_CAST(
        LTRIM(RTRIM(
            SUBSTRING(registro,
                CHARINDEX(',', registro, CHARINDEX(',', registro) + 1) + 1,
                CHARINDEX(',', registro, CHARINDEX(',', registro, CHARINDEX(',', registro) + 1) + 1) -
                CHARINDEX(',', registro, CHARINDEX(',', registro) + 1) - 1
            )
        )) as DECIMAL(18, 4)
    ) as OpenPrice,

    -- High
    TRY_CAST(
        LTRIM(RTRIM(
            SUBSTRING(registro,
                CHARINDEX(',', registro, CHARINDEX(',', registro, CHARINDEX(',', registro) + 1) + 1) + 1,
                CHARINDEX(',', registro, CHARINDEX(',', registro, CHARINDEX(',', registro, CHARINDEX(',', registro) + 1) + 1) + 1) -
                CHARINDEX(',', registro, CHARINDEX(',', registro, CHARINDEX(',', registro) + 1) + 1) - 1
            )
        )) as DECIMAL(18, 4)
    ) as HighPrice,

    -- Low
    TRY_CAST(
        REVERSE(
            SUBSTRING(
                REVERSE(registro),
                CHARINDEX(',', REVERSE(registro), CHARINDEX(',', REVERSE(registro), CHARINDEX(',', REVERSE(registro), CHARINDEX(',', REVERSE(registro), CHARINDEX(',', REVERSE(registro), CHARINDEX(',', REVERSE(registro), CHARINDEX(',', REVERSE(registro), CHARINDEX(',', REVERSE(registro)) + 1) + 1) + 1) + 1) + 1) + 1) + 1) + 1,
                CHARINDEX(',', REVERSE(registro), CHARINDEX(',', REVERSE(registro), CHARINDEX(',', REVERSE(registro), CHARINDEX(',', REVERSE(registro), CHARINDEX(',', REVERSE(registro), CHARINDEX(',', REVERSE(registro), CHARINDEX(',', REVERSE(registro), CHARINDEX(',', REVERSE(registro)) + 1) + 1) + 1) + 1) + 1) + 1) + 1) -
                CHARINDEX(',', REVERSE(registro), CHARINDEX(',', REVERSE(registro), CHARINDEX(',', REVERSE(registro), CHARINDEX(',', REVERSE(registro), CHARINDEX(',', REVERSE(registro), CHARINDEX(',', REVERSE(registro), CHARINDEX(',', REVERSE(registro)) + 1) + 1) + 1) + 1) + 1) + 1) - 1
            )
        ) as DECIMAL(18, 4)
    ) as LowPrice,

    -- Close
    TRY_CAST(
        REVERSE(
            LTRIM(RTRIM(
                SUBSTRING(
                    REVERSE(registro),
                    CHARINDEX(',', REVERSE(registro), CHARINDEX(',', REVERSE(registro), CHARINDEX(',', REVERSE(registro), CHARINDEX(',', REVERSE(registro), CHARINDEX(',', REVERSE(registro), CHARINDEX(',', REVERSE(registro), CHARINDEX(',', REVERSE(registro)) + 1) + 1) + 1) + 1) + 1) + 1) + 1,
                    CHARINDEX(',', REVERSE(registro), CHARINDEX(',', REVERSE(registro), CHARINDEX(',', REVERSE(registro), CHARINDEX(',', REVERSE(registro), CHARINDEX(',', REVERSE(registro), CHARINDEX(',', REVERSE(registro), CHARINDEX(',', REVERSE(registro), CHARINDEX(',', REVERSE(registro)) + 1) + 1) + 1) + 1) + 1) + 1) + 1) -
                    CHARINDEX(',', REVERSE(registro), CHARINDEX(',', REVERSE(registro), CHARINDEX(',', REVERSE(registro), CHARINDEX(',', REVERSE(registro), CHARINDEX(',', REVERSE(registro), CHARINDEX(',', REVERSE(registro)) + 1) + 1) + 1) + 1) + 1) - 1
                )
            ))
        ) as DECIMAL(18, 4)
    ) as ClosePrice,

    -- Volume
    TRY_CAST(
        REVERSE(
            LTRIM(RTRIM(
                SUBSTRING(
                    REVERSE(registro),
                    CHARINDEX(',', REVERSE(registro), CHARINDEX(',', REVERSE(registro), CHARINDEX(',', REVERSE(registro), CHARINDEX(',', REVERSE(registro), CHARINDEX(',', REVERSE(registro), CHARINDEX(',', REVERSE(registro)) + 1) + 1) + 1) + 1) + 1) + 1,
                    CHARINDEX(',', REVERSE(registro), CHARINDEX(',', REVERSE(registro), CHARINDEX(',', REVERSE(registro), CHARINDEX(',', REVERSE(registro), CHARINDEX(',', REVERSE(registro), CHARINDEX(',', REVERSE(registro), CHARINDEX(',', REVERSE(registro)) + 1) + 1) + 1) + 1) + 1) + 1) -
                    CHARINDEX(',', REVERSE(registro), CHARINDEX(',', REVERSE(registro), CHARINDEX(',', REVERSE(registro), CHARINDEX(',', REVERSE(registro), CHARINDEX(',', REVERSE(registro)) + 1) + 1) + 1) + 1) - 1
                )
            ))
        ) as DECIMAL(18, 2)
    ) as Volume,

    -- Amount
    TRY_CAST(
        REVERSE(
            LTRIM(RTRIM(
                SUBSTRING(
                    REVERSE(registro),
                    CHARINDEX(',', REVERSE(registro), CHARINDEX(',', REVERSE(registro), CHARINDEX(',', REVERSE(registro), CHARINDEX(',', REVERSE(registro), CHARINDEX(',', REVERSE(registro)) + 1) + 1) + 1) + 1) + 1,
                    CHARINDEX(',', REVERSE(registro), CHARINDEX(',', REVERSE(registro), CHARINDEX(',', REVERSE(registro), CHARINDEX(',', REVERSE(registro), CHARINDEX(',', REVERSE(registro), CHARINDEX(',', REVERSE(registro)) + 1) + 1) + 1) + 1) + 1) -
                    CHARINDEX(',', REVERSE(registro), CHARINDEX(',', REVERSE(registro), CHARINDEX(',', REVERSE(registro), CHARINDEX(',', REVERSE(registro)) + 1) + 1) + 1) - 1
                )
            ))
        ) as DECIMAL(18, 2)
    ) as Amount,

    -- SharesOutstanding
    TRY_CAST(
        REVERSE(
            LTRIM(RTRIM(
                SUBSTRING(
                    REVERSE(registro),
                    CHARINDEX(',', REVERSE(registro), CHARINDEX(',', REVERSE(registro), CHARINDEX(',', REVERSE(registro), CHARINDEX(',', REVERSE(registro)) + 1) + 1) + 1) + 1,
                    CHARINDEX(',', REVERSE(registro), CHARINDEX(',', REVERSE(registro), CHARINDEX(',', REVERSE(registro), CHARINDEX(',', REVERSE(registro), CHARINDEX(',', REVERSE(registro)) + 1) + 1) + 1) + 1) -
                    CHARINDEX(',', REVERSE(registro), CHARINDEX(',', REVERSE(registro), CHARINDEX(',', REVERSE(registro)) + 1) + 1) - 1
                )
            ))
        ) as DECIMAL(18, 2)
    ) as SharesOutstanding,

    -- TurnoverRate
    TRY_CAST(
        REVERSE(
            LTRIM(RTRIM(
                SUBSTRING(
                    REVERSE(registro),
                    CHARINDEX(',', REVERSE(registro), CHARINDEX(',', REVERSE(registro), CHARINDEX(',', REVERSE(registro)) + 1) + 1) + 1,
                    CHARINDEX(',', REVERSE(registro), CHARINDEX(',', REVERSE(registro), CHARINDEX(',', REVERSE(registro), CHARINDEX(',', REVERSE(registro)) + 1) + 1) + 1) -
                    CHARINDEX(',', REVERSE(registro), CHARINDEX(',', REVERSE(registro)) + 1) - 1
                )
            ))
        ) as DECIMAL(10, 8)
    ) as TurnoverRate,

    -- CompanyName
    REVERSE(
        LTRIM(RTRIM(
            SUBSTRING(
                REVERSE(registro),
                CHARINDEX(',', REVERSE(registro), CHARINDEX(',', REVERSE(registro)) + 1) + 1,
                CHARINDEX(',', REVERSE(registro), CHARINDEX(',', REVERSE(registro), CHARINDEX(',', REVERSE(registro)) + 1) + 1) -
                CHARINDEX(',', REVERSE(registro)) - 1
            )
        ))
    ) as CompanyName,

    -- CompanyNameEnglish
    REVERSE(
        LTRIM(RTRIM(
            SUBSTRING(
                REVERSE(registro),
                CHARINDEX(',', REVERSE(registro)) + 1,
                CHARINDEX(',', REVERSE(registro), CHARINDEX(',', REVERSE(registro)) + 1) -
                CHARINDEX(',', REVERSE(registro)) - 1
            )
        ))
    ) as CompanyNameEnglish,

    -- Industry (penúltimo campo)
    REVERSE(
        LTRIM(RTRIM(
            SUBSTRING(REVERSE(registro), 1, CHARINDEX(',', REVERSE(registro)) - 1)
        ))
    ) as Industry,

    -- Observations (último campo) – não estamos parseando, fica NULL
    NULL as Observations

FROM dbo.CSI500
WHERE registro NOT LIKE 'Symbol,Date%'        -- Ignorar header
  AND registro IS NOT NULL
  AND LEN(registro) > 0
  AND (LEN(registro) - LEN(REPLACE(registro, ',', ''))) >= 13;  -- pelo menos 14 colunas

PRINT 'Ações Chinesas populadas: ' + CAST(@@ROWCOUNT AS VARCHAR(10));
GO

-- =============================================
-- VERIFICAÇÃO FINAL
-- =============================================
PRINT '';
PRINT '=============================================';
PRINT 'VERIFICAÇÃO FINAL DAS TABELAS';
PRINT '=============================================';
GO

SELECT 'Empresas'      as Tabela, COUNT(*) as Total FROM dbo.Empresas
UNION ALL
SELECT 'IndiceSP500'   as Tabela, COUNT(*)          FROM dbo.IndiceSP500
UNION ALL
SELECT 'AcoesChinesas' as Tabela, COUNT(*)          FROM dbo.AcoesChinesas;
GO

PRINT '';
PRINT 'Amostra de dados - Empresas:';
SELECT TOP 5 Symbol, Security, GICSSector FROM dbo.Empresas ORDER BY Symbol;
GO

PRINT '';
PRINT 'Amostra de dados - IndiceSP500:';
SELECT TOP 5 ObservationDate, SP500Value FROM dbo.IndiceSP500 ORDER BY ObservationDate DESC;
GO

PRINT '';
PRINT 'Amostra de dados - AcoesChinesas:';
SELECT TOP 5 Symbol, TradeDate, ClosePrice, Volume FROM dbo.AcoesChinesas ORDER BY TradeDate DESC;
GO

PRINT '';
PRINT '=============================================';
PRINT 'TABELAS NORMALIZADAS CRIADAS COM SUCESSO!';
PRINT '=============================================';
GO
