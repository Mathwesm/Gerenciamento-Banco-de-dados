-- ========================================
-- SCRIPT: ANÁLISES CSI500 (Ações Chinesas)
-- ========================================
-- Descrição: Análises sobre o mercado chinês usando modelo dimensional
-- Database: FinanceDB
-- ========================================

USE FinanceDB;
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

WITH UltimaData AS (
    SELECT MAX(DataCompleta) AS DataFinal
    FROM Tempo
),
PrimeiraData AS (
    SELECT MIN(DataCompleta) AS DataInicial
    FROM Tempo
    WHERE DataCompleta >= DATEADD(YEAR, -1, (SELECT DataFinal FROM UltimaData))
),
PrecoInicial AS (
    SELECT
        p.CodigoEmpresa,
        e.NomeEmpresaEN,
        e.Industria,
        MIN(t.DataCompleta) AS DataInicio,
        AVG(p.PrecoFechamento) AS PrecoInicial
    FROM PrecoAcaoCSI500 p
    INNER JOIN EmpresasCSI500 e ON p.CodigoEmpresa = e.CodigoEmpresa
    INNER JOIN Tempo t ON p.IdTempo = t.IdTempo
    CROSS JOIN PrimeiraData pd
    WHERE t.DataCompleta BETWEEN pd.DataInicial AND DATEADD(DAY, 7, pd.DataInicial)
      AND p.PrecoFechamento IS NOT NULL
    GROUP BY p.CodigoEmpresa, e.NomeEmpresaEN, e.Industria
),
PrecoFinal AS (
    SELECT
        p.CodigoEmpresa,
        MAX(t.DataCompleta) AS DataFim,
        AVG(p.PrecoFechamento) AS PrecoFinal
    FROM PrecoAcaoCSI500 p
    INNER JOIN Tempo t ON p.IdTempo = t.IdTempo
    CROSS JOIN UltimaData ud
    WHERE t.DataCompleta >= DATEADD(DAY, -7, ud.DataFinal)
      AND p.PrecoFechamento IS NOT NULL
    GROUP BY p.CodigoEmpresa
)
SELECT TOP 20
    pi.CodigoEmpresa,
    pi.NomeEmpresaEN AS Empresa,
    pi.Industria,
    pi.DataInicio,
    CAST(pi.PrecoInicial AS DECIMAL(10, 4)) AS PrecoInicial,
    pf.DataFim,
    CAST(pf.PrecoFinal AS DECIMAL(10, 4)) AS PrecoFinal,
    CAST((pf.PrecoFinal - pi.PrecoInicial) AS DECIMAL(10, 4)) AS ValorizacaoAbsoluta,
    CAST(((pf.PrecoFinal - pi.PrecoInicial) / NULLIF(pi.PrecoInicial, 0) * 100) AS DECIMAL(10, 2)) AS ValorizacaoPercentual
FROM PrecoInicial pi
INNER JOIN PrecoFinal pf ON pi.CodigoEmpresa = pf.CodigoEmpresa
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

WITH RetornosDiarios AS (
    SELECT
        e.Industria,
        e.CodigoEmpresa,
        t.DataCompleta,
        p.PrecoFechamento,
        LAG(p.PrecoFechamento) OVER (PARTITION BY p.CodigoEmpresa ORDER BY t.DataCompleta) AS PrecoAnterior
    FROM PrecoAcaoCSI500 p
    INNER JOIN EmpresasCSI500 e ON p.CodigoEmpresa = e.CodigoEmpresa
    INNER JOIN Tempo t ON p.IdTempo = t.IdTempo
    WHERE p.PrecoFechamento IS NOT NULL
),
CalculoRetornos AS (
    SELECT
        Industria,
        CodigoEmpresa,
        DataCompleta,
        CASE
            WHEN PrecoAnterior IS NOT NULL AND PrecoAnterior > 0
            THEN ((PrecoFechamento - PrecoAnterior) / PrecoAnterior)
            ELSE NULL
        END AS RetornoDiario
    FROM RetornosDiarios
)
SELECT
    COALESCE(Industria, 'Sem Classificação') AS Industria,
    COUNT(DISTINCT CodigoEmpresa) AS QtdEmpresas,
    COUNT(*) AS QtdObservacoes,
    CAST(AVG(RetornoDiario) * 100 AS DECIMAL(10, 4)) AS RetornoMedioDiario_Pct,
    CAST(STDEV(RetornoDiario) * 100 AS DECIMAL(10, 4)) AS VolatilidadeDiaria_Pct,
    CAST(STDEV(RetornoDiario) * SQRT(252) * 100 AS DECIMAL(10, 4)) AS VolatilidadeAnualizada_Pct
FROM CalculoRetornos
WHERE RetornoDiario IS NOT NULL
GROUP BY Industria
HAVING COUNT(DISTINCT CodigoEmpresa) >= 3
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
    e.CodigoEmpresa,
    e.NomeEmpresaEN AS Empresa,
    e.Industria,
    COUNT(DISTINCT t.DataCompleta) AS DiasNegociados,
    CAST(SUM(p.Volume) AS DECIMAL(20, 0)) AS VolumeTotal,
    CAST(AVG(p.Volume) AS DECIMAL(18, 0)) AS VolumeMediaDiaria,
    CAST(AVG(p.PrecoFechamento) AS DECIMAL(10, 2)) AS PrecoMedio
FROM PrecoAcaoCSI500 p
INNER JOIN EmpresasCSI500 e ON p.CodigoEmpresa = e.CodigoEmpresa
INNER JOIN Tempo t ON p.IdTempo = t.IdTempo
WHERE p.Volume IS NOT NULL
  AND t.DataCompleta >= DATEADD(MONTH, -6, (SELECT MAX(DataCompleta) FROM Tempo))
GROUP BY e.CodigoEmpresa, e.NomeEmpresaEN, e.Industria
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
    e.Industria,
    COUNT(*) AS QtdEmpresas,
    MIN(e.DataPrimeiraObservacao) AS PrimeiraObservacao,
    MAX(e.DataPrimeiraObservacao) AS UltimaObservacao,
    STRING_AGG(e.CodigoEmpresa, ', ') AS CodigosEmpresas
FROM EmpresasCSI500 e
WHERE e.Industria IS NOT NULL
GROUP BY e.Industria
ORDER BY QtdEmpresas DESC;
GO

PRINT '';
GO

-- ========================================
-- PERGUNTA 5: Evolução do Índice CSI500
-- ========================================
PRINT '========================================';
PRINT 'PERGUNTA 5: Evolução do Índice CSI500';
PRINT '========================================';
PRINT '';
GO

WITH IndiceMensal AS (
    SELECT
        YEAR(DataReferencia) AS Ano,
        MONTH(DataReferencia) AS Mes,
        MIN(ValorMedioMercado) AS MinimoMes,
        MAX(ValorMedioMercado) AS MaximoMes,
        AVG(ValorMedioMercado) AS MediaMes,
        AVG(QtdEmpresasNegociadas) AS MediaEmpresas,
        FIRST_VALUE(ValorMedioMercado) OVER (
            PARTITION BY YEAR(DataReferencia), MONTH(DataReferencia)
            ORDER BY DataReferencia ASC
        ) AS AberturaMes,
        FIRST_VALUE(ValorMedioMercado) OVER (
            PARTITION BY YEAR(DataReferencia), MONTH(DataReferencia)
            ORDER BY DataReferencia DESC
        ) AS FechamentoMes
    FROM CSI500Historico
    GROUP BY YEAR(DataReferencia), MONTH(DataReferencia), DataReferencia, ValorMedioMercado, QtdEmpresasNegociadas
)
SELECT DISTINCT TOP 12
    Ano,
    Mes,
    CAST(AberturaMes AS DECIMAL(10, 2)) AS Abertura,
    CAST(FechamentoMes AS DECIMAL(10, 2)) AS Fechamento,
    CAST(MediaMes AS DECIMAL(10, 2)) AS Media,
    CAST(MinimoMes AS DECIMAL(10, 2)) AS Minimo,
    CAST(MaximoMes AS DECIMAL(10, 2)) AS Maximo,
    CAST(ROUND(MediaEmpresas, 0) AS INT) AS MediaEmpresasNegociadas,
    CAST(((FechamentoMes - AberturaMes) / NULLIF(AberturaMes, 0) * 100) AS DECIMAL(10, 2)) AS RetornoMensal_Pct
FROM IndiceMensal
ORDER BY Ano DESC, Mes DESC;
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
    CAST(COUNT(*) AS VARCHAR(20)) AS Valor
FROM EmpresasCSI500
UNION ALL
SELECT
    'Total de Observações de Preços',
    CAST(COUNT(*) AS VARCHAR(20))
FROM PrecoAcaoCSI500
UNION ALL
SELECT
    'Período de Dados',
    CAST(MIN(DataCompleta) AS VARCHAR(20)) + ' a ' + CAST(MAX(DataCompleta) AS VARCHAR(20))
FROM Tempo t
WHERE EXISTS (SELECT 1 FROM PrecoAcaoCSI500 p WHERE p.IdTempo = t.IdTempo)
UNION ALL
SELECT
    'Total de Indústrias',
    CAST(COUNT(DISTINCT Industria) AS VARCHAR(20))
FROM EmpresasCSI500
WHERE Industria IS NOT NULL
UNION ALL
SELECT
    'Valor Médio Atual do Mercado',
    CAST(CAST(ValorMedioMercado AS DECIMAL(10,2)) AS VARCHAR(20))
FROM CSI500Historico
WHERE DataReferencia = (SELECT MAX(DataReferencia) FROM CSI500Historico);
GO

PRINT '';
PRINT '========================================';
PRINT 'ANÁLISES CSI500 CONCLUÍDAS!';
PRINT '========================================';
GO
