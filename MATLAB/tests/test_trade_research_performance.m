clear;
clc;

matlabRoot = fileparts(fileparts(mfilename('fullpath')));
addpath(genpath(matlabRoot));

S = loadAuditWorkspace(matlabRoot,"ORB");

buildTimer = tic;
cache = buildTradeResearchCache(S.data);
buildSeconds = toc(buildTimer);

assert(cache.valid);
assert(~isempty(cache.sessionDates));
assert(height(cache.contextTable)==numel(cache.sessionDates));

profiles = getDashboardProfiles(S.results);
scenario = getDashboardScenario(S.results,profiles(1));
trades = scenario.trades;

rowIndex = find(trades.valid,1,"first");

if isempty(rowIndex)
    rowIndex = 1;
end

lookupTimer = tic;

[sessionData,context] = getCachedTradeResearchData( ...
    cache,trades(rowIndex,:));

lookupSeconds = toc(lookupTimer);

assert(~isempty(sessionData));
assert(isstruct(context));

plotSource = fileread(fullfile( ...
    matlabRoot,"Dashboard","Components", ...
    "plotTradeSessionChart.m"));

assert(contains(plotSource,"drawOHLCBarsVectorized"));
assert(~contains(plotSource,"for i = 1:height(sessionData)"));

dashboardSource = fileread(fullfile( ...
    matlabRoot,"Dashboard", ...
    "launchQuantLabDashboard.m"));

assert(contains(dashboardSource, ...
    "researchCache = buildTradeResearchCache(strategyRun.data)"));

assert(contains(dashboardSource, ...
    "showTradeResearchLoading("));

fprintf("TEST TRADE RESEARCH PERFORMANCE SUPERADO\n");
fprintf("Construcción de caché: %.3f s\n",buildSeconds);
fprintf("Consulta de una sesión: %.6f s\n",lookupSeconds);
fprintf("Barras recuperadas: %d\n",height(sessionData));
