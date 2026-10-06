# Migración de QuantLab v0.4 a v0.5

## Elementos que debes conservar

De tu carpeta actual:

1. `data/`
2. `Python/Config/settings.yaml`
3. `MATLAB/Reports/` si quieres conservar informes anteriores
4. `logs/` opcionalmente

## No copies

- `Python/.venv`
- `MATLAB/Core`
- `MATLAB/Strategies`
- `MATLAB/Audit`
- `MATLAB/Visualization`
- `MATLAB/Replay`
- scripts antiguos
- archivos `main.m` anteriores

## Procedimiento recomendado

1. Renombra tu carpeta actual como `QuantLab_v0_4_backup`.
2. Sube la nueva carpeta `QuantLab`.
3. Copia `data/` del backup a la nueva carpeta.
4. Copia `Python/Config/settings.yaml`.
5. Copia `MATLAB/Reports/` solo para conservar resultados históricos.
6. En MATLAB Online abre `QuantLab/MATLAB`.
7. Ejecuta `main`.
8. Ejecuta las pruebas de `README_v0_5.md`.
