# Gerenciamento-Banco-de-dados
## start the database in docker
```bash
docker run --name sqlserverCC -v ~/docker -e "ACCEPT_EULA=Y" -e "MSSQL_SA_PASSWORD=Cc202505!" -e "MSSQL_PID=Express" -p 1433:1433 -d mcr.microsoft.com/mssql/server:2022-latest
```
ou use o compose, clone o repositorio, abra o terminal dentro do diretorio e execute
```bash
docker compose up -d && docker ps
```

---

### database manager
- [sql server management studio](https://learn.microsoft.com/en-us/ssms/install/install)
- [dbeaver](https://dbeaver.io/)

#### Login default
```bash
user: sa
password: Cc202505!
```

# Dados
[Stock Market Dataset](https://www.kaggle.com/datasets/jacksoncrow/stock-market-dataset)
[S&P 500 stock data](https://www.kaggle.com/datasets/camnugent/sandp500)
[Financial_Markets](https://www.kaggle.com/datasets/regaipkurt/financial-markets)

### Perguntas
Quais ações tiveram maior valorização percentual no último ano?

Qual é a volatilidade média das ações por setor ou indústria?

Quais empresas registraram maior volume de negociação em determinado período?

Existe correlação entre o preço das ações e o volume de negociações?

Quais ações apresentaram crescimento consistente ao longo dos últimos 5 anos?

Quais setores apresentam melhor desempenho médio no índice S&P 500?

Quais ações sofreram maior queda em períodos de crise econômica?

Qual é o retorno médio de dividendos por setor e por empresa?


