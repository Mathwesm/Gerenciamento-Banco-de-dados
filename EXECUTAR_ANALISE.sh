#!/bin/bash

# =============================================
# SCRIPT SIMPLIFICADO: EXECUÇÃO DIRETA
# =============================================

set -e

# Cores
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

clear

echo -e "${CYAN}╔════════════════════════════════════════════════════════════╗${NC}"
echo -e "${CYAN}║                                                            ║${NC}"
echo -e "${CYAN}║         ANÁLISE DE MERCADO FINANCEIRO - SETUP RÁPIDO      ║${NC}"
echo -e "${CYAN}║                                                            ║${NC}"
echo -e "${CYAN}╚════════════════════════════════════════════════════════════╝${NC}"
echo ""

# Configurações
CONTAINER_NAME="sqlserverCC"
SA_PASSWORD="Cc202505!"
PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LOG_DIR="$PROJECT_DIR/logs"
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
LOG_FILE="$LOG_DIR/analise_${TIMESTAMP}.log"

mkdir -p "$LOG_DIR"

echo -e "${BLUE}>>> Verificando Docker...${NC}"
if ! docker ps | grep -q "$CONTAINER_NAME"; then
    echo -e "${YELLOW}Iniciando container SQL Server...${NC}"
    cd "$PROJECT_DIR"
    docker-compose up -d || docker compose up -d
    echo -e "${GREEN}Aguardando SQL Server inicializar (30s)...${NC}"
    sleep 30
fi
echo -e "${GREEN}✓ Container ativo${NC}"
echo ""

echo -e "${BLUE}╔════════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║  ETAPA 1/4: Criando Bancos e Importando Dados             ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════════════════════════╝${NC}"
echo ""

cd "$PROJECT_DIR/scripts-linux"
bash 1_setup_automatico.sh 2>&1 | tee -a "$LOG_FILE"

echo ""
echo -e "${GREEN}✓ Bancos criados e dados importados!${NC}"
echo ""

echo -e "${BLUE}╔════════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║  ETAPA 2/4: Processando Dados (ETL)                       ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════════════════════════╝${NC}"
echo ""

bash 2_processar_etl.sh 2>&1 | tee -a "$LOG_FILE"

echo ""
echo -e "${GREEN}✓ Dados normalizados!${NC}"
echo ""

echo -e "${BLUE}╔════════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║  ETAPA 3/4: Criando Tabelas e Views Analíticas            ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════════════════════════╝${NC}"
echo ""

cd "$PROJECT_DIR"

# Copiar scripts
docker cp "$PROJECT_DIR/scripts/2-analise/01_criar_tabelas_normalizadas.sql" "$CONTAINER_NAME:/tmp/"
docker cp "$PROJECT_DIR/scripts/2-analise/04_criar_views_7_perguntas.sql" "$CONTAINER_NAME:/tmp/"
docker cp "$PROJECT_DIR/scripts/2-analise/05_consultar_respostas.sql" "$CONTAINER_NAME:/tmp/"

echo -e "${CYAN}Criando tabelas normalizadas...${NC}"
docker exec "$CONTAINER_NAME" /opt/mssql-tools18/bin/sqlcmd \
    -S localhost -U SA -P "$SA_PASSWORD" -C \
    -i /tmp/01_criar_tabelas_normalizadas.sql \
    2>&1 | tee -a "$LOG_FILE"

echo ""
echo -e "${CYAN}Criando views das 7 perguntas...${NC}"
docker exec "$CONTAINER_NAME" /opt/mssql-tools18/bin/sqlcmd \
    -S localhost -U SA -P "$SA_PASSWORD" -C \
    -i /tmp/04_criar_views_7_perguntas.sql \
    2>&1 | tee -a "$LOG_FILE"

echo ""
echo -e "${GREEN}✓ Views criadas!${NC}"
echo ""

echo -e "${BLUE}╔════════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║  ETAPA 4/4: Consultando Respostas                         ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════════════════════════╝${NC}"
echo ""

docker exec "$CONTAINER_NAME" /opt/mssql-tools18/bin/sqlcmd \
    -S localhost -U SA -P "$SA_PASSWORD" -C \
    -i /tmp/05_consultar_respostas.sql \
    2>&1 | tee -a "$LOG_FILE"

echo ""
echo -e "${GREEN}╔════════════════════════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║                                                            ║${NC}"
echo -e "${GREEN}║              ✓ SETUP CONCLUÍDO COM SUCESSO!                ║${NC}"
echo -e "${GREEN}║                                                            ║${NC}"
echo -e "${GREEN}╚════════════════════════════════════════════════════════════╝${NC}"
echo ""
echo -e "${CYAN}📊 VIEWS CRIADAS (7 Perguntas):${NC}"
echo ""
echo -e "  ${GREEN}1.${NC} vw_P1_MaiorValorizacaoUltimoAno"
echo -e "  ${GREEN}2.${NC} vw_P2_VolatilidadePorIndustria"
echo -e "  ${GREEN}3.${NC} vw_P3_MaiorVolumeNegociacao"
echo -e "  ${GREEN}4.${NC} vw_P4_CrescimentoConsistente5Anos"
echo -e "  ${GREEN}5.${NC} vw_P5_DesempenhoSetoresSP500"
echo -e "  ${GREEN}6.${NC} vw_P6_QuedaCriseCovid"
echo -e "  ${GREEN}7.${NC} vw_P7_DadosBaseParaDividendos"
echo ""
echo -e "${CYAN}💡 PRÓXIMOS PASSOS:${NC}"
echo ""
echo -e "  ${GREEN}1.${NC} Abra o DataGrip e atualize a conexão (F5)"
echo -e "  ${GREEN}2.${NC} Navegue até: datasets > Views"
echo -e "  ${GREEN}3.${NC} Execute queries de exemplo:"
echo ""
echo -e "     ${BLUE}SELECT TOP 10 * FROM vw_P1_MaiorValorizacaoUltimoAno${NC}"
echo -e "     ${BLUE}ORDER BY ValorizacaoPercentual DESC;${NC}"
echo ""
echo -e "${CYAN}📁 Log completo: $LOG_FILE${NC}"
echo ""
echo -e "${GREEN}═══════════════════════════════════════════════════════════${NC}"
echo ""
