-- =============================================
-- Script: Consultas de Exemplo - 7 Perguntas Analíticas
-- Descrição: Queries prontas para responder cada pergunta
-- Autor: Sistema de Análise Financeira
-- Data: 2025-11-08
-- =============================================
-- Prerequisito: Execute primeiro 04_criar_views_7_perguntas.sql
-- =============================================

USE datasets;
GO

PRINT '========================================';
PRINT 'RESPOSTAS PARA AS 7 PERGUNTAS ANALÍTICAS';
PRINT '========================================';
PRINT '';
GO

-- =============================================
-- PERGUNTA 1: Quais ações tiveram maior valorização percentual no último ano?
-- =============================================
PRINT '========================================';
PRINT 'PERGUNTA 1: MAIOR VALORIZAÇÃO NO ÚLTIMO ANO';
PRINT '========================================';
PRINT '';
GO

-- Top 20 ações com maior valorização
SELECT TOP 20
    Symbol,
    Empresa,
    Industria,
    DataInicial,
    PrecoInicial,
    DataFinal,
    PrecoFinal,
    ValorizacaoPercentual,
    CategoriaDesempenho
FROM dbo.vw_P1_MaiorValorizacaoUltimoAno
ORDER BY ValorizacaoPercentual DESC;
GO

-- Resumo estatístico por categoria
PRINT 'Resumo por Categoria de Desempenho:';
SELECT
    CategoriaDesempenho,
    COUNT(*) as QtdEmpresas,
    CAST(AVG(ValorizacaoPercentual) as DECIMAL(10, 2)) as MediaValorizacao,
    CAST(MIN(ValorizacaoPercentual) as DECIMAL(10, 2)) as MinimaValorizacao,
    CAST(MAX(ValorizacaoPercentual) as DECIMAL(10, 2)) as MaximaValorizacao
FROM dbo.vw_P1_MaiorValorizacaoUltimoAno
GROUP BY CategoriaDesempenho
ORDER BY MediaValorizacao DESC;
GO

PRINT '';
GO

-- =============================================
-- PERGUNTA 2: Qual é a volatilidade média das ações por setor ou indústria?
-- =============================================
PRINT '========================================';
PRINT 'PERGUNTA 2: VOLATILIDADE POR INDÚSTRIA';
PRINT '========================================';
PRINT '';
GO

-- Top 15 indústrias mais voláteis
SELECT TOP 15
    Industria,
    QtdEmpresas,
    QtdObservacoes,
    RetornoMedioDiario_Pct,
    VolatilidadeDiaria_Pct,
    VolatilidadeAnualizada_Pct,
    ClassificacaoVolatilidade
FROM dbo.vw_P2_VolatilidadePorIndustria
ORDER BY VolatilidadeAnualizada_Pct DESC;
GO

-- Comparação: Indústrias mais e menos voláteis
PRINT 'Comparação: Mais Voláteis vs Menos Voláteis:';
;WITH MaisVolateis AS (
    SELECT TOP 5
        'Mais Volátil' as Tipo,
        Industria,
        VolatilidadeAnualizada_Pct,
        RetornoMedioDiario_Pct
    FROM dbo.vw_P2_VolatilidadePorIndustria
    ORDER BY VolatilidadeAnualizada_Pct DESC
),
MenosVolateis AS (
    SELECT TOP 5
        'Menos Volátil' as Tipo,
        Industria,
        VolatilidadeAnualizada_Pct,
        RetornoMedioDiario_Pct
    FROM dbo.vw_P2_VolatilidadePorIndustria
    WHERE QtdEmpresas >= 3
    ORDER BY VolatilidadeAnualizada_Pct ASC
)
SELECT *
FROM MaisVolateis
UNION ALL
SELECT *
FROM MenosVolateis
ORDER BY VolatilidadeAnualizada_Pct DESC;
GO

PRINT '';
GO

-- =============================================
-- PERGUNTA 3: Quais empresas registraram maior volume de negociação?
-- =============================================
PRINT '========================================';
PRINT 'PERGUNTA 3: MAIOR VOLUME DE NEGOCIAÇÃO';
PRINT '========================================';
PRINT '';
GO

-- Top 25 empresas por volume
SELECT TOP 25
    Symbol,
    Empresa,
    Industria,
    DiasNegociados,
    VolumeTotal,
    VolumeMediaDiaria,
    ValorFinanceiroTotal,
    TaxaGiroMedia_Pct,
    ClassificacaoLiquidez
FROM dbo.vw_P3_MaiorVolumeNegociacao
ORDER BY VolumeTotal DESC;
GO

-- Análise por indústria
PRINT 'Volume Total por Indústria:';
SELECT TOP 10
    Industria,
    COUNT(*) as QtdEmpresas,
    CAST(SUM(VolumeTotal) as DECIMAL(20, 0)) as VolumeAcumulado,
    CAST(AVG(VolumeMediaDiaria) as DECIMAL(20, 0)) as MediaVolumeEmpresa,
    CAST(AVG(TaxaGiroMedia_Pct) as DECIMAL(10, 4)) as MediaTaxaGiro
FROM dbo.vw_P3_MaiorVolumeNegociacao
WHERE Industria IS NOT NULL
GROUP BY Industria
ORDER BY VolumeAcumulado DESC;
GO

PRINT '';
GO

-- =============================================
-- PERGUNTA 4: Quais ações apresentaram crescimento consistente?
-- =============================================
PRINT '========================================';
PRINT 'PERGUNTA 4: CRESCIMENTO CONSISTENTE (5 ANOS)';
PRINT '========================================';
PRINT '';
GO

-- Top 30 ações mais consistentes
SELECT TOP 30
    Symbol,
    Empresa,
    Industria,
    AnosComDados,
    AnosPositivos,
    TaxaSucessoPct,
    RetornoMedioAnual_Pct,
    VolatilidadeRetornos_Pct,
    SharpeRatioSimplificado,
    ClassificacaoConsistencia
FROM dbo.vw_P4_CrescimentoConsistente5Anos
WHERE AnosComDados >= 4
ORDER BY TaxaSucessoPct DESC, RetornoMedioAnual_Pct DESC;
GO

-- Análise por classificação
PRINT 'Distribuição por Consistência:';
SELECT
    ClassificacaoConsistencia,
    COUNT(*) as QtdEmpresas,
    CAST(AVG(RetornoMedioAnual_Pct) as DECIMAL(10, 2)) as RetornoMedio,
    CAST(AVG(TaxaSucessoPct) as DECIMAL(10, 2)) as MediaTaxaSucesso,
    CAST(AVG(SharpeRatioSimplificado) as DECIMAL(10, 4)) as MediaSharpeRatio
FROM dbo.vw_P4_CrescimentoConsistente5Anos
GROUP BY ClassificacaoConsistencia
ORDER BY MediaTaxaSucesso DESC;
GO

PRINT '';
GO

-- =============================================
-- PERGUNTA 5: Quais setores apresentam melhor desempenho no S&P 500?
-- =============================================
PRINT '========================================';
PRINT 'PERGUNTA 5: DESEMPENHO DE SETORES (S&P 500)';
PRINT '========================================';
PRINT '';
GO

-- Análise completa por setor
SELECT
    Setor,
    QtdEmpresas,
    ParticipacaoPct,
    IdadeMediaAnos,
    AdicionadasUltimos5Anos,
    PctAdicionadasRecentemente,
    RetornoTotalIndiceSP500_Pct,
    ClassificacaoTamanho
FROM dbo.vw_P5_DesempenhoSetoresSP500
ORDER BY QtdEmpresas DESC;
GO

-- Setores em crescimento (mais adições recentes)
PRINT 'Setores em Crescimento (Mais Adições Recentes):';
SELECT TOP 5
    Setor,
    QtdEmpresas,
    AdicionadasUltimos5Anos,
    PctAdicionadasRecentemente,
    ClassificacaoTamanho
FROM dbo.vw_P5_DesempenhoSetoresSP500
ORDER BY PctAdicionadasRecentemente DESC;
GO

PRINT '';
GO

-- =============================================
-- PERGUNTA 6: Quais ações sofreram maior queda durante COVID?
-- =============================================
PRINT '========================================';
PRINT 'PERGUNTA 6: MAIOR QUEDA DURANTE CRISE COVID';
PRINT '========================================';
PRINT '';
GO

-- Top 30 ações mais afetadas
SELECT TOP 30
    Symbol,
    Empresa,
    Industria,
    PrecoPreCovid,
    PrecoMinimoCovid,
    DataMinimoAtingido,
    QuedaPercentual,
    RecuperacaoNoPeriodo_Pct,
    RecuperacaoTotal_Pct,
    ClassificacaoImpacto
FROM dbo.vw_P6_QuedaCriseCovid
ORDER BY QuedaPercentual ASC;
GO

-- Análise por indústria
PRINT 'Impacto COVID por Indústria:';
SELECT
    Industria,
    COUNT(*) as QtdEmpresas,
    CAST(AVG(QuedaPercentual) as DECIMAL(10, 2)) as MediaQueda,
    CAST(MIN(QuedaPercentual) as DECIMAL(10, 2)) as MaiorQueda,
    CAST(AVG(RecuperacaoTotal_Pct) as DECIMAL(10, 2)) as MediaRecuperacao,
    COUNT(CASE WHEN ClassificacaoImpacto = 'Resiliente' THEN 1 END) as EmpresasResilientes,
    COUNT(CASE WHEN ClassificacaoImpacto = 'Impacto Severo' THEN 1 END) as EmpresasImpactoSevero
FROM dbo.vw_P6_QuedaCriseCovid
WHERE Industria IS NOT NULL
GROUP BY Industria
ORDER BY MediaQueda ASC;
GO

-- Empresas resilientes vs severamente impactadas
PRINT 'Comparação: Resilientes vs Impacto Severo:';
SELECT
    ClassificacaoImpacto,
    COUNT(*) as QtdEmpresas,
    CAST(AVG(QuedaPercentual) as DECIMAL(10, 2)) as MediaQueda,
    CAST(AVG(RecuperacaoTotal_Pct) as DECIMAL(10, 2)) as MediaRecuperacao
FROM dbo.vw_P6_QuedaCriseCovid
WHERE ClassificacaoImpacto IN ('Resiliente', 'Impacto Severo')
GROUP BY ClassificacaoImpacto
ORDER BY ClassificacaoImpacto;
GO

PRINT '';
GO

-- =============================================
-- PERGUNTA 7: Qual é o retorno médio de dividendos?
-- =============================================
PRINT '========================================';
PRINT 'PERGUNTA 7: ANÁLISE DE DIVIDENDOS';
PRINT '========================================';
PRINT '';
PRINT 'NOTA: Dados de dividendos não disponíveis no dataset atual.';
PRINT 'Mostrando base de empresas para futura análise.';
PRINT '';
GO

-- Empresas por setor (base para análise futura)
SELECT TOP 20
    Symbol,
    NomeEmpresa,
    Setor,
    SubIndustria,
    AnoFundacao,
    IdadeEmpresa,
    TendenciaDividendos
FROM dbo.vw_P7_DadosBaseParaDividendos
WHERE EstaNoSP500 = 1
ORDER BY IdadeEmpresa DESC;
GO

-- Distribuição por setor e tendência de dividendos
PRINT 'Setores e Tendência de Pagamento de Dividendos:';
SELECT
    Setor,
    TendenciaDividendos,
    COUNT(*) as QtdEmpresas,
    CAST(AVG(CAST(IdadeEmpresa as FLOAT)) as DECIMAL(10, 1)) as IdadeMediaAnos
FROM dbo.vw_P7_DadosBaseParaDividendos
WHERE Setor IS NOT NULL
GROUP BY Setor, TendenciaDividendos
ORDER BY TendenciaDividendos, QtdEmpresas DESC;
GO

PRINT '';
PRINT 'Para análise completa de dividendos, considere:';
PRINT '  1. Importar dados de Yahoo Finance API';
PRINT '  2. Usar Alpha Vantage API';
PRINT '  3. Importar relatórios corporativos (10-K, 10-Q)';
PRINT '  4. Usar plataformas como Bloomberg ou Reuters';
GO

-- =============================================
-- RESUMO EXECUTIVO FINAL
-- =============================================
PRINT '';
PRINT '========================================';
PRINT 'RESUMO EXECUTIVO - PRINCIPAIS INSIGHTS';
PRINT '========================================';
PRINT '';
GO

-- Insight 1: Melhor valorização
PRINT '1. AÇÃO COM MELHOR VALORIZAÇÃO:';
SELECT TOP 1
    Symbol + ' (' + Empresa + ')' as Acao,
    CAST(ValorizacaoPercentual as VARCHAR(20)) + '%' as Valorizacao,
    Industria
FROM dbo.vw_P1_MaiorValorizacaoUltimoAno
ORDER BY ValorizacaoPercentual DESC;
GO

-- Insight 2: Indústria mais volátil
PRINT '2. INDÚSTRIA MAIS VOLÁTIL:';
SELECT TOP 1
    Industria,
    CAST(VolatilidadeAnualizada_Pct as VARCHAR(20)) + '%' as Volatilidade,
    QtdEmpresas
FROM dbo.vw_P2_VolatilidadePorIndustria
ORDER BY VolatilidadeAnualizada_Pct DESC;
GO

-- Insight 3: Empresa mais negociada
PRINT '3. EMPRESA MAIS NEGOCIADA:';
SELECT TOP 1
    Symbol + ' (' + Empresa + ')' as Empresa,
    VolumeTotal as Volume,
    ClassificacaoLiquidez
FROM dbo.vw_P3_MaiorVolumeNegociacao
ORDER BY VolumeTotal DESC;
GO

-- Insight 4: Ação mais consistente
PRINT '4. AÇÃO MAIS CONSISTENTE:';
SELECT TOP 1
    Symbol + ' (' + Empresa + ')' as Acao,
    CAST(TaxaSucessoPct as VARCHAR(20)) + '%' as TaxaSucesso,
    CAST(RetornoMedioAnual_Pct as VARCHAR(20)) + '%' as RetornoMedio
FROM dbo.vw_P4_CrescimentoConsistente5Anos
WHERE AnosComDados >= 4
ORDER BY TaxaSucessoPct DESC, RetornoMedioAnual_Pct DESC;
GO

-- Insight 5: Setor dominante no S&P 500
PRINT '5. SETOR DOMINANTE NO S&P 500:';
SELECT TOP 1
    Setor,
    QtdEmpresas,
    CAST(ParticipacaoPct as VARCHAR(20)) + '%' as Participacao
FROM dbo.vw_P5_DesempenhoSetoresSP500
ORDER BY QtdEmpresas DESC;
GO

-- Insight 6: Ação mais afetada pelo COVID
PRINT '6. AÇÃO MAIS AFETADA PELO COVID:';
SELECT TOP 1
    Symbol + ' (' + Empresa + ')' as Acao,
    CAST(QuedaPercentual as VARCHAR(20)) + '%' as Queda,
    CAST(RecuperacaoTotal_Pct as VARCHAR(20)) + '%' as Recuperacao
FROM dbo.vw_P6_QuedaCriseCovid
ORDER BY QuedaPercentual ASC;
GO

PRINT '';
PRINT '========================================';
PRINT '✅ ANÁLISE COMPLETA FINALIZADA!';
PRINT '========================================';
PRINT '';
PRINT 'Todas as 7 perguntas foram respondidas.';
PRINT 'Use as views criadas para análises personalizadas.';
PRINT '========================================';
GO
