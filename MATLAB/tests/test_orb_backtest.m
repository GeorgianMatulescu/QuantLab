clear;
clc;

matlabRoot = fileparts(fileparts(mfilename('fullpath')));
addpath(genpath(matlabRoot));

cfg = loadQuantLabConfig(matlabRoot);
[T, ~] = loadMarketData(cfg.dataFile, cfg);
daily = buildDailySessions(T, cfg);

[trades, summary] = runORBBacktest(T, daily, cfg);

assert(~isempty(trades), "No se ha generado ninguna operación.");
assert(height(trades) <= height(daily), ...
    "Se ha generado más de una operación por sesión.");
assert(all(trades.risk_points > 0), ...
    "Existe una operación con riesgo no positivo.");
assert(all(isfinite(trades.net_R)), ...
    "Existen resultados R no finitos.");
assert(all(ismember(trades.exit_reason, ["STOP","TARGET","EOD"])), ...
    "Existe un motivo de salida desconocido.");
assert(summary.totalTrades == height(trades));

fprintf("TEST ORB SUPERADO\n");
fprintf("Operaciones: %d\n", summary.totalTrades);
fprintf("Win rate: %.2f %%\n", summary.winRatePct);
fprintf("Net R: %.2f\n", summary.netR);
fprintf("Profit Factor: %.3f\n", summary.profitFactor);
fprintf("Max Drawdown: %.2f R\n", summary.maxDrawdownR);
