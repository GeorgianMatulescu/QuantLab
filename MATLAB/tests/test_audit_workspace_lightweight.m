clear;
clc;

matlabRoot = fileparts(fileparts(mfilename('fullpath')));
addpath(genpath(matlabRoot));

saveSource = fileread(fullfile( ...
    matlabRoot,"Audit","saveAuditWorkspace.m"));
loadSource = fileread(fullfile( ...
    matlabRoot,"Audit","loadAuditWorkspace.m"));
exportSource = fileread(fullfile( ...
    matlabRoot,"Core","Engine","exportStrategyRun.m"));

assert(~contains(saveSource,'"data","daily","results"'), ...
    "El histórico completo no debe volver a guardarse dentro del MAT.");
assert(contains(saveSource,'"dataReference","auditSchemaVersion","-v7"'));
assert(contains(saveSource,"tempname(reportDir)"));
assert(contains(saveSource,'movefile(temporaryFile,filePath,"f")'));

assert(contains(loadSource,'if ~isfield(S,"data")'));
assert(contains(loadSource,"loadConfiguredMarketData(S.cfg)"));
assert(contains(loadSource,"rebaseConfiguredPaths"));

assert(~contains(exportSource, ...
    "exportScenarioComparison(output.results,cfg,strategyName)"), ...
    "main no debe exportar automáticamente las 24 combinaciones.");
assert(contains(exportSource,"_scenario_summary.csv"));
assert(contains(exportSource,'string(events.event_type)~="NEW_BAR"'));
assert(contains(exportSource,"[3.1/3]"));
assert(contains(exportSource,"[3.3/3]"));

fprintf("TEST AUDIT WORKSPACE LIGHTWEIGHT SUPERADO\n");
