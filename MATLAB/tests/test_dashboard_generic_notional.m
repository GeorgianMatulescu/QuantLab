clear;
clc;

matlabRoot = fileparts(fileparts(mfilename('fullpath')));
addpath(genpath(matlabRoot));

cfg = struct();
cfg.instrumentSpec = createInstrumentSpec("BTCUSD","CRYPTO", ...
    tickSize=0.01,contractMultiplier=1, ...
    quantityStep=0.0001,minimumQuantity=0.0001, ...
    maximumQuantity=100);

trades = table([50000;51000],[0.10;0.20], ...
    'VariableNames',{'entry_price','quantity'});
notional = calculateDashboardTradeNotional(trades,cfg);
assert(abs(notional(1)-5000)<1e-12);
assert(abs(notional(2)-10200)<1e-12);

fprintf("TEST DASHBOARD GENERIC NOTIONAL SUPERADO\n");
