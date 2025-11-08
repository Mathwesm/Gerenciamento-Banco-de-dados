-- ========================================
-- SCRIPT DE TESTE - DATAGRIP
-- Execute estas queries para verificar se está tudo funcionando
-- ========================================

-- ========================================
-- TESTE 1: Verificar databases disponíveis
-- ========================================
SELECT
    name as DatabaseName,
    database_id as ID,
    create_date as DataCriacao
FROM sys.databases
WHERE name IN ('master', 'datasets')
ORDER BY name;

-- ========================================
-- TESTE 2: Resumo de todas as tabelas
-- ========================================
-- Tabelas do MASTER
SELECT
    'MASTER' as DatabaseName,
    name as Tabela,
    'Dimensional' as Tipo
FROM master.sys.tables
WHERE type = 'U'
  AND name NOT LIKE 'spt%'
  AND name NOT LIKE 'MS%'

UNION ALL

-- Tabelas do DATASETS
SELECT
    'DATASETS' as DatabaseName,
    name as Tabela,
    'Dados Brutos' as Tipo
FROM datasets.sys.tables
WHERE type = 'U'
ORDER BY DatabaseName, Tabela;

-- ========================================
-- TESTE 3: Contagem de registros (DATASETS)
-- ========================================
USE datasets;
GO

SELECT
    'SP500_companies' as Tabela,
    COUNT(*) as TotalRegistros,
    'Empresas do S&P 500' as Descricao
FROM SP500_companies

UNION ALL

SELECT
    'SP500_fred',
    COUNT(*),
    'Dados históricos S&P 500'
FROM SP500_fred

UNION ALL

SELECT
    'CSI500',
    COUNT(*),
    'Dados do índice CSI 500'
FROM CSI500
ORDER BY Tabela;
GO

-- ========================================
-- TESTE 4: Primeiros registros de cada tabela
-- ========================================
-- SP500_companies
PRINT '=== SP500_COMPANIES (primeiros 5 registros) ===';
SELECT TOP 5 * FROM datasets.dbo.SP500_companies;

-- SP500_fred
PRINT '=== SP500_FRED (primeiros 5 registros) ===';
SELECT TOP 5 * FROM datasets.dbo.SP500_fred;

-- CSI500
PRINT '=== CSI500 (primeiros 5 registros) ===';
SELECT TOP 5 * FROM datasets.dbo.CSI500;

-- ========================================
-- TESTE 5: Verificar estrutura das tabelas do MASTER
-- ========================================
USE master;
GO

SELECT
    t.name as Tabela,
    c.name as Coluna,
    ty.name as TipoDado,
    c.max_length as Tamanho,
    c.is_nullable as AceitaNulo
FROM sys.tables t
INNER JOIN sys.columns c ON t.object_id = c.object_id
INNER JOIN sys.types ty ON c.user_type_id = ty.user_type_id
WHERE t.type = 'U'
  AND t.name NOT LIKE 'spt%'
  AND t.name NOT LIKE 'MS%'
ORDER BY t.name, c.column_id;
GO

-- ========================================
-- TESTE 6: Verificar Foreign Keys (Relacionamentos)
-- ========================================
USE master;
GO

SELECT
    OBJECT_NAME(f.parent_object_id) as TabelaPai,
    COL_NAME(fc.parent_object_id, fc.parent_column_id) as ColunaPai,
    OBJECT_NAME(f.referenced_object_id) as TabelaReferenciada,
    COL_NAME(fc.referenced_object_id, fc.referenced_column_id) as ColunaReferenciada,
    f.name as NomeFK
FROM sys.foreign_keys AS f
INNER JOIN sys.foreign_key_columns AS fc ON f.object_id = fc.constraint_object_id
ORDER BY TabelaPai;
GO

-- ========================================
-- TESTE 7: Verificar Índices criados
-- ========================================
USE master;
GO

SELECT
    OBJECT_NAME(i.object_id) as Tabela,
    i.name as NomeIndice,
    i.type_desc as TipoIndice,
    COL_NAME(ic.object_id, ic.column_id) as Coluna
FROM sys.indexes i
INNER JOIN sys.index_columns ic ON i.object_id = ic.object_id AND i.index_id = ic.index_id
WHERE OBJECT_NAME(i.object_id) IN ('PrecoAcao', 'Dividendos', 'Tempo')
  AND i.name IS NOT NULL
ORDER BY Tabela, NomeIndice;
GO

-- ========================================
-- TESTE 8: Estatísticas gerais
-- ========================================
SELECT
    '🎯 RESUMO GERAL DO PROJETO' as Titulo;

SELECT
    'Total de Databases' as Metrica,
    COUNT(*) as Valor
FROM sys.databases
WHERE name IN ('master', 'datasets')

UNION ALL

SELECT
    'Tabelas no Master',
    COUNT(*)
FROM master.sys.tables
WHERE type = 'U'
  AND name NOT LIKE 'spt%'
  AND name NOT LIKE 'MS%'

UNION ALL

SELECT
    'Tabelas no Datasets',
    COUNT(*)
FROM datasets.sys.tables
WHERE type = 'U';

-- Total de registros
SELECT
    'Total de Registros Importados' as Metrica,
    (SELECT COUNT(*) FROM datasets.dbo.SP500_companies) +
    (SELECT COUNT(*) FROM datasets.dbo.SP500_fred) +
    (SELECT COUNT(*) FROM datasets.dbo.CSI500) as Valor;

-- ========================================
-- TESTE 9: Consulta de exemplo (análise real)
-- ========================================
-- Exemplo: Analisar distribuição de registros por tabela
USE datasets;
GO

PRINT '=== ANÁLISE DE DISTRIBUIÇÃO DE DADOS ===';

SELECT
    Tabela,
    TotalRegistros,
    CAST(TotalRegistros * 100.0 / SUM(TotalRegistros) OVER() AS DECIMAL(5,2)) as PercentualTotal
FROM (
    SELECT 'SP500_companies' as Tabela, COUNT(*) as TotalRegistros FROM SP500_companies
    UNION ALL
    SELECT 'SP500_fred', COUNT(*) FROM SP500_fred
    UNION ALL
    SELECT 'CSI500', COUNT(*) FROM CSI500
) as Dados
ORDER BY TotalRegistros DESC;
GO

-- ========================================
-- TESTE 10: Verificar se tabelas estão vazias ou populadas
-- ========================================
USE master;
GO

PRINT '=== STATUS DAS TABELAS DO MASTER (vazias ou populadas) ===';

SELECT
    t.name as Tabela,
    CASE
        WHEN p.rows = 0 THEN '⚠️ Vazia (pronta para ETL)'
        ELSE '✅ Populada'
    END as Status,
    p.rows as Registros
FROM sys.tables t
INNER JOIN sys.partitions p ON t.object_id = p.object_id
WHERE p.index_id IN (0,1)
  AND t.type = 'U'
  AND t.name NOT LIKE 'spt%'
  AND t.name NOT LIKE 'MS%'
ORDER BY t.name;
GO

-- ========================================
-- FIM DOS TESTES
-- ========================================
PRINT '';
PRINT '========================================';
PRINT '✅ TODOS OS TESTES CONCLUÍDOS!';
PRINT '========================================';
PRINT '';
PRINT 'Se você viu os resultados acima, seu DataGrip está configurado corretamente!';
PRINT '';
PRINT 'Próximos passos:';
PRINT '  1. Criar processo ETL para popular tabelas do master';
PRINT '  2. Criar views para análises';
PRINT '  3. Desenvolver queries de análise de dados';
PRINT '';
PRINT '========================================';
