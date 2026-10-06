@echo off
setlocal
cd /d "%~dp0\..\..\Python"

if not exist ".venv\Scripts\python.exe" (
    echo ERROR: falta Python\.venv
    pause
    exit /b 1
)

echo Esta peticion se ha retirado: IBKR no admite 1 Y de barras de 1 minuto
echo en una sola llamada. Usa 03 para la prueba o 07 para la cadena IBKR.
pause
exit /b 1
