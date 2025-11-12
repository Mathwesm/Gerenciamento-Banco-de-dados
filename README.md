# 📊 Sistema de Análise Financeira - S&P 500 & CSI500

Este repositório disponibiliza recursos para estruturar, gerenciar e explorar dados financeiros em um ambiente relacional, facilitando análises e tomadas de decisão baseadas em indicadores econômicos.

O objetivo é avaliar as situações do mercado financeiro americano e chines em situações de crise econômica.  Usando essa avaliação para prever como os mercados irá se portar em futuras situações de crise.

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

---

## Estrutura dos Datasets

Os datasets apresentam várias informações sobre as empresas, setores, preço da ação entre outros dados.

Exemplos:
-EmpresaID
-SubSetor
-Localização
-Preço Ação
-Dividendos
-TempoID
-IndiceID


## 📊 Análises Disponíveis

O projeto faz uso de um dataset financeiro real, que abrange dados sobre: 
### S&P 500

1. Maior Valorização - Top 20 ações
2. Volatilidade por Setor
3. Volume de Negociação
4. Evolução do Índice
5. Distribuição Setorial

### CSI500

1. Maior Valorização
2. Volatilidade por Indústria
3. Volume de Negociação
4. Distribuição por Indústria

---

## Principais Perguntas a serem respondidas

- Volatilidade média por setor do CSI 500
- Distribuição por Indústria do CSI 500
- Evolução do Índice CSI500
- Evolução do Índice S&P 500
- Setores com melhor desempenho médio no S&P 500
- Retorno médio de dividendos por setor e empresa S&P 500
- 

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

## 🔧 Uso

### Conectar via DataGrip

```
Host: localhost
Port: 1433
User: SA
Password: Cc202505!
Databases: FinanceDB, datasets
```
---

## 📚 Documentação

- **[SETUP.md](SETUP.md)** - Guia detalhado
- **[QUERIES_PRONTAS.md](QUERIES_PRONTAS.md)** - Exemplos
- **doc/** - Dicionário de dados

