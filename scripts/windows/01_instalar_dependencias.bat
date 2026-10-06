@echo off
setlocal
cd /d "%~dp0\..\..\Python"

where py >nul 2>nul
if errorlevel 1 (
    echo No se encontro el lanzador de Python.
    echo Instala Python 3.12 de 64 bits.
    pause
    exit /b 1
)

py -3.12 -c "import sys; print(sys.version)" >nul 2>nul
if errorlevel 1 (
    echo ERROR: Python 3.12 no esta instalado.
    echo Instala con:
    echo winget install Python.Python.3.12
    pause
    exit /b 1
)

if exist .venv\Scripts\python.exe (
    .venv\Scripts\python.exe -c "import sys; raise SystemExit(0 if sys.version_info[:2] == (3, 12) else 1)"
    if errorlevel 1 rmdir /s /q .venv
)

if not exist .venv (
    py -3.12 -m venv .venv
    if errorlevel 1 goto :error
)

call .venv\Scripts\activate.bat
python -m pip install --upgrade pip
if errorlevel 1 goto :error
python -m pip install -r requirements.txt
if errorlevel 1 goto :error

if not exist Config\settings.yaml (
    copy Config\settings.example.yaml Config\settings.yaml >nul
)

echo.
echo Instalacion terminada.
echo Revisa Python\Config\settings.yaml
pause
exit /b 0

:error
echo ERROR durante la instalacion.
pause
exit /b 1
