-- ========================================
-- TESTE RÁPIDO - DATASETS
-- Execute estas queries UMA POR VEZ no DataGrip
-- ========================================

-- Query 1: Contar registros
SELECT
    'SP500_companies' as Tabela,
    COUNT(*) as Total
FROM datasets.dbo.SP500_companies
UNION ALL
SELECT 'SP500_fred', COUNT(*) FROM datasets.dbo.SP500_fred
UNION ALL
SELECT 'CSI500', COUNT(*) FROM datasets.dbo.CSI500;

-- ========================================

-- Query 2: Ver 10 empresas
SELECT TOP 10 *
FROM datasets.dbo.SP500_companies;

-- ========================================

-- Query 3: Ver 10 preços S&P 500
SELECT TOP 10 *
FROM datasets.dbo.SP500_fred;

-- ========================================

-- Query 4: Ver 10 registros CSI500
SELECT TOP 10 *
FROM datasets.dbo.CSI500;

-- ========================================

-- Query 5: Buscar Apple
SELECT *
FROM datasets.dbo.SP500_companies
WHERE registro LIKE '%Apple%';

-- ========================================

-- Query 6: Buscar Microsoft
SELECT *
FROM datasets.dbo.SP500_companies
WHERE registro LIKE '%Microsoft%';
