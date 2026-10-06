clear;
clc;

matlabRoot = fileparts(fileparts(mfilename('fullpath')));
addpath(genpath(matlabRoot));

dashboardFile = fullfile( ...
    matlabRoot, ...
    "Dashboard", ...
    "launchQuantLabDashboard.m");

source = fileread(dashboardFile);

assert(~contains(source, "updateReport(m);"), ...
    "El dashboard todavía contiene la llamada obsoleta updateReport(m).");

assert(contains(source, ...
    "reportTable.Data = buildResearchReportTable(m);"), ...
    "El dashboard no usa buildResearchReportTable(m).");

S = loadAuditWorkspace(matlabRoot, "ORB");
profiles = getDashboardProfiles(S.results);
scenario = getDashboardScenario(S.results, profiles(1));

m = calculateResearchMetrics(scenario.trades, S.cfg);
reportData = buildResearchReportTable(m);

assert(istable(reportData));
assert(height(reportData) == 13);

fprintf("TEST DASHBOARD REPORT INTEGRATION SUPERADO\n");
