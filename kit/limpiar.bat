@echo off
rem ===========================================================================
rem  limpiar.bat - Borra los ficheros que genera la simulacion en la carpeta
rem  actual: work\, *.ghw, *.vcd, *.fst, *.cf, *.o, *.lst y los ejecutables
rem  que GHDL crea con el nombre de la entidad. No toca .vhd ni .gtkw.
rem ===========================================================================
setlocal EnableExtensions
echo Limpiando "%CD%"

if exist "work\" (
  del /q "work\*.cf" "work\*.o" "work\*.lst" "work\sim.log" 2>nul
  rd "work" 2>nul
  if exist "work\" echo   Aviso: work\ contiene otros ficheros y no se ha borrado.
)
for %%E in (ghw vcd fst cf o lst) do if exist "*.%%E" del /q "*.%%E"

rem Ejecutables que crean los backends gcc/llvm de GHDL: entidad.exe
for %%F in (*.vhd) do if exist "%%~nF.exe" del /q "%%~nF.exe"

echo Hecho.
endlocal
