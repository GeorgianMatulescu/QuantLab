function validateCanonicalBarData(T)
%VALIDATECANONICALBARDATA Valida el contrato OHLCV BarData v1.

required = [ ...
    "datetime","datetime_local","session_date","time_local", ...
    "open","high","low","close","volume","symbol"];

missing = required(~ismember( ...
    required,string(T.Properties.VariableNames)));

if ~isempty(missing)
    error("QuantLab:BarDataContract", ...
        "BarData v1 incompleto. Faltan: %s", ...
        strjoin(missing,", "));
end

if ~isdatetime(T.datetime) || ~isdatetime(T.datetime_local) || ...
        ~isdatetime(T.session_date) || ~isduration(T.time_local)
    error("QuantLab:BarDataTemporalTypes", ...
        "Tipos temporales no compatibles con BarData v1.");
end

numeric = ["open","high","low","close","volume"];
for field = numeric
    if ~isnumeric(T.(field))
        error("QuantLab:BarDataNumericType", ...
            "%s debe ser numérico.",field);
    end
end
end
