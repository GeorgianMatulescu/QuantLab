@echo off
setlocal
cd /d "%~dp0\..\..\Python"

if not exist ".venv\Scripts\python.exe" (
    echo ERROR: falta Python\.venv
    echo Ejecuta primero 01_instalar_dependencias.bat
    pause
    exit /b 1
)

echo ============================================================
echo  QUANTLAB v0.25.32 - MNQ IBKR POR CONTRATOS TRIMESTRALES
echo ============================================================
echo.
echo Requisitos:
echo   1. TWS o IB Gateway abierto y conectado.
echo   2. API habilitada en modo solo lectura.
echo   3. Permisos de datos CME disponibles en tu cuenta IBKR.
echo.
echo No se usa Databento ni se compra historico externo.
echo Se descargaran aproximadamente dos anos, hasta ayer UTC.
echo La operacion puede tardar. Si se interrumpe, ejecuta de nuevo
echo este mismo archivo y continuara desde el ultimo bloque guardado.
echo.
set "CONFIRM="
set /p "CONFIRM=Escribe SI para iniciar o reanudar la descarga: "
if /I not "%CONFIRM%"=="SI" (
    echo Descarga cancelada.
    pause
    exit /b 0
)

".venv\Scripts\python.exe" main.py ibkr-chain-download --symbol MNQ --exchange CME --years 2 --roll-lookback-days 45 --request-pause-seconds 2.1
if errorlevel 1 goto :error

echo.
echo Descarga y rollover completados.
echo Dataset activo:
echo   data\MNQ\1_min\MNQ_CONTFUT_1_min_ALL.csv
echo Auditoria de rolls:
echo   data\MNQ\1_min\MNQ_CONTFUT_1_min_ALL.rolls.csv
pause
exit /b 0

:error
echo.
echo La descarga no se completo. No se ha sustituido el dataset activo
echo con un resultado parcial. Corrige la conexion y ejecuta de nuevo
echo este mismo archivo para reanudar.
pause
exit /b 1
