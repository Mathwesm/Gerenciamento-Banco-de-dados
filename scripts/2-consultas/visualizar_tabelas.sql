-- ========================================
-- SCRIPT: VISUALIZAR DADOS DAS TABELAS
-- ========================================
-- Descrição: Mostra os dados de todas as tabelas do projeto
-- Use este script para verificar se os dados foram processados corretamente
-- ========================================

PRINT '========================================';
PRINT 'VISUALIZAÇÃO DE DADOS - TODAS AS TABELAS';
PRINT '========================================';
PRINT '';

-- ========================================
-- PARTE 1: RESUMO GERAL
-- ========================================

PRINT '========================================';
PRINT '1. RESUMO GERAL';
PRINT '========================================';
PRINT '';

-- Contagem de registros em todas as tabelas
SELECT
    'DATASETS' as Origem,
    'SP500_companies' as Tabela,
    COUNT(*) as TotalRegistros
FROM datasets.dbo.SP500_companies

UNION ALL

SELECT 'DATASETS', 'SP500_fred', COUNT(*)
FROM datasets.dbo.SP500_fred

UNION ALL

SELECT 'DATASETS', 'CSI500', COUNT(*)
FROM datasets.dbo.CSI500

UNION ALL

SELECT 'MASTER', 'Empresas', COUNT(*)
FROM master.dbo.Empresas

UNION ALL

SELECT 'MASTER', 'SubSetor', COUNT(*)
FROM master.dbo.SubSetor

UNION ALL

SELECT 'MASTER', 'Localizacao', COUNT(*)
FROM master.dbo.Localizacao

UNION ALL

SELECT 'MASTER', 'Indice', COUNT(*)
FROM master.dbo.Indice

UNION ALL

SELECT 'MASTER', 'IndiceSP500', COUNT(*)
FROM master.dbo.IndiceSP500

UNION ALL

SELECT 'MASTER', 'Tempo', COUNT(*)
FROM master.dbo.Tempo

UNION ALL

SELECT 'MASTER', 'PrecoAcao', COUNT(*)
FROM master.dbo.PrecoAcao

UNION ALL

SELECT 'MASTER', 'Dividendos', COUNT(*)
FROM master.dbo.Dividendos

ORDER BY Origem, Tabela;

PRINT '';
PRINT '========================================';
PRINT '2. TABELAS DO DATABASE MASTER';
PRINT '========================================';
PRINT '';

-- ========================================
-- TABELA: Empresas
-- ========================================
USE master;
GO

PRINT '--- EMPRESAS (Top 10) ---';
SELECT TOP 10
    CIK,
    NomeEmpresa,
    Ticker,
    Setor,
    DataEntrada,
    AnoFundacao
FROM Empresas
ORDER BY NomeEmpresa;
GO

PRINT '';
PRINT '--- SUBSETOR (Top 10) ---';
SELECT TOP 10
    s.IdSubSetor,
    e.Ticker,
    e.NomeEmpresa,
    s.Industria,
    s.SubIndustria,
    s.Categoria
FROM SubSetor s
INNER JOIN Empresas e ON s.CIK = e.CIK
ORDER BY e.NomeEmpresa;
GO

PRINT '';
PRINT '--- LOCALIZACAO (Top 10) ---';
SELECT TOP 10
    l.IdLocalizacao,
    e.Ticker,
    e.NomeEmpresa,
    l.Cidade,
    l.Estado,
    l.Pais,
    l.Regiao
FROM Localizacao l
INNER JOIN Empresas e ON l.CIK = e.CIK
ORDER BY e.NomeEmpresa;
GO

PRINT '';
PRINT '--- INDICE ---';
SELECT
    IdIndice,
    NomeIndice,
    Descricao,
    Simbolo,
    PaisOrigem,
    DataCriacao
FROM Indice;
GO

PRINT '';
PRINT '--- INDICE SP500 (Top 10 mais recentes) ---';
SELECT TOP 10
    i.IdIndiceSP500,
    ind.Simbolo,
    ind.NomeIndice,
    i.DataReferencia,
    i.ValorFechamento,
    i.ValorAbertura,
    i.ValorMaximo,
    i.ValorMinimo,
    i.VolumeNegociado
FROM IndiceSP500 i
INNER JOIN Indice ind ON i.IdIndice = ind.IdIndice
ORDER BY i.DataReferencia DESC;
GO

PRINT '';
PRINT '--- TEMPO (Top 10 mais recentes) ---';
SELECT TOP 10
    IdTempo,
    DataCompleta,
    Ano,
    Mes,
    Dia,
    Trimestre,
    Semestre,
    DiaSemana,
    NomeDiaSemana,
    NomeMes,
    EhFimDeSemana,
    EhFeriado
FROM Tempo
ORDER BY DataCompleta DESC;
GO

PRINT '';
PRINT '--- PRECO ACAO (Top 10) ---';
SELECT TOP 10
    p.IdPrecoAcao,
    e.Ticker,
    e.NomeEmpresa,
    t.DataCompleta,
    p.PrecoAbertura,
    p.PrecoMaximo,
    p.PrecoMinimo,
    p.PrecoFechamento,
    p.Volume,
    p.VariacaoPercentual
FROM PrecoAcao p
INNER JOIN Empresas e ON p.CIK = e.CIK
INNER JOIN Tempo t ON p.IdTempo = t.IdTempo
ORDER BY t.DataCompleta DESC;
GO

PRINT '';
PRINT '--- DIVIDENDOS (Top 10) ---';
SELECT TOP 10
    d.IdDividendo,
    e.Ticker,
    e.NomeEmpresa,
    t.DataCompleta,
    d.ValorDividendo,
    d.TipoDividendo,
    d.FrequenciaPagamento,
    d.DataExDividendo,
    d.DataPagamento
FROM Dividendos d
INNER JOIN Empresas e ON d.CIK = e.CIK
INNER JOIN Tempo t ON d.IdTempo = t.IdTempo
ORDER BY t.DataCompleta DESC;
GO

-- ========================================
-- PARTE 3: ANÁLISES RÁPIDAS
-- ========================================

PRINT '';
PRINT '========================================';
PRINT '3. ANÁLISES RÁPIDAS';
PRINT '========================================';
PRINT '';

-- Empresas por setor
PRINT '--- EMPRESAS POR SETOR ---';
SELECT
    Setor,
    COUNT(*) as TotalEmpresas
FROM Empresas
WHERE Setor IS NOT NULL
GROUP BY Setor
ORDER BY TotalEmpresas DESC;
GO

-- Empresas por estado
PRINT '';
PRINT '--- TOP 10 ESTADOS COM MAIS EMPRESAS ---';
SELECT TOP 10
    l.Estado,
    COUNT(*) as TotalEmpresas
FROM Localizacao l
WHERE l.Estado IS NOT NULL
GROUP BY l.Estado
ORDER BY TotalEmpresas DESC;
GO

-- Empresas mais antigas
PRINT '';
PRINT '--- TOP 10 EMPRESAS MAIS ANTIGAS ---';
SELECT TOP 10
    Ticker,
    NomeEmpresa,
    AnoFundacao,
    Setor
FROM Empresas
WHERE AnoFundacao IS NOT NULL
ORDER BY AnoFundacao ASC;
GO

-- Variação do índice S&P 500
PRINT '';
PRINT '--- VARIAÇÃO DO ÍNDICE S&P 500 (últimos 10 dias) ---';
SELECT TOP 10
    DataReferencia,
    ValorFechamento,
    LAG(ValorFechamento) OVER (ORDER BY DataReferencia) as ValorAnterior,
    ValorFechamento - LAG(ValorFechamento) OVER (ORDER BY DataReferencia) as Variacao,
    CASE
        WHEN LAG(ValorFechamento) OVER (ORDER BY DataReferencia) IS NOT NULL
        THEN CAST((ValorFechamento - LAG(ValorFechamento) OVER (ORDER BY DataReferencia)) /
                  LAG(ValorFechamento) OVER (ORDER BY DataReferencia) * 100 AS DECIMAL(10,2))
        ELSE NULL
    END as VariacaoPercentual
FROM IndiceSP500
ORDER BY DataReferencia DESC;
GO

-- Período de dados disponíveis
PRINT '';
PRINT '--- PERÍODO DE DADOS DISPONÍVEIS ---';
SELECT
    'Índice S&P 500' as Fonte,
    MIN(DataReferencia) as DataInicio,
    MAX(DataReferencia) as DataFim,
    DATEDIFF(DAY, MIN(DataReferencia), MAX(DataReferencia)) as TotalDias
FROM IndiceSP500

UNION ALL

SELECT
    'Dimensão Tempo',
    MIN(DataCompleta),
    MAX(DataCompleta),
    DATEDIFF(DAY, MIN(DataCompleta), MAX(DataCompleta))
FROM Tempo;
GO

-- ========================================
-- PARTE 4: VERIFICAÇÃO DE INTEGRIDADE
-- ========================================

PRINT '';
PRINT '========================================';
PRINT '4. VERIFICAÇÃO DE INTEGRIDADE';
PRINT '========================================';
PRINT '';

-- Empresas sem localização
PRINT '--- EMPRESAS SEM LOCALIZAÇÃO ---';
SELECT COUNT(*) as TotalSemLocalizacao
FROM Empresas e
WHERE NOT EXISTS (SELECT 1 FROM Localizacao l WHERE l.CIK = e.CIK);
GO

-- Empresas sem subsetor
PRINT '';
PRINT '--- EMPRESAS SEM SUBSETOR ---';
SELECT COUNT(*) as TotalSemSubsetor
FROM Empresas e
WHERE NOT EXISTS (SELECT 1 FROM SubSetor s WHERE s.CIK = e.CIK);
GO

-- Registros na dimensão Tempo
PRINT '';
PRINT '--- DIMENSÃO TEMPO - DISTRIBUIÇÃO POR ANO ---';
SELECT
    Ano,
    COUNT(*) as TotalDias,
    MIN(DataCompleta) as PrimeiraData,
    MAX(DataCompleta) as UltimaData
FROM Tempo
GROUP BY Ano
ORDER BY Ano DESC;
GO

-- ========================================
-- PARTE 5: DADOS BRUTOS (DATASETS)
-- ========================================

PRINT '';
PRINT '========================================';
PRINT '5. DADOS BRUTOS (DATABASE DATASETS)';
PRINT '========================================';
PRINT '';

USE datasets;
GO

PRINT '--- SP500_COMPANIES (Primeiros 5 registros brutos) ---';
SELECT TOP 5 registro
FROM SP500_companies;
GO

PRINT '';
PRINT '--- SP500_FRED (Primeiros 5 registros brutos) ---';
SELECT TOP 5 registro
FROM SP500_fred;
GO

PRINT '';
PRINT '--- CSI500 (Primeiros 5 registros brutos) ---';
SELECT TOP 5 registro
FROM CSI500;
GO

-- ========================================
-- FIM
-- ========================================

PRINT '';
PRINT '========================================';
PRINT '✅ VISUALIZAÇÃO COMPLETA FINALIZADA!';
PRINT '========================================';
PRINT '';
PRINT 'Resumo:';
PRINT '  ✓ Todas as tabelas foram consultadas';
PRINT '  ✓ Análises rápidas executadas';
PRINT '  ✓ Verificação de integridade realizada';
PRINT '';
PRINT 'Para análises mais detalhadas:';
PRINT '  - Crie suas próprias queries personalizadas';
PRINT '  - Use JOIN entre tabelas para análises cruzadas';
PRINT '  - Explore os relacionamentos entre as tabelas';
PRINT '';
PRINT '========================================';
GO
