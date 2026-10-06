clear;
clc;

matlabRoot = fileparts(fileparts(mfilename('fullpath')));
addpath(genpath(matlabRoot));

scenarioSource = fileread(fullfile( ...
    matlabRoot,"Strategies","CRT3H","runCRT3HScenario.m"));
dashboardSource = fileread(fullfile( ...
    matlabRoot,"Dashboard","launchQuantLabDashboard.m"));
chartSource = fileread(fullfile( ...
    matlabRoot,"Dashboard","Components","plotTradeSessionChart.m"));
ordersSource = fileread(fullfile( ...
    matlabRoot,"Dashboard","Components","updateOrdersTable.m"));

skipPosition = strfind(scenarioSource,"if sizing.skipTrade");
fillPosition = strfind(scenarioSource, ...
    "trade.entry_time = data.datetime_local(entryIndex)");
assert(~isempty(skipPosition) && ~isempty(fillPosition));
assert(skipPosition(1)<fillPosition(1), ...
    "entry_time solo puede escribirse después de aprobar el sizing.");

assert(contains(scenarioSource,'trade.order_status = "REJECTED"') || ...
    contains(scenarioSource,'trade.order_status = "NOT_CREATED"'));
assert(contains(scenarioSource,'trade.order_time ='));
assert(contains(scenarioSource,'trade.extreme_time ='));

assert(contains(dashboardSource, ...
    "dashboardState.currentTrades = executed"));
assert(contains(dashboardSource, ...
    "dashboardState.currentOrders = trades"));
assert(contains(dashboardSource, ...
    "updateTradesTable(tradesTable,executed)"));
assert(contains(dashboardSource, ...
    "updateOrdersTable(ordersTable,trades)"));
assert(contains(dashboardSource, ...
    "trades = dashboardState.currentOrders"));
assert(contains(dashboardSource,"restoreOrdersTable"));

assert(contains(ordersSource,'"setup_status","order_status"'));
assert(contains(ordersSource,'"order_time","order_price"'));

assert(contains(chartSource,"drawCRTContext("));
assert(contains(chartSource,'"CRT máximo","--"'));
assert(contains(chartSource,'"CRT mínimo","--"'));
assert(contains(chartSource,'readField(row,"entry_level"'));
assert(contains(chartSource,'entryLabel,"--"'));
assert(contains(chartSource,'xlabel(ax,"Hora de Madrid")'));

fprintf("TEST CRT3H TRADE LIFECYCLE DASHBOARD SUPERADO\n");
