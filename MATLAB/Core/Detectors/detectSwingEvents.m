function swingEvents = detectSwingEvents(data, cfg)
p = cfg.detectors.swing;
L = p.leftBars;
R = p.rightBars;
rows = cell(height(data),1);
k = 0;
dates = unique(data.session_date_new_york);

for d = 1:numel(dates)
    sessionDate = dates(d);
    D = sortrows(data(data.session_date_new_york == sessionDate,:), ...
        "datetime_new_york");
    n = height(D);
    if n < L + R + 1
        continue;
    end

    for i = (L+1):(n-R)
        leftHighs = D.high(i-L:i-1);
        rightHighs = D.high(i+1:i+R);
        leftLows = D.low(i-L:i-1);
        rightLows = D.low(i+1:i+R);

        if p.allowEqualHighs
            isHigh = D.high(i) >= max(leftHighs) && D.high(i) >= max(rightHighs);
        else
            isHigh = D.high(i) > max(leftHighs) && D.high(i) > max(rightHighs);
        end

        if p.allowEqualLows
            isLow = D.low(i) <= min(leftLows) && D.low(i) <= min(rightLows);
        else
            isLow = D.low(i) < min(leftLows) && D.low(i) < min(rightLows);
        end

        confirmationIndex = i + R;
        confirmationTime = D.datetime_new_york(confirmationIndex);
        globalIndex = find(data.datetime_new_york == confirmationTime,1,"first");

        if isHigh
            payload = struct("pivot_time",D.datetime_new_york(i), ...
                "confirmation_time",confirmationTime, ...
                "pivot_session_index",i, ...
                "confirmation_session_index",confirmationIndex, ...
                "left_bars",L,"right_bars",R);
            k = k + 1;
            rows{k} = makeEvent("SWING_HIGH",confirmationTime,sessionDate, ...
                string(D.symbol(1)),globalIndex,D.high(i), ...
                "BEARISH_REFERENCE","SwingDetector",payload);
        end

        if isLow
            payload = struct("pivot_time",D.datetime_new_york(i), ...
                "confirmation_time",confirmationTime, ...
                "pivot_session_index",i, ...
                "confirmation_session_index",confirmationIndex, ...
                "left_bars",L,"right_bars",R);
            k = k + 1;
            rows{k} = makeEvent("SWING_LOW",confirmationTime,sessionDate, ...
                string(D.symbol(1)),globalIndex,D.low(i), ...
                "BULLISH_REFERENCE","SwingDetector",payload);
        end
    end
end

if k == 0
    swingEvents = createEventTable();
else
    swingEvents = vertcat(rows{1:k});
    swingEvents = sortrows(swingEvents, ...
        ["event_time","bar_index","event_type"]);
end
end
