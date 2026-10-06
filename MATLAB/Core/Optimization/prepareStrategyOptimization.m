function prepared = prepareStrategyOptimization( ...
    strategyName,data,baseCfg,selectedSchema)
%PREPARESTRATEGYOPTIMIZATION Reutiliza eventos cuando es seguro.
%
% Si alguno de los parámetros seleccionados modifica la detección de
% eventos, cada combinación reconstruirá el contexto completo.

arguments
    strategyName (1,1) string
    data table
    baseCfg (1,1) struct
    selectedSchema table
end

selectedSchema = normalizeParameterSchema(selectedSchema);
plugin = resolveStrategyPlugin(strategyName);

rebuildEvents = any(selectedSchema.rebuild_events);

prepared = struct( ...
    "use_prepared_context",false, ...
    "plugin",plugin, ...
    "context",struct(), ...
    "events",table());

if rebuildEvents
    return;
end

[events,context] = plugin.buildEvents(data,baseCfg);
validateEventTable(events);

missingEvents = setdiff( ...
    string(plugin.requiredEventTypes), ...
    unique(string(events.event_type)));

if ~isempty(missingEvents)
    error("QuantLab:OptimizationMissingEvents", ...
        "No se generaron eventos requeridos: %s", ...
        strjoin(missingEvents,", "));
end

prepared.use_prepared_context = true;
prepared.context = context;
prepared.events = events;
end
