@echo off
rem ===========================================================================
rem  comprobar.bat - Comprueba un fichero VHDL sin simular (no necesita banco
rem  de pruebas): sintaxis, nombres no declarados, tipos y puertos.
rem
rem  Uso:     comprobar.bat <fichero.vhd>
rem  Ejemplo: comprobar.bat mux4.vhd
rem
rem  Se ejecuta desde la carpeta del proyecto. Los demas .vhd de la carpeta se
rem  importan para que se encuentren las entidades que use el fichero.
rem ===========================================================================
setlocal EnableExtensions

set "KIT=%~dp0"
set "GHDL=%KIT%ghdl\bin\ghdl.exe"
set "OPCIONES=--std=08 --workdir=work"

if "%~1"=="" goto uso
set "FICH=%~nx1"
if /i not "%~x1"==".vhd" if /i not "%~x1"==".vhdl" (
  echo ERROR: "%FICH%" no es un fichero VHDL.
  echo Con F9, el fichero activo en Notepad++ debe ser un .vhd
  goto fallo
)
if not exist "%FICH%" (
  echo ERROR: no se encuentra "%FICH%" en la carpeta actual:
  echo   "%CD%"
  goto fallo
)
if not exist "%GHDL%" (
  echo ERROR: no se encuentra GHDL en "%GHDL%"
  goto fallo
)

rem Biblioteca de trabajo limpia con todos los .vhd de la carpeta
if not exist "work\" md "work"
del /q "work\*.cf" 2>nul
for %%F in (*.vhd) do "%GHDL%" -i %OPCIONES% "%%F" >nul 2>&1

echo === Comprobando %FICH% ===
"%GHDL%" -s %OPCIONES% "%FICH%"
if errorlevel 1 goto error_fichero

echo.
echo Correcto: %FICH% no tiene errores de sintaxis, nombres, tipos ni puertos.
endlocal
exit /b 0

:error_fichero
echo.
echo ERROR en %FICH%. Los mensajes de arriba indican
echo   fichero.vhd:linea:columna: descripcion del error
echo Si dice que no encuentra una unidad, el fichero que la define no esta en
echo esta carpeta o tiene a su vez errores: compruebe tambien ese fichero.
goto fallo

:uso
echo Uso:     comprobar.bat ^<fichero.vhd^>
echo Ejemplo: comprobar.bat mux4.vhd
echo Ejecutelo desde la carpeta del proyecto.
goto fallo

:fallo
echo.
if not defined SIM_NOPAUSE pause
endlocal
exit /b 1
