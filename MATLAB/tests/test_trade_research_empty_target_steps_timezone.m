clear;
clc;

matlabRoot = fileparts(fileparts(mfilename('fullpath')));
addpath(genpath(matlabRoot));

timezone = "Europe/Madrid";
chartTime = datetime(2025,8,1,9,0,0, ...
    "TimeZone",timezone) + minutes((0:5)');

openPrice = [100;101;102;101;100;99];
highPrice = openPrice + 1;
lowPrice = openPrice - 1;
closePrice = openPrice + 0.25;
sessionData = table( ...
    chartTime,openPrice,highPrice,lowPrice,closePrice, ...
    "VariableNames",[ ...
    "datetime_local","open","high","low","close"]);

session_date = dateshift(chartTime(1),"start","day");
session_name = "LONDRES";
direction = "LONG";
valid = true;
contracts = 1;
entry_time = chartTime(1);
entry_price = 100;
exit_time = chartTime(4);
exit_price = 99;
stop_price = 99;
target_price = 101.5;
exit_reason = "STOP";
exit_management = "SWING_TRAILING_STEP_TARGET";
target_step_times = "";
target_step_prices = "";
trailing_stop_times = "";
trailing_stop_prices = "";
break_even_triggered = false;

tradeRow = table( ...
    session_date,session_name,direction,valid,contracts, ...
    entry_time,entry_price,exit_time,exit_price, ...
    stop_price,target_price,exit_reason,exit_management, ...
    target_step_times,target_step_prices, ...
    trailing_stop_times,trailing_stop_prices, ...
    break_even_triggered);

fig = figure("Visible","off");
cleanup = onCleanup(@() close(fig)); %#ok<NASGU>
ax = axes(fig);

plotTradeSessionChart(ax,sessionData,tradeRow);

assert(~isempty(ax.Children), ...
    "Research no representó el trade sin escalones de TP.");

fprintf([ ...
    "TEST TRADE RESEARCH EMPTY TARGET STEPS TIMEZONE " ...
    "SUPERADO\n"]);
