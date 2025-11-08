# ========================================
# SCRIPT: EXECUTAR ETL
# ========================================
# Descrição: Processa dados brutos e popula tabelas do master
# ========================================

$ErrorActionPreference = "Stop"

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "    PROCESSAMENTO ETL" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Verificar se container está rodando
$containerRunning = docker ps | Select-String "sqlserverCC"
if (-not $containerRunning) {
    Write-Host "Container não está rodando. Iniciando..." -ForegroundColor Yellow
    docker compose up -d
    Write-Host "Aguardando SQL Server inicializar (30 segundos)..."
    Start-Sleep -Seconds 30
}

Write-Host "[1/3] Copiando script ETL para o container..." -ForegroundColor Green
docker cp scripts/1-setup/02_processar_dados_etl.sql sqlserverCC:/tmp/02_processar_dados_etl.sql

Write-Host "[2/3] Executando processamento ETL..." -ForegroundColor Green
Write-Host ""
docker exec sqlserverCC /opt/mssql-tools18/bin/sqlcmd -S localhost -U SA -P "Cc202505!" -i /tmp/02_processar_dados_etl.sql -C

Write-Host ""
Write-Host "[3/3] Verificando resultados..." -ForegroundColor Green
docker exec sqlserverCC bash -c "/opt/mssql-tools18/bin/sqlcmd -S localhost -U SA -P 'Cc202505!' -C <<'EOF'
USE master
GO
PRINT 'Resumo das tabelas populadas:'
SELECT 'Empresas' as Tabela, COUNT(*) as Total FROM Empresas
UNION ALL
SELECT 'SubSetor', COUNT(*) FROM SubSetor
UNION ALL
SELECT 'Localizacao', COUNT(*) FROM Localizacao
UNION ALL
SELECT 'Indice', COUNT(*) FROM Indice
UNION ALL
SELECT 'IndiceSP500', COUNT(*) FROM IndiceSP500
UNION ALL
SELECT 'Tempo', COUNT(*) FROM Tempo
ORDER BY Tabela
GO
EOF"

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "✅ PROCESSAMENTO ETL CONCLUÍDO!" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Próximos passos:"
Write-Host "  1. Abra o DataGrip e faça Refresh (F5)"
Write-Host "  2. Verifique os dados nas tabelas"
Write-Host "  3. Execute queries de análise"
Write-Host ""
