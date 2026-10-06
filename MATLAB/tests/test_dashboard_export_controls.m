matlabRoot = string(fileparts(fileparts(mfilename("fullpath"))));
addpath(genpath(matlabRoot));

dashboardFile = fullfile( ...
    matlabRoot,"Dashboard","launchQuantLabDashboard.m");
source = fileread(dashboardFile);

assert(contains(source,"exportTabButton = uibutton"));
assert(contains(source,"exportAllButton = uibutton"));
assert(contains(source,"Exportar pestaña"));
assert(contains(source,"Exportar todo"));
assert(contains(source,"exportActiveTab()"));
assert(contains(source,"exportEverything()"));
assert(contains(source,"collectExportOptions"));
assert(contains(source,"exportQuantLabDashboardPackage"));
assert(contains(source,"OptimizationResults"));
assert(contains(source,"WalkForwardResult"));

exportFile = fullfile( ...
    matlabRoot,"Core","Export", ...
    "exportQuantLabDashboardPackage.m");
exportSource = fileread(exportFile);

assert(contains(exportSource,"02_all_scenarios"));
assert(contains(exportSource,"orders.csv"));
assert(contains(exportSource,"trades.csv"));
assert(contains(exportSource,"equity_drawdown.csv"));
assert(contains(exportSource,"daily_results.csv"));
assert(contains(exportSource,"dataset_inventory.csv"));
assert(contains(exportSource,"artifacts.csv"));

fprintf("TEST DASHBOARD EXPORT CONTROLS SUPERADO\n");
