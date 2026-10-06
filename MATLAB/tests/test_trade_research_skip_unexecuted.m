clear;
clc;

matlabRoot = fileparts(fileparts(mfilename('fullpath')));
addpath(genpath(matlabRoot));

source = fileread(fullfile( ...
    matlabRoot,"Dashboard","Components", ...
    "plotTradeSessionChart.m"));

assert(contains(source,"executedTrade = isExecutedTrade(tradeRow)"));
assert(contains(source,"if executedTrade"));
assert(contains(source,"contracts>0"));
assert(contains(source,"NO EJECUTADO"));

fprintf("TEST TRADE RESEARCH SKIP UNEXECUTED SUPERADO\n");
