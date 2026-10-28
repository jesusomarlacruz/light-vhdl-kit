@echo off
rem ===========================================================================
rem  instalar_kit.bat - Construye o actualiza el kit VHDL en un pendrive o carpeta.
rem  Uso:     instalar_kit.bat E:              instalacion nueva en E:\VHDL
rem           instalar_kit.bat E: actualizar   anade lo nuevo a un E:\VHDL existente
rem           (o doble clic: pregunta el destino)
rem  Al actualizar nunca se sobrescriben ni borran los ficheros de proyectos\.
rem ===========================================================================
setlocal
set "DESTINO=%~1"
set "MODO=%~2"
set "INTERACTIVO=0"
set "CODIGO=1"
if not "%DESTINO%"=="" goto instalar

set "INTERACTIVO=1"
echo Instalador del kit VHDL ligero (Notepad++ + GHDL + GTKWave + Python)
echo Se creara una carpeta VHDL en la unidad o carpeta que indique.
echo.
set /p "DESTINO=Unidad o carpeta de destino (por ejemplo E: o C:\kit): "
if "%DESTINO%"=="" goto fin
if not exist "%DESTINO%\VHDL\" goto instalar
echo.
echo Ya existe %DESTINO%\VHDL. Se puede actualizar: se anaden las herramientas y
echo los proyectos nuevos y se sustituyen los scripts y el manual del kit. Sus
echo ficheros de proyectos\ no se tocan.
set /p "RESP=Actualizar? (s/n): "
if /i not "%RESP%"=="s" goto fin
set "MODO=actualizar"

:instalar
set "ARGS="
if /i "%MODO%"=="actualizar" set "ARGS=-Actualizar"
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0instalar_kit.ps1" -Destino "%DESTINO%" %ARGS%
set "CODIGO=%ERRORLEVEL%"

:fin
if "%INTERACTIVO%"=="1" (
  echo.
  pause
)
exit /b %CODIGO%
