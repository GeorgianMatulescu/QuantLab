clear; clc;
matlabRoot = fileparts(fileparts(mfilename('fullpath')));
addpath(genpath(matlabRoot));

S = loadAuditWorkspace(matlabRoot,"ORB");
cfg = S.cfg;
cfg.instrumentSpec = normalizeInstrumentSpec(cfg);
cfg.sessionSpec = normalizeSessionSpec(cfg);
cfg.emaCross = loadQuantLabConfig(matlabRoot).emaCross;

output = runStrategy("EMA_CROSS",S.data,cfg);
assert(isfield(output.results,"REALISTIC"));
trades = output.results.REALISTIC.trades;

if ~isempty(trades)
    required = ["quantity","signal_name","fast_ema","slow_ema", ...
        "atr_points","net_R","net_pnl_usd"];
    assert(all(ismember(required,string(trades.Properties.VariableNames))));
    validateStrategyTradeTable(trades,"EMA_CROSS","REALISTIC");
end

fprintf("TEST EMA CROSS STRATEGY SMOKE SUPERADO\n");
fprintf("EMA trades: %d\n",height(trades));
