clear;
clc;

matlabRoot = fileparts(fileparts(mfilename('fullpath')));
addpath(genpath(matlabRoot));

S = loadAuditWorkspace(matlabRoot,"ORB");
profiles = getDashboardProfiles(S.results);
scenario = getDashboardScenario(S.results,profiles(1));
trades = scenario.trades;

rolling = calculateRollingMetrics(trades,20);

assert(~isempty(rolling.dates));
assert(strcmp( ...
    rolling.dates.TimeZone, ...
    trades.session_date.TimeZone));

expectedDates = trades.session_date(20:end);

assert(isequal(rolling.dates,expectedDates), ...
    "Las fechas rolling no coinciden con el final de cada ventana.");

fprintf("TEST ROLLING METRICS TIMEZONE SUPERADO\n");
