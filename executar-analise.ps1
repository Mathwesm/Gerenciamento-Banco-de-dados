# =============================================
# Script: Executar Análise Completa (Windows PowerShell)
# Descrição: Executa análise completa do mercado de ações
# Autor: Sistema de Análise Financeira
# Data: 2025-11-07
# =============================================

$ErrorActionPreference = "Stop"

Write-Host "=============================================" -ForegroundColor Cyan
Write-Host "EXECUTANDO ANÁLISE COMPLETA - MERCADO DE AÇÕES" -ForegroundColor Cyan
Write-Host "=============================================" -ForegroundColor Cyan
Write-Host ""

# Configurações
$CONTAINER_NAME = "sqlserverCC"
$SA_PASSWORD = "Cc202505!"
$DATABASE = "datasets"
$SCRIPT_DIR = ".\scripts\2-analise"
$LOG_DIR = ".\logs"
$TIMESTAMP = Get-Date -Format "yyyyMMdd_HHmmss"
$LOG_FILE = "$LOG_DIR\analise_$TIMESTAMP.log"

# Criar diretório de logs se não existir
if (!(Test-Path $LOG_DIR)) {
    New-Item -ItemType Directory -Path $LOG_DIR | Out-Null
}

Write-Host "Configurações:"
Write-Host "  - Container: $CONTAINER_NAME"
Write-Host "  - Database: $DATABASE"
Write-Host "  - Log: $LOG_FILE"
Write-Host ""

# Verificar se container está rodando
Write-Host ">>> Verificando container..." -ForegroundColor Yellow
$containerStatus = docker ps --filter "name=$CONTAINER_NAME" --format "{{.Names}}"
if ($containerStatus -ne $CONTAINER_NAME) {
    Write-Host "ERRO: Container $CONTAINER_NAME não está rodando!" -ForegroundColor Red
    Write-Host "Execute: docker compose up -d"
    exit 1
}
Write-Host "✓ Container está rodando" -ForegroundColor Green
Write-Host ""

# Verificar se banco de dados existe
Write-Host ">>> Verificando banco de dados..." -ForegroundColor Yellow
$dbCheck = docker exec $CONTAINER_NAME /opt/mssql-tools18/bin/sqlcmd `
    -S localhost -U SA -P "$SA_PASSWORD" -C `
    -Q "SET NOCOUNT ON; SELECT DB_ID('$DATABASE')" -h -1

if ([string]::IsNullOrWhiteSpace($dbCheck) -or $dbCheck.Trim() -eq "NULL") {
    Write-Host "ERRO: Banco de dados '$DATABASE' não existe!" -ForegroundColor Red
    Write-Host "Execute o setup primeiro: .\scripts-windows\1_setup_automatico.ps1"
    exit 1
}
Write-Host "✓ Banco de dados existe" -ForegroundColor Green
Write-Host ""

# Copiar scripts_linux para o container
Write-Host ">>> Copiando scripts_linux para o container..." -ForegroundColor Yellow
docker cp "$SCRIPT_DIR\01_criar_tabelas_normalizadas.sql" ${CONTAINER_NAME}:/tmp/
docker cp "$SCRIPT_DIR\02_queries_analise.sql" ${CONTAINER_NAME}:/tmp/
docker cp "$SCRIPT_DIR\03_executar_analise_completa.sql" ${CONTAINER_NAME}:/tmp/
Write-Host "✓ Scripts copiados" -ForegroundColor Green
Write-Host ""

# Executar análise completa
Write-Host ">>> Executando análise completa..." -ForegroundColor Yellow
Write-Host "    (Isso pode levar alguns minutos...)" -ForegroundColor Gray
Write-Host ""

$output = docker exec $CONTAINER_NAME /opt/mssql-tools18/bin/sqlcmd `
    -S localhost -U SA -P "$SA_PASSWORD" -C `
    -d "$DATABASE" `
    -i /tmp/03_executar_analise_completa.sql `
    2>&1

# Salvar log
$output | Out-File -FilePath $LOG_FILE -Encoding UTF8

# Exibir saída
$output | Write-Host

Write-Host ""
if ($LASTEXITCODE -eq 0) {
    Write-Host "=============================================" -ForegroundColor Green
    Write-Host "✓ ANÁLISE CONCLUÍDA COM SUCESSO!" -ForegroundColor Green
    Write-Host "=============================================" -ForegroundColor Green
    Write-Host ""
    Write-Host "Log salvo em: $LOG_FILE" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "Views criadas:" -ForegroundColor Cyan
    Write-Host "  - vw_EmpresasSP500Resumo"
    Write-Host "  - vw_IndiceSP500Metricas"
    Write-Host "  - vw_AcoesChinesasIndicadores"
    Write-Host "  - vw_TopPerformers30d"
    Write-Host "  - vw_ResumoSetoresSP500"
    Write-Host "  - vw_ResumoIndustriasCSI500"
    Write-Host ""
    Write-Host "Exemplo de consulta:" -ForegroundColor Yellow
    Write-Host "  docker exec $CONTAINER_NAME /opt/mssql-tools18/bin/sqlcmd -S localhost -U SA -P `"$SA_PASSWORD`" -d $DATABASE -Q `"SELECT TOP 10 * FROM vw_TopPerformers30d ORDER BY VariacaoPercentual DESC`" -C"
    Write-Host ""
} else {
    Write-Host "=============================================" -ForegroundColor Red
    Write-Host "✗ ERRO NA ANÁLISE!" -ForegroundColor Red
    Write-Host "=============================================" -ForegroundColor Red
    Write-Host ""
    Write-Host "Verifique o log: $LOG_FILE" -ForegroundColor Yellow
    Write-Host ""
    exit 1
}
