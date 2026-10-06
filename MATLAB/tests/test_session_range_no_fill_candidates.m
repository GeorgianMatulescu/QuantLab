clear; clc;
matlabRoot = string(fileparts(fileparts(mfilename("fullpath"))));
addpath(genpath(matlabRoot));

cfg = loadQuantLabConfig(matlabRoot,"MNQ","SESSION_RANGE_MADRID");
cfg.executionProfiles = cfg.executionProfiles(1);
cfg.crt3h.sessionScenarios = cfg.crt3h.sessionScenarios(2);
cfg.crt3h.exitManagementScenarios = cfg.crt3h.exitManagementScenarios(1);

data = buildNoFillSessionRangeData();
output = runStrategy("SESSION_RANGE_MADRID",data,cfg);
trades = output.results.IDEAL.trades;

newYork = trades(trades.session_name=="NUEVA_YORK",:);
assert(height(newYork)==1);
assert(~newYork.valid);
assert(newYork.skip_reason=="NO_SETUP");
assert(newYork.reference_range=="ASIA");

fprintf("TEST SESSION RANGE NO-FILL CANDIDATES SUPERADO\n");

function T = buildNoFillSessionRangeData()
timezone = "Europe/Madrid";
day = datetime(2026,9,7,"TimeZone",timezone);
times = duration(0,0,0):minutes(1):duration(16,59,0);
dt = day+times';
n = numel(dt);
tod = timeofday(dt);

open = 105*ones(n,1);
high = 106*ones(n,1);
low = 104*ones(n,1);
close = 105*ones(n,1);

asia = tod<duration(9,0,0);
high(asia) = 110;
low(asia) = 100;
london = tod>=duration(9,0,0) & tod<duration(15,0,0);
high(london) = 108;
low(london) = 102;

volume = ones(n,1);
symbol = repmat("MNQ",n,1);
use_rth = zeros(n,1);
T = table(dt,open,high,low,close,volume,symbol,use_rth, ...
    'VariableNames',{ ...
    'datetime_local','open','high','low','close', ...
    'volume','symbol','use_rth'});
end
