# 🔧 Guia de Solução de Problemas (Troubleshooting)

**Guia completo para resolver todos os problemas possíveis**

---

## 📋 Índice de Problemas

1. [Problemas com Docker](#1-problemas-com-docker)
2. [Problemas com DataGrip](#2-problemas-com-datagrip)
3. [Problemas com Importação](#3-problemas-com-importação)
4. [Problemas com Queries](#4-problemas-com-queries)
5. [Problemas de Conexão](#5-problemas-de-conexão)
6. [Reset Completo](#6-reset-completo)

---

## 1. Problemas com Docker

### 1.1 Container não inicia

**Sintomas:**
```bash
docker compose up -d
# Erro: container exits immediately
```

**Diagnóstico:**
```bash
docker logs sqlserverCC
```

**Soluções:**

**Solução A - Porta ocupada:**
```bash
# Verificar se a porta 1433 está em uso
sudo lsof -i :1433

# Se estiver ocupada, parar o serviço ou mudar a porta no compose.yaml
docker compose down
# Editar compose.yaml e mudar "1433:1433" para "1434:1433"
docker compose up -d
```

**Solução B - Permissões:**
```bash
# Verificar permissões da pasta datasets
ls -la datasets/

# Corrigir se necessário
chmod 755 datasets/
chmod 644 datasets/*.csv
```

**Solução C - Memória insuficiente:**
```bash
# Verificar memória disponível
free -h

# SQL Server precisa de pelo menos 2GB de RAM
# Se não tiver, aumentar swap ou liberar memória
```

### 1.2 Container reinicia constantemente

**Diagnóstico:**
```bash
docker compose ps
# Se mostrar "Restarting", há um problema

docker logs sqlserverCC | tail -50
```

**Solução:**
```bash
# Parar tudo
docker compose down

# Limpar volumes
docker volume ls
docker volume prune -f

# Reiniciar
docker compose up -d

# Aguardar 60 segundos e verificar
sleep 60
docker compose ps
```

### 1.3 "Cannot connect to Docker daemon"

**Solução:**
```bash
# Iniciar Docker
sudo systemctl start docker

# Habilitar para iniciar com o sistema
sudo systemctl enable docker

# Verificar status
sudo systemctl status docker
```

---

## 2. Problemas com DataGrip

### 2.1 Tabelas não aparecem na árvore

**Este é o problema mais comum!**

**Solução 1 - Invalidar cache (MAIS EFETIVA):**
1. DataGrip → **File → Invalidate Caches...**
2. Marque **TODAS** as opções
3. Clique em **"Invalidate and Restart"**
4. Aguarde o DataGrip reiniciar
5. Conecte novamente
6. Faça **Refresh (F5)** na conexão

**Solução 2 - Configurar schemas:**
1. Botão direito na conexão → **"Properties"**
2. Aba **"Schemas"** ou **"Options"**
3. Procure por "Schemas to introspect" ou similar
4. **Marque** os checkboxes:
   - ✅ datasets
   - ✅ dbo (dentro de datasets)
   - ✅ master
   - ✅ dbo (dentro de master)
5. Clique em **"Apply"** → **"OK"**
6. Botão direito na conexão → **"Refresh" (F5)**

**Solução 3 - Forget Cached Schemas:**
1. Botão direito na conexão
2. **"Database Tools" → "Forget Cached Schemas"**
3. Depois: **"Refresh" (F5)**

**Solução 4 - Recriar conexão:**
1. Delete a conexão atual (botão direito → Delete)
2. Crie uma nova:
   - Host: localhost
   - Port: 1433
   - User: SA
   - Password: Cc202505!
   - Database: deixe vazio ou use "master"
3. Test Connection → OK
4. Configure schemas (Solução 2)

**Solução 5 - Verificar via SQL:**

Se as tabelas não aparecem mas as queries funcionam, é apenas problema visual:

```sql
-- Executar no console SQL do DataGrip
USE datasets;
SELECT * FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_TYPE = 'BASE TABLE';

-- Deve mostrar as 3 tabelas
```

### 2.2 "Driver not found" ou "Download driver"

**Solução:**
1. Ao criar a conexão, clique em **"Test Connection"**
2. Se pedir para baixar o driver, clique em **"Download"**
3. Aguarde o download completar
4. Tente novamente

**Se o download falhar:**
1. DataGrip → **File → Settings**
2. **Tools → Database → Drivers**
3. Selecione **"Microsoft SQL Server"**
4. Clique em **"Download missing driver files"**

### 2.3 DataGrip lento ao conectar

**Solução:**
1. Botão direito na conexão → **Properties**
2. Aba **"Advanced"**
3. Ajustar:
   - **Introspection level**: Basic
   - **Introspection depth**: 1
4. **Apply** → **OK**

---

## 3. Problemas com Importação

### 3.1 "Cannot open bulk load file"

**Causa:** Arquivos CSV não estão acessíveis dentro do container

**Diagnóstico:**
```bash
# Verificar se os CSVs estão montados
docker exec sqlserverCC ls -la /datasets/
```

**Solução A - Volume não montado:**
```bash
# Parar container
docker compose down

# Verificar compose.yaml
cat compose.yaml | grep datasets

# Deve ter:
# - ./datasets:/datasets:Z

# Se não tiver, adicionar e reiniciar
docker compose up -d
```

**Solução B - Arquivos com nomes errados:**
```bash
# Verificar nomes exatos
docker exec sqlserverCC ls /datasets/

# Os nomes devem ser EXATAMENTE:
# - S&P-500-companies.csv
# - S&P500-fred.csv
# - CSI500-part-1.csv
# - CSI500-part-2.csv

# Renomear se necessário
```

### 3.2 "Importação parcial" (alguns arquivos importam, outros não)

**Diagnóstico:**
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

**Se alguma tabela tiver 0 registros:**

```bash
# Re-importar manualmente
docker exec sqlserverCC bash -c "/opt/mssql-tools18/bin/sqlcmd -S localhost -U SA -P 'Cc202505!' -C <<'EOF'
USE datasets
GO

BULK INSERT SP500_companies
FROM '/datasets/S&P-500-companies.csv'
WITH (
    FIRSTROW = 2,
    FIELDTERMINATOR = '\n',
    ROWTERMINATOR = '\n',
    DATAFILETYPE = 'char'
);
GO
EOF"
```

### 3.3 Encoding/caracteres especiais

**Sintomas:** Caracteres estranhos nos dados

**Solução:** Os arquivos devem estar em UTF-8

```bash
# Verificar encoding
file -i datasets/*.csv

# Converter se necessário
iconv -f ISO-8859-1 -t UTF-8 arquivo.csv > arquivo_utf8.csv
```

---

## 4. Problemas com Queries

### 4.1 "Invalid object name 'SP500_companies'"

**Causa:** Executando no database errado

**Solução A - Usar caminho completo:**
```sql
-- ❌ Errado
SELECT * FROM SP500_companies;

-- ✅ Correto
SELECT * FROM datasets.dbo.SP500_companies;
```

**Solução B - Mudar database:**
```sql
USE datasets;
GO
SELECT * FROM SP500_companies;
```

**Solução C - No DataGrip:**
1. No topo da janela de query, há um dropdown
2. Selecione **"datasets"** em vez de "master"
3. Execute a query

### 4.2 "Login failed for user 'SA'"

**Causa 1:** SQL Server ainda está inicializando

**Solução:**
```bash
# Aguardar até ver esta mensagem
docker logs sqlserverCC | grep "Server is listening"

# Deve mostrar:
# Server is listening on [ 0.0.0.0 <ipv4> 1433 ]
```

**Causa 2:** Senha incorreta

**Verificar:**
```bash
# A senha DEVE ser exatamente: Cc202505!
# Com C maiúsculo e exclamação no final
```

### 4.3 Query retorna dados vazios mas deveria ter dados

**Diagnóstico:**
```sql
-- Verificar se há dados
SELECT COUNT(*) FROM datasets.dbo.SP500_companies;

-- Se retornar 0, importação falhou
-- Se retornar > 0, query está errada
```

**Se retornou 0:**
```bash
# Re-executar importação
docker cp scripts/01_setup_completo.sql sqlserverCC:/tmp/01_setup_completo.sql
docker exec sqlserverCC /opt/mssql-tools18/bin/sqlcmd -S localhost -U SA -P "Cc202505!" -i /tmp/01_setup_completo.sql -C
```

---

## 5. Problemas de Conexão

### 5.1 "Connection refused" ou "Cannot connect"

**Diagnóstico:**
```bash
# 1. Container está rodando?
docker compose ps

# 2. Porta está aberta?
netstat -tuln | grep 1433

# 3. SQL Server está pronto?
docker logs sqlserverCC | tail -20
```

**Soluções:**

**A - Container parado:**
```bash
docker compose up -d
sleep 60  # Aguardar inicialização
```

**B - Porta não está exposta:**
```bash
# Verificar compose.yaml
cat compose.yaml | grep 1433

# Deve ter:
# ports:
#   - 1433:1433

# Se não tiver, adicionar e reiniciar
docker compose down
docker compose up -d
```

**C - Firewall bloqueando:**
```bash
# Verificar firewall
sudo ufw status

# Permitir porta (se necessário)
sudo ufw allow 1433/tcp
```

### 5.2 "SSL/TLS error" ou "Certificate error"

**Solução:** Usar parâmetro `-C` (trust server certificate)

Já está incluído nos comandos, mas se estiver usando outro cliente SQL:

```bash
sqlcmd -S localhost -U SA -P "Cc202505!" -C  # ← -C é importante
```

No DataGrip:
1. Propriedades da conexão
2. Aba **"Advanced"**
3. Adicionar: `trustServerCertificate=true`

---

## 6. Reset Completo

**Use isto como ÚLTIMO RECURSO quando nada funcionar**

### Opção A: Reset Suave (mantém imagens)

```bash
# 1. Parar container
docker compose down

# 2. Remover volumes
docker volume ls | grep Gerenciamento
docker volume rm <nome_do_volume>

# Ou remover todos os volumes não usados:
docker volume prune -f

# 3. Reiniciar
docker compose up -d

# 4. Aguardar inicialização
sleep 60

# 5. Re-executar setup
docker cp scripts/01_setup_completo.sql sqlserverCC:/tmp/01_setup_completo.sql
docker exec sqlserverCC /opt/mssql-tools18/bin/sqlcmd -S localhost -U SA -P "Cc202505!" -i /tmp/01_setup_completo.sql -C
```

### Opção B: Reset Completo (remove tudo)

```bash
# ⚠️ CUIDADO: Isto remove TUDO!

# 1. Parar e remover container
docker compose down -v

# 2. Remover imagem (força re-download)
docker rmi mcr.microsoft.com/mssql/server:2022-latest

# 3. Limpar sistema Docker
docker system prune -a -f

# 4. Reiniciar do zero
docker compose up -d

# 5. Aguardar 60-90 segundos
sleep 90

# 6. Executar setup
docker cp scripts/01_setup_completo.sql sqlserverCC:/tmp/01_setup_completo.sql
docker exec sqlserverCC /opt/mssql-tools18/bin/sqlcmd -S localhost -U SA -P "Cc202505!" -i /tmp/01_setup_completo.sql -C
```

---

## 7. Checklist de Verificação

Use esta checklist para verificar se está tudo OK:

### ✅ Docker
- [ ] Docker está instalado: `docker --version`
- [ ] Docker está rodando: `sudo systemctl status docker`
- [ ] Container está up: `docker compose ps` mostra "Up"
- [ ] SQL Server iniciou: `docker logs sqlserverCC | grep "Server is listening"`

### ✅ Databases
- [ ] Database master existe: `SELECT name FROM sys.databases` mostra "master"
- [ ] Database datasets existe: `SELECT name FROM sys.databases` mostra "datasets"

### ✅ Tabelas Master
- [ ] 8 tabelas criadas: `SELECT COUNT(*) FROM master.sys.tables WHERE type='U' AND name NOT LIKE 'spt%'` retorna 8

### ✅ Tabelas Datasets
- [ ] 3 tabelas criadas: `SELECT COUNT(*) FROM datasets.sys.tables WHERE type='U'` retorna 3
- [ ] SP500_companies tem dados: `SELECT COUNT(*) FROM datasets.dbo.SP500_companies` > 1000
- [ ] SP500_fred tem dados: `SELECT COUNT(*) FROM datasets.dbo.SP500_fred` > 5000
- [ ] CSI500 tem dados: `SELECT COUNT(*) FROM datasets.dbo.CSI500` > 2000000

### ✅ DataGrip
- [ ] Conexão criada
- [ ] Conexão funciona: Test Connection = OK
- [ ] Schemas configurados: datasets e master marcados
- [ ] Tabelas aparecem na árvore
- [ ] Queries funcionam

---

## 8. Comandos de Diagnóstico

Salve estes comandos para diagnóstico rápido:

```bash
# === DIAGNÓSTICO COMPLETO ===

echo "=== 1. Docker ==="
docker --version
sudo systemctl status docker | grep Active
docker compose ps

echo "=== 2. Container ==="
docker logs sqlserverCC | grep -E "(Server is listening|Error|Failed)" | tail -10

echo "=== 3. Databases ==="
docker exec sqlserverCC /opt/mssql-tools18/bin/sqlcmd -S localhost -U SA -P "Cc202505!" -Q "SELECT name FROM sys.databases ORDER BY name" -C

echo "=== 4. Tabelas Master ==="
docker exec sqlserverCC bash -c "/opt/mssql-tools18/bin/sqlcmd -S localhost -U SA -P 'Cc202505!' -C <<'EOF'
USE master
GO
SELECT name FROM sys.tables WHERE type='U' AND name NOT LIKE 'spt%' AND name NOT LIKE 'MS%' ORDER BY name
GO
EOF"

echo "=== 5. Tabelas Datasets ==="
docker exec sqlserverCC bash -c "/opt/mssql-tools18/bin/sqlcmd -S localhost -U SA -P 'Cc202505!' -C <<'EOF'
USE datasets
GO
SELECT name FROM sys.tables WHERE type='U' ORDER BY name
GO
EOF"

echo "=== 6. Contagem de Registros ==="
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

echo "=== FIM DO DIAGNÓSTICO ==="
```

---

## 9. Perguntas Frequentes (FAQ)

**Q: Por que as tabelas do master estão vazias?**
A: Isso é esperado! As tabelas do master são o modelo dimensional e serão populadas depois via ETL dos dados do datasets.

**Q: Posso usar outro cliente SQL além do DataGrip?**
A: Sim! Pode usar Azure Data Studio, DBeaver, SQL Server Management Studio (Windows), etc.

**Q: Preciso do Docker ou posso instalar SQL Server direto?**
A: Pode instalar direto, mas o Docker facilita muito. Para instalar direto no Linux, veja a documentação da Microsoft.

**Q: Como fazer backup dos dados?**
A: Use `docker exec` com comando `BACKUP DATABASE` ou exporte para CSV.

**Q: Posso mudar a senha do SA?**
A: Sim, edite `compose.yaml` na linha `MSSQL_SA_PASSWORD` ANTES de criar o container pela primeira vez.

---

**🎯 Se seguiu este guia e ainda não funciona, copie o output do "Comandos de Diagnóstico" e revise os logs!**

**Data**: 2025-11-07
