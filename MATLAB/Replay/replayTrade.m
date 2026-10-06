function replayTrade(data, results, selector, profileName, pauseSeconds)
%REPLAYTRADE Reproduce una sesión barra a barra.
%
% Ejemplo:
%   replayTrade(data, results, 12, "REALISTIC", 0.05)

arguments
    data table
    results (1,1) struct
    selector
    profileName (1,1) string = "REALISTIC"
    pauseSeconds (1,1) double {mustBeNonnegative} = 0.05
end

trades = getScenarioTrades(results, profileName);
[trade, rowIndex] = resolveTradeSelector(trades, selector);

mask = dateshift(data.session_date_new_york, "start", "day") == ...
       dateshift(trade.session_date, "start", "day");
D = sortrows(data(mask,:), "datetime_new_york");

if isempty(D)
    error("QuantLab:SessionDataNotFound", ...
        "No hay datos para la sesión seleccionada.");
end

fig = figure("Name", sprintf("Replay #%d - %s", ...
    rowIndex, string(trade.session_date)), "NumberTitle", "off");
ax = axes(fig);
grid(ax, "on");
hold(ax, "on");

allLow = min(D.low);
allHigh = max(D.high);
ylim(ax, [allLow allHigh]);

for i = 1:height(D)
    x = D.datetime_new_york(i);
    plot(ax, [x x], [D.low(i) D.high(i)], "-", "LineWidth", 0.5);

    halfWidth = seconds(18);
    plot(ax, [x-halfWidth x], [D.open(i) D.open(i)], "-", "LineWidth", 0.7);
    plot(ax, [x x+halfWidth], [D.close(i) D.close(i)], "-", "LineWidth", 0.7);

    if i == 1
        yline(ax, trade.orb_high, "--", "ORB High");
        yline(ax, trade.orb_low, "--", "ORB Low");

        if trade.valid
            yline(ax, trade.entry_price, "-", "Entrada");
            yline(ax, trade.stop_price, "-", "Stop");
            yline(ax, trade.target_price, "-", "Target");
        end
    end

    xlim(ax, [D.datetime_new_york(1), D.datetime_new_york(max(i,2))]);
    title(ax, sprintf("Replay #%d | %s | %s", ...
        rowIndex, string(D.datetime_new_york(i)), profileName));
    drawnow;

    if ~isvalid(fig)
        return;
    end

    pause(pauseSeconds);
end

if trade.valid
    plot(ax, trade.entry_time, trade.entry_price, ...
        "o", "MarkerSize", 7, "LineWidth", 1.5);
    plot(ax, trade.exit_time, trade.exit_price, ...
        "x", "MarkerSize", 9, "LineWidth", 1.8);
end

hold(ax, "off");
end
