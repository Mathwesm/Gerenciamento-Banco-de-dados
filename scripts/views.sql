
----- TRANSFORMAR CONSULTAS EM VIEWS

--------------------------------------- SP 500 -------------------------------------------------------------------------------
---- PERGUNTA 2: Volatilidade por Setor

CREATE VIEW vw_VolatilidadeSetorSP500 AS ---- view para criar
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
GROUP BY Setor
HAVING COUNT(DISTINCT Ticker) >= 3
ORDER BY VolatilidadeAnualizada_Pct DESC;
GO


---------------------------------------------------------------------------------------------------------------------------------------------------

-- PERGUNTA 4: Evolução do Índice S&P 500

CREATE VIEW vw_evolucao_do_indiceSP500 as
WITH IndiceMensal AS (
    SELECT
        YEAR(DataReferencia) AS Ano,
        MONTH(DataReferencia) AS Mes,
        MIN(ValorFechamento) AS MinimoMes,
        MAX(ValorFechamento) AS MaximoMes,
        AVG(ValorFechamento) AS MediaMes,
        FIRST_VALUE(ValorFechamento) OVER (
            PARTITION BY YEAR(DataReferencia), MONTH(DataReferencia)
            ORDER BY DataReferencia ASC
        ) AS AberturaMes,
        FIRST_VALUE(ValorFechamento) OVER (
            PARTITION BY YEAR(DataReferencia), MONTH(DataReferencia)
            ORDER BY DataReferencia DESC
        ) AS FechamentoMes
    FROM SP500Historico
    GROUP BY YEAR(DataReferencia), MONTH(DataReferencia), DataReferencia, ValorFechamento
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

--------------------------------------------------------------------------------------------------------------------------------------------------------------------------

------- PERGUNTA 5: Empresas por Setor

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



---- RESUMO EXECUTIVO



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
FROM SP500Historico
WHERE DataReferencia = (SELECT MAX(DataReferencia) FROM SP500Historico);
GO




------------------------------------------------- ANÁLISES CSI500 (MERCADO CHINÊS) ---------------------------------------------------------------------------

-- Volatilidade por Indústria

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


-- Distribuição por Indústria

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


-- PERGUNTA 5: Evolução do Índice CSI500

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



 -- RESUMO EXECUTIVO CSI500


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

----------------------------------------- PERGUNTA ADICIONAIS ------------------------------------------------------------------------------------------------

--- PERGUNTA 5: Desempenho Setores no S&P 500

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

--- PERGUNTA 7: Dividendos por Setor e Empresa (SP500)

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

PRINT '';
PRINT 'TOP 30 EMPRESAS COM MAIORES DIVIDENDOS:';
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