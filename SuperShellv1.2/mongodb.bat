@echo off
setlocal enabledelayedexpansion
chcp 65001 > NUL


set "defaultExportPath=C:\Mongo\export\"

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

:mainMenu
cls
echo ==============================================
echo             MENU DE MONGO DB  
echo ==============================================
echo 1. Mostrar estadísticas en tiempo real del servidor MongoDB
echo 2. Hacer backup de una base de datos
echo 3. Hacer backup de una colección
echo 4. Restaurar un backup
echo 5. Exportaciones e Importaciones
echo 6. Usuarios
echo 0. Salir
echo ==============================================
set /p option=Elija una opción: 

if "%option%"=="1" goto mongostat
if "%option%"=="2" goto backup
if "%option%"=="3" goto backup_coleccion
if "%option%"=="4" goto restore
if "%option%"=="5" goto exportaciones_importaciones
if "%option%"=="6" goto creacion_usuarios
if "%option%"=="0" exit /b

goto mainMenu

:mongostat
cls
echo ==============================================
echo     Mostrando estadísticas en tiempo real     
echo ==============================================
mongostat
pause
goto mainMenu

:backup
cls
echo ==============================================
echo        Hacer backup de una base de datos       
echo ==============================================
set /p dbname=Introduzca el nombre de la base de datos: 
set backupDir=C:\Mongo
if not exist %backupDir% (
    mkdir %backupDir%
)
echo Haciendo backup de la base de datos "%dbname%" en "%backupDir%"...
CALL mongodump --db %dbname% --out %backupDir%
echo Copia de seguridad realizada con éxito, guardada en "%backupDir%"
pause
goto mainMenu

:backup_coleccion
cls
echo ==============================================
echo         Hacer backup de una colección
echo ==============================================
set /p dbname=Nombre de la base de datos: 
set /p bkcoleccion=Nombre de la colección: 
set backupPath=C:\Mongo\bkCll
if not exist %backupPath% (
    mkdir %backupPath%
)
echo Realizando copia de seguridad de la colección "%bkcoleccion%" de la base de datos "%dbname%" en "%backupPath%"...
CALL mongodump --db %dbname% --collection "%bkcoleccion%" --out %backupPath%
echo Copia de seguridad de colección realizada con éxito, guardada en "%backupPath%"
pause
goto mainMenu

:restore
cls
echo ==============================================
echo        Restaurar una base de datos       
echo ==============================================
set /p dbname=Introduzca el nombre de la base de datos a restaurar: 
set restoreDir=C:\Mongo\%dbname%
if not exist %restoreDir% (
    echo No se encontró el directorio de respaldo para la base de datos "%dbname%".
    pause
    goto mainMenu
)
echo Restaurando la base de datos "%dbname%" desde "%restoreDir%"...
mongorestore --db %dbname% %restoreDir% --drop
pause
goto mainMenu

:exportaciones_importaciones
cls
echo ==============================================
echo            Importar y Exportar Datos
echo ==============================================
echo 1. Exportar datos de la base de datos a un archivo
echo 2. Importar datos desde un archivo a la base de datos
echo 0. Volver al menú principal
echo ==============================================
set /p choice=Elija una opción : 
if "%choice%"=="1" goto exportar_datos
if "%choice%"=="2" goto importar_datos
if "%choice%"=="0" goto mainMenu
goto exportaciones

:exportar_datos
cls
echo ==============================================
echo                     Exportar       
echo ==============================================
set /p dbName=Ingrese el nombre de la base de datos: 
set /p collectionName=Ingrese el nombre de la colección a exportar: 
CALL mongoexport --db %dbName% --collection %collectionName% --out %defaultExportPath%%collectionName%.json
echo Datos de la colección %collectionName% exportados con éxito desde la base de datos %dbName%.
pause
goto exportaciones_importaciones


:importar_datos
cls
echo ==============================================
echo                 Importaciones       
echo ==============================================
set /p dbName=Ingrese el nombre de la base de datos para la importación: 

set /p collectionName=Ingrese el nombre de la colección para la importación: 
if "%collectionName%"=="" set "collectionName=%defaultCollectionName%"

set /p dirPath=Ingrese la ruta del directorio con los archivos JSON: 

if not exist "%dirPath%" (
    echo El directorio especificado no existe.
    pause
    goto importar_datos
)

echo Archivos disponibles para importar:
set count=0
for /f "delims=" %%i in ('dir /b "%dirPath%\*.json"') do (
    set /a count+=1
    echo !count!: %%i
    set "file!count!=%%i"
)

if !count!==0 (
    echo No se encontraron archivos JSON en el directorio especificado.
    pause
    goto importar_datos
)

set /p fileChoice=Seleccione el número del archivo a importar: 
if !fileChoice! gtr !count! (
    echo Opción inválida.
    pause
    goto importar_datos
)
set "filePath=%dirPath%\!file%fileChoice%!"

CALL mongoimport --db %dbName% --collection %collectionName% --file "%filePath%"
echo Datos importados con éxito a la colección %collectionName% en la base de datos %dbName%.
pause
goto importaciones


:creacion_usuarios
cls
echo ==============================================
echo              Creación de Usuarios
echo ==============================================
echo 1. Creación de usuario
echo 2. Listar Usuarios
echo 3. Volver al menú principal
echo ==============================================
set /p choice=Elija una opción: 
if "%choice%"=="1" call node nuevo_usuario_mongo.js
if "%choice%"=="2" call node listar_usuarios.js
if "%choice%"=="3" goto mainMenu
pause
goto creacion_usuarios

