#!/bin/bash

# =============================================
# SCRIPT MASTER: SETUP COMPLETO DO PROJETO
# =============================================
# Descrição: Executa TODA a configuração do projeto
# Cria bancos, importa dados, cria views e responde as 7 perguntas
# =============================================

set -e

# Cores
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m'

clear

echo -e "${CYAN}╔════════════════════════════════════════════════════════════╗${NC}"
echo -e "${CYAN}║                                                            ║${NC}"
echo -e "${CYAN}║   ${PURPLE}ANÁLISE QUANTITATIVA DE MERCADO FINANCEIRO${CYAN}           ║${NC}"
echo -e "${CYAN}║   ${GREEN}Setup Completo - S&P 500 + CSI500${CYAN}                     ║${NC}"
echo -e "${CYAN}║                                                            ║${NC}"
echo -e "${CYAN}╚════════════════════════════════════════════════════════════╝${NC}"
echo ""

# Configurações
CONTAINER_NAME="sqlserverCC"
SA_PASSWORD="Cc202505!"
PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LOG_DIR="$PROJECT_DIR/logs"
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
LOG_FILE="$LOG_DIR/setup_completo_${TIMESTAMP}.log"

# Criar diretório de logs
mkdir -p "$LOG_DIR"

# Função de log
log() {
    echo -e "$1" | tee -a "$LOG_FILE"
}

print_step() {
    echo ""
    echo -e "${BLUE}═══════════════════════════════════════════════════════════${NC}"
    echo -e "${BLUE}▶ $1${NC}"
    echo -e "${BLUE}═══════════════════════════════════════════════════════════${NC}"
    echo ""
}

print_success() {
    echo -e "${GREEN}✓ $1${NC}"
}

print_error() {
    echo -e "${RED}✗ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠ $1${NC}"
}

print_info() {
    echo -e "${CYAN}ℹ $1${NC}"
}

# Menu principal
show_menu() {
    # Se recebeu parâmetro, usa ele
    if [ -n "$1" ]; then
        opcao=$1
    else
        echo -e "${YELLOW}Escolha o que deseja fazer:${NC}"
        echo ""
        echo "  1) Setup Completo (Do Zero ao Fim)"
        echo "     └─ Cria bancos, importa dados, cria tabelas e views"
        echo ""
        echo "  2) Apenas Criar Views das 7 Perguntas"
        echo "     └─ Requer que setup básico já esteja feito"
        echo ""
        echo "  3) Apenas Consultar Respostas"
        echo "     └─ Exibe os resultados das 7 perguntas"
        echo ""
        echo "  4) Resetar Tudo e Recomeçar"
        echo "     └─ Apaga bancos e recria do zero"
        echo ""
        echo "  5) Sair"
        echo ""
        read -p "$(echo -e ${CYAN}Opção [1-5]: ${NC})" opcao
        echo ""
    fi

    echo "$opcao"
}

# Verificar se Docker está rodando
check_docker() {
    print_step "VERIFICANDO AMBIENTE"

    if ! command -v docker &> /dev/null; then
        print_error "Docker não está instalado!"
        exit 1
    fi
    print_success "Docker instalado"

    if ! docker ps &> /dev/null; then
        print_error "Docker daemon não está rodando!"
        print_info "Execute: sudo systemctl start docker"
        exit 1
    fi
    print_success "Docker daemon rodando"

    if ! docker ps | grep -q "$CONTAINER_NAME"; then
        print_warning "Container $CONTAINER_NAME não está rodando"
        print_info "Iniciando container..."
        docker-compose up -d || docker compose up -d
        sleep 10
    fi
    print_success "Container $CONTAINER_NAME está ativo"
}

# Setup completo
setup_completo() {
    print_step "ETAPA 1/4: CRIANDO BANCOS E IMPORTANDO DADOS"

    cd "$PROJECT_DIR/scripts-linux"

    print_info "Executando setup básico..."
    bash 1_setup_automatico.sh 2>&1 | tee -a "$LOG_FILE"
    print_success "Bancos criados e dados importados!"

    print_step "ETAPA 2/4: PROCESSANDO DADOS (ETL)"

    print_info "Normalizando dados..."
    bash 2_processar_etl.sh 2>&1 | tee -a "$LOG_FILE"
    print_success "Dados normalizados!"

    print_step "ETAPA 3/4: CRIANDO TABELAS E VIEWS ANALÍTICAS"

    cd "$PROJECT_DIR"

    # Copiar scripts para o container
    docker cp "$PROJECT_DIR/scripts/2-analise/01_criar_tabelas_normalizadas.sql" "$CONTAINER_NAME:/tmp/"
    docker cp "$PROJECT_DIR/scripts/2-analise/04_criar_views_7_perguntas.sql" "$CONTAINER_NAME:/tmp/"

    print_info "Criando tabelas normalizadas..."
    docker exec "$CONTAINER_NAME" /opt/mssql-tools18/bin/sqlcmd \
        -S localhost -U SA -P "$SA_PASSWORD" -C \
        -i /tmp/01_criar_tabelas_normalizadas.sql \
        2>&1 | tee -a "$LOG_FILE"

    print_info "Criando views das 7 perguntas..."
    docker exec "$CONTAINER_NAME" /opt/mssql-tools18/bin/sqlcmd \
        -S localhost -U SA -P "$SA_PASSWORD" -C \
        -i /tmp/04_criar_views_7_perguntas.sql \
        2>&1 | tee -a "$LOG_FILE"

    print_success "Views criadas com sucesso!"

    print_step "ETAPA 4/4: CONSULTANDO RESPOSTAS"

    docker cp "$PROJECT_DIR/scripts/2-analise/05_consultar_respostas.sql" "$CONTAINER_NAME:/tmp/"

    print_info "Executando queries de análise..."
    docker exec "$CONTAINER_NAME" /opt/mssql-tools18/bin/sqlcmd \
        -S localhost -U SA -P "$SA_PASSWORD" -C \
        -i /tmp/05_consultar_respostas.sql \
        2>&1 | tee -a "$LOG_FILE"

    print_success "Análise completa!"
}

# Apenas criar views
criar_views() {
    print_step "CRIANDO VIEWS DAS 7 PERGUNTAS"

    docker cp "$PROJECT_DIR/scripts/2-analise/04_criar_views_7_perguntas.sql" "$CONTAINER_NAME:/tmp/"

    docker exec "$CONTAINER_NAME" /opt/mssql-tools18/bin/sqlcmd \
        -S localhost -U SA -P "$SA_PASSWORD" -C \
        -i /tmp/04_criar_views_7_perguntas.sql \
        2>&1 | tee -a "$LOG_FILE"

    print_success "Views criadas!"
}

# Consultar respostas
consultar_respostas() {
    print_step "CONSULTANDO RESPOSTAS DAS 7 PERGUNTAS"

    docker cp "$PROJECT_DIR/scripts/2-analise/05_consultar_respostas.sql" "$CONTAINER_NAME:/tmp/"

    docker exec "$CONTAINER_NAME" /opt/mssql-tools18/bin/sqlcmd \
        -S localhost -U SA -P "$SA_PASSWORD" -C \
        -i /tmp/05_consultar_respostas.sql \
        2>&1 | tee -a "$LOG_FILE"
}

# Resetar tudo
resetar_tudo() {
    print_step "RESETANDO TODO O PROJETO"

    print_warning "ATENÇÃO: Isso vai apagar TODOS os dados!"
    read -p "Tem certeza? Digite 'SIM' para confirmar: " confirm

    if [ "$confirm" != "SIM" ]; then
        print_info "Operação cancelada"
        return
    fi

    print_info "Apagando bancos de dados..."

    docker exec "$CONTAINER_NAME" /opt/mssql-tools18/bin/sqlcmd \
        -S localhost -U SA -P "$SA_PASSWORD" -C \
        -Q "DROP DATABASE IF EXISTS datasets; DROP DATABASE IF EXISTS master;" \
        2>&1 | tee -a "$LOG_FILE"

    print_success "Bancos apagados!"
    print_info "Execute a opção 1 para recriar tudo"
}

# Mostrar resumo final
show_summary() {
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
    echo -e "${CYAN}📁 ARQUIVOS IMPORTANTES:${NC}"
    echo ""
    echo -e "  ${YELLOW}→${NC} Perguntas:  perguntas-analise.md"
    echo -e "  ${YELLOW}→${NC} README:     README.md"
    echo -e "  ${YELLOW}→${NC} Logs:       logs/setup_completo_${TIMESTAMP}.log"
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
    echo -e "${CYAN}═══════════════════════════════════════════════════════════${NC}"
    echo ""
}

# Main
main() {
    check_docker

    # Aceita opção via parâmetro ou menu
    if [ -n "$1" ]; then
        opcao=$1
    else
        opcao=$(show_menu)
    fi

    case $opcao in
        1)
            setup_completo
            show_summary
            ;;
        2)
            criar_views
            print_success "Views criadas com sucesso!"
            ;;
        3)
            consultar_respostas
            print_success "Consultas executadas!"
            ;;
        4)
            resetar_tudo
            ;;
        5)
            print_info "Saindo..."
            exit 0
            ;;
        *)
            print_error "Opção inválida!"
            exit 1
            ;;
    esac

    echo ""
    print_info "Log completo salvo em: $LOG_FILE"
    echo ""
}

# Executar
main "$@"
