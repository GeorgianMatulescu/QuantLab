function results = runTemplateBarPlugin(data,context,events,cfg)
%RUNTEMPLATEBARPLUGIN Replace with the strategy runner.

profiles = cfg.executionProfiles;
results = struct();
rows = cell(numel(profiles),1);

for i = 1:numel(profiles)
    trades = table();
    summary = calculateScenarioStatistics(trades,cfg,profiles(i));
    field = matlab.lang.makeValidName(profiles(i).name);
    results.(field) = struct("trades",trades,"summary",summary);
    rows{i} = summary;
end

results.summaryTable = struct2table(vertcat(rows{:}));
end
