-- Creamos la BD y la tabla
DROP DATABASE IF EXISTS EOS_eq2
CREATE DATABASE EOS_eq2
GO
USE EOS_eq2
GO
DROP TABLE IF EXISTS F102
GO

-- Tenemos que utilizar el tipo de Collate Latin1_General_BIN2 porque si no no funciona.
CREATE TABLE F102  
(  
   ID int identity primary key,  
   Fecha date NOT NULL,
   Cod_Sdo varchar(100) COLLATE Latin1_General_BIN2 NOT NULL,  
   Actividad varchar(100) COLLATE Latin1_General_BIN2 NOT NULL
)
GO

INSERT INTO F102 ( Fecha, Cod_Sdo, Actividad)
VALUES ('2020-03-24','E02128Y', 'Tiro Nocturno'),
		('2020-03-24','E02194L', 'Tiro de Precision'),
		('2020-03-24','E02750O', 'Fast-Rope'),
		('2020-03-25','E02194L', 'Boarding'),
		('2020-03-25','E02750O', 'Abordaje'),
		('2020-03-26','E02128Y', 'Fast-Rope')
GO

-- Desde el entorno gráfico hacemos click derecho sobre la BD y dejamos el cursor en Tasks → Encrypt Columns
-- En el asistente de instalación le damos a Next y seleccionamos las columnas que queremos cifrar, así como el tipo de cifrado:
-- 1- Cifrado aleatorio (asigna valores aleatorios, es más segura pero no se puede estimar de qué trata)
-- 2- Cifrado determinista (genera el mismo valor cifrado para cualquier valor de texto no cifrado concreto)
-- En mi caso puse la columna Cod_Sdo como determinista y la columna Actividad como Aleatoria. Todo a Next como está una vez puesto eso.

-- Comprobamos que están encriptadas
SELECT * FROM F102;

-- Ahora vamos a cerrar la instancia SSMS y abrir otra. Pero antes de abrir conectar le damos a Options -> Additional Connection Parameters y le ponemos "Column Encryption Setting = Enabled"
-- La primera consulta la hacemos desde entorno gráfico. Click derecho en la tabla y seleccionamos Select Top 1000 Rows. Nos debería de mostrar todas las columnas sin encriptar

-- Si cerramos la conexión y volvemos a abrir otra, pero esta vez sin habilitar en opciones de la conexión el "Column Encryption Setting = Enabled", las columnas aparecen cifradas.

USE MASTER;
DROP DATABASE IF EXISTS EOS_eq2
GO
