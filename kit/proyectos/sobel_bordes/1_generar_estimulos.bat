@echo off
rem Paso 1: genera estimulos.txt y esperados.txt a partir de una imagen.
rem Doble clic: usa imagen_prueba.png. Para usar otra imagen PNG,
rem arrastrela sobre este fichero.
cd /d "%~dp0"
set "PY=%~dp0..\..\python\python.exe"
if not exist "%PY%" set "PY=python"
"%PY%" generar_estimulos.py %1
echo.
echo Siguiente paso: abra tb_sobel.vhd en Notepad++ y pulse F6.
pause
