clear;
clc;

matlabRoot = fileparts(fileparts(mfilename('fullpath')));
addpath(genpath(matlabRoot));

cfg = loadQuantLabConfig(matlabRoot);
[data, ~] = loadMarketData(cfg.dataFile, cfg);
daily = buildDailySessions(data, cfg);
results = runORBScenarioComparison(data, daily, cfg);

trades = getScenarioTrades(results, "REALISTIC");
assert(~isempty(trades));

[row, idx] = resolveTradeSelector(trades, 1);
assert(idx == 1);
assert(height(row) == 1);

comparison = compareTradeScenarios(results, 1, "REALISTIC");
assert(~isempty(comparison));
assert(ismember("profile", string(comparison.Properties.VariableNames)));

filePath = saveAuditWorkspace(data, daily, results, cfg, "ORB");
assert(isfile(filePath));

S = loadAuditWorkspace(matlabRoot, "ORB");
assert(isfield(S, "data"));
assert(isfield(S, "results"));
assert(isfield(S, "cfg"));

fprintf("TEST AUDIT GENERICO SUPERADO\n");
fprintf("Perfiles comparados: %d\n", height(comparison));
fprintf("Workspace: %s\n", filePath);
