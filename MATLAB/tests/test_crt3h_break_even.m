clear; clc;
matlabRoot = string(fileparts(fileparts(mfilename("fullpath"))));
addpath(genpath(matlabRoot));

cfg = loadQuantLabConfig(matlabRoot);
cfg.crt3h.entryFraction = 0.5;
cfg.strategyName = "CRT_3H_MADRID";
cfg.marketTimezone = "Europe/Madrid";
cfg.filterToSession = false;
cfg.executionProfiles = cfg.executionProfiles(1);
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

assert(cfg.crt3h.breakEven.enabled);
assert(cfg.crt3h.breakEven.triggerR==1.0);
assert(cfg.crt3h.breakEven.offsetTicks==0);
assert(cfg.crt3h.breakEven.activateOnNextBar);

% Esta regresión aísla la gestión break-even con un target posterior a su
% gatillo. El baseline v0.25.22 de 1R se valida por separado.
cfg.crt3h.rewardRisk = 1.5;

data = buildBreakEvenData();
output = runStrategy("CRT_3H_MADRID",data,cfg);
trades = output.results.IDEAL.trades;
london = trades.session_name=="LONDRES";

assert(nnz(london)==1);
assert(trades.valid(london));
assert(trades.direction(london)=="LONG");
assert(trades.entry_price(london)==104.00);
assert(trades.initial_stop_price(london)==98.00);
assert(trades.target_price(london)==113.00);
assert(trades.break_even_trigger_price(london)==110.00);
assert(trades.break_even_price(london)==104.00);
assert(trades.break_even_triggered(london));
assert(trades.break_even_trigger_time(london)==datetime( ...
    2026,7,29,9,2,0,"TimeZone","Europe/Madrid"));
assert(trades.break_even_effective_time(london)==datetime( ...
    2026,7,29,9,3,0,"TimeZone","Europe/Madrid"));
assert(trades.exit_time(london)==datetime( ...
    2026,7,29,9,3,0,"TimeZone","Europe/Madrid"));
assert(trades.exit_reason(london)=="BREAKEVEN");
assert(trades.exit_price(london)==trades.entry_price(london));
assert(abs(trades.gross_R(london))<1e-12);
assert(abs(trades.net_R(london))<1e-12);

% La vela 09:02 alcanza +1R y vuelve bajo la entrada. Con la política
% conservadora, el nuevo stop solo puede ejecutarse desde 09:03.
cfg.crt3h.breakEven.activateOnNextBar = false;
immediateOutput = runStrategy("CRT_3H_MADRID",data,cfg);
immediateTrades = immediateOutput.results.IDEAL.trades;
immediateLondon = immediateTrades.session_name=="LONDRES";
assert(immediateTrades.exit_reason(immediateLondon)=="BREAKEVEN");
assert(immediateTrades.exit_time(immediateLondon)==datetime( ...
    2026,7,29,9,2,0,"TimeZone","Europe/Madrid"));

% Sin break-even, el mismo recorrido continúa hasta el target experimental
% de 1,5R utilizado únicamente por esta regresión.
cfg.crt3h.breakEven.enabled = false;
cfg.crt3h.breakEven.activateOnNextBar = true;
disabledOutput = runStrategy("CRT_3H_MADRID",data,cfg);
disabledTrades = disabledOutput.results.IDEAL.trades;
disabledLondon = disabledTrades.session_name=="LONDRES";
assert(disabledTrades.exit_reason(disabledLondon)=="TARGET");
assert(disabledTrades.exit_time(disabledLondon)==datetime( ...
    2026,7,29,9,4,0,"TimeZone","Europe/Madrid"));
assert(abs(disabledTrades.gross_R(disabledLondon)-1.5)<1e-12);

schema = buildCRT3HParameterSchema();
assert(nnz(schema.name=="crt3h.breakEven.enabled")==1);
assert(nnz(schema.name=="crt3h.breakEven.triggerR")==1);
assert(nnz(schema.name=="crt3h.breakEven.offsetTicks")==1);

fprintf("TEST CRT3H BREAK EVEN SUPERADO\n");

function T = buildBreakEvenData()
timezone = "Europe/Madrid";
day = datetime(2026,7,29,"TimeZone",timezone);
times = duration(6,0,0):minutes(1):duration(16,59,0);
dt = day+times';
n = numel(dt);

open = 105*ones(n,1);
high = 109*ones(n,1);
low = 101*ones(n,1);
close = 105*ones(n,1);
tod = timeofday(dt);

reference = tod>=duration(6,0,0) & tod<duration(9,0,0);
open(reference)=105;
high(reference)=110;
low(reference)=100;
close(reference)=105;

setBar(datetime(2026,7,29,9,0,0,"TimeZone",timezone),100,103,98,100);
setBar(datetime(2026,7,29,9,1,0,"TimeZone",timezone),100,104.5,99,104);
setBar(datetime(2026,7,29,9,2,0,"TimeZone",timezone),104,110,103.5,109);
setBar(datetime(2026,7,29,9,3,0,"TimeZone",timezone),109,109.5,104,105);
setBar(datetime(2026,7,29,9,4,0,"TimeZone",timezone),105,113,105,112);

volume = ones(n,1);
symbol = repmat("MNQ",n,1);
use_rth = zeros(n,1);
T = table(dt,open,high,low,close,volume,symbol,use_rth, ...
    'VariableNames',{ ...
    'datetime_local','open','high','low','close','volume','symbol','use_rth'});

    function setBar(when,o,h,l,c)
        index = find(dt==when,1,"first");
        open(index)=o;
        high(index)=h;
        low(index)=l;
        close(index)=c;
    end
end
