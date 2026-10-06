function fig = plotTradeAudit(data, results, selector, profileName)
%PLOTTRADEAUDIT Dibuja una operación sobre barras OHLC de un minuto.
%
% Función genérica para cualquier estrategia que entregue:
% session_date, entry_time, exit_time, entry_price, stop_price,
% target_price, exit_price, direction, valid y skip_reason.

arguments
    data table
    results (1,1) struct
    selector
    profileName (1,1) string = "REALISTIC"
end

trades = getScenarioTrades(results, profileName);
[trade, rowIndex] = resolveTradeSelector(trades, selector);

sessionMask = dateshift(data.session_date_new_york, "start", "day") == ...
              dateshift(trade.session_date, "start", "day");
D = data(sessionMask,:);
D = sortrows(D, "datetime_new_york");

if isempty(D)
    error("QuantLab:SessionDataNotFound", ...
        "No hay barras para la sesión %s.", string(trade.session_date));
end

fig = figure("Name", sprintf("Trade Audit - %s - %s", ...
    profileName, string(trade.session_date)), "NumberTitle", "off");
ax = axes(fig);
hold(ax, "on");
grid(ax, "on");

plotOHLCBars(ax, D);

xStart = D.datetime_new_york(1);
xEnd = D.datetime_new_york(end);

yline(ax, trade.orb_high, "--", "ORB High");
yline(ax, trade.orb_low, "--", "ORB Low");

if trade.valid
    yline(ax, trade.entry_price, "-", "Entrada");
    yline(ax, trade.stop_price, "-", "Stop");
    yline(ax, trade.target_price, "-", "Target");

    plot(ax, trade.entry_time, trade.entry_price, ...
        "o", "MarkerSize", 7, "LineWidth", 1.5);
    plot(ax, trade.exit_time, trade.exit_price, ...
        "x", "MarkerSize", 9, "LineWidth", 1.8);

    title(ax, sprintf( ...
        "#%d | %s | %s | %s | %.2f R | %.2f USD", ...
        rowIndex, profileName, trade.direction, ...
        trade.exit_reason, trade.net_R, trade.net_pnl_usd));
else
    title(ax, sprintf( ...
        "#%d | %s | %s | DESCARTADA: %s", ...
        rowIndex, profileName, string(trade.session_date), ...
        trade.skip_reason));
end

xlim(ax, [xStart xEnd]);
xlabel(ax, "Hora de Nueva York");
ylabel(ax, "Precio");
hold(ax, "off");
end

function plotOHLCBars(ax, D)
% Representación OHLC sin requerir Financial Toolbox.
n = height(D);
for i = 1:n
    x = D.datetime_new_york(i);
    plot(ax, [x x], [D.low(i) D.high(i)], "-", "LineWidth", 0.5);

    halfWidth = seconds(18);
    plot(ax, [x-halfWidth x], [D.open(i) D.open(i)], "-", "LineWidth", 0.7);
    plot(ax, [x x+halfWidth], [D.close(i) D.close(i)], "-", "LineWidth", 0.7);
end
end
