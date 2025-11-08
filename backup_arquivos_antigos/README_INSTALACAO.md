# 🚀 Guia de Instalação e Uso - 100% Funcional

**Guia completo para rodar o projeto sem erros**

---

## 📋 Índice

1. [Visão Geral](#-visão-geral)
2. [Pré-requisitos](#-pré-requisitos)
3. [Instalação Passo a Passo](#-instalação-passo-a-passo)
4. [Verificação](#-verificação)
5. [Como Usar no DataGrip](#-como-usar-no-datagrip)
6. [Solução de Problemas](#-solução-de-problemas)
7. [Estrutura Final](#-estrutura-final)

---

## 🎯 Visão Geral

Este projeto cria e popula dois databases SQL Server:

### Database **master**
8 tabelas de modelo dimensional:
- Indice, IndiceSP500, Empresas, SubSetor, Localizacao, Tempo, PrecoAcao, Dividendos

### Database **datasets**
3 tabelas com dados brutos (importados dos CSVs):
- SP500_companies (~1.500 registros)
- SP500_fred (~7.800 registros)
- CSI500 (~2.6 milhões de registros)

---

## 💻 Pré-requisitos

### 1. Docker Instalado

Verifique se o Docker está instalado:
```bash
docker --version
```

Deve mostrar algo como: `Docker version 20.x.x`

Se não tiver, instale: https://docs.docker.com/get-docker/

### 2. DataGrip Instalado

Download: https://www.jetbrains.com/datagrip/

### 3. Arquivos CSV

Verifique se os arquivos existem na pasta `datasets/`:
```bash
ls -lh datasets/
```

Deve mostrar:
- S&P-500-companies.csv
- S&P500-fred.csv
- CSI500-part-1.csv
- CSI500-part-2.csv

---

## 🔧 Instalação Passo a Passo

### PASSO 1: Entrar no Diretório do Projeto

```bash
cd /home/matheus/DataGripProjects/Gerenciamento-Banco-de-dados_v2
```

### PASSO 2: Iniciar o Container Docker

```bash
docker compose up -d
```

**Aguarde 30-60 segundos** para o SQL Server inicializar completamente.

Verifique se está rodando:
```bash
docker compose ps
```

Deve mostrar:
```
NAME          STATUS
sqlserverCC   Up X minutes
```

### PASSO 3: Copiar Script para o Container

```bash
docker cp scripts/01_setup_completo.sql sqlserverCC:/tmp/01_setup_completo.sql
```

### PASSO 4: Executar o Setup Completo

```bash
docker exec sqlserverCC /opt/mssql-tools18/bin/sqlcmd -S localhost -U SA -P "Cc202505!" -i /tmp/01_setup_completo.sql -C
```

**Tempo de execução**: 2-5 minutos

Você verá mensagens como:
```
INICIANDO SETUP DO PROJETO
Database datasets criado...
Tabela SP500_companies criada...
SP500_companies: Dados importados com sucesso!
...
SETUP COMPLETO FINALIZADO COM SUCESSO!
```

---

## ✅ Verificação

### Verificar Databases Criados

```bash
docker exec sqlserverCC /opt/mssql-tools18/bin/sqlcmd -S localhost -U SA -P "Cc202505!" -Q "SELECT name FROM sys.databases ORDER BY name" -C
```

Deve mostrar:
- datasets ✅
- master ✅
- model
- msdb
- tempdb

### Verificar Tabelas do Master

```bash
docker exec sqlserverCC bash -c "/opt/mssql-tools18/bin/sqlcmd -S localhost -U SA -P 'Cc202505!' -C <<'EOF'
USE master
GO
SELECT name FROM sys.tables WHERE type = 'U' AND name NOT LIKE 'spt%' AND name NOT LIKE 'MS%' ORDER BY name
GO
EOF"
```

Deve mostrar **8 tabelas**:
- Dividendos ✅
- Empresas ✅
- Indice ✅
- IndiceSP500 ✅
- Localizacao ✅
- PrecoAcao ✅
- SubSetor ✅
- Tempo ✅

### Verificar Dados Importados

```bash
docker exec sqlserverCC bash -c "/opt/mssql-tools18/bin/sqlcmd -S localhost -U SA -P 'Cc202505!' -C <<'EOF'
USE datasets
GO
SELECT 'SP500_companies' as Tabela, COUNT(*) as Total FROM SP500_companies
UNION ALL
SELECT 'SP500_fred', COUNT(*) FROM SP500_fred
UNION ALL
SELECT 'CSI500', COUNT(*) FROM CSI500
GO
EOF"
```

Deve mostrar:
- SP500_companies: ~1.500 registros ✅
- SP500_fred: ~7.800 registros ✅
- CSI500: ~2.600.000 registros ✅

---

## 📊 Como Usar no DataGrip

### PASSO 1: Criar Conexão

1. Abra o **DataGrip**
2. Clique em **"+" → Data Source → Microsoft SQL Server**
3. Configure:

| Campo | Valor |
|-------|-------|
| **Host** | localhost |
| **Port** | 1433 |
| **Authentication** | User & Password |
| **User** | SA |
| **Password** | Cc202505! |
| **Database** | master |

4. Clique em **"Test Connection"**
   - Se pedir para baixar drivers, clique em **"Download"**
5. Se a conexão for bem-sucedida, clique em **"OK"**

### PASSO 2: Configurar Schemas

1. Clique com **botão direito** na conexão criada
2. Selecione **"Properties"** ou **"Database Settings"**
3. Vá na aba **"Schemas"**
4. **Marque** os checkboxes:
   - ✅ datasets
   - ✅ master (já deve estar marcado)
5. Clique em **"Apply"** → **"OK"**

### PASSO 3: Atualizar Visualização

1. Clique com **botão direito** na conexão
2. Selecione **"Refresh"** (ou pressione **F5**)
3. Expanda a árvore:
   ```
   sqlserverCC
   ├── datasets
   │   └── dbo
   │       └── tables
   │           ├── CSI500
   │           ├── SP500_companies
   │           └── SP500_fred
   └── master
       └── dbo
           └── tables
               ├── Dividendos
               ├── Empresas
               ├── Indice
               ├── IndiceSP500
               ├── Localizacao
               ├── PrecoAcao
               ├── SubSetor
               └── Tempo
   ```

### PASSO 4: Executar Consultas

1. Abra o arquivo **`scripts/02_consultas.sql`**
2. **Selecione** uma query (com o mouse)
3. Pressione **Ctrl+Enter** ou clique no botão ▶
4. Veja os resultados na aba inferior

**Exemplo de consulta rápida:**
```sql
-- Ver resumo de dados
SELECT
    'SP500_companies' as Tabela,
    COUNT(*) as Total
FROM datasets.dbo.SP500_companies
UNION ALL
SELECT 'SP500_fred', COUNT(*) FROM datasets.dbo.SP500_fred
UNION ALL
SELECT 'CSI500', COUNT(*) FROM datasets.dbo.CSI500;
```

---

## 🔍 Solução de Problemas

### Problema 1: "Tabelas não aparecem no DataGrip"

**Solução 1 - Invalidar Cache:**
1. DataGrip → **File → Invalidate Caches...**
2. Marque todas as opções
3. Clique em **"Invalidate and Restart"**
4. Após reiniciar, faça **Refresh (F5)** na conexão

**Solução 2 - Reconfigurar Schemas:**
1. Botão direito na conexão → **Properties**
2. Aba **Schemas** → Marque **datasets** e **master**
3. **Apply** → **OK** → **Refresh (F5)**

**Solução 3 - Recriar Conexão:**
1. Delete a conexão atual
2. Crie uma nova seguindo o PASSO 1

### Problema 2: "Invalid object SP500_companies"

**Causa:** Você está executando a query no database errado (provavelmente no master)

**Solução:** Use o caminho completo nas queries:
```sql
-- ❌ Errado
SELECT * FROM SP500_companies;

-- ✅ Correto
SELECT * FROM datasets.dbo.SP500_companies;
```

Ou mude o database ativo:
```sql
USE datasets;
SELECT * FROM SP500_companies;
```

### Problema 3: "Container não está rodando"

**Verificar:**
```bash
docker compose ps
```

**Se estiver parado, iniciar:**
```bash
docker compose up -d
```

**Ver logs de erro:**
```bash
docker logs sqlserverCC
```

### Problema 4: "Erro ao importar dados"

**Re-executar setup:**
```bash
# Parar container
docker compose down

# Apagar volumes (CUIDADO: isso apaga TODOS os dados!)
docker volume prune

# Iniciar novamente
docker compose up -d

# Aguardar 1 minuto

# Re-executar setup
docker cp scripts/01_setup_completo.sql sqlserverCC:/tmp/01_setup_completo.sql
docker exec sqlserverCC /opt/mssql-tools18/bin/sqlcmd -S localhost -U SA -P "Cc202505!" -i /tmp/01_setup_completo.sql -C
```

### Problema 5: "Login failed for user 'SA'"

**Causa:** O SQL Server ainda está inicializando

**Solução:** Aguarde 30-60 segundos e tente novamente

**Verificar se está pronto:**
```bash
docker logs sqlserverCC | grep "Server is listening"
```

Deve mostrar: `Server is listening on [ 0.0.0.0 <ipv4> 1433 ]`

---

## 📁 Estrutura Final

Após a instalação completa, você terá:

### Databases
- **master**: 8 tabelas vazias (prontas para receber dados via ETL)
- **datasets**: 3 tabelas com ~2.6M registros importados

### Arquivos de Scripts
```
scripts/
├── 01_setup_completo.sql       # ⭐ Setup completo (executar 1x)
├── 02_consultas.sql            # ⭐ Consultas prontas (usar no DataGrip)
├── create_tables_melhorado.sql # Backup: criar tabelas do master
├── insert_datasets.sql         # Backup: importar dados
└── ...
```

### Estatísticas
| Item | Quantidade |
|------|------------|
| Total de tabelas | 11 |
| Tabelas master | 8 |
| Tabelas datasets | 3 |
| Total de registros | ~2.600.000 |
| Empresas S&P 500 | ~1.500 |
| Registros CSI500 | ~2.600.000 |

---

## 🎯 Próximos Passos

1. ✅ **Setup completo** - CONCLUÍDO
2. ⏳ **Explorar dados** - Use `scripts/02_consultas.sql`
3. ⏳ **Criar ETL** - Popular tabelas do master
4. ⏳ **Criar views** - Facilitar análises
5. ⏳ **Criar dashboards** - Visualizar resultados

---

## 🛠️ Comandos Rápidos de Referência

### Docker
```bash
# Iniciar
docker compose up -d

# Parar
docker compose down

# Status
docker compose ps

# Logs
docker logs sqlserverCC

# Entrar no container
docker exec -it sqlserverCC bash
```

### SQL via Linha de Comando
```bash
# Listar databases
docker exec sqlserverCC /opt/mssql-tools18/bin/sqlcmd -S localhost -U SA -P "Cc202505!" -Q "SELECT name FROM sys.databases" -C

# Contar registros
docker exec sqlserverCC bash -c "/opt/mssql-tools18/bin/sqlcmd -S localhost -U SA -P 'Cc202505!' -C <<'EOF'
USE datasets
GO
SELECT COUNT(*) FROM SP500_companies
GO
EOF"
```

### DataGrip
| Ação | Atalho |
|------|--------|
| Refresh | F5 |
| Executar Query | Ctrl+Enter |
| Novo Console | Ctrl+Shift+F10 |
| Formatar SQL | Ctrl+Alt+L |

---

## 🔐 Credenciais

| Item | Valor |
|------|-------|
| Host | localhost |
| Porta | 1433 |
| Usuário | SA |
| Senha | Cc202505! |
| Database 1 | master |
| Database 2 | datasets |
| Container | sqlserverCC |

---

## 📞 Suporte

Se algo não funcionar:

1. ✅ Verifique os **pré-requisitos**
2. ✅ Siga o **passo a passo** na ordem exata
3. ✅ Consulte **Solução de Problemas**
4. ✅ Verifique os **logs**: `docker logs sqlserverCC`

---

**✨ Instalação 100% Funcional - Testada e Aprovada! ✨**

**Data**: 2025-11-07
**Autor**: Matheus
