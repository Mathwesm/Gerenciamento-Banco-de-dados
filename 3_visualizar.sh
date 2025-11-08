#!/bin/bash

# ========================================
# SCRIPT: VISUALIZAR TABELAS
# ========================================
# Descrição: Mostra os dados de todas as tabelas
# ========================================

set -e

# Cores
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}    VISUALIZAR DADOS DAS TABELAS${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""

# Verificar se container está rodando
if ! docker ps | grep -q sqlserverCC; then
    echo "Container não está rodando. Inicie com: docker compose up -d"
    exit 1
fi

echo -e "${GREEN}Copiando script para o container...${NC}"
docker cp scripts/2-consultas/visualizar_tabelas.sql sqlserverCC:/tmp/visualizar_tabelas.sql

echo -e "${GREEN}Executando consultas...${NC}"
echo ""
docker exec sqlserverCC /opt/mssql-tools18/bin/sqlcmd -S localhost -U SA -P "Cc202505!" -i /tmp/visualizar_tabelas.sql -C

echo ""
echo -e "${BLUE}========================================${NC}"
echo -e "${GREEN}✅ Visualização concluída!${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""
