@echo off
setlocal
cd /d "%~dp0\..\..\Python"

if not exist ".venv\Scripts\python.exe" (
    echo ERROR: falta Python\.venv
    pause
    exit /b 1
)

".venv\Scripts\python.exe" main.py download --symbol MNQ --sec-type CONTFUT --exchange CME --bar-size "1 min" --duration "1 D" --use-rth
pause
