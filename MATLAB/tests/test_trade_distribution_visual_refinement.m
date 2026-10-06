clear;
clc;

matlabRoot = fileparts(fileparts(mfilename('fullpath')));
addpath(genpath(matlabRoot));

source = fileread(fullfile( ...
    matlabRoot,"Dashboard","Components", ...
    "updateTradeDistributionDashboard.m"));

assert(contains(source,"buildHistogramEdges"));
assert(contains(source,'"DisplayName","Negativo"'));
assert(contains(source,'"DisplayName","Positivo"'));
assert(contains(source,'"DisplayName","Tendencia"'));
assert(contains(source,"correlationValue"));
assert(contains(source,"rSquared"));
assert(contains(source,"getGroupColor"));
assert(contains(source,"styleTradeDistributionSummaryTable"));

paletteSource = fileread(fullfile( ...
    matlabRoot,"Dashboard","Components", ...
    "getQuantLabPalette.m"));

assert(contains(paletteSource,'"long",[0.00 0.4470 0.7410]'));
assert(contains(paletteSource,'"short",[0.82 0.08 0.08]'));
assert(contains(paletteSource,'"target",[0.00 0.55 0.10]'));
assert(contains(paletteSource,'"eod",[0.93 0.49 0.19]'));

fprintf("TEST TRADE DISTRIBUTION VISUAL REFINEMENT SUPERADO\n");
