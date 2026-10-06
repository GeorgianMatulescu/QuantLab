function plugin = createTemplateBarStrategy()
%CREATETEMPLATEBARSTRATEGY Official SDK template — disabled by default.

plugin = struct();
plugin.name = "TEMPLATE_BAR";
plugin.displayName = "Template Bar Strategy";
plugin.version = "1.0.0";
plugin.enabled = false;
plugin.description = "Copy through createBarStrategyScaffold().";
plugin.assetClasses = ["FUTURE","STOCK","FOREX","CRYPTO"];
plugin.dataContractVersion = "BAR_V1";
plugin.tradeContractVersion = "TRADE_V1";
plugin.requiredDataColumns = [ ...
    "datetime_local","session_date","time_local", ...
    "open","high","low","close","volume","symbol"];
plugin.requiredEventTypes = [ ...
    "NEW_SESSION","NEW_BAR","SESSION_CLOSED"];
plugin.buildEvents = @buildTemplateBarContext;
plugin.run = @runTemplateBarPlugin;
plugin.featureCatalog = @buildTemplateBarFeatureCatalog;
plugin.parameterSchema = @buildTemplateBarParameterSchema;
plugin.analysisCapabilities = @buildTemplateBarAnalysisCapabilities;
plugin.validateConfig = @validateTemplateBarConfig;
end
