clear;
clc;

matlabRoot = fileparts(fileparts(mfilename('fullpath')));
source = fileread(fullfile( ...
    matlabRoot,"Dashboard","launchQuantLabDashboard.m"));

assert(contains(source,'"Title","Segment Explorer"'));
assert(contains(source,"updateSegmentFeatureSelector("));
assert(contains(source,"safeRefreshSegmentExplorer()"));
assert(contains(source,'"segmentDirty",true'));
assert(contains(source,"updateSegmentExplorerDashboard("));

segmentSource = fileread(fullfile( ...
    matlabRoot,"Dashboard","Components", ...
    "updateSegmentExplorerDashboard.m"));

assert(~contains(lower(segmentSource),"orb_range"));
assert(contains(segmentSource,"rankStrategyFeatures("));
assert(contains(segmentSource,"analyzeStrategySegments("));

fprintf("TEST DASHBOARD GENERIC SEGMENT INTEGRATION SUPERADO\n");
