# Exportaciones del Dashboard

QuantLab guarda las exportaciones en:

```text
QuantLab/exports/<ESTRATEGIA>/<YYYYMMDD_HHMMSS_mmm>_<modo>/
```

La barra superior ofrece:

- `Exportar pestaña`: guarda los datos propios de la pestaña visible.
- `Exportar todo`: guarda la vista activa, todas las combinaciones de
  ejecución/sesión/salida, los inputs de research y los resultados de
  optimización que estén cargados en memoria.

## Estructura

```text
00_manifest/       contexto, configuración, dataset e índice de archivos
01_active_view/    Orders, Trades, métricas y Analytics seleccionados
02_all_scenarios/  perfil/sesión/salida con backtests independientes
03_research/       eventos, contexto diario, catálogos y resumen global
04_optimization/   Full Grid y Walk-Forward disponibles
05_figures/        captura del Dashboard visible
06_logs/           logs cuando se exporta esa pestaña
```

`orders.csv` conserva también setups no ejecutados y su motivo. `trades.csv`
contiene únicamente operaciones ejecutadas.

El histórico de mercado no se duplica. `dataset_inventory.csv` registra la
ruta, tamaño, periodo, zona horaria y huella del fichero original.
