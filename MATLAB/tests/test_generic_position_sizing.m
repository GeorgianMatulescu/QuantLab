clear; clc;
matlabRoot = fileparts(fileparts(mfilename('fullpath')));
addpath(genpath(matlabRoot));
cfg = loadQuantLabConfig(matlabRoot);

cfg.instrumentSpec = createInstrumentSpec("BTCUSD","CRYPTO", ...
    tickSize=0.01,contractMultiplier=1,quantityStep=0.001, ...
    minimumQuantity=0.001,maximumQuantity=10);
cfg.risk.minimumQuantity = 0.001;
cfg.risk.maximumQuantity = 10;
cfg.risk.mode = "FIXED_USD";
cfg.risk.fixedRiskUSD = 100;

sizing = calculatePositionSize(500,50000,cfg);
assert(abs(sizing.quantity-0.2)<1e-12);
assert(abs(sizing.effectiveRiskUSD-100)<1e-12);
assert(sizing.contracts==sizing.quantity);

fprintf("TEST GENERIC POSITION SIZING SUPERADO\n");
