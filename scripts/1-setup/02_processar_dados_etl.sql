-- ========================================
-- SCRIPT ETL: PROCESSAR DADOS DOS CSVs
-- ========================================
-- Descrição: Faz o parse dos dados brutos e popula tabelas do master
-- Processa: SP500_companies e SP500_fred
-- ========================================
-- EXECUÇÃO: docker exec sqlserverCC /opt/mssql-tools18/bin/sqlcmd -S localhost -U SA -P "Cc202505!" -i /tmp/03_processar_dados_etl.sql -C
-- ========================================

PRINT '========================================';
PRINT 'INICIANDO PROCESSAMENTO ETL';
PRINT '========================================';
PRINT '';

-- ========================================
-- PARTE 1: PROCESSAR SP500_COMPANIES
-- ========================================
USE datasets;
GO

PRINT 'Processando SP500_companies...';
GO

-- Criar tabela temporária para armazenar dados parseados
IF OBJECT_ID('tempdb..#TempEmpresas') IS NOT NULL
    DROP TABLE #TempEmpresas;

CREATE TABLE #TempEmpresas (
    Symbol NVARCHAR(10),
    Security NVARCHAR(150),
    GICSSector NVARCHAR(100),
    GICSSubIndustry NVARCHAR(150),
    HeadquartersLocation NVARCHAR(255),
    DateAdded NVARCHAR(50),
    CIK NVARCHAR(20),
    Founded NVARCHAR(50)
);

-- Inserir dados parseados usando STRING_SPLIT ou parse manual
-- Nota: SQL Server tem limitações com CSV que contém vírgulas dentro de aspas
-- Vamos usar uma abordagem mais robusta com PARSENAME e manipulação de strings

DECLARE @registro NVARCHAR(MAX);
DECLARE @Symbol NVARCHAR(10);
DECLARE @Security NVARCHAR(150);
DECLARE @GICSSector NVARCHAR(100);
DECLARE @GICSSubIndustry NVARCHAR(150);
DECLARE @HeadquartersLocation NVARCHAR(255);
DECLARE @DateAdded DATE;
DECLARE @CIK INT;
DECLARE @Founded SMALLINT;
DECLARE @pos1 INT, @pos2 INT, @pos3 INT, @pos4 INT, @pos5 INT, @pos6 INT, @pos7 INT;
DECLARE @temp NVARCHAR(MAX);

DECLARE cursor_empresas CURSOR FOR
SELECT registro FROM SP500_companies;

OPEN cursor_empresas;
FETCH NEXT FROM cursor_empresas INTO @registro;

WHILE @@FETCH_STATUS = 0
BEGIN
    -- Parse manual do CSV respeitando aspas
    SET @temp = @registro;

    -- Symbol (campo 1)
    SET @pos1 = CHARINDEX(',', @temp);
    SET @Symbol = LEFT(@temp, @pos1 - 1);
    SET @temp = SUBSTRING(@temp, @pos1 + 1, LEN(@temp));

    -- Security (campo 2)
    SET @pos2 = CHARINDEX(',', @temp);
    SET @Security = LEFT(@temp, @pos2 - 1);
    SET @temp = SUBSTRING(@temp, @pos2 + 1, LEN(@temp));

    -- GICS Sector (campo 3)
    SET @pos3 = CHARINDEX(',', @temp);
    SET @GICSSector = LEFT(@temp, @pos3 - 1);
    SET @temp = SUBSTRING(@temp, @pos3 + 1, LEN(@temp));

    -- GICS Sub-Industry (campo 4)
    SET @pos4 = CHARINDEX(',', @temp);
    SET @GICSSubIndustry = LEFT(@temp, @pos4 - 1);
    SET @temp = SUBSTRING(@temp, @pos4 + 1, LEN(@temp));

    -- Headquarters Location (campo 5 - pode ter aspas e vírgula interna)
    IF LEFT(@temp, 1) = '"'
    BEGIN
        -- Tem aspas, procurar próxima aspa
        SET @temp = SUBSTRING(@temp, 2, LEN(@temp)); -- Remover aspa inicial
        SET @pos5 = CHARINDEX('"', @temp);
        SET @HeadquartersLocation = LEFT(@temp, @pos5 - 1);
        SET @temp = SUBSTRING(@temp, @pos5 + 2, LEN(@temp)); -- +2 para pular aspa e vírgula
    END
    ELSE
    BEGIN
        -- Não tem aspas
        SET @pos5 = CHARINDEX(',', @temp);
        SET @HeadquartersLocation = LEFT(@temp, @pos5 - 1);
        SET @temp = SUBSTRING(@temp, @pos5 + 1, LEN(@temp));
    END

    -- Date added (campo 6)
    SET @pos6 = CHARINDEX(',', @temp);
    IF @pos6 > 0
    BEGIN
        BEGIN TRY
            SET @DateAdded = CONVERT(DATE, LEFT(@temp, @pos6 - 1));
        END TRY
        BEGIN CATCH
            SET @DateAdded = NULL;
        END CATCH
        SET @temp = SUBSTRING(@temp, @pos6 + 1, LEN(@temp));
    END

    -- CIK (campo 7)
    SET @pos7 = CHARINDEX(',', @temp);
    IF @pos7 > 0
    BEGIN
        BEGIN TRY
            SET @CIK = CONVERT(INT, LEFT(@temp, @pos7 - 1));
        END TRY
        BEGIN CATCH
            SET @CIK = NULL;
        END CATCH
        SET @temp = SUBSTRING(@temp, @pos7 + 1, LEN(@temp));
    END

    -- Founded (campo 8 - último)
    BEGIN TRY
        -- Extrair apenas o ano (pode vir no formato "1888" ou "2013 (1888)")
        SET @temp = LTRIM(RTRIM(@temp));
        SET @pos1 = CHARINDEX(' ', @temp);
        IF @pos1 > 0
            SET @Founded = CONVERT(SMALLINT, LEFT(@temp, @pos1 - 1));
        ELSE
            SET @Founded = CONVERT(SMALLINT, @temp);
    END TRY
    BEGIN CATCH
        SET @Founded = NULL;
    END CATCH

    -- Inserir na tabela Empresas do master (se não existir)
    IF @CIK IS NOT NULL AND NOT EXISTS (SELECT 1 FROM master.dbo.Empresas WHERE CIK = @CIK)
    BEGIN
        -- Separar cidade e estado da localização
        DECLARE @Cidade NVARCHAR(100), @Estado NVARCHAR(50);
        SET @pos1 = CHARINDEX(',', @HeadquartersLocation);
        IF @pos1 > 0
        BEGIN
            SET @Cidade = LTRIM(RTRIM(LEFT(@HeadquartersLocation, @pos1 - 1)));
            SET @Estado = LTRIM(RTRIM(SUBSTRING(@HeadquartersLocation, @pos1 + 1, LEN(@HeadquartersLocation))));
        END
        ELSE
        BEGIN
            SET @Cidade = @HeadquartersLocation;
            SET @Estado = NULL;
        END

        -- Inserir na tabela Empresas
        INSERT INTO master.dbo.Empresas (CIK, NomeEmpresa, Ticker, Setor, DataEntrada, AnoFundacao)
        VALUES (@CIK, @Security, @Symbol, @GICSSector, @DateAdded, @Founded);

        -- Inserir na tabela SubSetor
        INSERT INTO master.dbo.SubSetor (CIK, Industria, SubIndustria)
        VALUES (@CIK, @GICSSector, @GICSSubIndustry);

        -- Inserir na tabela Localizacao
        INSERT INTO master.dbo.Localizacao (CIK, Cidade, Estado, Pais)
        VALUES (@CIK, @Cidade, @Estado, 'Estados Unidos');
    END

    FETCH NEXT FROM cursor_empresas INTO @registro;
END

CLOSE cursor_empresas;
DEALLOCATE cursor_empresas;

PRINT '✓ SP500_companies processado!';
GO

-- ========================================
-- PARTE 2: PROCESSAR SP500_FRED
-- ========================================
USE datasets;
GO

PRINT '';
PRINT 'Processando SP500_fred...';
GO

-- Primeiro, inserir o índice S&P 500 na tabela Indice (se não existir)
IF NOT EXISTS (SELECT 1 FROM master.dbo.Indice WHERE Simbolo = 'SP500')
BEGIN
    INSERT INTO master.dbo.Indice (NomeIndice, Descricao, Simbolo, PaisOrigem)
    VALUES ('S&P 500', 'Standard & Poor''s 500 Index', 'SP500', 'Estados Unidos');
END

DECLARE @IdIndice INT;
SELECT @IdIndice = IdIndice FROM master.dbo.Indice WHERE Simbolo = 'SP500';

-- Processar dados históricos do índice
DECLARE @DataReferencia DATE;
DECLARE @Valor DECIMAL(18,4);
DECLARE @linha NVARCHAR(MAX);
DECLARE @posVirgula INT;

DECLARE cursor_indice CURSOR FOR
SELECT registro FROM SP500_fred;

OPEN cursor_indice;
FETCH NEXT FROM cursor_indice INTO @linha;

WHILE @@FETCH_STATUS = 0
BEGIN
    -- Parse: data,valor
    SET @posVirgula = CHARINDEX(',', @linha);

    IF @posVirgula > 0
    BEGIN
        BEGIN TRY
            SET @DataReferencia = CONVERT(DATE, LEFT(@linha, @posVirgula - 1));
            SET @Valor = CONVERT(DECIMAL(18,4), SUBSTRING(@linha, @posVirgula + 1, LEN(@linha)));

            -- Inserir na tabela IndiceSP500 (se não existir)
            IF NOT EXISTS (
                SELECT 1 FROM master.dbo.IndiceSP500
                WHERE IdIndice = @IdIndice AND DataReferencia = @DataReferencia
            )
            BEGIN
                INSERT INTO master.dbo.IndiceSP500 (IdIndice, DataReferencia, ValorFechamento)
                VALUES (@IdIndice, @DataReferencia, @Valor);

                -- Inserir também na tabela Tempo (se não existir)
                IF NOT EXISTS (SELECT 1 FROM master.dbo.Tempo WHERE DataCompleta = @DataReferencia)
                BEGIN
                    INSERT INTO master.dbo.Tempo (
                        DataCompleta, Ano, Mes, Dia, Trimestre, Semestre, DiaSemana,
                        NomeDiaSemana, NomeMes, EhFimDeSemana
                    )
                    VALUES (
                        @DataReferencia,
                        YEAR(@DataReferencia),
                        MONTH(@DataReferencia),
                        DAY(@DataReferencia),
                        DATEPART(QUARTER, @DataReferencia),
                        CASE WHEN MONTH(@DataReferencia) <= 6 THEN 1 ELSE 2 END,
                        DATEPART(WEEKDAY, @DataReferencia),
                        DATENAME(WEEKDAY, @DataReferencia),
                        DATENAME(MONTH, @DataReferencia),
                        CASE WHEN DATEPART(WEEKDAY, @DataReferencia) IN (1, 7) THEN 1 ELSE 0 END
                    );
                END
            END
        END TRY
        BEGIN CATCH
            -- Ignorar erros de conversão
            PRINT 'Erro ao processar: ' + @linha;
        END CATCH
    END

    FETCH NEXT FROM cursor_indice INTO @linha;
END

CLOSE cursor_indice;
DEALLOCATE cursor_indice;

PRINT '✓ SP500_fred processado!';
GO

-- ========================================
-- PARTE 3: VERIFICAÇÃO FINAL
-- ========================================
USE master;
GO

PRINT '';
PRINT '========================================';
PRINT 'VERIFICAÇÃO FINAL - DADOS PROCESSADOS';
PRINT '========================================';
PRINT '';

SELECT 'Empresas' as Tabela, COUNT(*) as Total FROM Empresas
UNION ALL
SELECT 'SubSetor', COUNT(*) FROM SubSetor
UNION ALL
SELECT 'Localizacao', COUNT(*) FROM Localizacao
UNION ALL
SELECT 'Indice', COUNT(*) FROM Indice
UNION ALL
SELECT 'IndiceSP500', COUNT(*) FROM IndiceSP500
UNION ALL
SELECT 'Tempo', COUNT(*) FROM Tempo
ORDER BY Tabela;
GO

PRINT '';
PRINT '========================================';
PRINT '✅ PROCESSAMENTO ETL CONCLUÍDO!';
PRINT '========================================';
PRINT '';
PRINT 'Dados processados com sucesso:';
PRINT '  ✓ Empresas do S&P 500 inseridas';
PRINT '  ✓ Subsetores classificados';
PRINT '  ✓ Localizações mapeadas';
PRINT '  ✓ Histórico do índice S&P 500 carregado';
PRINT '  ✓ Dimensão Tempo populada';
PRINT '';
PRINT '========================================';
GO
