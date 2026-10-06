function [sessionData,context] = getCachedTradeResearchData( ...
    cache,tradeRow)
%GETCACHEDTRADERESEARCHDATA Recupera sesión y contexto precalculados.
%
% La búsqueda se realiza por componentes de fecha y no mediante una
% comparación directa de datetime. Esto evita errores cuando una fecha
% tiene TimeZone y la otra no, o cuando utilizan zonas distintas.

arguments
    cache (1,1) struct
    tradeRow table
end

sessionData = table();
context = emptyContext();

if ~isfield(cache,"valid") || ~cache.valid || ...
        ~ismember("session_date",string(tradeRow.Properties.VariableNames))
    return;
end

tradeDate = tradeRow.session_date(1);

if ~isdatetime(tradeDate) || isnat(tradeDate)
    return;
end

tradeKey = makeDateKey(tradeDate);
cacheKeys = makeDateKey(cache.sessionDates);

sessionIndex = find(cacheKeys==tradeKey,1,"first");

if isempty(sessionIndex)
    return;
end

% Las estrategias CRT necesitan la referencia de tres horas y pueden
% cerrar después de la ventana de manipulación. Recuperar el tramo exacto
% desde la serie completa evita recortar una salida posterior o usar la
% sesión RTH de Nueva York.
tradeVariables = string(tradeRow.Properties.VariableNames);
cacheVariables = string(cache.sessionData.Properties.VariableNames);
if all(ismember(["ref_start","man_end"],tradeVariables)) && ...
        ismember("datetime_local",cacheVariables)
    rangeStart = tradeRow.ref_start(1);
    rangeEnd = tradeRow.man_end(1);
    if ismember("exit_time",tradeVariables)
        exitTime = tradeRow.exit_time(1);
        if isdatetime(exitTime) && ~isnat(exitTime) && exitTime>rangeEnd
            rangeEnd = exitTime + minutes(2);
        end
    end

    chartTime = cache.sessionData.datetime_local;
    if ~isempty(chartTime.TimeZone)
        rangeStart.TimeZone = chartTime.TimeZone;
        rangeEnd.TimeZone = chartTime.TimeZone;
    end
    mask = chartTime>=rangeStart & chartTime<=rangeEnd;
    sessionData = cache.sessionData(mask,:);
    context = table2struct(cache.contextTable(sessionIndex,:));
    return;
end

rows = ...
    cache.rowStart(sessionIndex): ...
    cache.rowEnd(sessionIndex);

sessionData = cache.sessionData(rows,:);
context = table2struct( ...
    cache.contextTable(sessionIndex,:));
end

function key = makeDateKey(values)
%MAKEDATEKEY Convierte fechas a YYYYMMDD sin comparar zonas horarias.

values = values(:);
key = year(values)*10000 + month(values)*100 + day(values);
end

function context = emptyContext()
context = struct( ...
    "session_date",NaT, ...
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
end
