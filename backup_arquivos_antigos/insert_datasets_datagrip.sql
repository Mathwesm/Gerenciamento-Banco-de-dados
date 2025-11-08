-- Script compatível com DataGrip (sem GO)
-- Execute este script no database 'datasets'

USE datasets;

-- Criar tabela SP500_companies se não existir
IF NOT EXISTS (
    SELECT 1
    FROM sys.tables
    WHERE name = 'SP500_companies'
    AND schema_id = SCHEMA_ID('dbo')
)
BEGIN
    CREATE TABLE SP500_companies
    (
        registro NVARCHAR(MAX)
    );
    PRINT 'Tabela SP500_companies criada.';
END
ELSE
BEGIN
    PRINT 'Tabela SP500_companies já existe.';
END;

-- Importar dados SP500_companies
BEGIN TRY
    BULK INSERT SP500_companies
    FROM '/datasets/S&P-500-companies.csv'
    WITH (
        FIRSTROW = 2,
        FIELDTERMINATOR = '\n',
        ROWTERMINATOR = '\n',
        DATAFILETYPE = 'char'
    );
    PRINT 'Dados SP500_companies importados com sucesso.';
END TRY
BEGIN CATCH
    PRINT 'Erro ao carregar SP500_companies: ' + ERROR_MESSAGE();
END CATCH;

-- Criar tabela SP500_fred se não existir
IF NOT EXISTS (
    SELECT 1
    FROM sys.tables
    WHERE name = 'SP500_fred'
    AND schema_id = SCHEMA_ID('dbo')
)
BEGIN
    CREATE TABLE SP500_fred
    (
        registro NVARCHAR(MAX)
    );
    PRINT 'Tabela SP500_fred criada.';
END
ELSE
BEGIN
    PRINT 'Tabela SP500_fred já existe.';
END;

-- Importar dados SP500_fred
BEGIN TRY
    BULK INSERT SP500_fred
    FROM '/datasets/S&P500-fred.csv'
    WITH (
        FIRSTROW = 2,
        FIELDTERMINATOR = '\n',
        ROWTERMINATOR = '\n',
        DATAFILETYPE = 'char'
    );
    PRINT 'Dados SP500_fred importados com sucesso.';
END TRY
BEGIN CATCH
    PRINT 'Erro ao carregar SP500_fred: ' + ERROR_MESSAGE();
END CATCH;

-- Criar tabela CSI500 se não existir
IF NOT EXISTS (
    SELECT 1
    FROM sys.tables
    WHERE name = 'CSI500'
    AND schema_id = SCHEMA_ID('dbo')
)
BEGIN
    CREATE TABLE CSI500
    (
        registro NVARCHAR(MAX)
    );
    PRINT 'Tabela CSI500 criada.';
END
ELSE
BEGIN
    PRINT 'Tabela CSI500 já existe.';
END;

-- Importar dados CSI500 part-1
BEGIN TRY
    BULK INSERT CSI500
    FROM '/datasets/CSI500-part-1.csv'
    WITH (
        FIRSTROW = 2,
        FIELDTERMINATOR = '\n',
        ROWTERMINATOR = '\n',
        DATAFILETYPE = 'char'
    );
    PRINT 'Dados CSI500 part-1 importados com sucesso.';
END TRY
BEGIN CATCH
    PRINT 'Erro ao carregar CSI500 part-1: ' + ERROR_MESSAGE();
END CATCH;

-- Importar dados CSI500 part-2
BEGIN TRY
    BULK INSERT CSI500
    FROM '/datasets/CSI500-part-2.csv'
    WITH (
        FIRSTROW = 2,
        FIELDTERMINATOR = '\n',
        ROWTERMINATOR = '\n',
        DATAFILETYPE = 'char'
    );
    PRINT 'Dados CSI500 part-2 importados com sucesso.';
END TRY
BEGIN CATCH
    PRINT 'Erro ao carregar CSI500 part-2: ' + ERROR_MESSAGE();
END CATCH;

PRINT 'Importação concluída!';
