-- ========================================
-- VISUALIZAR DADOS PRINCIPAIS DOS DATASETS
-- Database: datasets
-- ========================================

USE datasets;

-- ========================================
-- 1. RESUMO GERAL - Quantidade de registros
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
-- 2. SP500_COMPANIES - Ver primeiros 50 registros
-- ========================================
SELECT TOP 50
    registro as DadosEmpresa
FROM SP500_companies;


-- ========================================
-- 3. SP500_FRED - Ver primeiros 50 registros
-- ========================================
SELECT TOP 50
    registro as DadosFRED
FROM SP500_fred;


-- ========================================
-- 4. CSI500 - Ver primeiros 50 registros
-- ========================================
SELECT TOP 50
    registro as DadosCSI500
FROM CSI500;


-- ========================================
-- 5. BUSCAR EMPRESAS ESPECÍFICAS (EXEMPLO)
-- ========================================

-- Buscar Apple
SELECT registro
FROM SP500_companies
WHERE registro LIKE '%Apple%' OR registro LIKE '%AAPL%';

-- Buscar Microsoft
SELECT registro
FROM SP500_companies
WHERE registro LIKE '%Microsoft%' OR registro LIKE '%MSFT%';

-- Buscar Amazon
SELECT registro
FROM SP500_companies
WHERE registro LIKE '%Amazon%' OR registro LIKE '%AMZN%';

-- Buscar Google/Alphabet
SELECT registro
FROM SP500_companies
WHERE registro LIKE '%Alphabet%' OR registro LIKE '%Google%' OR registro LIKE '%GOOGL%';


-- ========================================
-- 6. BUSCAR POR SETOR (EXEMPLO)
-- ========================================

-- Buscar empresas de tecnologia
SELECT registro
FROM SP500_companies
WHERE registro LIKE '%Technology%' OR registro LIKE '%Information%';

-- Buscar empresas financeiras
SELECT registro
FROM SP500_companies
WHERE registro LIKE '%Financial%' OR registro LIKE '%Bank%';


-- ========================================
-- 7. DADOS POR PERÍODO - CSI500 (EXEMPLO)
-- ========================================

-- Dados de 2020
SELECT TOP 100 registro
FROM CSI500
WHERE registro LIKE '%2020%';

-- Dados de 2021
SELECT TOP 100 registro
FROM CSI500
WHERE registro LIKE '%2021%';

-- Dados de 2022
SELECT TOP 100 registro
FROM CSI500
WHERE registro LIKE '%2022%';


-- ========================================
-- 8. AMOSTRA ALEATÓRIA DE CADA TABELA
-- ========================================

-- 20 registros aleatórios do SP500_companies
SELECT TOP 20 registro
FROM SP500_companies
ORDER BY NEWID();

-- 20 registros aleatórios do SP500_fred
SELECT TOP 20 registro
FROM SP500_fred
ORDER BY NEWID();

-- 20 registros aleatórios do CSI500
SELECT TOP 20 registro
FROM CSI500
ORDER BY NEWID();


-- ========================================
-- 9. PRIMEIROS E ÚLTIMOS REGISTROS
-- ========================================

-- Primeiros 10 do SP500_companies
SELECT TOP 10 registro as PrimeirosRegistros
FROM SP500_companies;

-- Primeiros 10 do CSI500
SELECT TOP 10 registro as PrimeirosRegistros
FROM CSI500;


-- ========================================
-- 10. ESTATÍSTICAS DAS TABELAS
-- ========================================

-- Ver tamanho e uso de espaço
SELECT
    t.NAME AS Tabela,
    p.rows AS Total_Linhas,
    SUM(a.total_pages) * 8 AS TamanhoTotal_KB,
    CAST(SUM(a.total_pages) * 8.0 / 1024 AS DECIMAL(10,2)) AS TamanhoTotal_MB,
    SUM(a.used_pages) * 8 AS EspacoUsado_KB,
    (SUM(a.total_pages) - SUM(a.used_pages)) * 8 AS EspacoLivre_KB
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
    p.Rows DESC;
