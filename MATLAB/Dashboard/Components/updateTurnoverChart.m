function updateTurnoverChart(turnoverAxes,executed,cfg)
%UPDATETURNOVERCHART Actualiza turnover acumulado genérico.

resetDashboardAxes(turnoverAxes);
if isempty(executed)
    return;
end

notional = calculateDashboardTradeNotional(executed,cfg);
turnover = cumsum(notional) ./ ...
    max(executed.equity_before_usd,eps);

plot(turnoverAxes,buildTradeTimeline(executed),turnover, ...
    "LineWidth",1.2,"Color",[0.30 0.50 0.95]);

grid(turnoverAxes,"on");
ylabel(turnoverAxes,"Turnover");
formatAxesNatural(turnoverAxes,"decimal");
end
