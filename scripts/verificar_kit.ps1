<#
  verificar_kit.ps1 - Comprueba un kit ya instalado, usando sus propias rutas.

  Uso:  powershell -ExecutionPolicy Bypass -File scripts\verificar_kit.ps1 -Kit D:\VHDL

  Abre y cierra ventanas de Notepad++ y GTKWave mientras se ejecuta (unos 2
  minutos). No toca ningun otro Notepad++ abierto en el PC.
  Comprueba: versiones, sim.bat en todos los bancos de pruebas, comprobar.bat,
  limpiar.bat, el editor (F6 = Simular, F9 = Comprobar, Limpiar) y que el
  editor no escribe su configuracion en %APPDATA%\Notepad++.
#>
param([string]$Kit = 'D:\VHDL')
$K = $Kit.TrimEnd('\')

if (-not ('KitVerif' -as [type])) {
Add-Type @"
using System;
using System.Collections.Generic;
using System.Runtime.InteropServices;
using System.Text;
public static class KitVerif {
  public delegate bool EnumProc(IntPtr h, IntPtr l);
  [DllImport("user32.dll")] static extern bool EnumWindows(EnumProc f, IntPtr l);
  [DllImport("user32.dll")] static extern bool EnumChildWindows(IntPtr p, EnumProc f, IntPtr l);
  [DllImport("user32.dll")] static extern uint GetWindowThreadProcessId(IntPtr h, out uint pid);
  [DllImport("user32.dll", CharSet=CharSet.Unicode)] static extern int GetClassName(IntPtr h, StringBuilder s, int n);
  [DllImport("user32.dll", CharSet=CharSet.Unicode)] static extern int GetWindowText(IntPtr h, StringBuilder s, int n);
  [DllImport("user32.dll")] public static extern IntPtr GetMenu(IntPtr h);
  [DllImport("user32.dll")] public static extern IntPtr GetSubMenu(IntPtr m, int pos);
  [DllImport("user32.dll")] public static extern int GetMenuItemCount(IntPtr m);
  [DllImport("user32.dll")] public static extern uint GetMenuItemID(IntPtr m, int pos);
  [DllImport("user32.dll", CharSet=CharSet.Unicode)] static extern int GetMenuString(IntPtr m, uint id, StringBuilder s, int n, uint flags);
  [DllImport("user32.dll")] public static extern bool PostMessage(IntPtr h, uint msg, IntPtr w, IntPtr l);
  [DllImport("user32.dll", CharSet=CharSet.Unicode)] static extern IntPtr SendMessage(IntPtr h, uint msg, IntPtr w, StringBuilder l);
  [DllImport("user32.dll")] static extern IntPtr SendMessage(IntPtr h, uint msg, IntPtr w, IntPtr l);
  static string Cls(IntPtr h) { var c = new StringBuilder(256); GetClassName(h, c, 256); return c.ToString(); }
  public static IntPtr MainWindow(uint pid, string cls) {
    IntPtr found = IntPtr.Zero;
    EnumWindows((h, l) => { uint p; GetWindowThreadProcessId(h, out p); if (p == pid && Cls(h) == cls) { found = h; return false; } return true; }, IntPtr.Zero);
    return found;
  }
  public static string MenuText(IntPtr m, int pos) { var sb = new StringBuilder(256); GetMenuString(m, (uint)pos, sb, 256, 0x400); return sb.ToString(); }
  public static IntPtr SubMenu(IntPtr m, string startsWith) {
    for (int i = 0; i < GetMenuItemCount(m); i++) if (MenuText(m, i).Replace("&", "").StartsWith(startsWith, StringComparison.OrdinalIgnoreCase)) return GetSubMenu(m, i);
    return IntPtr.Zero;
  }
  public static List<string> Items(IntPtr m) {
    var r = new List<string>();
    for (int i = 0; i < GetMenuItemCount(m); i++) r.Add(GetMenuItemID(m, i) + "\t" + MenuText(m, i));
    return r;
  }
  public static int CountChildren(IntPtr parent, string cls) {
    int n = 0; EnumChildWindows(parent, (h, l) => { if (Cls(h).StartsWith(cls, StringComparison.OrdinalIgnoreCase)) n++; return true; }, IntPtr.Zero); return n;
  }
  public static string RichEditText(IntPtr parent) {
    string text = "";
    EnumChildWindows(parent, (h, l) => {
      if (Cls(h).StartsWith("RichEdit", StringComparison.OrdinalIgnoreCase)) {
        int len = (int)SendMessage(h, 0x000E, IntPtr.Zero, IntPtr.Zero);
        var sb = new StringBuilder(len + 1); SendMessage(h, 0x000D, (IntPtr)(len + 1), sb);
        if (sb.Length > 0) { text = sb.ToString(); return false; }
      }
      return true; }, IntPtr.Zero);
    return text;
  }
}
"@
}

$env:PATH = "$env:WINDIR\System32;$env:WINDIR;$env:WINDIR\System32\Wbem"   # como un PC sin nada instalado
Remove-Item Env:\SIM_NOPAUSE -ErrorAction SilentlyContinue
$tmp = Join-Path $env:TEMP 'kitvhdl_verif'; New-Item -ItemType Directory -Force $tmp | Out-Null
$res = [ordered]@{}
function NuevosGtk([int[]]$antes) { @(Get-Process gtkwave -ErrorAction SilentlyContinue | Where-Object { $antes -notcontains $_.Id }) }
function Npp([string[]]$argumentos) {
  $p = Start-Process "$K\npp\notepad++.exe" -ArgumentList $argumentos -PassThru
  $w = [IntPtr]::Zero
  for ($i = 0; $i -lt 40 -and $w -eq [IntPtr]::Zero; $i++) { Start-Sleep -Milliseconds 500; $w = [KitVerif]::MainWindow([uint32]$p.Id, 'Notepad++') }
  Start-Sleep -Seconds 3
  @{ P = $p; W = $w }
}
function CerrarNpp($n) { [KitVerif]::PostMessage($n.W, 0x0010, [IntPtr]::Zero, [IntPtr]::Zero) | Out-Null; $n.P.WaitForExit(20000) }

Write-Host "=== Versiones ==="
$v = & "$K\ghdl\bin\ghdl.exe" --version; Write-Host "  $($v[0])"
$res['ghdl --version'] = ($LASTEXITCODE -eq 0 -and $v[0] -match '^GHDL ')
# (la salida de -V a veces se pierde al redirigirla; la de -h es fiable)
cmd /c "`"$K\gtkwave\bin\gtkwave.exe`" -h > `"$tmp\gv.txt`" 2>&1"; $gv = (Get-Content "$tmp\gv.txt") -join ' '
Write-Host "  gtkwave -h: $(if ($gv -match 'Usage: .*gtkwave') { 'responde' } else { 'sin respuesta' })"
$res['gtkwave -h (arranca)'] = ($gv -match 'Usage: .*gtkwave')

Write-Host "=== sim.bat en cada banco de pruebas ==="
foreach ($dir in Get-ChildItem "$K\proyectos" -Directory) {
  $tbs = Get-ChildItem $dir.FullName -Filter *.vhd | Where-Object { $_.BaseName -match '^tb|_tb$' }
  foreach ($tb in $tbs) {
    $antes = @(Get-Process gtkwave -ErrorAction SilentlyContinue).Id; $t0 = Get-Date
    cmd /c "cd /d `"$($dir.FullName)`" && `"$K\sim.bat`" $($tb.BaseName) > `"$tmp\sim.txt`" 2>&1"; $rc = $LASTEXITCODE
    $out = Get-Content "$tmp\sim.txt"
    $ghw = Get-Item "$($dir.FullName)\$($tb.BaseName).ghw" -ErrorAction SilentlyContinue
    $avisos = @($out | Where-Object { $_ -match 'warning|AVISO' }).Count
    Start-Sleep -Seconds 3; $g = NuevosGtk $antes; $g | Stop-Process -Force
    Write-Host "  $($dir.Name)\$($tb.BaseName): codigo $rc, ondas nuevas $([bool]($ghw -and $ghw.LastWriteTime -ge $t0)), avisos $avisos, GTKWave $($g.Count)"
    $res["sim.bat $($tb.BaseName)"] = ($rc -eq 0 -and $ghw -and $ghw.LastWriteTime -ge $t0 -and $avisos -eq 0 -and ($out -match 'Simulacion terminada correctamente') -and $g.Count -eq 1)
  }
}

Write-Host "=== comprobar.bat en cada .vhd ==="
foreach ($f in Get-ChildItem "$K\proyectos" -Recurse -Filter *.vhd) {
  cmd /c "cd /d `"$($f.DirectoryName)`" && `"$K\comprobar.bat`" $($f.Name) > `"$tmp\c.txt`" 2>&1"; $rc = $LASTEXITCODE
  $res["comprobar $($f.Name)"] = ($rc -eq 0 -and ((Get-Content "$tmp\c.txt") -match '^Correcto'))
}

Write-Host "=== limpiar.bat ==="
foreach ($dir in Get-ChildItem "$K\proyectos" -Directory) {
  cmd /c "cd /d `"$($dir.FullName)`" && `"$K\limpiar.bat`" > nul 2>&1"
  $resto = Get-ChildItem $dir.FullName -Force | Where-Object { $_.Name -notmatch '\.(vhd|gtkw|txt)$' } | ForEach-Object Name
  $res["limpiar $($dir.Name)"] = -not $resto
}

Write-Host "=== Editor (Notepad++ del kit) ==="
$foto = { if (Test-Path "$env:APPDATA\Notepad++") { Get-ChildItem "$env:APPDATA\Notepad++" -Recurse -File -Force | ForEach-Object { "{0}|{1}|{2:o}" -f $_.FullName, $_.Length, $_.LastWriteTimeUtc } } }
$app0 = @(& $foto); $t0 = Get-Date
$antesNpp = @(Get-Process notepad++ -ErrorAction SilentlyContinue).Id
cmd /c "`"$K\abrir_editor.bat`""
$p = $null; for ($i = 0; $i -lt 40 -and -not $p; $i++) { Start-Sleep -Milliseconds 500; $p = Get-Process notepad++ -ErrorAction SilentlyContinue | Where-Object { $antesNpp -notcontains $_.Id -and $_.Path -eq "$K\npp\notepad++.exe" } | Select-Object -First 1 }
Start-Sleep -Seconds 3
$n = @{ P = $p; W = [KitVerif]::MainWindow([uint32]$p.Id, 'Notepad++') }
$panel = [KitVerif]::CountChildren($n.W, 'SysTreeView32') -gt 0
$res['abrir_editor.bat (panel de proyectos)'] = ($panel -and (CerrarNpp $n))

$tbv = Get-ChildItem "$K\proyectos" -Recurse -Filter *.vhd | Where-Object { $_.BaseName -match '^tb|_tb$' } | Select-Object -First 1
$antes = @(Get-Process gtkwave -ErrorAction SilentlyContinue).Id
$n = Npp @('-multiInst', '-nosession', "`"$($tbv.FullName)`"")
$items = [KitVerif]::Items([KitVerif]::SubMenu([KitVerif]::SubMenu([KitVerif]::GetMenu($n.W), 'Plugins'), 'NppExec'))
$sim = $items | Where-Object { $_ -match "`tSimular" }; $chk = $items | Where-Object { $_ -match "`tComprobar" }; $lim = $items | Where-Object { $_ -match "`tLimpiar" }
Write-Host "  menu: $($sim -replace "`t", ' ') | $($chk -replace "`t", ' ') | $($lim -replace "`t", ' ')"
$res['F6 = Simular, F9 = Comprobar'] = ($sim -match "`tF6$" -and $chk -match "`tF9$" -and -not ($items | Where-Object { $_ -match "Execute NppExec Script.*`t" }))
function Orden($item) { [KitVerif]::PostMessage($n.W, 0x0111, [IntPtr][int](($item -split "`t")[0]), [IntPtr]::Zero) | Out-Null }
Orden $sim; Start-Sleep -Seconds 10
$con = [KitVerif]::RichEditText($n.W); $g = NuevosGtk $antes
$res['Simular desde el editor'] = ($con -match 'Simulacion terminada correctamente' -and $con -match 'Exit code 0' -and (Test-Path "$($tbv.DirectoryName)\$($tbv.BaseName).ghw") -and $g.Count -eq 1)
$g | Stop-Process -Force
Orden $chk; Start-Sleep -Seconds 6
$res['Comprobar desde el editor'] = ([KitVerif]::RichEditText($n.W) -match "Correcto: $([regex]::Escape($tbv.Name))")
Orden $lim; Start-Sleep -Seconds 5
$res['Limpiar desde el editor'] = (-not (Test-Path "$($tbv.DirectoryName)\$($tbv.BaseName).ghw") -and -not (Test-Path "$($tbv.DirectoryName)\work"))
$cerrado = CerrarNpp $n
$app1 = @(& $foto)
$cambios = @(Compare-Object $app0 $app1).Count
$escritos = @(Get-ChildItem "$K\npp" -Recurse -File | Where-Object { $_.LastWriteTime -ge $t0 }).Count
Write-Host "  ficheros escritos en npp\: $escritos | cambios en %APPDATA%\Notepad++: $cambios"
$res['configuracion solo en npp\ (nada en %APPDATA%)'] = ($cerrado -and $escritos -gt 0 -and $cambios -eq 0)

$todo = Get-ChildItem $K -Recurse -File -Force
Write-Host ("=== Tamano: {0} ficheros, {1:N1} MB ===" -f $todo.Count, (($todo | Measure-Object Length -Sum).Sum / 1MB))
Write-Host ""
$res.GetEnumerator() | ForEach-Object { Write-Host ("{0,-5} {1}" -f $(if ($_.Value) { 'OK' } else { 'FALLO' }), $_.Key) }
$fallos = @($res.Values | Where-Object { -not $_ }).Count
Write-Host ""; Write-Host $(if ($fallos) { "$fallos comprobaciones han fallado." } else { 'Todas las comprobaciones son correctas.' })
exit $fallos
