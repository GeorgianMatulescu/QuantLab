clear;
clc;

matlabRoot = fileparts(fileparts(mfilename('fullpath')));
source = fileread(fullfile( ...
    matlabRoot,"Dashboard", ...
    "launchQuantLabDashboard.m"));

assert(contains(source, ...
    'optimizationTab = uitab(leftTabs,"Title","Optimization")'));
assert(contains(source,"Run Full Grid"));
assert(contains(source,"runParameterSweep("));
assert(contains(source,"prepareStrategyOptimization("));
assert(contains(source,"saveOptimizationResults("));
assert(contains(source,'"OptimizationTab",optimizationTab'));

analyticsSection = extractBetween( ...
    source,"%% Analytics","%% Calendar & Rolling Analytics");

assert(~contains(analyticsSection,'"Title","Optimization"'), ...
    "Optimization debe ser una pestaña principal separada.");

fprintf("TEST DASHBOARD SEPARATE OPTIMIZATION TAB SUPERADO\n");
