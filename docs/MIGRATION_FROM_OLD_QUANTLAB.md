# Migración desde la carpeta anterior

Copia únicamente estos elementos:

1. Datos descargados:
   - desde `QuantLab_antiguo/data/`
   - hacia `QuantLab_nuevo/data/`

2. Configuración privada de IBKR:
   - desde `QuantLab_antiguo/Config/settings.yaml`
   - hacia `QuantLab_nuevo/Python/Config/settings.yaml`

3. Opcional: logs que quieras conservar:
   - desde `QuantLab_antiguo/logs/`
   - hacia `QuantLab_nuevo/logs/python/`

No copies:

- `.venv`
- `__pycache__`
- archivos `.pyc`
- la antigua carpeta `MATLAB`
- los antiguos `Reports`
- `requirements.txt` antiguo
- scripts BAT antiguos

Después:

1. Ejecuta `scripts/windows/01_instalar_dependencias.bat`.
2. Comprueba `Python/Config/settings.yaml`.
3. Ejecuta `scripts/windows/02_comprobar_MNQ.bat`.
4. En MATLAB Online abre `QuantLab/MATLAB` y ejecuta `main.m`.
