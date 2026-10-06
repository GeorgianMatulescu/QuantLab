matlabRoot = string(fileparts(fileparts(mfilename("fullpath"))));
addpath(genpath(matlabRoot));

dashboardFile = fullfile( ...
    matlabRoot,"Dashboard","launchQuantLabDashboard.m");
source = fileread(dashboardFile);

assert(contains(source,"sessionScenarioDropdown = uidropdown"));
assert(contains(source,"SessionScenarioDropdown"));
assert(contains(source,"exitManagementDropdown = uidropdown"));
assert(contains(source,"ExitManagementDropdown"));
assert(contains(source,"getDashboardExitManagementScenarios"));
assert(contains(source,"getDashboardSessionScenarios"));
assert(contains(source,"getDashboardScenario( ..."));
assert(contains(source,"activeViewLabel"));
assert(contains(source,"Session Comparison"));
assert(contains(source,"buildSessionScenarioComparisonTable"));

fprintf("TEST DASHBOARD SESSION SCENARIO SELECTOR SUPERADO\n");
