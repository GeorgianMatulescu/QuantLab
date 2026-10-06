# QuantLab Strategy SDK Quickstart

From `QuantLab/MATLAB`:

```matlab
createBarStrategyScaffold("MyStrategy","My Strategy")
rehash
listStrategies()
```

Edit only the generated folder under `MATLAB/Strategies/MyStrategy`.
Keep strategy rules, filters, features and parameters inside the plugin.
Do not add strategy-specific conditions to `Core`, `Dashboard`, `Research`
or `Optimization`.

Set the active plugin in `Config/loadQuantLabConfig.m`:

```matlab
cfg.strategyName = "MYSTRATEGY";
```

Then run:

```matlab
main
launch_dashboard
```
