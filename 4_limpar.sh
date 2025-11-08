2#!/bin/bash

# ========================================
# SCRIPT DE LIMPEZA - Menu Interativo
# ========================================

set -e

# Cores
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}    SCRIPT DE LIMPEZA DO PROJETO${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""
echo "Escolha uma opção:"
echo ""
echo -e "${GREEN}1)${NC} Limpar apenas os DADOS (mantém estrutura)"
echo "   - Remove todos os registros das tabelas"
echo "   - Mantém tabelas, databases e estrutura"
echo "   - Útil para reimportar dados"
echo ""
echo -e "${YELLOW}2)${NC} RESETAR TUDO do zero"
echo "   - Remove TODAS as tabelas"
echo "   - Remove database DATASETS"
echo "   - Sistema volta ao estado inicial"
echo ""
echo -e "${RED}3)${NC} Cancelar"
echo ""
read -p "Digite sua escolha [1-3]: " choice

case $choice in
    1)
        echo ""
        echo -e "${YELLOW}⚠️  Você escolheu: LIMPAR DADOS${NC}"
        echo "Isso vai remover todos os registros mas manter a estrutura."
        read -p "Tem certeza? (s/N): " confirm

        if [[ $confirm == [sS] ]]; then
            echo ""
            echo -e "${GREEN}Copiando script para o container...${NC}"
            docker cp scripts/3-manutencao/limpar_dados.sql sqlserverCC:/tmp/limpar_dados.sql

            echo -e "${GREEN}Executando limpeza de dados...${NC}"
            docker exec sqlserverCC /opt/mssql-tools18/bin/sqlcmd -S localhost -U SA -P "Cc202505!" -i /tmp/limpar_dados.sql -C

            echo ""
            echo -e "${GREEN}✅ Limpeza de dados concluída!${NC}"
            echo "Para reimportar dados, execute: ./1_setup_automatico.sh"
        else
            echo -e "${RED}Operação cancelada.${NC}"
        fi
        ;;

    2)
        echo ""
        echo -e "${RED}⚠️⚠️⚠️  ATENÇÃO! ⚠️⚠️⚠️${NC}"
        echo -e "${RED}Você escolheu: RESETAR TUDO${NC}"
        echo "Isso vai:"
        echo "  - Dropar TODAS as tabelas do master"
        echo "  - Dropar o database DATASETS"
        echo "  - APAGAR TODOS OS DADOS permanentemente"
        echo ""
        read -p "TEM CERTEZA ABSOLUTA? Digite 'RESETAR' para confirmar: " confirm

        if [[ $confirm == "RESETAR" ]]; then
            echo ""
            echo -e "${YELLOW}Copiando script para o container...${NC}"
            docker cp scripts/3-manutencao/resetar_tudo.sql sqlserverCC:/tmp/resetar_tudo.sql

            echo -e "${YELLOW}Executando reset completo...${NC}"
            docker exec sqlserverCC /opt/mssql-tools18/bin/sqlcmd -S localhost -U SA -P "Cc202505!" -i /tmp/resetar_tudo.sql -C

            echo ""
            echo -e "${GREEN}✅ Reset completo finalizado!${NC}"
            echo "Para recriar tudo do zero, execute: ./1_setup_automatico.sh"
        else
            echo -e "${RED}Operação cancelada (confirmação incorreta).${NC}"
        fi
        ;;

    3)
        echo -e "${GREEN}Operação cancelada.${NC}"
        exit 0
        ;;

    *)
        echo -e "${RED}Opção inválida!${NC}"
        exit 1
        ;;
esac

echo ""
echo -e "${BLUE}========================================${NC}"
