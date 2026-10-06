clear; clc;
matlabRoot = fileparts(fileparts(mfilename('fullpath')));
addpath(genpath(matlabRoot));
cfg = loadQuantLabConfig(matlabRoot);
[data,report] = loadConfiguredMarketData(cfg);
assert(~isempty(data));
assert(report.finalRows==height(data));
assert(all(ismember(["datetime_local","session_date","time_local"], ...
    string(data.Properties.VariableNames))));
fprintf("TEST CONFIGURED MARKET DATA LOADER SUPERADO\n");
