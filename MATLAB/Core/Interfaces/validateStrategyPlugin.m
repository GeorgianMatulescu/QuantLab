function validateStrategyPlugin(plugin)
%VALIDATESTRATEGYPLUGIN Contrato Strategy Plugin v1.

requiredFields = [ ...
    "name","displayName","version","description", ...
    "assetClasses","dataContractVersion","tradeContractVersion", ...
    "requiredDataColumns","requiredEventTypes", ...
    "run","buildEvents"];

missing = requiredFields(~isfield(plugin,requiredFields));

if ~isempty(missing)
    error("QuantLab:InvalidStrategyPlugin", ...
        "El plugin no cumple Strategy Plugin v1. Faltan: %s", ...
        strjoin(missing,", "));
end

if strlength(string(plugin.name))==0 || ...
        strlength(string(plugin.version))==0
    error("QuantLab:StrategyIdentity", ...
        "name y version son obligatorios.");
end

if ~isa(plugin.run,"function_handle") || ...
        ~isa(plugin.buildEvents,"function_handle")
    error("QuantLab:StrategyFunctions", ...
        "run y buildEvents deben ser function_handle.");
end

optionalFunctions = [ ...
    "runProfile","featureCatalog","parameterSchema", ...
    "analysisCapabilities","validateConfig"];

for field = optionalFunctions
    if isfield(plugin,field) && ...
            ~isa(plugin.(field),"function_handle")
        error("QuantLab:StrategyOptionalFunction", ...
            "%s debe ser function_handle.",field);
    end
end

allowedAssets = ["FUTURE","STOCK","FOREX","CRYPTO"];
invalidAssets = setdiff( ...
    upper(string(plugin.assetClasses)),allowedAssets);
if ~isempty(invalidAssets)
    error("QuantLab:StrategyAssetClass", ...
        "Asset classes no soportadas: %s", ...
        strjoin(invalidAssets,", "));
end

if isfield(plugin,"featureCatalog")
    validateFeatureCatalog(plugin.featureCatalog());
end

if isfield(plugin,"parameterSchema")
    validateParameterSchema(plugin.parameterSchema());
end

if isfield(plugin,"analysisCapabilities") && ...
        ~isstruct(plugin.analysisCapabilities())
    error("QuantLab:StrategyCapabilities", ...
        "analysisCapabilities debe devolver struct.");
end
end
