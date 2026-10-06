function updateRollingAnalytics( ...
    winRateAxes,expectancyAxes,profitFactorAxes, ...
    sharpeAxes,drawdownAxes,executionAxes, ...
    trades,windowSize)
%UPDATEROLLINGANALYTICS Actualiza las seis métricas móviles.

axesList = [ ...
    winRateAxes,expectancyAxes,profitFactorAxes, ...
    sharpeAxes,drawdownAxes,executionAxes];

for i = 1:numel(axesList)
    resetDashboardAxes(axesList(i));
end

rolling = calculateRollingMetrics(trades,windowSize);

if isempty(rolling.dates)
    for i = 1:numel(axesList)
        text(axesList(i),0.5,0.5, ...
            sprintf("Se necesitan %d observaciones",windowSize), ...
            "HorizontalAlignment","center");
    end
    return;
end

blue = [0.00 0.4470 0.7410];
green = [0.00 0.55 0.10];
red = [0.82 0.08 0.08];
dark = [0.25 0.25 0.25];

plotMetric( ...
    winRateAxes,rolling.dates,rolling.win_rate_pct, ...
    blue,"Rolling Win Rate","Win Rate (%)",50);

plotMetric( ...
    expectancyAxes,rolling.dates,rolling.expectancy_r, ...
    green,"Rolling Expectancy","Expectancy (R)",0);

plotMetric( ...
    profitFactorAxes,rolling.dates,rolling.profit_factor, ...
    blue,"Rolling Profit Factor","Profit Factor",1);

plotMetric( ...
    sharpeAxes,rolling.dates,rolling.sharpe, ...
    dark,"Rolling Sharpe (trade)","Sharpe",0);

plotMetric( ...
    drawdownAxes,rolling.dates,rolling.drawdown_pct, ...
    blue,"Rolling Drawdown","Drawdown (%)",0);

plotMetric( ...
    executionAxes,rolling.dates,rolling.execution_rate_pct, ...
    red,"Rolling Execution Rate","Executed (%)",[]);
end

function plotMetric(ax,dates,values,lineColor,titleText,yLabel,reference)
valid = isfinite(values);

if any(valid)
    plot(ax,dates(valid),values(valid), ...
        "Color",lineColor, ...
        "LineWidth",1.25, ...
        "HandleVisibility","off");
end

if ~isempty(reference)
    yline(ax,reference,"--", ...
        "Color",[0.45 0.45 0.45], ...
        "LineWidth",0.7, ...
        "HandleVisibility","off");
end

title(ax,titleText);
ylabel(ax,yLabel);
grid(ax,"on");

try
    ax.YAxis.Exponent = 0;
catch
end

try
    ytickformat(ax,"%.2f");
catch
end

if numel(dates)>=2
    xlim(ax,[dates(1) dates(end)]);
end
end
