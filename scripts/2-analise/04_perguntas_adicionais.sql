USE FinanceDB;
GO

-- PERGUNTA 1: Ações com crescimento consistente nos últimos 5 anos
WITH PrecosPorAno AS (
    SELECT
        e.CIK,
        e.Ticker,
        e.NomeEmpresa,
        e.Setor,
        YEAR(t.DataCompleta) AS Ano,
        AVG(p.PrecoFechamento) AS PrecoMedioAnual
    FROM PrecoAcao p
    INNER JOIN Empresas e ON p.CIK = e.CIK
    INNER JOIN Tempo t ON p.IdTempo = t.IdTempo
    WHERE p.PrecoFechamento IS NOT NULL
      AND t.DataCompleta >= DATEADD(YEAR, -5, (SELECT MAX(DataCompleta) FROM Tempo))
    GROUP BY e.CIK, e.Ticker, e.NomeEmpresa, e.Setor, YEAR(t.DataCompleta)
),
CrescimentoAnual AS (
    SELECT
        CIK,
        Ticker,
        NomeEmpresa,
        Setor,
        Ano,
        PrecoMedioAnual,
        LAG(PrecoMedioAnual) OVER (PARTITION BY CIK ORDER BY Ano) AS PrecoAnoAnterior,
        CASE
            WHEN LAG(PrecoMedioAnual) OVER (PARTITION BY CIK ORDER BY Ano) IS NOT NULL
            THEN ((PrecoMedioAnual - LAG(PrecoMedioAnual) OVER (PARTITION BY CIK ORDER BY Ano))
                  / NULLIF(LAG(PrecoMedioAnual) OVER (PARTITION BY CIK ORDER BY Ano), 0) * 100)
            ELSE NULL
        END AS CrescimentoPercentual
    FROM PrecosPorAno
),
AnosPositivos AS (
    SELECT
        CIK,
        Ticker,
        NomeEmpresa,
        Setor,
        COUNT(*) AS TotalAnos,
        SUM(CASE WHEN CrescimentoPercentual > 0 THEN 1 ELSE 0 END) AS AnosPositivos,
        AVG(CrescimentoPercentual) AS CrescimentoMedioAnual,
        MIN(CrescimentoPercentual) AS PiorAno,
        MAX(CrescimentoPercentual) AS MelhorAno
    FROM CrescimentoAnual
    WHERE CrescimentoPercentual IS NOT NULL
    GROUP BY CIK, Ticker, NomeEmpresa, Setor
)
SELECT TOP 30
    Ticker,
    NomeEmpresa,
    Setor,
    TotalAnos,
    AnosPositivos,
    CAST((CAST(AnosPositivos AS FLOAT) / TotalAnos * 100) AS DECIMAL(10, 2)) AS TaxaConsistencia,
    CAST(CrescimentoMedioAnual AS DECIMAL(10, 2)) AS CrescimentoMedioAnual_Pct,
    CAST(PiorAno AS DECIMAL(10, 2)) AS PiorAno_Pct,
    CAST(MelhorAno AS DECIMAL(10, 2)) AS MelhorAno_Pct,
    CASE
        WHEN AnosPositivos = TotalAnos THEN 'Crescimento Total'
        WHEN CAST(AnosPositivos AS FLOAT) / TotalAnos >= 0.8 THEN 'Altamente Consistente'
        WHEN CAST(AnosPositivos AS FLOAT) / TotalAnos >= 0.6 THEN 'Consistente'
        ELSE 'Volátil'
    END AS Classificacao
FROM AnosPositivos
WHERE TotalAnos >= 4
ORDER BY TaxaConsistencia DESC, CrescimentoMedioAnual DESC;
GO

-- PERGUNTA 2: Setores com melhor desempenho médio no S&P 500
WITH DesempenhoSetorial AS (
    SELECT
        e.Setor,
        COUNT(DISTINCT e.CIK) AS QtdEmpresas,
        AVG(p.PrecoFechamento) AS PrecoMedio,
        AVG(p.VariacaoPercentual) AS VariacaoMediaDiaria,
        AVG(p.Volume) AS VolumeMedia,
        MIN(t.DataCompleta) AS DataInicial,
        MAX(t.DataCompleta) AS DataFinal
    FROM PrecoAcao p
    INNER JOIN Empresas e ON p.CIK = e.CIK
    INNER JOIN Tempo t ON p.IdTempo = t.IdTempo
    WHERE p.PrecoFechamento IS NOT NULL
    GROUP BY e.Setor
),
CorrelacaoIndice AS (
    SELECT
        YEAR(s.DataReferencia) AS Ano,
        AVG(s.ValorFechamento) AS ValorMedioSP500
    FROM SP500Historico s
    GROUP BY YEAR(s.DataReferencia)
)
SELECT
    d.Setor,
    d.QtdEmpresas,
    CAST(d.PrecoMedio AS DECIMAL(10, 2)) AS PrecoMedioSetor,
    CAST(d.VariacaoMediaDiaria AS DECIMAL(10, 4)) AS VariacaoMediaDiaria_Pct,
    CAST(d.VolumeMedia AS DECIMAL(18, 0)) AS VolumeMedioSetor,
    DATEDIFF(DAY, d.DataInicial, d.DataFinal) AS DiasComDados,
    CASE
        WHEN d.VariacaoMediaDiaria > 0.5 THEN 'Alto Desempenho'
        WHEN d.VariacaoMediaDiaria > 0 THEN 'Desempenho Positivo'
        WHEN d.VariacaoMediaDiaria > -0.5 THEN 'Desempenho Neutro'
        ELSE 'Baixo Desempenho'
    END AS ClassificacaoDesempenho
FROM DesempenhoSetorial d
WHERE d.Setor IS NOT NULL
ORDER BY d.VariacaoMediaDiaria DESC;
GO

-- PERGUNTA 3: Ações com maior queda na crise COVID (Mar-Abr 2020)
WITH PreCovid AS (
    SELECT
        e.CIK,
        e.Ticker,
        e.NomeEmpresa,
        e.Setor,
        AVG(p.PrecoFechamento) AS PrecoPreCovid
    FROM PrecoAcao p
    INNER JOIN Empresas e ON p.CIK = e.CIK
    INNER JOIN Tempo t ON p.IdTempo = t.IdTempo
    WHERE t.DataCompleta BETWEEN '2020-01-01' AND '2020-02-29'
      AND p.PrecoFechamento IS NOT NULL
    GROUP BY e.CIK, e.Ticker, e.NomeEmpresa, e.Setor
),
AugeCovid AS (
    SELECT
        e.CIK,
        MIN(p.PrecoFechamento) AS PrecoMinimoCovid,
        MIN(t.DataCompleta) AS DataMinimo
    FROM PrecoAcao p
    INNER JOIN Empresas e ON p.CIK = e.CIK
    INNER JOIN Tempo t ON p.IdTempo = t.IdTempo
    WHERE t.DataCompleta BETWEEN '2020-03-01' AND '2020-04-30'
      AND p.PrecoFechamento IS NOT NULL
    GROUP BY e.CIK
),
Recuperacao AS (
    SELECT
        e.CIK,
        AVG(p.PrecoFechamento) AS PrecoRecuperacao
    FROM PrecoAcao p
    INNER JOIN Empresas e ON p.CIK = e.CIK
    INNER JOIN Tempo t ON p.IdTempo = t.IdTempo
    WHERE t.DataCompleta BETWEEN '2020-12-01' AND '2020-12-31'
      AND p.PrecoFechamento IS NOT NULL
    GROUP BY e.CIK
)
SELECT TOP 30
    pc.Ticker,
    pc.NomeEmpresa,
    pc.Setor,
    CAST(pc.PrecoPreCovid AS DECIMAL(10, 2)) AS PrecoPreCovid,
    CAST(ac.PrecoMinimoCovid AS DECIMAL(10, 2)) AS PrecoMinimoCovid,
    ac.DataMinimo,
    CAST(r.PrecoRecuperacao AS DECIMAL(10, 2)) AS PrecoRecuperacao,
    CAST(((ac.PrecoMinimoCovid - pc.PrecoPreCovid) / NULLIF(pc.PrecoPreCovid, 0) * 100) AS DECIMAL(10, 2)) AS QuedaCovid_Pct,
    CAST(((r.PrecoRecuperacao - ac.PrecoMinimoCovid) / NULLIF(ac.PrecoMinimoCovid, 0) * 100) AS DECIMAL(10, 2)) AS RecuperacaoAteDezembroPct,
    CASE
        WHEN ((r.PrecoRecuperacao - pc.PrecoPreCovid) / NULLIF(pc.PrecoPreCovid, 0) * 100) > 0
        THEN 'Recuperou e Superou'
        WHEN ((r.PrecoRecuperacao - ac.PrecoMinimoCovid) / NULLIF(ac.PrecoMinimoCovid, 0) * 100) > 50
        THEN 'Forte Recuperação'
        ELSE 'Recuperação Parcial'
    END AS StatusRecuperacao
FROM PreCovid pc
INNER JOIN AugeCovid ac ON pc.CIK = ac.CIK
LEFT JOIN Recuperacao r ON pc.CIK = r.CIK
WHERE pc.PrecoPreCovid > 0
ORDER BY QuedaCovid_Pct ASC;
GO

-- PERGUNTA 4: Retorno médio de dividendos por setor e empresa
SELECT
    e.Setor,
    COUNT(DISTINCT e.CIK) AS QtdEmpresas,
    COUNT(d.IdDividendo) AS TotalPagamentos,
    CAST(AVG(d.ValorDividendo) AS DECIMAL(10, 4)) AS DividendoMedio_Pct,
    CAST(MIN(d.ValorDividendo) AS DECIMAL(10, 4)) AS DividendoMinimo_Pct,
    CAST(MAX(d.ValorDividendo) AS DECIMAL(10, 4)) AS DividendoMaximo_Pct,
    CAST(STDEV(d.ValorDividendo) AS DECIMAL(10, 4)) AS DesvioPadrao,
    CASE
        WHEN AVG(d.ValorDividendo) > 3 THEN 'Alto Rendimento'
        WHEN AVG(d.ValorDividendo) > 1.5 THEN 'Rendimento Moderado'
        WHEN AVG(d.ValorDividendo) > 0 THEN 'Rendimento Baixo'
        ELSE 'Sem Dividendos'
    END AS ClassificacaoRendimento
FROM Empresas e
LEFT JOIN Dividendos d ON e.CIK = d.CIK
WHERE e.Setor IS NOT NULL
GROUP BY e.Setor
ORDER BY DividendoMedio_Pct DESC;
GO

SELECT TOP 30
    e.Ticker,
    e.NomeEmpresa,
    e.Setor,
    COUNT(d.IdDividendo) AS TotalPagamentos,
    CAST(AVG(d.ValorDividendo) AS DECIMAL(10, 4)) AS DividendoMedio_Pct,
    CAST(MIN(d.ValorDividendo) AS DECIMAL(10, 4)) AS DividendoMinimo_Pct,
    CAST(MAX(d.ValorDividendo) AS DECIMAL(10, 4)) AS DividendoMaximo_Pct,
    MIN(t.DataCompleta) AS PrimeiroPagamento,
    MAX(t.DataCompleta) AS UltimoPagamento,
    DATEDIFF(YEAR, MIN(t.DataCompleta), MAX(t.DataCompleta)) AS AnosPagando
FROM Empresas e
INNER JOIN Dividendos d ON e.CIK = d.CIK
INNER JOIN Tempo t ON d.IdTempo = t.IdTempo
GROUP BY e.Ticker, e.NomeEmpresa, e.Setor
HAVING COUNT(d.IdDividendo) > 100  -- Pelo menos 100 pagamentos
ORDER BY DividendoMedio_Pct DESC;
GO

-- PERGUNTA 5: Relação entre Market Cap e Performance
WITH MarketCapAtual AS (
    SELECT
        sp.cik,
        AVG(TRY_CAST(sp.market_cap AS DECIMAL(20, 2))) AS MarketCapMedia
    FROM datasets.dbo.SP500 sp
    WHERE sp.observation_date >= DATEADD(MONTH, -3, (SELECT MAX(observation_date) FROM datasets.dbo.SP500))
      AND sp.market_cap IS NOT NULL
    GROUP BY sp.cik
),
Performance6Meses AS (
    SELECT
        p.CIK,
        AVG(p.VariacaoPercentual) AS VariacaoMedia,
        STDEV(p.VariacaoPercentual) AS Volatilidade
    FROM PrecoAcao p
    INNER JOIN Tempo t ON p.IdTempo = t.IdTempo
    WHERE t.DataCompleta >= DATEADD(MONTH, -6, (SELECT MAX(DataCompleta) FROM Tempo))
    GROUP BY p.CIK
)
SELECT TOP 50
    e.Ticker,
    e.NomeEmpresa,
    e.Setor,
    CAST(m.MarketCapMedia / 1000000000 AS DECIMAL(10, 2)) AS MarketCap_Bilhoes,
    CAST(pf.VariacaoMedia AS DECIMAL(10, 4)) AS VariacaoMedia_Pct,
    CAST(pf.Volatilidade AS DECIMAL(10, 4)) AS Volatilidade_Pct,
    CASE
        WHEN m.MarketCapMedia > 500000000000 THEN 'Mega Cap (>500B)'
        WHEN m.MarketCapMedia > 200000000000 THEN 'Large Cap (200B-500B)'
        WHEN m.MarketCapMedia > 10000000000 THEN 'Mid Cap (10B-200B)'
        ELSE 'Small Cap (<10B)'
    END AS CategoriaMarketCap,
    CASE
        WHEN pf.Volatilidade < 2 AND pf.VariacaoMedia > 0 THEN 'Estável e Positiva'
        WHEN pf.Volatilidade < 2 THEN 'Estável'
        WHEN pf.VariacaoMedia > 0.5 THEN 'Volátil mas Crescente'
        ELSE 'Volátil'
    END AS ClassificacaoPerformance
FROM Empresas e
INNER JOIN MarketCapAtual m ON e.CIK = m.cik
INNER JOIN Performance6Meses pf ON e.CIK = pf.CIK
WHERE m.MarketCapMedia > 0
ORDER BY m.MarketCapMedia DESC;
GO

-- PERGUNTA 6: Empresas antigas (fundadas antes de 1950) com boa performance
WITH PerformanceRecente AS (
    SELECT
        p.CIK,
        AVG(p.PrecoFechamento) AS PrecoMedio,
        AVG(p.Volume) AS VolumeMedia,
        AVG(p.VariacaoPercentual) AS VariacaoMedia
    FROM PrecoAcao p
    INNER JOIN Tempo t ON p.IdTempo = t.IdTempo
    WHERE t.DataCompleta >= DATEADD(MONTH, -6, (SELECT MAX(DataCompleta) FROM Tempo))
    GROUP BY p.CIK
)
SELECT
    e.Ticker,
    e.NomeEmpresa,
    e.Setor,
    e.AnoFundacao,
    YEAR(GETDATE()) - e.AnoFundacao AS IdadeAnos,
    CAST(pr.PrecoMedio AS DECIMAL(10, 2)) AS PrecoMedio,
    CAST(pr.VolumeMedia AS DECIMAL(18, 0)) AS VolumeMedia,
    CAST(pr.VariacaoMedia AS DECIMAL(10, 4)) AS VariacaoMedia_Pct,
    CASE
        WHEN e.AnoFundacao < 1900 THEN 'Século XIX (>125 anos)'
        WHEN e.AnoFundacao < 1925 THEN 'Início Século XX (100-125 anos)'
        WHEN e.AnoFundacao < 1950 THEN 'Pré-1950 (75-100 anos)'
        ELSE 'Pós-1950 (<75 anos)'
    END AS GeracaoEmpresa,
    CASE
        WHEN pr.VariacaoMedia > 0.3 AND pr.VolumeMedia > 1000000 THEN 'Excelente'
        WHEN pr.VariacaoMedia > 0 AND pr.VolumeMedia > 500000 THEN 'Boa'
        WHEN pr.VariacaoMedia > 0 THEN 'Moderada'
        ELSE 'Fraca'
    END AS ClassificacaoPerformance
FROM Empresas e
INNER JOIN PerformanceRecente pr ON e.CIK = pr.CIK
WHERE e.AnoFundacao IS NOT NULL
  AND e.AnoFundacao < 1950
ORDER BY e.AnoFundacao ASC, pr.VariacaoMedia DESC;
GO

-- PERGUNTA 7: Distribuição geográfica por setor (foco em Tech)
SELECT
    LTRIM(RTRIM(REPLACE(REPLACE(l.Estado, '"', ''), '''', ''))) AS Estado,
    COUNT(*) AS TotalEmpresas,
    COUNT(CASE WHEN e.Setor = 'Information Technology' THEN 1 END) AS EmpresasTech,
    COUNT(CASE WHEN e.Setor = 'Health Care' THEN 1 END) AS EmpresasHealthcare,
    COUNT(CASE WHEN e.Setor = 'Financials' THEN 1 END) AS EmpresasFinanceiras,
    CAST((COUNT(CASE WHEN e.Setor = 'Information Technology' THEN 1 END) * 100.0 / COUNT(*)) AS DECIMAL(10, 2)) AS PctTech,
    STRING_AGG(CASE WHEN e.Setor = 'Information Technology' THEN e.Ticker ELSE NULL END, ', ') AS TickersTech
FROM Localizacao l
INNER JOIN Empresas e ON l.CIK = e.CIK
WHERE l.Estado IS NOT NULL
GROUP BY LTRIM(RTRIM(REPLACE(REPLACE(l.Estado, '"', ''), '''', '')))
HAVING COUNT(*) >= 3  -- Pelo menos 3 empresas
ORDER BY TotalEmpresas DESC, PctTech DESC;
GO

SELECT
    CASE WHEN e.Setor = 'Information Technology' THEN 'Technology' ELSE 'Outros Setores' END AS Categoria,
    COUNT(DISTINCT l.Estado) AS EstadosPresentes,
    COUNT(*) AS TotalEmpresas,
    COUNT(DISTINCT l.Cidade) AS CidadesPresentes,
    CAST(AVG(CAST(YEAR(GETDATE()) - e.AnoFundacao AS FLOAT)) AS DECIMAL(10, 1)) AS IdadeMedia
FROM Empresas e
INNER JOIN Localizacao l ON e.CIK = l.CIK
WHERE l.Estado IS NOT NULL
GROUP BY CASE WHEN e.Setor = 'Information Technology' THEN 'Technology' ELSE 'Outros Setores' END;
GO

SELECT TOP 10
    LTRIM(RTRIM(REPLACE(REPLACE(l.Cidade, '"', ''), '''', ''))) AS Cidade,
    LTRIM(RTRIM(REPLACE(REPLACE(l.Estado, '"', ''), '''', ''))) AS Estado,
    COUNT(*) AS TotalEmpresas,
    COUNT(CASE WHEN e.Setor = 'Information Technology' THEN 1 END) AS EmpresasTech,
    STRING_AGG(e.Ticker, ', ') AS Tickers
FROM Localizacao l
INNER JOIN Empresas e ON l.CIK = e.CIK
WHERE l.Cidade IS NOT NULL
GROUP BY LTRIM(RTRIM(REPLACE(REPLACE(l.Cidade, '"', ''), '''', ''))), LTRIM(RTRIM(REPLACE(REPLACE(l.Estado, '"', ''), '''', '')))
ORDER BY TotalEmpresas DESC;