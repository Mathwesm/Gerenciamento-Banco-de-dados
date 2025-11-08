# ========================================
# SCRIPT DE LIMPEZA - Menu Interativo
# ========================================

$ErrorActionPreference = "Stop"

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "    SCRIPT DE LIMPEZA DO PROJETO" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Escolha uma opção:"
Write-Host ""
Write-Host "1) Limpar apenas os DADOS (mantém estrutura)" -ForegroundColor Green
Write-Host "   - Remove todos os registros das tabelas"
Write-Host "   - Mantém tabelas, databases e estrutura"
Write-Host "   - Útil para reimportar dados"
Write-Host ""
Write-Host "2) RESETAR TUDO do zero" -ForegroundColor Yellow
Write-Host "   - Remove TODAS as tabelas"
Write-Host "   - Remove database DATASETS"
Write-Host "   - Sistema volta ao estado inicial"
Write-Host ""
Write-Host "3) Cancelar" -ForegroundColor Red
Write-Host ""

$choice = Read-Host "Digite sua escolha [1-3]"

switch ($choice) {
    "1" {
        Write-Host ""
        Write-Host "⚠️  Você escolheu: LIMPAR DADOS" -ForegroundColor Yellow
        Write-Host "Isso vai remover todos os registros mas manter a estrutura."
        $confirm = Read-Host "Tem certeza? (s/N)"

        if ($confirm -eq "s" -or $confirm -eq "S") {
            Write-Host ""
            Write-Host "Copiando script para o container..." -ForegroundColor Green
            docker cp scripts/3-manutencao/limpar_dados.sql sqlserverCC:/tmp/limpar_dados.sql

            Write-Host "Executando limpeza de dados..." -ForegroundColor Green
            docker exec sqlserverCC /opt/mssql-tools18/bin/sqlcmd -S localhost -U SA -P "Cc202505!" -i /tmp/limpar_dados.sql -C

            Write-Host ""
            Write-Host "✅ Limpeza de dados concluída!" -ForegroundColor Green
            Write-Host "Para reimportar dados, execute: .\1_setup_automatico.ps1"
        } else {
            Write-Host "Operação cancelada." -ForegroundColor Red
        }
    }

    "2" {
        Write-Host ""
        Write-Host "⚠️⚠️⚠️  ATENÇÃO! ⚠️⚠️⚠️" -ForegroundColor Red
        Write-Host "Você escolheu: RESETAR TUDO" -ForegroundColor Red
        Write-Host "Isso vai:"
        Write-Host "  - Dropar TODAS as tabelas do master"
        Write-Host "  - Dropar o database DATASETS"
        Write-Host "  - APAGAR TODOS OS DADOS permanentemente"
        Write-Host ""
        $confirm = Read-Host "TEM CERTEZA ABSOLUTA? Digite 'RESETAR' para confirmar"

        if ($confirm -eq "RESETAR") {
            Write-Host ""
            Write-Host "Copiando script para o container..." -ForegroundColor Yellow
            docker cp scripts/3-manutencao/resetar_tudo.sql sqlserverCC:/tmp/resetar_tudo.sql

            Write-Host "Executando reset completo..." -ForegroundColor Yellow
            docker exec sqlserverCC /opt/mssql-tools18/bin/sqlcmd -S localhost -U SA -P "Cc202505!" -i /tmp/resetar_tudo.sql -C

            Write-Host ""
            Write-Host "✅ Reset completo finalizado!" -ForegroundColor Green
            Write-Host "Para recriar tudo do zero, execute: .\1_setup_automatico.ps1"
        } else {
            Write-Host "Operação cancelada (confirmação incorreta)." -ForegroundColor Red
        }
    }

    "3" {
        Write-Host "Operação cancelada." -ForegroundColor Green
        exit 0
    }

    default {
        Write-Host "Opção inválida!" -ForegroundColor Red
        exit 1
    }
}

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
