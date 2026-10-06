# QuantLab v0.6 — Market State Foundation

Implementado:

- Data Dictionary central.
- MarketState estándar.
- MarketState Engine barra a barra.
- Event Timeline.
- Swing Detector confirmado 2+2.
- Pruebas anti-look-ahead.
- Exportación de snapshots y eventos.

Todavía no incluye BOS, CHOCH, HH/HL/LH/LL, FVG, sweeps ni CRT.

## Ejecución

```matlab
main
run_market_state_demo
```

## Tests

```matlab
run("tests/test_data_dictionary.m")
run("tests/test_swing_detector.m")
run("tests/test_market_state_engine.m")
```
