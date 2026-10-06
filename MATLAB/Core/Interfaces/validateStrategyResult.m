function validateStrategyResult(strategyResult)
%VALIDATESTRATEGYRESULT Valida la interfaz común de cualquier estrategia.

arguments
    strategyResult (1,1) struct
end

requiredFields = [ ...
    "strategy", ...
    "results", ...
    "config", ...
    "data", ...
    "events", ...
    "parameters", ...
    "feature_catalog", ...
    "parameter_schema", ...
    "analysis_capabilities", ...
    "created_at"];

missing = requiredFields(~isfield(strategyResult,requiredFields));

if ~isempty(missing)
    error("QuantLab:InvalidStrategyResult", ...
        "StrategyResult incompleto. Faltan: %s", ...
        strjoin(missing,", "));
end

if strlength(string(strategyResult.strategy))==0
    error("QuantLab:InvalidStrategyName", ...
        "StrategyResult.strategy no puede estar vacío.");
end

if ~isstruct(strategyResult.results)
    error("QuantLab:InvalidStrategyResults", ...
        "StrategyResult.results debe ser una estructura.");
end

if ~istable(strategyResult.feature_catalog)
    error("QuantLab:InvalidFeatureCatalog", ...
        "StrategyResult.feature_catalog debe ser una tabla.");
end

validateFeatureCatalog(strategyResult.feature_catalog);

if ~istable(strategyResult.parameter_schema)
    error("QuantLab:InvalidParameterSchema", ...
        "StrategyResult.parameter_schema debe ser una tabla.");
end

validateParameterSchema(strategyResult.parameter_schema);

if ~isstruct(strategyResult.analysis_capabilities)
    error("QuantLab:InvalidAnalysisCapabilities", ...
        "StrategyResult.analysis_capabilities debe ser una estructura.");
end

profiles = getDashboardProfiles(strategyResult.results);

for i = 1:numel(profiles)
    scenario = getDashboardScenario( ...
        strategyResult.results,profiles(i));

    if ~istable(scenario.trades)
        error("QuantLab:InvalidTradeTable", ...
            "El perfil %s no contiene una tabla trades válida.", ...
            profiles(i));
    end

    validateStrategyTradeTable( ...
        scenario.trades,string(strategyResult.strategy),profiles(i));
end
end
