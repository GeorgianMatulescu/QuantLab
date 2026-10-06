clear;
clc;

matlabRoot = fileparts(fileparts(mfilename('fullpath')));
addpath(genpath(matlabRoot));

cfg = loadQuantLabConfig(matlabRoot);
[data, ~] = loadMarketData(cfg.dataFile, cfg);

plugin = resolveStrategyPlugin("ORB");
assert(plugin.name == "ORB");
assert(isa(plugin.run, "function_handle"));
assert(isa(plugin.buildEvents, "function_handle"));

output = runStrategy("ORB", data, cfg);

assert(output.strategy == "ORB");
assert(istable(output.events));
assert(~isempty(output.events));
assert(isfield(output.results, "summaryTable"));
assert(isfield(output.results, "event_summary"));

requiredTypes = [ ...
    "NEW_SESSION","NEW_BAR","ORB_COMPLETED","SESSION_CLOSED"];
actualTypes = unique(string(output.events.event_type));
assert(all(ismember(requiredTypes, actualTypes)));

newBars = filterEvents(output.events, "NEW_BAR");
assert(height(newBars) == height(data));

orbEvents = filterEvents(output.events, "ORB_COMPLETED");
assert(height(orbEvents) == nnz(output.daily.orb_valid));

fprintf("TEST STRATEGY FRAMEWORK SUPERADO\n");
fprintf("Eventos totales: %d\n", height(output.events));
fprintf("NEW_BAR: %d\n", height(newBars));
fprintf("ORB_COMPLETED: %d\n", height(orbEvents));
