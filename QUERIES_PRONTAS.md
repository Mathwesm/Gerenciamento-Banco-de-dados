# 📊 Queries Prontas para Análise

## 🎯 Views Criadas e Disponíveis

### 1. vw_ValorizacaoAcoes (422 ações)
**Descrição:** Valorização de cada ação nos últimos 6 meses

```sql
USE FinanceDB;

-- Top 10 ações com maior valorização
SELECT TOP 10
    Ticker,
    NomeEmpresa,
    Setor,
    PrecoInicial,
    PrecoFinal,
    ValorizacaoPercentual,
    CategoriaDesempenho
FROM vw_ValorizacaoAcoes
ORDER BY ValorizacaoPercentual DESC;

-- Ações por categoria de desempenho
SELECT
    CategoriaDesempenho,
    COUNT(*) AS QtdAcoes,
    AVG(ValorizacaoPercentual) AS MediaValorizacao
FROM vw_ValorizacaoAcoes
GROUP BY CategoriaDesempenho
ORDER BY MediaValorizacao DESC;
```

### 2. vw_VolatilidadeSetor (11 setores)
**Descrição:** Volatilidade e retornos por setor

```sql
-- Setores mais voláteis
SELECT
    Setor,
    QtdEmpresas,
    RetornoMedioDiario_Pct,
    VolatilidadeAnualizada_Pct,
    ClassificacaoVolatilidade
FROM vw_VolatilidadeSetor
ORDER BY VolatilidadeAnualizada_Pct DESC;

-- Comparar setores
SELECT
    Setor,
    VolatilidadeAnualizada_Pct,
    RetornoMedioDiario_Pct
FROM vw_VolatilidadeSetor
WHERE QtdEmpresas >= 5
ORDER BY Setor;
```

### 3. vw_VolumeNegociacao (500 empresas)
**Descrição:** Volume de negociação dos últimos 6 meses

```sql
-- Top 20 empresas por volume
SELECT TOP 20
    Ticker,
    NomeEmpresa,
    Setor,
    VolumeTotal,
    VolumeMediaDiaria,
    PrecoMedio
FROM vw_VolumeNegociacao
ORDER BY VolumeTotal DESC;

-- Volume médio por setor
SELECT
    Setor,
    COUNT(*) AS QtdEmpresas,
    AVG(VolumeMediaDiaria) AS VolumeMediaSetor,
    AVG(PrecoMedio) AS PrecoMedioSetor
FROM vw_VolumeNegociacao
GROUP BY Setor
ORDER BY VolumeMediaSetor DESC;
```

### 4. vw_EvolucaoSP500Mensal (2.512 meses)
**Descrição:** Evolução mensal do índice S&P 500

```sql
-- Últimos 12 meses
SELECT TOP 12
    Ano,
    Mes,
    Abertura,
    Fechamento,
    RetornoMensal_Pct,
    AmplitudeMensal_Pct
FROM vw_EvolucaoSP500Mensal
ORDER BY Ano DESC, Mes DESC;

-- Melhores e piores meses
(SELECT TOP 5 'Melhores' AS Tipo, Ano, Mes, RetornoMensal_Pct
 FROM vw_EvolucaoSP500Mensal
 ORDER BY RetornoMensal_Pct DESC)
UNION ALL
(SELECT TOP 5 'Piores', Ano, Mes, RetornoMensal_Pct
 FROM vw_EvolucaoSP500Mensal
 ORDER BY RetornoMensal_Pct ASC)
ORDER BY Tipo, RetornoMensal_Pct DESC;
```

### 5. vw_EmpresasPorSetor (11 setores)
**Descrição:** Distribuição e estatísticas por setor

```sql
-- Visão geral dos setores
SELECT
    Setor,
    QtdEmpresas,
    IdadeMediaAnos,
    AdicionadasUltimos5Anos,
    PrimeiraAdicao,
    UltimaAdicao
FROM vw_EmpresasPorSetor
ORDER BY QtdEmpresas DESC;

-- Tickers por setor
SELECT
    Setor,
    QtdEmpresas,
    Tickers
FROM vw_EmpresasPorSetor
WHERE QtdEmpresas <= 10
ORDER BY Setor;
```

### 6. vw_ResumoDesempenhoEmpresas (500 empresas)
**Descrição:** Resumo completo de cada empresa

```sql
-- Buscar empresa específica
SELECT *
FROM vw_ResumoDesempenhoEmpresas
WHERE Ticker = 'AAPL';

-- Top performers por volume e preço
SELECT TOP 10
    Ticker,
    NomeEmpresa,
    Setor,
    Cidade,
    Estado,
    PrecoMedio,
    VolumeMediaDiaria,
    VariacaoMediaDiaria
FROM vw_ResumoDesempenhoEmpresas
WHERE VolumeMediaDiaria IS NOT NULL
ORDER BY VolumeMediaDiaria DESC;
```

## 🔍 Queries Analíticas Avançadas

### Análise 1: Correlação Setor vs Performance

```sql
USE FinanceDB;

SELECT
    v.Setor,
    COUNT(*) AS QtdEmpresas,
    AVG(v.ValorizacaoPercentual) AS ValorizacaoMedia,
    vs.VolatilidadeAnualizada_Pct,
    vs.ClassificacaoVolatilidade
FROM vw_ValorizacaoAcoes v
INNER JOIN vw_VolatilidadeSetor vs ON v.Setor = vs.Setor
GROUP BY v.Setor, vs.VolatilidadeAnualizada_Pct, vs.ClassificacaoVolatilidade
ORDER BY ValorizacaoMedia DESC;
```

### Análise 2: Empresas de Alto Volume e Alta Valorização

```sql
SELECT
    va.Ticker,
    va.NomeEmpresa,
    va.Setor,
    va.ValorizacaoPercentual,
    vn.VolumeTotal,
    vn.VolumeMediaDiaria
FROM vw_ValorizacaoAcoes va
INNER JOIN vw_VolumeNegociacao vn ON va.Ticker = vn.Ticker
WHERE va.ValorizacaoPercentual > 50
  AND vn.VolumeTotal > 1000000000
ORDER BY va.ValorizacaoPercentual DESC;
```

### Análise 3: Evolução do S&P 500 vs Performance Setorial

```sql
SELECT
    sp.Ano,
    sp.Mes,
    sp.RetornoMensal_Pct AS RetornoSP500,
    vs.Setor,
    vs.RetornoMedioDiario_Pct * 30 AS RetornoMensalEstimado
FROM vw_EvolucaoSP500Mensal sp
CROSS JOIN vw_VolatilidadeSetor vs
WHERE sp.Ano >= 2024
ORDER BY sp.Ano DESC, sp.Mes DESC, vs.Setor;
```

### Análise 4: Ranking Completo de Empresas

```sql
SELECT
    r.Ticker,
    r.NomeEmpresa,
    r.Setor,
    r.Cidade,
    r.Estado,
    v.ValorizacaoPercentual,
    vn.VolumeMediaDiaria,
    r.PrecoMedio,
    CASE
        WHEN v.ValorizacaoPercentual > 100 AND vn.VolumeMediaDiaria > 20000000
        THEN 'Estrela'
        WHEN v.ValorizacaoPercentual > 50 THEN 'Alto Crescimento'
        WHEN vn.VolumeMediaDiaria > 20000000 THEN 'Alta Liquidez'
        ELSE 'Normal'
    END AS Classificacao
FROM vw_ResumoDesempenhoEmpresas r
LEFT JOIN vw_ValorizacaoAcoes v ON r.Ticker = v.Ticker
LEFT JOIN vw_VolumeNegociacao vn ON r.Ticker = vn.Ticker
ORDER BY v.ValorizacaoPercentual DESC;
```

## 📈 Análises do Mercado Chinês (CSI500)

```sql
USE datasets;

-- Top 10 ações chinesas com maior volume
SELECT TOP 10
    codigo_empresa,
    nome_empresa_en,
    industry_en,
    COUNT(*) AS DiasNegociados,
    SUM(TRY_CAST(volume AS DECIMAL(18,2))) AS VolumeTotal
FROM CSI500
WHERE [date] >= DATEADD(MONTH, -6, (SELECT MAX([date]) FROM CSI500))
GROUP BY codigo_empresa, nome_empresa_en, industry_en
ORDER BY VolumeTotal DESC;

-- Distribuição por indústria
SELECT
    industry_en,
    COUNT(DISTINCT codigo_empresa) AS QtdEmpresas,
    COUNT(*) AS QtdObservacoes
FROM CSI500
WHERE industry_en IS NOT NULL
GROUP BY industry_en
ORDER BY QtdEmpresas DESC;
```

## 🎯 Queries para Relatórios Executivos

### Relatório 1: Dashboard Executivo

```sql
USE FinanceDB;

-- Métricas Gerais
SELECT
    'Total de Empresas' AS Metrica,
    CAST(COUNT(*) AS VARCHAR) AS Valor
FROM Empresas
UNION ALL
SELECT 'Setores Únicos', CAST(COUNT(DISTINCT Setor) AS VARCHAR)
FROM Empresas
UNION ALL
SELECT 'Total de Observações', CAST(COUNT(*) AS VARCHAR)
FROM PrecoAcao
UNION ALL
SELECT 'Período de Dados',
    CAST(MIN(DataCompleta) AS VARCHAR) + ' a ' + CAST(MAX(DataCompleta) AS VARCHAR)
FROM Tempo;

-- Top 5 por cada categoria
SELECT 'Top Valorização' AS Categoria, Ticker, CAST(ValorizacaoPercentual AS VARCHAR) AS Valor
FROM (SELECT TOP 5 Ticker, ValorizacaoPercentual FROM vw_ValorizacaoAcoes ORDER BY ValorizacaoPercentual DESC) t
UNION ALL
SELECT 'Top Volume', Ticker, CAST(VolumeTotal AS VARCHAR)
FROM (SELECT TOP 5 Ticker, VolumeTotal FROM vw_VolumeNegociacao ORDER BY VolumeTotal DESC) t
ORDER BY Categoria, Ticker;
```

### Relatório 2: Análise de Risco

```sql
-- Empresas de alto risco (alta volatilidade, baixo volume)
SELECT
    r.Ticker,
    r.NomeEmpresa,
    r.Setor,
    vs.VolatilidadeAnualizada_Pct,
    vn.VolumeMediaDiaria
FROM vw_ResumoDesempenhoEmpresas r
INNER JOIN vw_VolatilidadeSetor vs ON r.Setor = vs.Setor
LEFT JOIN vw_VolumeNegociacao vn ON r.Ticker = vn.Ticker
WHERE vs.VolatilidadeAnualizada_Pct > 1000
  AND (vn.VolumeMediaDiaria < 10000000 OR vn.VolumeMediaDiaria IS NULL)
ORDER BY vs.VolatilidadeAnualizada_Pct DESC;
```

## 💡 Dicas de Uso

1. **Filtrar por período:** Adicione WHERE clauses nas datas
2. **Exportar para Excel:** Use DataGrip Export (Ctrl+Alt+E)
3. **Criar gráficos:** Copie resultados para ferramentas de BI
4. **Performance:** As views já estão otimizadas com índices

## 🔗 Links Úteis

- Documentação completa: `SETUP.md`
- Scripts de análise: `scripts/2-analise/`
- Manutenção: `scripts/3-manutencao/`
