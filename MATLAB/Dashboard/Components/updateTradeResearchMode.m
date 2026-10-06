function updateTradeResearchMode( ...
    ax,titleLabel,detailsTable,featuresArea, ...
    researchCache,tradeRow,tradeIndex,profileName,varargin)
%UPDATETRADERESEARCHMODE Actualiza el panel Research de una operación.
%
% La sesión y el contexto se recuperan desde una caché precalculada,
% evitando recorrer todo el histórico de 1 minuto en cada clic.

resetResearchAxes(ax);

recordLabel = "Trade";
if ~isempty(varargin) && strlength(string(varargin{1}))>0
    recordLabel = string(varargin{1});
end

titleLabel.Text = sprintf( ...
    "%s #%d — %s", ...
    char(recordLabel), ...
    tradeIndex, ...
    char(string(profileName)));

detailsTable.Data = buildTradeResearchDetails( ...
    tradeRow,tradeIndex,profileName,recordLabel);

[sessionData,context] = getCachedTradeResearchData( ...
    researchCache,tradeRow);

featuresArea.Value = buildTradeFeatureLines( ...
    tradeRow,context);

if isempty(sessionData)
    text(ax,0.5,0.5, ...
        "No intraday bars found for this session", ...
        "HorizontalAlignment","center");
    return;
end

plotTradeSessionChart(ax,sessionData,tradeRow);
end
