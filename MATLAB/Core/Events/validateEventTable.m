function validateEventTable(events)
%VALIDATEEVENTTABLE Valida la interfaz estándar del Event Engine.

if ~istable(events)
    error("QuantLab:InvalidEvents", "Los eventos deben ser una tabla.");
end

required = [ ...
    "event_type","event_time","session_date","symbol", ...
    "bar_index","price","direction","source","payload"];

missing = required(~ismember(required, string(events.Properties.VariableNames)));

if ~isempty(missing)
    error("QuantLab:InvalidEventSchema", ...
        "La tabla de eventos no contiene: %s", ...
        strjoin(missing, ", "));
end

if isempty(events)
    error("QuantLab:EmptyEvents", ...
        "El Event Engine no generó ningún evento.");
end

if any(ismissing(events.event_type))
    error("QuantLab:MissingEventType", ...
        "Hay eventos sin event_type.");
end

events = sortrows(events, ["event_time","bar_index"]); %#ok<NASGU>
end
