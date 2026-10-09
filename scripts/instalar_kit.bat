@echo off
rem ===========================================================================
rem  instalar_kit.bat - Construye el kit VHDL en un pendrive o carpeta.
rem  Uso:     instalar_kit.bat E:       (o doble clic: pregunta el destino)
rem  Crea E:\VHDL. Si ya existe, no toca nada.
rem ===========================================================================
setlocal
set "DESTINO=%~1"
set "INTERACTIVO=0"
set "CODIGO=1"
if not "%DESTINO%"=="" goto instalar

set "INTERACTIVO=1"
echo Instalador del kit VHDL ligero (Notepad++ + GHDL + GTKWave)
echo Se creara una carpeta VHDL en la unidad o carpeta que indique.
echo.
set /p "DESTINO=Unidad o carpeta de destino (por ejemplo E: o C:\kit): "
if "%DESTINO%"=="" goto fin

:instalar
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0instalar_kit.ps1" -Destino "%DESTINO%"
set "CODIGO=%ERRORLEVEL%"

:fin
if "%INTERACTIVO%"=="1" (
  echo.
  pause
)
exit /b %CODIGO%
