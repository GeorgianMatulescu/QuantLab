function filtered = filterEvents(events, eventTypes)
%FILTEREVENTS Filtra eventos por uno o varios tipos.

arguments
    events table
    eventTypes string
end

mask = ismember(string(events.event_type), string(eventTypes));
filtered = events(mask,:);
end
