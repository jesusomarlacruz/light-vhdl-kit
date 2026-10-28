@echo off
rem Paso 4: compara resultados.txt con esperados.txt y muestra las imagenes.
cd /d "%~dp0"
set "PY=%~dp0..\..\python\python.exe"
if not exist "%PY%" set "PY=python"
"%PY%" ver_resultado.py
pause
