#!/bin/bash

# =============================================
# Script: Executar Análise Completa (Linux/Mac)
# Descrição: Executa análise completa das 7 perguntas de negócio
# Autor: Sistema de Análise Financeira
# Data: 2025-11-08
# =============================================

set -e

echo "============================================="
echo "ANÁLISE COMPLETA - 7 PERGUNTAS DE NEGÓCIO"
echo "============================================="
echo ""

# Configurações
CONTAINER_NAME="sqlserverCC"
SA_PASSWORD="Cc202505!"
DATABASE="datasets"
SCRIPT_DIR="./scripts/2-analise"
LOG_DIR="./logs"
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
LOG_FILE="${LOG_DIR}/analise_${TIMESTAMP}.log"

# Criar diretório de logs se não existir
mkdir -p "${LOG_DIR}"

echo "Configurações:"
echo "  - Container: ${CONTAINER_NAME}"
echo "  - Database: ${DATABASE}"
echo "  - Log: ${LOG_FILE}"
echo ""

# Verificar se container está rodando
echo ">>> Verificando container..."
if ! docker ps | grep -q "${CONTAINER_NAME}"; then
    echo "ERRO: Container ${CONTAINER_NAME} não está rodando!"
    echo "Execute: docker compose up -d"
    exit 1
fi
echo "✓ Container está rodando"
echo ""

# Verificar se banco de dados existe
echo ">>> Verificando banco de dados..."
DB_EXISTS=$(docker exec ${CONTAINER_NAME} /opt/mssql-tools18/bin/sqlcmd \
    -S localhost -U SA -P "${SA_PASSWORD}" -C \
    -Q "SET NOCOUNT ON; SELECT DB_ID('${DATABASE}')" -h -1 | tr -d ' ')

if [ -z "$DB_EXISTS" ] || [ "$DB_EXISTS" = "NULL" ]; then
    echo "ERRO: Banco de dados '${DATABASE}' não existe!"
    echo "Execute o setup primeiro: ./scripts-linux/1_setup_automatico.sh"
    exit 1
fi
echo "✓ Banco de dados existe"
echo ""

# Copiar scripts para o container
echo ">>> Copiando scripts para o container..."
docker cp "${SCRIPT_DIR}/01_criar_tabelas_normalizadas.sql" ${CONTAINER_NAME}:/tmp/ 2>/dev/null || true
docker cp "${SCRIPT_DIR}/04_criar_views_7_perguntas.sql" ${CONTAINER_NAME}:/tmp/ 2>/dev/null || true
docker cp "${SCRIPT_DIR}/05_consultar_respostas.sql" ${CONTAINER_NAME}:/tmp/ 2>/dev/null || true
echo "✓ Scripts copiados"
echo ""

# Menu de opções
echo "Escolha uma opção:"
echo "  1) Criar tabelas normalizadas"
echo "  2) Criar views das 7 perguntas"
echo "  3) Consultar respostas (executar queries)"
echo "  4) Executar análise completa (1 + 2 + 3)"
echo ""
read -p "Opção [1-4]: " OPCAO

case $OPCAO in
    1)
        echo ""
        echo ">>> Criando tabelas normalizadas..."
        docker exec ${CONTAINER_NAME} /opt/mssql-tools18/bin/sqlcmd \
            -S localhost -U SA -P "${SA_PASSWORD}" -C \
            -i /tmp/01_criar_tabelas_normalizadas.sql \
            2>&1 | tee "${LOG_FILE}"
        ;;
    2)
        echo ""
        echo ">>> Criando views das 7 perguntas..."
        docker exec ${CONTAINER_NAME} /opt/mssql-tools18/bin/sqlcmd \
            -S localhost -U SA -P "${SA_PASSWORD}" -C \
            -i /tmp/04_criar_views_7_perguntas.sql \
            2>&1 | tee "${LOG_FILE}"
        ;;
    3)
        echo ""
        echo ">>> Consultando respostas..."
        docker exec ${CONTAINER_NAME} /opt/mssql-tools18/bin/sqlcmd \
            -S localhost -U SA -P "${SA_PASSWORD}" -C \
            -i /tmp/05_consultar_respostas.sql \
            2>&1 | tee "${LOG_FILE}"
        ;;
    4)
        echo ""
        echo ">>> Executando análise completa (pode levar alguns minutos)..."
        echo ""

        echo "Passo 1/3: Criando tabelas normalizadas..."
        docker exec ${CONTAINER_NAME} /opt/mssql-tools18/bin/sqlcmd \
            -S localhost -U SA -P "${SA_PASSWORD}" -C \
            -i /tmp/01_criar_tabelas_normalizadas.sql \
            2>&1 | tee -a "${LOG_FILE}"

        echo ""
        echo "Passo 2/3: Criando views das 7 perguntas..."
        docker exec ${CONTAINER_NAME} /opt/mssql-tools18/bin/sqlcmd \
            -S localhost -U SA -P "${SA_PASSWORD}" -C \
            -i /tmp/04_criar_views_7_perguntas.sql \
            2>&1 | tee -a "${LOG_FILE}"

        echo ""
        echo "Passo 3/3: Consultando respostas..."
        docker exec ${CONTAINER_NAME} /opt/mssql-tools18/bin/sqlcmd \
            -S localhost -U SA -P "${SA_PASSWORD}" -C \
            -i /tmp/05_consultar_respostas.sql \
            2>&1 | tee -a "${LOG_FILE}"
        ;;
    *)
        echo "Opção inválida!"
        exit 1
        ;;
esac

EXIT_CODE=${PIPESTATUS[0]}

echo ""
if [ $EXIT_CODE -eq 0 ]; then
    echo "============================================="
    echo "✓ ANÁLISE CONCLUÍDA COM SUCESSO!"
    echo "============================================="
    echo ""
    echo "Log salvo em: ${LOG_FILE}"
    echo ""
    echo "Views criadas (7 perguntas):"
    echo "  1. vw_P1_MaiorValorizacaoUltimoAno"
    echo "  2. vw_P2_VolatilidadePorIndustria"
    echo "  3. vw_P3_MaiorVolumeNegociacao"
    echo "  4. vw_P4_CrescimentoConsistente5Anos"
    echo "  5. vw_P5_DesempenhoSetoresSP500"
    echo "  6. vw_P6_QuedaCriseCovid"
    echo "  7. vw_P7_DadosBaseParaDividendos"
    echo ""
    echo "Consulte no DataGrip ou via comando:"
    echo "  SELECT TOP 10 * FROM vw_P1_MaiorValorizacaoUltimoAno"
    echo "  ORDER BY ValorizacaoPercentual DESC;"
    echo ""
else
    echo "============================================="
    echo "✗ ERRO NA ANÁLISE!"
    echo "============================================="
    echo ""
    echo "Verifique o log: ${LOG_FILE}"
    echo ""
    exit 1
fi
