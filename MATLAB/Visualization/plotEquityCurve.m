function fig = plotEquityCurve(results, profileName, initialEquityUSD)
%PLOTEQUITYCURVE Dibuja equity y drawdown para un escenario.

arguments
    results (1,1) struct
    profileName (1,1) string = "REALISTIC"
    initialEquityUSD (1,1) double = 50000
end

trades = getScenarioTrades(results, profileName);
executed = trades(trades.valid,:);

if isempty(executed)
    error("QuantLab:NoExecutedTrades", ...
        "No hay operaciones ejecutadas en %s.", profileName);
end

dates = [executed.session_date(1); executed.session_date];
equity = [initialEquityUSD; executed.equity_after_usd];

peak = cummax(equity);
drawdownPct = 100 * (equity - peak) ./ peak;

fig = figure("Name", "Equity - " + profileName, "NumberTitle", "off");

tiledlayout(fig, 2, 1);

ax1 = nexttile;
plot(ax1, dates, equity, "LineWidth", 1.2);
grid(ax1, "on");
title(ax1, "Equity - " + profileName);
ylabel(ax1, "USD");

ax2 = nexttile;
plot(ax2, dates, drawdownPct, "LineWidth", 1.2);
grid(ax2, "on");
title(ax2, "Drawdown");
ylabel(ax2, "%");
xlabel(ax2, "Fecha");
end
