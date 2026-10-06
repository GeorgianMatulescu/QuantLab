function plugin = resolveStrategyPlugin(strategyName)
%RESOLVESTRATEGYPLUGIN Resuelve un plugin descubierto dinámicamente.

arguments
    strategyName (1,1) string
end

requested = upper(strtrim(strategyName));
registry = getStrategyRegistry();
names = upper(string({registry.name}));
index = find(names==requested,1,"first");

if isempty(index)
    available = names([registry.enabled]);
    error("QuantLab:UnknownStrategy", ...
        "Estrategia desconocida: %s. Disponibles: %s", ...
        strategyName,strjoin(available,", "));
end

entry = registry(index);

if ~entry.enabled
    message = entry.validationError;
    if strlength(message)==0
        message = "Plugin desactivado.";
    end
    error("QuantLab:StrategyNotAvailable", ...
        "%s no está disponible: %s",strategyName,message);
end

plugin = entry.factory();
validateStrategyPlugin(plugin);
end
