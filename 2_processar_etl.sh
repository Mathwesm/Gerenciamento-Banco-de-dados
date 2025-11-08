#!/bin/bash

# ========================================
# SCRIPT: EXECUTAR ETL
# ========================================
# Descrição: Processa dados brutos e popula tabelas do master
# ========================================

set -e

# Cores
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}    PROCESSAMENTO ETL${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""

# Verificar se container está rodando
if ! docker ps | grep -q sqlserverCC; then
    echo -e "${YELLOW}Container não está rodando. Iniciando...${NC}"
    docker compose up -d
    echo "Aguardando SQL Server inicializar (30 segundos)..."
    sleep 30
fi

echo -e "${GREEN}[1/3] Copiando script ETL para o container...${NC}"
docker cp scripts/1-setup/02_processar_dados_etl.sql sqlserverCC:/tmp/02_processar_dados_etl.sql

echo -e "${GREEN}[2/3] Executando processamento ETL...${NC}"
echo ""
docker exec sqlserverCC /opt/mssql-tools18/bin/sqlcmd -S localhost -U SA -P "Cc202505!" -i /tmp/02_processar_dados_etl.sql -C

echo ""
echo -e "${GREEN}[3/3] Verificando resultados...${NC}"
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

echo ""
echo -e "${BLUE}========================================${NC}"
echo -e "${GREEN}✅ PROCESSAMENTO ETL CONCLUÍDO!${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""
echo "Próximos passos:"
echo "  1. Abra o DataGrip e faça Refresh (F5)"
echo "  2. Verifique os dados nas tabelas"
echo "  3. Execute queries de análise"
echo ""
