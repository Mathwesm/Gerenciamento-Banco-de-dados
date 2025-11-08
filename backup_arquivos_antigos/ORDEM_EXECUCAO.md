# Ordem de Execução - Do Zero ao Funcionamento Completo

## Ordem Correta dos Passos

### PASSO 1: Verificar Pré-requisitos
```bash
# Verificar se Docker está instalado
docker --version

# Verificar se os arquivos CSV existem
ls -lh datasets/
```

Deve mostrar os arquivos:
- S&P-500-companies.csv
- S&P500-fred.csv
- CSI500-part-1.csv
- CSI500-part-2.csv

---

### PASSO 2: Iniciar Container Docker
```bash
# Entrar no diretório do projeto
cd /home/matheus/DataGripProjects/Gerenciamento-Banco-de-dados_v2

# Iniciar o container
docker compose up -d

# IMPORTANTE: Aguardar 30-60 segundos para o SQL Server inicializar
sleep 60

# Verificar se está rodando
docker compose ps
```

---

### PASSO 3: Copiar Script de Setup para o Container
```bash
docker cp scripts/01_setup_completo.sql sqlserverCC:/tmp/01_setup_completo.sql
```

---

### PASSO 4: Executar Setup Completo (Cria tudo)
```bash
docker exec sqlserverCC /opt/mssql-tools18/bin/sqlcmd -S localhost -U SA -P "Cc202505!" -i /tmp/01_setup_completo.sql -C
```

Este comando:
1. Cria o database **datasets**
2. Cria 3 tabelas no datasets (SP500_companies, SP500_fred, CSI500)
3. Importa os dados dos CSVs (~2.6M registros)
4. Cria 8 tabelas no database **master** (modelo dimensional)
5. Cria índices para performance

**Tempo estimado**: 2-5 minutos

---

### PASSO 5: Verificar Instalação

#### 5.1 - Verificar databases criados
```bash
docker exec sqlserverCC /opt/mssql-tools18/bin/sqlcmd -S localhost -U SA -P "Cc202505!" -Q "SELECT name FROM sys.databases ORDER BY name" -C
```

Deve mostrar: **datasets** e **master**

#### 5.2 - Verificar tabelas do master (8 tabelas)
```bash
docker exec sqlserverCC bash -c "/opt/mssql-tools18/bin/sqlcmd -S localhost -U SA -P 'Cc202505!' -C <<'EOF'
USE master
GO
SELECT name FROM sys.tables WHERE type = 'U' AND name NOT LIKE 'spt%' AND name NOT LIKE 'MS%' ORDER BY name
GO
EOF"
```

Deve mostrar:
- Dividendos
- Empresas
- Indice
- IndiceSP500
- Localizacao
- PrecoAcao
- SubSetor
- Tempo

#### 5.3 - Verificar dados importados
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
- SP500_companies: ~1.500 registros
- SP500_fred: ~7.800 registros
- CSI500: ~2.600.000 registros

---

### PASSO 6: Configurar DataGrip

#### 6.1 - Criar conexão
1. Abrir DataGrip
2. Clicar em **"+" → Data Source → Microsoft SQL Server**
3. Configurar:
   - **Host**: localhost
   - **Port**: 1433
   - **User**: SA
   - **Password**: Cc202505!
   - **Database**: master
4. Clicar em **"Test Connection"**
5. Se pedir drivers, clicar em **"Download"**
6. Clicar em **"OK"**

#### 6.2 - Configurar Schemas
1. Botão direito na conexão → **"Properties"**
2. Aba **"Schemas"**
3. Marcar checkboxes:
   - ✅ datasets
   - ✅ master
4. **Apply** → **OK**

#### 6.3 - Atualizar visualização
1. Botão direito na conexão → **"Refresh"** (ou F5)
2. Verificar se aparecem as 11 tabelas (8 no master + 3 no datasets)

---

### PASSO 7: Testar Consultas

Abrir arquivo **scripts/02_consultas.sql** no DataGrip e executar as queries.

Ou testar via linha de comando:
```bash
docker exec sqlserverCC bash -c "/opt/mssql-tools18/bin/sqlcmd -S localhost -U SA -P 'Cc202505!' -C <<'EOF'
USE datasets
GO
SELECT TOP 5 * FROM SP500_companies
GO
EOF"
```

---

## Resumo da Ordem de Execução

```
1. Verificar pré-requisitos (Docker + CSVs)
   ↓
2. Iniciar container (docker compose up -d)
   ↓
3. Aguardar 60 segundos
   ↓
4. Copiar script (docker cp)
   ↓
5. Executar setup completo (docker exec sqlcmd)
   ↓
6. Verificar instalação (comandos de verificação)
   ↓
7. Configurar DataGrip (conexão + schemas)
   ↓
8. Testar consultas
```

---

## Comandos em Sequência (Copy-Paste)

Para rodar tudo de uma vez:

```bash
# 1. Entrar no diretório
cd /home/matheus/DataGripProjects/Gerenciamento-Banco-de-dados_v2

# 2. Iniciar container
docker compose up -d

# 3. Aguardar inicialização
echo "Aguardando SQL Server inicializar (60 segundos)..."
sleep 60

# 4. Copiar script
docker cp scripts/01_setup_completo.sql sqlserverCC:/tmp/01_setup_completo.sql

# 5. Executar setup
docker exec sqlserverCC /opt/mssql-tools18/bin/sqlcmd -S localhost -U SA -P "Cc202505!" -i /tmp/01_setup_completo.sql -C

# 6. Verificar
echo "=== VERIFICANDO INSTALAÇÃO ==="
docker exec sqlserverCC /opt/mssql-tools18/bin/sqlcmd -S localhost -U SA -P "Cc202505!" -Q "SELECT name FROM sys.databases ORDER BY name" -C

echo "=== CONTAGEM DE REGISTROS ==="
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

echo "=== SETUP COMPLETO! ==="
echo "Agora configure o DataGrip conforme o PASSO 6"
```

---

## Troubleshooting Rápido

### Se der erro no PASSO 4:
```bash
# Verificar se o SQL Server está pronto
docker logs sqlserverCC | grep "Server is listening"

# Se não aparecer nada, aguardar mais tempo
sleep 30
```

### Se der erro "Invalid object":
Use o caminho completo nas queries:
```sql
-- Correto
SELECT * FROM datasets.dbo.SP500_companies;
```

### Para reiniciar do zero:
```bash
# Parar e apagar tudo
docker compose down -v

# Recomeçar do PASSO 2
docker compose up -d
```

---

## Estrutura Final Esperada

```
Databases:
├── master (8 tabelas vazias)
│   ├── Dividendos
│   ├── Empresas
│   ├── Indice
│   ├── IndiceSP500
│   ├── Localizacao
│   ├── PrecoAcao
│   ├── SubSetor
│   └── Tempo
└── datasets (3 tabelas com dados)
    ├── SP500_companies (~1.500 registros)
    ├── SP500_fred (~7.800 registros)
    └── CSI500 (~2.600.000 registros)

Total: 11 tabelas | ~2.6M registros
```

---

**Data**: 2025-11-07
**Status**: 100% Funcional
