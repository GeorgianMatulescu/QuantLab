function plugin = createSessionRangeStrategy()
%CREATESESSIONRANGESTRATEGY Rangos Asia/Londres con ejecución CRT.

plugin = struct();
plugin.name = "SESSION_RANGE_MADRID";
plugin.displayName = "Rangos Asia y Londres - Madrid";
plugin.version = "1.1.0";
plugin.enabled = true;
plugin.description = ...
    "Sweep y retorno CRT sobre rangos de sesión Asia/Londres.";
plugin.assetClasses = ["FUTURE","STOCK","FOREX","CRYPTO"];
plugin.dataContractVersion = "BAR_V1";
plugin.tradeContractVersion = "TRADE_V1";
plugin.requiredDataColumns = [ ...
    "datetime_local","session_date","time_local", ...
    "open","high","low","close","volume","symbol"];
plugin.requiredEventTypes = [ ...
    "NEW_SESSION","NEW_BAR","SESSION_CLOSED"];
plugin.buildEvents = @buildSessionRangeContext;
plugin.run = @runCRT3HPlugin;
plugin.runProfile = @runCRT3HProfileOptimization;
plugin.featureCatalog = @buildSessionRangeFeatureCatalog;
plugin.parameterSchema = @buildSessionRangeParameterSchema;
plugin.analysisCapabilities = @buildCRT3HAnalysisCapabilities;
plugin.validateConfig = @validateCRT3HConfig;
end
