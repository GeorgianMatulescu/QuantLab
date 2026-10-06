clear;
clc;

matlabRoot = fileparts(fileparts(mfilename('fullpath')));
source = fileread(fullfile( ...
    matlabRoot,"Dashboard","launchQuantLabDashboard.m"));

assert(contains(source, ...
    'optimizationControlsPanel,[5 1]'));
assert(contains(source, ...
    'optimizationRoot.RowHeight = {220,"1x","1.10x"}'));
assert(contains(source,"optimizationPlanRow"));
assert(contains(source,"optimizationParameter1Row"));
assert(contains(source,"optimizationParameter2Row"));
assert(contains(source,"optimizationExecutionRow"));
assert(contains(source,"optimizationStatusRow"));
assert(contains(source,'"Primary optimization dimension."'));
assert(contains(source, ...
    '"Select None for a one-dimensional grid."'));

fprintf("TEST FULL GRID READABLE LAYOUT SUPERADO\n");
