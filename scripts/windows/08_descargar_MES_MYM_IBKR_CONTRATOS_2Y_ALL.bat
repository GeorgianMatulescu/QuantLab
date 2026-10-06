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
echo  QUANTLAB v0.25.32 - MES + MYM IBKR, 1 MINUTO, DOS ANOS
echo ============================================================
echo.
echo Cesta congelada para la comparacion: MNQ + MES + MYM.
echo MES se solicita en CME y MYM en CBOT.
echo No se usa Databento ni se compra historico externo.
echo.
echo Requisitos:
echo   1. TWS o IB Gateway abierto y conectado.
echo   2. API habilitada en modo solo lectura.
echo   3. Permisos de datos CME y CBOT disponibles en IBKR.
echo.
echo Cada activo conserva su propia cache. Si se interrumpe, vuelve a
echo ejecutar este archivo y continuara desde el ultimo bloque guardado.
echo.
set "CONFIRM="
set /p "CONFIRM=Escribe SI para iniciar o reanudar MES y MYM: "
if /I not "%CONFIRM%"=="SI" (
    echo Descarga cancelada.
    pause
    exit /b 0
)

echo.
echo [1/2] Descargando MES...
".venv\Scripts\python.exe" main.py ibkr-chain-download --symbol MES --exchange CME --years 2 --roll-lookback-days 45 --request-pause-seconds 2.1
if errorlevel 1 goto :error_mes

echo.
echo [2/2] Descargando MYM...
".venv\Scripts\python.exe" main.py ibkr-chain-download --symbol MYM --exchange CBOT --years 2 --roll-lookback-days 45 --request-pause-seconds 2.1
if errorlevel 1 goto :error_mym

echo.
echo Descargas y rollovers completados.
echo Datasets activos:
echo   data\MES\1_min\MES_CONTFUT_1_min_ALL.csv
echo   data\MYM\1_min\MYM_CONTFUT_1_min_ALL.csv
echo.
echo Siguiente paso en MATLAB:
echo   run_three_asset_comparison
pause
exit /b 0

:error_mes
echo.
echo MES no se completo. No se ha activado un resultado parcial.
echo Corrige la conexion o permisos CME y ejecuta de nuevo para reanudar.
pause
exit /b 1

:error_mym
echo.
echo MES ya esta completo, pero MYM no se termino.
echo Corrige la conexion o permisos CBOT y ejecuta de nuevo para reanudar MYM.
pause
exit /b 1
