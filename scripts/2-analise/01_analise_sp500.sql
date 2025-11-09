-- ========================================
-- SCRIPT: ANÁLISES S&P 500
-- ========================================
-- Descrição: Análises sobre empresas e preços do S&P 500
-- Database: FinanceDB
-- ========================================

USE FinanceDB;
GO

PRINT '========================================';
PRINT 'ANÁLISES S&P 500';
PRINT '========================================';
PRINT '';
GO

-- ========================================
-- PERGUNTA 1: Quais ações tiveram maior valorização no último período?
-- ========================================
PRINT '========================================';
PRINT 'PERGUNTA 1: Maior Valorização Recente';
PRINT '========================================';
PRINT '';
GO

WITH UltimaData AS (
    SELECT MAX(DataCompleta) AS DataFinal
    FROM Tempo
),
PrimeiraData AS (
    SELECT MIN(DataCompleta) AS DataInicial
    FROM Tempo
    WHERE DataCompleta >= DATEADD(MONTH, -6, (SELECT DataFinal FROM UltimaData))
),
PrecoInicial AS (
    SELECT
        p.CIK,
        e.Ticker,
        e.NomeEmpresa,
        e.Setor,
        MIN(t.DataCompleta) AS DataInicial,
        AVG(p.PrecoFechamento) AS PrecoInicial
    FROM PrecoAcao p
    INNER JOIN Empresas e ON p.CIK = e.CIK
    INNER JOIN Tempo t ON p.IdTempo = t.IdTempo
    CROSS JOIN PrimeiraData pd
    WHERE t.DataCompleta BETWEEN pd.DataInicial AND DATEADD(DAY, 7, pd.DataInicial)
      AND p.PrecoFechamento IS NOT NULL
    GROUP BY p.CIK, e.Ticker, e.NomeEmpresa, e.Setor
),
PrecoFinal AS (
    SELECT
        p.CIK,
        MAX(t.DataCompleta) AS DataFinal,
        AVG(p.PrecoFechamento) AS PrecoFinal
    FROM PrecoAcao p
    INNER JOIN Tempo t ON p.IdTempo = t.IdTempo
    CROSS JOIN UltimaData ud
    WHERE t.DataCompleta >= DATEADD(DAY, -7, ud.DataFinal)
      AND p.PrecoFechamento IS NOT NULL
    GROUP BY p.CIK
)
SELECT TOP 20
    pi.Ticker,
    pi.NomeEmpresa,
    pi.Setor,
    pi.DataInicial,
    CAST(pi.PrecoInicial AS DECIMAL(10,2)) AS PrecoInicial,
    pf.DataFinal,
    CAST(pf.PrecoFinal AS DECIMAL(10,2)) AS PrecoFinal,
    CAST((pf.PrecoFinal - pi.PrecoInicial) AS DECIMAL(10,2)) AS ValorizacaoAbsoluta,
    CAST(((pf.PrecoFinal - pi.PrecoInicial) / NULLIF(pi.PrecoInicial, 0) * 100) AS DECIMAL(10,2)) AS ValorizacaoPercentual
FROM PrecoInicial pi
INNER JOIN PrecoFinal pf ON pi.CIK = pf.CIK
WHERE pi.PrecoInicial > 0
ORDER BY ValorizacaoPercentual DESC;
GO

PRINT '';
GO

-- ========================================
-- PERGUNTA 2: Qual é a volatilidade média por setor?
-- ========================================
PRINT '========================================';
PRINT 'PERGUNTA 2: Volatilidade por Setor';
PRINT '========================================';
PRINT '';
GO

WITH RetornosDiarios AS (
    SELECT
        e.Setor,
        e.Ticker,
        t.DataCompleta,
        p.PrecoFechamento,
        LAG(p.PrecoFechamento) OVER (PARTITION BY p.CIK ORDER BY t.DataCompleta) AS PrecoAnterior
    FROM PrecoAcao p
    INNER JOIN Empresas e ON p.CIK = e.CIK
    INNER JOIN Tempo t ON p.IdTempo = t.IdTempo
    WHERE p.PrecoFechamento IS NOT NULL
),
CalculoRetornos AS (
    SELECT
        Setor,
        Ticker,
        DataCompleta,
        CASE
            WHEN PrecoAnterior IS NOT NULL AND PrecoAnterior > 0
            THEN ((PrecoFechamento - PrecoAnterior) / PrecoAnterior)
            ELSE NULL
        END AS RetornoDiario
    FROM RetornosDiarios
)
SELECT
    COALESCE(Setor, 'Sem Classificação') AS Setor,
    COUNT(DISTINCT Ticker) AS QtdEmpresas,
    COUNT(*) AS QtdObservacoes,
    CAST(AVG(RetornoDiario) * 100 AS DECIMAL(10, 4)) AS RetornoMedioDiario_Pct,
    CAST(STDEV(RetornoDiario) * 100 AS DECIMAL(10, 4)) AS VolatilidadeDiaria_Pct,
    CAST(STDEV(RetornoDiario) * SQRT(252) * 100 AS DECIMAL(10, 4)) AS VolatilidadeAnualizada_Pct
FROM CalculoRetornos
WHERE RetornoDiario IS NOT NULL
GROUP BY Setor
HAVING COUNT(DISTINCT Ticker) >= 3
ORDER BY VolatilidadeAnualizada_Pct DESC;
GO

PRINT '';
GO

-- ========================================
-- PERGUNTA 3: Empresas com maior volume de negociação
-- ========================================
PRINT '========================================';
PRINT 'PERGUNTA 3: Maior Volume de Negociação';
PRINT '========================================';
PRINT '';
GO

SELECT TOP 30
    e.Ticker,
    e.NomeEmpresa,
    e.Setor,
    COUNT(DISTINCT t.DataCompleta) AS DiasNegociados,
    CAST(SUM(p.Volume) AS DECIMAL(20, 0)) AS VolumeTotal,
    CAST(AVG(p.Volume) AS DECIMAL(18, 0)) AS VolumeMediaDiaria,
    CAST(AVG(p.PrecoFechamento) AS DECIMAL(10, 2)) AS PrecoMedio
FROM PrecoAcao p
INNER JOIN Empresas e ON p.CIK = e.CIK
INNER JOIN Tempo t ON p.IdTempo = t.IdTempo
WHERE p.Volume IS NOT NULL
  AND t.DataCompleta >= DATEADD(MONTH, -6, (SELECT MAX(DataCompleta) FROM Tempo))
GROUP BY e.Ticker, e.NomeEmpresa, e.Setor
ORDER BY VolumeTotal DESC;
GO

PRINT '';
GO

-- ========================================
-- PERGUNTA 4: Evolução do Índice S&P 500
-- ========================================
PRINT '========================================';
PRINT 'PERGUNTA 4: Evolução do Índice S&P 500';
PRINT '========================================';
PRINT '';
GO

WITH IndiceMensal AS (
    SELECT
        YEAR(i.DataReferencia) AS Ano,
        MONTH(i.DataReferencia) AS Mes,
        MIN(i.ValorFechamento) AS MinimoMes,
        MAX(i.ValorFechamento) AS MaximoMes,
        AVG(i.ValorFechamento) AS MediaMes,
        FIRST_VALUE(i.ValorFechamento) OVER (
            PARTITION BY YEAR(i.DataReferencia), MONTH(i.DataReferencia)
            ORDER BY i.DataReferencia ASC
        ) AS AberturaMes,
        FIRST_VALUE(i.ValorFechamento) OVER (
            PARTITION BY YEAR(i.DataReferencia), MONTH(i.DataReferencia)
            ORDER BY i.DataReferencia DESC
        ) AS FechamentoMes
    FROM IndiceSP500 i
    INNER JOIN Indice ind ON i.IdIndice = ind.IdIndice
    WHERE ind.NomeIndice = 'S&P 500'
    GROUP BY YEAR(i.DataReferencia), MONTH(i.DataReferencia), i.DataReferencia, i.ValorFechamento
)
SELECT DISTINCT
    Ano,
    Mes,
    CAST(AberturaMes AS DECIMAL(10, 2)) AS Abertura,
    CAST(FechamentoMes AS DECIMAL(10, 2)) AS Fechamento,
    CAST(MediaMes AS DECIMAL(10, 2)) AS Media,
    CAST(MinimoMes AS DECIMAL(10, 2)) AS Minimo,
    CAST(MaximoMes AS DECIMAL(10, 2)) AS Maximo,
    CAST(((FechamentoMes - AberturaMes) / NULLIF(AberturaMes, 0) * 100) AS DECIMAL(10, 2)) AS RetornoMensal_Pct
FROM IndiceMensal
ORDER BY Ano DESC, Mes DESC;
GO

PRINT '';
GO

-- ========================================
-- PERGUNTA 5: Distribuição de empresas por setor
-- ========================================
PRINT '========================================';
PRINT 'PERGUNTA 5: Empresas por Setor';
PRINT '========================================';
PRINT '';
GO

SELECT
    e.Setor,
    COUNT(*) AS QtdEmpresas,
    MIN(e.DataEntrada) AS PrimeiraAdicao,
    MAX(e.DataEntrada) AS UltimaAdicao,
    CAST(AVG(CAST(YEAR(GETDATE()) - e.AnoFundacao AS FLOAT)) AS DECIMAL(10, 1)) AS IdadeMediaAnos
FROM Empresas e
WHERE e.Setor IS NOT NULL
GROUP BY e.Setor
ORDER BY QtdEmpresas DESC;
GO

PRINT '';
GO

-- ========================================
-- RESUMO EXECUTIVO
-- ========================================
PRINT '========================================';
PRINT 'RESUMO EXECUTIVO';
PRINT '========================================';
GO

SELECT
    'Total de Empresas' AS Metrica,
    CAST(COUNT(*) AS VARCHAR(20)) AS Valor
FROM Empresas
UNION ALL
SELECT
    'Total de Observações de Preços',
    CAST(COUNT(*) AS VARCHAR(20))
FROM PrecoAcao
UNION ALL
SELECT
    'Total de Dias com Dados',
    CAST(COUNT(*) AS VARCHAR(20))
FROM Tempo
UNION ALL
SELECT
    'Período de Dados',
    CAST(MIN(DataCompleta) AS VARCHAR(20)) + ' a ' + CAST(MAX(DataCompleta) AS VARCHAR(20))
FROM Tempo
UNION ALL
SELECT
    'Valor Atual do S&P 500',
    CAST(CAST(ValorFechamento AS DECIMAL(10,2)) AS VARCHAR(20))
FROM IndiceSP500
WHERE DataReferencia = (SELECT MAX(DataReferencia) FROM IndiceSP500);
GO

PRINT '';
PRINT '========================================';
PRINT 'ANÁLISES CONCLUÍDAS!';
PRINT '========================================';
GO
