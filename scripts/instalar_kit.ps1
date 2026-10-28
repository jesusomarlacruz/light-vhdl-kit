<#
  instalar_kit.ps1 - Construye o actualiza el kit VHDL portable en un pendrive o carpeta.

  Uso:   scripts\instalar_kit.bat E:               instalacion nueva en E:\VHDL
         scripts\instalar_kit.bat E: actualizar    actualiza un E:\VHDL ya existente
         (o) powershell -ExecutionPolicy Bypass -File scripts\instalar_kit.ps1 -Destino E: [-Actualizar]

  Instalacion nueva: crea <Destino>\VHDL con
    - las herramientas oficiales (Notepad++ portable, NppExec, GHDL, GTKWave,
      Python embeddable), descargadas en descargas\ si no estan ya y
      verificadas con SHA-256;
    - los ficheros propios del kit (carpeta kit\ de este repositorio).
  Si <Destino>\VHDL ya existe, se detiene sin tocar nada.

  Actualizacion (-Actualizar): sobre un <Destino>\VHDL existente
    - instala las herramientas que falten (las que ya estan no se tocan);
    - sustituye los ficheros propios del kit (sim.bat, comprobar.bat,
      LEEME.txt, MANUAL_USUARIO.html, configuracion de Notepad++/NppExec);
    - en proyectos\ solo anade ficheros nuevos: NUNCA sobrescribe ni borra
      los que ya existen (los proyectos de cada uno quedan intactos).

  Las versiones estan fijadas a las probadas. Para actualizar una herramienta,
  cambie Url y Sha256 y vuelva a probar F6/F9: NppExec numera los elementos de
  su menu, y los atajos de npp\shortcuts.xml dependen de esa numeracion.
#>
param(
  [Parameter(Mandatory = $true)][string]$Destino,
  [switch]$Actualizar
)
$ErrorActionPreference = 'Stop'
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
Add-Type -AssemblyName System.IO.Compression.FileSystem

$Repo      = Split-Path $PSScriptRoot -Parent
$Kit       = Join-Path $Repo 'kit'
$Descargas = Join-Path $Repo 'descargas'

$Herramientas = @(
  @{ Nombre = 'Notepad++ 8.9.8.1 portable x64'
     Url    = 'https://github.com/notepad-plus-plus/notepad-plus-plus/releases/download/v8.9.8.1/npp.8.9.8.1.portable.x64.zip'
     Sha256 = 'beddf5548e75c97930d1575ba1c7d113e6e2b33d0a200310e734ca08e225f414'
     Carpeta = 'npp'; Raiz = '' },
  @{ Nombre = 'NppExec 0.8.12.1 x64'
     Url    = 'https://github.com/d0vgan/nppexec/releases/download/NppExec_v08121/NppExec_08121_dll_x64.zip'
     Sha256 = 'a87625e651e37f1fc6bee646cf8f827eaa784ec5a8a1250da4f107998ad10d12'
     Carpeta = 'npp\plugins\NppExec'; Raiz = '' },
  @{ Nombre = 'GHDL 6.0.0 mcode UCRT64'
     Url    = 'https://github.com/ghdl/ghdl/releases/download/v6.0.0/ghdl-mcode-6.0.0-ucrt64.zip'
     Sha256 = '76e160ceec35834c73ada6e4e484416d13aed4b64cbc7c74c5cca53a7ef60e41'
     Carpeta = 'ghdl'; Raiz = '' },
  @{ Nombre = 'GTKWave 3.3.100 win64'
     Url    = 'https://downloads.sourceforge.net/project/gtkwave/gtkwave-3.3.100-bin-win64/gtkwave-3.3.100-bin-win64.zip'
     Sha256 = 'cace98e9c1e5bb6ab74ac2c4c1a2913617b6db7071418d052d2cf999a1acf39d'
     Carpeta = 'gtkwave'; Raiz = 'gtkwave64' },
  @{ Nombre = 'Python 3.15.2 embeddable x64'
     Url    = 'https://www.python.org/ftp/python/3.15.2/python-3.15.2-embed-amd64.zip'
     Sha256 = 'd012f3aa29cf07436dae8aea1fec0fd195c2612a0b059b1f915ae0afb9ad1f62'
     Carpeta = 'python'; Raiz = '' }
)
# Ficheros que debe tener un kit completo
$Imprescindibles = 'npp\notepad++.exe', 'npp\doLocalConf.xml', 'npp\shortcuts.xml', 'npp\plugins\NppExec\NppExec.dll',
                   'ghdl\bin\ghdl.exe', 'gtkwave\bin\gtkwave.exe', 'python\python.exe',
                   'sim.bat', 'comprobar.bat', 'MANUAL_USUARIO.html'

# --- Destino ----------------------------------------------------------------
$Destino = $Destino.Trim().TrimEnd('\')
if ($Destino -match '^[A-Za-z]:$') { $Destino += '\' }
if (-not (Test-Path -LiteralPath $Destino)) {
  # Una unidad que no existe es un error; una carpeta nueva se crea si su carpeta padre existe
  $padre = Split-Path $Destino -Parent
  if ($Destino -match '^[A-Za-z]:\\$' -or -not $padre -or -not (Test-Path -LiteralPath $padre)) { throw "No existe el destino '$Destino'." }
  New-Item -ItemType Directory $Destino | Out-Null
}
$Final = Join-Path $Destino 'VHDL'
$Existe = Test-Path -LiteralPath $Final
if ($Existe -and -not $Actualizar) {
  throw "Ya existe '$Final'. No se toca nada. Para anadir lo nuevo sin borrar sus proyectos: instalar_kit.bat $($Destino.TrimEnd('\')) actualizar"
}
$Modo = if ($Existe) { 'actualizar' } else { 'nuevo' }

# Herramientas a instalar: todas en un kit nuevo; al actualizar, solo las que falten
$Nuevas = @($Herramientas | Where-Object { $Modo -eq 'nuevo' -or -not (Test-Path -LiteralPath (Join-Path $Final $_.Carpeta)) })
if ($Modo -eq 'actualizar') {
  Write-Host "Actualizando $Final"
  Write-Host ("  Herramientas que faltan: " + $(if ($Nuevas) { ($Nuevas | ForEach-Object { $_.Nombre }) -join ', ' } else { 'ninguna' }))
}

# --- Descargas verificadas ----------------------------------------------------
New-Item -ItemType Directory -Force $Descargas | Out-Null
foreach ($h in $Nuevas) {
  $zip = Join-Path $Descargas (Split-Path $h.Url -Leaf)
  if (-not (Test-Path -LiteralPath $zip)) {
    Write-Host "Descargando $($h.Nombre)..."
    & curl.exe -sSL --fail --retry 3 --max-time 600 -o $zip $h.Url
    if ($LASTEXITCODE -ne 0) { throw "No se pudo descargar $($h.Url)" }
  }
  $sha = (Get-FileHash -Algorithm SHA256 -LiteralPath $zip).Hash.ToLower()
  if ($sha -ne $h.Sha256) { throw "SHA-256 incorrecto en $zip`n  esperado $($h.Sha256)`n  obtenido $sha" }
  Write-Host "  [OK] $($h.Nombre)  sha256 verificado"
  $h.Zip = $zip
}

# --- Montaje en una carpeta temporal de ruta corta (GHDL no admite rutas largas)
$Temp = Join-Path $env:TEMP ('kitvhdl_' + [Guid]::NewGuid().ToString('N').Substring(0, 8))
$Stage = Join-Path $Temp 'VHDL'
try {
  New-Item -ItemType Directory -Force $Stage | Out-Null
  foreach ($h in $Nuevas) {
    $ext = Join-Path $Temp ('x_' + [IO.Path]::GetFileNameWithoutExtension($h.Zip))
    [IO.Compression.ZipFile]::ExtractToDirectory($h.Zip, $ext)
    $origen = if ($h.Raiz) { Join-Path $ext $h.Raiz } else { $ext }
    $dst = Join-Path $Stage $h.Carpeta
    New-Item -ItemType Directory -Force (Split-Path $dst -Parent) | Out-Null
    if (Test-Path -LiteralPath $dst) {
      robocopy $origen $dst /E /NFL /NDL /NJH /NJS /NP | Out-Null
    } else {
      Move-Item -LiteralPath $origen -Destination $dst
    }
  }
  # Ficheros propios del kit (scripts, ejemplos, manual, configuracion)
  robocopy $Kit $Stage /E /COPY:DT /DCOPY:T /A-:R /NFL /NDL /NJH /NJS /NP | Out-Null
  if ($LASTEXITCODE -ge 8) { throw "Error copiando kit\ (robocopy $LASTEXITCODE)" }
  # Si el repositorio se descargo como ZIP, Windows marca sus ficheros como "descargados de
  # Internet" y pediria confirmacion al ejecutarlos: se quita esa marca en la copia.
  Get-ChildItem -LiteralPath $Stage -Recurse -File | Unblock-File

  Write-Host "Copiando a $Final ..."
  $opc = '/COPY:DT', '/DCOPY:T', '/A-:R', '/R:1', '/W:1', '/NFL', '/NDL', '/NJH', '/NJS', '/NP'
  if ($Modo -eq 'nuevo') {
    robocopy $Stage $Final /E @opc | Out-Null
    if ($LASTEXITCODE -ge 8) { throw "Error copiando a $Final (robocopy $LASTEXITCODE)" }
  } else {
    # Todo menos proyectos\: herramientas nuevas y ficheros propios del kit (se sustituyen)
    robocopy $Stage $Final /E /XD (Join-Path $Stage 'proyectos') @opc | Out-Null
    if ($LASTEXITCODE -ge 8) { throw "Error copiando a $Final (robocopy $LASTEXITCODE)" }
    # proyectos\: solo ficheros que no existan (/XC /XN /XO = no tocar los existentes)
    $antes = @(Get-ChildItem -LiteralPath (Join-Path $Final 'proyectos') -Recurse -File -ErrorAction SilentlyContinue).Count
    robocopy (Join-Path $Stage 'proyectos') (Join-Path $Final 'proyectos') /E /XC /XN /XO @opc | Out-Null
    if ($LASTEXITCODE -ge 8) { throw "Error copiando proyectos (robocopy $LASTEXITCODE)" }
    $despues = @(Get-ChildItem -LiteralPath (Join-Path $Final 'proyectos') -Recurse -File).Count
    Write-Host "  Ficheros nuevos en proyectos: $($despues - $antes) (los existentes no se han tocado)"
  }
  # Quitar "solo lectura" de las carpetas (robocopy lo hereda si el repositorio esta en una carpeta sincronizada)
  @(Get-Item -LiteralPath $Final -Force) + @(Get-ChildItem -LiteralPath $Final -Recurse -Directory -Force) |
    Where-Object { $_.Attributes -band [IO.FileAttributes]::ReadOnly } |
    ForEach-Object { $_.Attributes = $_.Attributes -band (-bnot [IO.FileAttributes]::ReadOnly) }

  foreach ($p in $Imprescindibles) {
    if (-not (Test-Path -LiteralPath (Join-Path $Final $p))) { throw "Falta $p en $Final" }
  }
}
finally {
  if (Test-Path -LiteralPath $Temp) {
    Get-ChildItem -LiteralPath $Temp -Recurse -Force | ForEach-Object { $_.Attributes = [IO.FileAttributes]::Normal -bor ($_.Attributes -band [IO.FileAttributes]::Directory) }
    [IO.Directory]::Delete($Temp, $true)
  }
}

$f = Get-ChildItem -LiteralPath $Final -Recurse -File -Force
$verbo = if ($Modo -eq 'nuevo') { 'instalado' } else { 'actualizado' }
Write-Host ("Kit {0} en {1}: {2} ficheros, {3:N1} MB" -f $verbo, $Final, $f.Count, (($f | Measure-Object Length -Sum).Sum / 1MB))
Write-Host "Para empezar, abra $Final\abrir_editor.bat (manual: $Final\MANUAL_USUARIO.html)."
