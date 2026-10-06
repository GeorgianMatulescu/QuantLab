clear;
clc;

matlabRoot = fileparts(fileparts(mfilename('fullpath')));

fullGridSource = fileread(fullfile( ...
    matlabRoot,"Dashboard","Components", ...
    "buildOptimizationDisplayTable.m"));

walkForwardSource = fileread(fullfile( ...
    matlabRoot,"Dashboard","Components", ...
    "buildWalkForwardAggregateDisplayTable.m"));

optimizerSource = fileread(fullfile( ...
    matlabRoot,"Core","Optimization", ...
    "runParameterSweep.m"));

assert(contains(fullGridSource,"'Activity'"));
assert(contains(fullGridSource,"'Equivalent'"));
assert(contains(fullGridSource,"'TargetHits'"));

assert(contains(walkForwardSource,"'Activity'"));
assert(contains(walkForwardSource,"'OOSTargetHits'"));
assert(contains(walkForwardSource,"'EffectiveOOSWindows'"));

assert(contains(optimizerSource,"annotateParameterActivity"));

fprintf("TEST OPTIMIZATION ACTIVITY DASHBOARD INTEGRATION SUPERADO\n");
