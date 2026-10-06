function [fieldName,direction,label] = ...
    getOptimizationMetricDefinition(metricName)
%GETOPTIMIZATIONMETRICDEFINITION Dashboard wrapper for shared contract.

[fieldName,direction,label] = ...
    resolveOptimizationMetricDefinition(metricName);
end
