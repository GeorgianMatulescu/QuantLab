function [T, report] = loadMarketData(filePath, cfg)
%LOADMARKETDATA Lee y normaliza el CSV creado por QuantLab Python.

arguments
    filePath (1,1) string
    cfg (1,1) struct
end

if ~isfile(filePath)
    error("QuantLab:DataFileNotFound", ...
        "No se encuentra el CSV esperado:\n%s\n\n" + ...
        "Comprueba que MATLAB está dentro de la raíz QuantLab y que el CSV está en:\n" + ...
        "QuantLab/data/<ACTIVO>/1_min/", filePath);
end

opts = detectImportOptions( ...
    filePath, ...
    "Delimiter", ",", ...
    "VariableNamingRule", "preserve");

required = [ ...
    "datetime","open","high","low","close","volume", ...
    "datetime_new_york","session_date_new_york", ...
    "time_new_york","symbol","local_symbol","con_id", ...
    "sec_type","exchange","bar_size","use_rth"];

missingColumns = setdiff(required, string(opts.VariableNames));
if ~isempty(missingColumns)
    error("QuantLab:MissingColumns", ...
        "Faltan columnas obligatorias: %s", ...
        strjoin(missingColumns, ", "));
end

T = readtable(filePath, opts);

T.datetime = parseDateTimeWithOffset(T.datetime, "UTC");
T.datetime_new_york = parseDateTimeWithOffset( ...
    T.datetime_new_york, cfg.marketTimezone);

T.session_date_new_york = datetime( ...
    string(T.session_date_new_york), ...
    "InputFormat", "yyyy-MM-dd", ...
    "TimeZone", cfg.marketTimezone);

T.time_new_york = duration( ...
    string(T.time_new_york), ...
    "InputFormat", "hh:mm:ss");

textColumns = ["symbol","local_symbol","sec_type","exchange","bar_size"];
for name = textColumns
    T.(name) = string(T.(name));
end

numericColumns = [ ...
    "open","high","low","close","volume","con_id","use_rth"];

for name = numericColumns
    if ~isnumeric(T.(name))
        T.(name) = str2double(string(T.(name)));
    end
end

optionalNumericColumns = ["average","barCount"];
for name = optionalNumericColumns
    if ismember(name, string(T.Properties.VariableNames)) ...
            && ~isnumeric(T.(name))
        T.(name) = str2double(string(T.(name)));
    end
end

T = ensureCanonicalBarData(T,cfg);
[T, report] = validateMarketData(T, cfg);
end

function dt = parseDateTimeWithOffset(values, targetTimezone)
values = string(values);

formats = [ ...
    "yyyy-MM-dd HH:mm:ssXXX", ...
    "yyyy-MM-dd'T'HH:mm:ssXXX", ...
    "yyyy-MM-dd HH:mm:ssZ"];

lastError = [];
for fmt = formats
    try
        dt = datetime(values, ...
            "InputFormat", fmt, ...
            "TimeZone", "UTC");
        dt.TimeZone = targetTimezone;
        return;
    catch ME
        lastError = ME;
    end
end

error("QuantLab:DateTimeParse", ...
    "No se ha podido interpretar la fecha. Ejemplo: %s\n%s", ...
    values(1), lastError.message);
end
