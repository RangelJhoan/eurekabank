--Ejemplo eliminar usuario: DROP USER ClienteFrecuente CASCADE;

--CREACIÓN DEL ESQUEMA
CREATE USER ClienteFrecuente IDENTIFIED BY ClienteFrecuente;

GRANT connect, dba TO ClienteFrecuente;

--CONSTRUCCIÓN DE LA ESTRUCTURA
--CONNECT ClienteFrecuente/ClienteFrecuente@ORCL;
CONNECT ClienteFrecuente/ClienteFrecuente;

CREATE TABLE D_MOVIMIENTO
(
llave_Movimiento VARCHAR(10) CONSTRAINT d_movi_llav_pk PRIMARY KEY,
CodMovimiento CHAR(8) CONSTRAINT d_movi_cod_nn NOT NULL,
Tipo_Movimiento CHAR(3) CONSTRAINT d_movi_tip_nn NOT NULL,
Importe NUMBER(12,2) CONSTRAINT d_movi_imp_nn NOT NULL
);

CREATE TABLE D_CLIENTE
(
llave_cliente VARCHAR(10) CONSTRAINT d_clie_llav_pk PRIMARY KEY,
CodCliente CHAR(5) CONSTRAINT d_clie_cod_nn NOT NULL,
Identificacion CHAR(8) CONSTRAINT d_clie_ide_nn NOT NULL,
Cod_Municipio NUMBER(6) CONSTRAINT d_clie_codmun_nn NOT NULL,
Municipio VARCHAR2(255) CONSTRAINT d_clie_mun_nn NOT NULL,
Departamento VARCHAR2(255) CONSTRAINT d_clie_dep_nn NOT NULL
);

CREATE TABLE D_TIEMPO
(
llave_tiempo VARCHAR(10) CONSTRAINT d_tie_llav_pk PRIMARY KEY,
Dia NUMBER(2) CONSTRAINT d_tie_dia_nn NOT NULL,
NomDia VARCHAR(12) CONSTRAINT d_tie_nom_nn NOT NULL,
Mes NUMBER(2) CONSTRAINT d_tie_mes_nn NOT NULL,
Anno NUMBER(4) CONSTRAINT d_tie_anno_nn NOT NULL,
Semestre NUMBER(1) CONSTRAINT d_tie_sem_nn NOT NULL
);

CREATE TABLE D_CUENTA
(
llave_cuenta VARCHAR(10) CONSTRAINT d_cuen_llav_pk PRIMARY KEY,
Cod_cuenta CHAR(8) CONSTRAINT d_cuen_cod_nn NOT NULL,
Antiguedad NUMBER(2) CONSTRAINT d_cuen_ant_nn NOT NULL,
Saldo NUMBER(12,2) CONSTRAINT d_cuen_sal_nn NOT NULL,
Estado VARCHAR2(15) CONSTRAINT d_cuen_est_nn NOT NULL
);

CREATE TABLE D_SUCURSAL
(
llave_sucursal VARCHAR(10) CONSTRAINT d_sucu_llav_pk PRIMARY KEY,
Codigo CHAR(3) CONSTRAINT d_sucu_cod_nn NOT NULL,
Nombre VARCHAR2(50) CONSTRAINT d_sucu_nom_nn NOT NULL,
Cod_municipio NUMBER(6) CONSTRAINT d_sucu_codmuni_nn NOT NULL,
Municipio VARCHAR2(255) CONSTRAINT d_sucu_mun_nn NOT NULL,
Departamento VARCHAR2(255) CONSTRAINT d_sucu_dep_nn NOT NULL
);

--Secuencias

CREATE SEQUENCE seq_movimiento;

CREATE SEQUENCE seq_cliente;

CREATE SEQUENCE seq_tiempo;

CREATE SEQUENCE seq_cuenta;

CREATE SEQUENCE seq_sucursal;

--CREACIÓN DEL HECHO

CREATE TABLE h_ClienteFrecuente
(
llave_cuenta VARCHAR2(10) CONSTRAINT h_clifre_llavcue_nn NOT NULL
CONSTRAINT h_clifre_llavcue_fk REFERENCES d_cuenta(llave_cuenta),
llave_sucursal VARCHAR2(10) CONSTRAINT h_clifre_llavsuc_nn NOT NULL
CONSTRAINT h_clifre_llavsuc_fk REFERENCES d_sucursal(llave_sucursal),
llave_tiempo VARCHAR2(10) CONSTRAINT h_clifre_llavtie_nn NOT NULL
CONSTRAINT h_clifre_llavtie_fk REFERENCES d_tiempo(llave_tiempo),
llave_cliente VARCHAR2(10) CONSTRAINT h_clifre_llavcli_nn NOT NULL
CONSTRAINT h_clifre_llavcli_fk REFERENCES d_cliente(llave_cliente),
llave_movimiento VARCHAR2(10) CONSTRAINT h_clifre_llavmov_nn NOT NULL
CONSTRAINT h_clifre_llavmov_fk REFERENCES d_movimiento(llave_movimiento),
CantMovimientosCuentas NUMBER(5) CONSTRAINT h_clifre_cant_nn NOT NULL,
TotalCuentasCanceladas Number(5) CONSTRAINT h_clifre_totalcan_nn NOT NULL
);

--VISTAS PARA EL LLENADO DE LAS DIMENSIONES

CREATE OR REPLACE VIEW v_d_movimiento AS
SELECT DISTINCT mov.int_movinumero as CodMovimiento,
tip.chr_tipocodigo as Tipo_Movimiento,
mov.dec_moviimporte as Importe
FROM TipoMovimiento tip
JOIN Movimiento mov ON tip.chr_tipocodigo = mov.chr_tipocodigo;

CREATE OR REPLACE VIEW v_d_cliente AS
SELECT DISTINCT c.chr_cliecodigo AS CodCliente,
c.chr_cliedni AS Identificacion,
m.id_municipio AS Cod_municipio,
m.nombre AS Municipio,
d.nombre AS Departamento
FROM cliente c
JOIN municipios m ON m.id_municipio = c.id_municipio
JOIN departamentos d ON d.id_departamento = m.id_departamento
JOIN cuenta cu ON cu.chr_cliecodigo = c.chr_cliecodigo
JOIN movimiento mo ON mo.chr_cuencodigo = cu.chr_cuencodigo;

CREATE OR REPLACE VIEW v_d_tiempo AS
SELECT DISTINCT TO_CHAR(dtt_movifecha,'DD') AS Dia,
TO_CHAR(dtt_movifecha,'MM') AS Mes,
TO_CHAR(dtt_movifecha,'YYYY') AS Anno,
CASE
WHEN TO_CHAR(dtt_movifecha,'MM')<07 THEN '1'
ELSE '2'
END AS Semestre,
LENGTH(TO_CHAR(dtt_movifecha,'day')) AS NomDia
FROM movimiento;

CREATE OR REPLACE VIEW v_d_cuenta AS
SELECT DISTINCT cue.chr_cuencodigo AS Cod_cuenta,
TRUNC(MONTHS_BETWEEN(mov.dtt_movifecha,cue.dtt_cuenfechacreacion)/12) AS Antiguedad,
cue.dec_cuensaldo AS Saldo,
cue.vch_cuenestado AS Estado
FROM Cuenta cue
JOIN Movimiento mov ON cue.chr_cuencodigo = mov.chr_cuencodigo;

CREATE OR REPLACE VIEW v_d_sucursal AS
SELECT DISTINCT s.chr_sucucodigo AS Codigo,
s.vch_sucunombre AS Nombre,
m.id_municipio AS Cod_municipio,
m.nombre AS Municipio,
d.nombre AS Departamento
FROM Departamentos d
JOIN Municipios m ON d.id_departamento = m.id_departamento
JOIN Sucursal s ON m.id_municipio = s.id_municipio
JOIN Cuenta cue ON s.chr_sucucodigo = cue.chr_sucucodigo
JOIN Movimiento mov ON cue.chr_cuencodigo = mov.chr_cuencodigo;

--INSERTS PARA EL LLENADO DE LAS DIMENSIONES

INSERT INTO D_MOVIMIENTO
SELECT seq_movimiento.NEXTVAL,
CodMovimiento,
Tipo_Movimiento,
Importe
FROM system.v_d_movimiento;

INSERT INTO D_CLIENTE
SELECT seq_cliente.NEXTVAL,
CodCliente,
Identificacion,
Cod_municipio,
Municipio,
Departamento
FROM system.v_d_cliente;

INSERT INTO D_TIEMPO
SELECT seq_tiempo.NEXTVAL,
Dia,
NomDia,
Mes,
Anno,
Semestre
FROM system.v_d_tiempo;

INSERT INTO D_CUENTA
SELECT seq_cuenta.NEXTVAL,
Cod_cuenta,
Antiguedad,
Saldo,
Estado
FROM system.v_d_cuenta;

INSERT INTO D_SUCURSAL
SELECT seq_sucursal.NEXTVAL,
Codigo,
Nombre,
Cod_municipio,
Municipio,
Departamento
FROM system.v_d_sucursal;

--VISTA PARA EL LLENADO DEL HECHO

CREATE OR REPLACE VIEW v_hecho AS
SELECT DISTINCT cue.chr_cuencodigo AS Cod_cuenta,
cue.dec_cuensaldo AS SaldoCuenta,
TRUNC(MONTHS_BETWEEN(mov.dtt_movifecha,cue.dtt_cuenfechacreacion)/12) AS AntiguedadCuenta,
cue.vch_cuenestado AS EstadoCuenta,
s.chr_sucucodigo AS CodigoSucursal,
m.id_municipio AS Codmunicipio_Sucursal,
mov.int_movinumero AS CodMovimiento,
tip.chr_tipocodigo AS Tipo_Movimiento,
mov.dec_moviimporte AS Importe_Movimiento,
c.chr_cliecodigo AS CodCliente,
munici.id_municipio AS Codmunicipio_Cliente,
mov.dtt_movifecha AS Fecha
FROM Municipios m
JOIN Sucursal s ON m.id_municipio = s.id_municipio
JOIN Cuenta cue ON s.chr_sucucodigo = cue.chr_sucucodigo
JOIN Cliente c ON c.chr_cliecodigo = cue.chr_cliecodigo
JOIN Movimiento mov ON cue.chr_cuencodigo = mov.chr_cuencodigo
JOIN TipoMovimiento tip ON tip.chr_tipocodigo = mov.chr_tipocodigo
JOIN Municipios munici ON munici.id_municipio = c.id_municipio;

--FUNCIONES PARA CALCULAR LAS MEDIDAS DEL HECHO

CREATE OR REPLACE FUNCTION fun_cantcuentas
(val_fecha DATE,
val_codSuc sucursal.chr_sucucodigo%TYPE,
val_codMun municipios.id_municipio%TYPE)
RETURN NUMBER
AS
val_cantcuenta NUMBER;
BEGIN
SELECT Count(DISTINCT cue.chr_cuencodigo) INTO val_cantcuenta
FROM Cuenta cue
JOIN cliente cl ON cl.chr_cliecodigo = cue.chr_cliecodigo
JOIN sucursal s ON s.chr_sucucodigo = cue.chr_sucucodigo
JOIN movimiento m ON m.chr_cuencodigo = cue.chr_cuencodigo
WHERE m.dtt_movifecha <= val_fecha
AND s.id_municipio = val_codMun
AND s.chr_sucucodigo = val_codSuc;
RETURN val_cantcuenta;
END;
/

CREATE OR REPLACE FUNCTION fun_cuencanceladas
(val_fecha DATE,
val_codSuc sucursal.chr_sucucodigo%TYPE,
val_codMun municipios.id_municipio%TYPE)
RETURN NUMBER
AS
val_cuencanceladas NUMBER;
BEGIN
SELECT Count(DISTINCT cue.chr_cuencodigo) INTO val_cuencanceladas
FROM Cuenta cue
JOIN cliente cl ON cl.chr_cliecodigo = cue.chr_cliecodigo
JOIN sucursal s ON s.chr_sucucodigo = cue.chr_sucucodigo
JOIN movimiento m ON m.chr_cuencodigo = cue.chr_cuencodigo
WHERE UPPER(cue.vch_cuenestado) = 'CANCELADO'
AND m.dtt_movifecha <= val_fecha
AND s.chr_sucucodigo = val_codSuc
AND s.id_municipio = val_codMun;
RETURN val_cuencanceladas;
END;
/

--BLOQUE PARA EL LLENADO DEL HECHO

DECLARE

CURSOR c_hecho
IS SELECT * FROM system.v_hecho;

r_hecho h_ClienteFrecuente%ROWTYPE;


val_codCuenta D_CUENTA.COD_CUENTA%TYPE;
val_antiguedadCuenta D_CUENTA.ANTIGUEDAD%TYPE;
val_estado D_CUENTA.ESTADO%TYPE;
val_saldoCuenta D_CUENTA.SALDO%TYPE;

val_codMov D_MOVIMIENTO.CODMOVIMIENTO%TYPE;
val_codTipo D_MOVIMIENTO.TIPO_MOVIMIENTO%TYPE;
val_importe D_MOVIMIENTO.IMPORTE%TYPE;

val_codSuc D_SUCURSAL.CODIGO%TYPE;
val_codMunSuc D_SUCURSAL.COD_MUNICIPIO%TYPE;

val_codCliente D_CLIENTE.CODCLIENTE%TYPE;
val_codMunCli D_CLIENTE.COD_MUNICIPIO%TYPE;

val_fecha DATE;


r_cursor c_hecho%ROWTYPE;

BEGIN

OPEN c_hecho;

LOOP

FETCH c_hecho INTO val_codCuenta,val_saldoCuenta, val_antiguedadCuenta,val_estado,val_codSuc,val_codMunSuc, val_codMov, val_codTipo, val_importe, val_codCliente, val_codMunCli, val_fecha;

EXIT WHEN c_hecho%NOTFOUND;

SELECT llave_movimiento INTO r_hecho.llave_movimiento
FROM D_MOVIMIENTO
WHERE codmovimiento = val_codMov AND Tipo_movimiento = val_codTipo AND importe = val_importe;

SELECT llave_cliente INTO r_hecho.llave_cliente
FROM D_CLIENTE
WHERE codcliente = val_codCliente AND cod_municipio = val_codMunCli;

SELECT llave_tiempo INTO r_hecho.llave_tiempo
FROM D_TIEMPO
WHERE Dia = TO_CHAR(val_fecha,'DD')
AND Mes = TO_CHAR(val_fecha,'MM')
AND Anno = TO_CHAR(val_fecha,'YYYY');

SELECT llave_cuenta INTO r_hecho.llave_cuenta
FROM D_CUENTA
WHERE cod_cuenta = val_codCuenta AND antiguedad = val_antiguedadCuenta AND saldo = val_saldoCuenta AND estado = val_estado;

SELECT llave_sucursal INTO r_hecho.llave_sucursal
FROM D_SUCURSAL
WHERE codigo = val_codSuc AND cod_municipio = val_codMunSuc;


r_hecho.CantMovimientosCuentas:= system.fun_cantcuentas(val_fecha,val_codSuc, val_codMunSuc);

r_hecho.TotalCuentasCanceladas:= system.fun_cuencanceladas(val_fecha,val_codSuc, val_codMunSuc);

INSERT INTO h_ClienteFrecuente
VALUES r_hecho;

END LOOP;

CLOSE c_hecho;

COMMIT;

END;
/