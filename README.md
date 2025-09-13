# Gerenciamento Banco de Dados - Análise Mercado Financeiro

## Objetivo

<p align="center">
  O objetivo é avaliar a situação do mercado financeiro americano e chinês em situações de crise econômica.<br />
  Usando essa avaliação para prever como o mercado irá se portar em futuras situações de crise.<br />
</p>

---

## Índice
- [Perguntas](#perguntas)
- [Datasets](#datasets)
- [Estrutura do Projeto](#estrutura-do-projeto)
- [Planejamento](#planejamento)

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

## Estrutura do Projeto

```
├── datasets/                    # Datasets do projeto
│   ├── S&P500-fred.csv         # Dados históricos do índice S&P 500
│   ├── S&P-500-companies.csv   # Lista de empresas do S&P 500
│   ├── csi500_consolidado_parte1.csv  # Dados CSI 500 (Parte 1)
│   └── csi500_consolidado_parte2.csv  # Dados CSI 500 (Parte 2)
├── doc/                        # Documentação e modelos
│   ├── modelo-conceitual.drawio.svg
│   ├── ModeloLogico.svg
│   └── ModeloFisico.svg
├── scripts/                    # Scripts SQL e de análise
└── README.md                   # Documentação do projeto
```

## Planejamento
- [Planner](https://trello.com/invite/b/KkIiciFk/ATTIc77290b98b15e3589e6f2e7ea4d9dad3915E3CA4/gest-o-de-tarefas-scrum)
- [Modelo Conceitual](doc/modelo-conceitual.drawio.svg)
- [Modelo Lógico](doc/ModeloLogico.svg)
- [Modelo Físico](doc/ModeloFisico.svg)
