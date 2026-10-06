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

assert(contains(source,'stopColor = [0.85 0.10 0.10]'));
assert(contains(source,'targetColor = [0.10 0.60 0.20]'));
assert(contains(source,'entryColor = [0.00 0.4470 0.7410]'));
assert(contains(source,'eodColor = [0.95 0.45 0.05]'));
assert(contains(source,'breakEvenColor = [0.40 0.40 0.40]'));

assert(contains(source,'"target_price","Target","-"'));
assert(contains(source,'targetColor,0.8'));
assert(contains(source,'"stop_price","Stop","-"'));
assert(contains(source,'stopColor,0.8'));
assert(contains(source,'"entry_price","Entrada","-"'));
assert(contains(source,'entryColor,0.9'));
assert(contains(source,'if exitReason=="EOD"'));
assert(contains(source,'"exit_price","Salida EOD","-"'));
assert(contains(source,'eodColor,0.9'));
assert(contains(source,'drawBreakEvenLevel('));
assert(contains(source,'"Break-even","--"'));

assert(~contains(source,'protectiveLevelColor'));
assert(contains(source,'drawTradeConnection(ax,tradeRow)'));
assert(contains(source,'getEntrySide(direction)'));
assert(contains(source,'getExitSide(direction)'));

fprintf("TEST TRADE RESEARCH SEMANTIC LEVEL COLORS SUPERADO\n");
