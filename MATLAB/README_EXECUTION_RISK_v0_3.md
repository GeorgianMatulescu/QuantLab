# QuantLab MATLAB — Execution & Risk v0.3

Añade perfiles IDEAL, REALISTIC y CONSERVATIVE; slippage separado; comisiones; sizing dinámico; riesgo fijo o porcentual; exclusión por exceso de riesgo; equity y drawdown.

## Configuración predeterminada actual

QuantLab utiliza `PERCENT_EQUITY` con un riesgo máximo del 1 % de la equity
disponible antes de cada operación. Para MNQ, el número de contratos se calcula
como `floor((equity * 0.01) / (stopPoints * 2))`, respetando el máximo de 40
contratos. El valor `fixedRiskUSD` permanece en la configuración únicamente para
poder volver explícitamente al modo `FIXED_USD`.

## Instalación
Copia la carpeta `MATLAB` sobre `QuantLab/MATLAB` y acepta reemplazar.

## Ejecución
```matlab
main
run("tests/test_execution_risk.m")
```

## Salidas
`QuantLab/MATLAB/Reports/ORB/`
