clear;
clc;

matlabRoot = fileparts(fileparts(mfilename('fullpath')));
addpath(genpath(matlabRoot));

S = loadAuditWorkspace(matlabRoot,"ORB");
profiles = getDashboardProfiles(S.results);
scenario = getDashboardScenario(S.results,profiles(1));

trades = scenario.trades;
index = find(trades.valid,1,"first");
tradeRow = trades(index,:);

context = calculateSessionContextFeatures(S.data,tradeRow);
lines = buildTradeFeatureLines(tradeRow,context);

assert(isstruct(context));
assert(isfield(context,"gap_pct"));
assert(isfield(context,"atr14_points"));
assert(isfield(context,"trend_day"));
assert(isstring(lines));
assert(size(lines,2)==1);

chartSource = fileread(fullfile( ...
    matlabRoot,"Dashboard","Components", ...
    "plotTradeSessionChart.m"));

assert(contains(chartSource,"drawSeparatedLevel"));
assert(contains(chartSource,"labelOffset"));

fprintf("TEST TRADE CONTEXT FEATURES SUPERADO\n");
fprintf("Gap: %.3f %%\n",context.gap_pct);
fprintf("ATR14: %.2f puntos\n",context.atr14_points);
