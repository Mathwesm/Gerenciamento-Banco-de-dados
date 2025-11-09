-- ========================================
-- SCRIPT: CRIAR VIEWS DE ANÁLISE
-- ========================================
-- Descrição: Cria views para facilitar análises
-- Database: FinanceDB
-- ========================================

USE FinanceDB;
GO

PRINT '========================================';
PRINT 'CRIANDO VIEWS DE ANÁLISE';
PRINT '========================================';
PRINT '';
GO

-- ========================================
-- VIEW 1: Valorização por Ação (Últimos 6 meses)
-- ========================================
IF OBJECT_ID('vw_ValorizacaoAcoes', 'V') IS NOT NULL DROP VIEW vw_ValorizacaoAcoes;
GO

CREATE VIEW vw_ValorizacaoAcoes AS
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
SELECT
    pi.CIK,
    pi.Ticker,
    pi.NomeEmpresa,
    pi.Setor,
    pi.DataInicial,
    CAST(pi.PrecoInicial AS DECIMAL(10,2)) AS PrecoInicial,
    pf.DataFinal,
    CAST(pf.PrecoFinal AS DECIMAL(10,2)) AS PrecoFinal,
    CAST((pf.PrecoFinal - pi.PrecoInicial) AS DECIMAL(10,2)) AS ValorizacaoAbsoluta,
    CAST(((pf.PrecoFinal - pi.PrecoInicial) / NULLIF(pi.PrecoInicial, 0) * 100) AS DECIMAL(10,2)) AS ValorizacaoPercentual,
    CASE
        WHEN ((pf.PrecoFinal - pi.PrecoInicial) / NULLIF(pi.PrecoInicial, 0) * 100) > 50 THEN 'Crescimento Excepcional'
        WHEN ((pf.PrecoFinal - pi.PrecoInicial) / NULLIF(pi.PrecoInicial, 0) * 100) > 20 THEN 'Alto Crescimento'
        WHEN ((pf.PrecoFinal - pi.PrecoInicial) / NULLIF(pi.PrecoInicial, 0) * 100) > 0 THEN 'Crescimento Moderado'
        WHEN ((pf.PrecoFinal - pi.PrecoInicial) / NULLIF(pi.PrecoInicial, 0) * 100) > -20 THEN 'Queda Moderada'
        ELSE 'Queda Significativa'
    END AS CategoriaDesempenho
FROM PrecoInicial pi
INNER JOIN PrecoFinal pf ON pi.CIK = pf.CIK
WHERE pi.PrecoInicial > 0;
GO

PRINT 'VIEW vw_ValorizacaoAcoes criada.';
GO

-- ========================================
-- VIEW 2: Volatilidade por Setor
-- ========================================
IF OBJECT_ID('vw_VolatilidadeSetor', 'V') IS NOT NULL DROP VIEW vw_VolatilidadeSetor;
GO

CREATE VIEW vw_VolatilidadeSetor AS
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
    CAST(STDEV(RetornoDiario) * SQRT(252) * 100 AS DECIMAL(10, 4)) AS VolatilidadeAnualizada_Pct,
    CASE
        WHEN STDEV(RetornoDiario) * SQRT(252) * 100 > 30 THEN 'Alta Volatilidade'
        WHEN STDEV(RetornoDiario) * SQRT(252) * 100 > 20 THEN 'Volatilidade Moderada'
        ELSE 'Baixa Volatilidade'
    END AS ClassificacaoVolatilidade
FROM CalculoRetornos
WHERE RetornoDiario IS NOT NULL
GROUP BY Setor;
GO

PRINT 'VIEW vw_VolatilidadeSetor criada.';
GO

-- ========================================
-- VIEW 3: Volume de Negociação por Empresa
-- ========================================
IF OBJECT_ID('vw_VolumeNegociacao', 'V') IS NOT NULL DROP VIEW vw_VolumeNegociacao;
GO

CREATE VIEW vw_VolumeNegociacao AS
SELECT
    e.CIK,
    e.Ticker,
    e.NomeEmpresa,
    e.Setor,
    COUNT(DISTINCT t.DataCompleta) AS DiasNegociados,
    CAST(SUM(p.Volume) AS DECIMAL(20, 0)) AS VolumeTotal,
    CAST(AVG(p.Volume) AS DECIMAL(18, 0)) AS VolumeMediaDiaria,
    CAST(AVG(p.PrecoFechamento) AS DECIMAL(10, 2)) AS PrecoMedio,
    CAST(MIN(p.PrecoFechamento) AS DECIMAL(10, 2)) AS PrecoMinimo,
    CAST(MAX(p.PrecoFechamento) AS DECIMAL(10, 2)) AS PrecoMaximo
FROM PrecoAcao p
INNER JOIN Empresas e ON p.CIK = e.CIK
INNER JOIN Tempo t ON p.IdTempo = t.IdTempo
WHERE p.Volume IS NOT NULL
  AND t.DataCompleta >= DATEADD(MONTH, -6, (SELECT MAX(DataCompleta) FROM Tempo))
GROUP BY e.CIK, e.Ticker, e.NomeEmpresa, e.Setor;
GO

PRINT 'VIEW vw_VolumeNegociacao criada.';
GO

-- ========================================
-- VIEW 4: Evolução Mensal do S&P 500
-- ========================================
IF OBJECT_ID('vw_EvolucaoSP500Mensal', 'V') IS NOT NULL DROP VIEW vw_EvolucaoSP500Mensal;
GO

CREATE VIEW vw_EvolucaoSP500Mensal AS
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
    CAST(((FechamentoMes - AberturaMes) / NULLIF(AberturaMes, 0) * 100) AS DECIMAL(10, 2)) AS RetornoMensal_Pct,
    CAST(((MaximoMes - MinimoMes) / NULLIF(AberturaMes, 0) * 100) AS DECIMAL(10, 2)) AS AmplitudeMensal_Pct
FROM IndiceMensal;
GO

PRINT 'VIEW vw_EvolucaoSP500Mensal criada.';
GO

-- ========================================
-- VIEW 5: Distribuição de Empresas por Setor
-- ========================================
IF OBJECT_ID('vw_EmpresasPorSetor', 'V') IS NOT NULL DROP VIEW vw_EmpresasPorSetor;
GO

CREATE VIEW vw_EmpresasPorSetor AS
SELECT
    e.Setor,
    COUNT(*) AS QtdEmpresas,
    MIN(e.DataEntrada) AS PrimeiraAdicao,
    MAX(e.DataEntrada) AS UltimaAdicao,
    CAST(AVG(CAST(YEAR(GETDATE()) - e.AnoFundacao AS FLOAT)) AS DECIMAL(10, 1)) AS IdadeMediaAnos,
    COUNT(CASE WHEN e.DataEntrada >= DATEADD(YEAR, -5, GETDATE()) THEN 1 END) AS AdicionadasUltimos5Anos,
    STRING_AGG(e.Ticker, ', ') AS Tickers
FROM Empresas e
WHERE e.Setor IS NOT NULL
GROUP BY e.Setor;
GO

PRINT 'VIEW vw_EmpresasPorSetor criada.';
GO

-- ========================================
-- VIEW 6: Resumo de Desempenho por Empresa
-- ========================================
IF OBJECT_ID('vw_ResumoDesempenhoEmpresas', 'V') IS NOT NULL DROP VIEW vw_ResumoDesempenhoEmpresas;
GO

CREATE VIEW vw_ResumoDesempenhoEmpresas AS
WITH EstatisticasPreco AS (
    SELECT
        p.CIK,
        COUNT(*) AS QtdObservacoes,
        MIN(t.DataCompleta) AS PrimeiraData,
        MAX(t.DataCompleta) AS UltimaData,
        CAST(AVG(p.PrecoFechamento) AS DECIMAL(10, 2)) AS PrecoMedio,
        CAST(MIN(p.PrecoFechamento) AS DECIMAL(10, 2)) AS PrecoMinimo,
        CAST(MAX(p.PrecoFechamento) AS DECIMAL(10, 2)) AS PrecoMaximo,
        CAST(AVG(p.Volume) AS DECIMAL(18, 0)) AS VolumeMediaDiaria,
        CAST(AVG(p.VariacaoPercentual) AS DECIMAL(10, 4)) AS VariacaoMediaDiaria
    FROM PrecoAcao p
    INNER JOIN Tempo t ON p.IdTempo = t.IdTempo
    GROUP BY p.CIK
)
SELECT
    e.CIK,
    e.Ticker,
    e.NomeEmpresa,
    e.Setor,
    l.Cidade,
    l.Estado,
    s.Industria,
    s.SubIndustria,
    e.DataEntrada,
    e.AnoFundacao,
    ep.QtdObservacoes,
    ep.PrimeiraData,
    ep.UltimaData,
    ep.PrecoMedio,
    ep.PrecoMinimo,
    ep.PrecoMaximo,
    ep.VolumeMediaDiaria,
    ep.VariacaoMediaDiaria
FROM Empresas e
LEFT JOIN EstatisticasPreco ep ON e.CIK = ep.CIK
LEFT JOIN Localizacao l ON e.CIK = l.CIK
LEFT JOIN SubSetor s ON e.CIK = s.CIK;
GO

PRINT 'VIEW vw_ResumoDesempenhoEmpresas criada.';
GO

-- ========================================
-- VERIFICAÇÃO E TESTES DAS VIEWS
-- ========================================
PRINT '';
PRINT '========================================';
PRINT 'VERIFICAÇÃO DAS VIEWS CRIADAS';
PRINT '========================================';
GO

SELECT TABLE_NAME AS ViewCriada
FROM INFORMATION_SCHEMA.VIEWS
WHERE TABLE_SCHEMA = 'dbo'
ORDER BY TABLE_NAME;
GO

PRINT '';
PRINT 'Testando views...';
PRINT '';
GO

-- Teste VIEW 1
PRINT '1. Top 5 Ações com Maior Valorização:';
SELECT TOP 5 Ticker, NomeEmpresa, ValorizacaoPercentual, CategoriaDesempenho
FROM vw_ValorizacaoAcoes
ORDER BY ValorizacaoPercentual DESC;
GO

-- Teste VIEW 2
PRINT '';
PRINT '2. Setores Mais Voláteis:';
SELECT TOP 5 Setor, QtdEmpresas, VolatilidadeAnualizada_Pct, ClassificacaoVolatilidade
FROM vw_VolatilidadeSetor
WHERE QtdEmpresas >= 3
ORDER BY VolatilidadeAnualizada_Pct DESC;
GO

-- Teste VIEW 3
PRINT '';
PRINT '3. Empresas com Maior Volume:';
SELECT TOP 5 Ticker, NomeEmpresa, VolumeTotal, VolumeMediaDiaria
FROM vw_VolumeNegociacao
ORDER BY VolumeTotal DESC;
GO

-- Teste VIEW 4
PRINT '';
PRINT '4. Evolução S&P 500 (Últimos 3 meses):';
SELECT TOP 3 Ano, Mes, Abertura, Fechamento, RetornoMensal_Pct
FROM vw_EvolucaoSP500Mensal
ORDER BY Ano DESC, Mes DESC;
GO

-- Teste VIEW 5
PRINT '';
PRINT '5. Setores com Mais Empresas:';
SELECT TOP 5 Setor, QtdEmpresas, IdadeMediaAnos
FROM vw_EmpresasPorSetor
ORDER BY QtdEmpresas DESC;
GO

-- Teste VIEW 6
PRINT '';
PRINT '6. Resumo de Empresas (Amostra):';
SELECT TOP 5 Ticker, NomeEmpresa, Setor, PrecoMedio, VolumeMediaDiaria
FROM vw_ResumoDesempenhoEmpresas
ORDER BY Ticker;
GO

PRINT '';
PRINT '========================================';
PRINT 'VIEWS DE ANÁLISE CRIADAS COM SUCESSO!';
PRINT '========================================';
PRINT '';
PRINT 'Views disponíveis:';
PRINT '  1. vw_ValorizacaoAcoes - Valorização de ações';
PRINT '  2. vw_VolatilidadeSetor - Volatilidade por setor';
PRINT '  3. vw_VolumeNegociacao - Volume de negociação';
PRINT '  4. vw_EvolucaoSP500Mensal - Evolução do índice';
PRINT '  5. vw_EmpresasPorSetor - Distribuição por setor';
PRINT '  6. vw_ResumoDesempenhoEmpresas - Resumo completo';
PRINT '';
PRINT 'Use: SELECT * FROM vw_[NomeDaView]';
PRINT '========================================';
GO
