USE FinanceDB;
GO

INSERT INTO Tempo (DataCompleta, Ano, Mes, Dia, Trimestre, Semestre, DiaSemana, NomeDiaSemana, NomeMes)
SELECT DISTINCT
    observation_date,
    YEAR(observation_date),
    MONTH(observation_date),
    DAY(observation_date),
    DATEPART(QUARTER, observation_date),
    CASE WHEN MONTH(observation_date) <= 6 THEN 1 ELSE 2 END,
    DATEPART(WEEKDAY, observation_date),
    DATENAME(WEEKDAY, observation_date),
    DATENAME(MONTH, observation_date)
FROM datasets.dbo.SP500
WHERE observation_date IS NOT NULL
  AND NOT EXISTS (SELECT 1 FROM Tempo WHERE DataCompleta = observation_date);
GO

WITH RankedCompanies AS (
    SELECT DISTINCT
        cik,
        company_name,
        symbol,
        sector,
        date_added_sp500,
        TRY_CAST(founded_year AS SMALLINT) AS founded_year,
        ROW_NUMBER() OVER (PARTITION BY cik ORDER BY symbol) as rn
    FROM datasets.dbo.SP500
    WHERE cik IS NOT NULL
)
MERGE Empresas AS target
USING (
    SELECT
        cik,
        company_name,
        symbol,
        sector,
        date_added_sp500,
        founded_year
    FROM RankedCompanies
    WHERE rn = 1
) AS source
ON target.CIK = source.cik
WHEN MATCHED THEN
    UPDATE SET
        NomeEmpresa = source.company_name,
        Ticker = source.symbol,
        Setor = source.sector,
        DataEntrada = source.date_added_sp500,
        AnoFundacao = source.founded_year
WHEN NOT MATCHED THEN
    INSERT (CIK, NomeEmpresa, Ticker, Setor, DataEntrada, AnoFundacao)
    VALUES (source.cik, source.company_name, source.symbol, source.sector,
            source.date_added_sp500, source.founded_year);

GO


WITH RankedSubSectors AS (
    SELECT DISTINCT
        cik,
        sector,
        sub_industry,
        ROW_NUMBER() OVER (PARTITION BY cik ORDER BY symbol) as rn
    FROM datasets.dbo.SP500
    WHERE cik IS NOT NULL
)
MERGE SubSetor AS target
USING (
    SELECT
        cik,
        sector,
        sub_industry
    FROM RankedSubSectors
    WHERE rn = 1
) AS source
ON target.CIK = source.cik
WHEN MATCHED THEN
    UPDATE SET
        Industria = source.sector,
        SubIndustria = source.sub_industry,
        Categoria = source.sector
WHEN NOT MATCHED THEN
    INSERT (CIK, Industria, SubIndustria, Categoria)
    VALUES (source.cik, source.sector, source.sub_industry, source.sector);

GO


WITH RankedLocations AS (
    SELECT DISTINCT
        cik,
        CASE
            WHEN CHARINDEX(',', headquarters) > 0
            THEN LTRIM(RTRIM(REPLACE(REPLACE(SUBSTRING(headquarters, 1, CHARINDEX(',', headquarters) - 1), '"', ''), '''', '')))
            ELSE LTRIM(RTRIM(REPLACE(REPLACE(headquarters, '"', ''), '''', '')))
        END AS cidade,
        CASE
            WHEN CHARINDEX(',', headquarters) > 0
            THEN LTRIM(RTRIM(REPLACE(REPLACE(SUBSTRING(headquarters, CHARINDEX(',', headquarters) + 1, LEN(headquarters)), '"', ''), '''', '')))
            ELSE NULL
        END AS estado,
        ROW_NUMBER() OVER (PARTITION BY cik ORDER BY symbol) as rn
    FROM datasets.dbo.SP500
    WHERE cik IS NOT NULL AND headquarters IS NOT NULL
),
LocationWithRegion AS (
    SELECT
        cik,
        cidade,
        estado,
        -- Derivar Regiao do Estado
        CASE
            WHEN estado IN ('California', 'Oregon', 'Washington', 'Nevada', 'Arizona', 'Hawaii', 'Alaska') THEN 'West'
            WHEN estado IN ('Texas', 'Oklahoma', 'New Mexico', 'Arkansas', 'Louisiana') THEN 'Southwest'
            WHEN estado IN ('Illinois', 'Indiana', 'Michigan', 'Ohio', 'Wisconsin', 'Minnesota', 'Iowa', 'Missouri', 'North Dakota', 'South Dakota', 'Nebraska', 'Kansas') THEN 'Midwest'
            WHEN estado IN ('New York', 'Pennsylvania', 'New Jersey', 'Massachusetts', 'Connecticut', 'Rhode Island', 'Vermont', 'New Hampshire', 'Maine') THEN 'Northeast'
            WHEN estado IN ('Florida', 'Georgia', 'North Carolina', 'South Carolina', 'Virginia', 'West Virginia', 'Maryland', 'Delaware', 'Kentucky', 'Tennessee', 'Alabama', 'Mississippi') THEN 'Southeast'
            WHEN estado IN ('Montana', 'Idaho', 'Wyoming', 'Colorado', 'Utah') THEN 'Mountain'
            ELSE 'Other'
        END AS regiao
    FROM RankedLocations
    WHERE rn = 1
)
MERGE Localizacao AS target
USING LocationWithRegion AS source
ON target.CIK = source.cik
WHEN MATCHED THEN
    UPDATE SET
        Cidade = source.cidade,
        Estado = source.estado,
        Pais = 'Estados Unidos',
        Regiao = source.regiao
WHEN NOT MATCHED THEN
    INSERT (CIK, Cidade, Estado, Pais, Regiao, CodigoPostal)
    VALUES (source.cik, source.cidade, source.estado, 'Estados Unidos', source.regiao, NULL);

GO
INSERT INTO PrecoAcao (
    CIK,
    IdTempo,
    PrecoAbertura,
    PrecoMaximo,
    PrecoMinimo,
    PrecoFechamento,
    PrecoFechamentoAjustado,
    Volume,
    VariacaoDiaria,
    VariacaoPercentual
)
SELECT
    sp.cik,
    t.IdTempo,
    sp.open_price,
    sp.high_price,
    sp.low_price,
    sp.close_price,
    sp.close_price,
    sp.volume,
    NULL,
    sp.price_change_percent
FROM datasets.dbo.SP500 sp
INNER JOIN Tempo t ON t.DataCompleta = sp.observation_date
WHERE sp.cik IS NOT NULL
  AND sp.observation_date IS NOT NULL
  AND EXISTS (SELECT 1 FROM Empresas WHERE CIK = sp.cik);

GO

INSERT INTO Dividendos (
    CIK,
    IdTempo,
    ValorDividendo,
    TipoDividendo,
    FrequenciaPagamento,
    DataExDividendo,
    DataPagamento
)
SELECT
    sp.cik,
    t.IdTempo,
    sp.dividend_yield,
    'Yield',
    NULL,
    sp.observation_date,
    NULL
FROM datasets.dbo.SP500 sp
INNER JOIN Tempo t ON t.DataCompleta = sp.observation_date
WHERE sp.cik IS NOT NULL
  AND sp.observation_date IS NOT NULL
  AND sp.dividend_yield IS NOT NULL
  AND sp.dividend_yield > 0
  AND EXISTS (SELECT 1 FROM Empresas WHERE CIK = sp.cik);

GO

WITH PrecoComAnterior AS (
    SELECT
        IdPrecoAcao,
        CIK,
        PrecoFechamento,
        LAG(PrecoFechamento) OVER (PARTITION BY CIK ORDER BY IdTempo) AS PrecoAnterior
    FROM PrecoAcao
    WHERE PrecoFechamento IS NOT NULL
)
UPDATE p
SET VariacaoDiaria = pca.PrecoFechamento - pca.PrecoAnterior
FROM PrecoAcao p
INNER JOIN PrecoComAnterior pca ON p.IdPrecoAcao = pca.IdPrecoAcao
WHERE pca.PrecoAnterior IS NOT NULL;

GO


INSERT INTO SP500Historico (DataReferencia, ValorFechamento, ValorAbertura, ValorMaximo, ValorMinimo, VolumeNegociado)
SELECT
    sp.observation_date,
    ISNULL(
        (SELECT AVG(TRY_CAST(sp2.sp500_index AS DECIMAL(18,2)))
         FROM datasets.dbo.SP500 sp2
         WHERE sp2.observation_date = sp.observation_date AND sp2.sp500_index IS NOT NULL),
        AVG(TRY_CAST(sp.close_price AS DECIMAL(18,2)))
    ) AS ValorFechamento,
    ISNULL(
        (SELECT AVG(TRY_CAST(sp2.sp500_index AS DECIMAL(18,2)))
         FROM datasets.dbo.SP500 sp2
         WHERE sp2.observation_date = sp.observation_date AND sp2.sp500_index IS NOT NULL),
        AVG(TRY_CAST(sp.open_price AS DECIMAL(18,2)))
    ) AS ValorAbertura,
    ISNULL(
        (SELECT AVG(TRY_CAST(sp2.sp500_index AS DECIMAL(18,2)))
         FROM datasets.dbo.SP500 sp2
         WHERE sp2.observation_date = sp.observation_date AND sp2.sp500_index IS NOT NULL),
        MAX(TRY_CAST(sp.high_price AS DECIMAL(18,2)))
    ) AS ValorMaximo,
    ISNULL(
        (SELECT AVG(TRY_CAST(sp2.sp500_index AS DECIMAL(18,2)))
         FROM datasets.dbo.SP500 sp2
         WHERE sp2.observation_date = sp.observation_date AND sp2.sp500_index IS NOT NULL),
        MIN(TRY_CAST(sp.low_price AS DECIMAL(18,2)))
    ) AS ValorMinimo,
    SUM(TRY_CAST(sp.volume AS BIGINT)) AS VolumeNegociado
FROM datasets.dbo.SP500 sp
WHERE sp.observation_date IS NOT NULL
  AND NOT EXISTS (
      SELECT 1 FROM SP500Historico
      WHERE DataReferencia = sp.observation_date
  )
GROUP BY sp.observation_date;

GO

INSERT INTO Tempo (DataCompleta, Ano, Mes, Dia, Trimestre, Semestre, DiaSemana, NomeDiaSemana, NomeMes, EhFimDeSemana, EhFeriado)
SELECT DISTINCT
    [date],
    YEAR([date]),
    MONTH([date]),
    DAY([date]),
    DATEPART(QUARTER, [date]),
    CASE WHEN MONTH([date]) <= 6 THEN 1 ELSE 2 END,
    DATEPART(WEEKDAY, [date]),
    DATENAME(WEEKDAY, [date]),
    DATENAME(MONTH, [date]),
    CASE WHEN DATEPART(WEEKDAY, [date]) IN (1, 7) THEN 1 ELSE 0 END,
    0
FROM datasets.dbo.CSI500
WHERE [date] IS NOT NULL
  AND NOT EXISTS (SELECT 1 FROM Tempo WHERE DataCompleta = [date]);
GO

--TODO tem duas colunas que não tem dados
WITH RankedCompanies AS (
    SELECT DISTINCT
        c.codigo_empresa,
        c.nome_empresa_en,
        c.industry_en,
        -- c.subindustry_en, -- Coluna comentada (não há dados)
        -- c.region_en, -- Coluna comentada (não há dados)
        c.[date],
        ROW_NUMBER() OVER (PARTITION BY c.codigo_empresa ORDER BY c.[date]) as rn
    FROM datasets.dbo.CSI500 c
    WHERE c.codigo_empresa IS NOT NULL
),
FirstDatePerCompany AS (
    SELECT
        codigo_empresa,
        nome_empresa_en,
        industry_en,
        -- subindustry_en, -- Coluna comentada (não há dados)
        -- region_en, -- Coluna comentada (não há dados)
        MIN([date]) OVER (PARTITION BY codigo_empresa) AS DataPrimeiraObservacao
    FROM RankedCompanies
    WHERE rn = 1
)
MERGE EmpresasCSI500 AS target
USING FirstDatePerCompany AS source
ON target.CodigoEmpresa = source.codigo_empresa
WHEN NOT MATCHED THEN
    INSERT (CodigoEmpresa, NomeEmpresa, NomeEmpresaEN, Industria, SubIndustria, Regiao, DataPrimeiraObservacao)
    VALUES (
        source.codigo_empresa, 
        NULL, -- NomeEmpresa (não fornecido, então insira como NULL ou outro valor adequado)
        source.nome_empresa_en, 
        source.industry_en, 
        NULL, -- SubIndustria (não fornecido, então insira como NULL ou outro valor adequado)
        NULL, -- Regiao (não fornecido, então insira como NULL ou outro valor adequado)
        source.DataPrimeiraObservacao
    );
GO

INSERT INTO PrecoAcaoCSI500 (
    CodigoEmpresa,
    IdTempo,
    PrecoAbertura,
    PrecoMaximo,
    PrecoMinimo,
    PrecoFechamento,
    Volume,
    Amount,
    OutstandingShare,
    Turnover
)
SELECT
    c.codigo_empresa,
    t.IdTempo,
    TRY_CAST(c.[open] AS DECIMAL(18,4)),
    TRY_CAST(c.[high] AS DECIMAL(18,4)),
    TRY_CAST(c.[low] AS DECIMAL(18,4)),
    TRY_CAST(c.[close] AS DECIMAL(18,4)),
    TRY_CAST(c.volume AS DECIMAL(20,2)),
    TRY_CAST(c.amount AS DECIMAL(20,2)),
    TRY_CAST(c.outstanding_share AS DECIMAL(20,2)),
    TRY_CAST(c.turnover AS DECIMAL(18,8))
FROM datasets.dbo.CSI500 c
INNER JOIN Tempo t ON t.DataCompleta = c.[date]
WHERE c.codigo_empresa IS NOT NULL
  AND c.[date] IS NOT NULL
  AND EXISTS (SELECT 1 FROM EmpresasCSI500 WHERE CodigoEmpresa = c.codigo_empresa);
GO

INSERT INTO CSI500Historico (DataReferencia, ValorMedioMercado, VolumeTotal, QtdEmpresasNegociadas)
SELECT
    c.[date],
    AVG(TRY_CAST(c.[close] AS DECIMAL(18,4))) AS ValorMedioMercado,
    SUM(TRY_CAST(c.volume AS DECIMAL(20,2))) AS VolumeTotal,
    COUNT(DISTINCT c.codigo_empresa) AS QtdEmpresasNegociadas
FROM datasets.dbo.CSI500 c
WHERE c.[date] IS NOT NULL
  AND TRY_CAST(c.[close] AS DECIMAL(18,4)) IS NOT NULL
  AND NOT EXISTS (SELECT 1 FROM CSI500Historico WHERE DataReferencia = c.[date])
GROUP BY c.[date];