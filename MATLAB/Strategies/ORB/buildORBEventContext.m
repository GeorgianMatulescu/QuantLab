function [events, context] = buildORBEventContext(data, cfg)
%BUILDORBEVENTCONTEXT Construye eventos y contexto diario de ORB.
%
% session_data se prepara una sola vez y se reutiliza en todos los
% perfiles y combinaciones del optimizador.

daily = buildDailySessions(data, cfg);
baseEvents = buildBaseMarketEvents(data, cfg);
orbEvents = detectORBEvents(data, daily, cfg);

events = [baseEvents; orbEvents];
events = sortrows(events, ...
    ["event_time","bar_index","event_type"]);

sessionData = buildORBSessionDataCache(data,daily);

context = struct( ...
    "daily",daily, ...
    "session_data",{sessionData}, ...
    "strategy_name","ORB");
end
