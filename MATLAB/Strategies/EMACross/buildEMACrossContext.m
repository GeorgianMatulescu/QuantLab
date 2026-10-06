function [events,context] = buildEMACrossContext(data,cfg)
%BUILDEMACROSSCONTEXT Calcula indicadores y eventos del plugin.

data = ensureCanonicalBarData(data,cfg);
p = cfg.emaCross;

fast = calculateEMA(data.close,p.fastPeriod);
slow = calculateEMA(data.close,p.slowPeriod);
atr = calculateATR(data.high,data.low,data.close,p.atrPeriod);

longSignal = false(height(data),1);
shortSignal = false(height(data),1);

longSignal(2:end) = ...
    fast(1:end-1)<=slow(1:end-1) & ...
    fast(2:end)>slow(2:end);
shortSignal(2:end) = ...
    fast(1:end-1)>=slow(1:end-1) & ...
    fast(2:end)<slow(2:end);

inEntryWindow = data.time_local>=p.entryStart & ...
    data.time_local<p.entryEnd;
longSignal = longSignal & inEntryWindow & p.allowLong;
shortSignal = shortSignal & inEntryWindow & p.allowShort;

indicatorTable = table( ...
    (1:height(data))',data.datetime_local,data.session_date, ...
    fast,slow,atr,longSignal,shortSignal, ...
    'VariableNames',{ ...
    'bar_index','datetime_local','session_date', ...
    'fast_ema','slow_ema','atr_points', ...
    'long_signal','short_signal'});

baseEvents = buildBaseMarketEvents(data,cfg);
signalRows = cell(nnz(longSignal)+nnz(shortSignal),1);
k = 0;

for index = find(longSignal | shortSignal)'
    if longSignal(index)
        eventType = "SIGNAL_LONG";
        direction = "LONG";
    else
        eventType = "SIGNAL_SHORT";
        direction = "SHORT";
    end

    k = k+1;
    signalRows{k} = makeEvent( ...
        eventType,data.datetime_local(index), ...
        data.session_date(index),string(data.symbol(index)), ...
        index,data.close(index),direction,"EMACross", ...
        struct( ...
        "fast_ema",fast(index), ...
        "slow_ema",slow(index), ...
        "atr_points",atr(index)));
end

if isempty(signalRows)
    events = baseEvents;
else
    signalEvents = vertcat(signalRows{:});
    events = [baseEvents;signalEvents];
    events = sortrows(events, ...
        ["event_time","bar_index","event_type"]);
end

grouped = groupBarDataBySession(data,cfg);
context = struct( ...
    "daily",buildGenericSessionSummary(data,cfg), ...
    "indicators",indicatorTable, ...
    "session_dates",grouped.session_dates, ...
    "session_data",{grouped.session_data}, ...
    "strategy_name","EMA_CROSS");
end

function values = calculateEMA(data,period)
values = nan(size(data));
if isempty(data), return; end
alpha = 2/(period+1);
values(1) = data(1);
for i = 2:numel(data)
    values(i) = alpha*data(i)+(1-alpha)*values(i-1);
end
end

function atr = calculateATR(high,low,close,period)
priorClose = [close(1);close(1:end-1)];
trueRange = max([ ...
    high-low,abs(high-priorClose),abs(low-priorClose)],[],2);
atr = nan(size(trueRange));
atr(1) = trueRange(1);
alpha = 1/period;
for i = 2:numel(trueRange)
    atr(i) = alpha*trueRange(i)+(1-alpha)*atr(i-1);
end
end
