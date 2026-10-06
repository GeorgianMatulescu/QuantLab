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

assert(contains(source,'leftLevelLabelX = xStart+xSpan*0.02'));

targetBlock = extractBetween(source, ...
    '"target_price","Target","-"', ...
    'priceRange*0.018);');
stopBlock = extractBetween(source, ...
    '"stop_price","Stop","-"', ...
    '-priceRange*0.022);');
entryBlock = extractBetween(source, ...
    '"entry_price","Entrada","-"', ...
    'priceRange*0.018);');

assert(numel(targetBlock)==1 && contains(targetBlock,'leftLevelLabelX'));
assert(numel(stopBlock)==1 && contains(stopBlock,'leftLevelLabelX'));
assert(numel(entryBlock)==1 && contains(entryBlock,'leftLevelLabelX'));

assert(~contains(targetBlock,'xStart+xSpan*0.90'));
assert(~contains(stopBlock,'xStart+xSpan*0.88'));
assert(~contains(entryBlock,'xStart+xSpan*0.72'));

fprintf("TEST TRADE RESEARCH LEFT LEVEL LABELS SUPERADO\n");
