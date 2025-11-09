# 📊 Sistema de Análise Financeira - S&P 500 & CSI500

> Sistema completo de gerenciamento e análise de dados financeiros usando SQL Server 2022 no Docker

[![SQL Server](https://img.shields.io/badge/SQL%20Server-2022-red)](https://www.microsoft.com/sql-server)
[![Docker](https://img.shields.io/badge/Docker-Required-blue)](https://www.docker.com/)

---

## 📋 Índice

- [Visão Geral](#-visão-geral)
- [Quick Start](#-quick-start)
- [Estrutura do Projeto](#-estrutura-do-projeto)
- [Databases](#-databases)
- [Análises Disponíveis](#-análises-disponíveis)
- [Uso](#-uso)
- [Troubleshooting](#-troubleshooting)

---

## 🎯 Visão Geral

Sistema de banco de dados para análise de **~1.3 milhões de registros** de dados financeiros:
- **500 empresas** do S&P 500
- **479 empresas** do mercado chinês (CSI500)
- **Período:** 2015-09-09 a 2025-11-07
- **6 views analíticas** prontas para uso

### ✨ Funcionalidades

- ✅ Setup automatizado com um comando
- ✅ ETL completo de dados brutos para modelo dimensional
- ✅ 6 views de análise prontas
- ✅ Scripts de análise para perguntas de negócio
- ✅ Suporte Linux e Windows

---

## 🚀 Quick Start

### Pré-requisitos

- Docker e Docker Compose
- 8GB RAM disponível
- 10GB espaço em disco

### Linux/Mac

```bash
# 1. Clonar e entrar no diretório
cd Gerenciamento-Banco-de-dados_v2

# 2. Executar setup automatizado
./scripts-linux/1_setup_automatico.sh

# 3. Aguardar ~3-5 minutos
```

### Windows

```powershell
.\scripts-windows\1_setup_automatico.ps1
```

---

## 📂 Estrutura do Projeto

```
├── datasets/                    # CSVs com dados (217MB)
├── doc/                         # Dicionário de dados
├── scripts/
│   ├── 1-setup/                 # Setup e ETL
│   ├── 2-analise/               # Scripts de análise
│   ├── 2-consultas/             # Visualização
│   └── 3-manutencao/            # Manutenção
├── scripts-linux/               # Automação Linux
├── scripts-windows/             # Automação Windows
├── README.md                    # Este arquivo
├── SETUP.md                     # Guia detalhado
└── QUERIES_PRONTAS.md           # Exemplos de queries
```

---

## 💾 Databases

### FinanceDB (Modelo Dimensional)

| Tabela | Registros | Descrição |
|--------|-----------|-----------|
| Empresas | 500 | Empresas do S&P 500 |
| Tempo | 2.515 | Dimensão temporal |
| PrecoAcao | 499.982 | Preços históricos |
| SubSetor | 500 | Classificação setorial |
| Localizacao | 500 | Localização |
| Indice | 1 | Índices |
| IndiceSP500 | 2.515 | Valores do S&P 500 |
| Dividendos | 0 | Preparada para futuro |

### datasets (Dados Brutos)

| Tabela | Registros | Descrição |
|--------|-----------|-----------|
| SP500_data | 499.982 | S&P 500 consolidado |
| CSI500 | 865.898 | Mercado chinês |

### Views de Análise

| View | Registros | Descrição |
|------|-----------|-----------|
| vw_ValorizacaoAcoes | 422 | Valorização 6 meses |
| vw_VolatilidadeSetor | 11 | Volatilidade/setor |
| vw_VolumeNegociacao | 500 | Volume negociação |
| vw_EvolucaoSP500Mensal | 2.512 | Evolução mensal |
| vw_EmpresasPorSetor | 11 | Distribuição setorial |
| vw_ResumoDesempenhoEmpresas | 500 | Resumo completo |

---

## 📊 Análises Disponíveis

### S&P 500

1. ✅ Maior Valorização - Top 20 ações
2. ✅ Volatilidade por Setor
3. ✅ Volume de Negociação
4. ✅ Evolução do Índice
5. ✅ Distribuição Setorial

### CSI500

1. ✅ Maior Valorização
2. ✅ Volatilidade por Indústria
3. ✅ Volume de Negociação
4. ✅ Distribuição por Indústria

---

## 🔧 Uso

### Conectar via DataGrip

```
Host: localhost
Port: 1433
User: SA
Password: Cc202505!
Databases: FinanceDB, datasets
```

### Queries Rápidas

```sql
-- Top 10 valorizações
USE FinanceDB;
SELECT TOP 10 * FROM vw_ValorizacaoAcoes
ORDER BY ValorizacaoPercentual DESC;

-- Setores voláteis
SELECT * FROM vw_VolatilidadeSetor
ORDER BY VolatilidadeAnualizada_Pct DESC;
```

Ver mais: [QUERIES_PRONTAS.md](QUERIES_PRONTAS.md)

### Comandos Docker

```bash
# Status
docker compose ps

# Logs
docker logs sqlserverCC --tail 50

# Parar
docker compose down

# Reiniciar
docker restart sqlserverCC
```

---

## 🔍 Troubleshooting

### Container não inicia

```bash
docker compose down -v
docker compose up -d
sleep 60
```

### Erro autenticação

```bash
docker inspect sqlserverCC | grep MSSQL_SA_PASSWORD
```

### Reimportar dados

```bash
./scripts-linux/4_limpar.sh
./scripts-linux/1_setup_automatico.sh
```

---

## 📚 Documentação

- **[SETUP.md](SETUP.md)** - Guia detalhado
- **[QUERIES_PRONTAS.md](QUERIES_PRONTAS.md)** - Exemplos
- **doc/** - Dicionário de dados

---

## 📈 Métricas

| Métrica | Valor |
|---------|-------|
| Total Registros | ~1.3M |
| Empresas S&P 500 | 500 |
| Empresas CSI500 | 479 |
| Período | 2015-2025 |
| Databases | 2 |
| Tabelas | 10 |
| Views | 6 |

---

**Status:** ✅ Funcionando
**Versão:** 2.0
**Atualização:** 2025-11-09
