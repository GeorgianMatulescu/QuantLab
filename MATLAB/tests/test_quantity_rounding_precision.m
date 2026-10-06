clear;
clc;

matlabRoot = fileparts(fileparts(mfilename('fullpath')));
addpath(genpath(matlabRoot));

crypto = createInstrumentSpec("BTCUSD","CRYPTO", ...
    tickSize=0.01,contractMultiplier=1, ...
    quantityStep=0.0001,minimumQuantity=0.0001, ...
    maximumQuantity=100);

quarterStep = createInstrumentSpec("TEST","CRYPTO", ...
    tickSize=0.01,contractMultiplier=1, ...
    quantityStep=0.25,minimumQuantity=0.25, ...
    maximumQuantity=100);

floorValue = roundQuantityToStep(0.123456,crypto,"FLOOR");
ceilValue = roundQuantityToStep(0.123456,crypto,"CEIL");
nearestValue = roundQuantityToStep(0.123456,crypto,"NEAREST");

assert(abs(floorValue-0.1234)<1e-12);
assert(abs(ceilValue-0.1235)<1e-12);
assert(abs(nearestValue-0.1235)<1e-12);

assert(roundQuantityToStep(1.13,quarterStep,"FLOOR")==1.00);
assert(roundQuantityToStep(1.13,quarterStep,"CEIL")==1.25);
assert(roundQuantityToStep(1.13,quarterStep,"NEAREST")==1.25);

fprintf("TEST QUANTITY ROUNDING PRECISION SUPERADO\n");
