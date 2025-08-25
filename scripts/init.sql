CREATE DATABASE TesteDB;
GO
USE TesteDB;
GO
CREATE TABLE Clientes (
    Id INT PRIMARY KEY,
    Nome NVARCHAR(100),
    Email NVARCHAR(100)
);
GO
INSERT INTO Clientes VALUES (1, 'João Silva', 'joao@email.com');
GO
