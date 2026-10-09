<#
  generar_manual.ps1 - Genera kit\MANUAL_USUARIO.html a partir de
  manual\manual_cuerpo.html (el mismo contenido, como pagina HTML completa
  con charset UTF-8 para abrirla sin conexion desde el pendrive).
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
$out = Join-Path $Repo 'kit\MANUAL_USUARIO.html'
[IO.File]::WriteAllText($out, $doc, (New-Object System.Text.UTF8Encoding($true)))
Write-Host "Generado $out"
