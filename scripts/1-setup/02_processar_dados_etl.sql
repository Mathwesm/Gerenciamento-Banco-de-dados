-- ========================================
-- SCRIPT 02: PROCESSAR DADOS (ETL)
-- ========================================
-- Descrição: Processa dados brutos e popula o modelo dimensional
-- Lê dados de: datasets.dbo.SP500_data e datasets.CSI500
-- Popula: FinanceDB.Empresas, FinanceDB.Tempo, FinanceDB.PrecoAcao, etc.
-- ========================================
-- IMPORTANTE: Execute APÓS o script 01_setup_completo.sql
-- Comando: docker exec sqlserverCC /opt/mssql-tools18/bin/sqlcmd -S localhost -U SA -P "Cc202505!" -i /tmp/02_processar_dados_etl.sql -C
-- ========================================

PRINT '========================================';
PRINT 'INICIANDO PROCESSAMENTO ETL';
PRINT '========================================';
GO

-- ========================================
-- PARTE 1: POPULAR DIMENSÃO TEMPO
-- ========================================
USE FinanceDB;
GO

PRINT 'Populando dimensão Tempo...';
GO

-- Inserir datas únicas do SP500_data
INSERT INTO Tempo (DataCompleta, Ano, Mes, Dia, Trimestre, Semestre, DiaSemana, NomeDiaSemana, NomeMes, EhFimDeSemana, EhFeriado)
SELECT DISTINCT
    observation_date,
    YEAR(observation_date),
    MONTH(observation_date),
    DAY(observation_date),
    DATEPART(QUARTER, observation_date),
    CASE WHEN MONTH(observation_date) <= 6 THEN 1 ELSE 2 END,
    DATEPART(WEEKDAY, observation_date),
    DATENAME(WEEKDAY, observation_date),
    DATENAME(MONTH, observation_date),
    CASE WHEN DATEPART(WEEKDAY, observation_date) IN (1, 7) THEN 1 ELSE 0 END,
    0
FROM datasets.dbo.SP500_data
WHERE observation_date IS NOT NULL
  AND NOT EXISTS (SELECT 1 FROM Tempo WHERE DataCompleta = observation_date);

PRINT 'Dimensão Tempo populada com ' + CAST(@@ROWCOUNT AS VARCHAR(10)) + ' registros.';
GO

-- ========================================
-- PARTE 2: POPULAR DIMENSÃO EMPRESAS
-- ========================================

PRINT 'Populando dimensão Empresas...';
GO

-- Inserir/atualizar empresas únicas do SP500_data usando MERGE
-- Para CIKs duplicados (ex: Class A e Class B), pega o primeiro alfabeticamente
;WITH RankedCompanies AS (
    SELECT DISTINCT
        cik,
        company_name,
        symbol,
        sector,
        date_added_sp500,
        TRY_CAST(founded_year AS SMALLINT) AS founded_year,
        ROW_NUMBER() OVER (PARTITION BY cik ORDER BY symbol) as rn
    FROM datasets.dbo.SP500_data
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
    INSERT (CIK, NomeEmpresa, Ticker, Setor, DataEntrada, AnoFundacao, TipoSeguranca, Site)
    VALUES (source.cik, source.company_name, source.symbol, source.sector,
            source.date_added_sp500, source.founded_year, NULL, NULL);

PRINT 'Dimensão Empresas populada/atualizada com ' + CAST(@@ROWCOUNT AS VARCHAR(10)) + ' registros.';
GO

-- ========================================
-- PARTE 3: POPULAR DIMENSÃO SUBSETOR
-- ========================================

PRINT 'Populando dimensão SubSetor...';
GO

-- Usar MERGE para evitar duplicatas
-- Para CIKs duplicados, pega o primeiro alfabeticamente por símbolo
;WITH RankedSubSectors AS (
    SELECT DISTINCT
        cik,
        sector,
        sub_industry,
        ROW_NUMBER() OVER (PARTITION BY cik ORDER BY symbol) as rn
    FROM datasets.dbo.SP500_data
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

PRINT 'Dimensão SubSetor populada/atualizada com ' + CAST(@@ROWCOUNT AS VARCHAR(10)) + ' registros.';
GO

-- ========================================
-- PARTE 4: POPULAR DIMENSÃO LOCALIZAÇÃO
-- ========================================

PRINT 'Populando dimensão Localizacao...';
GO

-- Usar MERGE para evitar duplicatas
-- Para CIKs duplicados, pega o primeiro alfabeticamente por símbolo
;WITH RankedLocations AS (
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
    FROM datasets.dbo.SP500_data
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

PRINT 'Dimensão Localizacao populada/atualizada com ' + CAST(@@ROWCOUNT AS VARCHAR(10)) + ' registros.';
GO

-- ========================================
-- PARTE 5: POPULAR FATO PREÇO AÇÃO
-- ========================================

PRINT 'Populando fato PrecoAcao (pode demorar alguns minutos)...';
GO

-- Inserir preços das ações
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
FROM datasets.dbo.SP500_data sp
INNER JOIN Tempo t ON t.DataCompleta = sp.observation_date
WHERE sp.cik IS NOT NULL
  AND sp.observation_date IS NOT NULL
  AND EXISTS (SELECT 1 FROM Empresas WHERE CIK = sp.cik);

PRINT 'Fato PrecoAcao populado com ' + CAST(@@ROWCOUNT AS VARCHAR(10)) + ' registros.';
GO

-- ========================================
-- PARTE 6: POPULAR TABELA DIVIDENDOS
-- ========================================

PRINT 'Populando tabela Dividendos...';
GO

-- Inserir dividendos das empresas
-- O dividend_yield representa o rendimento de dividendos em percentual
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
FROM datasets.dbo.SP500_data sp
INNER JOIN Tempo t ON t.DataCompleta = sp.observation_date
WHERE sp.cik IS NOT NULL
  AND sp.observation_date IS NOT NULL
  AND sp.dividend_yield IS NOT NULL
  AND sp.dividend_yield > 0
  AND EXISTS (SELECT 1 FROM Empresas WHERE CIK = sp.cik);

PRINT 'Tabela Dividendos populada com ' + CAST(@@ROWCOUNT AS VARCHAR(10)) + ' registros.';
GO

-- ========================================
-- PARTE 6.5: CALCULAR VARIAÇÃO DIÁRIA
-- ========================================

PRINT 'Calculando VariacaoDiaria para PrecoAcao...';
GO

-- Atualizar VariacaoDiaria (PreçoHoje - PreçoOntem)
;WITH PrecoComAnterior AS (
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

PRINT 'VariacaoDiaria calculada para ' + CAST(@@ROWCOUNT AS VARCHAR(10)) + ' registros.';
GO

-- ========================================
-- PARTE 7: POPULAR HISTÓRICO S&P 500
-- ========================================

PRINT 'Populando SP500Historico...';
GO

-- Inserir valores históricos do índice S&P 500
-- Como nem todos os registros têm sp500_index, calculamos com base no close_price
-- Usamos a média dos preços de fechamento como aproximação do índice
INSERT INTO SP500Historico (DataReferencia, ValorFechamento, ValorAbertura, ValorMaximo, ValorMinimo, VolumeNegociado)
SELECT
    sp.observation_date,
    -- Se houver sp500_index, usar; senão usar AVG(close_price) como aproximação
    ISNULL(
        (SELECT AVG(TRY_CAST(sp2.sp500_index AS DECIMAL(18,2)))
         FROM datasets.dbo.SP500_data sp2
         WHERE sp2.observation_date = sp.observation_date AND sp2.sp500_index IS NOT NULL),
        AVG(TRY_CAST(sp.close_price AS DECIMAL(18,2)))
    ) AS ValorFechamento,
    ISNULL(
        (SELECT AVG(TRY_CAST(sp2.sp500_index AS DECIMAL(18,2)))
         FROM datasets.dbo.SP500_data sp2
         WHERE sp2.observation_date = sp.observation_date AND sp2.sp500_index IS NOT NULL),
        AVG(TRY_CAST(sp.open_price AS DECIMAL(18,2)))
    ) AS ValorAbertura,
    ISNULL(
        (SELECT AVG(TRY_CAST(sp2.sp500_index AS DECIMAL(18,2)))
         FROM datasets.dbo.SP500_data sp2
         WHERE sp2.observation_date = sp.observation_date AND sp2.sp500_index IS NOT NULL),
        MAX(TRY_CAST(sp.high_price AS DECIMAL(18,2)))
    ) AS ValorMaximo,
    ISNULL(
        (SELECT AVG(TRY_CAST(sp2.sp500_index AS DECIMAL(18,2)))
         FROM datasets.dbo.SP500_data sp2
         WHERE sp2.observation_date = sp.observation_date AND sp2.sp500_index IS NOT NULL),
        MIN(TRY_CAST(sp.low_price AS DECIMAL(18,2)))
    ) AS ValorMinimo,
    SUM(TRY_CAST(sp.volume AS BIGINT)) AS VolumeNegociado
FROM datasets.dbo.SP500_data sp
WHERE sp.observation_date IS NOT NULL
  AND NOT EXISTS (
      SELECT 1 FROM SP500Historico
      WHERE DataReferencia = sp.observation_date
  )
GROUP BY sp.observation_date;

PRINT 'SP500Historico populado com ' + CAST(@@ROWCOUNT AS VARCHAR(10)) + ' registros.';
GO

-- ========================================
-- PARTE 8: PROCESSAR CSI500 (MERCADO CHINÊS)
-- ========================================

PRINT '';
PRINT '========================================';
PRINT 'PROCESSANDO CSI500 (MERCADO CHINÊS)';
PRINT '========================================';
GO

-- ========================================
-- PARTE 8.1: POPULAR DIMENSÃO TEMPO COM DATAS CSI500
-- ========================================

PRINT 'Adicionando datas do CSI500 à dimensão Tempo...';
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

PRINT 'Datas CSI500 adicionadas: ' + CAST(@@ROWCOUNT AS VARCHAR(10)) + ' registros.';
GO

-- ========================================
-- PARTE 8.2: POPULAR DIMENSÃO EMPRESASCSI500
-- ========================================

PRINT 'Populando dimensão EmpresasCSI500...';
GO

;WITH RankedCompanies AS (
    SELECT DISTINCT
        c.codigo_empresa,
        c.nome_empresa_en,
        c.industry_en,
        c.subindustry_en,
        c.region_en,
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
        subindustry_en,
        region_en,
        MIN([date]) OVER (PARTITION BY codigo_empresa) AS DataPrimeiraObservacao
    FROM RankedCompanies
    WHERE rn = 1
)
MERGE EmpresasCSI500 AS target
USING FirstDatePerCompany AS source
ON target.CodigoEmpresa = source.codigo_empresa
WHEN NOT MATCHED THEN
    INSERT (CodigoEmpresa, NomeEmpresa, NomeEmpresaEN, Industria, SubIndustria, Regiao, DataPrimeiraObservacao)
    VALUES (source.codigo_empresa, NULL, source.nome_empresa_en, source.industry_en, source.subindustry_en, source.region_en, source.DataPrimeiraObservacao);

PRINT 'Dimensão EmpresasCSI500 populada/atualizada com ' + CAST(@@ROWCOUNT AS VARCHAR(10)) + ' registros.';
GO

-- ========================================
-- PARTE 8.3: POPULAR FATO PREÇOACAOCSI500
-- ========================================

PRINT 'Populando fato PrecoAcaoCSI500 (pode demorar alguns minutos)...';
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

PRINT 'Fato PrecoAcaoCSI500 populado com ' + CAST(@@ROWCOUNT AS VARCHAR(10)) + ' registros.';
GO

-- ========================================
-- PARTE 8.4: POPULAR CSI500HISTORICO
-- ========================================

PRINT 'Populando CSI500Historico (agregação do mercado)...';
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

PRINT 'CSI500Historico populado com ' + CAST(@@ROWCOUNT AS VARCHAR(10)) + ' registros.';
GO

-- ========================================
-- VERIFICAÇÃO FINAL
-- ========================================

PRINT '';
PRINT '========================================';
PRINT 'ETL CONCLUÍDO COM SUCESSO!';
PRINT '========================================';
GO

PRINT 'Contagem de registros no modelo dimensional:';
PRINT '';
PRINT '--- S&P 500 ---';
SELECT 'Tempo' as Tabela, COUNT(*) as Total FROM Tempo
UNION ALL SELECT 'Empresas', COUNT(*) FROM Empresas
UNION ALL SELECT 'SubSetor', COUNT(*) FROM SubSetor
UNION ALL SELECT 'Localizacao', COUNT(*) FROM Localizacao
UNION ALL SELECT 'PrecoAcao', COUNT(*) FROM PrecoAcao
UNION ALL SELECT 'Dividendos', COUNT(*) FROM Dividendos
UNION ALL SELECT 'SP500Historico', COUNT(*) FROM SP500Historico;
GO

PRINT '';
PRINT '--- CSI500 (Mercado Chinês) ---';
SELECT 'EmpresasCSI500' as Tabela, COUNT(*) as Total FROM EmpresasCSI500
UNION ALL SELECT 'PrecoAcaoCSI500', COUNT(*) FROM PrecoAcaoCSI500
UNION ALL SELECT 'CSI500Historico', COUNT(*) FROM CSI500Historico;
GO

PRINT '';
PRINT 'Próximos passos:';
PRINT '  1. Execute scripts_linux de análise (pasta 2-analise)';
PRINT '  2. Crie views para responder às perguntas';
PRINT '  3. Configure o DataGrip com ambos databases (FinanceDB + datasets)';
PRINT '========================================';
GO
