clear;
clc;

matlabRoot = fileparts(fileparts(mfilename('fullpath')));
addpath(genpath(matlabRoot));

S = loadAuditWorkspace(matlabRoot,"ORB");
profiles = getDashboardProfiles(S.results);
scenario = getDashboardScenario(S.results,profiles(1));

trades = scenario.trades;
executedIndex = find(trades.valid,1,"first");

assert(~isempty(executedIndex));

tradeRow = trades(executedIndex,:);

details = buildTradeResearchDetails( ...
    tradeRow,executedIndex,profiles(1));

features = buildTradeFeatureLines(tradeRow);

assert(istable(details));
assert(height(details)>=10);
assert(isstring(features));
assert(size(features,2)==1);

requiredFiles = [ ...
    "updateTradeResearchMode.m"; ...
    "buildTradeResearchDetails.m"; ...
    "buildTradeFeatureLines.m"; ...
    "plotTradeSessionChart.m"; ...
    "clearTradeResearchView.m"];

for i = 1:numel(requiredFiles)
    assert(isfile(fullfile( ...
        matlabRoot,"Dashboard","Components", ...
        requiredFiles(i))));
end

fprintf("TEST TRADE RESEARCH MODE SUPERADO\n");
fprintf("Trade de prueba: %d\n",executedIndex);
