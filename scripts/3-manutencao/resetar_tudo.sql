-- ========================================
-- SCRIPT: RESETAR TUDO DO ZERO
-- ========================================
-- Descrição: Remove TODAS as tabelas e o database datasets
-- ⚠️ ATENÇÃO: Este script apaga TUDO! Use com cuidado!
-- ========================================
-- EXECUÇÃO: docker exec sqlserverCC /opt/mssql-tools18/bin/sqlcmd -S localhost -U SA -P "Cc202505!" -i /tmp/resetar_tudo.sql -C
-- ========================================

PRINT '========================================';
PRINT '⚠️  RESETANDO TUDO DO ZERO';
PRINT '========================================';
PRINT '';
PRINT '⚠️  ATENÇÃO: Este script vai:';
PRINT '  - Dropar TODAS as tabelas do master';
PRINT '  - Dropar o database DATASETS';
PRINT '  - Apagar TODOS os dados';
PRINT '';

-- ========================================
-- PARTE 1: DROPAR DATABASE DATASETS
-- ========================================
USE master;
GO

PRINT 'Dropando database DATASETS...';
GO

IF EXISTS (SELECT name FROM sys.databases WHERE name = 'datasets')
BEGIN
    -- Forçar fechamento de conexões abertas
    ALTER DATABASE datasets SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
    DROP DATABASE datasets;
    PRINT '✓ Database DATASETS removido completamente!';
END
ELSE
BEGIN
    PRINT '⚠ Database DATASETS não existe.';
END
GO

-- ========================================
-- PARTE 2: DROPAR TABELAS DO MASTER
-- ========================================
USE master;
GO

PRINT '';
PRINT 'Dropando tabelas do database MASTER...';
GO

-- Dropar tabelas com foreign keys primeiro (ordem reversa da criação)
IF EXISTS (SELECT 1 FROM sys.tables WHERE name = 'Dividendos')
BEGIN
    DROP TABLE Dividendos;
    PRINT '✓ Tabela Dividendos removida';
END
GO

IF EXISTS (SELECT 1 FROM sys.tables WHERE name = 'PrecoAcao')
BEGIN
    DROP TABLE PrecoAcao;
    PRINT '✓ Tabela PrecoAcao removida';
END
GO

IF EXISTS (SELECT 1 FROM sys.tables WHERE name = 'IndiceSP500')
BEGIN
    DROP TABLE IndiceSP500;
    PRINT '✓ Tabela IndiceSP500 removida';
END
GO

IF EXISTS (SELECT 1 FROM sys.tables WHERE name = 'Localizacao')
BEGIN
    DROP TABLE Localizacao;
    PRINT '✓ Tabela Localizacao removida';
END
GO

IF EXISTS (SELECT 1 FROM sys.tables WHERE name = 'SubSetor')
BEGIN
    DROP TABLE SubSetor;
    PRINT '✓ Tabela SubSetor removida';
END
GO

IF EXISTS (SELECT 1 FROM sys.tables WHERE name = 'Tempo')
BEGIN
    DROP TABLE Tempo;
    PRINT '✓ Tabela Tempo removida';
END
GO

IF EXISTS (SELECT 1 FROM sys.tables WHERE name = 'Empresas')
BEGIN
    DROP TABLE Empresas;
    PRINT '✓ Tabela Empresas removida';
END
GO

IF EXISTS (SELECT 1 FROM sys.tables WHERE name = 'Indice')
BEGIN
    DROP TABLE Indice;
    PRINT '✓ Tabela Indice removida';
END
GO

-- ========================================
-- PARTE 3: VERIFICAÇÃO FINAL
-- ========================================

PRINT '';
PRINT '========================================';
PRINT 'VERIFICAÇÃO FINAL';
PRINT '========================================';
PRINT '';

-- Verificar databases
PRINT 'Databases existentes:';
SELECT name as DatabaseName FROM sys.databases WHERE name IN ('master', 'datasets') ORDER BY name;
GO

-- Verificar tabelas no master
USE master;
GO

PRINT '';
PRINT 'Tabelas restantes no MASTER:';
DECLARE @count INT;
SELECT @count = COUNT(*) FROM sys.tables WHERE type = 'U' AND name NOT LIKE 'spt%' AND name NOT LIKE 'MS%';

IF @count = 0
    PRINT '✓ Nenhuma tabela encontrada (tudo limpo!)';
ELSE
BEGIN
    PRINT '⚠ Ainda existem tabelas:';
    SELECT name FROM sys.tables WHERE type = 'U' AND name NOT LIKE 'spt%' AND name NOT LIKE 'MS%' ORDER BY name;
END
GO

PRINT '';
PRINT '========================================';
PRINT '✅ RESET COMPLETO FINALIZADO!';
PRINT '========================================';
PRINT '';
PRINT 'Status:';
PRINT '  ✓ Database DATASETS removido';
PRINT '  ✓ Todas as tabelas do MASTER removidas';
PRINT '  ✓ Sistema está limpo';
PRINT '';
PRINT 'Para recriar tudo do zero:';
PRINT '  1. Execute: ./setup_automatico.sh';
PRINT '  2. Ou execute: scripts/01_setup_completo.sql';
PRINT '';
PRINT '========================================';
GO
