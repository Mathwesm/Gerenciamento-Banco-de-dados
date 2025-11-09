# 📊 Sistema de Análise Financeira - S&P 500 & CSI500

Sistema completo de análise de dados financeiros com SQL Server 2022 usando Docker.

## 🎯 Estrutura do Projeto

```
├── databases/
│   ├── FinanceDB       → Modelo dimensional (8 tabelas)
│   └── datasets        → Dados brutos (2 tabelas)
│
├── scripts/
│   ├── 1-setup/        → Scripts de criação e ETL
│   ├── 2-analise/      → Scripts de análise financeira
│   ├── 2-consultas/    → Scripts de visualização
│   └── 3-manutencao/   → Scripts de manutenção
│
└── scripts-linux/      → Automação de setup
```

## 📦 Databases

### FinanceDB (Modelo Dimensional)
- `Empresas` (500 empresas do S&P 500)
- `Tempo` (2.515 dias com dados)
- `PrecoAcao` (~500k registros de preços)
- `SubSetor` (classificação de indústrias)
- `Localizacao` (localização das empresas)
- `Indice` (índices de mercado)
- `IndiceSP500` (valores históricos do S&P 500)
- `Dividendos` (preparada para dados futuros)

### datasets (Dados Brutos)
- `SP500_data` (~500k registros consolidados)
- `CSI500` (~866k registros do mercado chinês)

## 🚀 Setup Rápido

### Opção 1: Setup Automatizado (Recomendado)

```bash
# Executar script de automação
./scripts-linux/1_setup_automatico.sh
```

O script automaticamente:
1. ✅ Verifica pré-requisitos
2. ✅ Inicia container Docker
3. ✅ Aguarda SQL Server inicializar
4. ✅ Cria databases e tabelas
5. ✅ Importa ~1.3M registros
6. ✅ Executa ETL completo
7. ✅ Valida instalação

### Opção 2: Setup Manual

```bash
# 1. Iniciar container
docker compose up -d

# 2. Aguardar 60 segundos
sleep 60

# 3. Executar setup
docker cp scripts/1-setup/01_setup_completo.sql sqlserverCC:/tmp/01_setup_completo.sql
docker exec sqlserverCC /opt/mssql-tools18/bin/sqlcmd -S localhost -U SA -P "Cc202505!" -i /tmp/01_setup_completo.sql -C

# 4. Executar ETL
docker cp scripts/1-setup/02_processar_dados_etl.sql sqlserverCC:/tmp/02_processar_dados_etl.sql
docker exec sqlserverCC /opt/mssql-tools18/bin/sqlcmd -S localhost -U SA -P "Cc202505!" -i /tmp/02_processar_dados_etl.sql -C
```

## 📊 Scripts de Análise

### Análise S&P 500
```bash
docker cp scripts/2-analise/01_analise_sp500.sql sqlserverCC:/tmp/analise.sql
docker exec sqlserverCC /opt/mssql-tools18/bin/sqlcmd -S localhost -U SA -P "Cc202505!" -i /tmp/analise.sql -C
```

**Perguntas respondidas:**
1. ✅ Quais ações tiveram maior valorização?
2. ✅ Qual é a volatilidade por setor?
3. ✅ Empresas com maior volume de negociação?
4. ✅ Evolução do índice S&P 500?
5. ✅ Distribuição de empresas por setor?

### Análise CSI500
```bash
docker cp scripts/2-analise/02_analise_csi500.sql sqlserverCC:/tmp/analise_csi.sql
docker exec sqlserverCC /opt/mssql-tools18/bin/sqlcmd -S localhost -U SA -P "Cc202505!" -i /tmp/analise_csi.sql -C
```

**Perguntas respondidas:**
1. ✅ Ações com maior valorização (mercado chinês)
2. ✅ Volatilidade por indústria
3. ✅ Maior volume de negociação
4. ✅ Distribuição por indústria

## 🔧 Configuração DataGrip

```
Host: localhost
Port: 1433
User: SA
Password: Cc202505!
Databases: FinanceDB + datasets
```

**Após conectar:**
1. Refresh (F5)
2. Navegue até FinanceDB e datasets
3. Execute queries diretamente dos scripts

## 📈 Dados Disponíveis

| Métrica | Valor |
|---------|-------|
| **Empresas S&P 500** | 500 |
| **Empresas CSI500** | 479 |
| **Registros de Preços** | ~500k |
| **Período de Dados** | 2015-09-09 a 2025-11-07 |
| **Total de Registros** | ~1.3M |
| **Indústrias** | 56+ |

## 🛠️ Comandos Úteis

```bash
# Status do container
docker compose ps

# Ver logs
docker logs sqlserverCC --tail 50

# Parar container
docker compose down

# Reiniciar container
docker restart sqlserverCC

# Acessar SQL diretamente
docker exec -it sqlserverCC /opt/mssql-tools18/bin/sqlcmd -S localhost -U SA -P "Cc202505!" -C
```

## 🧹 Manutenção

### Limpar dados (mantém estrutura)
```bash
docker cp scripts/3-manutencao/limpar_dados.sql sqlserverCC:/tmp/limpar.sql
docker exec sqlserverCC /opt/mssql-tools18/bin/sqlcmd -S localhost -U SA -P "Cc202505!" -i /tmp/limpar.sql -C
```

### Visualizar dados
```bash
docker cp scripts/2-consultas/visualizar_tabelas.sql sqlserverCC:/tmp/visualizar.sql
docker exec sqlserverCC /opt/mssql-tools18/bin/sqlcmd -S localhost -U SA -P "Cc202505!" -i /tmp/visualizar.sql -C
```

## 📋 Estrutura de Arquivos

```
scripts/
├── 1-setup/
│   ├── 01_setup_completo.sql       # Cria databases, tabelas e importa CSVs
│   └── 02_processar_dados_etl.sql  # ETL - processa dados brutos
│
├── 2-analise/
│   ├── 01_analise_sp500.sql        # 5 análises do S&P 500
│   └── 02_analise_csi500.sql       # 4 análises do CSI500
│
├── 2-consultas/
│   └── visualizar_tabelas.sql      # Visualização de todas as tabelas
│
└── 3-manutencao/
    └── limpar_dados.sql            # Limpeza de dados
```

## ⚠️ Troubleshooting

### Container não inicia
```bash
docker compose down -v
docker compose up -d
sleep 60
```

### Erro de autenticação
```bash
# Verificar senha no container
docker inspect sqlserverCC | grep MSSQL_SA_PASSWORD
```

### Reimportar dados
```bash
# Limpar
docker cp scripts/3-manutencao/limpar_dados.sql sqlserverCC:/tmp/limpar.sql
docker exec sqlserverCC /opt/mssql-tools18/bin/sqlcmd -S localhost -U SA -P "Cc202505!" -i /tmp/limpar.sql -C

# Reimportar
./scripts-linux/1_setup_automatico.sh
```

## 📚 Referências

- **SQL Server 2022** - Express Edition
- **Docker** - Container runtime
- **DataGrip** - IDE SQL da JetBrains

## 🎓 Perguntas de Análise

As análises respondem a seguintes perguntas de negócio:

1. **Valorização** - Quais ações tiveram maior retorno?
2. **Volatilidade** - Quais setores/indústrias são mais voláteis?
3. **Liquidez** - Quais empresas têm maior volume de negociação?
4. **Tendências** - Como evoluiu o índice S&P 500?
5. **Distribuição** - Como as empresas se distribuem por setor?

---

**Status:** ✅ Funcionando
**Última atualização:** 2025-11-09
**Versão:** 2.0
