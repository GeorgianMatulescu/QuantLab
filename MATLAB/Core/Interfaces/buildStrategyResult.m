function strategyResult = buildStrategyResult( ...
    strategyName,results,cfg,data,events,parameters, ...
    featureCatalog,parameterSchema,analysisCapabilities)
%BUILDSTRATEGYRESULT Construye la interfaz común del Research Terminal.
%
% Campos base:
%   strategyResult.strategy
%   strategyResult.results
%   strategyResult.config
%   strategyResult.data
%   strategyResult.events
%   strategyResult.parameters
%   strategyResult.created_at
%
% Contrato de investigación reutilizable:
%   strategyResult.feature_catalog
%   strategyResult.parameter_schema
%   strategyResult.analysis_capabilities
%
% Si una estrategia no proporciona metadatos, QuantLab infiere un catálogo
% conservador desde su tabla de trades y excluye outcomes conocidos.

arguments
    strategyName (1,1) string
    results (1,1) struct
    cfg (1,1) struct
    data table = table()
    events table = table()
    parameters (1,1) struct = struct()
    featureCatalog table = table()
    parameterSchema table = table()
    analysisCapabilities (1,1) struct = struct()
end

[resolvedCatalog,resolvedParameters,resolvedCapabilities] = ...
    resolveStrategyResearchSchema(strategyName,results);

if isempty(featureCatalog)
    featureCatalog = resolvedCatalog;
else
    featureCatalog = normalizeFeatureCatalog(featureCatalog);
end

if isempty(parameterSchema)
    parameterSchema = resolvedParameters;
end

parameterSchema = normalizeParameterSchema(parameterSchema);

if isempty(fieldnames(analysisCapabilities))
    analysisCapabilities = resolvedCapabilities;
end

strategyResult = struct( ...
    "strategy",strategyName, ...
    "results",results, ...
    "config",cfg, ...
    "data",data, ...
    "events",events, ...
    "parameters",parameters, ...
    "feature_catalog",featureCatalog, ...
    "parameter_schema",parameterSchema, ...
    "analysis_capabilities",analysisCapabilities, ...
    "created_at",datetime("now"));
end
