function sliced = sliceMarketDataBySession(data,startDate,endDate)
%SLICEMARKETDATABYSESSION Extrae un intervalo inclusivo de sesiones.
%
% La comparación usa claves yyyyMMdd para evitar diferencias de timezone
% entre fechas que representan la misma sesión de mercado.

arguments
    data table
    startDate (1,1) datetime
    endDate (1,1) datetime
end

if startDate>endDate
    error("QuantLab:OptimizationSliceRange", ...
        "La fecha inicial no puede ser posterior a la final.");
end

sessionDates = extractOptimizationSessionDates(data);
keys = string(sessionDates,"yyyyMMdd");
startKey = string(startDate,"yyyyMMdd");
endKey = string(endDate,"yyyyMMdd");

mask = keys>=startKey & keys<=endKey;
sliced = data(mask,:);
end
