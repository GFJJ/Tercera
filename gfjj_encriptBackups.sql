-- Creamos la BD, tablas y contenido
USE MASTER
GO
DROP DATABASE IF EXISTS Backups_GFJJ
GO
CREATE DATABASE Backups_GFJJ;
GO
USE Backups_GFJJ;
GO

DROP TABLE IF EXISTS ORDEN
GO
CREATE TABLE ORDEN (
    ID int IDENTITY(1,1000)  PRIMARY KEY, 
    num int
);
GO

-- Le introducimos el contenido mediante un Procedimiento Almacenado, para tener una cantidad de registros
CREATE OR ALTER PROCEDURE AutoAlta
AS
DECLARE @i int = 1
WHILE @i <201
    BEGIN 
        INSERT ORDEN (num) VALUES (@i)
        Set @i +=1
    END
GO

EXECUTE AutoAlta;
GO

SELECT * FROM ORDEN;
GO

-- Creamos la clave maestra
USE MASTER
GO
DROP MASTER KEY;
CREATE MASTER KEY ENCRYPTION BY PASSWORD = 'Abcd1234.';
GO

-- Creamos el certificado
DROP CERTIFICATE Back_GFJJ
GO
CREATE CERTIFICATE Back_GFJJ
    WITH SUBJECT = 'Back_GFJJ_cert Certificado de Backups';
GO

-- Guardamos el certificado en un fichero, para evitar perder toda la información si perdemos el certificado. No es obligatorio, pero sí recomendable.
BACKUP CERTIFICATE Back_GFJJ 
TO FILE = 'c:\SQLBackups\Back_GFJJ.cert'
WITH PRIVATE KEY (
			FILE = 'c:\SQLBackups\Back_GFJJ.key',
			ENCRYPTION BY PASSWORD = 'Abcd1234.')
GO

-- Hacemos el Backup de la BD
BACKUP DATABASE Backups_GFJJ
TO DISK = 'C:\SQLBackups\Backup_Enc_GFJJ.bak'
WITH
ENCRYPTION
(
ALGORITHM = AES_256,
SERVER CERTIFICATE = Back_GFJJ
)
GO

-- Ahora nos cargamos la BD. Posteriormente el certificado
DROP DATABASE Backups_GFJJ;
GO

DROP CERTIFICATE Back_GFJJ
GO

-- Intentamos restaurar la BD y no nos lo permite porque falta el certificado

RESTORE DATABASE Backups_GFJJ 
FROM DISK = 'c:\SQLBackups\Backup_Enc_GFJJ.bak'
WITH RECOVERY,
REPLACE, STATS = 10;
GO

-- Como se podía preveer, vamos a restaurar el certificado
CREATE CERTIFICATE SQL_encriptar_BBMDBCert
FROM FILE = 'c:\SQLBackups\Back_GFJJ.cert'
WITH PRIVATE KEY (FILE = 'c:\SQLBackups\Back_GFJJ.key',
DECRYPTION BY PASSWORD = 'Abcd1234.');
GO

-- Ahora restauramos la BD correctamente
RESTORE DATABASE Backups_GFJJ 
FROM DISK = 'c:\SQLBackups\Backup_Enc_GFJJ.bak'
WITH RECOVERY,
REPLACE, STATS = 10;
GO

-- Comprobamos que funciona
USE Backups_GFJJ
SELECT * FROM ORDEN;
-- Podemos eliminar el certificado, la clave y la BD (y restaurarlos si fuera preciso, disponemos de los .bak , .cert y .key

USE MASTER
GO
DROP CERTIFICATE Back_GFJJ
GO
DROP MASTER KEY;
DROP DATABASE Backups_GFJJ;
GO


