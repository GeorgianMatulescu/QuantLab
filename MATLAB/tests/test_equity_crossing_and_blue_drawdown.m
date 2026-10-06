clear;
clc;

matlabRoot = fileparts(fileparts(mfilename('fullpath')));
addpath(genpath(matlabRoot));

equitySource = fileread(fullfile( ...
    matlabRoot,"Dashboard","Components", ...
    "updateEquityCharts.m"));

drawdownSource = fileread(fullfile( ...
    matlabRoot,"Dashboard","Components", ...
    "updateDrawdownChart.m"));

assert(contains(equitySource,"plotSignedEquityLine"));
assert(contains(equitySource,"crossTime"));
assert(contains(equitySource,"plotSegment"));
assert(~contains(equitySource,"positiveLine(positiveLine<0) = NaN"));

assert(contains(drawdownSource, ...
    "blueLine = [0.00 0.4470 0.7410]"));

assert(contains(drawdownSource, ...
    "blueFill = [0.60 0.78 0.93]"));

assert(contains(drawdownSource, ...
    "ylim(drawdownAxes,[lowerLimit 0])"));

fprintf("TEST EQUITY CROSSING AND BLUE DRAWDOWN SUPERADO\n");
