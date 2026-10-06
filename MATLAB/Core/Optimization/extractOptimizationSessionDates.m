function sessionDates = extractOptimizationSessionDates(data)
%EXTRACTOPTIMIZATIONSESSIONDATES Obtiene una fecha de sesión por fila.
%
% El optimizador no presupone una estrategia. Solo busca columnas de fecha
% comunes en datos de mercado o trades y normaliza al inicio del día.

arguments
    data table
end

variables = string(data.Properties.VariableNames);
sourceName = "";

candidates = [ ...
    "session_date_new_york", ...
    "session_date", ...
    "datetime_new_york", ...
    "datetime", ...
    "date"];

for candidate = candidates
    if ismember(candidate,variables)
        sourceName = candidate;
        break;
    end
end

if strlength(sourceName)==0
    error("QuantLab:OptimizationSessionDate", ...
        "No se encontró una columna de fecha de sesión compatible.");
end

sessionDates = data.(sourceName);

if ~isdatetime(sessionDates)
    try
        sessionDates = datetime(string(sessionDates));
    catch ME
        error("QuantLab:OptimizationSessionDateParse", ...
            "No se pudo interpretar %s como fecha: %s", ...
            sourceName,ME.message);
    end
end

sessionDates = dateshift(sessionDates,"start","day");
end
