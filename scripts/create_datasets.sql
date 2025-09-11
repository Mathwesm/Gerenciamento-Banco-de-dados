IF NOT EXISTS(SELECT name FROM sys.tables WHERE name = 'SP500Companies')
    CREATE TABLE  SP500Companies ( -- TODO alterar a tipagem dos dados
        "Symbol" VARCHAR(10),
        "Security" VARCHAR(255),
        "Sector" VARCHAR(100),
        "SubIndustry" VARCHAR(100),
        "place" VARCHAR(255),
        "Date Added" VARCHAR(100),
        "CIK" VARCHAR(100),
        "Founded" VARCHAR(50)
    )

GO

IF (SELECT COUNT(1) FROM SP500Companies) = 0
    BULK INSERT SP500Companies
    FROM '/datasets/SP500-companies.csv'
    WITH (
        FORMAT = 'CSV',
        FIRSTROW = 2
    )

GO

IF NOT EXISTS(SELECT name FROM sys.tables WHERE name = 'SP500')
CREATE TABLE SP500 (
    "Observation Date" DATE,
    "SP500" MONEY
)

GO

IF (SELECT COUNT(1) FROM SP500) = 0
    BULK INSERT SP500
    FROM '/datasets/SP500-fred.csv'
    WITH (
        FORMAT = 'CSV',
        FIRSTROW = 2
    )

GO

IF NOT EXISTS (
    SELECT 1 
    FROM INFORMATION_SCHEMA.COLUMNS 
    WHERE TABLE_SCHEMA = 'dbo'
      AND TABLE_NAME = 'SP500Companies'
      AND COLUMN_NAME = 'country'
)
ALTER TABLE SP500Companies ADD
    country NVARCHAR(100)

GO

IF NOT EXISTS (
    SELECT 1 
    FROM INFORMATION_SCHEMA.COLUMNS 
    WHERE TABLE_SCHEMA = 'dbo'
      AND TABLE_NAME = 'SP500Companies'
      AND COLUMN_NAME = 'state'
)
ALTER TABLE SP500Companies ADD
    state NVARCHAR(100);

GO

WITH LocationParts AS ( -- separa os dados da coluna 'place' para country e state
    SELECT 
        c.Symbol,
        country = LTRIM(RTRIM(MIN(CASE WHEN p.ordinal = 1 THEN p.value END))),
        state   = LTRIM(RTRIM(MIN(CASE WHEN p.ordinal = 2 THEN p.value END)))
    FROM SP500Companies AS c
    CROSS APPLY STRING_SPLIT(c.place, ',', 1) AS p
    GROUP BY c.Symbol
)
UPDATE c
SET
    c.country = lp.country,
    c.state   = lp.state
FROM SP500Companies AS c
JOIN LocationParts AS lp ON c.Symbol = lp.Symbol;

GO

IF EXISTS(SELECT 1 FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_SCHEMA = 'dbo' AND TABLE_NAME = 'SP500Companies' AND COLUMN_NAME = 'place')
    ALTER TABLE SP500Companies DROP COLUMN place