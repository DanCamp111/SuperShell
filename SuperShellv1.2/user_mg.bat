@echo off
:mainMenu
cls
echo *****************************
echo *      Crear usuarios       *
echo *****************************
echo 1. Crear usuarios
echo 2. Ver usuarios
echo 3. Salir
echo **********************************
set /p choice="Selecciona una opcion: "

if "%choice%"=="1" goto crearUsuarios
if "%choice%"=="2" goto verUsuarios
if "%choice%"=="3" goto salir
goto mainMenu

:crearUsuarios
cls
echo Crear nuevo usuario
set /p USERNAME=Ingrese el nombre de usuario: 
set /p PASSWORD=Ingrese la contraseña: 
set /p DATABASE=Ingrese la base de datos: 
set /p ROLES=Ingrese las funciones del usuario (roles): 

rem Crear usuarios
echo use %DATABASE% > temp.js
echo db.createUser({ user: "^"%USERNAME%^", pwd: "^"%PASSWORD%^", roles: [%ROLES%] }) >> temp.js

mongo < temp.js

del temp.js

echo Usuario '%USERNAME%' creado en la base de datos '%DATABASE%' con roles '%ROLES%'.
pause
goto mainMenu

:verUsuarios

echo Ver usuarios
echo.
set /P Ingrese la base de datos:
