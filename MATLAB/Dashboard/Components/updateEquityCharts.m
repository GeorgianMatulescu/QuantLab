function updateEquityCharts(equityAxes,returnAxes,executed,metrics)
%UPDATEEQUITYCHARTS Actualiza equity acumulada y retorno por operación.
%
% La coordenada X utiliza entry_time y no session_date. Esto permite
% representar cualquier número de operaciones dentro de una sesión.

resetDashboardAxes(equityAxes);
resetDashboardAxes(returnAxes);

if isempty(executed)
    return;
end

tradeTimeline = buildTradeTimeline(executed);
initialTime = tradeTimeline(1)-milliseconds(1);

equityDates = [initialTime;tradeTimeline];
equityValues = [metrics.startEquity;executed.equity_after_usd];
equityReturnPct = 100 .* ...
    (equityValues ./ metrics.startEquity - 1);

[plotDates,plotValues] = insertZeroCrossings( ...
    equityDates,equityReturnPct);

positiveArea = max(plotValues,0);
negativeArea = min(plotValues,0);

positiveLine = plotValues;
positiveLine(positiveLine<0) = NaN;
negativeLine = plotValues;
negativeLine(negativeLine>0) = NaN;

greenLine = [0.00 0.55 0.10];
greenFill = [0.55 0.85 0.62];
redLine = [0.82 0.08 0.08];
redFill = [0.95 0.62 0.62];

hold(equityAxes,"on");
area(equityAxes,plotDates,positiveArea, ...
    "BaseValue",0,"FaceColor",greenFill, ...
    "FaceAlpha",0.35,"EdgeColor","none", ...
    "HandleVisibility","off");
area(equityAxes,plotDates,negativeArea, ...
    "BaseValue",0,"FaceColor",redFill, ...
    "FaceAlpha",0.35,"EdgeColor","none", ...
    "HandleVisibility","off");
plot(equityAxes,plotDates,positiveLine, ...
    "LineWidth",1.5,"Color",greenLine, ...
    "HandleVisibility","off");
plot(equityAxes,plotDates,negativeLine, ...
    "LineWidth",1.5,"Color",redLine, ...
    "HandleVisibility","off");
yline(equityAxes,0,"--","Color",[0.25 0.25 0.25], ...
    "LineWidth",0.8,"HandleVisibility","off");
hold(equityAxes,"off");

grid(equityAxes,"on");
ylabel(equityAxes,"Equity (%)");
formatAxesNatural(equityAxes,"percent");

if numel(plotDates)>=2
    xlim(equityAxes,[plotDates(1) plotDates(end)]);
end
setSignedPercentLimits(equityAxes,plotValues);

% Retorno de cada operación. bar() exige XData única.
tradeReturnPct = 100 .* executed.net_pnl_usd ./ ...
    max(executed.equity_before_usd,eps);
positiveTradeReturn = max(tradeReturnPct,0);
negativeTradeReturn = min(tradeReturnPct,0);

hold(returnAxes,"on");
bar(returnAxes,tradeTimeline,positiveTradeReturn, ...
    "FaceColor",greenLine,"EdgeColor","none", ...
    "HandleVisibility","off");
bar(returnAxes,tradeTimeline,negativeTradeReturn, ...
    "FaceColor",redLine,"EdgeColor","none", ...
    "HandleVisibility","off");
yline(returnAxes,0,"Color",[0.35 0.35 0.35], ...
    "LineWidth",0.6,"HandleVisibility","off");
hold(returnAxes,"off");

grid(returnAxes,"on");
ylabel(returnAxes,"Return (%)");
formatAxesNatural(returnAxes,"percent");

if height(executed)>=2
    xlim(returnAxes,[tradeTimeline(1) tradeTimeline(end)]);
end
end

function [datesOut,valuesOut] = insertZeroCrossings(datesIn,valuesIn)
datesOut = datesIn(1);
valuesOut = valuesIn(1);

for i = 1:numel(valuesIn)-1
    x1 = datesIn(i);
    x2 = datesIn(i+1);
    y1 = valuesIn(i);
    y2 = valuesIn(i+1);

    if isfinite(y1) && isfinite(y2) && y1*y2<0
        crossingFraction = abs(y1)/(abs(y1)+abs(y2));
        crossingDate = x1 + (x2-x1)*crossingFraction;
        datesOut(end+1,1) = crossingDate; %#ok<AGROW>
        valuesOut(end+1,1) = 0; %#ok<AGROW>
    end

    datesOut(end+1,1) = x2; %#ok<AGROW>
    valuesOut(end+1,1) = y2; %#ok<AGROW>
end
end

function setSignedPercentLimits(ax,values)
finiteValues = values(isfinite(values));
if isempty(finiteValues)
    ylim(ax,[-1 1]);
    return;
end
lower = min([0;finiteValues]);
upper = max([0;finiteValues]);
span = upper-lower;
if span<=0
    padding = 1;
else
    padding = max(0.25,0.08*span);
end
ylim(ax,[lower-padding upper+padding]);
end
