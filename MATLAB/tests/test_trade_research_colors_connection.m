clear;
clc;

matlabRoot = fileparts(fileparts(mfilename('fullpath')));
addpath(genpath(matlabRoot));

chartFile = fullfile( ...
    matlabRoot, ...
    "Dashboard", ...
    "Components", ...
    "plotTradeSessionChart.m");

source = fileread(chartFile);

assert(contains(source, ...
    'stopColor = [0.85 0.10 0.10]'));

assert(contains(source, ...
    'targetColor = [0.10 0.60 0.20]'));

assert(contains(source, ...
    'entryColor = [0.00 0.4470 0.7410]'));

assert(contains(source, ...
    'eodColor = [0.95 0.45 0.05]'));

assert(contains(source, ...
    '"entry_price","Entrada","-"'));

assert(contains(source, ...
    'if exitReason=="EOD"'));

assert(contains(source, ...
    '"exit_price","Salida EOD","-"'));

assert(contains(source, ...
    'drawTradeConnection(ax,tradeRow)'));

assert(contains(source, ...
    'entryMarkerColor = resolveResearchExecutionMarkerColor'));

assert(contains(source, ...
    'exitMarkerColor = resolveResearchExecutionMarkerColor'));

assert(contains(source,'[entryTime exitTime]'));
assert(contains(source,'[entryPrice exitPrice]'));
assert(contains(source,'"LineWidth",0.75'));

fprintf("TEST TRADE RESEARCH COLORS CONNECTION SUPERADO\n");
