@echo off
rem ===========================================================================
rem  sim.bat - Compila y simula un banco de pruebas con GHDL y abre GTKWave
rem
rem  Uso:     sim.bat <entidad_testbench> [tiempo_de_parada]
rem  Ejemplo: sim.bat tb_mux 200ns
rem
rem  Se ejecuta desde la carpeta del proyecto (la que contiene los .vhd).
rem  Compila todos los .vhd de esa carpeta (VHDL-2008) en la subcarpeta work\
rem  y guarda las formas de onda en <entidad_testbench>.ghw
rem ===========================================================================
setlocal EnableExtensions

rem Carpeta del kit (la de este fichero): vale con cualquier letra de unidad
set "KIT=%~dp0"
set "GHDL=%KIT%ghdl\bin\ghdl.exe"
set "GTKWAVE=%KIT%gtkwave\bin\gtkwave.exe"
set "PATH=%KIT%ghdl\bin;%KIT%gtkwave\bin;%PATH%"
set "OPCIONES=--std=08 --workdir=work"

if "%~1"=="" goto uso
set "TB=%~n1"
set "TIEMPO=%~2"
if "%TIEMPO%"=="" set "TIEMPO=1us"

rem Aviso (no es un error): por convenio los bancos de pruebas empiezan por tb
rem (tb_mux) o terminan en _tb (reloj_pulsera_v1_tb)
set "PREFIJO=%TB:~0,2%"
set "SUFIJO=%TB:~-3%"
set "ES_TB=0"
if /i "%PREFIJO%"=="tb" set "ES_TB=1"
if /i "%SUFIJO%"=="_tb" set "ES_TB=1"
if "%ES_TB%"=="0" (
  echo AVISO: "%TB%" no parece un banco de pruebas: ni empieza por tb ni termina
  echo en _tb. Se simula como nivel superior, pero si es un modulo con puertos
  echo sus entradas quedaran sin valor, 'U'.
  echo Con F6, el fichero activo en Notepad++ debe ser el banco de pruebas.
)

if not exist "%GHDL%" (
  echo ERROR: no se encuentra GHDL en "%GHDL%"
  goto fallo
)
if not exist "*.vhd" (
  echo ERROR: no hay ficheros .vhd en la carpeta actual:
  echo   "%CD%"
  echo Ejecute sim.bat desde la carpeta del proyecto.
  goto fallo
)

rem --- Biblioteca de trabajo limpia en cada ejecucion -----------------------
if not exist "work\" md "work"
if not exist "work\" goto fallo
del /q "work\*.cf" "work\sim.log" 2>nul
if exist "%TB%.ghw" del /q "%TB%.ghw"
if exist "%TB%.ghw" (
  echo ERROR: no se puede reemplazar %TB%.ghw porque otro programa lo tiene abierto.
  echo Cierre esa ventana de GTKWave y vuelva a simular.
  goto fallo
)

echo.
echo === 1/3  Importando los ficheros .vhd ===
for %%F in (*.vhd) do (
  echo   %%F
  "%GHDL%" -i %OPCIONES% "%%F"
  if errorlevel 1 goto error_importar
)

echo.
echo === 2/3  Compilando %TB% ===
"%GHDL%" -m %OPCIONES% %TB%
if errorlevel 1 goto error_compilar

echo.
echo === 3/3  Simulando %TB% hasta %TIEMPO% ===
"%GHDL%" -r %OPCIONES% %TB% --wave=%TB%.ghw --stop-time=%TIEMPO% > "work\sim.log" 2>&1
set "CODIGO=%ERRORLEVEL%"
type "work\sim.log"

rem Contar las comprobaciones que han fallado (assert/report con severity error o failure)
set "FALLOS=0"
for /f %%N in ('%SystemRoot%\System32\findstr.exe /c:"(assertion error)" /c:"(assertion failure)" /c:"(report error)" /c:"(report failure)" "work\sim.log" ^| %SystemRoot%\System32\find.exe /c /v ""') do set "FALLOS=%%N"

if not exist "%TB%.ghw" (
  echo.
  echo ERROR: la simulacion no ha generado el fichero %TB%.ghw
  goto fallo
)

rem GTKWave se abre maximizado y ajustado al tiempo total de la simulacion.
rem "start /b" evita una segunda ventana de consola (su salida se descarta) y
rem "/max" hace que la ventana no aparezca minimizada al lanzarlo desde Notepad++.
set "ZOOM=do_initial_zoom_fit 1"
echo.
if exist "%TB%.gtkw" (
  echo Abriendo GTKWave con la vista guardada %TB%.gtkw
  start "" /b /max "%GTKWAVE%" --rcvar "%ZOOM%" "%TB%.ghw" "%TB%.gtkw" >nul 2>&1 <nul
) else (
  echo Abriendo GTKWave. Para guardar las senales elegidas: File - Write Save File
  start "" /b /max "%GTKWAVE%" --rcvar "%ZOOM%" "%TB%.ghw" >nul 2>&1 <nul
)

if not "%CODIGO%"=="0" (
  echo.
  echo ERROR: la simulacion ha terminado con un error de ejecucion, codigo %CODIGO%.
  echo Revise los mensajes de arriba.
  goto fallo
)
if not "%FALLOS%"=="0" (
  echo.
  echo ATENCION: han fallado %FALLOS% comprobaciones assert. Revise los mensajes de arriba.
  goto fallo
)
echo.
echo Simulacion terminada correctamente.
endlocal
exit /b 0

:error_importar
echo.
echo ERROR: GHDL no ha podido leer los ficheros .vhd. Revise los mensajes de arriba.
goto fallo

:error_compilar
echo.
echo ERROR de compilacion. Los mensajes de GHDL de arriba indican
echo   fichero.vhd:linea:columna: descripcion del error
echo Si GHDL no encuentra la entidad "%TB%", compruebe que el fichero del banco de
echo pruebas se llama igual que su entidad: tb_mux.vhd contiene "entity tb_mux".
goto fallo

:uso
echo Uso:     sim.bat ^<entidad_testbench^> [tiempo_de_parada]
echo Ejemplo: sim.bat tb_mux 200ns
echo Ejecutelo desde la carpeta del proyecto. Tiempo de parada por defecto: 1us
goto fallo

:fallo
echo.
if not defined SIM_NOPAUSE pause
endlocal
exit /b 1
