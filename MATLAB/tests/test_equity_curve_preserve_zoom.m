clear;
clc;

matlabRoot = fileparts(fileparts(mfilename('fullpath')));
addpath(genpath(matlabRoot));

source = fileread(fullfile( ...
    matlabRoot,"Dashboard","Components", ...
    "updateEquityCharts.m"));

assert(contains(source,"cla(equityAxes);"));
assert(~contains(source,'cla(equityAxes,"reset")'));
assert(~contains(source,"xlim(equityAxes"));
assert(contains(source,"insertZeroCrossings"));

fprintf("TEST EQUITY CURVE PRESERVE ZOOM SUPERADO\n");
