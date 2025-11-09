# Guia de Setup - Gerenciamento de Banco de Dados

## Visão Geral

Este projeto contém um pipeline completo de setup para dois bancos de dados financeiros:
- **FinanceDB**: Dados do S&P 500 (modelo dimensional)
- **datasets**: Dados brutos do S&P 500 e CSI500 (mercado chinês)

## Pré-requisitos

- Docker rodando com container SQL Server (`sqlserverCC`)
- Script `setup.sh` na raiz do projeto
- Arquivos CSV em `datasets/`:
  - `sp500_data_part1.csv`
  - `sp500_data_part2.csv`
  - `CSI500-part-1.csv`
  - `CSI500-part-2.csv`

## Como Usar

### Opção 1: Execução Automática (Recomendado)

Execute o script de setup que faz tudo automaticamente:

```bash
cd /home/matheus/DataGripProjects/Gerenciamento-Banco-de-dados_v2
./setup.sh
```

Este script irá:
1. ✅ Criar diretório `/var/opt/mssql/datasets` no container
2. ✅ Copiar todos os CSVs para o container
3. ✅ Executar `01_setup_completo.sql` (cria tabelas e importa dados)
4. ✅ Executar `02_processar_dados_etl.sql` (processa dados e popula dimensões)
5. ✅ Exibir resumo final com contagem de registros

### Opção 2: Execução Manual (Passo a Passo)

Se preferir executar manualmente:

```bash
# 1. Copiar CSVs para o container
docker exec sqlserverCC mkdir -p /var/opt/mssql/datasets
docker cp datasets/sp500_data_part1.csv sqlserverCC:/var/opt/mssql/datasets/
docker cp datasets/sp500_data_part2.csv sqlserverCC:/var/opt/mssql/datasets/
docker cp datasets/CSI500-part-1.csv sqlserverCC:/var/opt/mssql/datasets/
docker cp datasets/CSI500-part-2.csv sqlserverCC:/var/opt/mssql/datasets/

# 2. Executar setup completo
docker cp scripts/1-setup/01_setup_completo.sql sqlserverCC:/tmp/
docker exec sqlserverCC /opt/mssql-tools18/bin/sqlcmd \
    -S localhost -U SA -P "Cc202505!" \
    -i /tmp/01_setup_completo.sql -C

# 3. Executar ETL
docker cp scripts/1-setup/02_processar_dados_etl.sql sqlserverCC:/tmp/
docker exec sqlserverCC /opt/mssql-tools18/bin/sqlcmd \
    -S localhost -U SA -P "Cc202505!" \
    -i /tmp/02_processar_dados_etl.sql -C
```

## Estrutura do Projeto

```
scripts/
├── 1-setup/
│   ├── 01_setup_completo.sql      # Cria tabelas e importa CSVs
│   ├── 02_processar_dados_etl.sql # Processa dados (ETL)
│   └── teste.sql                   # Testes
└── 2-analise/
    ├── 01_analise_sp500.sql        # Análises do S&P 500
    ├── 02_analise_csi500.sql       # Análises do CSI500
    ├── 03_criar_views_analise.sql  # Views para análises
    └── 04_perguntas_adicionais.sql # Perguntas específicas

datasets/
├── sp500_data_part1.csv   # Dados S&P 500 (primeira parte)
├── sp500_data_part2.csv   # Dados S&P 500 (segunda parte)
├── CSI500-part-1.csv      # Dados CSI500 (primeira parte)
└── CSI500-part-2.csv      # Dados CSI500 (segunda parte)
```

## Tabelas Criadas

### FinanceDB (Modelo Dimensional)

**Dimensões:**
- `Tempo` - Dimensão temporal com datas, anos, meses, etc
- `Empresas` - Informações das empresas do S&P 500
- `SubSetor` - Classificação de setores e subsetores
- `Localizacao` - Localização das sedes das empresas
- `EmpresasCSI500` - Empresas do índice chinês CSI500

**Fatos:**
- `PrecoAcao` - Histórico de preços das ações S&P 500
- `Dividendos` - Histórico de dividendos
- `PrecoAcaoCSI500` - Histórico de preços do CSI500

**Agregações:**
- `SP500Historico` - Índice S&P 500 ao longo do tempo
- `CSI500Historico` - Índice CSI500 ao longo do tempo

### datasets (Dados Brutos)

- `SP500_data` - Dados consolidados do S&P 500 (~500k registros)
- `SP500_data_Raw` - Tabela temporária para importação (limpada após conversão)
- `CSI500` - Dados do índice chinês (~865k registros)

## Resultados Esperados

Após a execução bem-sucedida, você deve ter:

```
S&P 500:
  - Tempo: 2.667 datas
  - Empresas: 151
  - PrecoAcao: 1.7M registros
  - Dividendos: 1.7M registros

CSI500:
  - EmpresasCSI500: 420+ empresas
  - PrecoAcaoCSI500: 6M+ registros
  - CSI500Historico: 2.400+ datas
```

## Troubleshooting

### Erro: "Cannot bulk load. The file does not exist"

**Solução:** Certifique-se de que executou `setup.sh` ou copiou manualmente os CSVs para o container:

```bash
./setup.sh
```

### Erro: "Unsafe query: 'Delete' statement without 'where'"

**Solução:** O projeto foi atualizado para usar `TRUNCATE` ao invés de `DELETE`. Verifique se você tem a última versão dos scripts SQL.

### Erro: "Violation of PRIMARY KEY constraint"

**Solução:** Se re-executar os scripts, limpe as tabelas primeiro usando o cleanup:

```bash
docker exec sqlserverCC /opt/mssql-tools18/bin/sqlcmd \
    -S localhost -U SA -P "Cc202505!" \
    -C <<'SQL'
USE FinanceDB;
GO
TRUNCATE TABLE CSI500Historico;
TRUNCATE TABLE PrecoAcaoCSI500;
TRUNCATE TABLE EmpresasCSI500;
GO
SQL
```

## Próximos Passos

1. **Explore os dados** usando DataGrip
2. **Execute análises** com os scripts em `scripts/2-analise/`
3. **Crie visualizações** baseado nas queries
4. **Responda perguntas** de negócio com os dados

## Conexão no DataGrip

**Banco: FinanceDB**
- Host: localhost
- Port: 1433
- User: SA
- Password: Cc202505!
- Database: FinanceDB

**Banco: datasets**
- Host: localhost
- Port: 1433
- User: SA
- Password: Cc202505!
- Database: datasets

## Contato/Suporte

Se encontrar problemas, verifique:
1. Se o Docker está rodando
2. Se o container SQL Server está rodando
3. Se os CSVs estão no diretório `datasets/`
4. Logs em `/tmp/setup_output.log` e `/tmp/etl_output.log`
