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

:menu_postgres
cls
echo ==============================================
echo                    Permisos 
echo ==============================================
echo 1. Crear Usuario y Otorgar Privilegios
echo 2. Crear Usuario de Replicacion
echo 0. Salir
echo ==============================================
set /p choice=Selecciona una opción: 

if %choice%==1 goto crear_usuario
if %choice%==2 goto crear_usuario_replicacion
if %choice%==0 exit /b

goto menu_postgres

:crear_usuario
cls
echo ****************************************
echo *     CREAR USUARIO Y OTORGAR PRIVILEGIOS      *
echo ****************************************
set /p PGUSER="Ingresa el nombre de usuario de PostgreSQL (admin): "
set /p PGPASSWORD="Ingresa la contraseña del usuario PostgreSQL: "

set /p NEWUSER="Ingresa el nombre del nuevo usuario: "
set /p NEWPASSWORD="Ingresa la contraseña para el nuevo usuario: "
set /p DBNAME="Ingresa el nombre de la base de datos para otorgar privilegios: "

echo Selecciona el paquete de privilegios:
echo 1. Admin (Permisos completos)
echo 2. Solo Visualizar (Permisos de solo lectura)
echo 3. Lectura y Escritura (Permisos de lectura y escritura)
set /p privilegechoice="Ingresa el número del paquete de privilegios: "

if %privilegechoice%==1 (
    set "PRIVILEGES=GRANT ALL PRIVILEGES ON DATABASE %DBNAME% TO %NEWUSER%;"
) else if %privilegechoice%==2 (
    set "PRIVILEGES=GRANT CONNECT ON DATABASE %DBNAME% TO %NEWUSER%; GRANT USAGE ON SCHEMA public TO %NEWUSER%; GRANT SELECT ON ALL TABLES IN SCHEMA public TO %NEWUSER%; ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT SELECT ON TABLES TO %NEWUSER%;"
) else if %privilegechoice%==3 (
    set "PRIVILEGES=GRANT CONNECT ON DATABASE %DBNAME% TO %NEWUSER%; GRANT USAGE ON SCHEMA public TO %NEWUSER%; GRANT SELECT, INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA public TO %NEWUSER%; ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT SELECT, INSERT, UPDATE, DELETE ON TABLES TO %NEWUSER%;"
) else (
    echo Seleccion invalida.
    pause
    goto menu_postgres
)

echo Creando el usuario %NEWUSER%...
psql -U %PGUSER% -h %PGHOST% -p %PGPORT% -c "CREATE USER %NEWUSER% WITH PASSWORD '%NEWPASSWORD%';" || (
    echo Error al crear el usuario %NEWUSER%.
    pause
    goto menu_postgres
)

echo Otorgando privilegios al usuario %NEWUSER% en la base de datos %DBNAME%...
psql -U %PGUSER% -h %PGHOST% -p %PGPORT% -d %DBNAME% -c "%PRIVILEGES%" || (
    echo Error al otorgar privilegios al usuario %NEWUSER% en la base de datos %DBNAME%.
    pause
    goto menu_postgres
)

echo Usuario %NEWUSER% creado y privilegios otorgados en la base de datos %DBNAME%.
pause
goto menu_postgres

:crear_usuario_replicacion
cls
echo ****************************************
echo *  CREAR USUARIO DE REPLICACIÓN        *
echo ****************************************
set /p PGUSER="Ingresa el nombre de usuario de PostgreSQL (admin): "
set /p PGPASSWORD="Ingresa la contraseña del usuario PostgreSQL: "
set REPLICATIONUSER= "rp_user"
set /p REPLICATIONPASSWORD="Ingresa la contraseña para el usuario de replicación: "

echo Creando el usuario de replicación %REPLICATIONUSER%...
psql -U %PGUSER% -h %PGHOST% -p %PGPORT% -c "CREATE ROLE %REPLICATIONUSER% REPLICATION LOGIN PASSWORD '%REPLICATIONPASSWORD%';" || (
    echo Error al crear el usuario de replicación %REPLICATIONUSER%.
    pause
    goto menu_postgres
)

echo Usuario de replicación %REPLICATIONUSER% creado correctamente.
pause
goto menu_postgres

:salir
exit
