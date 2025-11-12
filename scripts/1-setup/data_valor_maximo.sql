PRINT '========================================';
PRINT 'DEBUG IMPORTACAO SP500_data';
PRINT '========================================';
GO

USE datasets;
GO

PRINT 'Truncando tabela SP500_data...';
IF OBJECT_ID('dbo.SP500_data', 'U') IS NULL
BEGIN
    PRINT 'ERRO: Tabela SP500_data não existe no database datasets.';
    RETURN;
END
GO

TRUNCATE TABLE SP500_data;
PRINT 'Tabela SP500_data truncada.';
GO

-- ================================
-- IMPORTAR SP500_data PART 1
-- ================================
PRINT 'Importando /datasets/sp500_data_part1.csv ...';
GO

BEGIN TRY
    BULK INSERT SP500_data
    FROM '/datasets/sp500_data_part1.csv'
    WITH (
        FIRSTROW       = 2,
        FIELDTERMINATOR = ',',
        ROWTERMINATOR   = '\n',  -- vamos testar com \n normal
        TABLOCK,
        MAXERRORS       = 0
        -- Você pode ativar um LOG de erro se quiser:
        -- , ERRORFILE = '/tmp/sp500_part1_error.log'
    );
    PRINT 'SP500_data part-1: importacao OK.';
END TRY
BEGIN CATCH
    PRINT 'ERRO ao importar SP500_data part-1:';
    SELECT
        ERROR_NUMBER()   AS ErrorNumber,
        ERROR_SEVERITY() AS ErrorSeverity,
        ERROR_STATE()    AS ErrorState,
        ERROR_LINE()     AS ErrorLine,
        ERROR_MESSAGE()  AS ErrorMessage;
END CATCH;
GO

PRINT 'Total apos part-1:';
SELECT COUNT(*) AS Total_SP500_apos_part1 FROM SP500_data;
GO

-- ================================
-- IMPORTAR SP500_data PART 2
-- ================================
PRINT 'Importando /datasets/sp500_data_part2.csv ...';
GO

BEGIN TRY
    BULK INSERT SP500_data
    FROM '/datasets/sp500_data_part2.csv'
    WITH (
        FIRSTROW       = 2,
        FIELDTERMINATOR = ',',
        ROWTERMINATOR   = '\n',
        TABLOCK,
        MAXERRORS       = 0
        -- , ERRORFILE = '/tmp/sp500_part2_error.log'
    );
    PRINT 'SP500_data part-2: importacao OK.';
END TRY
BEGIN CATCH
    PRINT 'ERRO ao importar SP500_data part-2:';
    SELECT
        ERROR_NUMBER()   AS ErrorNumber,
        ERROR_SEVERITY() AS ErrorSeverity,
        ERROR_STATE()    AS ErrorState,
        ERROR_LINE()     AS ErrorLine,
        ERROR_MESSAGE()  AS ErrorMessage;
END CATCH;
GO

PRINT 'Total final na tabela SP500_data:';
SELECT COUNT(*) AS Total_SP500_Final FROM SP500_data;
GO

PRINT 'Top 5 registros SP500_data:';
SELECT TOP (5) * FROM SP500_data;
GO

PRINT '========================================';
PRINT 'FIM DEBUG SP500_data';
PRINT '========================================';
GO
