--CREAR EL ESQUEMA Y USUARIO
CREATE USER eureka IDENTIFIED BY eureka;

GRANT connect, dba TO eureka;

--CONSTRUCCIÓN DE LA ESTRUCTURA
--CONNECT ClienteFrecuente/ClienteFrecuente@ORCL;
CONNECT eureka/eureka;

--Tabla Departamentos

CREATE TABLE Departamentos(
	id_departamento NUMBER(2) NOT NULL,
	nombre VARCHAR2(255) NOT NULL,
	CONSTRAINT PK_DEPARTAMENTOS PRIMARY KEY (id_departamento)
);

CREATE TABLE Municipios (
	id_municipio NUMBER(6) NOT NULL,
	nombre VARCHAR2(255) NOT NULL,
	estado NUMBER(1) NOT NULL,
	id_departamento NUMBER(2) NOT NULL,
	CONSTRAINT PK_MUNICIPIOS PRIMARY KEY (id_municipio),
	CONSTRAINT FK_MUNICIPIOS_DEPARTAMENTOS FOREIGN KEY (id_departamento) REFERENCES Departamentos (id_departamento)
);

CREATE TABLE Sucursal (
	chr_sucucodigo CHAR(3) NOT NULL,
	vch_sucunombre VARCHAR(50) NOT NULL,
	vch_sucudireccion VARCHAR(50) NOT NULL,
	int_sucucontcuenta NUMBER(5, 0) NOT NULL,
	id_municipio NUMBER(6) NOT NULL,
	CONSTRAINT FK_SUCURSAL_MUNICIPIO FOREIGN KEY (id_municipio) REFERENCES Municipios (id_municipio),
	CONSTRAINT PK_SUCURSAL PRIMARY KEY (chr_sucucodigo)
);

CREATE TABLE Usuario (
	id_usuario NUMBER(4) NOT NULL,
	vch_emplusuario VARCHAR(15) NOT NULL,
	vch_emplclave VARCHAR(15) NOT NULL,
	CONSTRAINT PK_USUARIO PRIMARY KEY (id_usuario)
);

CREATE TABLE Empleado (
	chr_emplcodigo CHAR(4) NOT NULL,
	vch_emplpaterno VARCHAR(25) NOT NULL,
	vch_emplmaterno VARCHAR(25) NOT NULL,
	vch_emplnombre VARCHAR(30) NOT NULL,
	vch_empldireccion VARCHAR(50) NOT NULL,
	id_municipio NUMBER(6) NOT NULL,
	id_usuario NUMBER(4) NOT NULL,
	CONSTRAINT FK_EMPLEADO_MUNICIPIO FOREIGN KEY (id_municipio) REFERENCES Municipios (id_municipio),
	CONSTRAINT FK_EMPLEADO_USUARIO FOREIGN KEY (id_usuario) REFERENCES Usuario (id_usuario),
	CONSTRAINT PK_EMPLEADO PRIMARY KEY (chr_emplcodigo)
);

CREATE TABLE Asignado (
	chr_asigcodigo CHAR(6) NOT NULL,
	chr_sucucodigo CHAR(3) NOT NULL,
	chr_emplcodigo CHAR(4) NOT NULL,
	dtt_asigfechaalta DATE NOT NULL,
	dtt_asigfechabaja DATE NULL,
	CONSTRAINT PK_ASIGNADO PRIMARY KEY (chr_asigcodigo),
	CONSTRAINT FK_ASIGNADO_SUCURSAL FOREIGN KEY (chr_sucucodigo) REFERENCES Sucursal (chr_sucucodigo),
	CONSTRAINT FK_ASIGNADO_EMPLEADO FOREIGN KEY (chr_emplcodigo) REFERENCES Empleado (chr_emplcodigo)
);

CREATE TABLE Moneda (
	chr_monecodigo CHAR(2) NOT NULL,
	vch_monedescripcion VARCHAR(20) NOT NULL,
	CONSTRAINT PK_MONEDA PRIMARY KEY (chr_monecodigo)
);

CREATE TABLE Cliente (
	chr_cliecodigo CHAR(5) NOT NULL,
	vch_cliepaterno VARCHAR(25) NOT NULL,
	vch_cliematerno VARCHAR(25) NOT NULL,
	vch_clienombre VARCHAR(30) NOT NULL,
	chr_cliedni CHAR(8) NOT NULL,
	vch_cliedireccion VARCHAR(50) NOT NULL,
	vch_clietelefono VARCHAR(20) NULL,
	vch_clieemail VARCHAR(50) NULL,
	id_municipio NUMBER(6) NOT NULL,
	CONSTRAINT FK_CLIENTE_MUNICIPIO FOREIGN KEY (id_municipio) REFERENCES Municipios (id_municipio),
	CONSTRAINT PK_CLIENTE PRIMARY KEY (chr_cliecodigo)
);

CREATE TABLE Cuenta (
	chr_cuencodigo CHAR(8) NOT NULL,
	chr_monecodigo CHAR(2) NOT NULL,
	chr_sucucodigo CHAR(3) NOT NULL,
	chr_emplcreacuenta CHAR(4) NOT NULL,
	chr_cliecodigo CHAR(5) NOT NULL,
	dec_cuensaldo NUMBER(12, 2) NOT NULL,
	dtt_cuenfechacreacion DATE NOT NULL,
	vch_cuenestado VARCHAR(15) DEFAULT 'ACTIVO' NOT NULL CONSTRAINT CHK_CUENTA_ESTADO CHECK (
		vch_cuenestado IN ('ACTIVO', 'ANULADO', 'CANCELADO')
	),
	int_cuencontmov NUMBER(6, 0) NOT NULL,
	chr_cuenclave CHAR(6) NOT NULL,
	CONSTRAINT PK_CUENTA PRIMARY KEY (chr_cuencodigo),
	CONSTRAINT FK_CUENTA_MONEDA FOREIGN KEY (chr_monecodigo) REFERENCES Moneda (chr_monecodigo),
	CONSTRAINT FK_CUENTA_SUCURSAL FOREIGN KEY (chr_sucucodigo) REFERENCES Sucursal (chr_sucucodigo),
	CONSTRAINT FK_CUENTE_EMPLEADO FOREIGN KEY (chr_emplcreacuenta) REFERENCES Empleado (chr_emplcodigo),
	CONSTRAINT FK_CUENTE_CLIENTE FOREIGN KEY (chr_cliecodigo) REFERENCES Cliente (chr_cliecodigo)
);

CREATE TABLE TipoMovimiento (
	chr_tipocodigo CHAR(3) NOT NULL,
	vch_tipodescripcion VARCHAR(40) NOT NULL,
	vch_tipoaccion VARCHAR(10) NOT NULL CONSTRAINT CHK_TIPOMOV_ACCION CHECK (vch_tipoaccion IN ('INGRESO', 'SALIDA')),
	vch_tipoestado VARCHAR(15) DEFAULT 'ACTIVO' NOT NULL CONSTRAINT CHK_TIPOMOVIMIENTO_ESTADO CHECK (
		vch_tipoestado IN ('ACTIVO', 'ANULADO', 'CANCELADO')
	),
	CONSTRAINT PK_TIPOMOVIMIENTO PRIMARY KEY (chr_tipocodigo)
);

CREATE TABLE Movimiento (
	chr_cuencodigo CHAR(8) NOT NULL,
	int_movinumero NUMBER(6, 0) NOT NULL,
	dtt_movifecha DATE NOT NULL,
	chr_emplcodigo CHAR(4) NOT NULL,
	chr_tipocodigo CHAR(3) NOT NULL,
	dec_moviimporte NUMBER(12, 2) NOT NULL CONSTRAINT CHK_MOVIMIENTO_IMPORTE CHECK (dec_moviimporte >= 0.0),
	chr_cuenreferencia CHAR(8) NULL,
	CONSTRAINT PK_MOVIMIENTO PRIMARY KEY (chr_cuencodigo, int_movinumero),
	CONSTRAINT FK_MOVIMIENTO_CUENTA FOREIGN KEY (chr_cuencodigo) REFERENCES Cuenta (chr_cuencodigo),
	CONSTRAINT FK_MOVIMIENTO_EMPLEADO FOREIGN KEY (chr_emplcodigo) REFERENCES Empleado (chr_emplcodigo),
	CONSTRAINT FK_MOVIMIENTO_TIPOMOVIMIENTO FOREIGN KEY (chr_tipocodigo) REFERENCES TipoMovimiento (chr_tipocodigo)
);

CREATE TABLE Parametro (
	chr_paracodigo CHAR(3) NOT NULL,
	vch_paradescripcion VARCHAR(50) NOT NULL,
	vch_paravalor VARCHAR(70) NOT NULL,
	vch_paraestado VARCHAR(15) DEFAULT 'ACTIVO' NOT NULL CONSTRAINT CHK_PARAMETRO_ESTADO CHECK (
		vch_paraestado IN ('ACTIVO', 'ANULADO', 'CANCELADO')
	),
	CONSTRAINT PK_PARAMETRO PRIMARY KEY (chr_paracodigo)
);

CREATE TABLE InteresMensual (
	chr_monecodigo CHAR(2) NOT NULL,
	dec_inteimporte NUMBER(12, 2) NOT NULL,
	CONSTRAINT PK_INTERESMENSUAL PRIMARY KEY (chr_monecodigo),
	CONSTRAINT FK_INTERESMENSUAL_MONEDA FOREIGN KEY (chr_monecodigo) REFERENCES Moneda (chr_monecodigo)
);

CREATE TABLE CostoMovimiento (
	chr_monecodigo CHAR(2) NOT NULL,
	dec_costimporte NUMBER(12, 2) NOT NULL,
	CONSTRAINT PK_COSTOMOVIMIENTO PRIMARY KEY (chr_monecodigo),
	CONSTRAINT FK_COSTOMOVIMIENTO_MONEDA FOREIGN KEY (chr_monecodigo) REFERENCES Moneda (chr_monecodigo)
);

CREATE TABLE CargoMantenimiento (
	chr_monecodigo CHAR(2) NOT NULL,
	dec_cargMontoMaximo NUMBER(12, 2) NOT NULL,
	dec_cargImporte NUMBER(12, 2) NOT NULL,
	CONSTRAINT PK_CARGOMANTENIMIENTO PRIMARY KEY (chr_monecodigo),
	CONSTRAINT fk_cargomantenimiento_moneda FOREIGN KEY (chr_monecodigo) REFERENCES Moneda (chr_monecodigo)
);

CREATE TABLE Contador (
	vch_conttabla VARCHAR(30) NOT NULL,
	int_contitem NUMBER(6, 0) NOT NULL,
	int_contlongitud NUMBER(3, 0) NOT NULL,
	CONSTRAINT PK_CONTADORES PRIMARY KEY (vch_conttabla)
);