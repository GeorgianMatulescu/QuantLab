function plugin = createORBStrategy()
%CREATEORBSTRATEGY Factory del plugin ORB.

plugin = struct();

plugin.name = "ORB";
plugin.displayName = "Opening Range Breakout";
plugin.version = "0.7.0";
plugin.enabled = true;
plugin.assetClasses = ["FUTURE","STOCK","FOREX","CRYPTO"];
plugin.dataContractVersion = "BAR_V1";
plugin.tradeContractVersion = "TRADE_V1";
plugin.description = ...
    "Opening Range Breakout de 5 minutos con perfiles de ejecución.";

plugin.requiredDataColumns = [ ...
    "datetime_new_york", ...
    "session_date_new_york", ...
    "time_new_york", ...
    "open","high","low","close","volume","symbol"];

plugin.requiredEventTypes = [ ...
    "NEW_SESSION", ...
    "NEW_BAR", ...
    "ORB_COMPLETED", ...
    "SESSION_CLOSED"];

plugin.buildEvents = @buildORBEventContext;
plugin.run = @runORBPlugin;
plugin.runProfile = @runORBProfileOptimization;

% Metadatos opcionales consumidos por el Research Lab genérico.
plugin.featureCatalog = @buildORBFeatureCatalog;
plugin.parameterSchema = @buildORBParameterSchema;
plugin.analysisCapabilities = @buildORBAnalysisCapabilities;
plugin.validateConfig = @validateORBConfig;
end
