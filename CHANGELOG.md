# v0.25.37

- Corregida la ejecución de `SESSION_RANGE_MADRID` cuando Nueva York no
  produce ningún fill válido en los rangos candidatos Asia/Londres.
- La selección del candidato usa ahora estados y tiempos escalares, evitando
  el acceso vacío con llaves `{}` observado sobre el histórico real.
- Corregida la propiedad `Value` del área de estado del lanzador para aceptar
  el tipo requerido por `uitextarea` en MATLAB.
- Si falla el único instrumento seleccionado, el lanzador conserva ahora el
  error original en lugar de reemplazarlo por el mensaje genérico del lote.
- Añadida una regresión específica para una sesión NY completa sin setup.

## v0.25.36

- El selector muestra todas las estrategias habilitadas con nombre, identificador
  y versión del plugin.
- El instrumento pasa a ser una lista multiselección: una estrategia puede
  ejecutarse sobre uno o varios activos en la misma solicitud.
- `runQuantLabBatch` ejecuta cada activo de forma aislada, continúa si uno no
  tiene datos y abre un dashboard independiente por resultado correcto.
- Auditorías, optimizaciones y exportaciones quedan separadas en
  `Reports/<estrategia>/<instrumento>` para impedir sobrescrituras.
- Cada ventana de dashboard muestra estrategia e instrumento en el título.

## v0.25.35

- Nuevo lanzador visual universal `quantlab` para seleccionar estrategia e
  instrumento desde una sola ventana.
- Nuevo flujo reutilizable `runQuantLabWorkflow`, válido para cualquier plugin
  descubierto automáticamente en `MATLAB/Strategies`.
- Acciones separadas para recalcular, exportar y abrir el dashboard o para
  reutilizar el último resultado sin repetir el backtest.
- `main`, `launch_dashboard`, `run_session_range` y
  `launch_session_range_dashboard` quedan como wrappers compatibles; no será
  necesario crear más scripts específicos por estrategia.

## v0.25.34

- `SESSION_RANGE_MADRID` cambia su entrada del 75 % al 60 % del recorrido
  desde el extremo de manipulación hacia el extremo opuesto.
- Su objetivo fijo cambia de 0,5R a 0,66R desde el fill real.
- Nueva versión congelada de reglas
  `SESSION_RANGE_ASIA_0000_0900_LONDON_0900_1500_ENTRY_060_RR_066`.
- `CRT_3H_MADRID` conserva sin cambios la geometría 75 % / 0,5R.

## v0.25.33

- Nueva estrategia independiente `SESSION_RANGE_MADRID`; no sustituye ni
  modifica la configuración predeterminada de `CRT_3H_MADRID`.
- Londres usa el rango Asia 00:00–09:00 y opera entre 09:00–11:00.
- Nueva York compara por separado Asia 00:00–09:00 y Londres 09:00–15:00,
  conserva el primer fill válido y permite como máximo una operación.
- Cada resultado identifica `reference_range = ASIA | LONDRES` y utiliza
  señales diferenciadas para comparar ambos tipos de setup.
- Añadidos `run_session_range` y `launch_session_range_dashboard`.

## v0.25.32

- Eliminada la sincronización gráfica bloqueante durante el primer render del
  Dashboard en MATLAB Online.
- El arranque devuelve el control al cliente web y permite que los ejes se
  pinten de forma asíncrona, evitando una espera de 30 s por cada timeout.
- Los cambios interactivos posteriores conservan `drawnow limitrate` para
  actualizar el perfil sin bloquear la interfaz.

## v0.25.31

- Las peticiones intradía solicitan dos jornadas IBKR antes de recortar el
  bloque UTC, evitando conservar únicamente 120 minutos de cada día.
- Los bloques completos de lunes a viernes requieren una cobertura mínima y
  se reintentan si IBKR devuelve una jornada parcial.
- El cierre semanal del sábado se acepta como vacío sin producir un error.
- Nueva caché `ALL_v2` para ignorar los checkpoints parciales creados por la
  v0.25.30.

## v0.25.30

- Separadas las cachés IBKR de horario extendido (`ALL`) y regular (`RTH`).
- Una respuesta vacía inesperada de IBKR ya no se guarda como bloque completo.
- Añadidos reintentos con espera progresiva y pausa conservadora de 2,1 s.
- La caché antigua sin sufijo se ignora para reparar descargas contaminadas.
- El dataset activo sigue sustituyéndose únicamente después de completar y
  validar toda la cadena contractual.

## v0.25.29

- Nueva regla CRT congelada `CRT3H_ENTRY_075_RR_050`.
- Entrada al 75 % del recorrido desde el extremo barrido hacia el extremo
  opuesto del CRT, con stop detrás del extremo barrido.
- Objetivo fijo a 0,5R desde el fill real; puede quedar más allá del extremo
  opuesto del CRT y se registra explícitamente.
- Añadidos `entry_fraction`, `entry_level`, `reward_risk_planned` y
  `rules_version` al registro de cada sesión y trade.
- Dashboard y Research muestran el nivel de entrada configurado, sin seguir
  etiquetándolo erróneamente como nivel 50 %.
- La variante anterior 0,50/1R permanece reproducible mediante configuración
  y en el paquete v0.25.28.

## v0.25.28

- Añadida descarga conjunta de MES (CME) y MYM (CBOT) sin Databento.
- Auditoría de calidad sensible al tick: 0,25 para MNQ/MES y 1 para MYM.
- Configuración MATLAB parametrizable para MNQ, MES, MYM y sus minis.
- Deslizamiento normalizado por número de ticks entre activos.
- Nueva comparación MNQ/MES/MYM sobre el mismo intervalo temporal.
- Nueva cartera combinada con asignación fija de 1/3 del riesgo por activo.

## v0.25.27

- La detección contractual recorre MNQ desde el vencimiento más reciente hacia
  atrás y no aborta cuando IBKR deja de ofrecer el contrato más antiguo.
- La cadena utiliza todos los contratos consecutivos realmente disponibles.
- Si falta el contrato inicial, la cobertura comienza de forma conservadora
  después del vencimiento del trimestre anterior.
- Metadatos ampliados con cobertura solicitada, inicio efectivo y contratos no
  disponibles; el tramo ausente queda clasificado como cobertura parcial.

## v0.25.26

- Añadida descarga gratuita desde IBKR por contratos trimestrales MNQ H/M/U/Z.
- Rollover auditable por primer cruce de volumen dentro de los 45 días previos
  al vencimiento, efectivo en la siguiente apertura Globex.
- Precios originales sin back-adjustment y validación del tick de 0,25 puntos.
- Checkpoint SQLite diario para reanudar después de cierres o desconexiones.
- El dataset activo solo se sustituye tras completar toda la cadena.
- Generados `rolls.csv`, `contract_volume.csv` y `quality.csv`.
- Desactivado el script Databento para evitar compras accidentales de histórico.

## v0.25.25

- Añadida descarga de cuatro años de MNQ 1 minuto mediante Databento.
- Congelado `MNQ.v.0`: roll por volumen del día anterior y precios sin ajustar.
- Añadida estimación gratuita y límite máximo de coste obligatorio.
- Guardados `instrument_id` y contrato trimestral real para auditar cada roll.
- IBKR rechaza inmediatamente peticiones 1 minuto demasiado largas y evita
  esperas engañosas por timeout.
- Retirados los scripts IBKR de 1Y/4Y que generaban peticiones no admitidas.

## v0.11.0

- Modularización de gráficos del dashboard.
- Modularización de tablas Orders y Trades.
- Modularización del panel Logs.
- Preparación para Trade Research Mode.


## v0.12.0

- Trade Research Mode.
- Selección interactiva desde Trades.
- Ficha detallada de la operación.
- Gráfico intradía con ORB y niveles operativos.
- Panel de confluencias y contexto pendiente.


## v0.13.0

- Context Features en Trade Research Mode.
- Gap, ATR, percentiles, calendario y dirección de sesión.
- Heurística de día de tendencia.
- Etiquetas de niveles y marcadores separadas para evitar solapamientos.


## v0.14.0

- Flechas de compra y venta sobre la vela de ejecución.
- Compra: flecha azul marino bajo la vela.
- Venta: flecha roja sobre la vela.
- ORB High/Low en negro discontinuo.
- Stop/Target en línea fina continua y color según el lado de la orden.
- Eliminada la línea horizontal de entrada para reducir ruido visual.


## v0.14.1

- Corregida la acumulación de líneas y flechas en Trade Research.
- Limpieza completa de objetos con `HandleVisibility="off"`.
- Añadido `resetResearchAxes.m`.


## v0.14.2

- Azul de compra cambiado al azul primario.
- Stop y Target coloreados por dirección del trade.
- Añadida línea negra discontinua entre entrada y salida exactas.


## v0.14.3

- Línea entrada-salida cambiada de negra discontinua a gris oscuro de puntos.


## v0.14.5

- Resaltado visual de toda la fila seleccionada en Trades.
- Limpieza automática del resaltado anterior.


## v0.14.6

- Resaltado inmediato de la fila al hacer clic.
- Repintado forzado antes de calcular Research Mode.


## v0.14.7

- Resaltado inmediato de toda la fila seleccionada en Orders.
- Limpieza del resaltado de Orders al cambiar de perfil.


## v0.15.0

- Equity acumulada positiva/negativa con sombreado verde/rojo.
- Drawdown ajustado al panel y fijado en 0 % por la parte superior.
- Assets Sales Volume convertido a layout responsivo.


## v0.15.1

- Equity continua en los cruces por 0 % mediante interpolación.
- Drawdown cambiado a línea y sombreado azules.


## v0.15.2

- Reinicio completo de límites y zoom de Equity Curve.
- Cruces por 0 % insertados en la serie antes de dibujar.
- Eje X fijado al histórico completo.
- Eliminados artefactos entre línea y sombreado.


## v0.15.3

- El dashboard conserva el zoom manual de Equity Curve.
- Se mantiene la interpolación exacta de cruces por 0 %.


## v0.15.4

- Reactivado el restablecimiento automático de zoom y límites.
- Equity y retornos vuelven siempre a la vista completa al actualizarse.
- Se mantiene la interpolación exacta de cruces por 0 %.


## v0.15.5

- Corregida la acumulación de curvas de Drawdown al cambiar de perfil.
- Añadido `resetDashboardAxes.m`.
- Drawdown elimina objetos ocultos y reinicia zoom/límites antes de actualizarse.


## v0.15.6

- Limpieza completa estandarizada en todas las gráficas del Overview.
- Equity, Returns, Volume, Drawdown, Exposure y Turnover reinician objetos,
  zoom y límites al cambiar de perfil.
- Evitada la acumulación de curvas entre perfiles.


## v0.16.0

- Caché precalculada de sesiones y contexto del Trade Research.
- Eliminado el recorrido completo del CSV en cada clic.
- Gráfico OHLC vectorizado: tres objetos en lugar de ~1.170.
- Research se abre antes de dibujar y muestra estado de carga.
- Seleccionar otra celda de la misma fila no recalcula el trade.


## v0.17.0

- Nueva pestaña Analytics.
- Heatmap de Calendar Returns por mes y año.
- Resumen de estabilidad mensual.
- Rolling Win Rate, Expectancy, Profit Factor, Sharpe, Drawdown y Execution Rate.
- Ventanas seleccionables de 20, 40 y 60 observaciones.


## v0.17.1

- Corregida incompatibilidad entre datetimes con y sin zona horaria.
- Rolling Metrics reutiliza directamente `session_date(windowSize:end)`.
- Se conserva la zona horaria original en todas las fechas rolling.


## v0.18.0

- Nueva subpestaña Trade Distribution.
- Histogramas de R y PnL.
- Comparación por dirección y motivo de salida.
- Selector de MFE, MAE, duración, contratos, riesgo y ORB Range.
- Filtros ALL/LONG/SHORT/TARGET/STOP/EOD.
- Tabla con percentiles, asimetría y concentración del beneficio.


## v0.18.1

- Corregido el bloqueo de Research en `Cargando Trade...`.
- Callback de selección transaccional y recuperable.
- Eliminado el doble reset del eje durante la carga.
- Comparación de sesiones independiente de TimeZone.
- Alineación de zonas horarias para marcadores de entrada y salida.
- Añadida prueba end-to-end real del render de un trade.


## v0.18.2

- Corregido el tamaño fijo del tabgroup interno de Analytics.
- Analytics ocupa ahora toda la pestaña mediante un grid responsive.
- Calendar/Rolling y Trade Distribution pasan a carga diferida.
- Los análisis secundarios ya no bloquean el cambio de perfil.
- Añadida protección contra callbacks simultáneos.
- Errores de Analytics quedan aislados y visibles dentro de su pestaña.
- Restaurada la actualización inmediata de Overview, Report, Orders,
  Trades y Research.


## v0.18.3

- Eliminado `allchild` de la limpieza de UIAxes.
- Eliminado `cla(...,"reset")` de Dashboard y Trade Research.
- Añadida limpieza segura basada en `ax.Children`.
- Conservada la AxesToolbar y sus controladores internos.
- Límites y ticks vuelven a modo automático sin reset gráfico interno.
- Repintado completo con `drawnow nocallbacks`.
- Corregidos los gráficos en blanco y los timeouts gráficos asociados.


## v0.18.3.1

- Corregido falso positivo en `test_no_destructive_axes_reset`.
- El test ignora líneas de comentario antes de buscar llamadas prohibidas.
- La implementación de limpieza segura no cambia.


## v0.18.3.2

- Corregida la detección de objetos con HandleVisibility off.
- La limpieza usa findall limitado a primitivas gráficas seguras.
- Eliminada la dependencia de ax.Children para validar objetos ocultos.
- Añadido test específico de limpieza de gráficos ocultos.


## v0.18.4

- Paleta visual centralizada.
- Exposure con colores LONG/SHORT fijos.
- Histogramas de R y PnL separados por signo.
- Añadidas líneas de media y mediana.
- Colores consistentes por dirección y motivo de salida.
- Añadidos r, R² y n al análisis ORB Range vs R.
- Tabla de distribución con estilos semánticos.


## v0.19.0

- StrategyResult ampliado con feature catalog, parameter schema y
  analysis capabilities.
- Inferencia automática y conservadora de características.
- Roles para evitar leakage de outcomes.
- Nuevo Segment Explorer genérico.
- Segmentación por categorías, cuartiles, quintiles y deciles.
- Métricas por segmento y split temporal.
- Ranking descriptivo de características.
- ORB registra sus metadatos desde su plugin sin acoplar el dashboard.


## v0.20.0

- Added a separate top-level Optimization tab.
- Added generic one/two-parameter full-grid engine.
- Added nested configuration path overrides.
- Added parameter schema normalization and validation.
- Added event-context reuse controlled by rebuild_events.
- Added cancellation, cache and isolated combination errors.
- Added IS/OOS metrics and robustness score.
- Added optimization surface and risk/return chart.
- Added automatic MAT/CSV persistence.
- ORB registered practical optimizer ranges without coupling Core to ORB.


## v0.21.0

- Added Full Grid and Walk-Forward inner tabs under Optimization.
- Added anchored and rolling temporal windows.
- Added final holdout reservation isolated from optimization.
- Added full-grid evaluation on every training and next OOS window.
- Added per-window selected configuration results.
- Added aggregate OOS stability metrics for every parameter combination.
- Added WF Robustness and neighborhood Plateau Score.
- Added optional final holdout evaluation, unchecked by default.
- Added walk-forward cache namespaces and cancellation.
- Added MAT/CSV walk-forward persistence.


## v0.22.0

- Added deterministic trade-behavior signatures.
- Added automatic active/inactive parameter diagnostics.
- Added equivalent-configuration grouping.
- Added target/stop/EOD exit counts to optimization metrics.
- Added OOS activity diagnostics to walk-forward aggregation.
- Added visual markers and warnings for inactive plateaus.
- Extended parameter schema with suggested sweep ranges.
- Added ORB minimum/maximum range filters as plugin parameters.
- Enabled joint optimization of Reward/Risk and ORB range filters.


## v0.23.0

- Reorganized Walk-Forward controls into a readable five-row layout.
- Added fixed colors for Parameter Stability and WF Robustness.
- Added immediate Full Grid busy feedback.
- Added prepared-context caching inside the dashboard session.
- Throttled optimization progress redraws.
- Added ORB session-data cache.
- Added optional single-profile strategy optimization adapter.
- Removed scientific notation from Full Grid and Walk-Forward UI tables.
- Replaced visible %g formatting with plain decimal formatting.


## v0.24.0

- Moved Walk-Forward estimated runs to a dedicated full-width area.
- Split Walk-Forward estimate into total and complete calculation detail.
- Rebuilt Full Grid setup using a five-row intuitive layout.
- Separated required and optional optimization dimensions.
- Added a dynamic Full Grid run estimate.
- Added a dedicated full-width Full Grid status row.


## v0.24.1

- Removed hidden Full Grid rendering from dashboard startup.
- Removed hidden Walk-Forward rendering from dashboard startup.
- Removed repeated optimization estimate calculations at startup.
- Added lazy initialization per Optimization subtab.
- Startup now renders only the visible core dashboard.


## v0.25.0

- Added dynamic strategy discovery; no hardcoded strategy registry.
- Added Strategy Plugin v1 validation and official scaffold generator.
- Added canonical BAR_V1 and TRADE_V1 contracts.
- Added InstrumentSpec for futures, stocks, forex and crypto.
- Added SessionSpec for regular and 24/7 bar sessions.
- Added generic integer/fractional position sizing.
- Added generic PnL, commission, spread and slippage models.
- Added reusable bar-signal trade simulator.
- Added portable EMA_CROSS validation strategy.
- Made main and launch_dashboard strategy-configurable.
- Preserved ORB numerical compatibility through generic adapters.


## v0.25.1

- Fixed floating-point residues when rounding fractional quantities.
- Quantity rounding now normalizes to the precision defined by `quantityStep`.
- Updated the instrument abstraction test to use a numeric tolerance.
- Added regression coverage for FLOOR, CEIL and NEAREST rounding.


## v0.25.2

- Fixed Dashboard startup failure when a strategy executes multiple trades in one session.
- Temporal charts now use a unique trade timeline based on `entry_time`.
- Return bars no longer use repeated `session_date` values as XData.
- Drawdown, exposure, turnover and equity series support intraday multi-trade strategies.
- Asset Sales Volume uses unique operation labels instead of repeated dates.
- Dashboard notional calculations now use generic `quantity` and `contractMultiplier`.
- Renamed the top KPI from Contracts Traded to Quantity Traded.
## v0.25.5

- Corregida la semántica de `entry_*`: solo se rellena tras un fill real.
- Añadidos estados separados de setup, orden y trade.
- `Trades` muestra únicamente operaciones ejecutadas; `Orders` conserva la
  auditoría completa de Londres y Nueva York, incluidos rechazos y no-setups.
- Las filas de `Orders` también abren Research Mode para inspeccionar por qué
  una sesión no llegó a convertirse en trade, sin dibujar fills inexistentes.
- Añadidos `order_time`, `order_price` y `extreme_time` para explicar cada
  señal CRT sin convertirla artificialmente en un trade.
- Research Mode dibuja CRT 3H en hora de Madrid: caja 3H, máximo/mínimo
  discontinuos, 50 % discontinuo hasta su toque y extremo de manipulación.
- Research recupera el tramo exacto referencia-manipulación y lo prolonga
  hasta la salida cuando la posición cierra después de la ventana de entrada.
- La ficha Research muestra sesión CRT, estados, barrido, nivel 50 %, riesgo
  teórico y motivo traducido de no ejecución.
- Añadidas pruebas de regresión del ciclo setup → orden → fill → trade.

## v0.25.6

- Research utiliza colores semánticos independientes de LONG/SHORT.
- Stop siempre rojo y target siempre verde.
- Añadida línea horizontal azul en el precio de entrada.
- Añadida línea horizontal naranja en el precio de salida solo para cierres EOD.
- Se conservan las flechas de ejecución y la conexión punteada entrada-salida.
- Añadida prueba de regresión para la convención de colores de niveles.

## v0.25.7

- Las flechas de Research utilizan colores semánticos, no colores BUY/SELL.
- Entrada siempre azul.
- Salida por TARGET verde, por STOP roja y por EOD naranja.
- La orientación continúa indicando compra (arriba) o venta (abajo).
- Se mantienen las líneas operativas y la conexión punteada entrada-salida.
- Añadida prueba de regresión para colores y orientación de las flechas.

## v0.25.13

- Break-even CRT activado por defecto al alcanzar +1R.
- El stop se mueve al fill exacto de entrada, sin ticks adicionales.
- Política conservadora con datos de 1 minuto: el nuevo stop entra en vigor
  desde la vela siguiente a la activación.
- Los cierres protegidos se registran como `BREAKEVEN`, separados de `STOP`.
- Se guardan nivel y hora de activación, precio BE y primera vela efectiva.
- Research dibuja el tramo break-even discontinuo en gris y colorea en gris
  la flecha de salida correspondiente.
- Trade Distribution incorpora filtro y grupo `BREAKEVEN`.
- Añadida regresión funcional para activación conservadora, activación
  inmediata configurable y comparación con break-even desactivado.

## v0.25.12

- El target de CRT 3H pasa de aproximadamente 1R a 1,5R desde el fill real.
- Se elimina el límite del extremo opuesto del CRT, que impedía alcanzar 1,5R
  al estar la entrada situada en el 50 % de la manipulación.
- El nivel se ajusta conservadoramente al tick de mercado: hacia abajo para
  LONG y hacia arriba para SHORT.
- `crt3h.rewardRisk` se incorpora a configuración, validación y optimización.
- Añadida regresión funcional para targets LONG y SHORT de 1,5R.

## v0.25.11

- Aumenta de 20 a 40 micros el límite máximo de posición.
- Mantiene el riesgo dinámico del 1 % sobre la equity previa a cada trade.
- Actualiza configuración, especificación de MNQ, optimización y pruebas de sizing.

## v0.25.10

- El riesgo predeterminado pasa de 100 USD fijos al 1 % de la equity
  disponible antes de cada operación.
- El número de contratos MNQ se calcula dividiendo el presupuesto dinámico
  entre el riesgo monetario de un contrato y redondeando hacia abajo.
- Se conserva el máximo de seguridad de 20 contratos y la política `SKIP`
  cuando un solo contrato supera el presupuesto disponible.
- Añadida una regresión para el dimensionamiento porcentual y la evolución
  del presupuesto de riesgo junto con la equity.

## v0.25.9

- El umbral predeterminado de manipulación CRT pasa de 1,00 a 0,25 puntos
  tanto en Londres como en Nueva York, equivalente a un tick de MNQ.
- El catálogo de parámetros y sus valores predeterminados utilizan 0,25.
- La sesión NY del 11/11/2025 se reclasifica correctamente: el barrido del
  máximo de las 15:37 es el primero válido, fija SHORT y la entrada ocurre
  en la vela posterior de las 15:38.
- Añadida una regresión que verifica que los umbrales predeterminados
  coinciden con el tick mínimo del instrumento.

## v0.25.8

- Las etiquetas de Entrada, Target y Stop se anclan al lado izquierdo del
  gráfico Research; las líneas horizontales y sus colores no cambian.
- Auditada la sesión NY del 11/11/2025: el primer exceso sobre el máximo CRT
  fue de 0,75 puntos y no alcanzó el umbral configurado de 1 punto.
- Añadida una regresión con datos reales que confirma que el primer sweep
  válido fue el mínimo de las 15:50 y que la dirección correcta es LONG.
- Añadida una prueba de regresión para la posición izquierda de las etiquetas.

## v0.25.14

- Nueva York conserva la detección de sweeps desde las 15:00, pero solo
  permite entradas desde las 15:30, inclusive, en hora de Madrid.
- Los retornos al 50 % anteriores a las 15:30 no crean trades ni fills.
- Si solo hubo una oportunidad pre-15:30, Orders conserva el setup con el
  motivo `ENTRY_BEFORE_ALLOWED_TIME` para mantener la auditoría completa.
- Research incorpora botones contextuales de anterior/siguiente.
- La navegación conserva su origen: recorre exclusivamente Trades cuando se
  abrió desde Trades y exclusivamente Orders cuando se abrió desde Orders.
- Los controles se desactivan automáticamente al alcanzar la primera o la
  última fila del conjunto correspondiente.

## v0.25.15

- Nueva York ignora completamente las manipulaciones de las 15:00 a las
  15:29:59, hora de Madrid.
- Tanto la detección del primer sweep válido como las entradas comienzan a
  las 15:30, inclusive; la sesión parte desde estado limpio a esa hora.
- Un sweep anterior no fija dirección, extremo, nivel del 50 %, stop ni orden.
- El caso real del 06/07/2026 queda congelado como regresión: el sweep HIGH
  de las 15:00 se descarta y el primer sweep válido pasa a ser LOW a las
  15:30, con entrada LONG a las 15:31.
- Se mantienen los controles anterior/siguiente de Research y todas las
  reglas de riesgo, target y break-even de la versión anterior.

## v0.25.16

- CRT 3H ejecuta cuatro políticas de sesión como backtests independientes:
  solo Londres, solo Nueva York, ambas sesiones siempre y ambas sesiones con
  bloqueo de NY cuando Londres cierra por `TARGET`.
- Cada política mantiene su propia equity cronológica y recalcula sobre ella
  el riesgo dinámico del 1 % y el número de micros.
- El Dashboard incorpora el selector `Sessions`; Overview, Report, Orders,
  Trades, Research y Analytics cambian conjuntamente con la vista elegida.
- La vista predeterminada conserva la política anterior: un TP de Londres
  bloquea Nueva York.
- `summaryTable` incluye las doce combinaciones de cuatro políticas de sesión
  y tres perfiles de ejecución.
- Añadida una regresión que distingue `TARGET` de `BREAKEVEN` y valida las
  cuatro curvas sin filtrar resultados a posteriori.

## v0.25.19

- Nueva barra superior con `Exportar pestaña` y `Exportar todo`.
- La exportación contextual reconoce Overview, Report, Session Comparison,
  Orders, Trades, Research, las tres vistas de Analytics, Optimization y Logs.
- `Exportar todo` recorre las 24 combinaciones independientes de tres perfiles,
  cuatro políticas Londres/NY y dos gestiones de salida.
- Cada combinación guarda Orders, Trades, resumen, equity/drawdown y resultado
  diario dentro de una jerarquía perfil/sesión/salida.
- Añadidos configuración aplanada, manifiesto de artefactos, inventario del
  dataset, catálogo de features, esquema de parámetros y resultados de Full
  Grid/Walk-Forward disponibles en memoria.
- Orders y Trades se exportan por separado para conservar tanto setups no
  ejecutados como operaciones reales.
- El histórico no se duplica; queda identificado por ruta, periodo, tamaño,
  zona horaria y huella reproducible.

## v0.25.21

- Corregido el aparente bloqueo de `main` en la fase `[3/4]`.
- El workspace de auditoría deja de duplicar las 354.804 velas dentro de un
  MAT `-v7.3`; conserva una referencia reproducible al CSV y el Dashboard
  recarga el mercado original al abrirse.
- El guardado del workspace es atómico: una interrupción no sobrescribe el
  último archivo válido con un MAT parcial.
- `main` guarda automáticamente eventos, metadatos y el resumen. Los CSV de
  las 24 combinaciones se reservan para `Exportar todo`, evitando docenas de
  escrituras redundantes en MATLAB Drive.
- Los eventos `NEW_BAR`, que replicaban una fila por cada vela del CSV, no se
  vuelven a serializar; se conservan los eventos de sesión y sus conteos.
- La fase 3 muestra tres subpasos para identificar cualquier demora futura.
- Los workspaces antiguos que ya contienen `data` siguen siendo compatibles.

## v0.25.22

- La ventana operable de manipulación de Londres se amplía a `09:00–11:00`
  en hora de Madrid, manteniendo intacto el CRT de `06:00–09:00`.
- La ventana operable de Nueva York pasa a `15:00–17:00`, manteniendo
  intacto el CRT de `12:00–15:00`; los sweeps desde las 15:00 vuelven a ser
  elegibles y el estado de la sesión nace a esa hora.
- El target fijo predeterminado pasa de `1,5R` a `1R`, calculado desde el fill
  real y el stop estructural.
- `SWING_TRAILING_STEP_TARGET` se conserva como gestión alternativa
  independiente, con activación en `1,5R` y escalones de `0,5R`.
- El timeline de auditoría incluye ahora todas las barras relevantes hasta
  las 17:00.
- Añadidas regresiones para los límites de ambas ventanas, señales durante
  la segunda hora y coexistencia de TP fijo 1R con trailing.

## v0.25.23

- La conexión Python detecta automáticamente IB Gateway o TWS cuando el
  puerto guardado en `settings.yaml` no está disponible.
- Se verifican los puertos estándar `4001`, `4002`, `7496` y `7497`, pero un
  puerto solo se acepta tras completar el saludo de la API de IBKR.
- El puerto configurado conserva la máxima prioridad para evitar saltos
  silenciosos entre LIVE y PAPER cuando hay dos aplicaciones abiertas.
- El puerto elegido solo se actualiza en memoria; el archivo de configuración
  del usuario no se modifica.
- El log identifica aplicación, entorno, host, puerto y `clientId` antes de
  resolver el contrato.
- Añadida una regresión Python para el orden, deduplicación y etiquetado de los
  puertos candidatos.

## v0.25.24

- Eliminado el sondeo TCP preliminar introducido en v0.25.23: abría una
  conexión sin protocolo antes del cliente IBKR y podía interferir con la
  autorización o el saludo inicial de Gateway.
- Cada puerto candidato se prueba ahora directamente mediante la API de IBKR.
- Los puertos cerrados continúan descartándose automáticamente mediante el
  error de conexión inmediato del sistema operativo.
- Se mantiene la prioridad del puerto configurado y la identificación
  Gateway/TWS y LIVE/PAPER.
- No se modifican históricos, reglas de estrategia ni resultados.

## v0.25.20

- Corregido el aparente bloqueo de `main` al construir los rangos CRT 3H.
- Las ventanas diarias se indexan ahora sobre las velas del propio día; se
  elimina el recorrido completo del histórico para cada fecha.
- Los 24 escenarios reutilizan BarData ya canónico y dejan de ordenar/copiar
  las 354.804 velas antes de cada backtest independiente.
- `main` muestra cuatro fases y cada escenario informa su progreso para
  distinguir trabajo activo de un bloqueo real.
- Añadida una regresión que impide recuperar la búsqueda O(días x velas).
- Auditada la caché gratuita de Forex Factory aportada para el filtro macro.
  Se registra como fuente pendiente, pero no se activa el filtro porque el
  calendario termina el 07/04/2025, el mercado empieza el 31/07/2025 y parte
  de las horas Tier 1 están registradas como 00:00 de forma incorrecta.

## v0.25.18

- Corregido Research para trades con gestión
  `SWING_TRAILING_STEP_TARGET` que terminan antes de crear el primer escalón
  de TP. El array vacío de timestamps ya no se concatena con fechas zonadas.
- Entrada, salida y series temporales dinámicas se alinean antes de construir
  los tramos de TP y trailing stop.
- Añadida una regresión gráfica para el caso exacto: trade ejecutado, fechas
  con `TimeZone` y cero escalones de target.

## v0.25.17

- Añadida la gestión alternativa `SWING_TRAILING_STEP_TARGET` para CRT 3H.
- Al tocar 1,5R, el TP virtual avanza a 2R; después progresa en escalones
  de 0,5R. Cada barra puede confirmar como máximo un nuevo escalón.
- El trailing stop usa pivotes estrictos de 2 velas a cada lado y se coloca
  un tick por detrás del swing: bajo el swing low en largos y sobre el swing
  high en cortos.
- Los cambios de TP y stop entran en vigor desde la vela siguiente y el stop
  nunca retrocede ni empeora el break-even ya activo.
- Una salida estructural se registra como `TRAILING_STOP`, separada de
  `STOP`, `BREAKEVEN` y `TARGET`.
- El Dashboard incorpora el selector `Exit` y Research dibuja los escalones
  de TP y los tramos del stop estructural.
- La versión de TP fijo 1,5R permanece como baseline predeterminado.
- Se ejecutan 24 combinaciones independientes: tres perfiles, cuatro
  políticas Londres/NY y dos gestiones de salida.
