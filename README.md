# Gerenciamento Banco de Dados - Análise Mercado Financeiro

## 🎯 Objetivo

Avaliar a situação do mercado financeiro americano (S&P 500) e chinês (CSI 500) em situações de crise econômica, usando essa avaliação para prever como o mercado irá se comportar em futuras crises.

---

## 🚀 Como Começar (Setup Completo)

### **PASSO 1** - Setup Inicial

Cria databases, tabelas e importa dados brutos dos CSVs:

```bash
./1_setup_automatico.sh
```

### **PASSO 2** - Processar Dados (ETL)

Processa os dados brutos e popula as tabelas do master:

```bash
./2_processar_etl.sh
```

Este script vai:
- ✅ Fazer parse dos dados CSV (separar colunas)
- ✅ Popular tabela Empresas com dados do S&P 500
- ✅ Popular SubSetor e Localizacao
- ✅ Popular histórico do índice S&P 500
- ✅ Popular dimensão Tempo
- ✅ Verificar duplicatas automaticamente

### **PASSO 3** - Visualizar Dados (Opcional)

```bash
./3_visualizar.sh
```

### **PASSO 4** - Limpar/Resetar (Opcional)

```bash
./4_limpar.sh
```

---

## 📊 Configurar DataGrip

### 1. Criar Conexão
- Host: `localhost`
- Port: `1433`
- User: `SA`
- Password: `Cc202505!`
- Database: `master`

### 2. Marcar Schemas
- ✅ datasets
- ✅ master

### 3. Testar
Abra o arquivo `scripts/2-consultas/teste_conexao_datagrip.sql` e execute (Ctrl+Enter)

---

## 📁 Estrutura do Projeto

```
Gerenciamento-Banco-de-dados_v2/
│
├── compose.yaml                        # Configuração Docker
│
├── 1_setup_automatico.sh              # ⭐ PASSO 1: Setup inicial
├── 2_processar_etl.sh                 # ⭐ PASSO 2: Processar dados (ETL)
├── 3_visualizar.sh                    # 👁️  PASSO 3: Visualizar tabelas
├── 4_limpar.sh                        # 🧹 PASSO 4: Limpar/resetar
│
├── README.md                          # Este arquivo
├── COMECE_AQUI.md                     # Guia de início rápido
│
├── datasets/                          # Arquivos CSV
│   ├── S&P-500-companies.csv
│   ├── S&P500-fred.csv
│   ├── CSI500-part-1.csv
│   └── CSI500-part-2.csv
│
├── scripts/
│   ├── 1-setup/                       # Scripts de configuração
│   │   ├── 01_setup_completo.sql      # Cria databases e tabelas
│   │   └── 02_processar_dados_etl.sql # ETL (processar e popular)
│   │
│   ├── 2-consultas/                   # Scripts de visualização
│   │   ├── visualizar_tabelas.sql     # Ver todas as tabelas
│   │   └── teste_conexao_datagrip.sql # Testes no DataGrip
│   │
│   └── 3-manutencao/                  # Scripts de manutenção
│       ├── limpar_dados.sql           # Limpar dados (mantém estrutura)
│       └── resetar_tudo.sql           # Reset completo
│
├── doc/                               # Modelos e documentação
│   ├── SP500/
│   ├── CSI500/
│   └── dicionario-de-dados.csv
│
└── backup_arquivos_antigos/           # Arquivos de versões anteriores
```

---

## 💾 Estrutura dos Databases

### Database: `datasets` (Dados Brutos)
Tabelas com dados importados dos CSVs:
- **SP500_companies** (~1.000 registros)
- **SP500_fred** (~5.000 registros)
- **CSI500** (~1.700.000 registros)

### Database: `master` (Modelo Dimensional)
Estrutura para análises:
- **Indice** - Informações sobre índices financeiros
- **IndiceSP500** - Valores históricos S&P 500
- **Empresas** - Cadastro de empresas
- **SubSetor** - Classificação de indústrias
- **Localizacao** - Localização geográfica
- **Tempo** - Dimensão temporal
- **PrecoAcao** - Preços históricos das ações
- **Dividendos** - Histórico de dividendos

---

## 🔍 Perguntas de Negócio

1. Quais ações tiveram maior valorização percentual no último ano?
2. Qual é a volatilidade média das ações por setor ou indústria?
3. Quais empresas registraram maior volume de negociação?
4. Quais ações apresentaram crescimento consistente nos últimos 5 anos?
5. Quais setores apresentam melhor desempenho médio no S&P 500?
6. Quais ações sofreram maior queda em períodos de crise (COVID)?
7. Qual é o retorno médio de dividendos por setor e empresa?

---

## 📐 Modelagem de Dados

### Mercado Americano (S&P 500)
- [Modelo Conceitual](doc/SP500/Modelo-Conceitual-SP500.svg)
- [Modelo Lógico](doc/SP500/Modelo-Logico-SP500.svg)
- [Modelo Físico](doc/SP500/Modelo-Fisico-SP500.svg)

### Mercado Chinês (CSI 500)
- [Modelo Conceitual](doc/CSI500/Modelo-Conceitual-CSI500.png)
- [Modelo Lógico](doc/CSI500/Modelo-logico-CSI500.png)
- [Modelo Físico](doc/CSI500/Modelo-Fisico-CSI500.png)

### Dicionário de Dados
Consulte o [dicionário completo](doc/dicionario-de-dados.csv) para detalhes de todas as tabelas e colunas.

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
# Visualizar todas as tabelas e análises
./3_visualizar.sh

# Ou execute no DataGrip:
# scripts/2-consultas/visualizar_tabelas.sql
```

### Limpar/Resetar Dados
```bash
# Menu interativo de limpeza
./4_limpar.sh

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

```bash
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
