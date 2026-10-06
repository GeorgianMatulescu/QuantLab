clear; clc;
matlabRoot = string(fileparts(fileparts(mfilename("fullpath"))));
addpath(genpath(matlabRoot));

cfg = loadQuantLabConfig(matlabRoot);
cfg.executionProfiles = cfg.executionProfiles(1);
cfg.filterToSession = false;

assert(cfg.crt3h.entryFraction==0.75);
assert(cfg.crt3h.rewardRisk==0.5);

data = buildEntry075Data();
output = runStrategy("CRT_3H_MADRID",data,cfg);
scenario = output.results.IDEAL.sessionScenarios. ...
    LONDON_TP_BLOCKS_NEW_YORK.exitManagementScenarios.FIXED_TARGET;
trade = scenario.trades(scenario.trades.session_name=="LONDRES",:);

assert(height(trade)==1 && trade.valid);
assert(trade.direction=="LONG");
assert(trade.rules_version=="CRT3H_ENTRY_075_RR_050");
assert(trade.signal_name=="CRT_3H_RETURN_75");
assert(trade.entry_fraction==0.75);
assert(trade.reward_risk_planned==0.5);
assert(trade.manipulation_extreme==98.00);
assert(trade.entry_level_50==104.00);
assert(trade.entry_level==107.00);
assert(trade.entry_price==107.00);
assert(trade.stop_price==98.00);
assert(trade.target_price==111.50);
assert(trade.crt_high==110.00);
assert(trade.target_price>trade.crt_high);
assert(abs(trade.gross_R-0.5)<1e-12);
assert(~trade.break_even_triggered);

fprintf("TEST CRT3H ENTRY 075 TARGET 05R SUPERADO\n");

function T = buildEntry075Data()
timezone = "Europe/Madrid";
day = datetime(2026,8,3,"TimeZone",timezone);
times = duration(6,0,0):minutes(1):duration(16,59,0);
dt = day+times';
n = numel(dt);
tod = timeofday(dt);

open = 105*ones(n,1);
high = 109*ones(n,1);
low = 101*ones(n,1);
close = 105*ones(n,1);

reference = tod>=duration(6,0,0) & tod<duration(9,0,0);
open(reference)=105;
high(reference)=110;
low(reference)=100;
close(reference)=105;

setBar(9,0,100,103,98,100);
setBar(9,1,104,108,99,107);
setBar(9,2,107,112,106,111.75);

volume = ones(n,1);
symbol = repmat("MNQ",n,1);
use_rth = zeros(n,1);
T = table(dt,open,high,low,close,volume,symbol,use_rth, ...
    'VariableNames',{ ...
    'datetime_local','open','high','low','close', ...
    'volume','symbol','use_rth'});

    function setBar(hourValue,minuteValue,o,h,l,c)
        when = datetime(2026,8,3,hourValue,minuteValue,0, ...
            "TimeZone",timezone);
        index = find(dt==when,1,"first");
        open(index)=o;
        high(index)=h;
        low(index)=l;
        close(index)=c;
    end
end
