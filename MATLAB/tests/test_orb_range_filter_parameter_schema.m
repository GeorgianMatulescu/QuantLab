clear;
clc;

matlabRoot = fileparts(fileparts(mfilename('fullpath')));
addpath(genpath(matlabRoot));

cfg = loadQuantLabConfig(matlabRoot);
schema = getOptimizableParameterSchema( ...
    buildORBParameterSchema());

assert(any(schema.name=="orb.filters.minimumRangePoints"));
assert(any(schema.name=="orb.filters.maximumRangePoints"));

minimumRow = schema( ...
    schema.name=="orb.filters.minimumRangePoints",:);

assert(minimumRow.sweep_start==0);
assert(minimumRow.sweep_stop==80);
assert(minimumRow.step==5);

parameterSet = table( ...
    ["orb.rewardRisk"; ...
     "orb.filters.minimumRangePoints"], ...
    [8;35], ...
    'VariableNames',{'name','value'});

trialCfg = applyOptimizationParameters(cfg,parameterSet);

assert(trialCfg.orb.rewardRisk==8);
assert(trialCfg.orb.filters.minimumRangePoints==35);
assert(cfg.orb.filters.minimumRangePoints==0);

fprintf("TEST ORB RANGE FILTER PARAMETER SCHEMA SUPERADO\n");
