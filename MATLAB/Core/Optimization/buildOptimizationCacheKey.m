function key = buildOptimizationCacheKey( ...
    strategyName,profileName,trainingPct,parameterSet,cacheNamespace)
%BUILDOPTIMIZATIONCACHEKEY Clave determinista por configuración.

arguments
    strategyName (1,1) string
    profileName (1,1) string
    trainingPct (1,1) double
    parameterSet table
    cacheNamespace (1,1) string = "FULL"
end

parameterSet = sortrows(parameterSet,"name");
parts = strings(height(parameterSet),1);

for i = 1:height(parameterSet)
    parts(i) = parameterSet.name(i) + "=" + ...
        string(sprintf("%.15g",parameterSet.value(i)));
end

key = strategyName + "|" + profileName + ...
    "|namespace=" + cacheNamespace + ...
    "|split=" + string(sprintf("%.8g",trainingPct)) + ...
    "|" + strjoin(parts,";");
end
