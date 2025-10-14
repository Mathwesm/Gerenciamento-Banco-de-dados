CREATE DATABASE datasets

GO

use datasets

GO

BEGIN TRY
    BEGIN TRANSACTION
    
    IF NOT EXISTS (
        SELECT 1
FROM sys.tables
WHERE name = 'SP500_companies'
    AND schema_id = SCHEMA_ID('dbo')
    )
    BEGIN
    CREATE TABLE "SP500_companies"
    (
        registro NVARCHAR(MAX)
    )
END
    ELSE
    BEGIN
    PRINT 'Tabele SP500_companies já existe.'
END
    BEGIN TRY
        BULK INSERT SP500_companies
        FROM '/datasets/S&P-500-companies.csv'
        WITH (
            FIRSTROW = 2,
            FIELDTERMINATOR = '\n',
            ROWTERMINATOR = '\n',
            DATAFILETYPE = 'char'
        );
    END TRY
    BEGIN CATCH
        PRINT 'Erro ao carregar o arquivo CSV';
        THROW
    END CATCH
    PRINT 'Dados importados';

    COMMIT TRANSACTION
END TRY
BEGIN CATCH
    PRINT 'Ocorreu um erro';
    ROLLBACK TRANSACTION;

    PRINT ERROR_MESSAGE();
END CATCH;

GO

BEGIN TRY
    BEGIN TRANSACTION
    
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
    )
END
    ELSE
    BEGIN
    PRINT 'Tabele SP500_fred já existe.'
END
    BEGIN TRY
        BULK INSERT SP500_fred
        FROM '/datasets/S&P500-fred.csv'
        WITH (
            FIRSTROW = 2,
            FIELDTERMINATOR = '\n',
            ROWTERMINATOR = '\n',
            DATAFILETYPE = 'char'
        );
    END TRY
    BEGIN CATCH
        PRINT 'Erro ao carregar o arquivo CSV';
        THROW
    END CATCH
    PRINT 'Dados importados';

    COMMIT TRANSACTION
END TRY
BEGIN CATCH
    PRINT 'Ocorreu um erro';
    ROLLBACK TRANSACTION;

    PRINT ERROR_MESSAGE();
END CATCH;

GO

BEGIN TRY
    BEGIN TRANSACTION
    
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
    )
END
    ELSE
    BEGIN
    PRINT 'Tabele CSI500 já existe.'
END
    BEGIN TRY
        BULK INSERT CSI500
        FROM '/datasets/CSI500-part-1.csv'
        WITH (
            FIRSTROW = 2,
            FIELDTERMINATOR = '\n',
            ROWTERMINATOR = '\n',
            DATAFILETYPE = 'char'
        );
    END TRY
    BEGIN CATCH
        PRINT 'Erro ao carregar o arquivo CSV';
        THROW
    END CATCH
    PRINT 'Dados importados';

     BEGIN TRY
        BULK INSERT CSI500
        FROM '/datasets/CSI500-part-2.csv'
        WITH (
            FIRSTROW = 2,
            FIELDTERMINATOR = '\n',
            ROWTERMINATOR = '\n',
            DATAFILETYPE = 'char'
        );
    END TRY
    BEGIN CATCH
        PRINT 'Erro ao carregar o arquivo CSV';
        THROW
    END CATCH
    PRINT 'Dados importados';

    COMMIT TRANSACTION
END TRY
BEGIN CATCH
    PRINT 'Ocorreu um erro';
    ROLLBACK TRANSACTION;

    PRINT ERROR_MESSAGE();
END CATCH;
