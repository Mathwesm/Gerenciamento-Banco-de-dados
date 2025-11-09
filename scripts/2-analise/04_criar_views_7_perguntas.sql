-- =============================================
-- Script: Views Analíticas para 7 Perguntas de Negócio
-- Descrição: Cria views otimizadas para responder as perguntas analíticas
-- Autor: Sistema de Análise Financeira
-- Data: 2025-11-08
-- =============================================
-- Prerequisito: Execute primeiro 01_criar_tabelas_normalizadas.sql
-- =============================================

USE datasets;
GO

PRINT '========================================';
PRINT 'CRIANDO VIEWS ANALÍTICAS';
PRINT '========================================';
PRINT '';
GO

-- =============================================
-- LIMPAR VIEWS EXISTENTES
-- =============================================
IF OBJECT_ID('dbo.vw_P1_MaiorValorizacaoUltimoAno', 'V') IS NOT NULL DROP VIEW dbo.vw_P1_MaiorValorizacaoUltimoAno;
IF OBJECT_ID('dbo.vw_P2_VolatilidadePorIndustria', 'V') IS NOT NULL DROP VIEW dbo.vw_P2_VolatilidadePorIndustria;
IF OBJECT_ID('dbo.vw_P3_MaiorVolumeNegociacao', 'V') IS NOT NULL DROP VIEW dbo.vw_P3_MaiorVolumeNegociacao;
IF OBJECT_ID('dbo.vw_P4_CrescimentoConsistente5Anos', 'V') IS NOT NULL DROP VIEW dbo.vw_P4_CrescimentoConsistente5Anos;
IF OBJECT_ID('dbo.vw_P5_DesempenhoSetoresSP500', 'V') IS NOT NULL DROP VIEW dbo.vw_P5_DesempenhoSetoresSP500;
IF OBJECT_ID('dbo.vw_P6_QuedaCriseCovid', 'V') IS NOT NULL DROP VIEW dbo.vw_P6_QuedaCriseCovid;
IF OBJECT_ID('dbo.vw_P7_DadosBaseParaDividendos', 'V') IS NOT NULL DROP VIEW dbo.vw_P7_DadosBaseParaDividendos;
GO

/* ========================================================================
   VIEW 1: Ações com Maior Valorização no Último Ano
   ======================================================================== */
PRINT 'Criando VIEW 1: Maior Valorização no Último Ano...';
GO

CREATE VIEW dbo.vw_P1_MaiorValorizacaoUltimoAno AS
WITH UltimaData AS (
    SELECT MAX(TradeDate) AS DataMaxima
    FROM dbo.AcoesChinesas
),
PrecoInicial AS (
    SELECT
        a.Symbol,
        a.CompanyNameEnglish,
        a.Industry,
        MIN(a.TradeDate) AS DataInicial,
        AVG(a.ClosePrice) AS PrecoInicial
    FROM dbo.AcoesChinesas a
    CROSS JOIN UltimaData ud
    WHERE a.TradeDate >= DATEADD(YEAR, -1, ud.DataMaxima)
      AND a.TradeDate <= DATEADD(DAY, 7, DATEADD(YEAR, -1, ud.DataMaxima))
      AND a.ClosePrice IS NOT NULL
    GROUP BY a.Symbol, a.CompanyNameEnglish, a.Industry
),
PrecoFinal AS (
    SELECT
        a.Symbol,
        MAX(a.TradeDate) AS DataFinal,
        AVG(a.ClosePrice) AS PrecoFinal
    FROM dbo.AcoesChinesas a
    CROSS JOIN UltimaData ud
    WHERE a.TradeDate >= DATEADD(DAY, -7, ud.DataMaxima)
      AND a.TradeDate <= ud.DataMaxima
      AND a.ClosePrice IS NOT NULL
    GROUP BY a.Symbol
)
SELECT
    pi.Symbol,
    pi.CompanyNameEnglish AS Empresa,
    pi.Industry           AS Industria,
    pi.DataInicial,
    CAST(pi.PrecoInicial AS DECIMAL(10, 4)) AS PrecoInicial,
    pf.DataFinal,
    CAST(pf.PrecoFinal AS DECIMAL(10, 4)) AS PrecoFinal,
    CAST((pf.PrecoFinal - pi.PrecoInicial) AS DECIMAL(10, 4)) AS ValorizacaoAbsoluta,
    CAST(((pf.PrecoFinal - pi.PrecoInicial) / NULLIF(pi.PrecoInicial, 0) * 100) AS DECIMAL(10, 2)) AS ValorizacaoPercentual,
    CASE
        WHEN ((pf.PrecoFinal - pi.PrecoInicial) / NULLIF(pi.PrecoInicial, 0) * 100) > 50 THEN 'Crescimento Excepcional'
        WHEN ((pf.PrecoFinal - pi.PrecoInicial) / NULLIF(pi.PrecoInicial, 0) * 100) > 20 THEN 'Alto Crescimento'
        WHEN ((pf.PrecoFinal - pi.PrecoInicial) / NULLIF(pi.PrecoInicial, 0) * 100) > 0 THEN 'Crescimento Moderado'
        WHEN ((pf.PrecoFinal - pi.PrecoInicial) / NULLIF(pi.PrecoInicial, 0) * 100) > -20 THEN 'Queda Moderada'
        ELSE 'Queda Significativa'
    END AS CategoriaDesempenho
FROM PrecoInicial pi
INNER JOIN PrecoFinal pf ON pi.Symbol = pf.Symbol
WHERE pi.PrecoInicial > 0
  AND pf.PrecoFinal IS NOT NULL;
GO

PRINT '✓ VIEW 1 criada com sucesso!';
GO

/* ========================================================================
   VIEW 2: Volatilidade Média por Indústria
   ======================================================================== */
PRINT 'Criando VIEW 2: Volatilidade Média por Indústria...';
GO

CREATE VIEW dbo.vw_P2_VolatilidadePorIndustria AS
WITH RetornosDiarios AS (
    SELECT
        Symbol,
        Industry,
        TradeDate,
        ClosePrice,
        LAG(ClosePrice) OVER (PARTITION BY Symbol ORDER BY TradeDate) AS PrecoAnterior
    FROM dbo.AcoesChinesas
    WHERE ClosePrice IS NOT NULL
),
Calculos AS (
    SELECT
        Symbol,
        Industry,
        TradeDate,
        CASE
            WHEN PrecoAnterior IS NOT NULL AND PrecoAnterior > 0
            THEN ((ClosePrice - PrecoAnterior) / PrecoAnterior)
            ELSE NULL
        END AS RetornoDiario
    FROM RetornosDiarios
)
SELECT
    COALESCE(Industry, 'Sem Classificação') AS Industria,
    COUNT(DISTINCT Symbol)                  AS QtdEmpresas,
    COUNT(*)                                AS QtdObservacoes,
    CAST(AVG(RetornoDiario) * 100 AS DECIMAL(10, 4))                       AS RetornoMedioDiario_Pct,
    CAST(STDEV(RetornoDiario) * 100 AS DECIMAL(10, 4))                     AS VolatilidadeDiaria_Pct,
    CAST(STDEV(RetornoDiario) * SQRT(252) * 100 AS DECIMAL(10, 4))         AS VolatilidadeAnualizada_Pct,
    CAST(MIN(RetornoDiario) * 100 AS DECIMAL(10, 4))                       AS MenorRetornoDiario_Pct,
    CAST(MAX(RetornoDiario) * 100 AS DECIMAL(10, 4))                       AS MaiorRetornoDiario_Pct,
    CASE
        WHEN STDEV(RetornoDiario) * SQRT(252) * 100 > 40 THEN 'Muito Alta'
        WHEN STDEV(RetornoDiario) * SQRT(252) * 100 > 25 THEN 'Alta'
        WHEN STDEV(RetornoDiario) * SQRT(252) * 100 > 15 THEN 'Moderada'
        ELSE 'Baixa'
    END AS ClassificacaoVolatilidade
FROM Calculos
WHERE RetornoDiario IS NOT NULL
GROUP BY Industry;
GO

PRINT '✓ VIEW 2 criada com sucesso!';
GO

/* ========================================================================
   VIEW 3: Empresas com Maior Volume de Negociação (Últimos 6 meses)
   ======================================================================== */
PRINT 'Criando VIEW 3: Maior Volume de Negociação...';
GO

CREATE VIEW dbo.vw_P3_MaiorVolumeNegociacao AS
WITH UltimaData AS (
    SELECT MAX(TradeDate) AS DataMaxima
    FROM dbo.AcoesChinesas
),
Periodo AS (
    SELECT
        a.Symbol,
        a.CompanyNameEnglish,
        a.Industry,
        a.TradeDate,
        a.Volume,
        a.Amount,
        a.TurnoverRate
    FROM dbo.AcoesChinesas a
    CROSS JOIN UltimaData ud
    WHERE a.TradeDate >= DATEADD(MONTH, -6, ud.DataMaxima)
      AND a.TradeDate <= ud.DataMaxima
      AND a.Volume IS NOT NULL
)
SELECT
    Symbol,
    CompanyNameEnglish AS Empresa,
    Industry           AS Industria,
    COUNT(DISTINCT TradeDate)                      AS DiasNegociados,
    CAST(SUM(Volume) AS DECIMAL(20, 0))            AS VolumeTotal,
    CAST(AVG(Volume) AS DECIMAL(20, 0))            AS VolumeMediaDiaria,
    CAST(MAX(Volume) AS DECIMAL(20, 0))            AS VolumeMaximoDia,
    CAST(SUM(Amount) AS DECIMAL(20, 0))            AS ValorFinanceiroTotal,
    CAST(AVG(Amount) AS DECIMAL(20, 0))            AS ValorFinanceiroMedioDiario,
    CAST(AVG(TurnoverRate) * 100 AS DECIMAL(10, 4)) AS TaxaGiroMedia_Pct,
    CASE
        WHEN AVG(TurnoverRate) * 100 > 5   THEN 'Muito Líquida'
        WHEN AVG(TurnoverRate) * 100 > 2   THEN 'Líquida'
        WHEN AVG(TurnoverRate) * 100 > 0.5 THEN 'Moderadamente Líquida'
        ELSE 'Pouco Líquida'
    END AS ClassificacaoLiquidez
FROM Periodo
GROUP BY Symbol, CompanyNameEnglish, Industry;
GO

PRINT '✓ VIEW 3 criada com sucesso!';
GO

/* ========================================================================
   VIEW 4: Ações com Crescimento Consistente (Últimos 5 Anos)
   ======================================================================== */
PRINT 'Criando VIEW 4: Crescimento Consistente (5 Anos)...';
GO

CREATE VIEW dbo.vw_P4_CrescimentoConsistente5Anos AS
WITH UltimaData AS (
    SELECT MAX(TradeDate) AS DataMaxima
    FROM dbo.AcoesChinesas
),
DadosAno AS (
    SELECT
        a.Symbol,
        a.CompanyNameEnglish,
        a.Industry,
        YEAR(a.TradeDate) AS Ano,
        a.TradeDate,
        a.ClosePrice,
        ROW_NUMBER() OVER (PARTITION BY a.Symbol, YEAR(a.TradeDate) ORDER BY a.TradeDate ASC)  AS PrimeiraData,
        ROW_NUMBER() OVER (PARTITION BY a.Symbol, YEAR(a.TradeDate) ORDER BY a.TradeDate DESC) AS UltimaData
    FROM dbo.AcoesChinesas a
    CROSS JOIN UltimaData ud
    WHERE a.TradeDate >= DATEADD(YEAR, -5, ud.DataMaxima)
      AND a.ClosePrice IS NOT NULL
),
RetornosAnuais AS (
    SELECT
        Symbol,
        CompanyNameEnglish,
        Industry,
        Ano,
        MAX(CASE WHEN PrimeiraData = 1 THEN ClosePrice END) AS PrecoAbertura,
        MAX(CASE WHEN UltimaData   = 1 THEN ClosePrice END) AS PrecoFechamento
    FROM DadosAno
    GROUP BY Symbol, CompanyNameEnglish, Industry, Ano
),
Consistencia AS (
    SELECT
        Symbol,
        CompanyNameEnglish,
        Industry,
        COUNT(DISTINCT Ano) AS AnosComDados,
        SUM(CASE WHEN ((PrecoFechamento - PrecoAbertura) / NULLIF(PrecoAbertura, 0)) > 0 THEN 1 ELSE 0 END) AS AnosPositivos,
        AVG((PrecoFechamento - PrecoAbertura) / NULLIF(PrecoAbertura, 0) * 100) AS RetornoMedioAnual_Pct,
        STDEV((PrecoFechamento - PrecoAbertura) / NULLIF(PrecoAbertura, 0) * 100) AS VolatilidadeRetornos_Pct,
        MIN((PrecoFechamento - PrecoAbertura) / NULLIF(PrecoAbertura, 0) * 100) AS PiorAno_Pct,
        MAX((PrecoFechamento - PrecoAbertura) / NULLIF(PrecoAbertura, 0) * 100) AS MelhorAno_Pct
    FROM RetornosAnuais
    WHERE PrecoAbertura  > 0
      AND PrecoFechamento IS NOT NULL
    GROUP BY Symbol, CompanyNameEnglish, Industry
)
SELECT
    Symbol,
    CompanyNameEnglish AS Empresa,
    Industry           AS Industria,
    AnosComDados,
    AnosPositivos,
    CAST((CAST(AnosPositivos AS FLOAT) / NULLIF(AnosComDados, 0) * 100) AS DECIMAL(10, 2)) AS TaxaSucessoPct,
    CAST(RetornoMedioAnual_Pct     AS DECIMAL(10, 2)) AS RetornoMedioAnual_Pct,
    CAST(VolatilidadeRetornos_Pct  AS DECIMAL(10, 2)) AS VolatilidadeRetornos_Pct,
    CAST(PiorAno_Pct               AS DECIMAL(10, 2)) AS PiorAno_Pct,
    CAST(MelhorAno_Pct             AS DECIMAL(10, 2)) AS MelhorAno_Pct,
    CASE
        WHEN VolatilidadeRetornos_Pct > 0
        THEN CAST((RetornoMedioAnual_Pct / NULLIF(VolatilidadeRetornos_Pct, 0)) AS DECIMAL(10, 4))
        ELSE NULL
    END AS SharpeRatioSimplificado,
    CASE
        WHEN (CAST(AnosPositivos AS FLOAT) / NULLIF(AnosComDados, 0) * 100) >= 80 THEN 'Muito Consistente'
        WHEN (CAST(AnosPositivos AS FLOAT) / NULLIF(AnosComDados, 0) * 100) >= 60 THEN 'Consistente'
        WHEN (CAST(AnosPositivos AS FLOAT) / NULLIF(AnosComDados, 0) * 100) >= 40 THEN 'Moderadamente Consistente'
        ELSE 'Inconsistente'
    END AS ClassificacaoConsistencia
FROM Consistencia
WHERE AnosComDados >= 3;
GO

PRINT '✓ VIEW 4 criada com sucesso!';
GO

/* ========================================================================
   VIEW 5: Desempenho de Setores no S&P 500
   ======================================================================== */
PRINT 'Criando VIEW 5: Desempenho de Setores (S&P 500)...';
GO

CREATE VIEW dbo.vw_P5_DesempenhoSetoresSP500 AS
WITH DadosSetores AS (
    SELECT
        e.GICSSector AS Setor,
        COUNT(*)     AS QtdEmpresas,
        MIN(e.DateAdded) AS PrimeiraAdicao,
        MAX(e.DateAdded) AS UltimaAdicao,
        AVG(YEAR(GETDATE()) - NULLIF(e.Founded, 0)) AS IdadeMediaAnos,
        COUNT(CASE WHEN e.DateAdded >= DATEADD(YEAR, -5, GETDATE()) THEN 1 END) AS AdicionadasUltimos5Anos,
        COUNT(CASE WHEN e.Founded >= YEAR(GETDATE()) - 50 THEN 1 END)          AS EmpresasRecentes
    FROM dbo.Empresas e
    WHERE e.GICSSector IS NOT NULL
    GROUP BY e.GICSSector
),
EvolucaoIndice AS (
    SELECT
        (SELECT TOP 1 SP500Value FROM dbo.IndiceSP500 ORDER BY ObservationDate ASC)  AS ValorInicial,
        (SELECT TOP 1 SP500Value FROM dbo.IndiceSP500 ORDER BY ObservationDate DESC) AS ValorFinal
)
SELECT
    ds.Setor,
    ds.QtdEmpresas,
    CAST((CAST(ds.QtdEmpresas AS FLOAT) / NULLIF((SELECT SUM(QtdEmpresas) FROM DadosSetores), 0) * 100) AS DECIMAL(10, 2)) AS ParticipacaoPct,
    ds.PrimeiraAdicao,
    ds.UltimaAdicao,
    CAST(ds.IdadeMediaAnos AS DECIMAL(10, 1)) AS IdadeMediaAnos,
    ds.AdicionadasUltimos5Anos,
    ds.EmpresasRecentes,
    CAST((CAST(ds.AdicionadasUltimos5Anos AS FLOAT) / NULLIF(ds.QtdEmpresas, 0) * 100) AS DECIMAL(10, 2)) AS PctAdicionadasRecentemente,
    CAST(((ei.ValorFinal - ei.ValorInicial) / NULLIF(ei.ValorInicial, 0) * 100) AS DECIMAL(10, 2)) AS RetornoTotalIndiceSP500_Pct,
    CASE
        WHEN ds.QtdEmpresas >= 60 THEN 'Setor Dominante'
        WHEN ds.QtdEmpresas >= 40 THEN 'Setor Principal'
        WHEN ds.QtdEmpresas >= 20 THEN 'Setor Relevante'
        ELSE 'Setor Especializado'
    END AS ClassificacaoTamanho
FROM DadosSetores ds
CROSS JOIN EvolucaoIndice ei;
GO

PRINT '✓ VIEW 5 criada com sucesso!';
GO

/* ========================================================================
   VIEW 6: Ações com Maior Queda Durante Crise COVID
   ======================================================================== */
PRINT 'Criando VIEW 6: Maior Queda na Crise COVID...';
GO

CREATE VIEW dbo.vw_P6_QuedaCriseCovid AS
WITH PeriodoCovid AS (
    SELECT
        Symbol,
        CompanyNameEnglish,
        Industry,
        TradeDate,
        ClosePrice,
        CASE
            WHEN TradeDate BETWEEN '2020-01-01' AND '2020-01-31' THEN 'PreCovid'
            WHEN TradeDate BETWEEN '2020-02-01' AND '2020-04-30' THEN 'Durante'
            WHEN TradeDate BETWEEN '2020-05-01' AND '2020-07-31' THEN 'Recuperacao'
            ELSE NULL
        END AS Fase
    FROM dbo.AcoesChinesas
    WHERE TradeDate BETWEEN '2020-01-01' AND '2020-07-31'
      AND ClosePrice IS NOT NULL
),
MinimoDurante AS (
    -- preço mínimo durante a fase "Durante" por ação
    SELECT
        Symbol,
        MIN(ClosePrice) AS PrecoMinimoCovid
    FROM PeriodoCovid
    WHERE Fase = 'Durante'
    GROUP BY Symbol
),
Precos AS (
    SELECT
        p.Symbol,
        p.CompanyNameEnglish,
        p.Industry,
        AVG(CASE WHEN p.Fase = 'PreCovid'     THEN p.ClosePrice END) AS PrecoPreCovid,
        m.PrecoMinimoCovid,
        MAX(CASE WHEN p.Fase = 'Durante'      THEN p.ClosePrice END) AS PrecoMaximoCovid,
        AVG(CASE WHEN p.Fase = 'Recuperacao'  THEN p.ClosePrice END) AS PrecoRecuperacao,
        MIN(CASE
                WHEN p.Fase = 'Durante'
                 AND p.ClosePrice = m.PrecoMinimoCovid
                THEN p.TradeDate
            END) AS DataMinimoAtingido
    FROM PeriodoCovid p
    LEFT JOIN MinimoDurante m
        ON m.Symbol = p.Symbol
    GROUP BY
        p.Symbol,
        p.CompanyNameEnglish,
        p.Industry,
        m.PrecoMinimoCovid
)
SELECT
    Symbol,
    CompanyNameEnglish AS Empresa,
    Industry           AS Industria,
    CAST(PrecoPreCovid    AS DECIMAL(10, 4)) AS PrecoPreCovid,
    CAST(PrecoMinimoCovid AS DECIMAL(10, 4)) AS PrecoMinimoCovid,
    DataMinimoAtingido,
    CAST((PrecoMinimoCovid - PrecoPreCovid) AS DECIMAL(10, 4)) AS QuedaAbsoluta,
    CAST(((PrecoMinimoCovid - PrecoPreCovid) / NULLIF(PrecoPreCovid, 0) * 100) AS DECIMAL(10, 2)) AS QuedaPercentual,
    CAST(PrecoMaximoCovid AS DECIMAL(10, 4)) AS PrecoMaximoCovid,
    CAST(((PrecoMaximoCovid - PrecoMinimoCovid) / NULLIF(PrecoMinimoCovid, 0) * 100) AS DECIMAL(10, 2)) AS RecuperacaoNoPeriodo_Pct,
    CAST(PrecoRecuperacao AS DECIMAL(10, 4)) AS PrecoRecuperacao,
    CAST(((PrecoRecuperacao - PrecoPreCovid) / NULLIF(PrecoPreCovid, 0) * 100) AS DECIMAL(10, 2)) AS RecuperacaoTotal_Pct,
    CASE
        WHEN ((PrecoMinimoCovid - PrecoPreCovid) / NULLIF(PrecoPreCovid, 0) * 100) > -10 THEN 'Resiliente'
        WHEN ((PrecoMinimoCovid - PrecoPreCovid) / NULLIF(PrecoPreCovid, 0) * 100) > -25 THEN 'Impacto Moderado'
        WHEN ((PrecoMinimoCovid - PrecoPreCovid) / NULLIF(PrecoPreCovid, 0) * 100) > -40 THEN 'Alto Impacto'
        ELSE 'Impacto Severo'
    END AS ClassificacaoImpacto
FROM Precos
WHERE PrecoPreCovid    IS NOT NULL
  AND PrecoMinimoCovid IS NOT NULL
  AND PrecoPreCovid    > 0;
GO

PRINT '✓ VIEW 6 criada com sucesso!';
GO

/* ========================================================================
   VIEW 7: Dados Base para Análise de Dividendos (Futura)
   ======================================================================== */
PRINT 'Criando VIEW 7: Base para Dividendos...';
GO

CREATE VIEW dbo.vw_P7_DadosBaseParaDividendos AS
SELECT
    e.Symbol,
    e.Security           AS NomeEmpresa,
    e.GICSSector         AS Setor,
    e.GICSSubIndustry    AS SubIndustria,
    e.HeadquartersLocation AS Sede,
    e.DateAdded          AS DataAdicaoSP500,
    e.Founded            AS AnoFundacao,
    COUNT(DISTINCT CASE WHEN e.DateAdded IS NOT NULL THEN 1 END) AS EstaNoSP500,
    YEAR(GETDATE()) - NULLIF(e.Founded, 0) AS IdadeEmpresa,
    CASE
        WHEN e.GICSSector IN ('Utilities', 'Real Estate', 'Consumer Staples', 'Financials')
            THEN 'Setor Tipicamente Pagador de Dividendos'
        WHEN e.GICSSector IN ('Information Technology', 'Communication Services')
            THEN 'Setor com Dividendos Variáveis'
        ELSE 'Outros Setores'
    END AS TendenciaDividendos,
    'NOTA: Dados de dividendos não disponíveis no dataset atual. ' +
    'Para análise completa, importar histórico de dividendos de fontes como Yahoo Finance, Bloomberg ou relatórios corporativos.' AS Observacao
FROM dbo.Empresas e
WHERE e.Symbol IS NOT NULL
GROUP BY
    e.Symbol, e.Security, e.GICSSector, e.GICSSubIndustry,
    e.HeadquartersLocation, e.DateAdded, e.Founded;
GO

PRINT '✓ VIEW 7 criada com sucesso!';
GO

/* ========================================================================
   VERIFICAÇÃO FINAL
   ======================================================================== */
PRINT '';
PRINT '========================================';
PRINT 'VERIFICAÇÃO DAS VIEWS CRIADAS';
PRINT '========================================';
GO

SELECT
    'vw_P1_MaiorValorizacaoUltimoAno'  AS NomeView,
    'Pergunta 1: Maior valorização no último ano' AS Descricao,
    COUNT(*)                           AS TotalRegistros
FROM dbo.vw_P1_MaiorValorizacaoUltimoAno

UNION ALL

SELECT
    'vw_P2_VolatilidadePorIndustria',
    'Pergunta 2: Volatilidade média por indústria',
    COUNT(*)
FROM dbo.vw_P2_VolatilidadePorIndustria

UNION ALL

SELECT
    'vw_P3_MaiorVolumeNegociacao',
    'Pergunta 3: Maior volume de negociação',
    COUNT(*)
FROM dbo.vw_P3_MaiorVolumeNegociacao

UNION ALL

SELECT
    'vw_P4_CrescimentoConsistente5Anos',
    'Pergunta 4: Crescimento consistente (5 anos)',
    COUNT(*)
FROM dbo.vw_P4_CrescimentoConsistente5Anos

UNION ALL

SELECT
    'vw_P5_DesempenhoSetoresSP500',
    'Pergunta 5: Desempenho de setores S&P 500',
    COUNT(*)
FROM dbo.vw_P5_DesempenhoSetoresSP500

UNION ALL

SELECT
    'vw_P6_QuedaCriseCovid',
    'Pergunta 6: Maior queda durante crise COVID',
    COUNT(*)
FROM dbo.vw_P6_QuedaCriseCovid

UNION ALL

SELECT
    'vw_P7_DadosBaseParaDividendos',
    'Pergunta 7: Base para análise de dividendos',
    COUNT(*)
FROM dbo.vw_P7_DadosBaseParaDividendos;
GO

PRINT '';
PRINT '========================================';
PRINT '✅ TODAS AS 7 VIEWS CRIADAS COM SUCESSO!';
PRINT '========================================';
PRINT '';
PRINT 'Para consultar os dados, use:';
PRINT '  SELECT TOP 10 * FROM dbo.vw_P1_MaiorValorizacaoUltimoAno ORDER BY ValorizacaoPercentual DESC;';
PRINT '  SELECT TOP 10 * FROM dbo.vw_P2_VolatilidadePorIndustria ORDER BY VolatilidadeAnualizada_Pct DESC;';
PRINT '  SELECT TOP 10 * FROM dbo.vw_P3_MaiorVolumeNegociacao ORDER BY VolumeTotal DESC;';
PRINT '  SELECT TOP 10 * FROM dbo.vw_P4_CrescimentoConsistente5Anos ORDER BY TaxaSucessoPct DESC;';
PRINT '  SELECT * FROM dbo.vw_P5_DesempenhoSetoresSP500 ORDER BY QtdEmpresas DESC;';
PRINT '  SELECT TOP 10 * FROM dbo.vw_P6_QuedaCriseCovid ORDER BY QuedaPercentual ASC;';
PRINT '  SELECT * FROM dbo.vw_P7_DadosBaseParaDividendos WHERE Setor = ''Utilities'';';
PRINT '========================================';
GO
