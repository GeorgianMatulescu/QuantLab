clear;
clc;

matlabRoot = fileparts(fileparts(mfilename('fullpath')));
addpath(genpath(matlabRoot));

dashboardSource = fileread(fullfile( ...
    matlabRoot,"Dashboard","launchQuantLabDashboard.m"));

assert(contains(dashboardSource, ...
    "dashboardState.selectedTradeIndex = rowIndex;"));

assert(contains(dashboardSource, ...
    "dashboardState.selectedTradeIndex = NaN;"));

assert(contains(dashboardSource, ...
    "showTradeResearchError("));

assert(contains(dashboardSource, ...
    "drawnow limitrate nocallbacks"));

loadingSource = fileread(fullfile( ...
    matlabRoot,"Dashboard","Components", ...
    "showTradeResearchLoading.m"));

assert(~contains(loadingSource,"resetResearchAxes"));
assert(contains(loadingSource,"nocallbacks"));

lookupSource = fileread(fullfile( ...
    matlabRoot,"Dashboard","Components", ...
    "getCachedTradeResearchData.m"));

assert(contains(lookupSource,"makeDateKey"));
assert(~contains(lookupSource,"cache.sessionDates==tradeDate"));

fprintf("TEST TRADE RESEARCH CALLBACK RECOVERY SUPERADO\n");
