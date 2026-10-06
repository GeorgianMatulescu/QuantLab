function daily = buildDailySessions(T, cfg)
%BUILDDAILYSESSIONS Resume cada sesión y crea la ORB de cinco minutos.

arguments
    T table
    cfg (1,1) struct
end

dates = unique(T.session_date_new_york);
n = numel(dates);

session_date = NaT(n,1,"TimeZone",cfg.marketTimezone);
bars = zeros(n,1);
is_full_session = false(n,1);

session_open = nan(n,1);
session_high = nan(n,1);
session_low = nan(n,1);
session_close = nan(n,1);

orb_open = nan(n,1);
orb_high = nan(n,1);
orb_low = nan(n,1);
orb_close = nan(n,1);
orb_range_points = nan(n,1);
orb_direction = strings(n,1);
orb_valid = false(n,1);

for i = 1:n
    d = dates(i);
    D = T(T.session_date_new_york == d, :);
    D = sortrows(D, "datetime_new_york");

    session_date(i) = d;
    bars(i) = height(D);
    is_full_session(i) = bars(i) == cfg.expectedBarsPerFullSession;

    session_open(i) = D.open(1);
    session_high(i) = max(D.high);
    session_low(i) = min(D.low);
    session_close(i) = D.close(end);

    orbMask = ...
        D.time_new_york >= cfg.orbStart & ...
        D.time_new_york < cfg.orbEnd;

    O = D(orbMask,:);

    expectedOrbBars = ...
        minutes(cfg.orbEnd - cfg.orbStart) / ...
        cfg.expectedBarMinutes;

    if height(O) ~= expectedOrbBars
        orb_direction(i) = "INVALID";
        continue;
    end

    orb_open(i) = O.open(1);
    orb_high(i) = max(O.high);
    orb_low(i) = min(O.low);
    orb_close(i) = O.close(end);
    orb_range_points(i) = orb_high(i) - orb_low(i);

    if orb_close(i) > orb_open(i)
        orb_direction(i) = "LONG";
    elseif orb_close(i) < orb_open(i)
        orb_direction(i) = "SHORT";
    else
        orb_direction(i) = "DOJI";
    end

    orb_valid(i) = true;
end

daily = table( ...
    session_date, ...
    bars, ...
    is_full_session, ...
    session_open, ...
    session_high, ...
    session_low, ...
    session_close, ...
    orb_open, ...
    orb_high, ...
    orb_low, ...
    orb_close, ...
    orb_range_points, ...
    orb_direction, ...
    orb_valid);
end
