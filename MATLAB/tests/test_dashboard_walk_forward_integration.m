clear;
clc;

matlabRoot = fileparts(fileparts(mfilename('fullpath')));
source = fileread(fullfile( ...
    matlabRoot,"Dashboard","launchQuantLabDashboard.m"));

assert(contains(source, ...
    'walkForwardOptimizationTab = uitab'));
assert(contains(source,'"Title","Walk-Forward"'));
assert(contains(source,"runWalkForwardOptimization("));
assert(contains(source,"buildWalkForwardWindows("));
assert(contains(source,"Evaluate final holdout"));
assert(contains(source,"refreshVisibleOptimization()"));
assert(contains(source,"Plateau Score"));

engineSource = fileread(fullfile( ...
    matlabRoot,"Core","Optimization", ...
    "runWalkForwardOptimization.m"));

assert(~contains(lower(engineSource),"orb"), ...
    "El motor walk-forward no debe depender de ORB.");

fprintf("TEST DASHBOARD WALK FORWARD INTEGRATION SUPERADO\n");
