clear;
clc;

matlabRoot = fileparts(fileparts(mfilename('fullpath')));
addpath(genpath(matlabRoot));

cfg = loadQuantLabConfig(matlabRoot);
schema = buildORBParameterSchema();
schema = getOptimizableParameterSchema(schema);

assert(any(schema.name=="orb.rewardRisk"));
assert(any(schema.name=="risk.percentRisk"));
assert(any(schema.name=="risk.maximumContracts"));
assert(~any(schema.name=="risk.fixedRiskUSD"));
maximumContractsRow = schema.name=="risk.maximumContracts";
assert(schema.default_value(maximumContractsRow)==40);

parameterSet = table( ...
    ["orb.rewardRisk";"risk.percentRisk"], ...
    [5;0.02], ...
    'VariableNames',{'name','value'});

trialCfg = applyOptimizationParameters( ...
    cfg,parameterSet);

assert(trialCfg.orb.rewardRisk==5);
assert(trialCfg.risk.percentRisk==0.02);
assert(cfg.orb.rewardRisk==10);
assert(cfg.risk.percentRisk==0.01);

selected = schema( ...
    ismember(schema.name,parameterSet.name),:);

preparedFlag = any(selected.rebuild_events);
assert(~preparedFlag, ...
    "Los parámetros seleccionados no deben reconstruir eventos.");

fprintf("TEST ORB OPTIMIZATION PARAMETER SCHEMA SUPERADO\n");
