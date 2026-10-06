# QuantLab v0.5 — Strategy Framework & Event Engine

## Cambio principal

ORB deja de ser una estrategia especial del motor. Ahora se ejecuta como plugin:

```matlab
output = runStrategy("ORB", data, cfg);
```

El mismo punto de entrada servirá para:

```matlab
runStrategy("CRT", data, cfg)
runStrategy("POWEROF3", data, cfg)
runStrategy("FVG", data, cfg)
runStrategy("FLYFLYER", data, cfg)
```

cuando estén implementadas.

## Event Engine v1

Eventos disponibles:

- `NEW_SESSION`
- `NEW_BAR`
- `ORB_COMPLETED`
- `SESSION_CLOSED`

Todos siguen un esquema común:

- `event_type`
- `event_time`
- `session_date`
- `symbol`
- `bar_index`
- `price`
- `direction`
- `source`
- `payload`

## Registro de estrategias

```matlab
listStrategies()
```

## Pruebas

```matlab
run("tests/test_event_engine.m")
run("tests/test_strategy_framework.m")
run("tests/test_execution_risk.m")
run("tests/test_audit_generic.m")
```

## Próximos detectores

La carpeta `Core/Detectors` recibirá:

- SwingDetector
- FVGDetector
- BOSDetector
- CHOCHDetector
- LiquiditySweepDetector

No se han implementado todavía porque sus reglas necesitan definiciones exactas y pruebas independientes.
