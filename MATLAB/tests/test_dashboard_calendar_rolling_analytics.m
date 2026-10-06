clear;
clc;

matlabRoot = fileparts(fileparts(mfilename('fullpath')));
addpath(genpath(matlabRoot));

S = loadAuditWorkspace(matlabRoot,"ORB");
profiles = getDashboardProfiles(S.results);
scenario = getDashboardScenario(S.results,profiles(1));
trades = scenario.trades;

calendar = calculateCalendarReturns(trades);

assert(~isempty(calendar.years));
assert(size(calendar.matrix,2)==13);
assert(istable(calendar.monthlyObservations));

summary = buildCalendarSummaryTable(calendar);

assert(istable(summary));
assert(height(summary)==9);

rolling20 = calculateRollingMetrics(trades,20);

assert(~isempty(rolling20.dates));
assert(numel(rolling20.dates)==height(trades)-19);
assert(numel(rolling20.win_rate_pct)==numel(rolling20.dates));
assert(numel(rolling20.execution_rate_pct)==numel(rolling20.dates));

assert(strcmp( ...
    rolling20.dates.TimeZone, ...
    trades.session_date.TimeZone), ...
    "Rolling Metrics no conserva la zona horaria de session_date.");

dashboardSource = fileread(fullfile( ...
    matlabRoot,"Dashboard","launchQuantLabDashboard.m"));

assert(contains(dashboardSource, ...
    'analyticsTab = uitab(leftTabs,"Title","Analytics")'));

assert(contains(dashboardSource, ...
    "rollingWindowDropdown.ValueChangedFcn"));

fprintf("TEST DASHBOARD CALENDAR ROLLING ANALYTICS SUPERADO\n");
fprintf("Años: %d\n",numel(calendar.years));
fprintf("Meses con datos: %d\n",height(calendar.monthlyObservations));
fprintf("Puntos rolling 20: %d\n",numel(rolling20.dates));
