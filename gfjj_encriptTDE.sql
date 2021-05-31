-- Creamos la clave maestra y el certificado

USE MASTER
GO

DROP MASTER KEY;
CREATE MASTER KEY
  ENCRYPTION BY PASSWORD = 'Abcd1234.';
GO

CREATE CERTIFICATE TDE_GFJJ
  WITH SUBJECT = 'TDE Certificado';
GO

-- Para buscar el certificado por comandos.
SELECT TOP 1 * 
FROM sys.certificates 
ORDER BY name DESC
GO

-- Hacemos copia de seguridad del certificado (para cuando la liemos, que pasará)
BACKUP CERTIFICATE TDE_GFJJ 
TO FILE = 'c:\certificados\TDE_GFJJ.cert'
WITH PRIVATE KEY (
			FILE = 'c:\certificados\TDE_GFJJ.key',
			ENCRYPTION BY PASSWORD = 'Abcd1234.')
GO

-- Creamos la BD nueva
DROP DATABASE IF EXISTS HABILITACION_GFJJ
GO
CREATE DATABASE HABILITACION_GFJJ
GO 

-- Accedemos y creamos el certificado
USE HABILITACION_GFJJ;
CREATE DATABASE ENCRYPTION KEY
  WITH ALGORITHM = AES_256
  ENCRYPTION BY SERVER CERTIFICATE TDE_GFJJ;
GO 

-- Salimos de la BD (no se puede activar si tiene conexiones activas) y activamos la encriptación
USE [master];
ALTER DATABASE HABILITACION_GFJJ SET ENCRYPTION ON;
GO 

-- Comprobamos el estado de la BD con la siguiente instrucción
SELECT DB_Name(database_id) AS 'HABILITACION_GFJJ', encryption_state 
FROM sys.dm_database_encryption_keys;
GO

-- Creamos una tabla con un poco de contenido
USE HABILITACION_GFJJ;
CREATE TABLE NOMINAS
	(DNI VARCHAR(20) PRIMARY KEY,
	nombre varchar(100) NOT NULL,
	apellidos varchar(100) NOT NULL,
	nomina INT NOT NULL,
	cuenta varchar(200) NOT NULL)
GO

INSERT INTO NOMINAS VALUES ('32697849Z','Juan Jose','Gomez Fernandez',1160,'ES3635567373')
INSERT INTO NOMINAS VALUES ('33755843F','Andrea','Gallo Santabaya',1210,'ES12241649876')
INSERT INTO NOMINAS VALUES ('36594003W','Francisco Javier','Garcia Ramirez',1322,'ES43878957759')
INSERT INTO NOMINAS VALUES ('32156599N','Edmilton','Wilson Fernandes',1087,'ES302158352')
GO

-- Hacemos Backup de la BD y del log
USE MASTER;
BACKUP DATABASE HABILITACION_GFJJ
TO DISK = 'C:\backup\TDE_GFJJ.bak';
GO 

BACKUP LOG HABILITACION_GFJJ
TO DISK = 'C:\backup\HABILITACION_GFJJ_log.bak'
With NORECOVERY
GO

-- Cerramos la instancia de SSMS, abrimos otra y hacemos backup
USE MASTER;
RESTORE DATABASE HABILITACION_GFJJ
  FROM DISK = 'C:\backup\TDE_GFJJ.bak'
  WITH MOVE 'HABILITACION_GFJJ' TO 'C:\data\HABILITACION_GFJJ_2ndServer.mdf',
       MOVE 'HABILITACION_GFJJ_log' TO 'C:\data\HABILITACION_GFJJ_2ndServer_log.mdf';
GO

-- Probamos a cargarnos el certificado e intentar recuperar la BD
USE MASTER;
DROP DATABASE HABILITACION_GFJJ;
DROP CERTIFICATE TDE_GFJJ;
RESTORE DATABASE HABILITACION_GFJJ
  FROM DISK = 'C:\backup\TDE_GFJJ.bak'
  WITH MOVE 'HABILITACION_GFJJ' TO 'C:\data\HABILITACION_GFJJ_2ndServer.mdf',
       MOVE 'HABILITACION_GFJJ_log' TO 'C:\data\HABILITACION_GFJJ_2ndServer_log.mdf';
GO

-- No permite cargar la BD porque falta el certificado. Lo reinstalamos
DROP CERTIFICATE TDE_GFJJ;
CREATE CERTIFICATE TDE_GFJJ
  FROM FILE = 'c:\certificados\TDE_GFJJ.cert'
WITH PRIVATE KEY (
			FILE = 'c:\certificados\TDE_GFJJ.key',
			DECRYPTION BY PASSWORD = 'Abcd1234.')
GO

RESTORE DATABASE HABILITACION_GFJJ
  FROM DISK = 'C:\backup\TDE_GFJJ.bak'
  WITH MOVE 'HABILITACION_GFJJ' TO 'C:\data\HABILITACION_GFJJ_2ndServer.mdf',
       MOVE 'HABILITACION_GFJJ_log' TO 'C:\data\HABILITACION_GFJJ_2ndServer_log.mdf';
GO

-- Esta vez nos ha dejado. Ahora vamos a probar a restaurarlo utilizando una clave maestra falsa. Nos cargamos la clave maestra y hacemos otra distinta
USE MASTER;
DROP DATABASE HABILITACION_GFJJ;
DROP CERTIFICATE TDE_GFJJ;
DROP MASTER KEY;
CREATE MASTER KEY
  ENCRYPTION BY PASSWORD = 'Pirata.2021';
GO
-- Creamos el certificado nuevo con el mismo nombre que anteriormente
CREATE CERTIFICATE TDE_GFJJ
  WITH SUBJECT = 'TDE Certificado';
GO
-- Al intentar restaurar la BD no nos deja, porque la clave es distinta
RESTORE DATABASE HABILITACION_GFJJ
  FROM DISK = 'C:\backup\TDE_GFJJ.bak'
  WITH MOVE 'HABILITACION_GFJJ' TO 'C:\data\HABILITACION_GFJJ_2ndServer.mdf',
       MOVE 'HABILITACION_GFJJ_log' TO 'C:\data\HABILITACION_GFJJ_2ndServer_log.mdf';
GO

-- Volvemos a cargarla correctamente
DROP CERTIFICATE TDE_GFJJ;
DROP MASTER KEY;
CREATE MASTER KEY
  ENCRYPTION BY PASSWORD = 'Abcd1234.';
GO
CREATE CERTIFICATE TDE_GFJJ
  FROM FILE = 'c:\certificados\TDE_GFJJ.cert'
WITH PRIVATE KEY (
			FILE = 'c:\certificados\TDE_GFJJ.key',
			DECRYPTION BY PASSWORD = 'Abcd1234.')
GO

RESTORE DATABASE HABILITACION_GFJJ
  FROM DISK = 'C:\backup\TDE_GFJJ.bak'
  WITH MOVE 'HABILITACION_GFJJ' TO 'C:\data\HABILITACION_GFJJ_2ndServer.mdf',
       MOVE 'HABILITACION_GFJJ_log' TO 'C:\data\HABILITACION_GFJJ_2ndServer_log.mdf';
GO
