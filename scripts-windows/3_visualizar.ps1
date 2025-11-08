# ========================================
# SCRIPT: VISUALIZAR TABELAS
# ========================================
# Descrição: Mostra os dados de todas as tabelas
# ========================================

$ErrorActionPreference = "Stop"

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "    VISUALIZAR DADOS DAS TABELAS" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Verificar se container está rodando
$containerRunning = docker ps | Select-String "sqlserverCC"
if (-not $containerRunning) {
    Write-Host "Container não está rodando. Inicie com: docker compose up -d" -ForegroundColor Red
    exit 1
}

Write-Host "Copiando script para o container..." -ForegroundColor Green
docker cp scripts/2-consultas/visualizar_tabelas.sql sqlserverCC:/tmp/visualizar_tabelas.sql

Write-Host "Executando consultas..." -ForegroundColor Green
Write-Host ""
docker exec sqlserverCC /opt/mssql-tools18/bin/sqlcmd -S localhost -U SA -P "Cc202505!" -i /tmp/visualizar_tabelas.sql -C

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "✅ Visualização concluída!" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
