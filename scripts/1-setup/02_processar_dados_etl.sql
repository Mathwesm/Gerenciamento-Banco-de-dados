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
            THEN LTRIM(RTRIM(SUBSTRING(headquarters, 1, CHARINDEX(',', headquarters) - 1)))
            ELSE headquarters
        END AS cidade,
        CASE
            WHEN CHARINDEX(',', headquarters) > 0
            THEN LTRIM(RTRIM(SUBSTRING(headquarters, CHARINDEX(',', headquarters) + 1, LEN(headquarters))))
            ELSE NULL
        END AS estado,
        ROW_NUMBER() OVER (PARTITION BY cik ORDER BY symbol) as rn
    FROM datasets.dbo.SP500_data
    WHERE cik IS NOT NULL AND headquarters IS NOT NULL
)
MERGE Localizacao AS target
USING (
    SELECT
        cik,
        cidade,
        estado
    FROM RankedLocations
    WHERE rn = 1
) AS source
ON target.CIK = source.cik
WHEN MATCHED THEN
    UPDATE SET
        Cidade = source.cidade,
        Estado = source.estado,
        Pais = 'Estados Unidos'
WHEN NOT MATCHED THEN
    INSERT (CIK, Cidade, Estado, Pais, Regiao, CodigoPostal)
    VALUES (source.cik, source.cidade, source.estado, 'Estados Unidos', NULL, NULL);

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
    NULL,
    NULL,
    NULL,
    sp.stock_price,
    sp.stock_price,
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
-- PARTE 6: POPULAR ÍNDICE SP500
-- ========================================

PRINT 'Populando Indice e IndiceSP500...';
GO

-- Criar índice S&P 500 se não existir
IF NOT EXISTS (SELECT 1 FROM Indice WHERE NomeIndice = 'S&P 500')
BEGIN
    INSERT INTO Indice (NomeIndice, Descricao, Simbolo, PaisOrigem, DataCriacao)
    VALUES ('S&P 500', 'Standard & Poor''s 500 Index', 'SPX', 'Estados Unidos', '1957-03-04');
    PRINT 'Índice S&P 500 criado.';
END
GO

-- Inserir valores históricos do índice
INSERT INTO IndiceSP500 (IdIndice, DataReferencia, ValorFechamento, ValorAbertura, ValorMaximo, ValorMinimo, VolumeNegociado)
SELECT DISTINCT
    (SELECT IdIndice FROM Indice WHERE NomeIndice = 'S&P 500'),
    sp.observation_date,
    sp.sp500_index,
    NULL,
    NULL,
    NULL,
    NULL
FROM datasets.dbo.SP500_data sp
WHERE sp.observation_date IS NOT NULL
  AND sp.sp500_index IS NOT NULL
  AND NOT EXISTS (
      SELECT 1 FROM IndiceSP500
      WHERE IdIndice = (SELECT IdIndice FROM Indice WHERE NomeIndice = 'S&P 500')
        AND DataReferencia = sp.observation_date
  );

PRINT 'IndiceSP500 populado com ' + CAST(@@ROWCOUNT AS VARCHAR(10)) + ' registros.';
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
SELECT 'Tempo' as Tabela, COUNT(*) as Total FROM Tempo
UNION ALL SELECT 'Empresas', COUNT(*) FROM Empresas
UNION ALL SELECT 'SubSetor', COUNT(*) FROM SubSetor
UNION ALL SELECT 'Localizacao', COUNT(*) FROM Localizacao
UNION ALL SELECT 'PrecoAcao', COUNT(*) FROM PrecoAcao
UNION ALL SELECT 'Indice', COUNT(*) FROM Indice
UNION ALL SELECT 'IndiceSP500', COUNT(*) FROM IndiceSP500;
GO

PRINT '';
PRINT 'Próximos passos:';
PRINT '  1. Execute scripts de análise (pasta 2-analise)';
PRINT '  2. Crie views para responder às perguntas';
PRINT '  3. Configure o DataGrip com ambos databases (FinanceDB + datasets)';
PRINT '========================================';
GO
