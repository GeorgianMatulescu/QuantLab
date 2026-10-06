function results = runORBScenarioComparison( ...
    T,daily,cfg,sessionData)
%RUNORBSCENARIOCOMPARISON Ejecuta todos los perfiles configurados.

if nargin<4
    sessionData = cell(0,1);
end

profiles = cfg.executionProfiles;
rows = cell(numel(profiles),1);
results = struct();

for i = 1:numel(profiles)
    [trades,summary] = runORBScenario( ...
        T,daily,cfg,profiles(i),sessionData);

    field = matlab.lang.makeValidName( ...
        profiles(i).name);

    results.(field) = struct( ...
        "trades",trades, ...
        "summary",summary);

    rows{i} = summary;
end

results.summaryTable = ...
    struct2table(vertcat(rows{:}));
end
