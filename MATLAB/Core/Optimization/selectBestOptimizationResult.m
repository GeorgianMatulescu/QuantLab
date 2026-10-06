function [bestRow,bestIndex] = ...
    selectBestOptimizationResult(results,metricName)
%SELECTBESTOPTIMIZATIONRESULT Selecciona una configuración sin ORB logic.

arguments
    results table
    metricName (1,1) string
end

bestRow = table();
bestIndex = NaN;

if isempty(results)
    return;
end

[fieldName,direction] = ...
    resolveOptimizationMetricDefinition(metricName);

valid = results.status=="OK" & ...
    ~isnan(results.(fieldName));

candidates = find(valid);

if isempty(candidates)
    return;
end

values = results.(fieldName)(candidates);

if direction=="descend"
    [~,localIndex] = max(values);
else
    [~,localIndex] = min(values);
end

bestIndex = candidates(localIndex);
bestRow = results(bestIndex,:);
end
