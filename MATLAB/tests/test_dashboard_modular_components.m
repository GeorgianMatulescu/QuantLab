clear;
clc;

matlabRoot = fileparts(fileparts(mfilename('fullpath')));
addpath(genpath(matlabRoot));

S = loadAuditWorkspace(matlabRoot,"ORB");
profiles = getDashboardProfiles(S.results);
scenario = getDashboardScenario(S.results,profiles(1));

m = calculateResearchMetrics(scenario.trades,S.cfg);
reportData = buildResearchReportTable(m);

assert(istable(reportData));
assert(height(reportData)==13);
assert(isequal(reportData.Properties.VariableNames, ...
    {'Metric','Value','Metric2','Value2'}));

fprintf("TEST DASHBOARD MODULAR COMPONENTS SUPERADO\n");
