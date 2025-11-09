-- ========================================
-- SCRIPT: ANÁLISES CSI500 (Ações Chinesas)
-- ========================================
-- Descrição: Análises sobre o mercado chinês
-- Database: datasets
-- ========================================

USE datasets;
GO

PRINT '========================================';
PRINT 'ANÁLISES CSI500 (MERCADO CHINÊS)';
PRINT '========================================';
PRINT '';
GO

-- ========================================
-- PERGUNTA 1: Ações com maior valorização
-- ========================================
PRINT '========================================';
PRINT 'PERGUNTA 1: Maior Valorização CSI500';
PRINT '========================================';
PRINT '';
GO

WITH PeriodoAnalise AS (
    SELECT
        MIN([date]) AS DataInicial,
        MAX([date]) AS DataFinal
    FROM CSI500
    WHERE [date] >= DATEADD(YEAR, -1, (SELECT MAX([date]) FROM CSI500))
),
PrecoInicial AS (
    SELECT
        c.codigo_empresa,
        c.nome_empresa_en,
        c.industry_en,
        MIN(c.[date]) AS DataInicio,
        AVG(TRY_CAST(c.[close] AS DECIMAL(10,4))) AS PrecoInicial
    FROM CSI500 c
    CROSS JOIN PeriodoAnalise p
    WHERE c.[date] BETWEEN p.DataInicial AND DATEADD(DAY, 7, p.DataInicial)
      AND TRY_CAST(c.[close] AS DECIMAL(10,4)) IS NOT NULL
    GROUP BY c.codigo_empresa, c.nome_empresa_en, c.industry_en
),
PrecoFinal AS (
    SELECT
        c.codigo_empresa,
        MAX(c.[date]) AS DataFim,
        AVG(TRY_CAST(c.[close] AS DECIMAL(10,4))) AS PrecoFinal
    FROM CSI500 c
    CROSS JOIN PeriodoAnalise p
    WHERE c.[date] >= DATEADD(DAY, -7, p.DataFinal)
      AND TRY_CAST(c.[close] AS DECIMAL(10,4)) IS NOT NULL
    GROUP BY c.codigo_empresa
)
SELECT TOP 20
    pi.codigo_empresa AS Symbol,
    pi.nome_empresa_en AS Empresa,
    pi.industry_en AS Industria,
    pi.DataInicio,
    CAST(pi.PrecoInicial AS DECIMAL(10, 4)) AS PrecoInicial,
    pf.DataFim,
    CAST(pf.PrecoFinal AS DECIMAL(10, 4)) AS PrecoFinal,
    CAST((pf.PrecoFinal - pi.PrecoInicial) AS DECIMAL(10, 4)) AS ValorizacaoAbsoluta,
    CAST(((pf.PrecoFinal - pi.PrecoInicial) / NULLIF(pi.PrecoInicial, 0) * 100) AS DECIMAL(10, 2)) AS ValorizacaoPercentual
FROM PrecoInicial pi
INNER JOIN PrecoFinal pf ON pi.codigo_empresa = pf.codigo_empresa
WHERE pi.PrecoInicial > 0
ORDER BY ValorizacaoPercentual DESC;
GO

PRINT '';
GO

-- ========================================
-- PERGUNTA 2: Volatilidade por Indústria
-- ========================================
PRINT '========================================';
PRINT 'PERGUNTA 2: Volatilidade por Indústria';
PRINT '========================================';
PRINT '';
GO

WITH DadosNumericos AS (
    SELECT
        codigo_empresa,
        industry_en,
        [date],
        TRY_CAST([close] AS DECIMAL(10,4)) AS PrecoFechamento
    FROM CSI500
    WHERE TRY_CAST([close] AS DECIMAL(10,4)) IS NOT NULL
),
RetornosDiarios AS (
    SELECT
        codigo_empresa,
        industry_en,
        [date],
        PrecoFechamento,
        LAG(PrecoFechamento) OVER (PARTITION BY codigo_empresa ORDER BY [date]) AS PrecoAnterior
    FROM DadosNumericos
),
CalculoRetornos AS (
    SELECT
        industry_en,
        codigo_empresa,
        [date],
        CASE
            WHEN PrecoAnterior IS NOT NULL AND PrecoAnterior > 0
            THEN ((PrecoFechamento - PrecoAnterior) / PrecoAnterior)
            ELSE NULL
        END AS RetornoDiario
    FROM RetornosDiarios
)
SELECT
    COALESCE(industry_en, 'Sem Classificação') AS Industria,
    COUNT(DISTINCT codigo_empresa) AS QtdEmpresas,
    COUNT(*) AS QtdObservacoes,
    CAST(AVG(RetornoDiario) * 100 AS DECIMAL(10, 4)) AS RetornoMedioDiario_Pct,
    CAST(STDEV(RetornoDiario) * 100 AS DECIMAL(10, 4)) AS VolatilidadeDiaria_Pct,
    CAST(STDEV(RetornoDiario) * SQRT(252) * 100 AS DECIMAL(10, 4)) AS VolatilidadeAnualizada_Pct
FROM CalculoRetornos
WHERE RetornoDiario IS NOT NULL
GROUP BY industry_en
HAVING COUNT(DISTINCT codigo_empresa) >= 3
ORDER BY VolatilidadeAnualizada_Pct DESC;
GO

PRINT '';
GO

-- ========================================
-- PERGUNTA 3: Maior volume de negociação
-- ========================================
PRINT '========================================';
PRINT 'PERGUNTA 3: Maior Volume de Negociação';
PRINT '========================================';
PRINT '';
GO

SELECT TOP 30
    codigo_empresa AS Symbol,
    nome_empresa_en AS Empresa,
    industry_en AS Industria,
    COUNT(*) AS DiasNegociados,
    CAST(SUM(TRY_CAST(volume AS DECIMAL(18,2))) AS DECIMAL(20, 0)) AS VolumeTotal,
    CAST(AVG(TRY_CAST(volume AS DECIMAL(18,2))) AS DECIMAL(18, 0)) AS VolumeMediaDiaria,
    CAST(AVG(TRY_CAST([close] AS DECIMAL(10,4))) AS DECIMAL(10, 2)) AS PrecoMedio
FROM CSI500
WHERE [date] >= DATEADD(MONTH, -6, (SELECT MAX([date]) FROM CSI500))
  AND TRY_CAST(volume AS DECIMAL(18,2)) IS NOT NULL
GROUP BY codigo_empresa, nome_empresa_en, industry_en
ORDER BY VolumeTotal DESC;
GO

PRINT '';
GO

-- ========================================
-- PERGUNTA 4: Distribuição por Indústria
-- ========================================
PRINT '========================================';
PRINT 'PERGUNTA 4: Distribuição por Indústria';
PRINT '========================================';
PRINT '';
GO

SELECT
    industry_en AS Industria,
    COUNT(DISTINCT codigo_empresa) AS QtdEmpresas,
    COUNT(*) AS QtdObservacoes,
    MIN([date]) AS PrimeiraObservacao,
    MAX([date]) AS UltimaObservacao
FROM CSI500
WHERE industry_en IS NOT NULL
GROUP BY industry_en
ORDER BY QtdEmpresas DESC;
GO

PRINT '';
GO

-- ========================================
-- RESUMO EXECUTIVO CSI500
-- ========================================
PRINT '========================================';
PRINT 'RESUMO EXECUTIVO CSI500';
PRINT '========================================';
GO

SELECT
    'Total de Empresas CSI500' AS Metrica,
    CAST(COUNT(DISTINCT codigo_empresa) AS VARCHAR(20)) AS Valor
FROM CSI500
UNION ALL
SELECT
    'Total de Observações',
    CAST(COUNT(*) AS VARCHAR(20))
FROM CSI500
UNION ALL
SELECT
    'Período de Dados',
    CAST(MIN([date]) AS VARCHAR(20)) + ' a ' + CAST(MAX([date]) AS VARCHAR(20))
FROM CSI500
UNION ALL
SELECT
    'Total de Indústrias',
    CAST(COUNT(DISTINCT industry_en) AS VARCHAR(20))
FROM CSI500
WHERE industry_en IS NOT NULL;
GO

PRINT '';
PRINT '========================================';
PRINT 'ANÁLISES CSI500 CONCLUÍDAS!';
PRINT '========================================';
GO
