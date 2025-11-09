# 📊 Análise das 7 Perguntas de Negócio

## Visão Geral

Este diretório contém scripts SQL para criar tabelas normalizadas e views analíticas que respondem às 7 perguntas de negócio sobre o mercado de ações (S&P 500 e CSI500).

## Estrutura dos Scripts

### 1. `01_criar_tabelas_normalizadas.sql`

Cria a estrutura de tabelas normalizadas para análise otimizada:

**Tabelas Criadas:**
- `Empresas` - Empresas do índice S&P 500
- `IndiceSP500` - Valores históricos do índice S&P 500
- `AcoesChinesas` - Dados históricos de ações do CSI500

**Características:**
- Estrutura normalizada e otimizada
- Índices para consultas rápidas
- Parsing automático dos dados CSV brutos
- Validação de dados durante inserção

### 2. `04_criar_views_7_perguntas.sql`

Cria 7 views analíticas, uma para cada pergunta de negócio.

### 3. `05_consultar_respostas.sql`

Queries de exemplo para consultar e analisar os dados das views.

---

## 🎯 As 7 Perguntas e Suas Views

1. **Maior Valorização no Último Ano**
   - Identifica ações com melhor performance percentual
   - Calcula valorização absoluta e relativa

2. **Volatilidade por Indústria**
   - Calcula volatilidade diária e anualizada
   - Retornos médios por setor
   - Estatísticas de risco por indústria

3. **Maior Volume de Negociação**
   - Volume total e médio por empresa
   - Valor financeiro movimentado
   - Taxa de giro média

4. **Crescimento Consistente (5 anos)**
   - Taxa de sucesso anual
   - Retorno médio anual
   - Índice Sharpe simplificado
   - Análise de consistência

5. **Melhor Desempenho por Setor (S&P 500)**
   - Distribuição de empresas por setor
   - Evolução do índice S&P 500
   - Análise temporal

6. **Maior Queda Durante COVID-19**
   - Impacto da crise de 2020
   - Identificação de ações mais afetadas
   - Análise de recuperação

7. **Retorno de Dividendos**
   - Nota: Dataset atual não contém dados de dividendos
   - Estrutura preparada para futura análise

### 3. `03_executar_analise_completa.sql`

Script master que executa todo o processo de análise:

**Funcionalidades:**
- Execução automatizada de todos os scripts
- Criação de 6 views analíticas
- Testes de validação
- Relatório de estatísticas finais

**Views Criadas:**
- `vw_EmpresasSP500Resumo` - Resumo de empresas S&P 500
- `vw_IndiceSP500Metricas` - Métricas do índice com variações
- `vw_AcoesChinesasIndicadores` - Indicadores técnicos CSI500
- `vw_TopPerformers30d` - Melhores performances em 30 dias
- `vw_ResumoSetoresSP500` - Agregação por setor
- `vw_ResumoIndustriasCSI500` - Agregação por indústria

## Como Usar

### Opção 1: Execução Completa (Recomendado)

```bash
# Linux
./executar-analise.sh

# Windows PowerShell
.\executar-analise.ps1
```

### Opção 2: Execução Manual

```bash
# Usando Docker
docker cp scripts/2-analise/03_executar_analise_completa.sql sqlserverCC:/tmp/
docker exec sqlserverCC /opt/mssql-tools18/bin/sqlcmd -S localhost -U SA -P "Cc202505!" -i /tmp/03_executar_analise_completa.sql -C

# Ou executar scripts individuais
docker exec sqlserverCC /opt/mssql-tools18/bin/sqlcmd -S localhost -U SA -P "Cc202505!" -i /tmp/01_criar_tabelas_normalizadas.sql -C
docker exec sqlserverCC /opt/mssql-tools18/bin/sqlcmd -S localhost -U SA -P "Cc202505!" -i /tmp/02_queries_analise.sql -C
```

### Opção 3: Via DataGrip/SQL Client

1. Conectar ao banco de dados `datasets`
2. Executar os scripts na ordem:
   - `01_criar_tabelas_normalizadas.sql`
   - `02_queries_analise.sql`
   - Ou simplesmente `03_executar_analise_completa.sql`

## Consultas Rápidas com Views

Após executar a análise, você pode usar as views para consultas rápidas:

```sql
-- Top 10 performers nos últimos 30 dias
SELECT TOP 10 * FROM vw_TopPerformers30d ORDER BY VariacaoPercentual DESC;

-- Resumo por setor S&P 500
SELECT * FROM vw_ResumoSetoresSP500 ORDER BY QtdEmpresas DESC;

-- Métricas recentes do índice S&P 500
SELECT TOP 30 * FROM vw_IndiceSP500Metricas ORDER BY Data DESC;

-- Indicadores de ações chinesas
SELECT * FROM vw_AcoesChinesasIndicadores
WHERE Empresa LIKE '%Bank%'
ORDER BY Data DESC;
```

## Requisitos

- SQL Server 2019+
- Docker (se usando containerização)
- Banco de dados `datasets` criado
- Tabelas brutas carregadas (`SP500_companies`, `SP500_fred`, `CSI500`)

## Estrutura de Dados

### Empresas (S&P 500)
```
Symbol, Security, GICSSector, GICSSubIndustry, HeadquartersLocation,
DateAdded, CIK, Founded
```

### IndiceSP500
```
ObservationDate, SP500Value
```

### AcoesChinesas (CSI500)
```
Symbol, TradeDate, OpenPrice, HighPrice, LowPrice, ClosePrice,
Volume, Amount, SharesOutstanding, TurnoverRate, CompanyName,
CompanyNameEnglish, Industry, Observations
```

## Métricas Calculadas

### Métricas de Performance
- Variação percentual (diária, mensal, anual)
- Variação absoluta
- Retorno acumulado
- Taxa de crescimento

### Métricas de Risco
- Volatilidade diária
- Volatilidade anualizada (√252)
- Amplitude de preços
- Desvio padrão dos retornos

### Métricas de Volume
- Volume total e médio
- Valor financeiro movimentado
- Taxa de giro (turnover rate)
- Liquidez relativa

### Métricas de Consistência
- Taxa de sucesso anual
- Número de anos positivos
- Sharpe Ratio simplificado
- Amplitude de retornos

## Limitações

1. **Dividendos**: Datasets atuais não contêm informações de dividendos
2. **Splits**: Não há ajuste automático para splits de ações
3. **Dados Faltantes**: Alguns períodos podem ter gaps
4. **Câmbio**: Valores em moedas diferentes (USD vs CNY)

## Próximas Melhorias

- [ ] Adicionar dados de dividendos
- [ ] Implementar ajuste de splits
- [ ] Análise de correlação entre mercados
- [ ] Backtesting de estratégias
- [ ] Machine Learning para previsões
- [ ] Dashboards interativos
- [ ] Alertas automáticos
- [ ] Export para Power BI/Tableau

## Troubleshooting

### Erro: "Object already exists"
```sql
-- Limpar tabelas antes de recriar
DROP TABLE IF EXISTS dbo.PrecoAcao;
DROP TABLE IF EXISTS dbo.Empresas;
DROP TABLE IF EXISTS dbo.IndiceSP500;
DROP TABLE IF EXISTS dbo.AcoesChinesas;
```

### Erro: "Invalid column name"
Verificar se as tabelas brutas estão carregadas:
```sql
SELECT COUNT(*) FROM SP500_companies;
SELECT COUNT(*) FROM SP500_fred;
SELECT COUNT(*) FROM CSI500;
```

### Performance lenta
Verificar índices:
```sql
SELECT
    OBJECT_NAME(i.object_id) as TableName,
    i.name as IndexName,
    i.type_desc
FROM sys.indexes i
WHERE OBJECT_NAME(i.object_id) IN ('Empresas', 'IndiceSP500', 'AcoesChinesas')
ORDER BY TableName, IndexName;
```

## Suporte

Para questões ou melhorias, consulte:
- Documentação do projeto: `README.md` na raiz
- Issues no repositório
- Logs de execução em `/logs/`

## Licença

Este projeto é parte do sistema de gerenciamento de banco de dados educacional.
