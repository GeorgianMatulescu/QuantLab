clear;
clc;

matlabRoot = fileparts(fileparts(mfilename('fullpath')));
addpath(genpath(matlabRoot));

S = loadAuditWorkspace(matlabRoot,"ORB");
profiles = getDashboardProfiles(S.results);
assert(~isempty(profiles));

scenario = getDashboardScenario(S.results,profiles(1));
metrics = calculateDashboardMetrics( ...
    scenario.trades,S.cfg.risk.initialEquityUSD);

assert(metrics.executedTrades + metrics.skippedTrades == metrics.totalRows);

equity = buildEquitySeries( ...
    scenario.trades,S.cfg.risk.initialEquityUSD);
assert(istable(equity));

fprintf("TEST DASHBOARD ADAPTERS SUPERADO\n");
fprintf("Perfiles: %d\n",numel(profiles));
