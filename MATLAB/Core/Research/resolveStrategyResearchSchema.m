function [featureCatalog,parameterSchema,capabilities] = ...
    resolveStrategyResearchSchema(strategyName,results)
%RESOLVESTRATEGYRESEARCHSCHEMA Resuelve esquema genérico + plugin.

arguments
    strategyName (1,1) string
    results (1,1) struct
end

trades = firstTradeTable(results);
featureCatalog = inferFeatureCatalog(trades);
parameterSchema = table();

capabilities = struct( ...
    "calendar_analytics",true, ...
    "trade_distribution",true, ...
    "segment_explorer",true, ...
    "parameter_sweep",false, ...
    "walk_forward",false, ...
    "mfe_mae",false, ...
    "intraday_replay",false);

try
    plugin = resolveStrategyPlugin(strategyName);

    if isfield(plugin,"featureCatalog")
        customCatalog = evaluateMetadata(plugin.featureCatalog);
        featureCatalog = mergeFeatureCatalog( ...
            featureCatalog,customCatalog);
    end

    if isfield(plugin,"parameterSchema")
        parameterSchema = evaluateMetadata(plugin.parameterSchema);
    end

    if isfield(plugin,"analysisCapabilities")
        pluginCapabilities = ...
            evaluateMetadata(plugin.analysisCapabilities);

        fields = string(fieldnames(pluginCapabilities));

        for field = fields'
            capabilities.(field) = pluginCapabilities.(field);
        end
    end
catch
    % Una estrategia no registrada sigue siendo analizable mediante
    % inferencia automática. El dashboard no depende del registry.
end

featureCatalog = normalizeFeatureCatalog(featureCatalog);
end

function value = evaluateMetadata(metadata)
if isa(metadata,"function_handle")
    value = metadata();
else
    value = metadata;
end
end

function trades = firstTradeTable(results)
trades = table();

try
    profiles = getDashboardProfiles(results);

    if isempty(profiles)
        return;
    end

    scenario = getDashboardScenario(results,profiles(1));
    trades = scenario.trades;
catch
end
end
