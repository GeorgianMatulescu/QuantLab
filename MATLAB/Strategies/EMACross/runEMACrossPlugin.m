function results = runEMACrossPlugin(data,context,events,cfg)
%RUNEMACROSSPLUGIN Ejecuta todos los perfiles configurados.

arguments
    data table
    context (1,1) struct
    events table
    cfg (1,1) struct
end

profiles = cfg.executionProfiles;
rows = cell(numel(profiles),1);
results = struct();

for i = 1:numel(profiles)
    [trades,summary] = runEMACrossScenario( ...
        data,context,cfg,profiles(i));
    field = matlab.lang.makeValidName(profiles(i).name);
    results.(field) = struct("trades",trades,"summary",summary);
    rows{i} = summary;
end

results.summaryTable = struct2table(vertcat(rows{:}));
results.event_summary = summarizeEvents(events);
end

function summary = summarizeEvents(events)
types = unique(string(events.event_type));
counts = zeros(numel(types),1);
for i = 1:numel(types)
    counts(i) = nnz(string(events.event_type)==types(i));
end
summary = table(types,counts, ...
    'VariableNames',{'event_type','count'});
end
