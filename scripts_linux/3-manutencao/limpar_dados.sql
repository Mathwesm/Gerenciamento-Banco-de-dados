-- ========================================
-- SCRIPT: LIMPAR DADOS DAS TABELAS
-- ========================================
-- Descrição: Remove todos os dados das tabelas, mas mantém a estrutura
-- ⚠️  ATENÇÃO: Este script apaga TODOS os dados das tabelas!
-- ⚠️  Use apenas quando tiver certeza!
-- ========================================
-- EXECUÇÃO: docker exec sqlserverCC /opt/mssql-tools18/bin/sqlcmd -S localhost -U SA -P "Cc202505!" -i /tmp/limpar_dados.sql -C
-- ========================================
--
-- NOTA: Os comandos DELETE sem WHERE são INTENCIONAIS
-- Este script é projetado para limpar TODAS as tabelas
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

-- Limpar tabela SP500_data
IF EXISTS (SELECT 1 FROM sys.tables WHERE name = 'SP500_data')
BEGIN
    TRUNCATE TABLE SP500_data;
    PRINT 'SP500_data: Dados removidos';
END
GO

-- Limpar tabela CSI500
IF EXISTS (SELECT 1 FROM sys.tables WHERE name = 'CSI500')
BEGIN
    TRUNCATE TABLE CSI500;
    PRINT 'CSI500: Dados removidos';
END
GO

PRINT '';
PRINT 'Tabelas do DATASETS limpas!';
PRINT '';

-- ========================================
-- PARTE 2: LIMPAR TABELAS DO DATABASE FINANCEDB
-- ========================================
USE FinanceDB;
GO

PRINT 'Limpando tabelas do database FINANCEDB...';
GO

-- Desabilitar verificação de foreign keys temporariamente
EXEC sp_MSForEachTable 'ALTER TABLE ? NOCHECK CONSTRAINT ALL';
GO

-- Limpar em ordem respeitando foreign keys (filhos primeiro)
-- NOTA: Usamos DELETE em vez de TRUNCATE porque várias tabelas têm foreign keys
-- A annotation --noinspection SqlWithoutWhere suprime warnings do DataGrip
-- As foreign keys foram desabilitadas temporariamente para permitir a limpeza

IF EXISTS (SELECT 1 FROM sys.tables WHERE name = 'Dividendos')
BEGIN
    --noinspection SqlWithoutWhere @ delete
    DELETE FROM Dividendos;
    DBCC CHECKIDENT ('Dividendos', RESEED, 0);
    PRINT 'Dividendos: Dados removidos';
END
GO

IF EXISTS (SELECT 1 FROM sys.tables WHERE name = 'PrecoAcao')
BEGIN
    --noinspection SqlWithoutWhere
    DELETE FROM PrecoAcao;
    DBCC CHECKIDENT ('PrecoAcao', RESEED, 0);
    PRINT 'PrecoAcao: Dados removidos';
END
GO

IF EXISTS (SELECT 1 FROM sys.tables WHERE name = 'IndiceSP500')
BEGIN
    --noinspection SqlWithoutWhere
    DELETE FROM IndiceSP500;
    DBCC CHECKIDENT ('IndiceSP500', RESEED, 0);
    PRINT 'IndiceSP500: Dados removidos';
END
GO

IF EXISTS (SELECT 1 FROM sys.tables WHERE name = 'Localizacao')
BEGIN
    --noinspection SqlWithoutWhere
    DELETE FROM Localizacao;
    DBCC CHECKIDENT ('Localizacao', RESEED, 0);
    PRINT 'Localizacao: Dados removidos';
END
GO

IF EXISTS (SELECT 1 FROM sys.tables WHERE name = 'SubSetor')
BEGIN
    --noinspection SqlWithoutWhere
    DELETE FROM SubSetor;
    DBCC CHECKIDENT ('SubSetor', RESEED, 0);
    PRINT 'SubSetor: Dados removidos';
END
GO

IF EXISTS (SELECT 1 FROM sys.tables WHERE name = 'Tempo')
BEGIN
    --noinspection SqlWithoutWhere
    DELETE FROM Tempo;
    DBCC CHECKIDENT ('Tempo', RESEED, 0);
    PRINT 'Tempo: Dados removidos';
END
GO

IF EXISTS (SELECT 1 FROM sys.tables WHERE name = 'Empresas')
BEGIN
    --noinspection SqlWithoutWhere
    DELETE FROM Empresas;
    PRINT 'Empresas: Dados removidos (sem IDENTITY)';
END
GO

IF EXISTS (SELECT 1 FROM sys.tables WHERE name = 'Indice')
BEGIN
    --noinspection SqlWithoutWhere
    DELETE FROM Indice;
    DBCC CHECKIDENT ('Indice', RESEED, 0);
    PRINT 'Indice: Dados removidos';
END
GO

-- Reabilitar verificação de foreign keys
EXEC sp_MSForEachTable 'ALTER TABLE ? WITH CHECK CHECK CONSTRAINT ALL';
GO

PRINT '';
PRINT 'Tabelas do FINANCEDB limpas!';
PRINT '';

-- ========================================
-- VERIFICAÇÃO FINAL
-- ========================================

PRINT '========================================';
PRINT 'VERIFICAÇÃO FINAL';
PRINT '========================================';
PRINT '';

-- Verificar tabelas do datasets
USE datasets;
GO

PRINT 'Contagem de registros no DATASETS (deve ser 0):';
SELECT 'SP500_data' as Tabela, COUNT(*) as Total FROM SP500_data
UNION ALL
SELECT 'CSI500', COUNT(*) FROM CSI500;
GO

-- Verificar tabelas do master
USE FinanceDB;
GO

PRINT '';
PRINT 'Contagem de registros no FINANCEDB (deve ser 0):';
SELECT 'Dividendos' as Tabela, COUNT(*) as Total FROM Dividendos
UNION ALL SELECT 'PrecoAcao', COUNT(*) FROM PrecoAcao
UNION ALL SELECT 'IndiceSP500', COUNT(*) FROM IndiceSP500
UNION ALL SELECT 'Localizacao', COUNT(*) FROM Localizacao
UNION ALL SELECT 'SubSetor', COUNT(*) FROM SubSetor
UNION ALL SELECT 'Tempo', COUNT(*) FROM Tempo
UNION ALL SELECT 'Empresas', COUNT(*) FROM Empresas
UNION ALL SELECT 'Indice', COUNT(*) FROM Indice
ORDER BY Tabela;
GO

PRINT '';
PRINT '========================================';
PRINT 'LIMPEZA CONCLUÍDA COM SUCESSO!';
PRINT '========================================';
PRINT '';
PRINT 'Status:';
PRINT '  - Todos os dados foram removidos';
PRINT '  - Estrutura das tabelas mantida';
PRINT '  - Foreign keys reabilitadas';
PRINT '  - IDENTITY resetados';
PRINT '';
PRINT 'Próximos passos:';
PRINT '  1. Execute o setup completo novamente';
PRINT '  2. Ou reimportar dados manualmente';
PRINT '';
PRINT '========================================';
GO
