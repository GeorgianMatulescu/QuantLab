# Migración v0.5 a v0.6

Conserva:

- `data/`
- `Python/Config/settings.yaml`
- `MATLAB/Reports/` opcionalmente
- `logs/` opcionalmente

No copies:

- `MATLAB/Core/`
- `MATLAB/Strategies/`
- `MATLAB/tests/`
- `MATLAB/main.m`
- `Python/.venv`

Procedimiento:

1. Renombra la carpeta anterior como backup.
2. Sube la nueva carpeta QuantLab.
3. Copia `data/`.
4. Copia `Python/Config/settings.yaml`.
5. Ejecuta `main`.
6. Ejecuta `run_market_state_demo`.
7. Ejecuta los tests de `README_v0_6.md`.
