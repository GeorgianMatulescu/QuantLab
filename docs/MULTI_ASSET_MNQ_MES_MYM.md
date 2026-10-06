# Comparación CRT 3H: MNQ, MES y MYM

## Por qué se usan los micros

La cesta oficial de esta prueba es `MNQ + MES + MYM`. Mantiene una escala de
ejecución compatible con una cuenta de 50.000 USD y evita que el contrato
mínimo de ES, NQ o YM descarte señales cuyo stop supera el presupuesto de
riesgo. Las reglas de señal no cambian entre activos.

| Activo | Bolsa IBKR | Tick | Multiplicador USD/punto |
| --- | --- | ---: | ---: |
| MNQ | CME | 0,25 | 2,00 |
| MES | CME | 0,25 | 5,00 |
| MYM | CBOT | 1,00 | 0,50 |

Los perfiles de ejecución conservan el mismo número de ticks de deslizamiento:

- `IDEAL`: sin costes ni slippage.
- `REALISTIC`: 1 tick en entrada, 2 ticks en stop y 1,24 USD round-trip por
  contrato.
- `CONSERVATIVE`: 2 ticks en entrada, 4 ticks en stop, 1 tick en target y
  1,50 USD round-trip por contrato.

## Descargar MES y MYM

1. Abre TWS o IB Gateway y espera a que figure conectado.
2. Habilita la API en modo solo lectura.
3. Ejecuta `DESCARGAR_MES_MYM_IBKR_2Y.bat` desde la raíz de QuantLab.
4. Escribe `SI`.

No se utiliza Databento ni se inicia ninguna compra de histórico. La descarga
depende de los permisos CME y CBOT ya disponibles en la cuenta IBKR. Si se
interrumpe, vuelve a ejecutar el mismo archivo: cada activo reanuda su caché.

## Comparar en MATLAB

Abre la carpeta `QuantLab/MATLAB` y ejecuta:

```matlab
result = run_three_asset_comparison;
```

El proceso:

1. audita la cobertura de cada CSV;
2. elimina el primer y último día potencialmente parciales;
3. recorta los tres activos al mismo intervalo común;
4. ejecuta las mismas 24 combinaciones de perfil, sesión y salida;
5. genera la comparación por activo y la cartera combinada.

Los resultados se guardan en:

`MATLAB/Reports/CRT_3H_MADRID/MULTI_ASSET/`

Archivos principales:

- `coverage_audit.csv`: fechas, filas y huecos por activo.
- `asset_comparison_common_sample.csv`: métricas de cada activo en fechas
  idénticas.
- `combined_portfolio_summary.csv`: métricas de la cartera para los 24
  escenarios.
- `combined_trades_ideal.csv`, `combined_trades_realistic.csv` y
  `combined_trades_conservative.csv`: operaciones del escenario principal.

## Regla de la combinada

Cada trade de activo recibe un tercio del riesgo normal. Si MNQ, MES y MYM
generan señal dentro de la misma sesión, la exposición agregada equivale al
riesgo de una operación mono-activo. Si solo aparece una señal, se mantiene
ese tercio: no se reasigna capital usando información futura.

La curva combinada se expresa en R, ordenada por hora de salida. También se
conserva `rawNetR` para distinguir la suma bruta de señales de la asignación
real de cartera. Esta política evita presentar tres índices estadounidenses
correlacionados como si fueran tres apuestas independientes.
