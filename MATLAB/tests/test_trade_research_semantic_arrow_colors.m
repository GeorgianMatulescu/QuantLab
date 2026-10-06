clear;
clc;

matlabRoot = fileparts(fileparts(mfilename('fullpath')));
addpath(genpath(matlabRoot));

tolerance = 1e-12;

entryColor = resolveResearchExecutionMarkerColor("ENTRY","");
targetColor = resolveResearchExecutionMarkerColor("EXIT","TARGET");
stopColor = resolveResearchExecutionMarkerColor("EXIT","STOP");
breakEvenColor = resolveResearchExecutionMarkerColor("EXIT","BREAKEVEN");
trailingColor = resolveResearchExecutionMarkerColor("EXIT","TRAILING_STOP");
eodColor = resolveResearchExecutionMarkerColor("EXIT","EOD");

assert(max(abs(entryColor-[0.00 0.4470 0.7410]))<tolerance);
assert(max(abs(targetColor-[0.10 0.60 0.20]))<tolerance);
assert(max(abs(stopColor-[0.85 0.10 0.10]))<tolerance);
assert(max(abs(breakEvenColor-[0.40 0.40 0.40]))<tolerance);
assert(max(abs(trailingColor-[0.4940 0.1840 0.5560]))<tolerance);
assert(max(abs(eodColor-[0.95 0.45 0.05]))<tolerance);

chartFile = fullfile( ...
    matlabRoot, ...
    "Dashboard", ...
    "Components", ...
    "plotTradeSessionChart.m");
source = fileread(chartFile);

assert(contains(source,'getEntrySide(direction)'));
assert(contains(source,'getExitSide(direction)'));
assert(contains(source,'"ENTRY",""'));
assert(contains(source,'"EXIT",exitReason'));
assert(~contains(source,'buyColor'));
assert(~contains(source,'sellColor'));

fprintf("TEST TRADE RESEARCH SEMANTIC ARROW COLORS SUPERADO\n");
