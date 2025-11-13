use FinanceDB
SELECT
    'DATASETS' as Origem,
    'SP500_data' as Tabela,
    COUNT(*) as TotalRegistros
FROM datasets.dbo.SP500

UNION ALL

SELECT 'DATASETS', 'CSI500', COUNT(*)
FROM datasets.dbo.CSI500

UNION ALL

SELECT 'FINANCEDB', 'Empresas', COUNT(*)
FROM FinanceDB.dbo.Empresas

UNION ALL

SELECT 'FINANCEDB', 'SubSetor', COUNT(*)
FROM FinanceDB.dbo.SubSetor

UNION ALL

SELECT 'FINANCEDB', 'Localizacao', COUNT(*)
FROM FinanceDB.dbo.Localizacao

UNION ALL

SELECT 'FINANCEDB', 'SP500Historico', COUNT(*)
FROM FinanceDB.dbo.SP500Historico

UNION ALL

SELECT 'FINANCEDB', 'Tempo', COUNT(*)
FROM FinanceDB.dbo.Tempo

UNION ALL

SELECT 'FINANCEDB', 'PrecoAcao', COUNT(*)
FROM FinanceDB.dbo.PrecoAcao

UNION ALL

SELECT 'FINANCEDB', 'Dividendos', COUNT(*)
FROM FinanceDB.dbo.Dividendos

ORDER BY Origem, Tabela;


USE FinanceDB;
GO


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

SELECT TOP 10
    IdSP500,
    DataReferencia,
    ValorFechamento,
    ValorAbertura,
    ValorMaximo,
    ValorMinimo,
    VolumeNegociado
FROM SP500Historico
ORDER BY DataReferencia DESC;
GO


SELECT TOP 10
    IdTempo,
    DataCompleta,
    Ano,
    Mes,
    Dia,
    Trimestre,
    DiaSemana,
    NomeDiaSemana,
    NomeMes
FROM Tempo
ORDER BY DataCompleta DESC;
GO

SELECT TOP 10
    p.IdPrecoAcao,
    e.Ticker,
    e.NomeEmpresa,
    t.DataCompleta,
    p.PrecoFechamento,
    p.Volume,
    p.VariacaoPercentual
FROM PrecoAcao p
INNER JOIN Empresas e ON p.CIK = e.CIK
INNER JOIN Tempo t ON p.IdTempo = t.IdTempo
ORDER BY t.DataCompleta DESC;
GO


SELECT TOP 10
    d.IdDividendo,
    e.Ticker,
    e.NomeEmpresa,
    t.DataCompleta,
    d.ValorDividendo,
    d.TipoDividendo,
    d.DataExDividendo
FROM Dividendos d
INNER JOIN Empresas e ON d.CIK = e.CIK
INNER JOIN Tempo t ON d.IdTempo = t.IdTempo
ORDER BY d.ValorDividendo DESC;
GO

USE datasets;
GO

SELECT TOP 5
    id,
    symbol,
    company_name,
    sector,
    observation_date,
    close_price AS stock_price,
    volume
FROM SP500
ORDER BY id;
GO


SELECT TOP 5
    codigo_empresa,
    [date],
    [close],
    volume,
    nome_empresa_en,
    industry_en
FROM CSI500
ORDER BY [date] DESC;
GO


USE FinanceDB;
GO



SELECT
    Setor,
    COUNT(*) as TotalEmpresas
FROM Empresas
WHERE Setor IS NOT NULL
GROUP BY Setor
ORDER BY TotalEmpresas DESC;
GO


SELECT TOP 10
    l.Estado,
    COUNT(*) as TotalEmpresas
FROM Localizacao l
WHERE l.Estado IS NOT NULL
GROUP BY l.Estado
ORDER BY TotalEmpresas DESC;
GO

SELECT
    'S&P 500 Data' as Fonte,
    MIN(observation_date) as DataInicio,
    MAX(observation_date) as DataFim,
    COUNT(DISTINCT observation_date) as TotalDias,
    COUNT(DISTINCT symbol) as TotalEmpresas
FROM datasets.dbo.SP500;
GO

SELECT
    'CSI 500' as Fonte,
    MIN([date]) as DataInicio,
    MAX([date]) as DataFim,
    COUNT(DISTINCT [date]) as TotalDias,
    COUNT(DISTINCT codigo_empresa) as TotalEmpresas
FROM datasets.dbo.CSI500;
GO