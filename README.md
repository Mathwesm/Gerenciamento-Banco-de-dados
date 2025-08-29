## Objetivo

---

<p align="center">
  O objetivo é avaliar a situação do mercado financeiro americano em situações de crise econômica.<br />
  Usando essa avaliação para prever como o mercado irá se portar em futuras situações de crise.<br />
</p>

---

## Índice
- [Perguntas](#perguntas)
- [Datasets](#datasets)
- [Planejamento](#planejamento)
- [Configuração](#configuração-recomendada)
  - [Iniciando Instância do Container](#iniciando-instância-do-container)

## Perguntas
- Quais ações tiveram maior valorização percentual no último ano?

- Qual é a volatilidade média das ações por setor ou indústria?

- Quais empresas registraram maior volume de negociação em determinado período?

- Quais ações apresentaram crescimento consistente ao longo dos últimos 5 anos?

- Quais setores apresentam melhor desempenho médio no índice S&P 500?

- Quais ações sofreram maior queda em períodos de crise econômica? (Covid)

- Qual é o retorno médio de dividendos por setor e por empresa?


## Datasets
- S&P 500 Fred
  - [Fonte oficial](https://fred.stlouisfed.org/series/SP500)
  - [CSV](datasets/S&P500-fred.csv)
  
- S&P 500 Companies
  - [Fonte oficial](https://github.com/datasets/s-and-p-500-companies/blob/main/data/constituents.csv)
  - [CSV](datasets/S&P-500-companies.csv)
  
- S&P 500 Stock Data
  - [Fonte oficial](https://www.kaggle.com/datasets/camnugent/sandp500)
<!-- [CSV]() -->

## Planejamento
- [Planner](https://trello.com/invite/b/KkIiciFk/ATTIc77290b98b15e3589e6f2e7ea4d9dad3915E3CA4/gest-o-de-tarefas-scrum)
- [Banco de dados - modelo fisico](https://drive.google.com/file/d/1AMSSVLgTu009XKA2OgShzxKs-iADlm3w/view?usp=sharing)

---

### Configuração Recomendada
O uso do Docker é essencial, pois torna a configuração trivial e permite o uso de scripts para automatizar diversas tarefas.<br />
Existem duas formas de iniciar o banco de dados SQL Server: utilizando docker run ou docker compose.<br />
É recomendável utilizar a segunda opção, pois o docker compose permite a execução de scripts automaticamente durante a montagem do container.<br />

### Requisitos
- Docker
- Docker compose
- Docker Desktop
- Gerenciador de banco de dados de sua preferencia
  - [sql server management studio](https://learn.microsoft.com/en-us/ssms/install/install) 
  - [dbeaver](https://dbeaver.io/)



### Windows
A maneira mais fácil e recomendada de obter o Docker é instalar o Docker Desktop.
- [Docker Desktop](https://docs.docker.com/desktop/setup/install/windows-install/)

### Linux
para Linux é necessario instalar individualmente cada pacote.
- [Docker Engine](https://docs.docker.com/engine/install/)
- [Docker Desktop](https://docs.docker.com/desktop/setup/install/linux/)

### Iniciando Instância do Container
> ⚠️ **Atenção: Verifique a virtualização da CPU**
> Para que o `SQL Server` funcione corretamente em containers, é necessário que a **virtualização esteja habilitada** no BIOS/UEFI da sua máquina.
>
> Caso contrário, o Docker pode falhar ao iniciar o container, especialmente em sistemas que usam **Hyper-V** ou **WSL2** no Windows.

Docker Run
```bash
docker run --name sqlserverCC -v ~/docker -e "ACCEPT_EULA=Y" -e "MSSQL_SA_PASSWORD=Cc202505!" -e \
"MSSQL_PID=Express" -p 1433:1433 -d mcr.microsoft.com/mssql/server:2022-latest
```
Docker Compose
```bash
git clone https://github.com/Mathwesm/Gerenciamento-Banco-de-dados.git db
cd db
docker compose up -d
docker ps
```
A instância do container é iniciada com um login padrão
- Usuario: `sa`
- Senha: `Cc202505!`
