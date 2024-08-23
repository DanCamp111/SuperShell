@echo off
setlocal enabledelayedexpansion
chcp 65001 > NUL

:: Check for administrator privileges
net session >nul 2>&1
if %errorlevel% neq 0 (
    echo No tiene privilegios de administrador. El script se reiniciará con privilegios de administrador.
    powershell -Command "Start-Process '%0' -Verb RunAs"
    exit /b
)

REM ===========================================================
REM             Super Shell By Danno Bannano 
REM ===========================================================
REM Este programa ha sido creado para poder completar mis practicas 
REM todos los derechos reservados de su uso a Daniel Israel Campos Zuñiga
REM codigo reutilizado de VirtualBox Manage Menu - Teaching Tool

REM Configuración
set PGHOST=localhost
set PGPORT=5432

:mainMenu
cls
echo ==============================================
echo             MENU DE MONITOREO 
echo ==============================================
echo 1. Monitorear estadísticas de base de datos
echo 2. Monitorear todas las tablas
echo 3. Verificar conectividad de replicación
echo 4. Verificar estado de replicación
echo 5. Prender el servidor PostgreSQL
echo 6. Apagar el servidor PostgreSQL
echo 7. Recargar la configuración de PostgreSQL
echo 8. Salir
echo 9. Accion de Emergencia
echo ==============================================
set /p option=Elija una opción: 

if "%option%"=="1" goto monitorDatabaseStats
if "%option%"=="2" goto monitorAllTables
if "%option%"=="3" goto checkReplication
if "%option%"=="4" goto checkReplicationStatus
if "%option%"=="5" goto startServer
if "%option%"=="6" goto stopServer
if "%option%"=="7" goto reloadConfig
if "%option%"=="8" exit /b
if "%option%"=="9" goto slavetomaster

goto mainMenu

:askCredentials
cls
echo ****************************************
echo *    Ingresar Credenciales de PostgreSQL    *
echo ****************************************
set /p PGUSER="Ingresa el nombre de usuario de PostgreSQL (admin): "
set /p PGPASSWORD="Ingresa la contraseña del usuario PostgreSQL: "
set PGPASSWORD=%PGPASSWORD%
goto mainMenu

:monitorDatabaseStats
cls
echo ****************************************
echo *      MONITOREO DE ESTADÍSTICAS DE BASE DE DATOS      *
echo ****************************************

if "%PGUSER%"=="" goto askCredentials

echo Consultando pg_stat_database...
psql -U %PGUSER% -h %PGHOST% -p %PGPORT% -c "SELECT datname, numbackends, xact_commit, xact_rollback, blks_read, blks_hit, tup_returned, tup_fetched, tup_inserted, tup_updated, tup_deleted FROM pg_stat_database;" || (
    echo Error al consultar pg_stat_database.
    pause
    goto mainMenu
)

pause
goto mainMenu

:monitorAllTables
cls
echo ****************************************
echo *      MONITOREO DE TODAS LAS TABLAS   *
echo ****************************************

if "%PGUSER%"=="" goto askCredentials

echo Consultando pg_stat_all_tables...
psql -U %PGUSER% -h %PGHOST% -p %PGPORT% -c "SELECT schemaname, relname, seq_scan, idx_scan, n_tup_ins, n_tup_upd, n_tup_del FROM pg_stat_all_tables;" || (
    echo Error al consultar pg_stat_all_tables.
    pause
    goto mainMenu
)

pause
goto mainMenu

:checkReplication
cls
echo ****************************************
echo *      VERIFICAR CONECTIVIDAD DE REPLICACIÓN    *
echo ****************************************

if "%PGUSER%"=="" goto askCredentials

echo Consultando pg_stat_replication...
psql -U %PGUSER% -h %PGHOST% -p %PGPORT% -c "SELECT * FROM pg_stat_replication;" || (
    echo Error al consultar pg_stat_replication.
    pause
    goto mainMenu
)

pause
goto mainMenu

:checkReplicationStatus
cls
echo ****************************************
echo *      VERIFICAR ESTADO DE REPLICACIÓN   *
echo ****************************************

if "%PGUSER%"=="" goto askCredentials

echo Consultando estado de replicación en el maestro...
psql -U %PGUSER% -h %PGHOST% -p %PGPORT% -c "SELECT application_name, state, sync_state, sent_lsn, write_lsn, flush_lsn, replay_lsn FROM pg_stat_replication;" || (
    echo Error al consultar pg_stat_replication.
    pause
    goto mainMenu
)

echo Consultando estado de replicación en el esclavo...
psql -U %PGUSER% -h %PGHOST% -p %PGPORT% -c "SELECT * FROM pg_stat_wal_receiver;" || (
    echo Error al consultar pg_stat_wal_receiver.
    pause
    goto mainMenu
)

pause
goto mainMenu

:startServer
cls
echo ****************************************
echo *      PRENDER SERVIDOR POSTGRESQL     *
echo ****************************************
net start postgresql-x64-15 || (
    echo Error al iniciar el servidor PostgreSQL.
    pause
    goto mainMenu
)
echo Servidor PostgreSQL iniciado con éxito.
pause
goto mainMenu

:stopServer
cls
echo ****************************************
echo *      APAGAR SERVIDOR POSTGRESQL      *
echo ****************************************
net stop postgresql-x64-15 || (
    echo Error al detener el servidor PostgreSQL.
    pause
    goto mainMenu
)
echo Servidor PostgreSQL detenido con éxito.
pause
goto mainMenu

:reloadConfig
cls
echo ****************************************
echo *      RECARGAR CONFIGURACION POSTGRESQL *
echo ****************************************
pg_ctl reload -D "C:\Program Files\PostgreSQL\15\data" || (
    echo Error al recargar la configuración de PostgreSQL.
    pause
    goto mainMenu
)
echo Configuración de PostgreSQL recargada con éxito.
pause
goto mainMenu

:slavetomaster
cls
echo ==============================================
echo       Cambiar la Dirección IP de Windows
echo ==============================================
set interface=Ethernet 3
set ip=192.168.10.20

REM Calcular máscara de subred y puerta de enlace basada en la IP proporcionada
set mask=255.255.255.0
for /f "tokens=1,2,3 delims=." %%a in ("%ip%") do set gateway=%%a.%%b.%%c.1

REM Establecer la nueva IP y la configuración de red
netsh interface ip set address name="%interface%" static %ip% %mask% %gateway%
netsh interface ip set dns name="%interface%" static 8.8.8.8
netsh interface ip add dns name="%interface%" 8.8.4.4 index=2

echo Dirección IP configurada correctamente.
echo ==============================================
ipconfig
echo ==============================================

cls
echo ==============================================
echo    Actualizando archivos de configuración
echo ==============================================
echo Modificando los archivos de configuración...

REM Eliminar y copiar postgresql.conf
del "C:\Program Files\PostgreSQL\15\data\postgresql.conf"
copy "C:\SuperShellv1.2\postgresql.conf" "C:\Program Files\PostgreSQL\15\data\postgresql.conf"

REM Eliminar y copiar pg_hba.conf
del "C:\Program Files\PostgreSQL\15\data\pg_hba.conf"
copy "C:\SuperShellv1.2\pg_hba.conf" "C:\Program Files\PostgreSQL\15\data\pg_hba.conf"

if %errorlevel%==0 (
    echo Los archivos de configuración han sido actualizados exitosamente.
) else (
    echo Error al actualizar los archivos de configuración.
)

cls
echo ****************************************
echo *  CREAR USUARIO DE REPLICACIÓN        *
echo ****************************************
set PGUSER=postgres
set PGPASSWORD=Admin123.
set REPLICATIONUSER=rp_user
set REPLICATIONPASSWORD=Admin123.

echo Creando el usuario de replicación %REPLICATIONUSER%...
psql -U %PGUSER% -c "CREATE ROLE %REPLICATIONUSER% REPLICATION LOGIN PASSWORD '%REPLICATIONPASSWORD%';" || (
    echo Error al crear el usuario de replicación %REPLICATIONUSER%.
    goto :EOF
)

echo Usuario de replicación %REPLICATIONUSER% creado exitosamente.

cls
echo Reiniciando el servicio PostgreSQL...
net stop postgresql-x64-15
net start postgresql-x64-15

if %errorlevel%==0 (
    echo El servicio PostgreSQL se ha reiniciado exitosamente.
) else (
    echo Error al reiniciar el servicio PostgreSQL.
)
pause
goto mainMenu