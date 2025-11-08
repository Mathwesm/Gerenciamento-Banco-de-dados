-- ========================================
-- CONSULTAS PARA AS TABELAS DO DATASETS
-- ========================================

USE datasets;

-- ========================================
-- 1. VERIFICAR TODAS AS TABELAS E CONTAGEM DE REGISTROS
-- ========================================
SELECT
    'SP500_companies' as Tabela,
    COUNT(*) as Total_Registros
FROM SP500_companies
UNION ALL
SELECT 'SP500_fred', COUNT(*) FROM SP500_fred
UNION ALL
SELECT 'CSI500', COUNT(*) FROM CSI500;


-- ========================================
-- 2. CONSULTAR SP500_COMPANIES (primeiros 100 registros)
-- ========================================
SELECT TOP 100 *
FROM SP500_companies;


-- ========================================
-- 3. CONSULTAR SP500_FRED (primeiros 100 registros)
-- ========================================
SELECT TOP 100 *
FROM SP500_fred;


-- ========================================
-- 4. CONSULTAR CSI500 (primeiros 100 registros)
-- ========================================
SELECT TOP 100 *
FROM CSI500;


-- ========================================
-- 5. VER ESTRUTURA DAS TABELAS
-- ========================================
SELECT
    TABLE_NAME,
    COLUMN_NAME,
    DATA_TYPE,
    CHARACTER_MAXIMUM_LENGTH
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_NAME IN ('SP500_companies', 'SP500_fred', 'CSI500')
ORDER BY TABLE_NAME, ORDINAL_POSITION;


-- ========================================
-- 6. CONSULTAR TODOS OS DADOS (CUIDADO: PODE SER MUITO!)
-- ========================================

-- SP500_companies - TODOS os registros
-- SELECT * FROM SP500_companies;

-- SP500_fred - TODOS os registros
-- SELECT * FROM SP500_fred;

-- CSI500 - TODOS os registros (1.7 MILHÕES - NÃO RECOMENDADO!)
-- SELECT * FROM CSI500;


-- ========================================
-- 7. CONSULTAS COM FILTROS (EXEMPLOS)
-- ========================================

-- Primeiros 10 registros de cada tabela
SELECT TOP 10 'SP500_companies' as Origem, registro FROM SP500_companies
UNION ALL
SELECT TOP 10 'SP500_fred', registro FROM SP500_fred
UNION ALL
SELECT TOP 10 'CSI500', registro FROM CSI500;


-- ========================================
-- 8. BUSCAR POR PALAVRA-CHAVE (EXEMPLO)
-- ========================================

-- Buscar registros que contêm "Apple" ou "AAPL" no SP500_companies
SELECT *
FROM SP500_companies
WHERE registro LIKE '%Apple%' OR registro LIKE '%AAPL%';

-- Buscar registros de 2020 no CSI500 (exemplo)
SELECT TOP 100 *
FROM CSI500
WHERE registro LIKE '%2020%';


-- ========================================
-- 9. EXPORTAR AMOSTRA DE DADOS
-- ========================================

-- Amostra aleatória de 50 registros do CSI500
SELECT TOP 50 *
FROM CSI500
ORDER BY NEWID();


-- ========================================
-- 10. VERIFICAR TAMANHO DAS TABELAS
-- ========================================
SELECT
    t.NAME AS TableName,
    p.rows AS RowCounts,
    SUM(a.total_pages) * 8 AS TotalSpaceKB,
    SUM(a.used_pages) * 8 AS UsedSpaceKB,
    (SUM(a.total_pages) - SUM(a.used_pages)) * 8 AS UnusedSpaceKB
FROM
    sys.tables t
INNER JOIN
    sys.indexes i ON t.OBJECT_ID = i.object_id
INNER JOIN
    sys.partitions p ON i.object_id = p.OBJECT_ID AND i.index_id = p.index_id
INNER JOIN
    sys.allocation_units a ON p.partition_id = a.container_id
WHERE
    t.NAME IN ('SP500_companies', 'SP500_fred', 'CSI500')
    AND t.is_ms_shipped = 0
    AND i.OBJECT_ID > 255
GROUP BY
    t.Name, p.Rows
ORDER BY
    t.Name;
