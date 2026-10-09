<#
  generar_manual.ps1 - Genera el manual a partir de manual\manual_cuerpo.html:
    kit\MANUAL_USUARIO.html   pagina completa (UTF-8) que va en el kit, para leerla sin conexion
    docs\index.html           la misma pagina, publicada en linea con GitHub Pages
    docs\MANUAL_USUARIO.pdf   version PDF, impresa con Microsoft Edge (si esta instalado)
  Ejecutar despues de editar manual\manual_cuerpo.html.
#>
$ErrorActionPreference = 'Stop'
$Repo = Split-Path $PSScriptRoot -Parent
$t = [IO.File]::ReadAllText((Join-Path $Repo 'manual\manual_cuerpo.html'), [Text.Encoding]::UTF8)
$i = $t.IndexOf('</style>')
if ($i -lt 0) { throw 'manual_cuerpo.html no contiene </style>' }
$i += '</style>'.Length
$doc = "<!doctype html>`n<html lang=`"es`">`n<head>`n<meta charset=`"utf-8`">`n" +
       "<meta name=`"viewport`" content=`"width=device-width, initial-scale=1`">`n" +
       $t.Substring(0, $i) + "`n</head>`n<body>" + $t.Substring($i) + "</body>`n</html>`n"
$doc = ($doc -replace "`r`n", "`n") -replace "`n", "`r`n"
$utf8 = New-Object System.Text.UTF8Encoding($true)

$kit = Join-Path $Repo 'kit\MANUAL_USUARIO.html'
[IO.File]::WriteAllText($kit, $doc, $utf8)
Write-Host "Generado $kit"

$docs = Join-Path $Repo 'docs'
New-Item -ItemType Directory -Force $docs | Out-Null
$web = Join-Path $docs 'index.html'
[IO.File]::WriteAllText($web, $doc, $utf8)
Write-Host "Generado $web"

$edge = @("${env:ProgramFiles(x86)}\Microsoft\Edge\Application\msedge.exe", "$env:ProgramFiles\Microsoft\Edge\Application\msedge.exe") |
        Where-Object { Test-Path $_ } | Select-Object -First 1
if (-not $edge) { Write-Host 'Microsoft Edge no encontrado: no se genera el PDF.'; return }
$pdf = Join-Path $docs 'MANUAL_USUARIO.pdf'
# Edge necesita un perfil propio para no interferir con el navegador abierto
$perfil = Join-Path $env:TEMP ('edge_manual_' + [Guid]::NewGuid().ToString('N').Substring(0, 8))
$url = ([Uri]$kit).AbsoluteUri
$p = Start-Process $edge -ArgumentList '--headless=new', '--disable-gpu', '--no-pdf-header-footer', "--user-data-dir=`"$perfil`"",
                                       "--print-to-pdf=`"$pdf`"", "`"$url`"" -PassThru -WindowStyle Hidden
if (-not $p.WaitForExit(60000)) { Stop-Process -Id $p.Id -Force; throw 'Edge no termino de generar el PDF' }
Start-Sleep -Seconds 1
if (Test-Path $perfil) { cmd /c "rd /s /q `"$perfil`"" }
if (-not (Test-Path $pdf)) { throw 'No se genero el PDF' }
Write-Host ("Generado {0} ({1:N0} KB)" -f $pdf, ((Get-Item $pdf).Length / 1KB))
