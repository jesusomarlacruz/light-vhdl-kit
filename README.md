# Light VHDL Kit

A lightweight, portable VHDL environment for students: **Notepad++ + GHDL + GTKWave**, ready to run on Windows from a USB stick or any folder. No installation, no administrator rights and no Vivado needed.

- **F6** in the editor: compiles and simulates the active testbench and opens the waveforms in GTKWave.
- **F9**: checks the active file (syntax, undeclared names, types, ports) without simulating.
- Example projects: a 4-to-1 multiplexer, a 4-bit counter, and a wristwatch display selector (finite state machine, two versions) with a configurable cycle counter.
- Student manual: `kit/MANUAL_USUARIO.html` (opens offline in any browser).

The kit itself (menus, messages, manual and examples) is in **Spanish**.

## Quick start

Requirements: Windows 10 or 11 (64-bit), an internet connection for the first install, about 160 MB of free space.

1. Download this repository: green **Code** button → **Download ZIP**, and extract it.
2. Double-click `scripts\instalar_kit.bat` and type where to install it: a USB drive (`E:`) or a folder (`C:\kit`). It downloads the tools once (about 55 MB), checks them and creates a `VHDL` folder there.
   From a console you can also run `scripts\instalar_kit.bat E:`.
3. Open the new `VHDL` folder and double-click `abrir_editor.bat`.
4. Open `proyectos\ejemplo_mux\tb_mux.vhd` and press **F6**. GTKWave opens with the waveforms.

The full guide is in `VHDL\MANUAL_USUARIO.html`, with a short summary in `VHDL\LEEME.txt`.

GHDL only **simulates**. Synthesis, implementation and programming an FPGA still need the vendor's tools (for example, Vivado).

## What's inside

| Path | Contents |
|---|---|
| `kit/` | Everything copied into `VHDL\` besides the tools: `sim.bat`, `comprobar.bat`, `limpiar.bat`, `abrir_editor.bat`, `LEEME.txt`, `MANUAL_USUARIO.html` and the Notepad++/NppExec configuration (F6 = Simular, F9 = Comprobar). |
| `kit/proyectos/` | `ejemplo_mux`, `ejemplo_contador` and `reloj_pulsera` (state machine in two versions, testbenches, a cycle counter with a generic, and saved GTKWave views). |
| `scripts/instalar_kit.bat` / `.ps1` | Builds the kit in a drive or folder. Refuses to touch an existing `VHDL` folder. |
| `scripts/verificar_kit.ps1` | Automated check of an installed kit (simulations, F6/F9 in the editor, cleanup). |
| `manual/manual_cuerpo.html` | Source of the manual; `scripts/generar_manual.ps1` turns it into `kit/MANUAL_USUARIO.html`. |

## Tools

This repository contains only scripts, configuration and examples. The installer downloads each tool from its official source and verifies it with SHA-256. Each tool keeps its own license.

| Tool | Version | Source |
|---|---|---|
| Notepad++ | 8.9.8.1 portable x64 | https://github.com/notepad-plus-plus/notepad-plus-plus |
| NppExec | 0.8.12.1 x64 | https://github.com/d0vgan/nppexec |
| GHDL | 6.0.0 (mcode, UCRT64) | https://github.com/ghdl/ghdl |
| GTKWave | 3.3.100 win64 (latest official Windows build) | https://sourceforge.net/projects/gtkwave |

Versions are pinned (URL + SHA-256) in `scripts/instalar_kit.ps1`. If you update NppExec, re-check the F6/F9 shortcuts: `kit/npp/shortcuts.xml` refers to NppExec menu items by position (`internalID` 25 = Simular, 26 = Comprobar, the first two entries of `[UserMenu]` in `NppExec.ini`).

## License

The scripts, configuration, examples and manual in this repository are released under the [MIT License](LICENSE). The tools downloaded by the installer (Notepad++, NppExec, GHDL, GTKWave) are not part of this repository and keep their own licenses.

## Checking an installed kit

```bat
powershell -ExecutionPolicy Bypass -File scripts\verificar_kit.ps1 -Kit E:\VHDL
```

It takes about two minutes and opens and closes Notepad++ and GTKWave windows, so don't use the kit while it runs. It ends with "Todas las comprobaciones son correctas" when everything passes.
