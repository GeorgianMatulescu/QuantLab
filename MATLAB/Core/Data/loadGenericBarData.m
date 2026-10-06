function [T,report] = loadGenericBarData(filePath,cfg)
%LOADGENERICBARDATA Carga un CSV OHLCV sencillo y lo normaliza.
%
% Acepta datetime_local, datetime_new_york o datetime.
% Las columnas mínimas son open, high, low, close y una fecha.

arguments
    filePath (1,1) string
    cfg (1,1) struct
end

if ~isfile(filePath)
    error("QuantLab:DataFileNotFound", ...
        "No se encuentra el archivo: %s",filePath);
end

opts = detectImportOptions( ...
    filePath,"Delimiter",",", ...
    "VariableNamingRule","preserve");
T = readtable(filePath,opts);
variables = string(T.Properties.VariableNames);

requiredPrice = ["open","high","low","close"];
missing = requiredPrice(~ismember(requiredPrice,variables));
if ~isempty(missing)
    error("QuantLab:GenericBarColumns", ...
        "Faltan columnas OHLC: %s",strjoin(missing,", "));
end

numericColumns = ["open","high","low","close","volume"];
for name = numericColumns
    if ismember(name,variables) && ~isnumeric(T.(name))
        T.(name) = str2double(string(T.(name)));
    end
end

session = normalizeSessionSpec(cfg);
dateCandidates = ["datetime_local","datetime_new_york","datetime"];
dateColumn = dateCandidates(find(ismember(dateCandidates,variables),1));

if isempty(dateColumn)
    error("QuantLab:GenericBarDateTime", ...
        "El CSV necesita datetime_local, datetime_new_york o datetime.");
end

if ~isdatetime(T.(dateColumn))
    T.(dateColumn) = parseGenericDateTime( ...
        T.(dateColumn),session.timezone);
end

T = ensureCanonicalBarData(T,cfg);
[T,report] = validateMarketData(T,cfg);
end

function dt = parseGenericDateTime(values,timeZone)
values = string(values);
formats = [ ...
    "yyyy-MM-dd HH:mm:ssXXX", ...
    "yyyy-MM-dd'T'HH:mm:ssXXX", ...
    "yyyy-MM-dd HH:mm:ss", ...
    "yyyy-MM-dd'T'HH:mm:ss"];

for format = formats
    try
        dt = datetime(values,"InputFormat",format, ...
            "TimeZone",char(timeZone));
        return;
    catch
    end
end

try
    dt = datetime(values,"TimeZone",char(timeZone));
catch ME
    error("QuantLab:GenericBarDateParse", ...
        "No se pudo interpretar la fecha: %s",ME.message);
end
end
