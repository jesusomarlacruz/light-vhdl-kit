@echo off
rem ===========================================================================
rem  abrir_editor.bat - Abre el Notepad++ del USB con la carpeta de proyectos
rem  en el panel lateral (Folder as Workspace).
rem  -multiInst: abre siempre este Notepad++ aunque el PC tenga otro abierto.
rem ===========================================================================
start "" "%~dp0npp\notepad++.exe" -multiInst -openFoldersAsWorkspace "%~dp0proyectos"
