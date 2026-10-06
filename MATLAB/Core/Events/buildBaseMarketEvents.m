function events = buildBaseMarketEvents(data,cfg)
%BUILDBASEMARKETEVENTS Eventos comunes para cualquier estrategia de barras.

arguments
    data table
    cfg (1,1) struct
end

data = ensureCanonicalBarData(data,cfg);
session = normalizeSessionSpec(cfg);
events = createEventTable();
dates = unique(data.session_date);
rows = cell(height(data)+2*numel(dates),1);
k = 0;
globalBarIndex = 0;

for i = 1:numel(dates)
    d = dates(i);
    D = data(data.session_date==d,:);
    D = sortrows(D,"datetime_local");
    if isempty(D), continue; end

    symbol = string(D.symbol(1));
    k = k+1;
    rows{k} = makeEvent( ...
        "NEW_SESSION",D.datetime_local(1),d,symbol, ...
        globalBarIndex+1,D.open(1),"","BaseMarketEvents", ...
        struct("bars_expected",session.expectedBarsPerSession));

    for j = 1:height(D)
        globalBarIndex = globalBarIndex+1;
        payload = struct( ...
            "open",D.open(j),"high",D.high(j), ...
            "low",D.low(j),"close",D.close(j), ...
            "volume",D.volume(j), ...
            "time_local",D.time_local(j), ...
            "time_new_york",D.time_local(j));

        k = k+1;
        rows{k} = makeEvent( ...
            "NEW_BAR",D.datetime_local(j),d,symbol, ...
            globalBarIndex,D.close(j),"","BaseMarketEvents",payload);
    end

    k = k+1;
    rows{k} = makeEvent( ...
        "SESSION_CLOSED",D.datetime_local(end),d,symbol, ...
        globalBarIndex,D.close(end),"","BaseMarketEvents", ...
        struct("bars_received",height(D)));
end

rows = rows(1:k);
if isempty(rows)
    events = createEventTable();
else
    events = vertcat(rows{:});
    events = sortrows(events,["event_time","bar_index","event_type"]);
end
end
