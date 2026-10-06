matlabRoot = string(fileparts(fileparts(mfilename("fullpath"))));
addpath(genpath(matlabRoot));

cfg = loadQuantLabConfig(matlabRoot);
cfg.crt3h.entryFraction = 0.5;
cfg.crt3h.rewardRisk = 1.0;
cfg.strategyName = "CRT_3H_MADRID";
cfg.marketTimezone = "Europe/Madrid";
cfg.filterToSession = false;
cfg.sessionSpec = createSessionSpec( ...
    name="Synthetic Extended Madrid", ...
    timezone=cfg.marketTimezone, ...
    mode="24X7", ...
    expectedBarMinutes=1, ...
    expectedBarsPerSession=0, ...
    weekdays=1:7);
cfg.instrumentSpec = createInstrumentSpec( ...
    "MNQ","FUTURE", ...
    quoteCurrency="USD",accountCurrency="USD", ...
    tickSize=0.25,contractMultiplier=2.0, ...
    quantityStep=1,minimumQuantity=1,maximumQuantity=40, ...
    marketTimezone=cfg.marketTimezone, ...
    sessionTemplate="SYNTHETIC_EXTENDED");

data = buildSyntheticCRTData();
output = runStrategy("CRT_3H_MADRID",data,cfg);
trades = output.results.IDEAL.trades;

assert(height(trades)==4);
assert(nnz(trades.valid)==2);

day1London = trades.session_date==datetime(2026,7,27, ...
    "TimeZone","Europe/Madrid") & trades.session_name=="LONDRES";
day1Ny = trades.session_date==datetime(2026,7,27, ...
    "TimeZone","Europe/Madrid") & trades.session_name=="NUEVA_YORK";
day2London = trades.session_date==datetime(2026,7,28, ...
    "TimeZone","Europe/Madrid") & trades.session_name=="LONDRES";
day2Ny = trades.session_date==datetime(2026,7,28, ...
    "TimeZone","Europe/Madrid") & trades.session_name=="NUEVA_YORK";

assert(trades.valid(day1London));
assert(trades.record_type(day1London)=="TRADE");
assert(trades.setup_status(day1London)=="EXECUTED");
assert(trades.order_status(day1London)=="FILLED");
assert(trades.direction(day1London)=="LONG");
assert(trades.entry_time(day1London)==datetime(2026,7,27,9,1,0, ...
    "TimeZone","Europe/Madrid"));
assert(trades.order_time(day1London)==trades.entry_time(day1London));
assert(trades.exit_reason(day1London)=="TARGET");
assert(trades.target_price(day1London)==110.00);
assert(abs(trades.gross_R(day1London)-1.0)<1e-12);
assert(trades.skip_reason(day1Ny)=="LONDON_TP_BLOCK");
assert(trades.setup_status(day1Ny)=="BLOCKED");
assert(isnat(trades.entry_time(day1Ny)));
assert(trades.skip_reason(day2London)=="NO_SETUP");
assert(trades.setup_status(day2London)=="NO_SETUP");
assert(isnat(trades.entry_time(day2London)));
assert(trades.valid(day2Ny));
assert(trades.direction(day2Ny)=="SHORT");
assert(trades.sweep_time(day2Ny)==datetime(2026,7,28,15,0,0, ...
    "TimeZone","Europe/Madrid"));
assert(trades.entry_start(day2Ny)==datetime(2026,7,28,15,0,0, ...
    "TimeZone","Europe/Madrid"));
assert(trades.entry_time(day2Ny)==datetime(2026,7,28,15,1,0, ...
    "TimeZone","Europe/Madrid"));
assert(trades.exit_reason(day2Ny)=="TARGET");
assert(trades.target_price(day2Ny)==200.00);
assert(abs(trades.gross_R(day2Ny)-1.0)<1e-12);

assert(all(isnat(trades.entry_time(~trades.valid))));

% Regresión: una señal cuyo contrato mínimo supera el presupuesto debe
% conservarse como orden rechazada, nunca como trade parcialmente rellenado.
cfg.risk.mode = "FIXED_USD";
cfg.risk.fixedRiskUSD = 1;
rejectedOutput = runStrategy("CRT_3H_MADRID",data,cfg);
rejectedTrades = rejectedOutput.results.IDEAL.trades;
rejectedMask = rejectedTrades.skip_reason=="RISK_TOO_LARGE";
assert(nnz(rejectedMask)==2);
assert(all(~rejectedTrades.valid(rejectedMask)));
assert(all(isnat(rejectedTrades.entry_time(rejectedMask))));
assert(all(~isnat(rejectedTrades.order_time(rejectedMask))));
assert(all(rejectedTrades.order_status(rejectedMask)=="REJECTED"));

plugin = resolveStrategyPlugin("CRT_3H_MADRID");
assert(plugin.name=="CRT_3H_MADRID");
assert(plugin.version=="1.10.0");
assert(height(plugin.parameterSchema())==15);

fprintf("TEST CRT3H STRATEGY SMOKE SUPERADO\n");

function T = buildSyntheticCRTData()
timezone = "Europe/Madrid";
dates = [datetime(2026,7,27,"TimeZone",timezone), ...
    datetime(2026,7,28,"TimeZone",timezone)];
times = duration(6,0,0):minutes(1):duration(16,59,0);
dt = [dates(1)+times,dates(2)+times]';
n = numel(dt);
open = 105*ones(n,1);
high = 109*ones(n,1);
low = 101*ones(n,1);
close = 105*ones(n,1);

day1 = dateshift(dt,"start","day")==dates(1);
day2 = dateshift(dt,"start","day")==dates(2);
tod = timeofday(dt);

setRange(day2,205,209,201,205);

setRange(day1 & tod>=duration(6,0,0) & tod<duration(9,0,0), ...
    105,110,100,105);
setRange(day1 & tod>=duration(12,0,0) & tod<duration(15,0,0), ...
    115,120,110,115);
setRange(day2 & tod>=duration(6,0,0) & tod<duration(9,0,0), ...
    205,210,200,205);
setRange(day2 & tod>=duration(12,0,0) & tod<duration(15,0,0), ...
    205,210,200,205);

setBar(datetime(2026,7,27,9,0,0,"TimeZone",timezone),100,103,98,100);
setBar(datetime(2026,7,27,9,1,0,"TimeZone",timezone),100,104.5,99,104);
setBar(datetime(2026,7,27,9,2,0,"TimeZone",timezone),104,113,104,112);

setBar(datetime(2026,7,28,15,0,0,"TimeZone",timezone),209,212,208,209);
setBar(datetime(2026,7,28,15,1,0,"TimeZone",timezone),209,210,206,206);
setBar(datetime(2026,7,28,15,2,0,"TimeZone",timezone),206,206,197,198);
volume = ones(n,1);
symbol = repmat("MNQ",n,1);
use_rth = zeros(n,1);
T = table(dt,open,high,low,close,volume,symbol,use_rth, ...
    'VariableNames',{ ...
    'datetime_local','open','high','low','close','volume','symbol','use_rth'});

    function setRange(mask,o,h,l,c)
        open(mask)=o; high(mask)=h; low(mask)=l; close(mask)=c;
    end

    function setBar(when,o,h,l,c)
        index = find(dt==when,1,"first");
        open(index)=o; high(index)=h; low(index)=l; close(index)=c;
    end
end
