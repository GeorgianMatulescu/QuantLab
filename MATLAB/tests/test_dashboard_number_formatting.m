clear;
clc;

matlabRoot = fileparts(fileparts(mfilename('fullpath')));
addpath(genpath(matlabRoot));

T = table( ...
    [24282.0; 24315.0; NaN], ...
    [24315.0; 24258.0; NaN], ...
    [23952.0; 24494.0; NaN], ...
    [1.23456; -0.98765; NaN], ...
    [2; 10; 0], ...
    'VariableNames', { ...
    'entry_price','stop_price','target_price','net_R','contracts'});

D = formatTableForDisplay(T);

assert(D.entry_price(1) == "24282.00");
assert(D.stop_price(1) == "24315.00");
assert(D.target_price(1) == "23952.00");
assert(D.net_R(1) == "1.235");
assert(D.contracts(2) == "10");
assert(D.entry_price(3) == "");

fprintf("TEST DASHBOARD NUMBER FORMATTING SUPERADO\n");
