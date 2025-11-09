-- =============================================
-- Script: Análise Completa - Execução Automática
-- Descrição: Executa todos os passos de análise de forma automatizada
-- Autor: Sistema de Análise Financeira
-- Data: 2025-11-07
-- =============================================

PRINT '============================================='
PRINT 'INICIANDO ANÁLISE COMPLETA DO MERCADO'
PRINT '============================================='
PRINT ''
PRINT 'Data/Hora Início: ' + CONVERT(VARCHAR(20), GETDATE(), 120)
PRINT ''
GO

-- =============================================
-- PASSO 1: Criar Tabelas Normalizadas
-- =============================================
PRINT ''
PRINT '>>> PASSO 1/3: Criando Tabelas Normalizadas...'
PRINT ''
GO

-- Incluir o script de criação de tabelas
:r 01_criar_tabelas_normalizadas.sql
GO

-- =============================================
-- PASSO 2: Executar Queries de Análise
-- =============================================
PRINT ''
PRINT '>>> PASSO 2/3: Executando Queries de Análise...'
PRINT ''
GO

-- Incluir o script de queries
:r 02_queries_analise.sql
GO

-- =============================================
-- PASSO 3: Criar Views para Análises Rápidas
-- =============================================
PRINT ''
PRINT '>>> PASSO 3/3: Criando Views para Consultas Rápidas...'
PRINT ''
GO

USE datasets
GO

-------------------------------------------------
-- View: Empresas S&P 500 com Resumo
-------------------------------------------------
IF OBJECT_ID('vw_EmpresasSP500Resumo', 'V') IS NOT NULL DROP VIEW vw_EmpresasSP500Resumo;
GO

CREATE VIEW vw_EmpresasSP500Resumo AS
SELECT
    e.Symbol,
    e.Security              AS NomeEmpresa,
    e.GICSSector            AS Setor,
    e.GICSSubIndustry       AS SubIndustria,
    e.HeadquartersLocation  AS Sede,
    e.DateAdded             AS DataAdicaoIndice,
    e.Founded               AS AnoFundacao,
    CASE
        WHEN e.Founded IS NOT NULL THEN YEAR(GETDATE()) - e.Founded
        ELSE NULL
    END                     AS IdadeAnos,
    CASE
        WHEN e.DateAdded IS NOT NULL THEN DATEDIFF(DAY, e.DateAdded, GETDATE())
        ELSE NULL
    END                     AS DiasNoIndice,
    e.CIK
FROM dbo.Empresas e;
GO

PRINT 'View criada: vw_EmpresasSP500Resumo'
GO

-------------------------------------------------
-- View: Índice S&P 500 com Métricas Diárias
-------------------------------------------------
IF OBJECT_ID('vw_IndiceSP500Metricas', 'V') IS NOT NULL DROP VIEW vw_IndiceSP500Metricas;
GO

CREATE VIEW vw_IndiceSP500Metricas AS
SELECT
    i.ObservationDate AS Data,
    i.SP500Value      AS Valor,
    LAG(i.SP500Value) OVER (ORDER BY i.ObservationDate) AS ValorDiaAnterior,
    (i.SP500Value - LAG(i.SP500Value) OVER (ORDER BY i.ObservationDate)) AS VariacaoAbsoluta,
    CASE
        WHEN LAG(i.SP500Value) OVER (ORDER BY i.ObservationDate) > 0
        THEN ((i.SP500Value - LAG(i.SP500Value) OVER (ORDER BY i.ObservationDate)) /
              LAG(i.SP500Value) OVER (ORDER BY i.ObservationDate) * 100)
        ELSE NULL
    END AS VariacaoPercentual,
    YEAR(i.ObservationDate)              AS Ano,
    MONTH(i.ObservationDate)             AS Mes,
    DATENAME(WEEKDAY, i.ObservationDate) AS DiaSemana
FROM dbo.IndiceSP500 i;
GO

PRINT 'View criada: vw_IndiceSP500Metricas'
GO

-------------------------------------------------
-- View: Ações Chinesas com Indicadores Diários
-------------------------------------------------
IF OBJECT_ID('vw_AcoesChinesasIndicadores', 'V') IS NOT NULL DROP VIEW vw_AcoesChinesasIndicadores;
GO

CREATE VIEW vw_AcoesChinesasIndicadores AS
SELECT
    a.Symbol,
    a.CompanyNameEnglish           AS Empresa,
    a.Industry                     AS Industria,
    a.TradeDate                    AS Data,
    a.OpenPrice                    AS Abertura,
    a.HighPrice                    AS Maxima,
    a.LowPrice                     AS Minima,
    a.ClosePrice                   AS Fechamento,
    a.Volume,
    a.Amount                       AS ValorFinanceiro,
    a.TurnoverRate                 AS TaxaGiro,
    (a.HighPrice - a.LowPrice)     AS AmplitudeDiaria,
    CASE
        WHEN a.OpenPrice > 0
        THEN ((a.ClosePrice - a.OpenPrice) / a.OpenPrice * 100)
        ELSE NULL
    END                            AS VariacaoDiaria_Pct,
    CASE
        WHEN a.LowPrice > 0
        THEN ((a.HighPrice - a.LowPrice) / a.LowPrice * 100)
        ELSE NULL
    END                            AS AmplitudePercentual,
    LAG(a.ClosePrice) OVER (PARTITION BY a.Symbol ORDER BY a.TradeDate) AS FechamentoAnterior,
    YEAR(a.TradeDate)              AS Ano,
    MONTH(a.TradeDate)             AS Mes,
    DATEPART(QUARTER, a.TradeDate) AS Trimestre
FROM dbo.AcoesChinesas a
WHERE a.ClosePrice IS NOT NULL;
GO

PRINT 'View criada: vw_AcoesChinesasIndicadores'
GO

-------------------------------------------------
-- View: Top Performers (últimos 30 pregões)
-------------------------------------------------
IF OBJECT_ID('vw_TopPerformers30d', 'V') IS NOT NULL DROP VIEW vw_TopPerformers30d;
GO

CREATE VIEW vw_TopPerformers30d AS
WITH UltimosDias AS (
    SELECT TOP 30 TradeDate
    FROM dbo.AcoesChinesas
    WHERE TradeDate IS NOT NULL
    GROUP BY TradeDate
    ORDER BY TradeDate DESC
),
Dados AS (
    SELECT
        a.Symbol,
        a.CompanyNameEnglish,
        a.Industry,
        a.TradeDate,
        a.ClosePrice,
        ROW_NUMBER() OVER (PARTITION BY a.Symbol ORDER BY a.TradeDate ASC)  AS rn_asc,
        ROW_NUMBER() OVER (PARTITION BY a.Symbol ORDER BY a.TradeDate DESC) AS rn_desc
    FROM dbo.AcoesChinesas a
    INNER JOIN UltimosDias ud
        ON a.TradeDate = ud.TradeDate
    WHERE a.ClosePrice IS NOT NULL
),
PrecoInicial AS (
    SELECT
        Symbol,
        CompanyNameEnglish,
        Industry,
        TradeDate  AS DataInicial,
        ClosePrice AS PrecoInicial
    FROM Dados
    WHERE rn_asc = 1
),
PrecoFinal AS (
    SELECT
        Symbol,
        TradeDate  AS DataFinal,
        ClosePrice AS PrecoFinal
    FROM Dados
    WHERE rn_desc = 1
)
SELECT
    pi.Symbol,
    pi.CompanyNameEnglish AS Empresa,
    pi.Industry           AS Industria,
    pi.DataInicial,
    pf.DataFinal,
    pi.PrecoInicial,
    pf.PrecoFinal,
    (pf.PrecoFinal - pi.PrecoInicial) AS Variacao,
    CASE
        WHEN pi.PrecoInicial > 0
        THEN ((pf.PrecoFinal - pi.PrecoInicial) / pi.PrecoInicial * 100)
        ELSE NULL
    END AS VariacaoPercentual
FROM PrecoInicial pi
INNER JOIN PrecoFinal pf
    ON pi.Symbol = pf.Symbol
WHERE pi.PrecoInicial IS NOT NULL
  AND pf.PrecoFinal  IS NOT NULL;
GO

PRINT 'View criada: vw_TopPerformers30d'
GO

-------------------------------------------------
-- View: Resumo por Setor (S&P 500)
-------------------------------------------------
IF OBJECT_ID('vw_ResumoSetoresSP500', 'V') IS NOT NULL DROP VIEW vw_ResumoSetoresSP500;
GO

CREATE VIEW vw_ResumoSetoresSP500 AS
SELECT
    GICSSector AS Setor,
    COUNT(*)   AS QtdEmpresas,
    MIN(DateAdded) AS PrimeiraEmpresa,
    MAX(DateAdded) AS UltimaEmpresa,
    AVG(CAST(YEAR(GETDATE()) - Founded AS FLOAT)) AS IdadeMedia,
    COUNT(CASE WHEN DateAdded >= DATEADD(YEAR, -5, GETDATE()) THEN 1 END) AS AdicionadasUltimos5Anos
FROM dbo.Empresas
WHERE GICSSector IS NOT NULL
GROUP BY GICSSector;
GO

PRINT 'View criada: vw_ResumoSetoresSP500'
GO

-------------------------------------------------
-- View: Resumo por Indústria (CSI500 / Ações Chinesas)
-------------------------------------------------
IF OBJECT_ID('vw_ResumoIndustriasCSI500', 'V') IS NOT NULL DROP VIEW vw_ResumoIndustriasCSI500;
GO

CREATE VIEW vw_ResumoIndustriasCSI500 AS
SELECT
    Industry                  AS Industria,
    COUNT(DISTINCT Symbol)    AS QtdEmpresas,
    COUNT(*)                  AS QtdObservacoes,
    MIN(TradeDate)            AS PrimeiraObservacao,
    MAX(TradeDate)            AS UltimaObservacao,
    AVG(ClosePrice)           AS PrecoMedio,
    SUM(Volume)               AS VolumeTotal,
    SUM(Amount)               AS ValorFinanceiroTotal,
    AVG(TurnoverRate)         AS TaxaGiroMedia
FROM dbo.AcoesChinesas
WHERE Industry   IS NOT NULL
  AND ClosePrice IS NOT NULL
GROUP BY Industry;
GO

PRINT 'View criada: vw_ResumoIndustriasCSI500'
GO

-- =============================================
-- VERIFICAÇÃO FINAL E TESTES
-- =============================================
PRINT ''
PRINT '============================================='
PRINT 'VERIFICANDO VIEWS CRIADAS'
PRINT '============================================='
GO

SELECT
    TABLE_NAME AS NomeView,
    'View'     AS Tipo
FROM INFORMATION_SCHEMA.VIEWS
WHERE TABLE_SCHEMA = 'dbo'
  AND TABLE_NAME LIKE 'vw_%'
ORDER BY TABLE_NAME;
GO

PRINT ''
PRINT '============================================='
PRINT 'TESTANDO VIEWS'
PRINT '============================================='
GO

PRINT ''
PRINT '>>> View: vw_EmpresasSP500Resumo (Top 5)'
SELECT TOP 5 * FROM vw_EmpresasSP500Resumo ORDER BY Symbol;
GO

PRINT ''
PRINT '>>> View: vw_IndiceSP500Metricas (Últimos 5 dias)'
SELECT TOP 5 * FROM vw_IndiceSP500Metricas ORDER BY Data DESC;
GO

PRINT ''
PRINT '>>> View: vw_AcoesChinesasIndicadores (Últimos 5 registros)'
SELECT TOP 5 * FROM vw_AcoesChinesasIndicadores ORDER BY Data DESC, Symbol;
GO

PRINT ''
PRINT '>>> View: vw_TopPerformers30d (Top 10 Performers)'
SELECT TOP 10 * FROM vw_TopPerformers30d ORDER BY VariacaoPercentual DESC;
GO

PRINT ''
PRINT '>>> View: vw_ResumoSetoresSP500'
SELECT * FROM vw_ResumoSetoresSP500 ORDER BY QtdEmpresas DESC;
GO

PRINT ''
PRINT '>>> View: vw_ResumoIndustriasCSI500 (Top 10 por Volume)'
SELECT TOP 10 * FROM vw_ResumoIndustriasCSI500 ORDER BY VolumeTotal DESC;
GO

-- =============================================
-- ESTATÍSTICAS FINAIS
-- =============================================
PRINT ''
PRINT '============================================='
PRINT 'ESTATÍSTICAS FINAIS'
PRINT '============================================='
GO

DECLARE @TotalEmpresas      INT;
DECLARE @TotalObsIndice     INT;
DECLARE @TotalAcoesChinesas INT;
DECLARE @TotalObsAcoes      INT;
DECLARE @TotalViews         INT;

SELECT @TotalEmpresas      = COUNT(*)               FROM dbo.Empresas;
SELECT @TotalObsIndice     = COUNT(*)               FROM dbo.IndiceSP500;
SELECT @TotalAcoesChinesas = COUNT(DISTINCT Symbol) FROM dbo.AcoesChinesas;
SELECT @TotalObsAcoes      = COUNT(*)               FROM dbo.AcoesChinesas;
SELECT @TotalViews         = COUNT(*)
FROM INFORMATION_SCHEMA.VIEWS
WHERE TABLE_SCHEMA = 'dbo'
  AND TABLE_NAME LIKE 'vw_%';

PRINT ''
PRINT 'Resumo da Análise:'
PRINT '  - Empresas S&P 500: '           + CAST(@TotalEmpresas      AS VARCHAR(10));
PRINT '  - Observações Índice S&P 500: ' + CAST(@TotalObsIndice     AS VARCHAR(10));
PRINT '  - Ações Chinesas (CSI500): '   + CAST(@TotalAcoesChinesas AS VARCHAR(10));
PRINT '  - Observações CSI500: '        + CAST(@TotalObsAcoes      AS VARCHAR(10));
PRINT '  - Views Criadas: '             + CAST(@TotalViews         AS VARCHAR(10));
PRINT '';
GO

-- =============================================
-- CONCLUSÃO
-- =============================================
PRINT ''
PRINT '============================================='
PRINT 'ANÁLISE COMPLETA FINALIZADA COM SUCESSO!'
PRINT '============================================='
PRINT ''
PRINT 'Data/Hora Fim: ' + CONVERT(VARCHAR(20), GETDATE(), 120)
PRINT ''
PRINT 'Próximos passos:'
PRINT '  1. Consultar as views criadas para análises rápidas'
PRINT '  2. Exportar resultados para análise externa'
PRINT '  3. Criar dashboards e visualizações'
PRINT '  4. Configurar alertas e monitoramento'
PRINT ''
PRINT 'Views disponíveis:'
PRINT '  - vw_EmpresasSP500Resumo'
PRINT '  - vw_IndiceSP500Metricas'
PRINT '  - vw_AcoesChinesasIndicadores'
PRINT '  - vw_TopPerformers30d'
PRINT '  - vw_ResumoSetoresSP500'
PRINT '  - vw_ResumoIndustriasCSI500'
PRINT ''
PRINT '============================================='
GO
