clear;
clc;

matlabRoot = fileparts(fileparts(mfilename('fullpath')));
addpath(genpath(matlabRoot));

S = loadAuditWorkspace(matlabRoot,"ORB");

strategyRun = buildStrategyResult( ...
    "ORB",S.results,S.cfg,S.data);

validateStrategyResult(strategyRun);

assert(isfield(strategyRun,"feature_catalog"));
assert(isfield(strategyRun,"parameter_schema"));
assert(isfield(strategyRun,"analysis_capabilities"));

catalog = strategyRun.feature_catalog;

assert(any(catalog.name=="orb_range_points"));
assert(any(catalog.name=="direction"));
assert(strategyRun.analysis_capabilities.segment_explorer);

fprintf("TEST STRATEGY RESEARCH SCHEMA SUPERADO\n");
fprintf("Features registradas: %d\n",height(catalog));
fprintf("Parámetros registrados: %d\n", ...
    height(strategyRun.parameter_schema));
