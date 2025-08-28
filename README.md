# Objetivo do Projeto
O objetivo é avaliar a situação do mercado financeiro americano em situações de crise econômica.  Usando essa avaliação para prever como o mercado irá se portar em futuras situações de crise.
### Perguntas
```
Quais ações tiveram maior valorização percentual no último ano?

Qual é a volatilidade média das ações por setor ou indústria?

Quais empresas registraram maior volume de negociação em determinado período?

Quais ações apresentaram crescimento consistente ao longo dos últimos 5 anos?

Quais setores apresentam melhor desempenho médio no índice S&P 500?

Quais ações sofreram maior queda em períodos de crise econômica? (Covid)

Qual é o retorno médio de dividendos por setor e por empresa?
```

### Datasets
- [S&P 500](https://fred.stlouisfed.org/series/SP500)
- [S&P 500 stock data](https://www.kaggle.com/datasets/camnugent/sandp500)
- [S&P 500 companies](https://github.com/datasets/s-and-p-500-companies/blob/main/data/constituents.csv)

---

##Trello

link:https://trello.com/invite/b/KkIiciFk/ATTIc77290b98b15e3589e6f2e7ea4d9dad3915E3CA4/gest-o-de-tarefas-scrum-

---

## Docker
###### start database
```bash
docker run --name sqlserverCC -v ~/docker -e "ACCEPT_EULA=Y" -e "MSSQL_SA_PASSWORD=Cc202505!" -e "MSSQL_PID=Express" -p 1433:1433 -d mcr.microsoft.com/mssql/server:2022-latest
```
ou use o compose, clone o repositorio, abra o terminal dentro do diretorio e execute
```bash
docker compose up -d
docker ps
```

##### database manager
- [sql server management studio](https://learn.microsoft.com/en-us/ssms/install/install)
- [dbeaver](https://dbeaver.io/)

##### Login default
```bash
user: sa
password: Cc202505!
```



