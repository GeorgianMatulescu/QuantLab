clear; clc;
matlabRoot = string(fileparts(fileparts(mfilename("fullpath"))));
addpath(genpath(matlabRoot));

cfg = loadQuantLabConfig(matlabRoot,"MNQ","SESSION_RANGE_MADRID");
cfg.executionProfiles = cfg.executionProfiles(1);
data = buildSessionRangeData();
output = runStrategy("SESSION_RANGE_MADRID",data,cfg);
trades = output.results.IDEAL.trades;

assert(cfg.dataFile==fullfile(cfg.quantLabRoot,"data","MNQ", ...
    "1_min","MNQ_CONTFUT_1_min_ALL.csv"));
assert(cfg.marketTimezone=="Europe/Madrid");
assert(cfg.crt3h.london.refStart==duration(0,0,0));
assert(cfg.crt3h.london.refEnd==duration(9,0,0));
assert(cfg.crt3h.newYork.refStart==duration(9,0,0));
assert(cfg.crt3h.newYork.refEnd==duration(15,0,0));
assert(cfg.crt3h.entryFraction==0.60);
assert(cfg.crt3h.rewardRisk==0.66);
assert(cfg.crt3h.rulesVersion== ...
    "SESSION_RANGE_ASIA_0000_0900_LONDON_0900_1500_ENTRY_060_RR_066");
assert(height(trades)==2);

london = trades(trades.session_name=="LONDRES",:);
newYork = trades(trades.session_name=="NUEVA_YORK",:);
assert(~london.valid && london.skip_reason=="NO_SETUP");
assert(newYork.valid);
assert(newYork.reference_range=="LONDRES");
assert(newYork.signal_name=="SESSION_RANGE_LONDRES_RETURN_60");
assert(newYork.entry_fraction==0.60);
assert(newYork.entry_level==104.75);
assert(newYork.reward_risk_planned==0.66);
assert(newYork.target_price==102.00);
assert(newYork.entry_time==datetime(2026,9,7,15,1,0, ...
    "TimeZone","Europe/Madrid"));
assert(newYork.exit_reason=="STOP");

daily = output.daily;
assert(daily.asia_high==110 && daily.asia_low==100);
assert(daily.london_high==108 && daily.london_low==102);
assert(daily.asia_london_complete);
assert(daily.asia_new_york_complete);
assert(daily.london_new_york_complete);

plugin = resolveStrategyPlugin("SESSION_RANGE_MADRID");
assert(plugin.name=="SESSION_RANGE_MADRID");
catalog = plugin.featureCatalog();
assert(any(catalog.name=="reference_range"));
schema = plugin.parameterSchema();
assert(schema.default_value( ...
    schema.name=="crt3h.entryFraction")==0.60);
assert(schema.default_value( ...
    schema.name=="crt3h.rewardRisk")==0.66);

% Regresión: seleccionar la estrategia nueva no altera el default CRT.
crtCfg = loadQuantLabConfig(matlabRoot,"MNQ");
assert(crtCfg.strategyName=="CRT_3H_MADRID");
assert(crtCfg.crt3h.entryFraction==0.75);
assert(crtCfg.crt3h.rewardRisk==0.5);
assert(crtCfg.crt3h.london.refStart==duration(6,0,0));
assert(crtCfg.crt3h.newYork.refStart==duration(12,0,0));

fprintf("TEST SESSION RANGE STRATEGY SMOKE SUPERADO\n");

function T = buildSessionRangeData()
timezone = "Europe/Madrid";
day = datetime(2026,9,7,"TimeZone",timezone);
times = duration(0,0,0):minutes(1):duration(16,59,0);
dt = day+times';
n = numel(dt);
tod = timeofday(dt);

open = 105*ones(n,1);
high = 107*ones(n,1);
low = 103*ones(n,1);
close = 105*ones(n,1);

asia = tod>=duration(0,0,0) & tod<duration(9,0,0);
open(asia)=105; high(asia)=110; low(asia)=100; close(asia)=105;
london = tod>=duration(9,0,0) & tod<duration(15,0,0);
open(london)=105; high(london)=108; low(london)=102; close(london)=105;

setBar(15,0,106,109,105,108);
setBar(15,1,106,108,103.5,104);
setBar(15,2,108,111,107,109);
setBar(15,3,105,107,102,103);
setBar(15,4,102,103,98,99);

volume = ones(n,1);
symbol = repmat("MNQ",n,1);
use_rth = zeros(n,1);
T = table(dt,open,high,low,close,volume,symbol,use_rth, ...
    'VariableNames',{ ...
    'datetime_local','open','high','low','close', ...
    'volume','symbol','use_rth'});

    function setBar(hourValue,minuteValue,o,h,l,c)
        when = datetime(2026,9,7,hourValue,minuteValue,0, ...
            "TimeZone",timezone);
        index = find(dt==when,1,"first");
        open(index)=o; high(index)=h; low(index)=l; close(index)=c;
    end
end
