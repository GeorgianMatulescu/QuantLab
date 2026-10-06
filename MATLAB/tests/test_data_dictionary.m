clear; clc;
matlabRoot = fileparts(fileparts(mfilename('fullpath')));
addpath(genpath(matlabRoot));
cfg = loadQuantLabConfig(matlabRoot);
[data,~] = loadMarketData(cfg.dataFile,cfg);
dictionary = getDataDictionary();
assert(istable(dictionary));
assert(height(dictionary) >= 18);
required = ["datetime_new_york","session_date_new_york", ...
    "open","high","low","close","volume","symbol"];
report = validateDataAgainstDictionary(data,required);
assert(report.isValid);
fprintf("TEST DATA DICTIONARY SUPERADO\n");
