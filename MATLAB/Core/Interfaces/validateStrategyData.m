function validateStrategyData(data, plugin)
%VALIDATESTRATEGYDATA Comprueba las columnas que necesita la estrategia.

available = string(data.Properties.VariableNames);
required = string(plugin.requiredDataColumns);
missing = required(~ismember(required, available));

if ~isempty(missing)
    error("QuantLab:MissingStrategyData", ...
        "La estrategia %s necesita estas columnas: %s", ...
        plugin.name, strjoin(missing, ", "));
end
end
