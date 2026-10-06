function T = ensureCanonicalBarData(T,cfg)
%ENSURECANONICALBARDATA Añade el contrato BarData v1.
%
% Columnas canónicas:
%   datetime, datetime_local, session_date, time_local,
%   open, high, low, close, volume, symbol
%
% Se conservan alias *_new_york para compatibilidad con módulos antiguos.

arguments
    T table
    cfg (1,1) struct
end

variables = string(T.Properties.VariableNames);
session = normalizeSessionSpec(cfg);
spec = normalizeInstrumentSpec(cfg);

if ~ismember("datetime_local",variables)
    if ismember("datetime_new_york",variables)
        T.datetime_local = T.datetime_new_york;
    elseif ismember("datetime",variables) && isdatetime(T.datetime)
        T.datetime_local = T.datetime;
        T.datetime_local.TimeZone = char(session.timezone);
    else
        error("QuantLab:CanonicalDateTime", ...
            "Se necesita datetime_local, datetime_new_york o datetime.");
    end
end

if strlength(string(T.datetime_local.TimeZone))==0
    T.datetime_local.TimeZone = char(session.timezone);
else
    T.datetime_local.TimeZone = char(session.timezone);
end

variables = string(T.Properties.VariableNames);

if ~ismember("datetime",variables)
    T.datetime = T.datetime_local;
    T.datetime.TimeZone = "UTC";
elseif isdatetime(T.datetime)
    if strlength(string(T.datetime.TimeZone))==0
        T.datetime.TimeZone = char(session.timezone);
    end
    T.datetime.TimeZone = "UTC";
end

if ~ismember("session_date",variables)
    % Los aliases *_new_york pertenecen al archivo IBKR original y pueden
    % estar expresados en otra zona horaria. El contrato canónico siempre
    % deriva la fecha de la línea temporal local ya normalizada.
    T.session_date = dateshift(T.datetime_local,"start","day");
end

if isdatetime(T.session_date)
    T.session_date.TimeZone = char(session.timezone);
end

if ~ismember("time_local",variables)
    T.time_local = timeofday(T.datetime_local);
end

if ~ismember("volume",variables)
    T.volume = zeros(height(T),1);
end

if ~ismember("symbol",variables)
    T.symbol = repmat(spec.symbol,height(T),1);
else
    T.symbol = string(T.symbol);
end

% Alias legados: contienen tiempo local aunque el nombre histórico diga NY.
variables = string(T.Properties.VariableNames);
if ~ismember("datetime_new_york",variables)
    T.datetime_new_york = T.datetime_local;
end
if ~ismember("session_date_new_york",variables)
    T.session_date_new_york = T.session_date;
end
if ~ismember("time_new_york",variables)
    T.time_new_york = T.time_local;
end

T = sortrows(T,"datetime_local");
validateCanonicalBarData(T);
end
