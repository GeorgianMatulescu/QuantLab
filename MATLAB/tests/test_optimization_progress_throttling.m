clear;
clc;

matlabRoot = fileparts(fileparts(mfilename('fullpath')));
source = fileread(fullfile( ...
    matlabRoot,"Core","Optimization", ...
    "runParameterSweep.m"));

dashboardSource = fileread(fullfile( ...
    matlabRoot,"Dashboard", ...
    "launchQuantLabDashboard.m"));

assert(contains(source,"progressStride"));
assert(contains(source,"progressIntervalSeconds"));
assert(contains(source,"shouldReport"));

assert(contains(dashboardSource, ...
    "Preparing reusable context"));
assert(contains(dashboardSource, ...
    "optimizationPreparedCache"));
assert(contains(dashboardSource, ...
    "drawnow limitrate"));

fprintf("TEST OPTIMIZATION PROGRESS THROTTLING SUPERADO\n");
