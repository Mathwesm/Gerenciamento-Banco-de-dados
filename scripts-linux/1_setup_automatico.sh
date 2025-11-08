#!/bin/bash

# ========================================
# SCRIPT DE SETUP AUTOMATIZADO
# Executa todos os passos do zero
# ========================================

set -e  # Parar em caso de erro

echo "========================================="
echo "SETUP AUTOMATIZADO DO PROJETO"
echo "========================================="
echo ""

# Cores para output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# ========================================
# PASSO 1: Verificar pré-requisitos
# ========================================
echo -e "${YELLOW}[1/7] Verificando pré-requisitos...${NC}"

if ! command -v docker &> /dev/null; then
    echo -e "${RED}ERRO: Docker não está instalado!${NC}"
    exit 1
fi

if [ ! -d "datasets" ]; then
    echo -e "${RED}ERRO: Pasta 'datasets' não encontrada!${NC}"
    exit 1
fi

if [ ! -f "datasets/S&P-500-companies.csv" ]; then
    echo -e "${RED}ERRO: Arquivo S&P-500-companies.csv não encontrado!${NC}"
    exit 1
fi

echo -e "${GREEN}✓ Pré-requisitos OK${NC}"
echo ""

# ========================================
# PASSO 2: Iniciar container
# ========================================
echo -e "${YELLOW}[2/7] Iniciando container Docker...${NC}"

docker compose down 2>/dev/null || true
docker compose up -d

echo -e "${GREEN}✓ Container iniciado${NC}"
echo ""

# ========================================
# PASSO 3: Aguardar SQL Server inicializar
# ========================================
echo -e "${YELLOW}[3/7] Aguardando SQL Server inicializar (60 segundos)...${NC}"

for i in {60..1}; do
    echo -ne "${YELLOW}Aguardando... ${i}s restantes\r${NC}"
    sleep 1
done

echo -e "\n${GREEN}✓ SQL Server deve estar pronto${NC}"
echo ""

# Verificar se está rodando
echo -e "${YELLOW}Verificando se SQL Server está escutando...${NC}"
docker logs sqlserverCC 2>&1 | grep -q "Server is listening" && echo -e "${GREEN}✓ SQL Server está rodando${NC}" || echo -e "${YELLOW}⚠ SQL Server pode ainda estar inicializando...${NC}"
echo ""

# ========================================
# PASSO 4: Copiar script
# ========================================
echo -e "${YELLOW}[4/7] Copiando script de setup para o container...${NC}"

if [ ! -f "scripts/1-setup/01_setup_completo.sql" ]; then
    echo -e "${RED}ERRO: Script scripts/1-setup/01_setup_completo.sql não encontrado!${NC}"
    exit 1
fi

docker cp scripts/1-setup/01_setup_completo.sql sqlserverCC:/tmp/01_setup_completo.sql

echo -e "${GREEN}✓ Script copiado${NC}"
echo ""

# ========================================
# PASSO 5: Executar setup completo
# ========================================
echo -e "${YELLOW}[5/7] Executando setup completo (pode levar 2-5 minutos)...${NC}"
echo ""

docker exec sqlserverCC /opt/mssql-tools18/bin/sqlcmd -S localhost -U SA -P "Cc202505!" -i /tmp/01_setup_completo.sql -C

echo ""
echo -e "${GREEN}✓ Setup executado${NC}"
echo ""

# ========================================
# PASSO 6: Verificar instalação
# ========================================
echo -e "${YELLOW}[6/7] Verificando instalação...${NC}"
echo ""

echo -e "${YELLOW}Databases criados:${NC}"
docker exec sqlserverCC /opt/mssql-tools18/bin/sqlcmd -S localhost -U SA -P "Cc202505!" -Q "SELECT name FROM sys.databases WHERE name IN ('master', 'datasets') ORDER BY name" -C -h-1 -W

echo ""
echo -e "${YELLOW}Tabelas no master:${NC}"
docker exec sqlserverCC bash -c "/opt/mssql-tools18/bin/sqlcmd -S localhost -U SA -P 'Cc202505!' -C -h-1 -W <<'EOF'
USE master
GO
SELECT name FROM sys.tables WHERE type = 'U' AND name NOT LIKE 'spt%' AND name NOT LIKE 'MS%' ORDER BY name
GO
EOF"

echo ""
echo -e "${YELLOW}Contagem de registros importados:${NC}"
docker exec sqlserverCC bash -c "/opt/mssql-tools18/bin/sqlcmd -S localhost -U SA -P 'Cc202505!' -C -W <<'EOF'
USE datasets
GO
SELECT
    'SP500_companies' as Tabela,
    COUNT(*) as Total
FROM SP500_companies
UNION ALL
SELECT 'SP500_fred', COUNT(*) FROM SP500_fred
UNION ALL
SELECT 'CSI500', COUNT(*) FROM CSI500
GO
EOF"

echo ""
echo -e "${GREEN}✓ Verificação concluída${NC}"
echo ""

# ========================================
# PASSO 7: Informações finais
# ========================================
echo -e "${YELLOW}[7/7] Informações de acesso${NC}"
echo ""
echo "========================================="
echo -e "${GREEN}SETUP CONCLUÍDO COM SUCESSO!${NC}"
echo "========================================="
echo ""
echo "Credenciais para DataGrip:"
echo "  Host: localhost"
echo "  Port: 1433"
echo "  User: SA"
echo "  Password: Cc202505!"
echo "  Database: master"
echo ""
echo "Próximos passos:"
echo "  1. Abra o DataGrip"
echo "  2. Crie uma nova conexão com as credenciais acima"
echo "  3. Configure os schemas (datasets + master)"
echo "  4. Faça Refresh (F5)"
echo "  5. Abra scripts/02_consultas.sql para testar"
echo ""
echo "Comandos úteis:"
echo "  docker compose ps        # Status do container"
echo "  docker compose down      # Parar container"
echo "  docker compose up -d     # Iniciar container"
echo ""
echo "========================================="
