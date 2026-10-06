clear; clc;
matlabRoot = fileparts(fileparts(mfilename('fullpath')));
addpath(genpath(matlabRoot));
cfg = loadQuantLabConfig(matlabRoot);

n = 5;
datetime_local = datetime(2026,1,2,9,30,0, ...
    "TimeZone",cfg.marketTimezone) + minutes((0:n-1)');
open = (100:104)'; high=open+1; low=open-1; close=open+0.5;
volume=ones(n,1); symbol=repmat("TEST",n,1);
T = table(datetime_local,open,high,low,close,volume,symbol);
T = ensureCanonicalBarData(T,cfg);

required = ["datetime","datetime_local","session_date","time_local", ...
    "datetime_new_york","session_date_new_york","time_new_york"];
assert(all(ismember(required,string(T.Properties.VariableNames))));
validateCanonicalBarData(T);

fprintf("TEST CANONICAL BAR CONTRACT SUPERADO\n");
