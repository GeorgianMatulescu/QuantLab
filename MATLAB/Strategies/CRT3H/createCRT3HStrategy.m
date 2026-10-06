function plugin = createCRT3HStrategy()
%CREATECRT3HSTRATEGY Plugin CRT 3H de Londres y Nueva York.

plugin = struct();
plugin.name = "CRT_3H_MADRID";
plugin.displayName = "CRT 3H Madrid";
plugin.version = "1.10.0";
plugin.enabled = true;
plugin.description = ...
    "CRT 3H con entrada fraccional configurable en horario de Madrid.";
plugin.assetClasses = ["FUTURE","STOCK","FOREX","CRYPTO"];
plugin.dataContractVersion = "BAR_V1";
plugin.tradeContractVersion = "TRADE_V1";
plugin.requiredDataColumns = [ ...
    "datetime_local","session_date","time_local", ...
    "open","high","low","close","volume","symbol"];
plugin.requiredEventTypes = [ ...
    "NEW_SESSION","NEW_BAR","SESSION_CLOSED"];
plugin.buildEvents = @buildCRT3HContext;
plugin.run = @runCRT3HPlugin;
plugin.runProfile = @runCRT3HProfileOptimization;
plugin.featureCatalog = @buildCRT3HFeatureCatalog;
plugin.parameterSchema = @buildCRT3HParameterSchema;
plugin.analysisCapabilities = @buildCRT3HAnalysisCapabilities;
plugin.validateConfig = @validateCRT3HConfig;
end
