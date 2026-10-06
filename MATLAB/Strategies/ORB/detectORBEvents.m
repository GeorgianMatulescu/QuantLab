function orbEvents = detectORBEvents(data, daily, cfg)
%DETECTORBEVENTS Publica ORB_COMPLETED para cada sesión válida.

arguments
    data table
    daily table
    cfg (1,1) struct
end

rows = cell(height(daily),1);
k = 0;

for i = 1:height(daily)
    dayInfo = daily(i,:);

    if ~dayInfo.orb_valid
        continue;
    end

    D = data(data.session_date_new_york == dayInfo.session_date,:);
    D = sortrows(D, "datetime_new_york");

    completedMask = D.time_new_york >= cfg.orbEnd;
    idx = find(completedMask, 1, "first");

    if isempty(idx)
        continue;
    end

    payload = struct( ...
        "orb_open", dayInfo.orb_open, ...
        "orb_high", dayInfo.orb_high, ...
        "orb_low", dayInfo.orb_low, ...
        "orb_close", dayInfo.orb_close, ...
        "orb_range_points", dayInfo.orb_range_points, ...
        "orb_direction", string(dayInfo.orb_direction), ...
        "is_full_session", dayInfo.is_full_session);

    k = k + 1;
    rows{k} = makeEvent( ...
        "ORB_COMPLETED", ...
        D.datetime_new_york(idx), ...
        dayInfo.session_date, ...
        string(D.symbol(1)), ...
        find(data.datetime_new_york == D.datetime_new_york(idx), 1, "first"), ...
        dayInfo.orb_close, ...
        string(dayInfo.orb_direction), ...
        "ORBDetector", ...
        payload);
end

if k == 0
    orbEvents = createEventTable();
    return;
end

rows = rows(1:k);
orbEvents = vertcat(rows{:});
orbEvents = sortrows(orbEvents, ["event_time","bar_index"]);
end
