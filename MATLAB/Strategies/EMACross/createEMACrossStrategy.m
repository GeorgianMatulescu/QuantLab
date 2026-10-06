function plugin = createEMACrossStrategy()
%CREATEEMACROSSSTRATEGY Portable bar-strategy reference plugin.

plugin = struct();
plugin.name = "EMA_CROSS";
plugin.displayName = "EMA Crossover";
plugin.version = "1.0.0";
plugin.enabled = true;
plugin.description = ...
    "EMA crossover with ATR stop, fixed RR and intraday controls.";
plugin.assetClasses = ["FUTURE","STOCK","FOREX","CRYPTO"];
plugin.dataContractVersion = "BAR_V1";
plugin.tradeContractVersion = "TRADE_V1";
plugin.requiredDataColumns = [ ...
    "datetime_local","session_date","time_local", ...
    "open","high","low","close","volume","symbol"];
plugin.requiredEventTypes = [ ...
    "NEW_SESSION","NEW_BAR","SESSION_CLOSED"];
plugin.buildEvents = @buildEMACrossContext;
plugin.run = @runEMACrossPlugin;
plugin.runProfile = @runEMACrossProfileOptimization;
plugin.featureCatalog = @buildEMACrossFeatureCatalog;
plugin.parameterSchema = @buildEMACrossParameterSchema;
plugin.analysisCapabilities = @buildEMACrossAnalysisCapabilities;
plugin.validateConfig = @validateEMACrossConfig;
end
