@echo off
setlocal
cd /d "%~dp0\..\..\Python"

if not exist ".venv\Scripts\python.exe" (
    echo ERROR: falta Python\.venv
    pause
    exit /b 1
)

echo Esta peticion se ha retirado: IBKR no admite 4 Y de barras de 1 minuto
echo en una sola llamada y CONTFUT no se puede paginar hacia atras.
echo Sin comprar historico externo, usa 07 para la cadena IBKR disponible.
pause
exit /b 1
