clear;
clc;

matlabRoot = fileparts(mfilename('fullpath'));
addpath(genpath(matlabRoot));

cfg = loadQuantLabConfig(matlabRoot);
[data,dataReport] = loadMarketData(cfg.dataFile,cfg);

strategyOutput = runStrategy("ORB",data,cfg);
swingEvents = detectSwingEvents(data,cfg);

allEvents = [strategyOutput.events; swingEvents];
allEvents = sortrows(allEvents, ...
    ["event_time","bar_index","event_type"]);

market = runMarketStateEngine(data,allEvents,cfg);

fprintf('\n=== QUANTLAB MARKET STATE ENGINE v0.6 ===\n');
fprintf('Filas:           %d\n',height(data));
fprintf('Duplicados:      %d\n',dataReport.duplicatesRemoved);
fprintf('Eventos totales: %d\n',height(market.timeline));
fprintf('Snapshots:       %d\n\n',height(market.snapshots));

disp(market.timelineSummary);

reportDir = fullfile(cfg.matlabRoot,"Reports","MarketState");
if ~isfolder(reportDir)
    mkdir(reportDir);
end

writetable(market.timeline, ...
    fullfile(reportDir,"market_event_timeline.csv"));
writetable(market.timelineSummary, ...
    fullfile(reportDir,"market_event_summary.csv"));
writetable(market.snapshots, ...
    fullfile(reportDir,"market_state_snapshots.csv"));

save(fullfile(reportDir,"latest_market_state.mat"), ...
    "market","cfg","-v7.3");

fprintf('\nInformes creados en:\n%s\n',reportDir);
