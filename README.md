# 📊 Análise de Mercado de Ações - S&P 500 e CSI500

## 📋 Sobre o Projeto

Este projeto realiza análises quantitativas aprofundadas sobre os mercados de ações dos índices **S&P 500** (EUA) e **CSI500** (China), utilizando SQL Server para processamento de dados e geração de insights financeiros.

### 🎯 Objetivo

Avaliar a situação do mercado financeiro americano (S&P 500) e chinês (CSI 500) em situações de crise econômica, usando essa avaliação para prever como o mercado irá se comportar em futuras crises.

**Responder 7 perguntas analíticas fundamentais:**

1. ✅ **Quais ações tiveram maior valorização percentual no último ano?**
2. ✅ **Qual é a volatilidade média das ações por setor ou indústria?**
3. ✅ **Quais empresas registraram maior volume de negociação em determinado período?**
4. ✅ **Quais ações apresentaram crescimento consistente ao longo dos últimos 5 anos?**
5. ✅ **Quais setores apresentam melhor desempenho médio no índice S&P 500?**
6. ✅ **Quais ações sofreram maior queda em períodos de crise econômica? (COVID-19)**
7. ⚠️  **Qual é o retorno médio de dividendos por setor e por empresa?** (Dados não disponíveis no dataset atual)

---

## 📁 Estrutura do Projeto

```
Gerenciamento-Banco-de-dados_v2/
│
├── 📂 datasets/                    # Dados brutos (CSV)
│   ├── S&P-500-companies.csv      # 503 empresas S&P 500
│   ├── S&P500-fred.csv             # 2,609 observações do índice
│   ├── CSI500-part-1.csv           # Ações chinesas (parte 1)
│   └── CSI500-part-2.csv           # Ações chinesas (parte 2)
│
├── 📂 doc/                         # Documentação e modelos
│   ├── SP500/                      # Modelos de dados S&P 500
│   ├── CSI500/                     # Modelos de dados CSI500
│   └── dicionario-de-dados.csv     # Dicionário completo
│
├── 📂 scripts/                     # Scripts SQL organizados
│   ├── 1-setup/                    # Configuração inicial
│   │   ├── 01_setup_completo.sql
│   │   └── 02_processar_dados_etl.sql
│   │
│   ├── 2-analise/                  # ⭐ ANÁLISES PRINCIPAIS
│   │   ├── 01_criar_tabelas_normalizadas.sql
│   │   ├── 02_queries_analise.sql
│   │   ├── 03_executar_analise_completa.sql
│   │   └── README.md
│   │
│   ├── 2-consultas/                # Consultas auxiliares
│   │   ├── teste_conexao_datagrip.sql
│   │   └── visualizar_tabelas.sql
│   │
│   └── 3-manutencao/               # Limpeza e reset
│       ├── limpar_dados.sql
│       └── resetar_tudo.sql
│
├── 📂 scripts-linux/               # Scripts Bash para Linux/Mac
│   ├── 1_setup_automatico.sh
│   ├── 2_processar_etl.sh
│   ├── 3_visualizar.sh
│   └── 4_limpar.sh
│
├── 📂 scripts-windows/             # Scripts PowerShell para Windows
│   ├── 1_setup_automatico.ps1
│   ├── 2_processar_etl.ps1
│   ├── 3_visualizar.ps1
│   └── 4_limpar.ps1
│
├── 📂 logs/                        # Logs de execução
├── 📂 resultados/                  # Resultados das análises
├── 📂 backup_arquivos_antigos/     # Arquivos legados
│
├── 📄 COMECE_AQUI.md               # ⭐ INÍCIO RÁPIDO
├── 📄 perguntas-analise.md         # Lista das 7 perguntas
├── 📄 executar-analise.sh          # Execução rápida (Linux)
├── 📄 executar-analise.ps1         # Execução rápida (Windows)
├── 📄 compose.yaml                 # Docker Compose
└── 📄 README.md                    # Este arquivo
```

---

## 🚀 Início Rápido (3 COMANDOS!)

### Pré-requisitos

- **Docker** e **Docker Compose** instalados
- **8GB RAM** disponível (mínimo 4GB)
- **10GB espaço em disco**
- Sistema operacional: Linux, macOS ou Windows

### ⚡ Setup Automático (RECOMENDADO)

#### 🐧 Linux / macOS

```bash
# 1. Navegar até o projeto
cd /home/matheus/DataGripProjects/Gerenciamento-Banco-de-dados_v2

# 2. Tornar script executável
chmod +x SETUP_COMPLETO.sh

# 3. Executar setup completo (escolha opção 1 no menu)
./SETUP_COMPLETO.sh
```

**O que o script faz:**
- ✅ Inicia o Docker container SQL Server
- ✅ Cria os bancos de dados (datasets, master)
- ✅ Importa ~1.7 milhões de registros dos CSVs
- ✅ Normaliza e processa os dados
- ✅ Cria tabelas otimizadas com índices
- ✅ Cria as 7 views analíticas
- ✅ Executa as queries e mostra os resultados

**Tempo estimado:** 5-10 minutos

#### 🪟 Windows PowerShell

```powershell
# 1. Navegar até o projeto
cd C:\caminho\do\projeto

# 2. Iniciar o ambiente
docker compose up -d

# 3. Executar setup (primeira vez)
.\scripts-windows\1_setup_automatico.ps1

# 4. Executar análises
.\executar-analise.ps1

# 5. Ver resultados
.\scripts-windows\3_visualizar.ps1
```

**Se der erro de política de execução:**
```powershell
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
.\executar-analise.ps1
```

---

---

## 📊 Dados Disponíveis

### Dataset 1: S&P 500 Companies
- **Empresas:** 503
- **Campos:** Symbol, Security, GICS Sector, GICS Sub-Industry, Headquarters, Date Added, CIK, Founded
- **Fonte:** CSV de empresas listadas no S&P 500

### Dataset 2: S&P 500 Index (FRED)
- **Observações:** 2,609
- **Período:** 2015-08-31 até presente
- **Campos:** Observation Date, SP500 Value
- **Fonte:** Federal Reserve Economic Data

### Dataset 3: CSI500 (China)
- **Ações:** 500+ empresas chinesas
- **Registros:** 865,898 observações
- **Período:** 2015-09-09 até presente
- **Campos:** Symbol, Date, Open, High, Low, Close, Volume, Amount, Shares Outstanding, Turnover Rate, Company Name, Industry

---

## 🎯 As 7 Perguntas Respondidas

### 1️⃣ Quais ações tiveram maior valorização percentual no último ano?
- **View:** `vw_P1_MaiorValorizacaoUltimoAno`
- **Métricas:** Valorização %, Variação absoluta, Categoria de desempenho
- **Classificação:** Crescimento Excepcional (>50%), Alto (20-50%), Moderado (0-20%)
- **Exemplo:**
  ```sql
  SELECT TOP 20 Symbol, Empresa, ValorizacaoPercentual, CategoriaDesempenho
  FROM vw_P1_MaiorValorizacaoUltimoAno
  ORDER BY ValorizacaoPercentual DESC;
  ```

### 2️⃣ Qual é a volatilidade média das ações por setor ou indústria?
- **View:** `vw_P2_VolatilidadePorIndustria`
- **Métricas:** Volatilidade diária, Volatilidade anualizada (√252), Retorno médio
- **Classificação:** Muito Alta (>40%), Alta (25-40%), Moderada (15-25%), Baixa (<15%)
- **Exemplo:**
  ```sql
  SELECT Industria, VolatilidadeAnualizada_Pct, ClassificacaoVolatilidade
  FROM vw_P2_VolatilidadePorIndustria
  ORDER BY VolatilidadeAnualizada_Pct DESC;
  ```

### 3️⃣ Quais empresas registraram maior volume de negociação?
- **View:** `vw_P3_MaiorVolumeNegociacao`
- **Período:** Últimos 6 meses
- **Métricas:** Volume total/médio, Valor financeiro, Taxa de giro
- **Classificação:** Muito Líquida, Líquida, Moderadamente Líquida, Pouco Líquida
- **Exemplo:**
  ```sql
  SELECT TOP 30 Symbol, Empresa, VolumeTotal, ClassificacaoLiquidez
  FROM vw_P3_MaiorVolumeNegociacao
  ORDER BY VolumeTotal DESC;
  ```

### 4️⃣ Quais ações apresentaram crescimento consistente nos últimos 5 anos?
- **View:** `vw_P4_CrescimentoConsistente5Anos`
- **Métricas:** Taxa de sucesso (% anos positivos), Retorno médio anual, Sharpe Ratio
- **Classificação:** Muito Consistente (≥80%), Consistente (60-80%), Moderada (40-60%)
- **Exemplo:**
  ```sql
  SELECT TOP 30 Symbol, Empresa, TaxaSucessoPct, RetornoMedioAnual_Pct
  FROM vw_P4_CrescimentoConsistente5Anos
  ORDER BY TaxaSucessoPct DESC;
  ```

### 5️⃣ Quais setores apresentam melhor desempenho médio no S&P 500?
- **View:** `vw_P5_DesempenhoSetoresSP500`
- **Métricas:** Quantidade de empresas, Participação %, Empresas adicionadas recentemente
- **Classificação:** Setor Dominante (≥60), Principal (40-59), Relevante (20-39)
- **Exemplo:**
  ```sql
  SELECT Setor, QtdEmpresas, ParticipacaoPct, ClassificacaoTamanho
  FROM vw_P5_DesempenhoSetoresSP500
  ORDER BY QtdEmpresas DESC;
  ```

### 6️⃣ Quais ações sofreram maior queda durante a crise COVID-19?
- **View:** `vw_P6_QuedaCriseCovid`
- **Período:** Janeiro a Julho de 2020
- **Métricas:** Queda percentual, Recuperação total, Data do mínimo
- **Classificação:** Resiliente (<10%), Impacto Moderado (10-25%), Alto (25-40%), Severo (>40%)
- **Exemplo:**
  ```sql
  SELECT TOP 30 Symbol, Empresa, QuedaPercentual, RecuperacaoTotal_Pct, ClassificacaoImpacto
  FROM vw_P6_QuedaCriseCovid
  ORDER BY QuedaPercentual ASC;
  ```

### 7️⃣ Qual é o retorno médio de dividendos por setor e por empresa?
- **View:** `vw_P7_DadosBaseParaDividendos`
- **Status:** ⚠️ Dados de dividendos não disponíveis no dataset atual
- **Estrutura:** Preparada para futura integração
- **Alternativas:** API Yahoo Finance, Alpha Vantage, Bloomberg
- **Exemplo:**
  ```sql
  SELECT Symbol, NomeEmpresa, Setor, TendenciaDividendos
  FROM vw_P7_DadosBaseParaDividendos
  WHERE Setor IN ('Utilities', 'Real Estate')
  ORDER BY Setor;
  ```

---

## 📈 Views Criadas

### Views Analíticas (6 total)

| View | Descrição | Uso |
|------|-----------|-----|
| `vw_EmpresasSP500Resumo` | Resumo de empresas S&P 500 | Consultas gerais sobre empresas |
| `vw_IndiceSP500Metricas` | Métricas do índice com variações | Análise temporal do mercado |
| `vw_AcoesChinesasIndicadores` | Indicadores técnicos CSI500 | Análises técnicas detalhadas |
| `vw_TopPerformers30d` | Top performers em 30 dias | Identificação rápida de winners |
| `vw_ResumoSetoresSP500` | Agregação por setor | Análise setorial |
| `vw_ResumoIndustriasCSI500` | Agregação por indústria | Análise industrial China |

### Exemplos de Consulta

```sql
-- Top 10 performers nos últimos 30 dias
SELECT TOP 10 * FROM vw_TopPerformers30d
ORDER BY VariacaoPercentual DESC;

-- Resumo por setor S&P 500
SELECT * FROM vw_ResumoSetoresSP500
ORDER BY QtdEmpresas DESC;

-- Evolução recente do índice
SELECT TOP 30 Data, Valor, VariacaoPercentual
FROM vw_IndiceSP500Metricas
ORDER BY Data DESC;

-- Ações chinesas por indústria
SELECT * FROM vw_ResumoIndustriasCSI500
ORDER BY VolumeTotal DESC;
```

---

## 🔧 Comandos Úteis

### Docker
```bash
# Iniciar container
docker compose up -d

# Parar container
docker compose down

# Ver status
docker compose ps

# Ver logs
docker logs sqlserverCC
```

### Verificar Dados
```bash
# Listar databases
docker exec sqlserverCC /opt/mssql-tools18/bin/sqlcmd -S localhost -U SA -P "Cc202505!" -Q "SELECT name FROM sys.databases" -C

# Contar registros
docker exec sqlserverCC bash -c "/opt/mssql-tools18/bin/sqlcmd -S localhost -U SA -P 'Cc202505!' -C <<'EOF'
USE datasets
GO
SELECT 'SP500_companies' as Tabela, COUNT(*) as Total FROM SP500_companies
UNION ALL
SELECT 'SP500_fred', COUNT(*) FROM SP500_fred
UNION ALL
SELECT 'CSI500', COUNT(*) FROM CSI500
GO
EOF"
```

### Visualizar Dados das Tabelas
```bash
# Linux/Mac
cd scripts-linux && ./3_visualizar.sh

# Windows
cd scripts-windows
.\3_visualizar.ps1

# Ou execute no DataGrip:
# scripts/2-consultas/visualizar_tabelas.sql
```

### Limpar/Resetar Dados
```bash
# Linux/Mac
cd scripts-linux && ./4_limpar.sh

# Windows
cd scripts-windows
.\4_limpar.ps1

# Opção 1: Limpar apenas dados (mantém estrutura)
# Opção 2: Resetar tudo do zero (remove tudo)
```

---

## 🛠️ Tecnologias Utilizadas

- **Banco de Dados**: SQL Server 2022 (Docker)
- **Container**: Docker Compose
- **IDE**: DataGrip
- **Modelagem**: Data Warehouse (Esquema Dimensional)
- **Controle de Versão**: Git/GitHub
- **Gerenciamento**: Trello (SCRUM)

---

## 📋 Status do Projeto

1. ✅ Setup do ambiente (Docker + SQL Server)
2. ✅ Importação de dados brutos (datasets)
3. ✅ Processo ETL (popular tabelas do master)
4. ⏳ Desenvolver queries de análise
5. ⏳ Criar views e stored procedures
6. ⏳ Implementar dashboards

## 🔄 Fluxo Completo de Uso

### Linux/Mac
```bash
cd scripts-linux

# PASSO 1: Setup inicial (primeira vez)
./1_setup_automatico.sh

# PASSO 2: Processar dados (ETL)
./2_processar_etl.sh

# PASSO 3: Visualizar dados (opcional)
./3_visualizar.sh

# PASSO 4: Configurar DataGrip e executar análises

# Se precisar resetar:
./4_limpar.sh  # Escolher opção desejada
```

### Windows
```powershell
cd scripts-windows

# PASSO 1: Setup inicial (primeira vez)
.\1_setup_automatico.ps1

# PASSO 2: Processar dados (ETL)
.\2_processar_etl.ps1

# PASSO 3: Visualizar dados (opcional)
.\3_visualizar.ps1

# PASSO 4: Configurar DataGrip e executar análises

# Se precisar resetar:
.\4_limpar.ps1  # Escolher opção desejada
```

---

## 🔗 Links Importantes

- [Planejamento (Trello)](https://trello.com/invite/b/KkIiciFk/ATTIc77290b98b15e3589e6f2e7ea4d9dad3915E3CA4/gest-o-de-tarefas-scrum)
- [Fonte S&P 500 Index](https://fred.stlouisfed.org/series/SP500)
- [Fonte S&P 500 Companies](https://github.com/datasets/s-and-p-500-companies)

---

## ⚠️ Troubleshooting

### Container não inicia
```bash
docker compose down -v
docker compose up -d
```

### Tabelas não aparecem no DataGrip
1. File → Invalidate Caches
2. Restart
3. F5 na conexão

### Erro "Invalid object"
Use o caminho completo:
```sql
SELECT * FROM datasets.dbo.SP500_companies;
```

---

## 📞 Credenciais

| Item | Valor |
|------|-------|
| Host | localhost |
| Port | 1433 |
| User | SA |
| Password | Cc202505! |
| Database 1 | master |
| Database 2 | datasets |

---

**📊 Desenvolvido como parte da disciplina de Gerenciamento de Banco de Dados**
