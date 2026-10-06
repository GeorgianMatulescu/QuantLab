clear;
clc;

matlabRoot = fileparts(fileparts(mfilename('fullpath')));
addpath(genpath(matlabRoot));

palette = getQuantLabPalette();

assert(max(abs( ...
    palette.parameterStability - ...
    [0.4940 0.1840 0.5560]))<1e-12);

assert(max(abs( ...
    palette.wfRobustness - ...
    [0.8500 0.3250 0.0980]))<1e-12);

source = fileread(fullfile( ...
    matlabRoot,"Dashboard","Components", ...
    "updateWalkForwardDashboard.m"));

assert(contains(source,'"Color",metricColor'));
assert(contains(source,'"Color",palette.wfRobustness'));

fprintf("TEST WALK FORWARD STABILITY FIXED COLORS SUPERADO\n");
