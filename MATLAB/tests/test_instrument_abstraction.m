clear; clc;
matlabRoot = fileparts(fileparts(mfilename('fullpath')));
addpath(genpath(matlabRoot));

future = createInstrumentSpec("MNQ","FUTURE", ...
    tickSize=0.25,contractMultiplier=2,quantityStep=1);
stock = createInstrumentSpec("AAPL","STOCK", ...
    tickSize=0.01,contractMultiplier=1,quantityStep=1);
forex = createInstrumentSpec("EURUSD","FOREX", ...
    tickSize=0.00001,contractMultiplier=1,quantityStep=1000, ...
    minimumQuantity=1000,maximumQuantity=1000000);
crypto = createInstrumentSpec("BTCUSD","CRYPTO", ...
    tickSize=0.01,contractMultiplier=1,quantityStep=0.0001, ...
    minimumQuantity=0.0001,maximumQuantity=100);

assert(calculateInstrumentPnL(20000,20010,1,2,future)==40);
assert(calculateInstrumentPnL(100,101,1,10,stock)==10);
assert(abs(calculateInstrumentPnL(1.10,1.11,1,10000,forex)-100)<1e-9);
assert(abs(calculateInstrumentPnL(60000,60100,1,0.1,crypto)-10)<1e-9);
roundedCrypto = roundQuantityToStep(0.123456,crypto,"FLOOR");
assert(abs(roundedCrypto-0.1234)<1e-12);

fprintf("TEST INSTRUMENT ABSTRACTION SUPERADO\n");
