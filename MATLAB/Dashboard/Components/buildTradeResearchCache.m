function cache = buildTradeResearchCache(marketData)
%BUILDTRADERESEARCHCACHE Precalcula datos usados por Trade Research.
%
% Evita reconstruir en cada clic:
% - las 252 sesiones;
% - OHLC diario;
% - gap;
% - ATR;
% - percentiles;
% - ORB de cada sesión;
% - clasificación de tendencia.
%
% También crea índices de inicio/fin para recuperar una sesión sin
% recorrer toda la tabla de 1 minuto.

arguments
    marketData table
end

cache = struct( ...
    "valid",false, ...
    "sessionData",table(), ...
    "sessionDates",NaT(0,1), ...
    "rowStart",zeros(0,1), ...
    "rowEnd",zeros(0,1), ...
    "contextTable",table());

variables = string(marketData.Properties.VariableNames);
requiredPrices = ["open","high","low","close"];

if isempty(marketData) || ~all(ismember(requiredPrices,variables))
    return;
end

if all(ismember(["session_date","datetime_local"],variables))
    sessionDateField = "session_date";
    datetimeField = "datetime_local";
elseif all(ismember( ...
        ["session_date_new_york","datetime_new_york"],variables))
    sessionDateField = "session_date_new_york";
    datetimeField = "datetime_new_york";
else
    return;
end

data = sortrows(marketData,datetimeField);
normalizedDates = dateshift( ...
    data.(sessionDateField), ...
    "start","day");

groupId = findgroups(normalizedDates);
rowStart = find([true;diff(groupId)~=0]);
rowEnd = [rowStart(2:end)-1;height(data)];
sessionDates = normalizedDates(rowStart);

n = numel(sessionDates);

sessionOpen = nan(n,1);
sessionHigh = nan(n,1);
sessionLow = nan(n,1);
sessionClose = nan(n,1);
orbRange = nan(n,1);

hasNewYorkTime = ismember("time_new_york",variables);
hasLocalTime = ismember("time_local",variables);

for i = 1:n
    rows = rowStart(i):rowEnd(i);

    sessionOpen(i) = data.open(rows(1));
    sessionHigh(i) = max(data.high(rows),[],"omitnan");
    sessionLow(i) = min(data.low(rows),[],"omitnan");
    sessionClose(i) = data.close(rows(end));

    if hasNewYorkTime
        localTime = data.time_new_york(rows);
    elseif hasLocalTime
        localTime = data.time_local(rows);
    else
        localTime = timeofday(data.(datetimeField)(rows));
    end

    orbMask = ...
        localTime>=duration(9,30,0) & ...
        localTime<duration(9,35,0);

    if any(orbMask)
        sessionRows = rows(orbMask);
        orbRange(i) = ...
            max(data.high(sessionRows),[],"omitnan") - ...
            min(data.low(sessionRows),[],"omitnan");
    end
end

gapPct = nan(n,1);

if n>1
    gapPct(2:end) = 100 .* ...
        (sessionOpen(2:end)-sessionClose(1:end-1)) ./ ...
        sessionClose(1:end-1);
end

trueRange = calculateTrueRange( ...
    sessionHigh,sessionLow,sessionClose);

atr14Points = nan(n,1);
atrMoving = nan(n,1);

for i = 1:n
    movingStart = max(1,i-13);
    atrMoving(i) = mean( ...
        trueRange(movingStart:i), ...
        "omitnan");

    if i>1
        priorStart = max(1,i-14);
        atr14Points(i) = mean( ...
            trueRange(priorStart:i-1), ...
            "omitnan");
    end
end

atrPercentile60 = nan(n,1);
orbPercentile60 = nan(n,1);

for i = 2:n
    historyStart = max(1,i-60);

    atrPercentile60(i) = empiricalPercentile( ...
        atrMoving(i), ...
        atrMoving(historyStart:i-1));

    orbPercentile60(i) = empiricalPercentile( ...
        orbRange(i), ...
        orbRange(historyStart:i-1));
end

sessionReturnPct = 100 .* ...
    (sessionClose-sessionOpen) ./ sessionOpen;

sessionDirection = strings(n,1);
sessionDirection(sessionClose>sessionOpen) = "BULLISH";
sessionDirection(sessionClose<sessionOpen) = "BEARISH";
sessionDirection(sessionClose==sessionOpen) = "FLAT";

dayOfWeek = string(day(sessionDates,"name"));
monthName = string(month(sessionDates,"name"));

trendDay = false(n,1);
trendDayScore = nan(n,1);

for i = 1:n
    sessionRange = sessionHigh(i)-sessionLow(i);

    if ~isfinite(sessionRange) || sessionRange<=0
        continue;
    end

    bodyFraction = ...
        abs(sessionClose(i)-sessionOpen(i)) / sessionRange;

    if sessionDirection(i)=="BULLISH"
        closeLocation = ...
            (sessionClose(i)-sessionLow(i)) / sessionRange;
    elseif sessionDirection(i)=="BEARISH"
        closeLocation = ...
            (sessionHigh(i)-sessionClose(i)) / sessionRange;
    else
        closeLocation = 0;
    end

    trendDayScore(i) = ...
        0.5*bodyFraction + 0.5*closeLocation;

    trendDay(i) = ...
        bodyFraction>=0.60 && closeLocation>=0.80;
end

vix = nan(n,1);

contextTable = table( ...
    sessionDates, ...
    gapPct, ...
    atr14Points, ...
    atrPercentile60, ...
    orbPercentile60, ...
    dayOfWeek, ...
    monthName, ...
    sessionReturnPct, ...
    sessionDirection, ...
    trendDay, ...
    trendDayScore, ...
    vix, ...
    'VariableNames', { ...
    'session_date', ...
    'gap_pct', ...
    'atr14_points', ...
    'atr_percentile_60', ...
    'orb_range_percentile_60', ...
    'day_of_week', ...
    'month', ...
    'session_return_pct', ...
    'session_direction', ...
    'trend_day', ...
    'trend_day_score', ...
    'vix'});

% Guardar solo las columnas necesarias para dibujar el gráfico.
chartColumns = [ ...
    "session_date","datetime_local","time_local", ...
    "session_date_new_york","datetime_new_york","time_new_york", ...
    "open","high","low","close"];
chartColumns = chartColumns(ismember( ...
    chartColumns,string(data.Properties.VariableNames)));

cache.valid = true;
cache.sessionData = data(:,chartColumns);
cache.sessionDates = sessionDates;
cache.rowStart = rowStart;
cache.rowEnd = rowEnd;
cache.contextTable = contextTable;
end

function trueRange = calculateTrueRange( ...
    sessionHigh,sessionLow,sessionClose)

n = numel(sessionClose);
trueRange = nan(n,1);

if n==0
    return;
end

trueRange(1) = sessionHigh(1)-sessionLow(1);

for i = 2:n
    trueRange(i) = max([ ...
        sessionHigh(i)-sessionLow(i), ...
        abs(sessionHigh(i)-sessionClose(i-1)), ...
        abs(sessionLow(i)-sessionClose(i-1))]);
end
end

function percentile = empiricalPercentile(value,history)
history = history(isfinite(history));

if ~isfinite(value) || isempty(history)
    percentile = NaN;
    return;
end

percentile = 100 .* ...
    sum(history<=value) ./ numel(history);
end
