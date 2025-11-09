# ========================================
# SCRIPT DE LIMPEZA - Menu Interativo (Windows)
# ========================================

$ErrorActionPreference = "Stop"

# Navegar para o diretório raiz do projeto (pasta pai de scripts-windows)
Set-Location (Join-Path $PSScriptRoot "..")

# Função para escrever com cor
function Write-Blue($msg)   { Write-Host $msg -ForegroundColor Blue }
function Write-Green($msg)  { Write-Host $msg -ForegroundColor Green }
function Write-Yellow($msg) { Write-Host $msg -ForegroundColor Yellow }
function Write-Red($msg)    { Write-Host $msg -ForegroundColor Red }

Write-Blue  "========================================"
Write-Blue  "    SCRIPT DE LIMPEZA DO PROJETO"
Write-Blue  "========================================"
Write-Host  ""
Write-Host  "Escolha uma opção:"
Write-Host  ""
Write-Green "1) Limpar apenas os DADOS (mantém estrutura)"
Write-Host  "   - Remove todos os registros das tabelas"
Write-Host  "   - Mantém tabelas, databases e estrutura"
Write-Host  "   - Útil para reimportar dados"
Write-Host  ""
Write-Yellow "2) RESETAR TUDO do zero"
Write-Host   "   - Remove TODAS as tabelas"
Write-Host   "   - Remove database DATASETS"
Write-Host   "   - Sistema volta ao estado inicial"
Write-Host   ""
Write-Red    "3) Cancelar"
Write-Host   ""

$choice = Read-Host "Digite sua escolha [1-3]"

switch ($choice) {
    '1' {
        Write-Host ""
        Write-Yellow "Você escolheu: LIMPAR DADOS"
        Write-Host   "Isso vai remover todos os registros mas manter a estrutura."
        $confirm = Read-Host "Tem certeza? (s/N):"

        if ($confirm -match '^[sS]$') {
            Write-Host ""
            Write-Green "Copiando script para o container..."
            docker cp "scripts/3-manutencao/limpar_dados.sql" "sqlserverCC:/tmp/limpar_dados.sql"

            Write-Green "Executando limpeza de dados..."
            docker exec sqlserverCC /opt/mssql-tools18/bin/sqlcmd -S localhost -U SA -P "Cc202505!" -i "/tmp/limpar_dados.sql" -C

            Write-Host ""
            Write-Green "Limpeza de dados concluída!"
            Write-Host "Para reimportar dados, execute: scripts-windows\1_setup_automatico.ps1"
        }
        else {
            Write-Red "Operação cancelada."
        }
    }

    '2' {
        Write-Host ""
        Write-Red "ATENÇÃO!"
        Write-Red "Você escolheu: RESETAR TUDO"
        Write-Host "Isso vai:"
        Write-Host "  - Dropar TODAS as tabelas do master"
        Write-Host "  - Dropar o database DATASETS"
        Write-Host "  - APAGAR TODOS OS DADOS permanentemente"
        Write-Host ""
        $confirm = Read-Host "TEM CERTEZA ABSOLUTA? Digite 'RESETAR' para confirmar:"

        if ($confirm -eq "RESETAR") {
            Write-Host ""
            Write-Yellow "Copiando script para o container..."
            docker cp "scripts/3-manutencao/resetar_tudo.sql" "sqlserverCC:/tmp/resetar_tudo.sql"

            Write-Yellow "Executando reset completo..."
            docker exec sqlserverCC /opt/mssql-tools18/bin/sqlcmd -S localhost -U SA -P "Cc202505!" -i "/tmp/resetar_tudo.sql" -C

            Write-Host ""
            Write-Green "Reset completo finalizado!"
            Write-Host "Para recriar tudo do zero, execute: scripts-windows\1_setup_automatico.ps1"
        }
        else {
            Write-Red "Operação cancelada (confirmação incorreta)."
        }
    }

    '3' {
        Write-Green "Operação cancelada."
        exit 0
    }

    Default {
        Write-Red "Opção inválida!"
        exit 1
    }
}

Write-Host ""
Write-Blue "========================================"
