clear;
clc;

matlabRoot = fileparts(fileparts(mfilename('fullpath')));
source = fileread(fullfile(matlabRoot, ...
    "Dashboard","Components","updateEquityCharts.m"));

assert(contains(source,"tradeTimeline = buildTradeTimeline(executed)"));
assert(contains(source,"bar(returnAxes,tradeTimeline"));
assert(~contains(source,"bar( ...\n    returnAxes, ...\n    executed.session_date"));

fprintf("TEST DASHBOARD EQUITY USES TRADE TIME SUPERADO\n");
