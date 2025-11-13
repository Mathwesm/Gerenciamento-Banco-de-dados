# Sistema de Análise Financeira - S&P 500 & CSI500

Este repositório disponibiliza recursos para estruturar e explorar dados financeiros em um ambiente relacional, facilitando análises.

O objetivo é avaliar as situações do mercado financeiro americano e chines em situações de crise econômica.  Usando essa avaliação para prever como os mercados irá se portar em futuras situações de crise.

> Sistema completo de gerenciamento e análise de dados financeiros usando SQL Server 2022 no Docker

[![SQL Server](https://img.shields.io/badge/SQL%20Server-2022-red)](https://www.microsoft.com/sql-server)
[![Docker](https://img.shields.io/badge/Docker-Required-blue)](https://www.docker.com/)

---

## Índice

- [Visão Geral](#visão-geral)
- [Estrutura dos Datasets](#estrutura-dos-datasets)
- [Estrutura do Projeto](#estrutura-do-projeto)
- [Análises Disponíveis](#análises-disponíveis)
- [Principais Perguntas a serem respondidas](#principais-perguntas-a-serem-respondidas)
- [Datasets](#datasets)
- [Setup Ambiente](#setup-ambiente)
- [Backup](#backup)

---

## Visão Geral

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

---

## Estrutura do Projeto

```
├── datasets/                    # CSVs com dados (217MB)
├── doc/                         # Dicionário de dados
├── scripts/
│   ├── 1-setup/                 # Setup e ETL
│   ├── 2-analise/               # Scripts de análise
│   └── 2-consultas/             # Visualização
├── README.md                    # Este arquivo
└── compose.yaml                  
```
---

## Análises Disponíveis

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


## Datasets 
Link para os [Datasets](https://github.com/Mathwesm/Dataseat_SP500xCSI500)

---

## Setup Ambiente

### Configurando o ambiente
```
### Clone o repositório
git clone https://github.com/Mathwesm/Gerenciamento-Banco-de-dados.git

### Acesse o diretório do projeto
cd Gerenciamento-Banco-de-dados

### Suba os containers
docker compose up -d
```
---

## Backup
Link para o [Backup](https://drive.google.com/file/d/12Ea0lZDLdp9H-QQEvFtK0GG8EoHud99v/view?usp=sharing)



