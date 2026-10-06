@echo off
setlocal
cd /d "%~dp0"

if not exist "Python\.venv\Scripts\python.exe" (
    echo No existe el entorno Python. Se iniciara la instalacion.
    call "scripts\windows\01_instalar_dependencias.bat"
    if errorlevel 1 exit /b 1
)

call "scripts\windows\07_descargar_MNQ_IBKR_CONTRATOS_2Y_ALL.bat"
exit /b %errorlevel%
