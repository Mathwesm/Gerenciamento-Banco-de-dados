-- =============================================
-- Script: Queries de Análise - Mercado de Ações
-- Descrição: Queries para responder as 7 perguntas analíticas
-- Autor: Sistema de Análise Financeira
-- Data: 2025-11-07
-- =============================================

USE datasets
GO

-- =============================================
-- PERGUNTA 1: Quais ações tiveram maior valorização percentual no último ano?
-- =============================================
PRINT ''
PRINT '============================================='
PRINT 'PERGUNTA 1: Maior Valorização no Último Ano'
PRINT '============================================='
GO

WITH PrecoInicial AS (
    SELECT
        Symbol,
        CompanyNameEnglish,
        TradeDate,
        ClosePrice,
        ROW_NUMBER() OVER (PARTITION BY Symbol ORDER BY TradeDate ASC) as RowNum
    FROM dbo.AcoesChinesas
    WHERE TradeDate >= DATEADD(YEAR, -1, (SELECT MAX(TradeDate) FROM dbo.AcoesChinesas))
),
PrecoFinal AS (
    SELECT
        Symbol,
        TradeDate,
        ClosePrice,
        ROW_NUMBER() OVER (PARTITION BY Symbol ORDER BY TradeDate DESC) as RowNum
    FROM dbo.AcoesChinesas
    WHERE TradeDate <= (SELECT MAX(TradeDate) FROM dbo.AcoesChinesas)
)
SELECT TOP 20
    pi.Symbol,
    pi.CompanyNameEnglish as Empresa,
    pi.TradeDate as DataInicial,
    pi.ClosePrice as PrecoInicial,
    pf.TradeDate as DataFinal,
    pf.ClosePrice as PrecoFinal,
    CAST(
        ((pf.ClosePrice - pi.ClosePrice) / pi.ClosePrice * 100)
        as DECIMAL(10, 2)
    ) as ValorizacaoPercentual,
    CAST((pf.ClosePrice - pi.ClosePrice) as DECIMAL(10, 2)) as ValorizacaoAbsoluta
FROM PrecoInicial pi
INNER JOIN PrecoFinal pf ON pi.Symbol = pf.Symbol
WHERE pi.RowNum = 1 AND pf.RowNum = 1
  AND pi.ClosePrice IS NOT NULL
  AND pf.ClosePrice IS NOT NULL
  AND pi.ClosePrice > 0
ORDER BY ValorizacaoPercentual DESC;
GO

-- =============================================
-- PERGUNTA 2: Qual é a volatilidade média das ações por setor ou indústria?
-- =============================================
PRINT ''
PRINT '============================================='
PRINT 'PERGUNTA 2: Volatilidade Média por Indústria'
PRINT '============================================='
GO

WITH Volatilidade AS (
    SELECT
        Symbol,
        Industry,
        TradeDate,
        ClosePrice,
        LAG(ClosePrice) OVER (PARTITION BY Symbol ORDER BY TradeDate) as PrecoAnterior
    FROM dbo.AcoesChinesas
    WHERE ClosePrice IS NOT NULL
),
RetornosDiarios AS (
    SELECT
        Symbol,
        Industry,
        TradeDate,
        CASE
            WHEN PrecoAnterior IS NOT NULL AND PrecoAnterior > 0
            THEN ((ClosePrice - PrecoAnterior) / PrecoAnterior)
            ELSE NULL
        END as RetornoDiario
    FROM Volatilidade
)
SELECT
    COALESCE(Industry, 'Sem Classificação') as Industria,
    COUNT(DISTINCT Symbol) as QtdEmpresas,
    COUNT(*) as QtdObservacoes,
    CAST(AVG(RetornoDiario) * 100 as DECIMAL(10, 4)) as RetornoMedioDiario_Pct,
    CAST(STDEV(RetornoDiario) * 100 as DECIMAL(10, 4)) as VolatilidadeDiaria_Pct,
    CAST(STDEV(RetornoDiario) * SQRT(252) * 100 as DECIMAL(10, 4)) as VolatilidadeAnualizada_Pct,
    CAST(MIN(RetornoDiario) * 100 as DECIMAL(10, 4)) as MenorRetornoDiario_Pct,
    CAST(MAX(RetornoDiario) * 100 as DECIMAL(10, 4)) as MaiorRetornoDiario_Pct
FROM RetornosDiarios
WHERE RetornoDiario IS NOT NULL
GROUP BY Industry
ORDER BY VolatilidadeAnualizada_Pct DESC;
GO

-- =============================================
-- PERGUNTA 3: Quais empresas registraram maior volume de negociação em determinado período?
-- =============================================
PRINT ''
PRINT '============================================='
PRINT 'PERGUNTA 3: Maior Volume de Negociação (Últimos 6 meses)'
PRINT '============================================='
GO

DECLARE @DataInicio DATE = DATEADD(MONTH, -6, (SELECT MAX(TradeDate) FROM dbo.AcoesChinesas))
DECLARE @DataFim DATE = (SELECT MAX(TradeDate) FROM dbo.AcoesChinesas)

SELECT TOP 30
    a.Symbol,
    a.CompanyNameEnglish as Empresa,
    a.Industry as Industria,
    COUNT(DISTINCT a.TradeDate) as DiasNegociados,
    CAST(SUM(a.Volume) as DECIMAL(18, 0)) as VolumeTotal,
    CAST(AVG(a.Volume) as DECIMAL(18, 0)) as VolumeMediaDiaria,
    CAST(SUM(a.Amount) as DECIMAL(18, 0)) as ValorFinanceiroTotal,
    CAST(AVG(a.Amount) as DECIMAL(18, 0)) as ValorFinanceiroMedioDiario,
    CAST(AVG(a.TurnoverRate) * 100 as DECIMAL(10, 4)) as TaxaGiroMedia_Pct
FROM dbo.AcoesChinesas a
WHERE a.TradeDate BETWEEN @DataInicio AND @DataFim
  AND a.Volume IS NOT NULL
GROUP BY a.Symbol, a.CompanyNameEnglish, a.Industry
ORDER BY VolumeTotal DESC;
GO

-- =============================================
-- PERGUNTA 4: Quais ações apresentaram crescimento consistente ao longo dos últimos 5 anos?
-- =============================================
PRINT ''
PRINT '============================================='
PRINT 'PERGUNTA 4: Crescimento Consistente (Últimos 5 anos)'
PRINT '============================================='
GO

WITH AnosPorAcao AS (
    SELECT
        Symbol,
        CompanyNameEnglish,
        YEAR(TradeDate) as Ano,
        MIN(ClosePrice) as PrecoMinimo,
        MAX(ClosePrice) as PrecoMaximo,
        AVG(ClosePrice) as PrecoMedio,
        FIRST_VALUE(ClosePrice) OVER (PARTITION BY Symbol, YEAR(TradeDate) ORDER BY TradeDate ASC) as PrecoAbertura,
        FIRST_VALUE(ClosePrice) OVER (PARTITION BY Symbol, YEAR(TradeDate) ORDER BY TradeDate DESC) as PrecoFechamento
    FROM dbo.AcoesChinesas
    WHERE TradeDate >= DATEADD(YEAR, -5, (SELECT MAX(TradeDate) FROM dbo.AcoesChinesas))
      AND ClosePrice IS NOT NULL
    GROUP BY Symbol, CompanyNameEnglish, YEAR(TradeDate), TradeDate, ClosePrice
),
RetornosAnuais AS (
    SELECT DISTINCT
        Symbol,
        CompanyNameEnglish,
        Ano,
        PrecoAbertura,
        PrecoFechamento,
        CASE
            WHEN PrecoAbertura > 0
            THEN ((PrecoFechamento - PrecoAbertura) / PrecoAbertura * 100)
            ELSE NULL
        END as RetornoAnual
    FROM AnosPorAcao
),
Consistencia AS (
    SELECT
        Symbol,
        CompanyNameEnglish,
        COUNT(DISTINCT Ano) as AnosComDados,
        SUM(CASE WHEN RetornoAnual > 0 THEN 1 ELSE 0 END) as AnosPositivos,
        AVG(RetornoAnual) as RetornoMedioAnual,
        STDEV(RetornoAnual) as VolatilidadeRetornos,
        MIN(RetornoAnual) as PiorAno,
        MAX(RetornoAnual) as MelhorAno
    FROM RetornosAnuais
    WHERE RetornoAnual IS NOT NULL
    GROUP BY Symbol, CompanyNameEnglish
)
SELECT TOP 30
    Symbol,
    CompanyNameEnglish as Empresa,
    AnosComDados,
    AnosPositivos,
    CAST((CAST(AnosPositivos as FLOAT) / AnosComDados * 100) as DECIMAL(10, 2)) as TaxaSucessoPct,
    CAST(RetornoMedioAnual as DECIMAL(10, 2)) as RetornoMedioAnual_Pct,
    CAST(VolatilidadeRetornos as DECIMAL(10, 2)) as VolatilidadeRetornos_Pct,
    CAST(PiorAno as DECIMAL(10, 2)) as PiorAno_Pct,
    CAST(MelhorAno as DECIMAL(10, 2)) as MelhorAno_Pct,
    CASE
        WHEN VolatilidadeRetornos > 0
        THEN CAST((RetornoMedioAnual / VolatilidadeRetornos) as DECIMAL(10, 4))
        ELSE NULL
    END as SharpeRatioSimplificado
FROM Consistencia
WHERE AnosComDados >= 3
  AND AnosPositivos >= 2
ORDER BY TaxaSucessoPct DESC, RetornoMedioAnual DESC;
GO

-- =============================================
-- PERGUNTA 5: Quais setores apresentam melhor desempenho médio no índice S&P 500?
-- =============================================
PRINT ''
PRINT '============================================='
PRINT 'PERGUNTA 5: Melhor Desempenho por Setor (S&P 500)'
PRINT '============================================='
GO

-- Nota: Como não temos dados históricos de preços para empresas S&P 500,
-- vamos analisar a distribuição de empresas por setor e correlação com o índice

SELECT
    e.GICSSector as Setor,
    COUNT(*) as QtdEmpresas,
    MIN(e.DateAdded) as PrimeiraAdicao,
    MAX(e.DateAdded) as UltimaAdicao,
    AVG(YEAR(GETDATE()) - e.Founded) as IdadeMediaAnos,
    COUNT(CASE WHEN e.DateAdded >= DATEADD(YEAR, -5, GETDATE()) THEN 1 END) as AdicionadasUltimos5Anos,
    CAST(
        (COUNT(CASE WHEN e.DateAdded >= DATEADD(YEAR, -5, GETDATE()) THEN 1 END) * 100.0 / COUNT(*))
        as DECIMAL(10, 2)
    ) as PctAdicionadasRecentemente
FROM dbo.Empresas e
WHERE e.GICSSector IS NOT NULL
GROUP BY e.GICSSector
ORDER BY QtdEmpresas DESC;
GO

-- Análise complementar: Evolução do índice S&P 500
PRINT ''
PRINT 'Evolução do Índice S&P 500 por Período:'
GO

WITH PeriodosIndice AS (
    SELECT
        YEAR(ObservationDate) as Ano,
        MIN(SP500Value) as MinimoAno,
        MAX(SP500Value) as MaximoAno,
        AVG(SP500Value) as MediaAno,
        FIRST_VALUE(SP500Value) OVER (PARTITION BY YEAR(ObservationDate) ORDER BY ObservationDate ASC) as AberturaAno,
        FIRST_VALUE(SP500Value) OVER (PARTITION BY YEAR(ObservationDate) ORDER BY ObservationDate DESC) as FechamentoAno
    FROM dbo.IndiceSP500
    GROUP BY YEAR(ObservationDate), ObservationDate, SP500Value
)
SELECT DISTINCT
    Ano,
    CAST(AberturaAno as DECIMAL(10, 2)) as Abertura,
    CAST(FechamentoAno as DECIMAL(10, 2)) as Fechamento,
    CAST(MediaAno as DECIMAL(10, 2)) as Media,
    CAST(MinimoAno as DECIMAL(10, 2)) as Minimo,
    CAST(MaximoAno as DECIMAL(10, 2)) as Maximo,
    CAST(((FechamentoAno - AberturaAno) / AberturaAno * 100) as DECIMAL(10, 2)) as RetornoAnual_Pct,
    CAST(((MaximoAno - MinimoAno) / AberturaAno * 100) as DECIMAL(10, 2)) as AmplitudeAnual_Pct
FROM PeriodosIndice
ORDER BY Ano DESC;
GO

-- =============================================
-- PERGUNTA 6: Quais ações sofreram maior queda em períodos de crise econômica? (COVID)
-- =============================================
PRINT ''
PRINT '============================================='
PRINT 'PERGUNTA 6: Maior Queda Durante Crise COVID (2020)'
PRINT '============================================='
GO

DECLARE @InicioPreCovid DATE = '2020-01-01'
DECLARE @FimCovid DATE = '2020-04-30'

WITH PrecosPeriodo AS (
    SELECT
        Symbol,
        CompanyNameEnglish,
        Industry,
        MAX(CASE WHEN TradeDate BETWEEN @InicioPreCovid AND DATEADD(DAY, 30, @InicioPreCovid) THEN ClosePrice END) as PrecoPreCovid,
        MIN(CASE WHEN TradeDate BETWEEN @InicioPreCovid AND @FimCovid THEN ClosePrice END) as PrecoMinimoCovid,
        MAX(CASE WHEN TradeDate BETWEEN @InicioPreCovid AND @FimCovid THEN ClosePrice END) as PrecoMaximoCovid,
        MIN(CASE WHEN TradeDate BETWEEN @InicioPreCovid AND @FimCovid THEN TradeDate END) as DataMinimo
    FROM dbo.AcoesChinesas
    WHERE TradeDate BETWEEN @InicioPreCovid AND @FimCovid
      AND ClosePrice IS NOT NULL
    GROUP BY Symbol, CompanyNameEnglish, Industry
)
SELECT TOP 30
    Symbol,
    CompanyNameEnglish as Empresa,
    Industry as Industria,
    CAST(PrecoPreCovid as DECIMAL(10, 4)) as PrecoInicial,
    CAST(PrecoMinimoCovid as DECIMAL(10, 4)) as PrecoMinimo,
    DataMinimo as DataMinimoAtingido,
    CAST(((PrecoMinimoCovid - PrecoPreCovid) / PrecoPreCovid * 100) as DECIMAL(10, 2)) as QuedaPercentual,
    CAST((PrecoPreCovid - PrecoMinimoCovid) as DECIMAL(10, 4)) as QuedaAbsoluta,
    CAST(((PrecoMaximoCovid - PrecoMinimoCovid) / PrecoMinimoCovid * 100) as DECIMAL(10, 2)) as RecuperacaoNoPeriodo_Pct
FROM PrecosPeriodo
WHERE PrecoPreCovid IS NOT NULL
  AND PrecoMinimoCovid IS NOT NULL
  AND PrecoPreCovid > 0
ORDER BY QuedaPercentual ASC;
GO

-- =============================================
-- PERGUNTA 7: Qual é o retorno médio de dividendos por setor e por empresa?
-- =============================================
PRINT ''
PRINT '============================================='
PRINT 'PERGUNTA 7: Análise de Dividendos'
PRINT '============================================='
PRINT ''
PRINT 'NOTA: Os datasets disponíveis (CSI500 e S&P 500) não contêm'
PRINT 'informações específicas sobre dividendos pagos.'
PRINT ''
PRINT 'Para análise de dividendos, seria necessário um dataset adicional'
PRINT 'contendo histórico de pagamentos de dividendos por empresa.'
PRINT ''
PRINT 'Alternativas de análise:'
PRINT '1. Adicionar dataset com histórico de dividendos'
PRINT '2. Usar APIs financeiras (Yahoo Finance, Alpha Vantage, etc.)'
PRINT '3. Importar dados de relatórios corporativos'
GO

-- Análise alternativa: Empresas por setor (base para futura análise de dividendos)
PRINT ''
PRINT 'Empresas S&P 500 por Setor (base para análise futura):'
GO

SELECT
    e.GICSSector as Setor,
    e.GICSSubIndustry as SubIndustria,
    COUNT(*) as QtdEmpresas,
    STRING_AGG(e.Symbol, ', ') as Symbols
FROM dbo.Empresas e
WHERE e.GICSSector IS NOT NULL
  AND e.GICSSubIndustry IS NOT NULL
GROUP BY e.GICSSector, e.GICSSubIndustry
ORDER BY e.GICSSector, QtdEmpresas DESC;
GO

-- =============================================
-- RESUMO EXECUTIVO
-- =============================================
PRINT ''
PRINT '============================================='
PRINT 'RESUMO EXECUTIVO DAS ANÁLISES'
PRINT '============================================='
GO

SELECT
    'Total de Empresas S&P 500' as Metrica,
    CAST(COUNT(*) as VARCHAR(20)) as Valor
FROM dbo.Empresas
UNION ALL
SELECT
    'Total de Observações Índice S&P 500',
    CAST(COUNT(*) as VARCHAR(20))
FROM dbo.IndiceSP500
UNION ALL
SELECT
    'Total de Ações Chinesas (CSI500)',
    CAST(COUNT(DISTINCT Symbol) as VARCHAR(20))
FROM dbo.AcoesChinesas
UNION ALL
SELECT
    'Total de Observações CSI500',
    CAST(COUNT(*) as VARCHAR(20))
FROM dbo.AcoesChinesas
UNION ALL
SELECT
    'Período Índice S&P 500',
    CAST(MIN(ObservationDate) as VARCHAR(20)) + ' a ' + CAST(MAX(ObservationDate) as VARCHAR(20))
FROM dbo.IndiceSP500
UNION ALL
SELECT
    'Período Ações CSI500',
    CAST(MIN(TradeDate) as VARCHAR(20)) + ' a ' + CAST(MAX(TradeDate) as VARCHAR(20))
FROM dbo.AcoesChinesas
GO

PRINT ''
PRINT '============================================='
PRINT 'ANÁLISES CONCLUÍDAS COM SUCESSO!'
PRINT '============================================='
GO
