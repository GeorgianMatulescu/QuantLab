function daily = buildGenericSessionSummary(data,cfg)
%BUILDGENERICSESSIONSUMMARY OHLC diario común para estrategias de barras.

grouped = groupBarDataBySession(data,cfg);
session = normalizeSessionSpec(cfg);
n = numel(grouped.session_dates);

session_date = grouped.session_dates;
session_open = nan(n,1);
session_high = nan(n,1);
session_low = nan(n,1);
session_close = nan(n,1);
bars_received = zeros(n,1);
is_full_session = false(n,1);

for i = 1:n
    D = grouped.session_data{i};
    if isempty(D), continue; end
    session_open(i) = D.open(1);
    session_high(i) = max(D.high,[],"omitnan");
    session_low(i) = min(D.low,[],"omitnan");
    session_close(i) = D.close(end);
    bars_received(i) = height(D);

    if session.expectedBarsPerSession>0
        is_full_session(i) = ...
            height(D)>=session.expectedBarsPerSession;
    else
        is_full_session(i) = true;
    end
end

daily = table( ...
    session_date,session_open,session_high,session_low, ...
    session_close,bars_received,is_full_session);
end
