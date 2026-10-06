clear;
clc;

matlabRoot = fileparts(fileparts(mfilename('fullpath')));
addpath(genpath(matlabRoot));

S = loadAuditWorkspace(matlabRoot,"ORB");
plugin = resolveStrategyPlugin("ORB");

assert(isfield(plugin,"runProfile"));
assert(isa(plugin.runProfile,"function_handle"));

schema = getOptimizableParameterSchema( ...
    buildORBParameterSchema());
selected = schema(schema.name=="orb.rewardRisk",:);

prepared = prepareStrategyOptimization( ...
    "ORB",S.data,S.cfg,selected);

assert(prepared.use_prepared_context);
assert(isfield(prepared.context,"session_data"));
assert(numel(prepared.context.session_data)== ...
    height(prepared.context.daily));

parameterSet = table( ...
    "orb.rewardRisk",5, ...
    'VariableNames',{'name','value'});

fastMetrics = runStrategyOptimizationCombination( ...
    "ORB",S.data,S.cfg,parameterSet, ...
    "REALISTIC",70,prepared);

trialCfg = applyOptimizationParameters( ...
    S.cfg,parameterSet);
fullOutput = runStrategy("ORB",S.data,trialCfg);
scenario = getDashboardScenario( ...
    fullOutput.results,"REALISTIC");
fullMetrics = calculateOptimizationMetrics( ...
    scenario,trialCfg,70);

assert(abs( ...
    fastMetrics.net_pnl_usd - ...
    fullMetrics.net_pnl_usd)<1e-9);

assert(abs( ...
    fastMetrics.expectancy_r - ...
    fullMetrics.expectancy_r)<1e-12);

fprintf("TEST ORB OPTIMIZATION FAST PATH SUPERADO\n");
