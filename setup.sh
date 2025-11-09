#!/bin/bash

# ========================================
# SCRIPT DE SETUP AUTOMATIZADO
# ========================================
# Executa todo o processo de setup do projeto
# - Copia CSVs para o container
# - Executa 01_setup_completo.sql
# - Executa 02_processar_dados_etl.sql
# ========================================

set -e  # Exit on error

# Cores para output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Configurações
CONTAINER_NAME="sqlserverCC"
SA_PASSWORD="Cc202505!"
CONTAINER_DATASETS_PATH="/var/opt/mssql/datasets"
LOCAL_DATASETS_PATH="./datasets"
SCRIPTS_PATH="./scripts/1-setup"

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}INICIANDO SETUP AUTOMATIZADO${NC}"
echo -e "${BLUE}========================================${NC}"

# ========================================
# PARTE 1: CRIAR DIRETÓRIO NO CONTAINER
# ========================================
echo -e "\n${YELLOW}[1/5]${NC} Criando diretório de datasets no container..."
docker exec $CONTAINER_NAME mkdir -p $CONTAINER_DATASETS_PATH
echo -e "${GREEN}✓ Diretório criado${NC}"

# ========================================
# PARTE 2: COPIAR CSVs PARA O CONTAINER
# ========================================
echo -e "\n${YELLOW}[2/5]${NC} Copiando arquivos CSV para o container..."

if [ ! -f "$LOCAL_DATASETS_PATH/sp500_data_part1.csv" ]; then
    echo -e "${YELLOW}✗ Erro: Arquivo sp500_data_part1.csv não encontrado${NC}"
    exit 1
fi

echo "  - Copiando sp500_data_part1.csv..."
docker cp "$LOCAL_DATASETS_PATH/sp500_data_part1.csv" "$CONTAINER_NAME:$CONTAINER_DATASETS_PATH/"

echo "  - Copiando sp500_data_part2.csv..."
docker cp "$LOCAL_DATASETS_PATH/sp500_data_part2.csv" "$CONTAINER_NAME:$CONTAINER_DATASETS_PATH/"

echo "  - Copiando CSI500-part-1.csv..."
docker cp "$LOCAL_DATASETS_PATH/CSI500-part-1.csv" "$CONTAINER_NAME:$CONTAINER_DATASETS_PATH/"

echo "  - Copiando CSI500-part-2.csv..."
docker cp "$LOCAL_DATASETS_PATH/CSI500-part-2.csv" "$CONTAINER_NAME:$CONTAINER_DATASETS_PATH/"

echo -e "${GREEN}✓ Arquivos copiados com sucesso${NC}"

# ========================================
# PARTE 3: EXECUTAR SETUP COMPLETO
# ========================================
echo -e "\n${YELLOW}[3/5]${NC} Executando script 01_setup_completo.sql..."
docker cp "$SCRIPTS_PATH/01_setup_completo.sql" "$CONTAINER_NAME:/tmp/"

docker exec $CONTAINER_NAME /opt/mssql-tools18/bin/sqlcmd \
    -S localhost \
    -U SA \
    -P "$SA_PASSWORD" \
    -i /tmp/01_setup_completo.sql \
    -C > /tmp/setup_output.log 2>&1

if grep -q "SETUP COMPLETO FINALIZADO COM SUCESSO" /tmp/setup_output.log; then
    echo -e "${GREEN}✓ Setup completo executado com sucesso${NC}"
else
    echo -e "${YELLOW}⚠ Verifique o arquivo /tmp/setup_output.log${NC}"
fi

# ========================================
# PARTE 4: EXECUTAR ETL
# ========================================
echo -e "\n${YELLOW}[4/5]${NC} Executando script 02_processar_dados_etl.sql..."
docker cp "$SCRIPTS_PATH/02_processar_dados_etl.sql" "$CONTAINER_NAME:/tmp/"

docker exec $CONTAINER_NAME /opt/mssql-tools18/bin/sqlcmd \
    -S localhost \
    -U SA \
    -P "$SA_PASSWORD" \
    -i /tmp/02_processar_dados_etl.sql \
    -C > /tmp/etl_output.log 2>&1

if grep -q "ETL CONCLUÍDO COM SUCESSO" /tmp/etl_output.log; then
    echo -e "${GREEN}✓ ETL executado com sucesso${NC}"
else
    echo -e "${YELLOW}⚠ Verifique o arquivo /tmp/etl_output.log${NC}"
fi

# ========================================
# PARTE 5: RESUMO FINAL
# ========================================
echo -e "\n${YELLOW}[5/5]${NC} Exibindo resumo final..."

docker exec $CONTAINER_NAME /opt/mssql-tools18/bin/sqlcmd \
    -S localhost \
    -U SA \
    -P "$SA_PASSWORD" \
    -C <<'SQL'
USE FinanceDB;
GO

PRINT '';
PRINT '========================================';
PRINT 'RESUMO FINAL DO SETUP';
PRINT '========================================';
PRINT '';
PRINT 'S&P 500:';
SELECT '  - Tempo: ' + CAST(COUNT(*) AS VARCHAR(10)) as Status FROM Tempo;
SELECT '  - Empresas: ' + CAST(COUNT(*) AS VARCHAR(10)) as Status FROM Empresas;
SELECT '  - PrecoAcao: ' + CAST(COUNT(*) AS VARCHAR(10)) as Status FROM PrecoAcao;
SELECT '  - Dividendos: ' + CAST(COUNT(*) AS VARCHAR(10)) as Status FROM Dividendos;

PRINT '';
PRINT 'CSI500:';
SELECT '  - EmpresasCSI500: ' + CAST(COUNT(*) AS VARCHAR(10)) as Status FROM EmpresasCSI500;
SELECT '  - PrecoAcaoCSI500: ' + CAST(COUNT(*) AS VARCHAR(10)) as Status FROM PrecoAcaoCSI500;
SELECT '  - CSI500Historico: ' + CAST(COUNT(*) AS VARCHAR(10)) as Status FROM CSI500Historico;
GO
SQL

echo ""
echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}✓ SETUP FINALIZADO COM SUCESSO!${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""
echo -e "${BLUE}Próximos passos:${NC}"
echo "  1. Abra o DataGrip"
echo "  2. Execute os scripts de análise em scripts/2-analise/"
echo "  3. Crie as views e consultas conforme necessário"
echo ""
