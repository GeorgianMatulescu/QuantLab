# QuantLab

Arquitectura base para descarga, investigación y backtesting cuantitativo.

## Principios

- `data/` es el único almacenamiento compartido.
- `Python/` descarga, valida y persiste datos.
- `MATLAB/` ejecuta backtests, estadísticas y dashboards.
- Cada estrategia vive en `MATLAB/Strategies/<Nombre>/`.
- El código reutilizable vive en `MATLAB/Core/`.
- Los resultados generados por MATLAB permanecen en `MATLAB/Reports/`.

## Estructura

```text
QuantLab/
├── data/
├── Python/
├── MATLAB/
│   ├── Core/
│   ├── Strategies/
│   ├── Analytics/
│   ├── Reports/
│   ├── Dashboard/
│   ├── Utils/
│   └── tests/
├── scripts/windows/
├── logs/
├── docs/
└── README.md
```

## Flujo normal

1. Descargar datos con `scripts/windows/`.
2. Subir o sincronizar `data/` con MATLAB Online.
3. Ejecutar `quantlab` desde la carpeta `MATLAB`.
4. Revisar `MATLAB/Reports/<Estrategia>/`.

La conexión Python detecta automáticamente IB Gateway y TWS en sus puertos
LIVE/PAPER habituales. El puerto configurado conserva prioridad; consulta
`docs/IBKR_CONNECTION_AUTODETECT.md`.

Para descargar MNQ de 1 minuto sin comprar histórico externo usa
`DESCARGAR_MNQ_IBKR_2Y.bat` desde la raíz del proyecto. El flujo descarga
los futuros trimestrales de IBKR, calcula el rollover por volumen, conserva
precios sin ajustar y puede reanudarse tras una interrupción. Consulta
`docs/IBKR_MNQ_FUTURES_CHAIN.md`.

Para añadir MES y MYM y comparar los tres micros usa
`DESCARGAR_MES_MYM_IBKR_2Y.bat`. Cuando finalice, ejecuta
`run_three_asset_comparison` desde la carpeta `MATLAB`. La comparación usa el
mismo intervalo temporal para los tres mercados y genera una cartera con el
riesgo repartido a tercios. Consulta `docs/MULTI_ASSET_MNQ_MES_MYM.md`.

La regla CRT predeterminada entra al 75 % del recorrido desde
el extremo barrido hacia el extremo opuesto y utiliza un target fijo de 0,5R.
La geometría y la versión de reglas se documentan en
`docs/CRT3H_ENTRY_075_RR_050.md`.

Para probar la variante con rango asiático y londinense sin sobrescribir CRT,
ejecuta `quantlab`, selecciona `SESSION_RANGE_MADRID` y pulsa **Ejecutar y
abrir dashboard**. Las reglas congeladas están en
`docs/SESSION_RANGE_MADRID_RULES.md`; esta variante utiliza entrada al 60 % y
objetivo fijo de 0,66R.

El selector descubre automáticamente los plugins instalados. También se puede
automatizar el mismo flujo con
`runQuantLabWorkflow("SESSION_RANGE_MADRID","MNQ")`. Para varios activos:
`runQuantLabBatch("SESSION_RANGE_MADRID",["MNQ","MES","MYM"])`. Consulta
`docs/QUANTLAB_LAUNCHER.md`.

## Exportar desde el Dashboard

La barra superior permite exportar la pestaña visible o un paquete completo
con todas las combinaciones. Los paquetes se guardan en `exports/<Estrategia>/`.
Consulta `docs/EXPORTS.md` para ver el contenido y la estructura.
