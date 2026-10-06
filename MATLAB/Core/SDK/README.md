# QuantLab Generic Bar Strategy SDK v1

QuantLab discovers strategies automatically using this convention:

```text
Strategies/MyStrategy/createMyStrategyStrategy.m
```

Create a new plugin with:

```matlab
createBarStrategyScaffold("MyStrategy","My Strategy")
rehash
listStrategies()
```

A plugin declares its market compatibility, data columns, event builder,
runner, features, parameters and capabilities. QuantLab Core, Dashboard,
Full Grid and Walk-Forward do not contain strategy-specific rules.

The initial supported asset classes are:

- FUTURE
- STOCK
- FOREX
- CRYPTO

The v1 data contract is OHLCV bars. Account currency must currently match
the instrument quote currency.
