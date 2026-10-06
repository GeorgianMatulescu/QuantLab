# QuantLab Dashboard v0.13 — Context Features

## Mejoras visuales

Las etiquetas de:

- ORB High;
- ORB Low;
- Entry;
- Stop;
- Target;
- Exit;

usan ahora posiciones y desplazamientos diferentes, reduciendo los
solapamientos.

## Contexto añadido

- Gap porcentual respecto al cierre anterior.
- ATR 14 en puntos.
- Percentil ATR de las últimas 60 sesiones.
- Percentil del rango ORB de las últimas 60 sesiones.
- Día de la semana.
- Mes.
- Retorno de la sesión.
- Dirección de la sesión.
- Clasificación heurística de día de tendencia.

VIX continúa como dato pendiente porque aún no está integrado.

## Test

```matlab
run("tests/test_trade_context_features.m")
```


## v0.14 — Marcadores de ejecución

Convención gráfica:

- Compra: flecha azul marino debajo de la vela, apuntando hacia arriba.
- Venta: flecha roja encima de la vela, apuntando hacia abajo.
- ORB High y ORB Low: línea negra discontinua.
- Stop y Target: línea fina continua.
- Para LONG, stop y target son órdenes de venta y aparecen en rojo.
- Para SHORT, stop y target son órdenes de compra y aparecen en azul marino.

Prueba:

```matlab
run("tests/test_trade_research_execution_markers.m")
```


## v0.14.1 — Limpieza completa del gráfico Research

El exceso de líneas se producía porque `cla(ax)` no elimina objetos con
`HandleVisibility="off"`.

Las líneas ORB, Stop, Target y las flechas usan precisamente esa propiedad,
por lo que cada selección de trade añadía nuevos objetos sin borrar los
anteriores.

Se añade:

```matlab
resetResearchAxes(ax)
```

que elimina todos los objetos mediante `allchild`.

Prueba:

```matlab
run("tests/test_trade_research_axes_reset.m")
```


## v0.14.2 / v0.25.6 — Colores de niveles y conexión del trade

- Stop siempre rojo y Target siempre verde, sin depender de LONG/SHORT.
- Entrada siempre azul.
- Salida EOD siempre naranja; no se añade para salidas STOP, BREAKEVEN o TARGET.
- Entrada y salida exactas unidas mediante línea gris oscura de puntos.

Prueba:

```matlab
run("tests/test_trade_research_colors_connection.m")
run("tests/test_trade_research_semantic_level_colors.m")
```

## v0.25.7 — Colores semánticos de las flechas

- La flecha de entrada es siempre azul.
- La flecha de salida por TARGET es siempre verde.
- La flecha de salida por STOP es siempre roja.
- La flecha de salida por BREAKEVEN es siempre gris.
- La flecha de salida por EOD es siempre naranja.
- La orientación conserva el significado BUY/SELL: arriba para compra y abajo
  para venta.

Prueba:

```matlab
run("tests/test_trade_research_semantic_arrow_colors.m")
```

## v0.25.8 — Etiquetas operativas a la izquierda

- Las etiquetas Entrada, Target y Stop aparecen al lado izquierdo de Research.
- Las líneas conservan su extensión completa y sus colores semánticos.
- La etiqueta Salida EOD mantiene su posición independiente.

Prueba:

```matlab
run("tests/test_trade_research_left_level_labels.m")
```


## v0.14.3 — Conexión entrada-salida

La conexión exacta entre entrada y salida usa ahora:

- línea de puntos `:`;
- color gris oscuro `[0.25 0.25 0.25]`;
- grosor fino `0.75`.

Prueba:

```matlab
run("tests/test_trade_research_dotted_connection.m")
```


## v0.14.4 — Trades descartados

Los niveles teóricos de entrada, stop y target pueden quedar guardados para
auditoría aunque la operación no se ejecute. El gráfico solo muestra flechas,
Stop, Target y conexión entrada-salida cuando:

```matlab
valid == true
contracts > 0
entry_time válido
entry_price finito
```

Los trades descartados conservan únicamente la sesión y las líneas ORB.


## v0.14.5 — Resaltado de fila seleccionada

Al seleccionar cualquier celda en `Trades`, se resalta la fila completa con:

- fondo azul claro;
- texto azul oscuro;
- fuente en negrita.

Al cambiar de perfil o seleccionar otra operación, el resaltado anterior se
elimina automáticamente.

Prueba:

```matlab
run("tests/test_trade_table_row_highlight.m")
```


## v0.14.6 — Resaltado inmediato

Al seleccionar una celda, QuantLab ahora:

1. elimina el resaltado anterior;
2. aplica el estilo a toda la nueva fila;
3. fuerza el repintado con `drawnow`;
4. calcula y abre Research Mode.

Esto evita que la fila anterior permanezca resaltada mientras se procesa el
nuevo trade.

Prueba:

```matlab
run("tests/test_trade_table_immediate_highlight.m")
```


## v0.14.7 — Resaltado de filas en Orders

Al seleccionar cualquier celda de la pestaña `Orders`:

- se elimina el resaltado anterior de esa tabla;
- se resalta la fila completa;
- se fuerza el repintado inmediato con `drawnow`;
- no se abre Research Mode, porque Orders conserva su función de auditoría.

El resaltado de Orders se limpia al cambiar de perfil.

Prueba:

```matlab
run("tests/test_orders_table_immediate_highlight.m")
```


## v0.15 — Equity, Drawdown y layout responsivo

- Equity acumulada expresada en porcentaje respecto al capital inicial.
- Equity positiva: línea y sombreado verdes.
- Equity negativa: línea y sombreado rojos.
- Retornos por trade coloreados según su signo.
- Drawdown con línea y sombreado rojos.
- El eje del drawdown siempre tiene 0 % como límite superior.
- Assets Sales Volume y Drawdown ocupan todo el panel mediante uigridlayout.
- Assets Sales Volume ajusta automáticamente el eje al notional mostrado.

Prueba:

```matlab
run("tests/test_dashboard_equity_drawdown_layout.m")
```


## v0.15.1 — Cruces de equity y drawdown azul

La ausencia de línea en algunos cruces por 0 % se debía a que la serie positiva
y la negativa se separaban mediante valores `NaN`. Entre una observación
negativa y otra positiva quedaba un tramo sin dibujar.

Ahora se interpola el instante exacto del cruce por 0 % y se dibujan ambos
segmentos con su color correspondiente.

El drawdown utiliza:

- línea azul primario;
- sombreado azul;
- 0 % fijo como límite superior.

Prueba:

```matlab
run("tests/test_equity_crossing_and_blue_drawdown.m")
```


## v0.15.2 — Corrección completa de Equity Curve

Se corrigen dos posibles fuentes de artefactos:

1. `cla` podía conservar límites manuales o un zoom anterior del eje.
2. El sombreado positivo/negativo no incluía el instante exacto del cruce
   por 0 %, produciendo pequeñas cuñas o discontinuidades.

Ahora:

- los ejes se reinician con `cla(...,"reset")`;
- se insertan puntos exactos en cada cruce por 0 %;
- línea y sombreado comparten la misma serie interpolada;
- el eje X se fija explícitamente al histórico completo;
- el eje Y se recalcula con todos los valores.

Prueba:

```matlab
run("tests/test_equity_curve_complete_rendering.m")
```


## v0.15.3 — Conservación del zoom

El zoom mostrado en la captura era intencionado. Se elimina el restablecimiento
forzado de límites y se conserva cualquier zoom manual del usuario.

Se mantiene la corrección de los cruces por 0 % mediante interpolación.

Prueba:

```matlab
run("tests/test_equity_curve_preserve_zoom.m")
```


## v0.15.4 — Restablecimiento automático del zoom

La Equity Curve vuelve a utilizar:

```matlab
cla(equityAxes,"reset");
cla(returnAxes,"reset");
```

Cada actualización del dashboard:

- elimina cualquier zoom manual anterior;
- elimina desplazamientos realizados con pan;
- recalcula automáticamente los límites;
- muestra de nuevo todo el histórico;
- conserva la corrección de los cruces exactos por 0 %.

Prueba:

```matlab
run("tests/test_equity_curve_reset_zoom.m")
```


## v0.15.5 — Limpieza del Drawdown al cambiar de perfil

El gráfico acumulaba curvas porque sus objetos se crean con:

```matlab
HandleVisibility = "off"
```

y `cla(drawdownAxes)` podía conservarlos.

Ahora utiliza:

```matlab
resetDashboardAxes(drawdownAxes)
```

que elimina todos los objetos mediante `allchild` y reinicia completamente el
eje antes de representar el perfil seleccionado.

Prueba:

```matlab
run("tests/test_drawdown_profile_reset.m")
```


## v0.15.6 — Reinicio estandarizado de todas las gráficas

Todas las gráficas principales del Overview utilizan ahora:

```matlab
resetDashboardAxes(ax)
```

Se aplica a:

- Equity;
- retornos por trade;
- Assets Sales Volume;
- Drawdown;
- Exposure;
- Portfolio Turnover.

Al cambiar de perfil, cada gráfica:

- elimina todos los objetos anteriores;
- elimina también objetos con `HandleVisibility="off"`;
- reinicia zoom y pan;
- recalcula automáticamente los límites;
- dibuja únicamente el perfil seleccionado.

Trade Research conserva su limpieza específica mediante
`resetResearchAxes`, porque ese gráfico contiene velas, niveles y marcadores
propios.

Prueba:

```matlab
run("tests/test_all_dashboard_charts_reset.m")
```


## v0.16 — Trade Research optimizado

Se han corregido los dos principales cuellos de botella.

### Caché de sesiones

Antes, cada clic volvía a recorrer todo el CSV de un minuto para:

- construir las sesiones diarias;
- calcular gap y ATR;
- calcular percentiles;
- calcular ORB;
- localizar las 390 barras del día.

Ahora `buildTradeResearchCache` realiza ese trabajo una sola vez al abrir el
dashboard. Cada clic recupera la sesión mediante índices precalculados.

### Dibujo OHLC vectorizado

Antes se creaban aproximadamente:

```text
390 barras × 3 objetos = 1.170 objetos gráficos
```

Ahora todas las barras se dibujan con solo tres objetos:

- mechas;
- aperturas;
- cierres.

### Respuesta visual inmediata

Al seleccionar un trade:

1. se resalta la fila;
2. se abre Research;
3. aparece `Cargando Trade...`;
4. se representa la sesión desde la caché.

Al pulsar otra celda de la misma fila no se recalcula el trade.

Prueba:

```matlab
run("tests/test_trade_research_performance.m")
```


## v0.17 — Calendar & Rolling Analytics

Se añade la pestaña `Analytics`.

### Calendar Returns

- Heatmap mensual por año.
- Columna Total anual.
- Verde para rentabilidad positiva.
- Rojo para rentabilidad negativa.
- Mejor y peor mes.
- Mejor y peor año.
- Porcentaje de meses positivos.
- Rentabilidad y volatilidad mensual.

### Rolling Metrics

Ventanas seleccionables de 20, 40 y 60 observaciones:

- Win Rate.
- Expectancy en R.
- Profit Factor.
- Sharpe por operación.
- Drawdown.
- Porcentaje de operaciones ejecutadas.

Al cambiar de perfil o de ventana, todos los gráficos se reinician y muestran
únicamente la selección actual.

Prueba:

```matlab
run("tests/test_dashboard_calendar_rolling_analytics.m")
```


## v0.17.1 — Corrección de zona horaria

`calculateRollingMetrics` ya no preasigna las fechas con `NaT(count,1)`.
Ahora reutiliza directamente:

```matlab
dates = trades.session_date(windowSize:end);
```

Así se conserva la zona horaria de `session_date` y se evita el error
`checkCompatibleTZ`.

Pruebas:

```matlab
run("tests/test_rolling_metrics_timezone.m")
run("tests/test_dashboard_calendar_rolling_analytics.m")
```


## v0.18 — Trade Distribution

La pestaña `Analytics` contiene ahora dos subpestañas:

- `Calendar & Rolling`
- `Trade Distribution`

### Gráficos

- Histograma de Net R.
- Histograma de Net PnL.
- Distribución de R por dirección.
- Distribución de R por motivo de salida.
- ORB Range frente a Net R.
- Histogramas seleccionables de MFE, MAE, duración, contratos y riesgo.

### Filtros

- ALL.
- LONG.
- SHORT.
- TARGET.
- STOP.
- BREAKEVEN.
- EOD.

### Estadísticas

- Media y mediana.
- Desviación estándar.
- Percentiles 5, 25, 75 y 95.
- Mínimo y máximo.
- Asimetría.
- Porcentaje de resultados positivos.
- PnL total, medio y mediano.
- Porcentaje del beneficio generado por el mejor 10 % de operaciones.
- MFE, MAE, duración, contratos, riesgo y rango ORB medios.

Los percentiles y la asimetría se calculan sin depender de Statistics
Toolbox.

Prueba:

```matlab
run("tests/test_dashboard_trade_distribution.m")
```


## v0.18.1 — Corrección del bloqueo de Trade Research

Se corrige el estado permanente `Cargando Trade...`.

Cambios:

- el loading ya no reinicia dos veces el eje;
- `drawnow` utiliza `limitrate nocallbacks`;
- la fila solo se marca como cargada después de completar el render;
- cualquier error devuelve Research a un estado recuperable;
- el error se muestra dentro del propio dashboard;
- la misma fila puede seleccionarse de nuevo;
- la búsqueda de sesión se realiza mediante `YYYYMMDD`, evitando
  incompatibilidades de zona horaria;
- entrada y salida se alinean con la zona horaria del gráfico.

Pruebas:

```matlab
run("tests/test_trade_research_callback_recovery.m")
run("tests/test_trade_research_end_to_end.m")
```


## v0.18.2 — Restauración estable del dashboard

Se corrigen dos problemas introducidos al añadir Trade Distribution.

### Analytics responsive

El `uitabgroup` interno estaba creado directamente sobre el `uitab`, por lo
que conservaba un tamaño fijo y aparecía como un panel pequeño en la esquina
inferior izquierda.

Ahora utiliza:

```matlab
analyticsHost = uigridlayout(analyticsTab,[1 1]);
analyticsTabs = uitabgroup(analyticsHost);
```

### Carga diferida y aislada

Calendar & Rolling y Trade Distribution ya no se calculan dentro del camino
crítico de `refreshAll`.

Al cambiar de perfil:

1. se actualizan KPIs, Overview, Report, Orders y Trades;
2. se repinta inmediatamente el perfil;
3. Analytics queda marcado como pendiente;
4. solo se calcula al abrir la subpestaña correspondiente.

Un error en Analytics ya no puede dejar en blanco el dashboard, bloquear el
selector de perfiles ni afectar a Research.

Pruebas:

```matlab
run("tests/test_dashboard_lazy_analytics_architecture.m")
run("tests/test_dashboard_core_profile_refresh.m")
run("tests/test_trade_research_end_to_end.m")
```


## v0.18.3 — Corrección del cliente gráfico

El origen de las gráficas en blanco era la limpieza destructiva de los
`UIAxes`:

```matlab
allchild(ax)
cla(ax,"reset")
```

`allchild` también podía alcanzar objetos internos y ocultos de la
`AxesToolbar`. En MATLAB Online esto podía dejar el cliente gráfico sin
respuesta, provocar `Graphics timeout` y hacer que los ejes quedasen en
blanco.

Ahora todas las gráficas utilizan `clearDashboardAxesSafely`, que:

- elimina únicamente las primitivas de `ax.Children`;
- conserva la AxesToolbar;
- conserva los controladores internos;
- devuelve límites y ticks a modo automático;
- permite redibujar inmediatamente;
- sigue eliminando líneas con `HandleVisibility="off"`.

También se fuerza un `drawnow nocallbacks` después de actualizar el perfil
principal.

Pruebas:

```matlab
run("tests/test_no_destructive_axes_reset.m")
run("tests/test_safe_graphics_reset_and_redraw.m")
run("tests/test_dashboard_core_profile_refresh.m")
run("tests/test_trade_research_end_to_end.m")
```


## v0.18.3.1 — Corrección del test

El test anterior encontraba la cadena `cla(ax,"reset")` dentro de un
comentario explicativo y la interpretaba erróneamente como código ejecutable.

Ahora ignora las líneas de comentario antes de comprobar llamadas
destructivas.

Pruebas:

```matlab
run("tests/test_safe_graphics_reset_source_scan.m")
run("tests/test_no_destructive_axes_reset.m")
run("tests/test_safe_graphics_reset_and_redraw.m")
```


## v0.18.3.2 — Limpieza de objetos gráficos ocultos

`ax.Children` no incluye necesariamente los objetos creados con:

```matlab
HandleVisibility = "off"
```

Por eso el test anterior concluía que no se habían creado objetos, aunque
sí estaban dibujados.

La limpieza ahora usa `findall` restringido a tipos gráficos concretos:

- line
- area
- bar
- histogram
- scatter
- text
- constantline
- image
- surface
- patch
- rectangle
- quiver
- errorbar
- stem

Esto elimina también los objetos ocultos sin tocar la AxesToolbar.

Pruebas:

```matlab
run("tests/test_safe_graphics_reset_source_scan.m")
run("tests/test_hidden_graphics_cleanup.m")
run("tests/test_safe_graphics_reset_and_redraw.m")
```


## v0.18.4 — Refinamiento visual y colores fijos

### Exposure

Los colores ya no dependen del orden interno de MATLAB:

- LONG: azul.
- SHORT: rojo.

### Trade Distribution

- histogramas separados por signo;
- pérdidas en rojo y ganancias en verde;
- intervalos de Net R más legibles;
- líneas de media y mediana;
- LONG azul y SHORT rojo;
- STOP rojo, BREAKEVEN gris, TRAILING_STOP morado, TARGET verde y EOD naranja;
- correlación, R² y número de observaciones en ORB Range vs Net R;
- tabla resumen con formato visual de resultados positivos, negativos y
  concentración elevada del beneficio.

Pruebas:

```matlab
run("tests/test_exposure_fixed_colors.m")
run("tests/test_trade_distribution_visual_refinement.m")
run("tests/test_safe_graphics_reset_and_redraw.m")
```


## v0.19 — Generic Segment Explorer

QuantLab incorpora un Research Lab reutilizable con cualquier estrategia.

### StrategyResult extendido

Cada estrategia puede declarar:

```matlab
strategyResult.feature_catalog
strategyResult.parameter_schema
strategyResult.analysis_capabilities
```

Cuando no existe catálogo, QuantLab lo infiere de forma conservadora.

### Feature roles

- `input`: conocido antes o al entrar.
- `context`: contexto temporal o de mercado.
- `outcome`: conocido después del trade.
- `execution`: información operativa.
- `identifier` y `time`.

El Segment Explorer solo ofrece por defecto `input` y `context`, evitando
usar PnL, MFE, MAE o exit reason como filtros predictivos.

### Segment Explorer

- selector dinámico de características;
- categorías, quartiles, quintiles y deciles;
- muestra mínima configurable;
- split temporal configurable;
- expectancy, win rate, profit factor, PnL, mediana, drawdown y número de
  trades;
- comparación inicial/final;
- ranking descriptivo de características;
- tabla de validación por segmento.

El motor no contiene referencias a ORB. ORB únicamente aporta su catálogo
desde su propio plugin.

Pruebas:

```matlab
run("tests/test_strategy_research_schema.m")
run("tests/test_generic_segment_explorer.m")
run("tests/test_dashboard_generic_segment_integration.m")
```


## v0.20 — Generic Strategy Optimizer

Optimization is a separate top-level tab because it is an execution
workflow, not a descriptive analytics view.

### Current mode

- Full Grid, similar to the exhaustive optimizer in MetaTrader 5.
- One or two numeric/integer parameters.
- Independent execution profile selection.
- Configurable IS/OOS temporal split.
- Cache by strategy, profile, split and parameter values.
- Cancellation between combinations.
- Partial errors do not stop the entire sweep.
- Automatic MAT and CSV export.
- Heatmap for two parameters.
- Line chart for one parameter.
- Return versus drawdown chart.
- Ranking by PnL, Net R, expectancy, profit factor, OOS expectancy,
  return/drawdown, robustness or lowest drawdown.

### Generic contract

Parameter names are configuration paths:

```matlab
orb.rewardRisk
risk.fixedRiskUSD
risk.maximumContracts
```

The optimizer does not contain ORB logic. It applies each path to `cfg`
and executes the installed strategy plugin.

A strategy declares whether a parameter requires rebuilding events using
`rebuild_events`. When all selected parameters are downstream of event
detection, QuantLab builds events once and reuses them for every run.

### Tests

```matlab
run("tests/test_orb_optimization_parameter_schema.m")
run("tests/test_generic_parameter_sweep_engine.m")
run("tests/test_dashboard_separate_optimization_tab.m")
run("tests/test_orb_parameter_sweep_smoke.m")
```


## v0.21 — Walk-Forward & Robustness

Optimization now contains two internal tabs:

```text
Optimization
├── Full Grid
└── Walk-Forward
```

### Walk-forward workflow

1. Reserve the final holdout sessions.
2. Build anchored or rolling development windows.
3. Run the full parameter grid on every training window.
4. Evaluate every configuration on the immediately following OOS window.
5. Select the training winner for each window.
6. Aggregate OOS behavior for every configuration.
7. Rank stable neighborhoods using Plateau Score.
8. Optionally evaluate the consensus configuration on the final holdout.

The holdout is never included in parameter ranking. Its checkbox is unchecked
by default and requires an explicit warning confirmation before evaluation.

### Robustness outputs

- OOS expectancy by window;
- positive OOS window percentage;
- worst OOS expectancy;
- OOS dispersion;
- IS/OOS sign agreement;
- aggregate OOS PnL and drawdown;
- WF Robustness Score;
- neighborhood mean/std;
- Plateau Score;
- selected-configuration frequency;
- locked or evaluated holdout result.

### Tests

```matlab
run("tests/test_walk_forward_window_builder.m")
run("tests/test_walk_forward_holdout_isolation.m")
run("tests/test_generic_walk_forward_engine.m")
run("tests/test_dashboard_walk_forward_integration.m")
run("tests/test_orb_walk_forward_smoke.m")
```


## v0.22 — Parameter Activity & Strategy Filters

### Automatic activity diagnostics

Every optimization result now contains:

- `Activity`
- `Equivalent`
- `TargetHits`
- a deterministic behavior group

Activity states:

- `ACTIVE`
- `PLATEAU_EDGE`
- `INACTIVE_PLATEAU`
- `NO_TRADES`
- `MIXED`

Configurations with identical trade behavior are grouped automatically.
This detects cases such as several profit targets that are never reached
and therefore produce the same exits and PnL.

Full Grid and Walk-Forward tables highlight inactive regions in grey.
The summaries warn when the best or consensus configuration has zero
target exits or belongs to an equivalent plateau.

### Generic strategy filters

The optimization core remains strategy-agnostic. ORB now declares two
real filter parameters from its plugin:

```matlab
orb.filters.minimumRangePoints
orb.filters.maximumRangePoints
```

These parameters can be optimized alone or jointly with Reward/Risk.

Suggested first joint Full Grid:

```text
Reward/Risk Target: 4 → 12, step 2
Minimum ORB Range:   0 → 60, step 10
```

Suggested Walk-Forward grid:

```text
5 RR values × 7 range values = 35 configurations
5 windows × 35 × 2 phases = 350 backtests
```

Keep the final holdout disabled until a positive, stable and active
region is found.


## v0.23 — UI, Performance & Plain Numbers

### Walk-Forward layout

The setup panel is divided into five clear rows:

1. temporal plan and protected holdout;
2. parameter 1;
3. optional parameter 2;
4. ranking and execution;
5. full-width status.

Labels use explicit names such as `Train sessions`, `OOS sessions` and
`Step sessions`, and the status no longer competes with parameter fields.

### Fixed stability colors

- selected stability metric: fixed purple;
- WF Robustness: fixed orange;
- inactive equivalent configurations: fixed grey.

Colors no longer depend on plot creation order, profile or selected tab.

### Faster Full Grid reaction

- immediate busy feedback before context preparation;
- prepared context cached during the dashboard session;
- ORB bars pre-grouped by session;
- ORB optimizer executes only the requested profile;
- progress redraws are throttled.

The numerical result remains identical to the complete strategy run.

### No scientific notation

Optimization and Walk-Forward tables are formatted as plain decimal text.
This includes PnL, R values, percentages, parameter values, scores and
elapsed time. Raw numeric results and exported files remain numeric.


## v0.24 — Optimization Setup Layout

### Walk-Forward estimate

The estimate is no longer placed in the crowded execution row. The final
row now contains three independent areas:

- full-width execution status;
- total estimated runs;
- complete breakdown of windows, configurations and phases.

The breakdown is therefore visible without ellipsis at the normal
dashboard width.

### Full Grid setup

Full Grid now follows the same visual hierarchy as Walk-Forward:

1. profile, ranking, inner split and run limit;
2. required parameter 1;
3. optional parameter 2;
4. execution buttons and complete estimate;
5. full-width status.

The estimate updates automatically when a parameter, start, stop, step or
maximum-run limit changes.


## v0.24.1 — Fast Dashboard Startup

The v0.24 dashboard performed several hidden-tab operations during
startup:

- repeated Full Grid estimate calculations;
- repeated Walk-Forward estimate calculations;
- rendering empty optimization axes and tables.

These operations are now lazy.

At startup QuantLab only renders the visible core dashboard. The selected
Optimization subtab initializes its estimate and result view when the user
opens it for the first time. Empty result charts are not redrawn.

This change does not alter backtest, optimization or walk-forward results.


## v0.25 — Generic Bar Strategy SDK & Market Abstraction

QuantLab Core is no longer registered around a fixed list of strategies.
It discovers plugin folders automatically and validates the Strategy
Plugin v1 contract.

### Initial scope

- intraday futures;
- simple stock strategies;
- forex bar strategies;
- crypto bar strategies;
- canonical OHLCV bars;
- long/short, stops, targets and time exits;
- integer and fractional quantities.

### Create a strategy

```matlab
createBarStrategyScaffold("MyStrategy","My Strategy")
rehash
listStrategies()
```

The new plugin is available without changing Core, Dashboard, Research,
Full Grid or Walk-Forward.

### Reference validation strategy

`EMA_CROSS` proves that the framework is not coupled to ORB. It uses EMA
crosses, an ATR stop and a fixed reward/risk target and supports all four
initial asset classes.

### Contracts

- `BAR_V1`: canonical OHLCV bars;
- `TRADE_V1`: common result table;
- `InstrumentSpec`: tick, multiplier and quantity rules;
- `SessionSpec`: regular or 24/7 sessions;
- generic commission, spread and slippage models.
