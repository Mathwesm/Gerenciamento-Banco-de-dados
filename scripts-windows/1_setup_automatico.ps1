# ========================================
# SCRIPT DE SETUP AUTOMATIZADO (Windows)
# ========================================

$ErrorActionPreference = "Stop"

# Navegar para o diretório raiz do projeto (pasta pai de scripts-windows)
Set-Location (Join-Path $PSScriptRoot "..")

Write-Host "========================================="
Write-Host "SETUP AUTOMATIZADO DO PROJETO"
Write-Host "========================================="
Write-Host ""

# ========================================
# PASSO 1: Verificar pré-requisitos
# ========================================
Write-Host "[1/7] Verificando pré-requisitos..." -ForegroundColor Yellow

# Verificar Docker
try {
    docker --version | Out-Null
}
catch {
    Write-Host "ERRO: Docker não está instalado ou não está no PATH!" -ForegroundColor Red
    exit 1
}

# Verificar pasta datasets
if (-not (Test-Path "datasets")) {
    Write-Host "ERRO: Pasta 'datasets' não encontrada!" -ForegroundColor Red
    exit 1
}

# Verificar arquivos CSV
if (-not (Test-Path "datasets/sp500_data_part1.csv")) {
    Write-Host "ERRO: Arquivo sp500_data_part1.csv não encontrado!" -ForegroundColor Red
    exit 1
}

if (-not (Test-Path "datasets/sp500_data_part2.csv")) {
    Write-Host "ERRO: Arquivo sp500_data_part2.csv não encontrado!" -ForegroundColor Red
    exit 1
}

Write-Host "[OK] Pré-requisitos verificados." -ForegroundColor Green
Write-Host ""

# ========================================
# PASSO 2: Iniciar container
# ========================================
Write-Host "[2/7] Iniciando container Docker..." -ForegroundColor Yellow

# Tenta derrubar containers antigos, mas NÃO quebra o script se der erro
docker compose down -v 2>&1 | Out-Null

# Sobe o container
docker compose up -d

if ($LASTEXITCODE -ne 0) {
    Write-Host "ERRO: Falha ao iniciar o container Docker (docker compose up -d)." -ForegroundColor Red
    exit 1
}

Write-Host "[OK] Container iniciado." -ForegroundColor Green
Write-Host ""

# ========================================
# PASSO 3: Aguardar SQL Server inicializar
# ========================================
Write-Host "[3/7] Aguardando SQL Server inicializar (60 segundos)..." -ForegroundColor Yellow

for ($i = 60; $i -gt 0; $i--) {
    Write-Host -NoNewline "`rAguardando... $i segundos restantes"
    Start-Sleep -Seconds 1
}

Write-Host ""
Write-Host "[OK] SQL Server deve estar pronto." -ForegroundColor Green
Write-Host ""

Write-Host "Últimas linhas de log do SQL Server:" -ForegroundColor Yellow
docker logs sqlserverCC 2>&1 | Select-Object -Last 5
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

Write-Host "[OK] Script copiado para o container." -ForegroundColor Green
Write-Host ""

# ========================================
# PASSO 5: Executar setup completo
# ========================================
Write-Host "[5/7] Executando setup completo (pode levar alguns minutos)..." -ForegroundColor Yellow
Write-Host ""

docker exec sqlserverCC /opt/mssql-tools18/bin/sqlcmd `
    -S localhost -U SA -P "Cc202505!" `
    -i /tmp/01_setup_completo.sql -C

Write-Host ""
Write-Host "[OK] Setup executado." -ForegroundColor Green
Write-Host ""

# ========================================
# PASSO 6: Verificar instalação
# ========================================
Write-Host "[6/7] Verificando instalação..." -ForegroundColor Yellow
Write-Host ""

Write-Host "Databases criados:" -ForegroundColor Yellow
docker exec sqlserverCC /opt/mssql-tools18/bin/sqlcmd `
    -S localhost -U SA -P "Cc202505!" `
    -Q "SELECT name FROM sys.databases WHERE name IN ('master','datasets','FinanceDB') ORDER BY name;" `
    -C -h-1 -W

Write-Host ""
Write-Host "Tabelas no FinanceDB:" -ForegroundColor Yellow
docker exec sqlserverCC /opt/mssql-tools18/bin/sqlcmd `
    -S localhost -U SA -P "Cc202505!" `
    -Q "USE FinanceDB; SELECT name FROM sys.tables WHERE type = 'U' ORDER BY name;" `
    -C -h-1 -W

Write-Host ""
Write-Host "Contagem de registros importados:" -ForegroundColor Yellow
docker exec sqlserverCC /opt/mssql-tools18/bin/sqlcmd `
    -S localhost -U SA -P "Cc202505!" `
    -Q "USE datasets; SELECT 'SP500_data' AS Tabela, COUNT(*) AS Total FROM SP500_data UNION ALL SELECT 'CSI500' AS Tabela, COUNT(*) AS Total FROM CSI500;" `
    -C -W

Write-Host ""
Write-Host "[OK] Verificação concluída." -ForegroundColor Green
Write-Host ""

# ========================================
# PASSO 7: Informações finais
# ========================================
Write-Host "[7/7] Informações de acesso" -ForegroundColor Yellow
Write-Host ""
Write-Host "========================================="
Write-Host "SETUP CONCLUIDO COM SUCESSO!"
Write-Host "========================================="
Write-Host ""
Write-Host "Credenciais para DataGrip:"
Write-Host "  Host: localhost"
Write-Host "  Port: 1433"
Write-Host "  User: SA"
Write-Host "  Password: Cc202505!"
Write-Host "  Databases: FinanceDB + datasets"
Write-Host ""
Write-Host "Próximos passos:"
Write-Host "  1. Abra o DataGrip"
Write-Host "  2. Crie uma nova conexão com as credenciais acima"
Write-Host "  3. Configure os schemas (FinanceDB + datasets)"
Write-Host "  4. Faça Refresh (F5)"
Write-Host "  5. Execute scripts de análise (pasta 2-analise)"
Write-Host ""
Write-Host "Comandos úteis:"
Write-Host "  docker compose ps        # Status do container"
Write-Host "  docker compose down      # Parar container"
Write-Host "  docker compose up -d     # Iniciar container"
Write-Host ""
Write-Host "========================================="
