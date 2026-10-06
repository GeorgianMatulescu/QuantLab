function schema = getStrategyResearchSchema(strategyRun,trades)
%GETSTRATEGYRESEARCHSCHEMA Recupera metadatos con fallback automático.

arguments
    strategyRun (1,1) struct
    trades table
end

if isfield(strategyRun,"feature_catalog") && ...
        istable(strategyRun.feature_catalog)
    featureCatalog = strategyRun.feature_catalog;
else
    featureCatalog = inferFeatureCatalog(trades);
end

if isfield(strategyRun,"parameter_schema") && ...
        istable(strategyRun.parameter_schema)
    parameterSchema = strategyRun.parameter_schema;
else
    parameterSchema = table();
end

if isfield(strategyRun,"analysis_capabilities") && ...
        isstruct(strategyRun.analysis_capabilities)
    capabilities = strategyRun.analysis_capabilities;
else
    capabilities = struct("segment_explorer",true);
end

schema = struct( ...
    "featureCatalog",normalizeFeatureCatalog(featureCatalog), ...
    "parameterSchema",normalizeParameterSchema(parameterSchema), ...
    "capabilities",capabilities);
end
