-- La BD que habíamos creado:
USE MASTER
GO
DROP DATABASE IF EXISTS gfjj
GO

CREATE DATABASE gfjj
GO

USE gfjj
GO

CREATE TABLE dbo.DESTINO
(
Destino VARCHAR(20) NOT NULL PRIMARY KEY,
Compañia VARCHAR(20),
Encargado VARCHAR(9)
);

CREATE TABLE dbo.MUNICION
(
 Mun_MM INT NOT NULL PRIMARY KEY,
 Cant_Mun INT DEFAULT 0
);

CREATE TABLE dbo.ARMAMENTO
(
 NS_Arm VARCHAR(9) NOT NULL PRIMARY KEY,
 Clase VARCHAR(20) NOT NULL,
 MARCA VARCHAR(9) NOT NULL,
 Modelo VARCHAR(9) NOT NULL,
 Mun_MM INT NOT NULL,
 FOREIGN KEY (Mun_MM) REFERENCES dbo.MUNICION (Mun_MM)
);

CREATE TABLE dbo.MILITAR
(
 DNI VARCHAR(9) NOT NULL PRIMARY KEY,
 NOMBRE VARCHAR(30) NOT NULL,
 NS_Arm VARCHAR(9),
 Destino VARCHAR(20) NOT NULL,
  FOREIGN KEY (Destino) REFERENCES dbo.DESTINO (Destino),
 FOREIGN KEY (NS_Arm) REFERENCES dbo.ARMAMENTO (NS_Arm)
);

CREATE TABLE dbo.CAMPAMENTO
(
 COD_Cam VARCHAR(2) NOT NULL PRIMARY KEY,
 Localidad VARCHAR(15) NOT NULL,
 Distancia INT NOT NULL,
 Alojamiento INT NOT NULL
);

CREATE TABLE dbo.CLASE_CAMPAMENTO
(
 ID_Cam INT NOT NULL PRIMARY KEY,
 Clase VARCHAR(25),
 Destino VARCHAR(20) NOT NULL,
 FOREIGN KEY (Destino) REFERENCES dbo.DESTINO (Destino)
);

CREATE TABLE dbo.MANIOBRAS
(
 COD_Man VARCHAR(9) NOT NULL PRIMARY KEY,
 COD_Cam VARCHAR(2) NOT NULL,
 Fecha_ini DATE,
 FECHA_fin DATE,
 ID_CAM INT NOT NULL,
 FOREIGN KEY (COD_Cam)REFERENCES dbo.CAMPAMENTO (Cod_Cam),
 FOREIGN KEY (ID_CAM)REFERENCES dbo.CLASE_CAMPAMENTO (ID_Cam)
);

CREATE TABLE dbo.VIVERES
(
 COD_Alim VARCHAR(2) NOT NULL PRIMARY KEY,
 Tipo VARCHAR(9) NOT NULL,
 Alimento VARCHAR(20),
 Reserva_Alim INT,
 Unidad VARCHAR(6)
);

CREATE TABLE dbo.MATERIAL
(
 NIN INT NOT NULL PRIMARY KEY,
 Nombre VARCHAR(20) NOT NULL,
 Marca VARCHAR(20),
 Total INT
);

CREATE TABLE dbo.VEHICULO
(
 ID_Veh INT NOT NULL PRIMARY KEY,
 Marca VARCHAR(15),
 Modelo VARCHAR(15),
 Consumo INT
);

CREATE TABLE dbo.CONSUMO_VIVERES
(
 Cod_Man VARCHAR(9) NOT NULL,
 FOREIGN KEY (Cod_Man) REFERENCES dbo.MANIOBRAS(Cod_Man),
 Cod_Alim VARCHAR(2) NOT NULL,
 FOREIGN KEY (Cod_Alim) REFERENCES dbo.VIVERES(Cod_Alim),
 Con_Viv INT  
);

CREATE TABLE dbo.CONSUMO_MUNICION
(
 Cod_Man VARCHAR(9) NOT NULL,
 FOREIGN KEY (Cod_Man) REFERENCES dbo.MANIOBRAS(Cod_Man),
 Mun_MM INT NOT NULL,
 FOREIGN KEY (Mun_MM) REFERENCES dbo.MUNICION(Mun_MM),
 Con_Mun INT  
);

CREATE TABLE dbo.CONSUMO_COMBUSTIBLE
(
 Cod_Man VARCHAR(9) NOT NULL,
 FOREIGN KEY (Cod_Man) REFERENCES dbo.MANIOBRAS(Cod_Man),
 ID_Veh INT NOT NULL,
 FOREIGN KEY (ID_Veh) REFERENCES dbo.VEHICULO(ID_Veh),
 Km INT DEFAULT 0,
 Con_Com INT
);

CREATE TABLE dbo.CONSUMO_MATERIAL
(
 Cod_Man VARCHAR(9) NOT NULL,
 FOREIGN KEY (Cod_Man) REFERENCES dbo.MANIOBRAS(Cod_Man),
 NIN INT NOT NULL,
 FOREIGN KEY (NIN) REFERENCES dbo.MATERIAL(NIN),
 Con_Mat INT  
);

CREATE TABLE dbo.DIAS_MANIOBRAS
(
 Cod_Man VARCHAR(9) NOT NULL,
 FOREIGN KEY (Cod_Man) REFERENCES dbo.MANIOBRAS(Cod_Man),
 DNI VARCHAR (9) NOT NULL,
 FOREIGN KEY (DNI) REFERENCES dbo.MILITAR(DNI),
 Dias INT
);

DROP TRIGGER IF EXISTS Trg_Consumo_Viveres
GO
CREATE OR ALTER TRIGGER Trg_Consumo_Viveres
ON CONSUMO_VIVERES
FOR INSERT
AS
		DECLARE @Existencias INT
		
		SELECT @Existencias=Reserva_Alim
		FROM VIVERES
		WHERE Cod_Alim = (SELECT Cod_Alim FROM INSERTED)
		
		IF @Existencias < (SELECT Con_Viv FROM INSERTED)
			BEGIN
					RAISERROR ('Lo sentimos. No hay suficientes víveres disponibles. Contacte con Despensa', -- Message text.
					16, -- Severity.
					1 -- State.
					);
						ROLLBACK TRAN
						RETURN
			END
		ELSE
			BEGIN
					Update VIVERES
					SET Reserva_Alim = Reserva_Alim - (SELECT Con_Viv FROM Inserted)
					WHERE Cod_Alim = (SELECT Cod_Alim FROM INSERTED)
			END
GO

-- Script para el consumo de materiales 
DROP TRIGGER IF EXISTS Trg_Consumo_Material
GO
CREATE OR ALTER TRIGGER Trg_Consumo_Material
ON CONSUMO_MATERIAL
FOR INSERT
AS
		DECLARE @Materiales INT
		
		SELECT @Materiales=Total
		FROM MATERIAL
		WHERE NIN = (SELECT NIN FROM INSERTED)
		
		IF @Materiales < (SELECT NIN FROM INSERTED)
			BEGIN
					RAISERROR ('Lo sentimos. No hay suficiente cantidad de material disponible. Contacte con Utensilios', -- Message text.
					16, -- Severity.
					1 -- State.
					);
						ROLLBACK TRAN
						RETURN
			END
		ELSE
			BEGIN
					Update MATERIAL
					SET Total = Total - (SELECT Con_Mat FROM Inserted)
					WHERE NIN = (SELECT NIN FROM INSERTED)
			END
GO

-- Script para el consumo de munición
DROP TRIGGER IF EXISTS Trg_Consumo_Municion
GO
CREATE OR ALTER TRIGGER Trg_Consumo_Municion
ON CONSUMO_MUNICION
FOR INSERT
AS
		DECLARE @Cartuchos INT
		
		SELECT @Cartuchos=Cant_Mun
		FROM MUNICION
		WHERE Mun_MM = (SELECT Mun_MM FROM INSERTED)
		
		IF @Cartuchos < (SELECT Mun_MM FROM INSERTED)
			BEGIN
					RAISERROR ('Lo sentimos. No hay suficiente munición de ese calibre. Contacte con Armamento', -- Message text.
					16, -- Severity.
					1 -- State.
					);
						ROLLBACK TRAN
						RETURN
			END
		ELSE
			BEGIN
					Update MUNICION
					SET Cant_Mun = Cant_Mun - (SELECT Con_Mun FROM Inserted)
					WHERE Mun_MM = (SELECT Mun_MM FROM INSERTED)
			END
GO
-- Script que actualiza el consumo de un vehículo, cogiendo el consumo que marca su ficha técnica
DROP TRIGGER IF EXISTS Trg_Consumo_Combustible
GO
CREATE OR ALTER TRIGGER Trg_Consumo_Combustible
ON CONSUMO_COMBUSTIBLE
FOR INSERT
AS
		DECLARE @Gasoil INT
		
		SELECT @Gasoil=Consumo
		FROM VEHICULO
		WHERE ID_Veh = (SELECT ID_Veh FROM INSERTED)
				
			BEGIN
					Update CONSUMO_COMBUSTIBLE
					SET Con_Com = (SELECT Km FROM Inserted) * (SELECT @Gasoil) / 100
					WHERE ID_Veh = (SELECT ID_Veh FROM INSERTED) AND Cod_Man = (SELECT Cod_man FROM INSERTED)
			END
GO

-- Introducimos datos en la BD

INSERT INTO dbo.DESTINO (Destino, Compañia) VALUES
('SEG','Seguridad'),
('PN','Policia Naval'),
('PLM','Plana Mayor'),
('EOS','Equipos Operativos')
GO

INSERT INTO dbo.MUNICION (Mun_MM, Cant_Mun) VALUES
(9,6000),
(5.56,18000),
(7.62,5000),
(12,1500)
GO

INSERT INTO dbo.ARMAMENTO (NS_Arm, Clase, MARCA, Modelo, Mun_MM) VALUES
('FN04717','Fusil','HK','G36',5.56),
('FN04770','Fusil','HK','G36',5.56),
('FN04716','Fusil','HK','G36',5.56),
('FN04771','Fusil','HK','G36',5.56),
('FN14589','Fusil','HK','G36K',5.56),
('FN14590','Fusil','HK','G36K',5.56),
('FN14591','Fusil','HK','G36K',5.56),
('57670FN','Pistola','STAR','Super',9),
('57671FN','Pistola','STAR','Super',9),
('5649G','Pistola','STAR','30M',9),
('5650G','Pistola','STAR','30M',9),
('FS15745','Ametralladora','Mauser','MG 42',7.62),
('FN045697','Ametralladora ligera','FN','Minimi',7.62),
('OT5780','Fusil francotirador','Accuracy','AW',7.62),
('FN57532','Escopeta','Remington','870',12)
GO

INSERT INTO dbo.ARMAMENTO (NS_Arm, Clase, MARCA, Modelo, Mun_MM) VALUES
('OT5780','dor','Accuracy','AW',7.62)
GO

INSERT INTO dbo.MILITAR (DNI, NOMBRE, NS_Arm, Destino) VALUES
('32637357Y','Alfredo Perez','FN14589','SEG'),
('32374058Y','Jorge Gonzalez Bellon','FN04716','SEG'),
('36947201D','John Pena Thomas','57671FN','PN'),
('32409123L','Guillermo Baliña Perez','5650G','PN'),
('7495234R','Saul Cabanillas Rodriguez','FN04717','PLM'),
('32697849Z','Juan Gomez Fernandez','FN04770','PLM'),
('X7830521','Rafael Florez Castillejo','FN57532','EOS'),
('36280541X','Lucia Cabanas Lopez','FN14591','EOS'),
('32941523A','Francisco Bermudez Suarez','OT5780','EOS'),
('32850642V','Hector Criado Garcia','FN045697','EOS')
GO

INSERT INTO dbo.CAMPAMENTO (COD_Cam, Localidad, Distancia, Alojamiento) VALUES
('PA','Parga',88,120),
('VI','Viveiro',87,40),
('AP','As Pontes',41,30),
('TE','Pico Teleno',307,160),
('TT','Tentegorra',1053,30),
('RE','Retin',1040,300),
('TV','TVR Embarque',0,11)
GO

INSERT INTO dbo.CLASE_CAMPAMENTO (ID_Cam, Clase, Destino) VALUES
(1,'UCIN','PN'),
(2,'Tiro policial','PN'),
(3,'Marchas y Tiro','SEG'),
(4,'Tiro Diurno y Nocturno','SEG'),
(5,'Despliegue Tactico','SEG'),
(6,'Topografia y Despliegue','SEG'),
(7,'Tiro Diurno y Nocturno','PLM'),
(8,'Convivencia','EOS'),
(9,'Fuego en Movimiento','EOS'),
(10,'Despliegue Tactico','EOS'),
(11,'Tirador de precision','EOS')
GO

INSERT INTO dbo.MANIOBRAS (COD_Man, COD_CAM, Fecha_ini, FECHA_fin, ID_CAM) VALUES
('pa1','PA','2019-03-12','2019-03-14',4),
('pa2','PA','2019-06-21','2019-06-25',9),
('pa3','PA','2019-09-14','2019-09-18',3),
('pa4','PA','2019-11-05','2019-11-07',7),
('vi1','VI','2019-01-15','2019-01-17',6),
('ap1','AP','2019-04-12','2019-04-14',2),
('te1','TE','2019-05-19','2019-05-29',10),
('re1','RE','2019-09-17','2019-10-03',9),
('tt1','TT','2019-11-06','2019-11-11',1),
('tv1','TV','2019-02-21','2019-02-24',11),
('tv2','TV','2019-10-01','2019-10-07',8)
GO

INSERT INTO dbo.VIVERES (COD_Alim, Tipo, Alimento, Reserva_Alim, Unidad) VALUES
('fi','fresco','filetes de cerdo',6000,'kilo'),
('pe','congelado','pescado',9000,'kilo'),
('co','bebida','cocacola',12000,'litro')
GO

INSERT INTO dbo.MATERIAL (NIN, Nombre, Marca, Total) VALUES
(1,'pila','duracell',600),
(2,'snaplight','Cyalume',300),
(3,'tapones auditivos','generico',3000)
GO

INSERT INTO dbo.VEHICULO (ID_Veh, Marca, Modelo, Consumo) VALUES
(1,'Land Rover','Defender',18),
(2,'IVECO','7217',40),
(3,'NISSAN','Pathfinder',10)
GO

INSERT INTO dbo.CONSUMO_VIVERES (Cod_Man, Cod_Alim, Con_Viv) VALUES
('pa1','fi',60),
('pa2','pe',30),
('pa3','fi',45),
('pa4','pe',45),
('vi1','fi',80),
('ap1','pe',10),
('te1','fi',90),
('re1','pe',120),
('tt1','fi',25),
('tv1','pe',40),
('tv2','fi',50),
('pa1','co',120),
('pa2','co',60),
('pa3','co',90),
('pa4','co',90),
('vi1','co',160),
('ap1','co',20),
('te1','co',180),
('re1','co',240),
('tt1','co',50),
('tv1','co',80),
('tv2','co',100)
GO

INSERT INTO dbo.CONSUMO_MUNICION (Cod_Man, Mun_MM, Con_Mun) VALUES
('pa1',5.56,3000),
('pa2',5.56,1200),
('pa2',12,100),
('pa2',7.62,200),
('pa3',5.56,2000),
('pa4',5.56,2000),
('ap1',9,1500),
('re1',5.56,4000),
('re1',7.62,1200),
('re1',12,400),
('tv1',7.62,300)
GO

INSERT INTO dbo.CONSUMO_COMBUSTIBLE (Cod_Man, ID_Veh, KM) VALUES
('pa1',2,204),
('pa2',1,202),
('pa3',2,212),
('pa4',3,196),
('vi1',2,120),
('ap1',3,90),
('te1',2,685),
('re1',2,2144),
('tt1',1,2102),
('tv1',3,5),
('tv2',1,5)
GO
INSERT INTO dbo.DIAS_MANIOBRAS (Cod_Man, DNI) VALUES
('pa1','32637357Y'),
('pa1','32374058Y'),
('pa2','36280541X'),
('pa2','X7830521'),
('pa2','32850642V'),
('pa3','32637357Y'),
('pa3','32374058Y'),
('pa4','32697849Z'),
('pa4','7495234R'),
('vi1','32374058Y'),
('ap1','36947201D'),
('te1','X7830521'),
('te1','36280541X'),
('te1','32941523A'),
('te1','32850642V'),
('re1','36280541X'),
('re1','32941523A'),
('re1','32850642V'),
('tt1','32409123L'),
('tv1','32941523A'),
('tv2','X7830521'),
('tv2','36280541X'),
('tv2','32941523A'),
('tv2','32850642V')
GO

INSERT INTO dbo.CONSUMO_MATERIAL (Cod_Man, NIN, Con_Mat) VALUES
('pa1',1,16),
('pa1',2,4),
('pa1',3,50),
('pa2',1,12),
('pa2',2,18),
('pa2',3,22),
('pa3',1,8),
('pa3',3,40),
('pa4',1,12),
('pa4',2,10),
('pa4',3,50),
('vi1',1,8),
('vi1',2,12),
('ap1',3,30),
('te1',1,20),
('te1',2,30),
('te1',3,80),
('re1',2,40),
('re1',3,60),
('tv1',2,14),
('tv1',3,2),
('tv2',1,11)
GO

-- Particiones

DROP DATABASE IF EXISTS gfjj_archivo
GO

CREATE DATABASE [gfjj_archivo] 
    ON PRIMARY ( NAME = 'gfjj_archivo', 
        FILENAME = 'C:\Data\gfjj_archivo.mdf' , 
        SIZE = 15360KB , MAXSIZE = UNLIMITED, FILEGROWTH = 0) 
    LOG ON ( NAME = 'gfjj_archivo_log', 
        FILENAME = 'C:\Data\gfjj_archivo_log.ldf' , 
        SIZE = 10176KB , MAXSIZE = 2048GB , FILEGROWTH = 10%) 
GO

USE gfjj_archivo
GO

ALTER DATABASE [gfjj_archivo] ADD FILEGROUP [GFJJFILEGROUP_Historico] 
GO
ALTER DATABASE [gfjj_archivo] ADD FILEGROUP [GFJJFILEGROUP_2020] 
GO 
ALTER DATABASE [gfjj_archivo] ADD FILEGROUP [GFJJFILEGROUP_2021]
GO

ALTER DATABASE [gfjj_archivo] ADD FILE ( NAME = 'Nuevas_Altas_gfjj', FILENAME = 'c:\Data\Nuevas_Altas_gfjj.ndf', SIZE = 5MB, MAXSIZE = 100MB, FILEGROWTH = 2MB ) TO FILEGROUP [GFJJFILEGROUP_Historico] 
GO
ALTER DATABASE [gfjj_archivo] ADD FILE ( NAME = 'ARCHIVO_2020', FILENAME = 'c:\Data\ARCHIVO_2020.ndf', SIZE = 5MB, MAXSIZE = 100MB, FILEGROWTH = 2MB ) TO FILEGROUP [GFJJFILEGROUP_2020] 
GO
ALTER DATABASE [gfjj_archivo] ADD FILE ( NAME = 'ARCHIVO_2021', FILENAME = 'c:\Data\ARCHIVO_2021.ndf', SIZE = 5MB, MAXSIZE = 100MB, FILEGROWTH = 2MB ) TO FILEGROUP [GFJJFILEGROUP_2021] 
GO

CREATE PARTITION FUNCTION PART_FUNCTION_gfjj (datetime) 
AS RANGE RIGHT 
	FOR VALUES ('2020-01-01','2021-01-01')
GO

CREATE PARTITION SCHEME PART_SCHEMA_gfjj 
AS PARTITION PART_FUNCTION_gfjj
	TO (GFJJFILEGROUP_Historico,GFJJFILEGROUP_2020,GFJJFILEGROUP_2021) 
GO

DROP TABLE IF EXISTS GFJJ_Registro
GO
CREATE TABLE GFJJ_Registro (
	ID INT NOT NULL IDENTITY,
	Nombre varchar(40) NULL,
	Almacenaje varchar(20) NULL,
	fecha_documento datetime) 
	ON PART_SCHEMA_GFJJ
		(fecha_documento)
GO

INSERT INTO GFJJ_Registro (Nombre, Almacenaje, fecha_documento) 
	Values ('BOD Nº 1','Secretaria','2020-01-02'),
	('BOD Nº 2','Secretaria','2020-01-03'),
	('Sancion Disciplinaria','Personal','2020-05-14'),
	('Revista de Defensa','OFAPAR','2020-01-02'),
	('Solicitud de Condecoraciones','Archivo','1998-03-13'),
	('BOD Nº 1','Secretaria','2021-01-02'),
	('Orden de Operaciones Operacion Balmis','Operaciones','2021-02-16'),
	('Revista de Defensa','Archivo','2005-08-01'),
	('Compromiso Soldado Gómez','Personal','2004-03-24')
GO

SELECT *,$Partition.PART_FUNCTION_GFJJ(fecha_documento) AS Partition
FROM GFJJ_Registro
GO

DECLARE @TableName NVARCHAR(200) = N'GFJJ_Registro' 
SELECT SCHEMA_NAME(o.schema_id) + '.' + OBJECT_NAME(i.object_id) AS [object] , p.partition_number AS [p#] , GFJJFILEGROUP.name AS [filegroup] , p.rows , au.total_pages AS pages , CASE boundary_value_on_right WHEN 1 THEN 'menor que' ELSE 'menor o igual' END as comparison , rv.value , CONVERT (VARCHAR(6), CONVERT (INT, SUBSTRING (au.first_page, 6, 1) + SUBSTRING (au.first_page, 5, 1))) + ':' + CONVERT (VARCHAR(20), CONVERT (INT, SUBSTRING (au.first_page, 4, 1) + SUBSTRING (au.first_page, 3, 1) + SUBSTRING (au.first_page, 2, 1) + SUBSTRING (au.first_page, 1, 1))) AS first_page FROM sys.partitions p INNER JOIN sys.indexes i ON p.object_id = i.object_id AND p.index_id = i.index_id INNER JOIN sys.objects o
ON p.object_id = o.object_id INNER JOIN sys.system_internals_allocation_units au ON p.partition_id = au.container_id INNER JOIN sys.partition_schemes ps ON ps.data_space_id = i.data_space_id INNER JOIN sys.partition_functions f ON f.function_id = ps.function_id INNER JOIN sys.destination_data_spaces dds ON dds.partition_scheme_id = ps.data_space_id AND dds.destination_id = p.partition_number INNER JOIN sys.filegroups GFJJFILEGROUP ON dds.data_space_id = GFJJFILEGROUP.data_space_id LEFT OUTER JOIN sys.partition_range_values rv ON f.function_id = rv.function_id AND p.partition_number = rv.boundary_id WHERE i.index_id < 2 AND o.object_id = OBJECT_ID(@TableName);
GO

-- SPLIT 
-- Para poder trabajar con esto vamos a crear un nuevo Filegroup y añadirlo al Schema

ALTER DATABASE GFJJ_archivo ADD FILEGROUP GFJJ_particiones;

ALTER DATABASE GFJJ_archivo   
ADD FILE   
(  
    NAME = GFJJ_particiones,  
    FILENAME = 'c:\Data\GFJJ_particiones.ndf',  
    SIZE = 5MB,  
    MAXSIZE = 100MB,  
    FILEGROWTH = 5MB  
)  
TO FILEGROUP GFJJ_particiones;

ALTER PARTITION SCHEME PART_SCHEMA_gfjj  
NEXT USED GFJJ_particiones;

ALTER PARTITION FUNCTION PART_FUNCTION_gfjj() 
	SPLIT RANGE ('2022-01-01'); 
GO

INSERT INTO GFJJ_Registro (Nombre, Almacenaje, fecha_documento) 
	Values ('BOD Nº 1','Secretaria','2022-01-02')
GO

SELECT *,$Partition.PART_FUNCTION_gfjj(fecha_documento) as PARTITION
FROM GFJJ_Registro
GO

DECLARE @TableName NVARCHAR(200) = N'GFJJ_Registro' 
SELECT SCHEMA_NAME(o.schema_id) + '.' + OBJECT_NAME(i.object_id) AS [object] , p.partition_number AS [p#] , GFJJFILEGROUP.name AS [filegroup] , p.rows , au.total_pages AS pages , CASE boundary_value_on_right WHEN 1 THEN 'menor que' ELSE 'menor o igual' END as comparison , rv.value , CONVERT (VARCHAR(6), CONVERT (INT, SUBSTRING (au.first_page, 6, 1) + SUBSTRING (au.first_page, 5, 1))) + ':' + CONVERT (VARCHAR(20), CONVERT (INT, SUBSTRING (au.first_page, 4, 1) + SUBSTRING (au.first_page, 3, 1) + SUBSTRING (au.first_page, 2, 1) + SUBSTRING (au.first_page, 1, 1))) AS first_page FROM sys.partitions p INNER JOIN sys.indexes i ON p.object_id = i.object_id AND p.index_id = i.index_id INNER JOIN sys.objects o
ON p.object_id = o.object_id INNER JOIN sys.system_internals_allocation_units au ON p.partition_id = au.container_id INNER JOIN sys.partition_schemes ps ON ps.data_space_id = i.data_space_id INNER JOIN sys.partition_functions f ON f.function_id = ps.function_id INNER JOIN sys.destination_data_spaces dds ON dds.partition_scheme_id = ps.data_space_id AND dds.destination_id = p.partition_number INNER JOIN sys.filegroups GFJJFILEGROUP ON dds.data_space_id = GFJJFILEGROUP.data_space_id LEFT OUTER JOIN sys.partition_range_values rv ON f.function_id = rv.function_id AND p.partition_number = rv.boundary_id WHERE i.index_id < 2 AND o.object_id = OBJECT_ID(@TableName);
GO

-- SWITCH
CREATE TABLE GFJJ_Switch (
	ID INT NOT NULL IDENTITY,
	Nombre varchar(40) NULL,
	Almacenaje varchar(20) NULL,
	fecha_documento datetime) 
	ON GFJJFILEGROUP_Historico
GO

ALTER TABLE GFJJ_Registro 
	SWITCH Partition 1 to GFJJ_Switch
GO

SELECT *,$Partition.PART_FUNCTION_gfjj(fecha_documento) as PARTITION
FROM GFJJ_Registro
GO

SELECT *,$Partition.PART_FUNCTION_gfjj(fecha_documento) as PARTITION
FROM GFJJ_Switch
GO

DECLARE @TableName NVARCHAR(200) = N'GFJJ_Registro' 
SELECT SCHEMA_NAME(o.schema_id) + '.' + OBJECT_NAME(i.object_id) AS [object] , p.partition_number AS [p#] , GFJJFILEGROUP.name AS [filegroup] , p.rows , au.total_pages AS pages , CASE boundary_value_on_right WHEN 1 THEN 'menor que' ELSE 'menor o igual' END as comparison , rv.value , CONVERT (VARCHAR(6), CONVERT (INT, SUBSTRING (au.first_page, 6, 1) + SUBSTRING (au.first_page, 5, 1))) + ':' + CONVERT (VARCHAR(20), CONVERT (INT, SUBSTRING (au.first_page, 4, 1) + SUBSTRING (au.first_page, 3, 1) + SUBSTRING (au.first_page, 2, 1) + SUBSTRING (au.first_page, 1, 1))) AS first_page FROM sys.partitions p INNER JOIN sys.indexes i ON p.object_id = i.object_id AND p.index_id = i.index_id INNER JOIN sys.objects o
ON p.object_id = o.object_id INNER JOIN sys.system_internals_allocation_units au ON p.partition_id = au.container_id INNER JOIN sys.partition_schemes ps ON ps.data_space_id = i.data_space_id INNER JOIN sys.partition_functions f ON f.function_id = ps.function_id INNER JOIN sys.destination_data_spaces dds ON dds.partition_scheme_id = ps.data_space_id AND dds.destination_id = p.partition_number INNER JOIN sys.filegroups GFJJFILEGROUP ON dds.data_space_id = GFJJFILEGROUP.data_space_id LEFT OUTER JOIN sys.partition_range_values rv ON f.function_id = rv.function_id AND p.partition_number = rv.boundary_id WHERE i.index_id < 2 AND o.object_id = OBJECT_ID(@TableName);
GO

-- TRUNCATE

TRUNCATE TABLE GFJJ_Registro 
	WITH (PARTITIONS (2));
GO

SELECT *,$Partition.PART_FUNCTION_gfjj(fecha_documento) as PARTITION
FROM GFJJ_Registro
GO

---------------------------------------------------------------------------------------------------------------------------------------
-- PROCEDIMIENTO ALMACENADO

USE gfjj
GO

CREATE TABLE dbo.COSTE
(Empleo VARCHAR (9) PRIMARY KEY,
 San_dia INT NOT NULL,
);

INSERT INTO dbo.COSTE (Empleo, San_dia) VALUES
('Soldado',15),
('Cabo',18),
('Sargento',38)
GO

ALTER TABLE dbo.MILITAR ADD Empleo VARCHAR (9) NULL;
UPDATE dbo.MILITAR SET Empleo = 'Soldado' WHERE DNI = '32697849Z';
UPDATE dbo.MILITAR SET Empleo = 'Cabo' WHERE DNI = '32374058Y';
UPDATE dbo.MILITAR SET Empleo = 'Sargento' WHERE DNI = '32409123L';

CREATE TABLE dbo.SANCION
(Cod_San INT PRIMARY KEY IDENTITY,
 DNI VARCHAR (9) NOT NULL,
 FOREIGN KEY (DNI) REFERENCES dbo.MILITAR(DNI),
 San_Ini DATE,
 San_Fin DATE,
 San_pago INT
);

DROP PROCEDURE IF EXISTS Nueva_Sancion;
CREATE OR ALTER PROCEDURE dbo.Nueva_Sancion
	@dni AS VARCHAR(9),
	@fecha AS DATE,
	@dias AS INT
AS
BEGIN
DECLARE @fecha2 AS DATE;
DECLARE @san AS INT;
DECLARE @empleo AS VARCHAR(9);
DECLARE @pago AS INT;
DECLARE @nombre AS VARCHAR(30);
SET @empleo = (SELECT Empleo FROM MILITAR WHERE DNI = @dni);  
SELECT @fecha2 = DATEADD (day, @dias,@fecha);
SELECT @pago = (@dias * (SELECT San_dia FROM COSTE WHERE Empleo = @empleo));
SELECT @nombre = (SELECT NOMBRE FROM MILITAR WHERE DNI = @dni);
INSERT INTO dbo.SANCION (DNI, San_Ini, San_Fin, San_pago) VALUES (@dni, @fecha, @fecha2,@pago);
END;

EXEC dbo.Nueva_Sancion '32374058Y','20210320', 12;

SELECT * FROM dbo.SANCION

EXEC dbo.Nueva_Sancion '32697849Z','20080404', 8;

SELECT * FROM dbo.SANCION


------------------------------------------------------------------------------------------------------------------------------------
-- Tablas Temporales
USE gfjj_archivo
GO

IF OBJECT_ID('dbo.DAOS', 'U') IS NOT NULL
  DROP TABLE dbo.DAOS; 
CREATE TABLE DAOS( 
DNI VARCHAR(9) PRIMARY KEY NOT NULL,
Nombre VARCHAR (100) NOT NULL,
Apellidos VARCHAR (100) NOT NULL,
DAO INT NULL);

IF OBJECT_ID('tempdb.dbo.Personal', 'U') IS NOT NULL
  DROP TABLE tempdb.dbo.Personal;
CREATE TABLE Personal( 
ID INT PRIMARY KEY NOT NULL IDENTITY,
DNI VARCHAR(9),
Guardias INT,
Inicio datetime2 GENERATED ALWAYS AS ROW START NOT NULL,
Fin datetime2 GENERATED ALWAYS AS ROW END NOT NULL,
PERIOD FOR SYSTEM_TIME (Inicio,Fin)
)
WITH (SYSTEM_VERSIONING = ON(HISTORY_TABLE = dbo.PersonalHistorico)); 

DROP PROCEDURE Alta_Des;
CREATE PROCEDURE Alta_Des
	@dni AS VARCHAR(9),
	@nombre AS VARCHAR(100),
	@apellidos AS VARCHAR(100)
AS
BEGIN
INSERT INTO dbo.DAOS (DNI, Nombre, Apellidos) VALUES (@dni, @nombre,@apellidos);
INSERT INTO dbo.Personal (DNI) VALUES (@dni);
PRINT @dni + ' ha realizado su primera guardia'
END

DROP PROCEDURE Descansos;
CREATE PROCEDURE Descansos
	@dni AS VARCHAR(9)
AS
DECLARE @cuenta AS INT;
DECLARE @dias AS INT;
BEGIN
UPDATE dbo.Personal SET Guardias = Guardias+1 WHERE DNI = @dni;
SET @cuenta = (SELECT COUNT(DNI) FROM dbo.PersonalHistorico WHERE DNI = @dni);
SET @dias = @cuenta/7;
UPDATE dbo.DAOS SET DAO = @dias WHERE DNI = @dni;
PRINT @dni + ' dispone de ' + CAST(@dias AS VARCHAR) + ' días adicionales.'
END

EXEC Alta_Des '32697849Z','Juan Jose','Gomez Fernandez';

SELECT * FROM dbo.DAOS;
SELECT * FROM dbo.Personal;

EXEC Descansos '32697849Z';
EXEC Descansos '32697849Z';
EXEC Descansos '32697849Z';
EXEC Descansos '32697849Z';
EXEC Descansos '32697849Z';
EXEC Descansos '32697849Z';
EXEC Descansos '32697849Z';

SELECT * FROM dbo.DAOS;
SELECT * FROM dbo.Personal;
SELECT * FROM dbo.PersonalHistorico;




