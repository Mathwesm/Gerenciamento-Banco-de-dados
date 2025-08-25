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
[Airbnb Open Data](https://www.kaggle.com/datasets/arianazmoudeh/airbnbopendata/data)

### Perguntas
O que podemos aprender sobre diferentes anfitriões e áreas?

O que podemos aprender com as previsões? (ex: locais, preços, avaliações, etc.)

Quais hosts são os mais ocupados e por quê?
