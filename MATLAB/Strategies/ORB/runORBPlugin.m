function results = runORBPlugin(data, context, events, cfg)
%RUNORBPLUGIN Adaptador ORB para el Strategy Framework.

arguments
    data table
    context (1,1) struct
    events table
    cfg (1,1) struct
end

validateORBEventCount(events,context.daily);

sessionData = cell(0,1);

if isfield(context,"session_data")
    sessionData = context.session_data;
end

results = runORBScenarioComparison( ...
    data,context.daily,cfg,sessionData);

results.event_summary = summarizeEvents(events);
end

function validateORBEventCount(events,daily)
orbCompleted = filterEvents(events,"ORB_COMPLETED");

if height(orbCompleted)~=nnz(daily.orb_valid)
    error("QuantLab:ORBEventMismatch", ...
        "ORB_COMPLETED no coincide con las ORB válidas.");
end
end

function summary = summarizeEvents(events)
types = unique(string(events.event_type));
counts = zeros(numel(types),1);

for i = 1:numel(types)
    counts(i) = nnz( ...
        string(events.event_type)==types(i));
end

summary = table(types,counts, ...
    'VariableNames',{'event_type','count'});
end
