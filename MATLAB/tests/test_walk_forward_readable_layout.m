clear;
clc;

matlabRoot = fileparts(fileparts(mfilename('fullpath')));
source = fileread(fullfile( ...
    matlabRoot,"Dashboard","launchQuantLabDashboard.m"));

assert(contains(source, ...
    'walkForwardControlsPanel,[5 1]'));
assert(contains(source, ...
    'walkForwardRoot.RowHeight = {238,"1x","1.15x"}'));
assert(contains(source,'"Train sessions:"'));
assert(contains(source,'"OOS sessions:"'));
assert(contains(source,'"Step sessions:"'));
assert(contains(source,"wfParameter1Row"));
assert(contains(source,"wfParameter2Row"));
assert(contains(source,"wfStatusRow"));

fprintf("TEST WALK FORWARD READABLE LAYOUT SUPERADO\n");
