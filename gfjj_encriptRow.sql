-- Creamos la BD, la tabla y los usuarios
DROP DATABASE IF Exists PLMS;
CREATE DATABASE PLMS;
USE PLMS;

CREATE TABLE ESTADILLO (
    ID  int NOT NULL IDENTITY PRIMARY KEY, 
    Nombre    nvarchar(20) NULL, 
    Apellido    nvarchar(20) NULL,
    Situacion    varchar(20) NOT NULL CONSTRAINT DFLTSituacion DEFAULT ('Presente') 
                            CONSTRAINT CHKSituacion
							CHECK (Situacion in ('Presente','Guardia','Ausente','Vacaciones')),
    fecha date NOT NULL,
	usuario char(50) NOT NULL DEFAULT CURRENT_USER);
GO

DROP USER IF EXISTS Oficina;
CREATE USER Oficina WITHOUT LOGIN; 

DROP USER IF EXISTS Despensa
CREATE USER Despensa WITHOUT LOGIN;

DROP USER IF EXISTS Jardin 
CREATE USER Jardin WITHOUT LOGIN;
GO

DROP USER IF EXISTS Secretaria 
CREATE USER Secretaria WITHOUT LOGIN;
GO

GRANT SELECT, INSERT ON ESTADILLO TO Despensa, Jardin, Secretaria
GRANT SELECT ON ESTADILLO TO Oficina
GRANT EXECUTE TO Despensa, Jardin, Secretaria
GO
-- Crea la política de seguridad y el filtro a aplicar
DROP SECURITY POLICY IF EXISTS dbo.ESTADILLO_SecurityPolicy ;
GO 
DROP FUNCTION usuario$SecurityPredicate;
CREATE FUNCTION dbo.usuario$SecurityPredicate (@usuario AS sysname) 
    RETURNS TABLE 
WITH SCHEMABINDING 
AS 
    RETURN (SELECT 1 AS usuario$SecurityPredicate 
            WHERE @usuario = USER_NAME()
               OR (USER_NAME() IN ('Oficina','dbo')));
GO 
CREATE SECURITY POLICY dbo.RLSGFJJ
ADD FILTER PREDICATE dbo.usuario$SecurityPredicate(usuario) ON dbo.ESTADILLO
WITH (STATE = ON); 

-- Creamos el procedimiento almacenado que permita automatizarlo
CREATE OR ALTER PROCEDURE Nuevo_estadillo
	@nombre AS VARCHAR(20),
	@apellido AS VARCHAR(20),
	@situacion AS varchar(20)
AS
BEGIN
DECLARE @fecha AS DATE;
SET @fecha = (SELECT CONVERT (date, GETDATE()));
INSERT INTO dbo.ESTADILLO (nombre, apellido, situacion, fecha, usuario) VALUES (@nombre,@apellido,@situacion,@fecha,NULL);
END;

-- Probamos que funciona
EXECUTE AS USER = 'jardin'; 
GO
EXEC dbo.Nuevo_estadillo 'Alfonso','Molina Perez',DEFAULT;
EXEC dbo.Nuevo_estadillo 'Ramon','Manzano Cordoba','Ausente'; 
GO
SELECT * FROM ESTADILLO;
REVERT;

EXECUTE AS USER = 'despensa'; 
GO
EXEC dbo.Nuevo_estadillo 'Alberto','Sampaio Lago','Vacaciones';
EXEC dbo.Nuevo_estadillo 'Lucia','Sanchez Fernandez','Guardia'; 
GO
SELECT * FROM ESTADILLO;
REVERT;

EXECUTE AS USER = 'secretaria'; 
GO
EXEC dbo.Nuevo_estadillo 'Manuel','Folgar Valencia',DEFAULT;
EXEC dbo.Nuevo_estadillo 'Cristina','Berrocal Aguirre',DEFAULT; 
GO
SELECT * FROM ESTADILLO;
REVERT;
-- Como oficina comprobamos que no puede insertar, pero sí ver todos los registros
EXECUTE AS USER = 'secretaria'; 
GO
EXEC dbo.Nuevo_estadillo 'Francisco','Lopez Alonso',DEFAULT;
GO
SELECT * FROM ESTADILLO;
REVERT;



