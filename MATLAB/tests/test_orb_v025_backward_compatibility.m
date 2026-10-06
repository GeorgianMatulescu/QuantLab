clear; clc;
matlabRoot = fileparts(fileparts(mfilename('fullpath')));
addpath(genpath(matlabRoot));

S = loadAuditWorkspace(matlabRoot,"ORB");
oldScenario = getDashboardScenario(S.results,"REALISTIC");
newOutput = runStrategy("ORB",S.data,S.cfg);
newScenario = getDashboardScenario(newOutput.results,"REALISTIC");

oldPnL = sum(oldScenario.trades.net_pnl_usd,"omitnan");
newPnL = sum(newScenario.trades.net_pnl_usd,"omitnan");
assert(abs(oldPnL-newPnL)<1e-8);
assert(ismember("quantity", ...
    string(newScenario.trades.Properties.VariableNames)));

fprintf("TEST ORB V025 BACKWARD COMPATIBILITY SUPERADO\n");
