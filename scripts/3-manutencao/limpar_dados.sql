-- ========================================
-- SCRIPT: LIMPAR DADOS DAS TABELAS
-- ========================================
-- Descrição: Remove todos os dados das tabelas, mas mantém a estrutura
-- Use este script quando quiser reimportar dados sem recriar tabelas
-- ========================================
-- EXECUÇÃO: docker exec sqlserverCC /opt/mssql-tools18/bin/sqlcmd -S localhost -U SA -P "Cc202505!" -i /tmp/limpar_dados.sql -C
-- ========================================

PRINT '========================================';
PRINT 'INICIANDO LIMPEZA DE DADOS';
PRINT '========================================';
PRINT '';

-- ========================================
-- PARTE 1: LIMPAR TABELAS DO DATABASE DATASETS
-- ========================================
USE datasets;
GO

PRINT 'Limpando tabelas do database DATASETS...';
GO

-- Desabilitar verificação de foreign keys temporariamente
EXEC sp_MSForEachTable 'ALTER TABLE ? NOCHECK CONSTRAINT ALL';
GO

-- Limpar tabela CSI500
IF EXISTS (SELECT 1 FROM sys.tables WHERE name = 'CSI500')
BEGIN
    TRUNCATE TABLE CSI500;
    PRINT '✓ CSI500: Dados removidos';
END
GO

-- Limpar tabela SP500_companies
IF EXISTS (SELECT 1 FROM sys.tables WHERE name = 'SP500_companies')
BEGIN
    TRUNCATE TABLE SP500_companies;
    PRINT '✓ SP500_companies: Dados removidos';
END
GO

-- Limpar tabela SP500_fred
IF EXISTS (SELECT 1 FROM sys.tables WHERE name = 'SP500_fred')
BEGIN
    TRUNCATE TABLE SP500_fred;
    PRINT '✓ SP500_fred: Dados removidos';
END
GO

-- Reabilitar verificação de foreign keys
EXEC sp_MSForEachTable 'ALTER TABLE ? WITH CHECK CHECK CONSTRAINT ALL';
GO

PRINT '';
PRINT 'Tabelas do DATASETS limpas!';
PRINT '';

-- ========================================
-- PARTE 2: LIMPAR TABELAS DO DATABASE MASTER
-- ========================================
USE master;
GO

PRINT 'Limpando tabelas do database MASTER...';
GO

-- Desabilitar verificação de foreign keys temporariamente
EXEC sp_MSForEachTable 'ALTER TABLE ? NOCHECK CONSTRAINT ALL';
GO

-- Limpar em ordem respeitando foreign keys (filhos primeiro)
-- Tabelas que dependem de outras (com FK)
IF EXISTS (SELECT 1 FROM sys.tables WHERE name = 'Dividendos')
BEGIN
    DELETE FROM Dividendos;
    PRINT '✓ Dividendos: Dados removidos';
END
GO

IF EXISTS (SELECT 1 FROM sys.tables WHERE name = 'PrecoAcao')
BEGIN
    DELETE FROM PrecoAcao;
    PRINT '✓ PrecoAcao: Dados removidos';
END
GO

IF EXISTS (SELECT 1 FROM sys.tables WHERE name = 'IndiceSP500')
BEGIN
    DELETE FROM IndiceSP500;
    PRINT '✓ IndiceSP500: Dados removidos';
END
GO

IF EXISTS (SELECT 1 FROM sys.tables WHERE name = 'Localizacao')
BEGIN
    DELETE FROM Localizacao;
    PRINT '✓ Localizacao: Dados removidos';
END
GO

IF EXISTS (SELECT 1 FROM sys.tables WHERE name = 'SubSetor')
BEGIN
    DELETE FROM SubSetor;
    PRINT '✓ SubSetor: Dados removidos';
END
GO

-- Resetar IDENTITY das tabelas com IDENTITY
IF EXISTS (SELECT 1 FROM sys.tables WHERE name = 'Dividendos')
    DBCC CHECKIDENT ('Dividendos', RESEED, 0);
IF EXISTS (SELECT 1 FROM sys.tables WHERE name = 'PrecoAcao')
    DBCC CHECKIDENT ('PrecoAcao', RESEED, 0);
IF EXISTS (SELECT 1 FROM sys.tables WHERE name = 'IndiceSP500')
    DBCC CHECKIDENT ('IndiceSP500', RESEED, 0);
IF EXISTS (SELECT 1 FROM sys.tables WHERE name = 'Localizacao')
    DBCC CHECKIDENT ('Localizacao', RESEED, 0);
IF EXISTS (SELECT 1 FROM sys.tables WHERE name = 'SubSetor')
    DBCC CHECKIDENT ('SubSetor', RESEED, 0);
GO

-- Tabelas independentes (sem FK referenciando elas, mas com FK para outras)
IF EXISTS (SELECT 1 FROM sys.tables WHERE name = 'Tempo')
BEGIN
    DELETE FROM Tempo;
    DBCC CHECKIDENT ('Tempo', RESEED, 0);
    PRINT '✓ Tempo: Dados removidos';
END
GO

IF EXISTS (SELECT 1 FROM sys.tables WHERE name = 'Empresas')
BEGIN
    DELETE FROM Empresas;
    PRINT '✓ Empresas: Dados removidos (CIK é PK mas não IDENTITY)';
END
GO

IF EXISTS (SELECT 1 FROM sys.tables WHERE name = 'Indice')
BEGIN
    DELETE FROM Indice;
    DBCC CHECKIDENT ('Indice', RESEED, 0);
    PRINT '✓ Indice: Dados removidos';
END
GO

-- Reabilitar verificação de foreign keys
EXEC sp_MSForEachTable 'ALTER TABLE ? WITH CHECK CHECK CONSTRAINT ALL';
GO

PRINT '';
PRINT 'Tabelas do MASTER limpas!';
PRINT '';

-- ========================================
-- PARTE 3: VERIFICAÇÃO FINAL
-- ========================================

PRINT '========================================';
PRINT 'VERIFICAÇÃO FINAL';
PRINT '========================================';
PRINT '';

-- Verificar tabelas do datasets
USE datasets;
GO

PRINT 'Contagem de registros no DATASETS (deve ser 0):';
SELECT
    'SP500_companies' as Tabela,
    COUNT(*) as Total
FROM SP500_companies
UNION ALL
SELECT 'SP500_fred', COUNT(*) FROM SP500_fred
UNION ALL
SELECT 'CSI500', COUNT(*) FROM CSI500;
GO

-- Verificar tabelas do master
USE master;
GO

PRINT '';
PRINT 'Contagem de registros no MASTER (deve ser 0):';
SELECT
    'Dividendos' as Tabela,
    COUNT(*) as Total
FROM Dividendos
UNION ALL
SELECT 'PrecoAcao', COUNT(*) FROM PrecoAcao
UNION ALL
SELECT 'IndiceSP500', COUNT(*) FROM IndiceSP500
UNION ALL
SELECT 'Localizacao', COUNT(*) FROM Localizacao
UNION ALL
SELECT 'SubSetor', COUNT(*) FROM SubSetor
UNION ALL
SELECT 'Tempo', COUNT(*) FROM Tempo
UNION ALL
SELECT 'Empresas', COUNT(*) FROM Empresas
UNION ALL
SELECT 'Indice', COUNT(*) FROM Indice
ORDER BY Tabela;
GO

PRINT '';
PRINT '========================================';
PRINT 'LIMPEZA CONCLUÍDA COM SUCESSO!';
PRINT '========================================';
PRINT '';
PRINT 'Status:';
PRINT '  ✓ Todos os dados foram removidos';
PRINT '  ✓ Estrutura das tabelas mantida';
PRINT '  ✓ Foreign keys reabilitadas';
PRINT '  ✓ IDENTITY resetados para 0';
PRINT '';
PRINT 'Próximos passos:';
PRINT '  1. Reimportar dados dos CSVs (se necessário)';
PRINT '  2. Ou executar processo ETL';
PRINT '  3. Ou executar setup completo novamente';
PRINT '';
PRINT '========================================';
GO
