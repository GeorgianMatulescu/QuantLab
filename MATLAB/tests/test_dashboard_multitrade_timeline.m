clear;
clc;

matlabRoot = fileparts(fileparts(mfilename('fullpath')));
addpath(genpath(matlabRoot));

tz = "America/New_York";
d = datetime(2026,7,1,"TimeZone",tz);
entry = [d+hours(10); d+hours(10); d+hours(14)];
executed = table([d;d;d],entry, ...
    'VariableNames',{'session_date','entry_time'});

timeline = buildTradeTimeline(executed);
assert(numel(unique(timeline))==3);
assert(all(diff(timeline)>seconds(0)));
assert(timeline(2)>timeline(1));

fprintf("TEST DASHBOARD MULTITRADE TIMELINE SUPERADO\n");
