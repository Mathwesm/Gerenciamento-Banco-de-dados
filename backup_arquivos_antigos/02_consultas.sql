-- ========================================
-- SCRIPT 02: CONSULTAS PRINCIPAIS
-- ========================================
-- Descrição: Consultas prontas para análise dos dados
-- IMPORTANTE: Execute no DataGrip, uma query por vez
-- ========================================

-- ========================================
-- SEÇÃO 1: CONSULTAS NO DATABASE DATASETS
-- ========================================

-- Query 1.1: Resumo de registros
SELECT
    'SP500_companies' as Tabela,
    COUNT(*) as Total_Registros
FROM datasets.dbo.SP500_companies
UNION ALL
SELECT 'SP500_fred', COUNT(*) FROM datasets.dbo.SP500_fred
UNION ALL
SELECT 'CSI500', COUNT(*) FROM datasets.dbo.CSI500;

-- Query 1.2: Primeiras 20 empresas do S&P 500
SELECT TOP 20
    registro as Empresa
FROM datasets.dbo.SP500_companies;

-- Query 1.3: Últimos 20 preços do índice S&P 500
SELECT TOP 20
    registro as PrecoIndice
FROM datasets.dbo.SP500_fred
ORDER BY registro DESC;

-- Query 1.4: Amostra de 20 registros do CSI500
SELECT TOP 20
    registro as DadosCSI500
FROM datasets.dbo.CSI500;

-- Query 1.5: Buscar Apple
SELECT registro
FROM datasets.dbo.SP500_companies
WHERE registro LIKE '%Apple%' OR registro LIKE '%AAPL%';

-- Query 1.6: Buscar Microsoft
SELECT registro
FROM datasets.dbo.SP500_companies
WHERE registro LIKE '%Microsoft%' OR registro LIKE '%MSFT%';

-- Query 1.7: Buscar Amazon
SELECT registro
FROM datasets.dbo.SP500_companies
WHERE registro LIKE '%Amazon%' OR registro LIKE '%AMZN%';

-- Query 1.8: Buscar Google/Alphabet
SELECT registro
FROM datasets.dbo.SP500_companies
WHERE registro LIKE '%Alphabet%' OR registro LIKE '%Google%' OR registro LIKE '%GOOGL%';

-- Query 1.9: Empresas de Tecnologia
SELECT TOP 30 registro
FROM datasets.dbo.SP500_companies
WHERE registro LIKE '%Technology%' OR registro LIKE '%Information%';

-- Query 1.10: Empresas Financeiras
SELECT TOP 30 registro
FROM datasets.dbo.SP500_companies
WHERE registro LIKE '%Financial%' OR registro LIKE '%Bank%';

-- Query 1.11: Dados CSI500 de 2020
SELECT TOP 100 registro
FROM datasets.dbo.CSI500
WHERE registro LIKE '%2020%';

-- Query 1.12: Dados CSI500 de 2021
SELECT TOP 100 registro
FROM datasets.dbo.CSI500
WHERE registro LIKE '%2021%';

-- Query 1.13: Dados CSI500 de 2022
SELECT TOP 100 registro
FROM datasets.dbo.CSI500
WHERE registro LIKE '%2022%';

-- Query 1.14: Estatísticas das tabelas
SELECT
    t.NAME AS Tabela,
    p.rows AS Total_Linhas,
    CAST(SUM(a.total_pages) * 8.0 / 1024 AS DECIMAL(10,2)) AS TamanhoTotal_MB,
    CAST(SUM(a.used_pages) * 8.0 / 1024 AS DECIMAL(10,2)) AS EspacoUsado_MB
FROM
    datasets.sys.tables t
INNER JOIN
    datasets.sys.indexes i ON t.OBJECT_ID = i.object_id
INNER JOIN
    datasets.sys.partitions p ON i.object_id = p.OBJECT_ID AND i.index_id = p.index_id
INNER JOIN
    datasets.sys.allocation_units a ON p.partition_id = a.container_id
WHERE
    t.NAME IN ('SP500_companies', 'SP500_fred', 'CSI500')
    AND t.is_ms_shipped = 0
    AND i.OBJECT_ID > 255
GROUP BY
    t.Name, p.Rows
ORDER BY
    p.Rows DESC;


-- ========================================
-- SEÇÃO 2: CONSULTAS NO DATABASE MASTER
-- ========================================

-- Query 2.1: Listar todas as tabelas do modelo dimensional
SELECT
    TABLE_NAME as Tabela,
    TABLE_TYPE as Tipo
FROM master.INFORMATION_SCHEMA.TABLES
WHERE TABLE_TYPE = 'BASE TABLE'
    AND TABLE_NAME NOT LIKE 'spt%'
    AND TABLE_NAME NOT LIKE 'MS%'
ORDER BY TABLE_NAME;

-- Query 2.2: Ver estrutura da tabela Empresas
SELECT
    COLUMN_NAME as Coluna,
    DATA_TYPE as TipoDado,
    CHARACTER_MAXIMUM_LENGTH as Tamanho,
    IS_NULLABLE as Nulo
FROM master.INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_NAME = 'Empresas'
ORDER BY ORDINAL_POSITION;

-- Query 2.3: Ver estrutura da tabela PrecoAcao
SELECT
    COLUMN_NAME as Coluna,
    DATA_TYPE as TipoDado,
    CHARACTER_MAXIMUM_LENGTH as Tamanho,
    IS_NULLABLE as Nulo
FROM master.INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_NAME = 'PrecoAcao'
ORDER BY ORDINAL_POSITION;

-- Query 2.4: Ver estrutura da tabela Tempo
SELECT
    COLUMN_NAME as Coluna,
    DATA_TYPE as TipoDado,
    CHARACTER_MAXIMUM_LENGTH as Tamanho,
    IS_NULLABLE as Nulo
FROM master.INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_NAME = 'Tempo'
ORDER BY ORDINAL_POSITION;

-- Query 2.5: Ver todas as Foreign Keys
SELECT
    fk.name AS ForeignKey,
    OBJECT_NAME(fk.parent_object_id) AS TabelaOrigem,
    OBJECT_NAME(fk.referenced_object_id) AS TabelaReferenciada
FROM master.sys.foreign_keys AS fk
ORDER BY TabelaOrigem;

-- Query 2.6: Ver todos os índices criados
SELECT
    t.name AS Tabela,
    i.name AS Indice,
    i.type_desc AS TipoIndice
FROM master.sys.indexes i
INNER JOIN master.sys.tables t ON i.object_id = t.object_id
WHERE i.name IS NOT NULL
    AND t.name NOT LIKE 'spt%'
    AND t.name NOT LIKE 'MS%'
ORDER BY t.name, i.name;


-- ========================================
-- SEÇÃO 3: CONSULTAS ÚTEIS PARA ANÁLISE
-- ========================================

-- Query 3.1: Contar tabelas em cada database
SELECT
    'master' as Database,
    COUNT(*) as TotalTabelas
FROM master.sys.tables
WHERE type = 'U' AND name NOT LIKE 'spt%' AND name NOT LIKE 'MS%'
UNION ALL
SELECT
    'datasets',
    COUNT(*)
FROM datasets.sys.tables
WHERE type = 'U';

-- Query 3.2: Ver tamanho total dos databases
SELECT
    name AS Database_Name,
    size * 8 / 1024 AS TamanhoMB
FROM master.sys.master_files
WHERE type = 0
    AND database_id IN (DB_ID('master'), DB_ID('datasets'))
ORDER BY name;

-- Query 3.3: Verificar se há dados nas tabelas do master
-- (Tabelas devem estar vazias pois ainda não foram populadas)
SELECT
    'Indice' as Tabela,
    COUNT(*) as Registros
FROM master.dbo.Indice
UNION ALL
SELECT 'IndiceSP500', COUNT(*) FROM master.dbo.IndiceSP500
UNION ALL
SELECT 'Empresas', COUNT(*) FROM master.dbo.Empresas
UNION ALL
SELECT 'SubSetor', COUNT(*) FROM master.dbo.SubSetor
UNION ALL
SELECT 'Localizacao', COUNT(*) FROM master.dbo.Localizacao
UNION ALL
SELECT 'Tempo', COUNT(*) FROM master.dbo.Tempo
UNION ALL
SELECT 'PrecoAcao', COUNT(*) FROM master.dbo.PrecoAcao
UNION ALL
SELECT 'Dividendos', COUNT(*) FROM master.dbo.Dividendos;


-- ========================================
-- SEÇÃO 4: QUERIES DE EXEMPLO PARA FUTURO
-- (Após popular as tabelas do master)
-- ========================================

-- Query 4.1: Inserir exemplo na tabela Indice
-- INSERT INTO master.dbo.Indice (NomeIndice, Descricao, Simbolo, PaisOrigem, DataCriacao)
-- VALUES ('S&P 500', 'Standard & Poor''s 500 Index', 'SPX', 'Estados Unidos', '1957-03-04');

-- Query 4.2: Inserir exemplo na tabela Empresas
-- INSERT INTO master.dbo.Empresas (CIK, NomeEmpresa, Ticker, Setor, DataEntrada, AnoFundacao, TipoSeguranca, Site)
-- VALUES (320193, 'Apple Inc.', 'AAPL', 'Information Technology', '1980-12-12', 1976, 'Common Stock', 'https://www.apple.com');

-- Query 4.3: Consultar empresas por setor (exemplo futuro)
-- SELECT
--     NomeEmpresa,
--     Ticker,
--     Setor,
--     AnoFundacao
-- FROM master.dbo.Empresas
-- WHERE Setor = 'Information Technology'
-- ORDER BY NomeEmpresa;

-- Query 4.4: Análise de preços (exemplo futuro)
-- SELECT
--     e.NomeEmpresa,
--     e.Ticker,
--     t.DataCompleta,
--     p.PrecoFechamento,
--     p.Volume
-- FROM master.dbo.PrecoAcao p
-- INNER JOIN master.dbo.Empresas e ON p.CIK = e.CIK
-- INNER JOIN master.dbo.Tempo t ON p.IdTempo = t.IdTempo
-- WHERE e.Ticker = 'AAPL'
-- ORDER BY t.DataCompleta DESC;


-- ========================================
-- FIM DAS CONSULTAS
-- ========================================
-- Próximos passos:
-- 1. Popular as tabelas do master com dados dos CSVs
-- 2. Criar ETL para transformar dados brutos em dimensional
-- 3. Criar views para análises complexas
-- 4. Criar stored procedures para relatórios
-- ========================================
