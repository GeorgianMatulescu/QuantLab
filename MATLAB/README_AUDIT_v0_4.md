# QuantLab v0.4 — Audit, Visualization & Replay

Este módulo es genérico y reutilizable para cualquier estrategia.

## Interfaz esperada para una estrategia

La estrategia debe devolver:

```matlab
results.<PROFILE>.trades
results.<PROFILE>.summary
results.summaryTable
```

Cada tabla `trades` debe incluir, como mínimo:

- `session_date`
- `valid`
- `skip_reason`
- `direction`
- `entry_time`
- `exit_time`
- `entry_price`
- `stop_price`
- `target_price`
- `exit_price`
- `exit_reason`
- `net_R`
- `net_pnl_usd`
- `equity_before_usd`
- `equity_after_usd`

La ORB ya cumple esta interfaz. CRT, PowerOf3, FVG y FlyFlyer podrán usar las mismas herramientas sin modificar el módulo de auditoría.

## Herramientas

```matlab
inspectTrade(results, 1, "REALISTIC")
compareTradeScenarios(results, 1, "REALISTIC")
plotTradeAudit(data, results, 1, "REALISTIC")
plotSessionAudit(data, results, "2025-10-15", "REALISTIC")
plotEquityCurve(results, "REALISTIC", cfg.risk.initialEquityUSD)
replayTrade(data, results, 1, "REALISTIC", 0.03)
```

## Ejecución

1. Copia la carpeta `MATLAB` sobre `QuantLab/MATLAB`.
2. Acepta reemplazar.
3. Ejecuta `main`.
4. Ejecuta:

```matlab
run("tests/test_audit_generic.m")
```
