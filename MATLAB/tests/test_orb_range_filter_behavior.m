clear;
clc;

matlabRoot = fileparts(fileparts(mfilename('fullpath')));
addpath(genpath(matlabRoot));

S = loadAuditWorkspace(matlabRoot,"ORB");

baseline = runStrategy("ORB",S.data,S.cfg);
baselineScenario = getDashboardScenario( ...
    baseline.results,"REALISTIC");

filteredCfg = S.cfg;
filteredCfg.orb.filters.minimumRangePoints = 50;
filtered = runStrategy("ORB",S.data,filteredCfg);
filteredScenario = getDashboardScenario( ...
    filtered.results,"REALISTIC");

assert(height(filteredScenario.trades)<= ...
    height(baselineScenario.trades));

if ~isempty(filteredScenario.trades)
    assert(all(filteredScenario.trades.orb_range_points>=50));
end

fprintf("TEST ORB RANGE FILTER BEHAVIOR SUPERADO\n");
fprintf("Baseline trades: %d\n",height(baselineScenario.trades));
fprintf("Filtered trades: %d\n",height(filteredScenario.trades));
