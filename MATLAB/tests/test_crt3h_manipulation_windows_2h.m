clear;
clc;

matlabRoot = string(fileparts(fileparts(mfilename("fullpath"))));
addpath(genpath(matlabRoot));

cfg = loadQuantLabConfig(matlabRoot);
cfg.crt3h.entryFraction = 0.5;
cfg.crt3h.rewardRisk = 1.0;
assert(cfg.crt3h.london.refStart==duration(6,0,0));
assert(cfg.crt3h.london.refEnd==duration(9,0,0));
assert(cfg.crt3h.london.entryStart==duration(9,0,0));
assert(cfg.crt3h.london.manEnd==duration(11,0,0));
assert(cfg.crt3h.newYork.refStart==duration(12,0,0));
assert(cfg.crt3h.newYork.refEnd==duration(15,0,0));
assert(cfg.crt3h.newYork.entryStart==duration(15,0,0));
assert(cfg.crt3h.newYork.manEnd==duration(17,0,0));

data = buildLateSweepData();
[events,context] = buildCRT3HContext(data,cfg);
londonWindow = context.windows(1);
nyWindow = context.windows(2);

assert(londonWindow.data_complete && nyWindow.data_complete);
assert(londonWindow.expected_man_bars==120);
assert(nyWindow.expected_man_bars==120);
assert(londonWindow.man_start==datetime(2026,7,29,9,0,0, ...
    "TimeZone","Europe/Madrid"));
assert(londonWindow.man_end==datetime(2026,7,29,11,0,0, ...
    "TimeZone","Europe/Madrid"));
assert(nyWindow.man_start==datetime(2026,7,29,15,0,0, ...
    "TimeZone","Europe/Madrid"));
assert(nyWindow.man_end==datetime(2026,7,29,17,0,0, ...
    "TimeZone","Europe/Madrid"));
newBars = events(events.event_type=="NEW_BAR",:);
assert(max(newBars.event_time)==datetime(2026,7,29,16,59,0, ...
    "TimeZone","Europe/Madrid"));

output = runStrategy("CRT_3H_MADRID",data,cfg);
session = output.results.IDEAL.sessionScenarios.LONDON_AND_NEW_YORK;
scenario = session.exitManagementScenarios.FIXED_TARGET;
orders = scenario.trades;
london = orders(orders.session_name=="LONDRES",:);
newYork = orders(orders.session_name=="NUEVA_YORK",:);

assert(london.valid && newYork.valid);
assert(london.sweep_time==datetime(2026,7,29,10,30,0, ...
    "TimeZone","Europe/Madrid"));
assert(london.entry_time==datetime(2026,7,29,10,31,0, ...
    "TimeZone","Europe/Madrid"));
assert(london.exit_reason=="TARGET");
assert(abs(london.gross_R-1.0)<1e-12);
assert(newYork.sweep_time==datetime(2026,7,29,16,30,0, ...
    "TimeZone","Europe/Madrid"));
assert(newYork.entry_time==datetime(2026,7,29,16,31,0, ...
    "TimeZone","Europe/Madrid"));
assert(newYork.exit_reason=="TARGET");
assert(abs(newYork.gross_R-1.0)<1e-12);

fprintf("TEST CRT3H MANIPULATION WINDOWS 2H SUPERADO\n");

function T = buildLateSweepData()
timezone = "Europe/Madrid";
day = datetime(2026,7,29,"TimeZone",timezone);
times = duration(6,0,0):minutes(1):duration(16,59,0);
dt = day+times';
n = numel(dt);
tod = timeofday(dt);

open = 105*ones(n,1);
high = 109*ones(n,1);
low = 101*ones(n,1);
close = 105*ones(n,1);

nyReference = tod>=duration(12,0,0) & tod<duration(15,0,0);
open(nyReference)=205; high(nyReference)=210;
low(nyReference)=200; close(nyReference)=205;
nyManipulation = tod>=duration(15,0,0);
open(nyManipulation)=205; high(nyManipulation)=209;
low(nyManipulation)=201; close(nyManipulation)=205;

setBar(10,30,100,103,98,100);
setBar(10,31,100,104,99,103);
setBar(10,32,104,111,103,110);

setBar(16,30,209,212,208,210);
setBar(16,31,210,211,206,207);
setBar(16,32,206,207,199,200);

volume = ones(n,1);
symbol = repmat("MNQ",n,1);
use_rth = zeros(n,1);
T = table(dt,open,high,low,close,volume,symbol,use_rth, ...
    'VariableNames',{ ...
    'datetime_local','open','high','low','close','volume','symbol','use_rth'});

    function setBar(hourValue,minuteValue,o,h,l,c)
        when = datetime(2026,7,29,hourValue,minuteValue,0, ...
            "TimeZone",timezone);
        index = find(dt==when,1,"first");
        open(index)=o; high(index)=h; low(index)=l; close(index)=c;
    end
end
