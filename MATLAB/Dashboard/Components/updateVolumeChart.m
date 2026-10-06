function updateVolumeChart(volumeAxes,executed,cfg)
%UPDATEVOLUMECHART Actualiza el notional por operación.

resetDashboardAxes(volumeAxes);
if isempty(executed)
    return;
end

notional = calculateDashboardTradeNotional(executed,cfg);
validRows = isfinite(notional) & notional>0;
notional = notional(validRows);
executed = executed(validRows,:);

if isempty(executed)
    return;
end

[sortedNotional,index] = sort(notional,"descend");
topN = min(12,height(executed));
sortedNotional = sortedNotional(1:topN);
index = index(1:topN);

tradeTimeline = buildTradeTimeline(executed);
selectedTimes = tradeTimeline(index);
labels = strings(topN,1);
for i = 1:topN
    labels(i) = string(selectedTimes(i),"yyyy-MM-dd HH:mm") + ...
        " | #" + string(index(i));
end

positions = (1:topN)';
barh(volumeAxes,positions,sortedNotional, ...
    "FaceColor",[0.00 0.4470 0.7410], ...
    "EdgeColor",[0.15 0.15 0.15]);
volumeAxes.YTick = positions;
volumeAxes.YTickLabel = cellstr(labels);
volumeAxes.YDir = "reverse";

title(volumeAxes,"Top trade notionals");
xlabel(volumeAxes,"Notional");
grid(volumeAxes,"on");

maximumNotional = max(sortedNotional);
if isfinite(maximumNotional) && maximumNotional>0
    xlim(volumeAxes,[0 maximumNotional*1.08]);
end

volumeAxes.FontSize = 9;
volumeAxes.LooseInset = max( ...
    volumeAxes.TightInset,[0.01 0.01 0.01 0.01]);
try
    volumeAxes.XAxis.Exponent = 0;
catch
end
try
    xtickformat(volumeAxes,"%.0f");
catch
end
end
