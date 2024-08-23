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

:menu_win
cls
echo ==============================================
echo            Configuración Maestro/Esclavo
echo ==============================================
echo 1. Configurar Maestro
echo 2. Configurar Esclavo
echo 3. Configurar VPN
echo 0. Salir
echo ==============================================
set /p choice=Selecciona una opción: 

if %choice%==1 goto config_master
if %choice%==2 goto config_slave
if %choice%==3 goto config_vpn
if %choice%==0 exit /b

goto menu_win

:config_master
cls
echo ==============================================
echo         Configuración del Maestro - Paso 1
echo ==============================================
echo Cambiar la Dirección IP de Windows...
call :cambiar_ip
call :pausa_continuar

cls
echo ==============================================
echo         Configuración del Maestro - Paso 2
echo ==============================================
echo Verificar la apertura del puerto 5432...
call :verify_ip 5432
call :pausa_continuar

cls
echo ==============================================
echo         Configuración del Maestro - Paso 2 - 5
echo ==============================================
echo Borrando otros archivos...
call :eli_stand
call :pausa_continuar

cls
echo ==============================================
echo         Configuración del Maestro - Paso 3
echo ==============================================
echo Actualizando archivos de configuración...
call :update_config_files
call :pausa_continuar

cls
echo ==============================================
echo         Configuración del Maestro - Paso 4
echo ==============================================
echo Creando usuario de replicación...
call :crear_usuario_replicacion
call :pausa_continuar

cls
echo ==============================================
echo         Configuración del Maestro - Paso 5
echo ==============================================
echo Reiniciando el servicio de PostgreSQL...
call :reiniciar_postgresql
call :pausa_continuar

cls
echo ==============================================
echo         Configuración del Maestro Completa
echo ==============================================
echo La configuración del maestro se ha completado exitosamente.
pause
goto menu_win

REM =================================== ESCLAVO ===============================================

:config_slave
cls
echo ==============================================
echo         Configuración del Esclavo - Paso 1
echo ==============================================
echo Cambiar la Dirección IP de Windows...
call :cambiar_ip
call :pausa_continuar

cls
echo ==============================================
echo         Configuración del Esclavo - Paso 2
echo ==============================================
echo Deteniendo servidor PostgreSQL...
call :detener_servidor
call :pausa_continuar

cls
echo ==============================================
echo         Configuración del Esclavo - Paso 3
echo ==============================================
echo Limpiando la carpeta datos...
call :limpiar_carpeta_datos
call :pausa_continuar

cls
echo ==============================================
echo         Configuración del Esclavo - Paso 4
echo ==============================================
echo Copiando datos del servidor principal...
call :copiar_datos_pg_basebackup
call :pausa_continuar

cls
echo ==============================================
echo         Configuración del Esclavo - Paso 5
echo ==============================================
echo Creando archivo standby...
call :crear_standby_signal
call :pausa_continuar

cls
echo ==============================================
echo         Configuración del Esclavo - Paso 6
echo ==============================================
echo Modificando el archivo pg_hba.conf en el servidor secundario...
call :update_config_files_slave
call :pausa_continuar

cls
echo ==============================================
echo         Configuración del Esclavo - Paso 7
echo ==============================================
echo Configurando la conexión con el servidor principal...
call :configurar_conexion_servidor_principal
call :pausa_continuar

cls
echo ==============================================
echo         Configuración del Esclavo Completa
echo ==============================================
echo La configuración del esclavo se ha completado exitosamente.
pause
goto menu_win

REM =================================== VPN ===============================================

:config_vpn

cls
echo ==============================================
echo         Configuración del VPN - Paso 1
echo ==============================================
echo Modificando el archivo pg_hba.conf en el servidor secundario...
call :update_config_files_vpn
call :pausa_continuar

cls
echo ==============================================
echo         Configuración del Esclavo - Paso 2
echo ==============================================
echo Configurando la conexión con el servidor principal...
call :configurar_conexion_servidor_principal
call :pausa_continuar

cls
echo ==============================================
echo         Configuración del VPN Completa
echo ==============================================
echo La configuración del esclavo se ha completado exitosamente.
pause
goto menu_win

REM =================================== FUNCIONES ===============================================

:cambiar_ip
cls
echo ==============================================
echo       Cambiar la Dirección IP de Windows
echo ==============================================
echo Adaptadores de red disponibles:
echo ==============================================
netsh interface show interface
echo ==============================================
set /p interface=Nombre del adaptador de red: 
set /p ip=Nueva dirección IP (ejemplo: 192.168.10.10): 

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
goto :EOF

:detener_servidor
cls
echo ****************************************
echo Deteniendo el servidor PostgreSQL...
echo ****************************************
net stop postgresql-x64-15
echo Servidor PostgreSQL detenido.
goto :EOF

:verify_ip
cls
echo ==============================================
echo        Verificar la apertura del puerto
echo ==============================================
set /p puerto=Numero del puerto a verificar: 
echo Verificando el puerto %puerto%...
netstat -an | find ":%puerto%"
if %errorlevel%==0 (
    echo El puerto %puerto% está abierto.
) else (
    echo El puerto %puerto% no está abierto.
)
goto :EOF

:limpiar_carpeta_datos
cls
echo ==============================================
echo    Limpiando la carpeta de datos de PostgreSQL
echo ==============================================
echo Borrando el contenido de la carpeta de datos...

REM Eliminar todos los archivos en la carpeta de datos
del /f /s /q "C:\Program Files\PostgreSQL\15\data\*.*"

REM Eliminar todas las subcarpetas en la carpeta de datos
for /d %%x in ("C:\Program Files\PostgreSQL\15\data\*") do rmdir /s /q "%%x"

echo Carpeta de datos limpiada correctamente.
echo ==============================================
goto :EOF

:update_config_files
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
goto :EOF

:update_config_files_slave
cls
echo ==============================================
echo    Actualizando archivos de configuración
echo ==============================================
echo Modificando los archivos de configuración...

REM Eliminar y copiar postgresql.conf
del "C:\Program Files\PostgreSQL\15\data\postgresql.conf"
copy "C:\SuperShellv1.2\slave_postgresql.conf" "C:\Program Files\PostgreSQL\15\data\postgresql.conf"

REM Eliminar y copiar pg_hba.conf
del "C:\Program Files\PostgreSQL\15\data\pg_hba.conf"
copy "C:\SuperShellv1.2\pg_hba.conf" "C:\Program Files\PostgreSQL\15\data\pg_hba.conf"

if %errorlevel%==0 (
    echo Los archivos de configuración han sido actualizados exitosamente.
) else (
    echo Error al actualizar los archivos de configuración.
)
goto :EOF

:update_config_files_vpn
cls
echo ==============================================
echo    Actualizando archivos de configuración
echo ==============================================
echo Modificando los archivos de configuración...

REM Eliminar y copiar pg_hba.conf
del "C:\Program Files\PostgreSQL\15\data\pg_hba.conf"
copy "C:\SuperShellv1.2\pg_hba.conf" "C:\Program Files\PostgreSQL\15\data\pg_hba.conf"

if %errorlevel%==0 (
    echo Los archivos de configuración han sido actualizados exitosamente.
) else (
    echo Error al actualizar los archivos de configuración.
)
goto :EOF

:crear_usuario_replicacion
cls
echo ****************************************
echo *  CREAR USUARIO DE REPLICACIÓN        *
echo ****************************************
set /p PGUSER="Ingresa el nombre de usuario de PostgreSQL (admin): "
set /p PGPASSWORD="Ingresa la contraseña del usuario PostgreSQL: "
set REPLICATIONUSER=rp_user
set /p REPLICATIONPASSWORD="Ingresa la contraseña para el usuario de replicación: "

echo Creando el usuario de replicación %REPLICATIONUSER%...
psql -U %PGUSER% -c "CREATE ROLE %REPLICATIONUSER% REPLICATION LOGIN PASSWORD '%REPLICATIONPASSWORD%';" || (
    echo Error al crear el usuario de replicación %REPLICATIONUSER%.
    goto :EOF
)

echo Usuario de replicación %REPLICATIONUSER% creado exitosamente.
goto :EOF

:reiniciar_postgresql
cls
echo Reiniciando el servicio PostgreSQL...
net stop postgresql-x64-15
net start postgresql-x64-15

if %errorlevel%==0 (
    echo El servicio PostgreSQL se ha reiniciado exitosamente.
) else (
    echo Error al reiniciar el servicio PostgreSQL.
)
goto :EOF

:copiar_datos_pg_basebackup
cls
echo ==============================================
echo   Utilizar pg_basebackup para copiar datos
echo ==============================================
 set /p server_ip=Ingresa la IP del servidor principal: 
 set /p replication_user=Ingresa el nombre del usuario de replicación: 
 set /p replication_password=Ingresa la contraseña del usuario de replicación: 

 Establecer la contraseña para el usuario de replicación
 set PGPASSWORD=%replication_password%

echo Realizando la copia de datos desde el servidor principal...
 pg_basebackup -h %server_ip% -D "C:\Program Files\PostgreSQL\15\data" -U %replication_user% -P -v -X stream
rem pg_basebackup -h 192.168.10.10 -D "C:\Program Files\PostgreSQL\15\data" -U rp_user -P -v -X stream

echo Copia de datos realizada correctamente.
echo ==============================================
goto :EOF

:crear_standby_signal
cls
echo ==============================================
echo          Creación del archivo standby
echo ==============================================
echo Creando el archivo standby.signal en C:\Program Files\PostgreSQL\15\data...
type NUL > "C:\Program Files\PostgreSQL\15\data\standby.signal"

if exist "C:\Program Files\PostgreSQL\15\data\standby.signal" (
    echo El archivo standby.signal ha sido creado exitosamente.
) else (
    echo Error al crear el archivo standby.signal.
)
goto :EOF

:eli_stand
cls
echo ==============================================
echo        Eliminación del archivo standby
echo ==============================================
echo Verificando la existencia del archivo standby.signal en C:\Program Files\PostgreSQL\15\data...

if exist "C:\Program Files\PostgreSQL\15\data\standby.signal" (
    del "C:\Program Files\PostgreSQL\15\data\standby.signal"
    if not exist "C:\Program Files\PostgreSQL\15\data\standby.signal" (
        echo El archivo standby.signal ha sido eliminado exitosamente.
    ) else (
        echo Error al eliminar el archivo standby.signal.
    )
) else (
    echo El archivo standby.signal no existe.
)
goto :EOF


:configurar_conexion_servidor_principal
cls
echo ==============================================
echo Configurar conexión con el servidor principal
echo ==============================================
set /p server_ip=Ingresa la IP del servidor principal: 
set /p replication_user=Ingresa el nombre del usuario de replicación: 
set /p replication_password=Ingresa la contraseña del usuario de replicación: 

echo primary_conninfo = ^'host=%server_ip% port=5432 user=%replication_user% password=%replication_password%^' > "C:\Program Files\PostgreSQL\15\data\postgresql.auto.conf"
rem echo primary_conninfo = 'host=192.168.10.10 port=5432 user=rp_user password=Admin123.' > "C:\Program Files\PostgreSQL\15\data\postgresql.auto.conf"

echo Iniciando el servidor PostgreSQL...
net start postgresql-x64-15

if %errorlevel%==0 (
    echo Recargando la configuración de PostgreSQL...
    pg_ctl reload -D "C:\Program Files\PostgreSQL\15\data"
    echo Configuración realizada correctamente.
 ) else (
     echo Error al iniciar el servidor PostgreSQL.
 )
echo ==============================================
goto :EOF

:pausa_continuar
set /p continuar=¿Deseas continuar? (S/N): 
if /i "%continuar%"=="N" exit /b
if /i "%continuar%"=="S" goto :EOF
echo Opción inválida. Por favor, ingresa S o N.
goto :pausa_continuar
