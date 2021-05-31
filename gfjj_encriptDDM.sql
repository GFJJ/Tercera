-- Creamos la BD
DROP DATABASE If Exists Personal_GFJJ
GO
CREATE DATABASE Personal_GFJJ
GO
USE Personal_GFJJ
GO
CREATE SCHEMA Perso;
DROP TABLE Perso.LISTADO;
CREATE TABLE Perso.LISTADO (
    CodVacante    int NOT NULL CONSTRAINT PKLISTADO PRIMARY KEY, 
    Nombre    nvarchar(20) NULL, 
    Apellido    nvarchar(20) NULL, 
    ISFAS varchar(20) NOT NULL, 
    Situacion    varchar(20) CONSTRAINT DFLTSituacion DEFAULT ('Activo') 
                            CONSTRAINT CHKSituacion
							CHECK (Situacion in ('Activo','Licencia','RED')), 
    Email nvarchar(100) NULL, 
    Alta_Cuartel date NOT NULL);
GO

INSERT INTO Perso.LISTADO (CodVacante, Nombre, Apellido, ISFAS, Email,Alta_Cuartel) 
VALUES(1,'Juan Jose','Gomez Fernandez','682412560','awjuanjose@gmail.com','2004-04-24'), 
      (2,'Ernesto','Grial Facundo','682954456','jcerlf2@mdef.com','2021-04-12'), 
      (3,'Lucia','Garrote Lopez','682120385','fjvywq2@mdef.com', '1/1/1959');
GO

-- Creamos los usuarios y les damos permisos
CREATE USER tropa WITHOUT LOGIN; 
CREATE USER subof WITHOUT LOGIN;
GO

GRANT SELECT ON Perso.Listado TO tropa; 
GRANT SELECT ON Perso.Listado TO subof;
GRANT UNMASK TO subof;
GO

-- Enmascaramiento de tipo Default

ALTER TABLE Perso.LISTADO
ALTER COLUMN Email varchar(200) MASKED WITH (FUNCTION = 'default()');
GO

-- Comprobamos con el usuario tropa que no puede ver la columna email, sale como las películas de Canal+
EXECUTE AS USER='tropa'; 
GO

SELECT * 
FROM   Perso.LISTADO; 
GO

-- Ahora comprobamos con el usuario de suboficiales que sí que vemos correctamente la columna
REVERT
GO

EXECUTE AS USER='subof'; 
GO
SELECT * 
FROM   Perso.LISTADO; 
GO

REVERT
GO

-- Comprobamos el enmascaramiento que tiene cada columna mediante un procedimiento almacenado

CREATE OR ALTER PROC ElZorro
AS
BEGIN
		SET NOCOUNT ON 
		SELECT c.name, tbl.name as table_name, c.is_masked, c.masking_function  
		FROM sys.masked_columns AS c  
		JOIN sys.tables AS tbl   
			ON c.[object_id] = tbl.[object_id]  
		WHERE is_masked = 1;
END
GO

EXEC ElZorro
GO

-- Creamos el enmascaramiento de tipo parcial a la columna ISFAS.

ALTER TABLE Perso.LISTADO
ALTER COLUMN ISFAS ADD MASKED WITH (FUNCTION = 'partial(0,"XXXXX",4)')
GO

-- Comprobamos con el usuario tropa que solamente nos muestra los 4 últimos dígitos del nº del ISFAS
EXECUTE AS USER='tropa'; 
GO

SELECT * 
FROM   Perso.LISTADO; 
GO

REVERT
GO

-- Ahora comprobamos con el usuario de suboficiales que sí que vemos correctamente la columna

EXECUTE AS USER='subof'; 
GO
SELECT * 
FROM   Perso.LISTADO; 
GO

REVERT
GO

-- Comprobamos el estado de encriptación de la tabla
EXEC ElZorro
GO

-- Encriptamos con tipo aleatorio la columna que refleja el codigo de Vacante
ALTER TABLE Perso.LISTADO
ALTER COLUMN CodVacante ADD MASKED WITH (FUNCTION = 'random(1, 140)')
GO

-- Comprobamos con el usuario tropa que los numeros del codigo cambian de valor
EXECUTE AS USER='tropa'; 
GO

SELECT * 
FROM   Perso.LISTADO; 
GO

REVERT
GO

-- Ahora comprobamos con el usuario de suboficiales que sí que vemos correctamente la columna

EXECUTE AS USER='subof'; 
GO
SELECT * 
FROM   Perso.LISTADO; 
GO

REVERT
GO

-- Comprobamos el estado de encriptación de la tabla
EXEC ElZorro
GO

-- Le vamos a quitar encriptación a la columna de email. Comprobamos el estado de encriptación de la tabla
ALTER TABLE Perso.LISTADO
ALTER COLUMN Email DROP MASKED;
GO

EXEC ElZorro
GO

-- Copiamos los datos que nos interesan
SELECT nombre, apellido, email INTO Perso.EMAIL FROM Perso.LISTADO;

-- Ahora volvemos a enmascarar la columna
ALTER TABLE Perso.LISTADO
ALTER COLUMN email ADD MASKED WITH (FUNCTION = 'email()')
GO

-- Comprobamos con el usuario tropa que el email está cifrado
EXECUTE AS USER='tropa'; 
GO

SELECT * 
FROM   Perso.LISTADO; 
GO

REVERT
GO

-- Retiramos los permisos a los suboficiales y comprobamos que efectivamente no tiene permisos
REVOKE  UNMASK FROM  subof
GO

EXECUTE AS USER='subof'; 
GO
SELECT * 
FROM   Perso.LISTADO; 
GO

REVERT
GO

-- Eliminamos los usuarios y la BD tras las filtraciones
DROP USER subof;
DROP USER tropa;
USE MASTER;
DROP DATABASE Personal_GFJJ;
