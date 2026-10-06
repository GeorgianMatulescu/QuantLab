clear; clc;
matlabRoot = string(fileparts(fileparts(mfilename("fullpath"))));
addpath(genpath(matlabRoot));

cfg = loadQuantLabConfig(matlabRoot);
cfg.crt3h.entryFraction = 0.5;
cfg.crt3h.rewardRisk = 1.0;
cfg.executionProfiles = cfg.executionProfiles(1);
cfg.filterToSession = false;
cfg.sessionSpec = createSessionSpec( ...
    name="Synthetic Extended Madrid", ...
    timezone=cfg.marketTimezone, ...
    mode="24X7", ...
    expectedBarMinutes=1, ...
    expectedBarsPerSession=0, ...
    weekdays=1:7);

assert(cfg.crt3h.exitManagement.trailing.activationR==1.5);
assert(cfg.crt3h.exitManagement.trailing.targetStepR==0.5);
assert(cfg.crt3h.exitManagement.trailing.swingLeftBars==2);
assert(cfg.crt3h.exitManagement.trailing.swingRightBars==2);
assert(cfg.crt3h.exitManagement.trailing.swingOffsetTicks==1);

output = runStrategy( ...
    "CRT_3H_MADRID",buildTrailingData(),cfg);
session = ...
    output.results.IDEAL.sessionScenarios.LONDON_TP_BLOCKS_NEW_YORK;
fixed = session.exitManagementScenarios.FIXED_TARGET.trades;
trailing = ...
    session.exitManagementScenarios.SWING_TRAILING_STEP_TARGET.trades;
fixedLondon = fixed(fixed.session_name=="LONDRES",:);
trailLondon = trailing(trailing.session_name=="LONDRES",:);

assert(fixedLondon.valid);
assert(fixedLondon.exit_reason=="TARGET");
assert(fixedLondon.exit_price==110.00);
assert(abs(fixedLondon.gross_R-1.0)<1e-12);

assert(trailLondon.valid);
assert(trailLondon.exit_management== ...
    "SWING_TRAILING_STEP_TARGET");
assert(trailLondon.break_even_triggered);
assert(trailLondon.trailing_activated);
assert(trailLondon.trailing_activation_time==datetime( ...
    2026,7,30,9,6,0,"TimeZone","Europe/Madrid"));
assert(trailLondon.target_steps_advanced==2);
assert(trailLondon.final_target_r==2.5);
assert(trailLondon.final_target_price==119.00);
assert(trailLondon.trailing_stop_triggered);
assert(trailLondon.trailing_stop_price==108.75);
assert(trailLondon.exit_reason=="TRAILING_STOP");
assert(trailLondon.exit_time==datetime( ...
    2026,7,30,9,12,0,"TimeZone","Europe/Madrid"));
assert(trailLondon.exit_price==108.75);

stopPrices = str2double(split(trailLondon.trailing_stop_prices,";"));
targetPrices = str2double(split(trailLondon.target_step_prices,";"));
assert(isequal(stopPrices,[104.75;108.75]));
assert(isequal(targetPrices,[116.00;119.00]));

catalog = getDashboardExitManagementScenarios( ...
    output.results,"IDEAL","LONDON_TP_BLOCKS_NEW_YORK");
assert(height(catalog)==2);
assert(catalog.Properties.UserData.defaultName=="FIXED_TARGET");
selected = getDashboardScenario( ...
    output.results,"IDEAL","LONDON_TP_BLOCKS_NEW_YORK", ...
    "SWING_TRAILING_STEP_TARGET");
assert(selected.trades.exit_reason( ...
    selected.trades.session_name=="LONDRES")=="TRAILING_STOP");

fprintf("TEST CRT3H SWING TRAILING STEP TARGET SUPERADO\n");

function T = buildTrailingData()
timezone = "Europe/Madrid";
day = datetime(2026,7,30,"TimeZone",timezone);
times = duration(6,0,0):minutes(1):duration(16,59,0);
dt = day+times';
n = numel(dt);

open = 105*ones(n,1);
high = 109*ones(n,1);
low = 101*ones(n,1);
close = 105*ones(n,1);
tod = timeofday(dt);
reference = tod>=duration(6,0,0) & tod<duration(9,0,0);
open(reference)=105; high(reference)=110;
low(reference)=100; close(reference)=105;

setBar(9,0,100,103,98,100);
setBar(9,1,100,104.5,99,104);
setBar(9,2,104,111,103.5,110);
setBar(9,3,110,112,107,111);
setBar(9,4,111,112,106,108);
setBar(9,5,108,112,105,111);
setBar(9,6,111,113,107,112);
setBar(9,7,112,116,110,115);
setBar(9,8,115,117,111,116);
setBar(9,9,116,118,109,112);
setBar(9,10,112,117,110,116);
setBar(9,11,116,118,111,117);
setBar(9,12,117,118,108.75,110);

volume = ones(n,1);
symbol = repmat("MNQ",n,1);
use_rth = zeros(n,1);
T = table(dt,open,high,low,close,volume,symbol,use_rth, ...
    'VariableNames',{ ...
    'datetime_local','open','high','low','close', ...
    'volume','symbol','use_rth'});

    function setBar(hourValue,minuteValue,o,h,l,c)
        when = datetime(2026,7,30,hourValue,minuteValue,0, ...
            "TimeZone",timezone);
        index = find(dt==when,1,"first");
        open(index)=o; high(index)=h; low(index)=l; close(index)=c;
    end
end
