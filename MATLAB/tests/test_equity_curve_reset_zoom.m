clear;
clc;

matlabRoot = fileparts(fileparts(mfilename('fullpath')));
addpath(genpath(matlabRoot));

source = fileread(fullfile( ...
    matlabRoot,"Dashboard","Components", ...
    "updateEquityCharts.m"));

assert(contains(source,'cla(equityAxes,"reset")'));
assert(contains(source,'cla(returnAxes,"reset")'));
assert(contains(source,'xlim(equityAxes,[plotDates(1) plotDates(end)])'));
assert(contains(source,"insertZeroCrossings"));

fprintf("TEST EQUITY CURVE RESET ZOOM SUPERADO\n");
