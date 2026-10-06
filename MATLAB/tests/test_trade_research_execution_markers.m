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

assert(contains(source,'"^"'));
assert(contains(source,'"v"'));
assert(contains(source,'entryMarkerColor = resolveResearchExecutionMarkerColor'));
assert(contains(source,'exitMarkerColor = resolveResearchExecutionMarkerColor'));
assert(contains(source,'"ENTRY",""'));
assert(contains(source,'"EXIT",exitReason'));
assert(contains(source,'"MarkerFaceColor",markerColor'));
assert(contains(source,'"MarkerEdgeColor",markerColor'));
assert(contains(source,'"orb_high","ORB High","--"'));
assert(contains(source,'"orb_low","ORB Low","--"'));
assert(contains(source,'"target_price","Target","-"'));
assert(contains(source,'"stop_price","Stop","-"'));
assert(contains(source,'"entry_price","Entrada","-"'));
assert(contains(source,'"exit_price","Salida EOD","-"'));
assert(contains(source,'getEntrySide(direction)'));
assert(contains(source,'getExitSide(direction)'));

fprintf("TEST TRADE RESEARCH EXECUTION MARKERS SUPERADO\n");
