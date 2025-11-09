# 🎯 7 Perguntas Analíticas - Mercado de Ações

## 📊 Análises Implementadas

### 1️⃣ Quais ações tiveram maior valorização percentual no último ano?

**View:** `vw_P1_MaiorValorizacaoUltimoAno`

**O que analisa:**
- Compara preço inicial (há 1 ano) com preço final (data mais recente)
- Calcula valorização percentual
- Classifica em categorias de desempenho

**Métricas:**
- Valorização Percentual (%)
- Valorização Absoluta (valor)
- Categoria: Crescimento Excepcional, Alto, Moderado, Queda

**Query de exemplo:**
```sql
SELECT TOP 20 Symbol, Empresa, ValorizacaoPercentual, CategoriaDesempenho
FROM vw_P1_MaiorValorizacaoUltimoAno
ORDER BY ValorizacaoPercentual DESC;
```

---

### 2️⃣ Qual é a volatilidade média das ações por setor ou indústria?

**View:** `vw_P2_VolatilidadePorIndustria`

**O que analisa:**
- Calcula retornos diários para cada ação
- Agrega por indústria
- Calcula desvio padrão e anualiza (√252)

**Métricas:**
- Retorno Médio Diário (%)
- Volatilidade Diária (%)
- Volatilidade Anualizada (%)
- Classificação: Muito Alta, Alta, Moderada, Baixa

**Query de exemplo:**
```sql
SELECT Industria, VolatilidadeAnualizada_Pct, ClassificacaoVolatilidade
FROM vw_P2_VolatilidadePorIndustria
ORDER BY VolatilidadeAnualizada_Pct DESC;
```

---

### 3️⃣ Quais empresas registraram maior volume de negociação em determinado período?

**View:** `vw_P3_MaiorVolumeNegociacao`

**Período analisado:** Últimos 6 meses

**O que analisa:**
- Soma volume total negociado
- Calcula volume médio diário
- Analisa valor financeiro movimentado
- Avalia taxa de giro (turnover rate)

**Métricas:**
- Volume Total
- Volume Médio Diário
- Valor Financeiro Total
- Taxa de Giro Média (%)
- Classificação: Muito Líquida, Líquida, Moderadamente Líquida, Pouco Líquida

**Query de exemplo:**
```sql
SELECT TOP 30 Symbol, Empresa, VolumeTotal, ClassificacaoLiquidez
FROM vw_P3_MaiorVolumeNegociacao
ORDER BY VolumeTotal DESC;
```

---

### 4️⃣ Quais ações apresentaram crescimento consistente ao longo dos últimos 5 anos?

**View:** `vw_P4_CrescimentoConsistente5Anos`

**O que analisa:**
- Divide dados em períodos anuais
- Calcula retorno de cada ano
- Conta quantos anos foram positivos
- Calcula Sharpe Ratio simplificado

**Métricas:**
- Anos com Dados
- Anos Positivos
- Taxa de Sucesso (% anos positivos)
- Retorno Médio Anual (%)
- Sharpe Ratio Simplificado
- Classificação: Muito Consistente, Consistente, Moderadamente Consistente, Inconsistente

**Query de exemplo:**
```sql
SELECT TOP 30 Symbol, Empresa, TaxaSucessoPct, RetornoMedioAnual_Pct
FROM vw_P4_CrescimentoConsistente5Anos
ORDER BY TaxaSucessoPct DESC;
```

---

### 5️⃣ Quais setores apresentam melhor desempenho médio no índice S&P 500?

**View:** `vw_P5_DesempenhoSetoresSP500`

**O que analisa:**
- Distribui empresas por setor GICS
- Calcula participação percentual
- Identifica empresas adicionadas recentemente
- Correlaciona com evolução do índice

**Métricas:**
- Quantidade de Empresas
- Participação no Índice (%)
- Idade Média das Empresas
- Empresas Adicionadas nos Últimos 5 Anos
- Retorno Total do Índice S&P 500
- Classificação: Setor Dominante, Principal, Relevante, Especializado

**Query de exemplo:**
```sql
SELECT Setor, QtdEmpresas, ParticipacaoPct, ClassificacaoTamanho
FROM vw_P5_DesempenhoSetoresSP500
ORDER BY QtdEmpresas DESC;
```

---

### 6️⃣ Quais ações sofreram maior queda em períodos de crise econômica? (COVID-19)

**View:** `vw_P6_QuedaCriseCovid`

**Período analisado:** Janeiro a Julho de 2020

**O que analisa:**
- Define preço pré-COVID (janeiro 2020)
- Encontra preço mínimo durante crise (fev-abr 2020)
- Calcula recuperação (maio-jul 2020)
- Classifica impacto

**Métricas:**
- Preço Pré-COVID
- Preço Mínimo COVID
- Data do Mínimo
- Queda Percentual (%)
- Recuperação no Período (%)
- Recuperação Total (%)
- Classificação: Resiliente, Impacto Moderado, Alto Impacto, Impacto Severo

**Query de exemplo:**
```sql
SELECT TOP 30 Symbol, Empresa, QuedaPercentual, RecuperacaoTotal_Pct, ClassificacaoImpacto
FROM vw_P6_QuedaCriseCovid
ORDER BY QuedaPercentual ASC;
```

---

### 7️⃣ Qual é o retorno médio de dividendos por setor e por empresa?

**View:** `vw_P7_DadosBaseParaDividendos`

**Status:** ⚠️ **Dados não disponíveis no dataset atual**

**O que fornece:**
- Base de empresas classificadas por setor
- Identificação de setores que tipicamente pagam dividendos
- Estrutura preparada para integração futura

**Setores com tendência a pagar dividendos:**
- Utilities (Utilidades)
- Real Estate (Imóveis)
- Consumer Staples (Bens de consumo básico)
- Financials (Finanças)

**Para análise completa, você precisará:**
- API Yahoo Finance
- Alpha Vantage API
- Bloomberg Terminal
- Relatórios corporativos (10-K, 10-Q)

**Query de exemplo:**
```sql
SELECT Symbol, NomeEmpresa, Setor, TendenciaDividendos
FROM vw_P7_DadosBaseParaDividendos
WHERE Setor IN ('Utilities', 'Real Estate')
ORDER BY Setor;
```

---

## 🚀 Como Executar as Análises

### Método 1: Script Automatizado

```bash
cd /home/matheus/DataGripProjects/Gerenciamento-Banco-de-dados_v2
./SETUP_COMPLETO.sh
# Escolha opção 1: Setup Completo
```

### Método 2: DataGrip

1. Abra o DataGrip
2. Conecte ao banco `datasets`
3. Navegue até `Views`
4. Clique com botão direito em qualquer view > `Edit Data`

### Método 3: SQL direto

```bash
docker exec -i sqlserverCC /opt/mssql-tools18/bin/sqlcmd \
  -S localhost -U SA -P "Cc202505!" -C \
  -i /tmp/05_consultar_respostas.sql
```

---

## 📚 Documentação

- **Guia Rápido:** `GUIA_RAPIDO.md`
- **README Completo:** `README.md`
- **Documentação das Views:** `scripts/2-analise/README.md`

---

**Última atualização:** 2025-11-08
