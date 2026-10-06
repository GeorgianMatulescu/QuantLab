# QuantLab v0.7 — Dashboard

## Incluye

- selector de perfil;
- tarjetas de métricas;
- equity;
- drawdown;
- motivos de salida;
- LONG/SHORT;
- tabla de operaciones;
- distribuciones de PnL y R;
- tabla comparativa de escenarios;
- exportación contextual de datos por pestaña;
- exportación completa estructurada de todos los escenarios;
- captura PNG de la vista visible.

## Uso

```matlab
quantlab
```

El selector permite ejecutar cualquier plugin e instrumento y abrir el
dashboard. `main` y `launch_dashboard` continúan disponibles por compatibilidad.

## Test

```matlab
run("tests/test_dashboard_adapters.m")
```

El dashboard es genérico y usa la interfaz común de resultados.
