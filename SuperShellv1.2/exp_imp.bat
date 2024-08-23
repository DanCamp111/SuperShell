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

REM Configuración de exportación
set PGHOST=localhost
set PGPORT=5432
set BASE_EXPORT_DIR=C:\bkdb

:mainMenu
cls
echo ==============================================
echo             MENU DE EXPORTACIONES 
echo ==============================================
echo 1. Exportar datos periodicamente v1.1
echo 2. Importar Datos 
echo 3. Salir
echo ==============================================
set /p option=Elija una opción: 

if "%option%"=="1" goto exportData
if "%option%"=="2" goto importData
if "%option%"=="3" exit /b

goto mainMenu

:exportData
cls
echo ****************************************
echo *     Exportar Datos Periodicamente    *
echo ****************************************
set /p PGUSER="Ingresa el nombre de usuario de PostgreSQL: "
set /p PGPASSWORD="Ingresa la contraseña de PostgreSQL: "
set PGPASSWORD=%PGPASSWORD%

echo Listando bases de datos disponibles...
psql -U %PGUSER% -h %PGHOST% -p %PGPORT% -t -c "\l" | findstr /v /c:"template0" | findstr /v /c:"template1" | findstr /r /v "^\s*$" > temp_dbs.txt

set count=0
for /f "tokens=1 delims=|" %%a in (temp_dbs.txt) do (
    set "dbName=%%a"
    set "dbName=!dbName: =!"
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

set /p dbchoice="Selecciona la base de datos por numero para exportar: "
if not defined db%dbchoice% (
    echo Seleccion invalida.
    pause
    goto exportData
)
set "DATABASE=!db%dbchoice%!"
set "DATABASE=!DATABASE: =!"

set /p interval="Ingresa el intervalo de tiempo en segundos para la exportacion: "

echo Iniciando exportacion periodica de datos desde la base de datos %DATABASE% cada %interval% segundos...
:exportLoop
set timestamp=%date:~-4%-%date:~3,2%-%date:~0,2%_%time:~0,2%%time:~3,2%%time:~6,2%
set timestamp=%timestamp: =0%

set EXPORT_DIR=%BASE_EXPORT_DIR%\%DATABASE%
if not exist "%EXPORT_DIR%" (
    mkdir "%EXPORT_DIR%"
)

pg_dump -U %PGUSER% -h %PGHOST% -p %PGPORT% %DATABASE% > "%EXPORT_DIR%\%DATABASE%_export_%timestamp%.sql"
if %errorlevel% neq 0 (
    echo Error al exportar la base de datos %DATABASE%.
    pause
    goto exportData
)
echo Exportacion completada para %DATABASE% a %EXPORT_DIR%\%DATABASE%_export_%timestamp%.sql
timeout /t %interval% /nobreak
goto exportLoop


:importData
cls
echo ****************************************
echo *         Importar Exportaciones       *
echo ****************************************

set /p PGUSER="Ingresa el nombre de usuario de PostgreSQL: "

echo Listando bases de datos disponibles...
psql -U %PGUSER% -h %PGHOST% -p %PGPORT% -t -c "\l" | findstr /v /c:"template0" | findstr /v /c:"template1" | findstr /r /v "^\s*$" > temp_dbs.txt

set count=0
for /f "tokens=1 delims=|" %%a in (temp_dbs.txt) do (
    set "dbName=%%a"
    set "dbName=!dbName: =!"
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
    exit /b
)

set /p dbchoice="Selecciona la base de datos por número para importar la última exportación: "
if not defined db%dbchoice% (
    echo Selección inválida.
    pause
    goto :mainMenu
)
set "DATABASE=!db%dbchoice%!"
set "DATABASE=!DATABASE: =!"

set /p EXPORT_DIR="Ingresa el directorio donde se encuentran las exportaciones: "

echo Listando exportaciones de la base de datos %DATABASE% por fecha:
set "options="
set count=0
for /f "delims=" %%a in ('dir /b /a-d /o-d "%EXPORT_DIR%\%DATABASE%_export_*.sql"') do (
    set /a count+=1
    set "options[!count!]=%%a"
    echo !count!. %%a
)

if %count%==0 (
    echo No se encontraron exportaciones para la base de datos %DATABASE% en el directorio especificado.
    pause
    exit /b
)

set /p selection="Selecciona el número de la exportación que deseas importar: "
if not defined options[%selection%] (
    echo Selección inválida.
    pause
    goto :mainMenu
)
set "lastExport=!options[%selection%]!"

echo Importando %lastExport% en la base de datos %DATABASE%...
psql -U %PGUSER% -h %PGHOST% -p %PGPORT% -d %DATABASE% -f "%EXPORT_DIR%\%lastExport%"
if %errorlevel% neq 0 (
    echo Error al importar la exportación en la base de datos %DATABASE%.
    pause
    exit /b
)
echo Importación completada para %DATABASE% desde %lastExport%.
pause
exit /b
