matlabRoot = string(fileparts(fileparts(mfilename("fullpath"))));
addpath(genpath(matlabRoot));

cfg = loadQuantLabConfig(matlabRoot);
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

data = buildScenarioData();
output = runStrategy("CRT_3H_MADRID",data,cfg);

assert(height(output.results.summaryTable)==24);
assert(all(ismember([ ...
    "LONDON_ONLY","NEW_YORK_ONLY", ...
    "LONDON_AND_NEW_YORK","LONDON_TP_BLOCKS_NEW_YORK"], ...
    unique(output.results.summaryTable.sessionScenario))));

profile = output.results.IDEAL;
assert(profile.defaultSessionScenario== ...
    "LONDON_TP_BLOCKS_NEW_YORK");

londonOnly = profile.sessionScenarios.LONDON_ONLY.trades;
newYorkOnly = profile.sessionScenarios.NEW_YORK_ONLY.trades;
bothAlways = profile.sessionScenarios.LONDON_AND_NEW_YORK.trades;
conditional = ...
    profile.sessionScenarios.LONDON_TP_BLOCKS_NEW_YORK.trades;

assert(nnz(londonOnly.valid)==1);
assert(all(londonOnly.session_name(londonOnly.valid)=="LONDRES"));
assert(newYorkRow(londonOnly).skip_reason=="SESSION_DISABLED");

assert(nnz(newYorkOnly.valid)==1);
assert(all(newYorkOnly.session_name(newYorkOnly.valid)=="NUEVA_YORK"));
assert(londonRow(newYorkOnly).skip_reason=="SESSION_DISABLED");

assert(nnz(bothAlways.valid)==2);
assert(londonRow(bothAlways).exit_reason=="TARGET");
assert(newYorkRow(bothAlways).exit_reason=="TARGET");
assert(newYorkRow(bothAlways).equity_before_usd== ...
    londonRow(bothAlways).equity_after_usd);

assert(nnz(conditional.valid)==1);
assert(londonRow(conditional).exit_reason=="TARGET");
assert(newYorkRow(conditional).skip_reason=="LONDON_TP_BLOCK");
assert(newYorkRow(conditional).setup_status=="BLOCKED");

% El escenario base conserva compatibilidad y apunta a la política condicional.
assert(isequaln(profile.trades,conditional));

catalog = getDashboardSessionScenarios(output.results,"IDEAL");
assert(height(catalog)==4);
assert(catalog.Properties.UserData.defaultName== ...
    "LONDON_TP_BLOCKS_NEW_YORK");
selected = getDashboardScenario( ...
    output.results,"IDEAL","LONDON_AND_NEW_YORK");
assert(nnz(selected.trades.valid)==2);

comparison = buildSessionScenarioComparisonTable( ...
    output.results.summaryTable,"IDEAL","FIXED_TARGET");
assert(height(comparison)==4);
assert(all(ismember([ ...
    "Solo Londres","Solo Nueva York", ...
    "Londres + Nueva York", ...
    "Londres + NY; TP Londres bloquea NY"], ...
    comparison.Policy)));

fprintf("TEST CRT3H SESSION SCENARIOS SUPERADO\n");

function row = londonRow(trades)
row = trades(trades.session_name=="LONDRES",:);
end

function row = newYorkRow(trades)
row = trades(trades.session_name=="NUEVA_YORK",:);
end

function T = buildScenarioData()
timezone = "Europe/Madrid";
sessionDate = datetime(2026,7,27,"TimeZone",timezone);
times = duration(6,0,0):minutes(1):duration(16,59,0);
dt = sessionDate+times;
dt = dt';
n = numel(dt);

open = 105*ones(n,1);
high = 109*ones(n,1);
low = 101*ones(n,1);
close = 105*ones(n,1);
tod = timeofday(dt);

nyReference = tod>=duration(12,0,0) & tod<duration(15,0,0);
open(nyReference)=205;
high(nyReference)=210;
low(nyReference)=200;
close(nyReference)=205;

setBar(datetime(2026,7,27,9,0,0,"TimeZone",timezone), ...
    100,103,98,100);
setBar(datetime(2026,7,27,9,1,0,"TimeZone",timezone), ...
    100,104.5,99,104);
setBar(datetime(2026,7,27,9,2,0,"TimeZone",timezone), ...
    104,113,104,112);

setBar(datetime(2026,7,27,15,30,0,"TimeZone",timezone), ...
    210,212,209,210);
setBar(datetime(2026,7,27,15,31,0,"TimeZone",timezone), ...
    209,210,206,206);
setBar(datetime(2026,7,27,15,32,0,"TimeZone",timezone), ...
    206,206,197,198);

volume = ones(n,1);
symbol = repmat("MNQ",n,1);
use_rth = zeros(n,1);
T = table(dt,open,high,low,close,volume,symbol,use_rth, ...
    'VariableNames',{ ...
    'datetime_local','open','high','low','close', ...
    'volume','symbol','use_rth'});

    function setBar(when,o,h,l,c)
        index = find(dt==when,1,"first");
        open(index)=o;
        high(index)=h;
        low(index)=l;
        close(index)=c;
    end
end
