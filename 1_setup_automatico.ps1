# ========================================
# SCRIPT DE SETUP AUTOMATIZADO
# Executa todos os passos do zero
# ========================================

$ErrorActionPreference = "Stop"

Write-Host "=========================================" -ForegroundColor Cyan
Write-Host "SETUP AUTOMATIZADO DO PROJETO" -ForegroundColor Cyan
Write-Host "=========================================" -ForegroundColor Cyan
Write-Host ""

# ========================================
# PASSO 1: Verificar pré-requisitos
# ========================================
Write-Host "[1/7] Verificando pré-requisitos..." -ForegroundColor Yellow

# Verificar Docker
try {
    docker --version | Out-Null
} catch {
    Write-Host "ERRO: Docker não está instalado!" -ForegroundColor Red
    exit 1
}

# Verificar pasta datasets
if (-not (Test-Path "datasets")) {
    Write-Host "ERRO: Pasta 'datasets' não encontrada!" -ForegroundColor Red
    exit 1
}

# Verificar arquivo CSV
if (-not (Test-Path "datasets/S&P-500-companies.csv")) {
    Write-Host "ERRO: Arquivo S&P-500-companies.csv não encontrado!" -ForegroundColor Red
    exit 1
}

Write-Host "✓ Pré-requisitos OK" -ForegroundColor Green
Write-Host ""

# ========================================
# PASSO 2: Iniciar container
# ========================================
Write-Host "[2/7] Iniciando container Docker..." -ForegroundColor Yellow

docker compose down 2>$null
docker compose up -d

Write-Host "✓ Container iniciado" -ForegroundColor Green
Write-Host ""

# ========================================
# PASSO 3: Aguardar SQL Server inicializar
# ========================================
Write-Host "[3/7] Aguardando SQL Server inicializar (60 segundos)..." -ForegroundColor Yellow

for ($i = 60; $i -gt 0; $i--) {
    Write-Host -NoNewline "`rAguardando... $i segundos restantes" -ForegroundColor Yellow
    Start-Sleep -Seconds 1
}

Write-Host "`n✓ SQL Server deve estar pronto" -ForegroundColor Green
Write-Host ""

# Verificar se está rodando
Write-Host "Verificando se SQL Server está escutando..." -ForegroundColor Yellow
$logs = docker logs sqlserverCC 2>&1
if ($logs -match "Server is listening") {
    Write-Host "✓ SQL Server está rodando" -ForegroundColor Green
} else {
    Write-Host "⚠ SQL Server pode ainda estar inicializando..." -ForegroundColor Yellow
}
Write-Host ""

# ========================================
# PASSO 4: Copiar script
# ========================================
Write-Host "[4/7] Copiando script de setup para o container..." -ForegroundColor Yellow

if (-not (Test-Path "scripts/1-setup/01_setup_completo.sql")) {
    Write-Host "ERRO: Script scripts/1-setup/01_setup_completo.sql não encontrado!" -ForegroundColor Red
    exit 1
}

docker cp scripts/1-setup/01_setup_completo.sql sqlserverCC:/tmp/01_setup_completo.sql

Write-Host "✓ Script copiado" -ForegroundColor Green
Write-Host ""

# ========================================
# PASSO 5: Executar setup completo
# ========================================
Write-Host "[5/7] Executando setup completo (pode levar 2-5 minutos)..." -ForegroundColor Yellow
Write-Host ""

docker exec sqlserverCC /opt/mssql-tools18/bin/sqlcmd -S localhost -U SA -P "Cc202505!" -i /tmp/01_setup_completo.sql -C

Write-Host ""
Write-Host "✓ Setup executado" -ForegroundColor Green
Write-Host ""

# ========================================
# PASSO 6: Verificar instalação
# ========================================
Write-Host "[6/7] Verificando instalação..." -ForegroundColor Yellow
Write-Host ""

Write-Host "Databases criados:" -ForegroundColor Yellow
docker exec sqlserverCC /opt/mssql-tools18/bin/sqlcmd -S localhost -U SA -P "Cc202505!" -Q "SELECT name FROM sys.databases WHERE name IN ('master', 'datasets') ORDER BY name" -C -h-1 -W

Write-Host ""
Write-Host "Tabelas no master:" -ForegroundColor Yellow
docker exec sqlserverCC bash -c "/opt/mssql-tools18/bin/sqlcmd -S localhost -U SA -P 'Cc202505!' -C -h-1 -W <<'EOF'
USE master
GO
SELECT name FROM sys.tables WHERE type = 'U' AND name NOT LIKE 'spt%' AND name NOT LIKE 'MS%' ORDER BY name
GO
EOF"

Write-Host ""
Write-Host "Contagem de registros importados:" -ForegroundColor Yellow
docker exec sqlserverCC bash -c "/opt/mssql-tools18/bin/sqlcmd -S localhost -U SA -P 'Cc202505!' -C -W <<'EOF'
USE datasets
GO
SELECT
    'SP500_companies' as Tabela,
    COUNT(*) as Total
FROM SP500_companies
UNION ALL
SELECT 'SP500_fred', COUNT(*) FROM SP500_fred
UNION ALL
SELECT 'CSI500', COUNT(*) FROM CSI500
GO
EOF"

Write-Host ""
Write-Host "✓ Verificação concluída" -ForegroundColor Green
Write-Host ""

# ========================================
# PASSO 7: Informações finais
# ========================================
Write-Host "[7/7] Informações de acesso" -ForegroundColor Yellow
Write-Host ""
Write-Host "=========================================" -ForegroundColor Cyan
Write-Host "SETUP CONCLUÍDO COM SUCESSO!" -ForegroundColor Green
Write-Host "=========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Credenciais para DataGrip:"
Write-Host "  Host: localhost"
Write-Host "  Port: 1433"
Write-Host "  User: SA"
Write-Host "  Password: Cc202505!"
Write-Host "  Database: master"
Write-Host ""
Write-Host "Próximos passos:"
Write-Host "  1. Abra o DataGrip"
Write-Host "  2. Crie uma nova conexão com as credenciais acima"
Write-Host "  3. Configure os schemas (datasets + master)"
Write-Host "  4. Faça Refresh (F5)"
Write-Host "  5. Abra scripts/02_consultas.sql para testar"
Write-Host ""
Write-Host "Comandos úteis:"
Write-Host "  docker compose ps        # Status do container"
Write-Host "  docker compose down      # Parar container"
Write-Host "  docker compose up -d     # Iniciar container"
Write-Host ""
Write-Host "=========================================" -ForegroundColor Cyan
