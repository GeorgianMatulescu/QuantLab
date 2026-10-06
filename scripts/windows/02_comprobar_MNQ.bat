@echo off
setlocal
cd /d "%~dp0\..\..\Python"

if not exist ".venv\Scripts\python.exe" (
    echo ERROR: falta Python\.venv
    echo Ejecuta primero 01_instalar_dependencias.bat
    pause
    exit /b 1
)

".venv\Scripts\python.exe" main.py info --symbol MNQ --sec-type CONTFUT --exchange CME --use-rth
pause
