function context = calculateSessionContextFeatures( ...
    marketData, tradeRow)
%CALCULATESESSIONCONTEXTFEATURES Calcula contexto disponible para un trade.
%
% Las métricas se calculan solo con datos conocidos hasta la sesión
% seleccionada. No utiliza VIX porque aún no está integrado.
%
% Salida:
%   gap_pct
%   atr14_points
%   atr_percentile_60
%   orb_range_percentile_60
%   day_of_week
%   month
%   session_return_pct
%   session_direction
%   trend_day
%   trend_day_score

arguments
    marketData table
    tradeRow table
end

context = struct( ...
    "gap_pct",NaN, ...
    "atr14_points",NaN, ...
    "atr_percentile_60",NaN, ...
    "orb_range_percentile_60",NaN, ...
    "day_of_week","", ...
    "month","", ...
    "session_return_pct",NaN, ...
    "session_direction","", ...
    "trend_day",false, ...
    "trend_day_score",NaN, ...
    "vix",NaN);

if isempty(marketData) || ...
        ~ismember("session_date",string(tradeRow.Properties.VariableNames))
    return;
end

required = [ ...
    "session_date_new_york","datetime_new_york", ...
    "open","high","low","close"];

if ~all(ismember(required,string(marketData.Properties.VariableNames)))
    return;
end

daily = buildDailyContextTable(marketData);

tradeDate = dateshift(tradeRow.session_date(1),"start","day");
dailyDates = dateshift(daily.session_date,"start","day");
currentIndex = find(dailyDates==tradeDate,1,"first");

if isempty(currentIndex)
    return;
end

current = daily(currentIndex,:);

context.day_of_week = string(day(current.session_date,"name"));
context.month = string(month(current.session_date,"name"));
context.session_return_pct = ...
    100*(current.session_close-current.session_open)/current.session_open;

if current.session_close > current.session_open
    context.session_direction = "BULLISH";
elseif current.session_close < current.session_open
    context.session_direction = "BEARISH";
else
    context.session_direction = "FLAT";
end

if currentIndex > 1
    previousClose = daily.session_close(currentIndex-1);
    context.gap_pct = ...
        100*(current.session_open-previousClose)/previousClose;
end

trueRange = calculateTrueRange(daily);

atrStart = max(1,currentIndex-14);
priorTR = trueRange(atrStart:currentIndex-1);

if ~isempty(priorTR)
    context.atr14_points = mean(priorTR,"omitnan");
end

if currentIndex > 1
    historyStart = max(1,currentIndex-60);
    priorATR = movingATR(trueRange,14);
    atrHistory = priorATR(historyStart:currentIndex-1);
    currentATR = priorATR(currentIndex);

    context.atr_percentile_60 = ...
        empiricalPercentile(currentATR,atrHistory);
end

if ismember("orb_range_points", ...
        string(tradeRow.Properties.VariableNames))
    currentORB = tradeRow.orb_range_points(1);

    orbRanges = collectORBRanges( ...
        marketData,daily.session_date);

    if currentIndex > 1 && isfinite(currentORB)
        historyStart = max(1,currentIndex-60);
        context.orb_range_percentile_60 = ...
            empiricalPercentile( ...
            currentORB, ...
            orbRanges(historyStart:currentIndex-1));
    end
end

sessionRange = current.session_high-current.session_low;

if sessionRange > 0
    body = abs(current.session_close-current.session_open);
    bodyFraction = body/sessionRange;

    if context.session_direction=="BULLISH"
        closeLocation = ...
            (current.session_close-current.session_low)/sessionRange;
    elseif context.session_direction=="BEARISH"
        closeLocation = ...
            (current.session_high-current.session_close)/sessionRange;
    else
        closeLocation = 0;
    end

    context.trend_day_score = ...
        0.5*bodyFraction + 0.5*closeLocation;

    context.trend_day = ...
        bodyFraction>=0.60 && closeLocation>=0.80;
end
end

function daily = buildDailyContextTable(marketData)
dates = unique(marketData.session_date_new_york);
rows = cell(numel(dates),1);

for i = 1:numel(dates)
    D = marketData( ...
        marketData.session_date_new_york==dates(i),:);
    D = sortrows(D,"datetime_new_york");

    rows{i} = table( ...
        dates(i), ...
        D.open(1), ...
        max(D.high), ...
        min(D.low), ...
        D.close(end), ...
        'VariableNames', { ...
        'session_date','session_open','session_high', ...
        'session_low','session_close'});
end

daily = vertcat(rows{:});
end

function tr = calculateTrueRange(daily)
n = height(daily);
tr = nan(n,1);

for i = 1:n
    if i==1
        tr(i) = daily.session_high(i)-daily.session_low(i);
    else
        tr(i) = max([ ...
            daily.session_high(i)-daily.session_low(i), ...
            abs(daily.session_high(i)-daily.session_close(i-1)), ...
            abs(daily.session_low(i)-daily.session_close(i-1))]);
    end
end
end

function atr = movingATR(trueRange,period)
n = numel(trueRange);
atr = nan(n,1);

for i = 1:n
    firstIndex = max(1,i-period+1);
    atr(i) = mean(trueRange(firstIndex:i),"omitnan");
end
end

function percentile = empiricalPercentile(value,history)
history = history(isfinite(history));

if ~isfinite(value) || isempty(history)
    percentile = NaN;
    return;
end

percentile = 100*sum(history<=value)/numel(history);
end

function orbRanges = collectORBRanges(marketData,sessionDates)
orbRanges = nan(numel(sessionDates),1);

for i = 1:numel(sessionDates)
    D = marketData( ...
        marketData.session_date_new_york==sessionDates(i),:);
    D = sortrows(D,"datetime_new_york");

    if ismember("time_new_york", ...
            string(D.Properties.VariableNames))
        orbMask = D.time_new_york>=duration(9,30,0) & ...
            D.time_new_york<duration(9,35,0);
    else
        localTime = timeofday(D.datetime_new_york);
        orbMask = localTime>=duration(9,30,0) & ...
            localTime<duration(9,35,0);
    end

    ORB = D(orbMask,:);

    if ~isempty(ORB)
        orbRanges(i) = max(ORB.high)-min(ORB.low);
    end
end
end
