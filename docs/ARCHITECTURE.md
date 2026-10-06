# Arquitectura de QuantLab

## data

Fuente única de verdad para datos históricos. No se duplica dentro de Python ni MATLAB.

## Python

Responsable de:

- conexión a brokers y proveedores;
- descarga de históricos;
- validación técnica;
- almacenamiento CSV/SQLite/Parquet;
- actualización incremental futura.

## MATLAB/Core

Código reutilizable por todas las estrategias:

- `Data`: carga, limpieza, sesiones y calendarios;
- `Execution`: simulación de órdenes y trades;
- `FillModels`: reglas de ejecución intrabar;
- `Risk`: sizing y límites de riesgo;
- `Statistics`: métricas comunes.

## MATLAB/Strategies

Cada estrategia contiene únicamente su lógica específica. Una estrategia no debe duplicar loaders, fill models ni estadísticas comunes.

## MATLAB/Analytics

Análisis transversal: Monte Carlo, bootstrap, walk-forward, estabilidad temporal, segmentación y comparativas.

## MATLAB/Reports

Salidas reproducibles generadas por MATLAB y separadas por estrategia.

## MATLAB/Dashboard

Visualización y exploración interactiva.

## tests

Pruebas de regresión para evitar que un cambio rompa resultados ya validados.


## Interfaz genérica de estrategias

Toda estrategia MATLAB debe devolver una estructura `results` con perfiles de ejecución. Esto desacopla las herramientas de auditoría de la lógica de ORB, CRT, FVG, PowerOf3 o FlyFlyer.

## Audit, Visualization y Replay

- `MATLAB/Audit`: inspección y comparación de operaciones.
- `MATLAB/Visualization`: gráficos de trades, sesiones y equity.
- `MATLAB/Replay`: reproducción barra a barra.
- `MATLAB/Core/Interfaces`: adaptadores genéricos para resultados.


## v0.5: Strategy Framework

`runStrategy` es el único punto de entrada del motor. Las estrategias se registran en `getStrategyRegistry` y se cargan mediante factories.

## v0.5: Event Engine

Los detectores publican tablas con un esquema común. Las estrategias consumen eventos sin duplicar lógica de mercado.

El núcleo no debe contener referencias directas a ORB, CRT, FVG o cualquier estrategia concreta.


## Generic Research Contract — v0.19

```text
Strategy plugin
├── feature catalog
├── parameter schema
└── analysis capabilities
          │
          ▼
StrategyResult
          │
          ▼
QuantLab Core/Research
├── feature inference
├── feature roles
├── generic segmentation
├── temporal validation
└── feature ranking
          │
          ▼
Dashboard / Segment Explorer
```

Strategy-specific names remain inside each strategy plugin. Core/Research
only consumes the shared feature contract.


## Generic Optimization Contract — v0.20

```text
Strategy parameter schema
          │
          ▼
Optimization request
├── parameter path
├── start
├── stop
└── step
          │
          ▼
Full-grid generator
          │
          ▼
Generic runner
├── apply paths to cfg
├── rebuild/reuse events
├── execute strategy plugin
├── extract selected profile
└── calculate IS/OOS metrics
          │
          ▼
Cache + Results + Dashboard + CSV/MAT
```

Optimization is deliberately separated from Analytics. Analytics studies
one completed backtest; Optimization launches many new backtests.


## Walk-Forward Contract — v0.21

```text
Raw market sessions
        │
        ├── Development windows
        │   ├── Training full grid
        │   └── Immediate next OOS full grid
        │
        └── Final holdout (excluded from ranking)
                    │
                    ▼
Per-window selected configuration
+ Per-configuration OOS aggregation
                    │
                    ▼
WF Robustness + Plateau Score
                    │
                    ▼
Consensus configuration
                    │
                    └── Optional one-time holdout evaluation
```

The Core/Optimization implementation receives strategy runners through a
factory and contains no ORB-specific rules.


## Parameter Activity Diagnostics — v0.22

```text
Backtest trade table
        │
        ▼
Behavior diagnostics
├── deterministic outcome signature
├── target / stop / EOD counts
├── selected-session checksum
└── weighted R and PnL checksums
        │
        ▼
Grid activity analysis
├── active transitions
├── plateau edges
├── inactive plateaus
└── equivalent configuration groups
        │
        ▼
Full Grid + Walk-Forward Dashboard
```

Strategy filters remain inside each plugin and are exposed through the
generic Parameter Schema. Core/Optimization never references ORB fields.


## Optimization fast path — v0.23

```text
Run Full Grid
      │
      ├── immediate UI feedback
      │
      ▼
Prepared context cache
      │
      ├── events built once
      └── market rows grouped by session
      │
      ▼
Optional plugin.runProfile(...)
      │
      └── only requested execution profile
      │
      ▼
Throttled progress + result cache
```

The generic optimizer uses `runProfile` only when a plugin declares it.
Strategies without this optional adapter continue through the standard
StrategyResult path.


## Generic Bar Strategy SDK — v0.25

```text
External OHLCV source
        │
        ▼
BAR_V1 normalization
        │
        ├── InstrumentSpec
        └── SessionSpec
        │
        ▼
Discovered Strategy Plugin
├── buildEvents(data,cfg)
├── run(data,context,events,cfg)
├── Feature Catalog
├── Parameter Schema
└── Analysis Capabilities
        │
        ▼
TRADE_V1 / StrategyResult
        │
        ├── Dashboard + Research
        ├── Full Grid
        └── Walk-Forward
```

Adding a strategy requires a new folder under `MATLAB/Strategies`; the
Core registry is generated dynamically from plugin factories.
