clear;
clc;

matlabRoot = fileparts(fileparts(mfilename('fullpath')));
addpath(genpath(matlabRoot));

S = loadAuditWorkspace(matlabRoot,"ORB");
profiles = getDashboardProfiles(S.results);
scenario = getDashboardScenario(S.results,profiles(1));
trades = scenario.trades;

tradeIndex = find(trades.valid,1,"first");

if isempty(tradeIndex)
    tradeIndex = 1;
end

cache = buildTradeResearchCache(S.data);

fig = uifigure("Visible","off");
cleanup = onCleanup(@() delete(fig));

root = uigridlayout(fig,[1 2]);
ax = uiaxes(root);

infoGrid = uigridlayout(root,[3 1]);
titleLabel = uilabel(infoGrid);
detailsTable = uitable(infoGrid);
featuresArea = uitextarea(infoGrid);

showTradeResearchLoading(titleLabel,tradeIndex);

updateTradeResearchMode( ...
    ax,titleLabel,detailsTable,featuresArea, ...
    cache,trades(tradeIndex,:),tradeIndex,profiles(1));

assert(~startsWith( ...
    string(titleLabel.Text), ...
    "Cargando"), ...
    "Research quedó bloqueado en estado Cargando.");

assert(~isempty(detailsTable.Data), ...
    "No se cargaron los detalles del trade.");

assert(~isempty(allchild(ax)), ...
    "No se dibujó la sesión del trade.");

[sessionData,context] = getCachedTradeResearchData( ...
    cache,trades(tradeIndex,:));

assert(~isempty(sessionData));
assert(isstruct(context));

fprintf("TEST TRADE RESEARCH END TO END SUPERADO\n");
fprintf("Trade renderizado: %d\n",tradeIndex);
fprintf("Barras: %d\n",height(sessionData));
