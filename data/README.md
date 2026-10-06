# Carpeta de datos

Los históricos creados por el descargador se guardan automáticamente aquí.

Para MNQ continuo de 1 minuto, el proyecto incluye dos datasets:

```text
MNQ/
└── 1_min/
    ├── MNQ_CONTFUT_1_min_ALL.csv
    ├── MNQ_CONTFUT_1_min_ALL.sqlite
    ├── MNQ_CONTFUT_1_min_ALL.metadata.json
    ├── MNQ_CONTFUT_1_min_ALL.rolls.csv   (tras descarga contractual IBKR)
    ├── MNQ_CONTFUT_1_min_ALL.contract_volume.csv
    ├── MNQ_CONTFUT_1_min_ALL.quality.csv
    ├── MNQ_FUT_CHAIN_1_min.cache.sqlite
    ├── MNQ_CONTFUT_1_min_RTH.csv
    ├── MNQ_CONTFUT_1_min_RTH.sqlite
    └── MNQ_CONTFUT_1_min_RTH.metadata.json
```

- `ALL`: horario extendido (`use_rth=0`). Es el dataset activo para
  `CRT_3H_MADRID` porque incluye las ventanas de Londres y Nueva York.
- `RTH`: horario regular de Estados Unidos (`use_rth=1`). Se conserva para
  ORB, EMA Cross y comparaciones posteriores.

La configuración selecciona el archivo correcto automáticamente según
`cfg.strategyName`.

## Dataset incluido y sustitución segura

El paquete conserva el dataset IBKR aportado por el usuario para que el
dashboard siga funcionando antes de la nueva descarga. Sus tramos antiguos no
deben considerarse validados contractualmente.

Para sustituirlo por una cadena construida con contratos reales ejecuta
`scripts/windows/07_descargar_MNQ_IBKR_CONTRATOS_2Y_ALL.bat`. La descarga usa
solo IBKR, se puede reanudar y no reemplaza el CSV activo hasta completar la
validación. La cobertura final queda registrada en los metadatos.

Para MATLAB Online, sube como mínimo el CSV a esta misma ruta dentro de MATLAB Drive.
El CSV incluye:

- `datetime`: hora UTC;
- `datetime_new_york`: hora de Nueva York;
- `session_date_new_york`;
- `time_new_york`;
- OHLCV y metadatos del contrato.
