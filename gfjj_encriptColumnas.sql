--Encriptación de Columnas

USE MASTER
GO
CREATE LOGIN SANIDADlogin WITH PASSWORD='Abcd1234.'
GO
CREATE DATABASE SANIDAD_GFJJ
GO
USE SANIDAD_GFJJ
GO
CREATE USER SANIDAD FOR LOGIN SANIDADLogin
GO
CREATE TABLE VACUNACION
	(DNI VARCHAR(9) PRIMARY KEY,
	nombre varchar(100) NOT NULL,
	apellidos varchar(100) NOT NULL,
	fecha_ult DATE NOT NULL,
	vacuna varchar(200) NOT NULL)
GO
GRANT SELECT, INSERT, UPDATE, DELETE ON VACUNACION TO SANIDAD
GO

-- Creando la clave simétrica
CREATE SYMMETRIC KEY Sanitario_Key
AUTHORIZATION SANIDAD
WITH ALGORITHM=AES_256 
ENCRYPTION BY PASSWORD='Abcd1234.'
GO
EXECUTE AS USER='SANIDAD'
GO
-- Abrimos la clave
OPEN SYMMETRIC KEY [Sanitario_Key] DECRYPTION BY PASSWORD='Abcd1234.'
GO
-- Introducimos los datos en la tabla
INSERT INTO VACUNACION VALUES ('32697849Z',EncryptByKey(Key_GUID('Sanitario_Key'),'Juan Jose'),EncryptByKey(Key_GUID('Sanitario_Key'),'Gomez Fernandez'),'2021-04-04','AstraZeneca'
)
INSERT INTO VACUNACION VALUES ('36434580I',EncryptByKey(Key_GUID('Sanitario_Key'),'Adrian'),EncryptByKey(Key_GUID('Sanitario_Key'),'Iglesias Cid'),'2021-04-04','No se vacuna'
)
INSERT INTO VACUNACION VALUES ('32950257E',EncryptByKey(Key_GUID('Sanitario_Key'),'Oscar'),EncryptByKey(Key_GUID('Sanitario_Key'),'Llao Mera'),'2021-01-08','Pfizer'
)
GO
--Comprobando que funciona
SELECT * FROM VACUNACION
GO

SELECT DNI,CONVERT(VARCHAR,DecryptByKey(nombre)) + ' ' + CONVERT(VARCHAR,DecryptByKey(apellidos)) AS 'Nombre Completo',observaciones
FROM VACUNACION
GO

-- Vemos que funciona. Ahora cerramos las claves y probamos de nuevo la consulta desencriptando
CLOSE ALL SYMMETRIC KEYS
GO

SELECT DNI,CONVERT(VARCHAR,DecryptByKey(nombre)) + ' ' + CONVERT(VARCHAR,DecryptByKey(apellidos)) AS 'Nombre Completo',observaciones
FROM VACUNACION
GO
