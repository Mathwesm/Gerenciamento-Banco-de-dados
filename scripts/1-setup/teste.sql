/* ============================================================
   SCRIPT: REMOVER DATA INVÁLIDA 9389-01-01
   Afeta:
     - datasets.dbo.SP500_data (observation_date)
     - datasets.dbo.CSI500 ([date])
     - FinanceDB.Tempo (DataCompleta)
     - FinanceDB.PrecoAcao (IdTempo)
     - FinanceDB.Dividendos (IdTempo)
     - FinanceDB.PrecoAcaoCSI500 (IdTempo)
     - FinanceDB.SP500Historico (DataReferencia)
     - FinanceDB.CSI500Historico (DataReferencia)
   ============================================================ */

---------------------------------------------------------------
-- PARTE 1: REMOVER DATA 9389-01-01 DAS TABELAS BRUTAS (DATASETS)
---------------------------------------------------------------
USE datasets;
PRINT '===== REMOVENDO DATA 9389-01-01 EM DATASETS =====';

-- SP500_data
DECLARE @Rows_SP500 INT, @Rows_CSI500 INT;

DELETE FROM dbo.SP500_data
WHERE observation_date = '9389-01-01';

SET @Rows_SP500 = @@ROWCOUNT;
PRINT 'Linhas removidas em datasets.dbo.SP500_data (observation_date = 9389-01-01): '
      + CAST(@Rows_SP500 AS VARCHAR(20));


-- CSI500
DELETE FROM dbo.CSI500
WHERE [date] = '9389-01-01';

SET @Rows_CSI500 = @@ROWCOUNT;
PRINT 'Linhas removidas em datasets.dbo.CSI500 ([date] = 9389-01-01): '
      + CAST(@Rows_CSI500 AS VARCHAR(20));

PRINT '===== FIM PARTE 1 (DATASETS) =====';
---------------------------------------------------------------
-- PARTE 2: REMOVER DATA 9389-01-01 DO MODELO DIMENSIONAL (FinanceDB)
---------------------------------------------------------------
USE FinanceDB;
PRINT '===== REMOVENDO DATA 9389-01-01 EM FinanceDB =====';

DECLARE
    @DataInvalida DATE = '9389-01-01',
    @IdTempo INT;

-- Descobrir IdTempo correspondente
SELECT @IdTempo = IdTempo
FROM Tempo
WHERE DataCompleta = @DataInvalida;

IF @IdTempo IS NULL
BEGIN
    PRINT 'Nenhum registro encontrado em Tempo com DataCompleta = 9389-01-01.';
END
ELSE
BEGIN
    PRINT 'Encontrado IdTempo = ' + CAST(@IdTempo AS VARCHAR(20))
        + ' para DataCompleta = 9389-01-01.';

    -- 2.1 Remover fatos que apontam para esse IdTempo
    DECLARE
        @Rows_PrecoAcao INT,
        @Rows_Dividendos INT,
        @Rows_PrecoAcaoCSI500 INT,
        @Rows_SP500Hist INT,
        @Rows_CSI500Hist INT;

    PRINT 'Removendo dependências em tabelas de fato...';

    -- Fato PrecoAcao (S&P 500)
    DELETE FROM PrecoAcao
    WHERE IdTempo = @IdTempo;

    SET @Rows_PrecoAcao = @@ROWCOUNT;
    PRINT 'Linhas removidas em PrecoAcao (IdTempo = '
        + CAST(@IdTempo AS VARCHAR(20)) + '): '
        + CAST(@Rows_PrecoAcao AS VARCHAR(20));

    -- Fato Dividendos
    DELETE FROM Dividendos
    WHERE IdTempo = @IdTempo;

    SET @Rows_Dividendos = @@ROWCOUNT;
    PRINT 'Linhas removidas em Dividendos (IdTempo = '
        + CAST(@IdTempo AS VARCHAR(20)) + '): '
        + CAST(@Rows_Dividendos AS VARCHAR(20));

    -- Fato PrecoAcaoCSI500
    DELETE FROM PrecoAcaoCSI500
    WHERE IdTempo = @IdTempo;

    SET @Rows_PrecoAcaoCSI500 = @@ROWCOUNT;
    PRINT 'Linhas removidas em PrecoAcaoCSI500 (IdTempo = '
        + CAST(@IdTempo AS VARCHAR(20)) + '): '
        + CAST(@Rows_PrecoAcaoCSI500 AS VARCHAR(20));

    -- Históricos agregados por DataReferencia
    DELETE FROM SP500Historico
    WHERE DataReferencia = @DataInvalida;

    SET @Rows_SP500Hist = @@ROWCOUNT;
    PRINT 'Linhas removidas em SP500Historico (DataReferencia = 9389-01-01): '
        + CAST(@Rows_SP500Hist AS VARCHAR(20));

    DELETE FROM CSI500Historico
    WHERE DataReferencia = @DataInvalida;

    SET @Rows_CSI500Hist = @@ROWCOUNT;
    PRINT 'Linhas removidas em CSI500Historico (DataReferencia = 9389-01-01): '
        + CAST(@Rows_CSI500Hist AS VARCHAR(20));

    -- 2.2 Remover linha da dimensão Tempo
    PRINT 'Removendo linha da dimensão Tempo...';

    DELETE FROM Tempo
    WHERE IdTempo = @IdTempo;

    IF @@ROWCOUNT = 1
        PRINT 'Registro removido da tabela Tempo (IdTempo = ' + CAST(@IdTempo AS VARCHAR(20)) + ').';
    ELSE
        PRINT 'Nenhum registro removido de Tempo (algo inconsistente aconteceu).';
END

PRINT '===== FIM PARTE 2 (FinanceDB) =====';

PRINT '===== LIMPEZA DA DATA 9389-01-01 CONCLUÍDA =====';
GO
