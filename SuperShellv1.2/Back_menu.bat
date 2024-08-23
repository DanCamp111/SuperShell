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

REM Configuración de respaldo
set PGHOST=localhost
set PGPORT=5432
set BACKUP_DIR=C:\Postgrebk
set DEFAULT_DB=mi_financiera_demo

REM Obtener la fecha y hora en formato AAAAMMDD_HHMM
for /f "tokens=2 delims==" %%i in ('"wmic os get localdatetime /value"') do set datetime=%%i
set "BACKUP_DATE=%datetime:~0,4%%datetime:~4,2%%datetime:~6,2%_%datetime:~8,2%%datetime:~10,2%"

:mainMenu
cls
echo ==============================================
echo                    MENU DE RESPALDOS 
echo ==============================================
echo 1. Respaldar base de datos
echo 2. Restaurar base de datos existente
echo 3. Crear y restaurar nueva base de datos
echo 4. Salir
echo ==============================================
set /p option=Elija una opción: 

if "%option%"=="1" goto backupDatabase
if "%option%"=="2" goto restoreDatabase
if "%option%"=="3" goto createAndRestoreDatabase
if "%option%"=="4" exit /b

goto mainMenu

:backupDatabase
cls
echo ****************************************
echo *       Respaldar Base de Datos        *
echo ****************************************
set /p PGUSER="Ingresa el nombre de usuario de PostgreSQL: "
set /p DATABASE="Ingresa el nombre de la base de datos [%DEFAULT_DB%]: "
if "%DATABASE%"=="" set DATABASE=%DEFAULT_DB%

set "BACKUP_FILE=%BACKUP_DIR%\%DATABASE%_backup_%BACKUP_DATE%.backup"

REM Crear directorio de respaldo si no existe
if not exist "%BACKUP_DIR%" (
    mkdir "%BACKUP_DIR%"
)

echo Respaldando la base de datos %DATABASE%...
pg_dump -U %PGUSER% -h %PGHOST% -p %PGPORT% -d %DATABASE% -F c -b -v -f "%BACKUP_FILE%"
if %errorlevel% neq 0 (
    echo Error al realizar el respaldo de la base de datos %DATABASE%.
    pause
    goto mainMenu
)
echo Respaldo completado: %BACKUP_FILE%
pause
goto mainMenu

:restoreDatabase
cls
echo ****************************************
echo *    Restaurar Base de Datos Existente *
echo ****************************************
set /p PGUSER="Ingresa el nombre de usuario de PostgreSQL: "

echo Listando bases de datos disponibles...
psql -U %PGUSER% -h %PGHOST% -p %PGPORT% -t -c "\l" | findstr /v /c:"template0" | findstr /v /c:"template1" | findstr /r /v "^\s*$" > temp_dbs.txt

set count=0
for /f "tokens=1 delims=|" %%a in (temp_dbs.txt) do (
    set "dbName=%%a"
    if not "!dbName!"=="" (
        for /f "tokens=*" %%b in ("!dbName!") do (
            if not "%%b"=="" (
                set /a count+=1
                echo !count!. %%b
                set "db!count!=%%b"
            )
        )
    )
)
del temp_dbs.txt

if %count%==0 (
    echo No hay bases de datos disponibles.
    pause
    goto mainMenu
)

set /p dbchoice="Selecciona la base de datos por numero: "
if not defined db%dbchoice% (
    echo Seleccion invalida.
    pause
    goto mainMenu
)
set "DATABASE=!db%dbchoice%!"

echo Archivos de respaldo disponibles:
set count=0
for %%F in ("%BACKUP_DIR%\*.backup") do (
    set /a count+=1
    echo !count!. %%~nxF
    set "file!count!=%%F"
)
if %count%==0 (
    echo No hay archivos de respaldo disponibles en %BACKUP_DIR%.
    pause
    goto mainMenu
)

set /p choice="Selecciona el archivo de respaldo por numero: "
if not defined file%choice% (
    echo Seleccion invalida.
    pause
    goto mainMenu
)
set "RESTORE_FILE=!file%choice%!"

echo Restaurando la base de datos %DATABASE% desde el respaldo %RESTORE_FILE%...
pg_restore -U %PGUSER% -h %PGHOST% -p %PGPORT% -d %DATABASE% -v "%RESTORE_FILE%"
if %errorlevel% neq 0 (
    echo Error al restaurar la base de datos %DATABASE% desde el respaldo %RESTORE_FILE%.
    pause
    goto mainMenu
)
echo Restauracion completada en la base de datos %DATABASE%.
pause
goto mainMenu

:createAndRestoreDatabase
cls
echo ****************************************
echo *   Crear y Restaurar Nueva Base de Datos   *
echo ****************************************

REM Solicitar nombre de usuario de PostgreSQL
set /p PGUSER="Ingresa el nombre de usuario de PostgreSQL: "

REM Solicitar el nombre de la nueva base de datos
set /p NEW_DATABASE="Ingresa el nombre de la nueva base de datos: "

REM Listar archivos de respaldo disponibles
echo Archivos de respaldo disponibles:
set count=0
for %%F in ("%BACKUP_DIR%\*.backup") do (
    set /a count+=1
    echo !count!. %%~nxF
    set "file!count!=%%F"
)
if %count%==0 (
    echo No hay archivos de respaldo disponibles en %BACKUP_DIR%.
    pause
    goto mainMenu
)

REM Seleccionar el archivo de respaldo por numero
set /p choice="Selecciona el archivo de respaldo por numero: "
if not defined file%choice% (
    echo Seleccion invalida.
    pause
    goto mainMenu
)
set "RESTORE_FILE=!file%choice%!"

REM Verificar si el archivo de respaldo realmente existe
if not exist "!RESTORE_FILE!" (
    echo El archivo de respaldo !RESTORE_FILE! no existe.
    pause
    goto mainMenu
)

REM Crear la nueva base de datos
echo Creando la nueva base de datos %NEW_DATABASE%...
psql -U %PGUSER% -h %PGHOST% -p %PGPORT% -c "CREATE DATABASE %NEW_DATABASE%;" || (
    echo Error al crear la base de datos %NEW_DATABASE%.
    pause
    goto mainMenu
)

REM Pausa breve para asegurar que la base de datos esté disponible
timeout /t 5

REM Restaurar el respaldo en la nueva base de datos
echo Restaurando el respaldo !RESTORE_FILE! en la nueva base de datos %NEW_DATABASE%...
pg_restore -U %PGUSER% -h %PGHOST% -p %PGPORT% -d %NEW_DATABASE% -v "!RESTORE_FILE!"
if %errorlevel% neq 0 (
    echo Error al restaurar el respaldo !RESTORE_FILE! en la nueva base de datos %NEW_DATABASE%.
    pause
    goto mainMenu
)
echo Restauracion completada en la nueva base de datos %NEW_DATABASE%.
pause
goto mainMenu
