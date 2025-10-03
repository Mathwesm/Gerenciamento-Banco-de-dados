# Gerenciamento Banco de Dados - Análise Mercado Financeiro

## Objetivo

<p align="center">
  O objetivo é avaliar a situação do mercado financeiro americano e chinês em situações de crise econômica.<br />
  Usando essa avaliação para prever como o mercado irá se portar em futuras situações de crise.<br />
</p>

---

## Índice
- [Objetivo](#objetivo)
- [Perguntas de Negócio](#perguntas)
- [Datasets](#datasets)
- [Modelagem de Dados](#modelagem-de-dados)
- [Estrutura do Projeto](#estrutura-do-projeto)
- [Como Usar](#como-usar)
- [Planejamento](#planejamento)
- [Tecnologias Utilizadas](#tecnologias-utilizadas)
- [Contribuidores](#contribuidores)

## Perguntas
- Quais ações tiveram maior valorização percentual no último ano?

- Qual é a volatilidade média das ações por setor ou indústria?

- Quais empresas registraram maior volume de negociação em determinado período?

- Quais ações apresentaram crescimento consistente ao longo dos últimos 5 anos?

- Quais setores apresentam melhor desempenho médio no índice S&P 500?

- Quais ações sofreram maior queda em períodos de crise econômica? (Covid)

- Qual é o retorno médio de dividendos por setor e por empresa?


## Datasets

### Mercado Americano (S&P 500)
- **S&P 500 Index Data**
  - [Fonte oficial](https://fred.stlouisfed.org/series/SP500)
  - [CSV](datasets/S&P500-fred.csv)

- **S&P 500 Companies**
  - [Fonte oficial](https://github.com/datasets/s-and-p-500-companies/blob/main/data/constituents.csv)
  - [CSV](datasets/S&P-500-companies.csv)

### Mercado Chinês (CSI 500)
- **CSI 500 Stock Data Consolidado**
  - Dados históricos consolidados de ações do índice CSI 500
  - [Parte 1](datasets/csi500_consolidado_parte1.csv) (865k+ registros)
  - [Parte 2](datasets/csi500_consolidado_parte2.csv)

## Modelagem de Dados

O projeto utiliza modelagem dimensional (Data Warehouse) com os seguintes modelos para cada mercado:

### Mercado Americano (S&P 500)
- **[Modelo Conceitual](doc/SP500/Modelo-Conceitual-SP500.svg)** - Visão geral das entidades e relacionamentos
- **[Modelo Lógico](doc/SP500/Modelo-Logico-SP500.svg)** - Estrutura lógica das tabelas
- **[Modelo Físico](doc/SP500/Modelo-Fisico-SP500.svg)** - Implementação física no banco de dados

### Mercado Chinês (CSI 500)
- **[Modelo Conceitual](doc/CSI500/Modelo-Conceitual-CSI500.png)** - Visão geral das entidades e relacionamentos
- **[Modelo Lógico](doc/CSI500/Modelo-logico-CSI500.png)** - Estrutura lógica das tabelas
- **[Modelo Físico](doc/CSI500/Modelo-Fisico-CSI500.png)** - Implementação física no banco de dados

### Dicionário de Dados
O projeto possui um [dicionário de dados completo](doc/dicionario-de-dados.csv) descrevendo:
- Todas as tabelas (dimensões e fatos)
- Tipos de dados de cada campo
- Descrição detalhada de cada coluna
- Relacionamentos entre tabelas

## Estrutura do Projeto

```
├── datasets/                           # Datasets do projeto
│   ├── S&P500-fred.csv                 # Dados históricos do índice S&P 500
│   ├── S&P-500-companies.csv           # Lista de empresas do S&P 500
│   ├── csi500_consolidado_parte1.csv   # Dados CSI 500 (Parte 1 - 865k+ registros)
│   └── csi500_consolidado_parte2.csv   # Dados CSI 500 (Parte 2)
├── doc/                                # Documentação e modelos
│   ├── SP500/                          # Modelos do mercado americano
│   │   ├── Modelo-Conceitual-SP500.svg
│   │   ├── Modelo-Logico-SP500.svg
│   │   └── Modelo-Fisico-SP500.svg
│   ├── CSI500/                         # Modelos do mercado chinês
│   │   ├── Modelo-Conceitual-CSI500.png
│   │   ├── Modelo-logico-CSI500.png
│   │   └── Modelo-Fisico-CSI500.png
│   └── dicionario-de-dados.csv         # Dicionário de dados completo
├── scripts/                            # Scripts SQL
│   ├── create_datasets.sql             # Criação das tabelas
│   └── Script_SP500.sql                # Queries de análise S&P 500
└── README.md                           # Documentação do projeto
```

## Como Usar

### Pré-requisitos
- Sistema de Gerenciamento de Banco de Dados (MySQL, PostgreSQL, SQL Server, etc.)
- Ferramenta para importação de arquivos CSV

### Instalação

1. **Clone o repositório**
   ```bash
   git clone https://github.com/seu-usuario/Gerenciamento-Banco-de-dados.git
   cd Gerenciamento-Banco-de-dados
   ```

2. **Crie o banco de dados**
   ```sql
   CREATE DATABASE analise_mercado_financeiro;
   USE analise_mercado_financeiro;
   ```

3. **Execute os scripts de criação**
   ```bash
   # Execute o script de criação das tabelas
   mysql -u seu_usuario -p analise_mercado_financeiro < scripts/create_datasets.sql
   ```

4. **Importe os datasets**
   - Importe os arquivos CSV da pasta `datasets/` para as respectivas tabelas
   - Utilize as ferramentas de importação do seu SGBD ou scripts ETL

5. **Execute as análises**
   ```bash
   # Execute as queries de análise
   mysql -u seu_usuario -p analise_mercado_financeiro < scripts/Script_SP500.sql
   ```

## Planejamento

O gerenciamento do projeto é feito através do **Trello** utilizando metodologia **SCRUM**:
- [Board de Planejamento (Trello)](https://trello.com/invite/b/KkIiciFk/ATTIc77290b98b15e3589e6f2e7ea4d9dad3915E3CA4/gest-o-de-tarefas-scrum)

## Tecnologias Utilizadas

- **Banco de Dados**: SQL (MySQL/PostgreSQL/SQL Server)
- **Modelagem**: Data Warehouse (Esquema Estrela/Floco de Neve)
- **Visualização de Modelos**: Draw.io, ferramentas de modelagem ER
- **Gerenciamento de Projeto**: Trello (Metodologia SCRUM)
- **Controle de Versão**: Git/GitHub

## Contribuidores

Este projeto foi desenvolvido como parte da disciplina de Gerenciamento de Banco de Dados.

---

**📊 Análise de Mercado Financeiro - S&P 500 & CSI 500**
