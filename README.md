# Gerenciamento-Banco-de-dados
## start the database in docker
```bash
docker run --name sqlserverCC -v ~/docker -e "ACCEPT_EULA=Y" -e "MSSQL_SA_PASSWORD=Cc202505!" -e "MSSQL_PID=Express" -p 1433:1433 -d mcr.microsoft.com/mssql/server:2022-latest

```

### database manager
- [sql server management studio](https://learn.microsoft.com/en-us/ssms/install/install)
- [dbeaver](https://dbeaver.io/)

#### Login default
```bash
user: sa
password: Cc202505!
```
