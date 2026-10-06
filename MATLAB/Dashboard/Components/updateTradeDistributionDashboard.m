function updateTradeDistributionDashboard( ...
    rAxes,pnlAxes,directionAxes,exitAxes,detailAxes, ...
    summaryTable,trades,filterName,detailName)
%UPDATETRADEDISTRIBUTIONDASHBOARD Actualiza Trade Distribution.

axesList = [rAxes,pnlAxes,directionAxes,exitAxes,detailAxes];

for i = 1:numel(axesList)
    resetDashboardAxes(axesList(i));
end

filtered = filterTradeDistributionData(trades,filterName);
stats = calculateTradeDistributionStatistics(filtered);

summaryTable.Data = buildTradeDistributionSummaryTable( ...
    stats,filterName);

styleTradeDistributionSummaryTable(summaryTable,stats);

if isempty(filtered)
    showNoData(axesList,"No hay trades para este filtro");
    return;
end

plotHistogramVariable( ...
    rAxes,filtered,"net_R", ...
    "Distribución de Net R","Net R","Trades",true);

plotHistogramVariable( ...
    pnlAxes,filtered,"net_pnl_usd", ...
    "Distribución de Net PnL","Net PnL (USD)","Trades",true);

plotGroupDistribution( ...
    directionAxes,filtered,"direction", ...
    ["LONG","SHORT"], ...
    "Distribución de R por dirección");

plotGroupDistribution( ...
    exitAxes,filtered,"exit_reason", ...
    ["STOP","BREAKEVEN","TRAILING_STOP","TARGET","EOD"], ...
    "Distribución de R por salida");

plotSelectedDetail(detailAxes,filtered,detailName);
end

function plotHistogramVariable( ...
    ax,trades,columnName,titleText,xLabel,yLabel,showZero)

variables = string(trades.Properties.VariableNames);

if ~ismember(columnName,variables)
    showNoData(ax,"Variable no disponible");
    return;
end

values = trades.(columnName);
values = values(isfinite(values));

if isempty(values)
    showNoData(ax,"Sin valores válidos");
    return;
end

palette = getQuantLabPalette();
edges = buildHistogramEdges(values,columnName);

negativeValues = values(values<0);
zeroValues = values(values==0);
positiveValues = values(values>0);

hold(ax,"on");

if ~isempty(negativeValues)
    histogram( ...
        ax,negativeValues,edges, ...
        "FaceColor",palette.negative, ...
        "FaceAlpha",0.78, ...
        "EdgeColor",[0.25 0.25 0.25], ...
        "DisplayName","Negativo");
end

if ~isempty(zeroValues)
    histogram( ...
        ax,zeroValues,edges, ...
        "FaceColor",[0.55 0.55 0.55], ...
        "FaceAlpha",0.78, ...
        "EdgeColor",[0.25 0.25 0.25], ...
        "DisplayName","Cero");
end

if ~isempty(positiveValues)
    histogram( ...
        ax,positiveValues,edges, ...
        "FaceColor",palette.positive, ...
        "FaceAlpha",0.78, ...
        "EdgeColor",[0.25 0.25 0.25], ...
        "DisplayName","Positivo");
end

meanValue = mean(values);
medianValue = median(values);

xline( ...
    ax,meanValue,"-", ...
    "Color",palette.mean, ...
    "LineWidth",1.35, ...
    "DisplayName",sprintf("Media %.2f",meanValue));

xline( ...
    ax,medianValue,":", ...
    "Color",palette.median, ...
    "LineWidth",1.35, ...
    "DisplayName",sprintf("Mediana %.2f",medianValue));

if showZero
    xline( ...
        ax,0,"--", ...
        "Color",palette.neutral, ...
        "LineWidth",0.8, ...
        "HandleVisibility","off");
end

hold(ax,"off");

title(ax,titleText);
xlabel(ax,xLabel);
ylabel(ax,yLabel);
grid(ax,"on");
legend(ax,"show","Location","best");
end

function edges = buildHistogramEdges(values,columnName)
%BUILDHISTOGRAMEDGES Intervalos legibles y reproducibles.

minimumValue = min(values);
maximumValue = max(values);

if minimumValue==maximumValue
    padding = max(0.5,abs(minimumValue)*0.10);
    edges = [minimumValue-padding maximumValue+padding];
    return;
end

if columnName=="net_R"
    dataRange = maximumValue-minimumValue;

    if dataRange<=15
        step = 0.5;
    elseif dataRange<=30
        step = 1.0;
    else
        step = 2.0;
    end

    minimumCenter = floor(minimumValue/step)*step;
    maximumCenter = ceil(maximumValue/step)*step;
    edges = (minimumCenter-step/2):step:(maximumCenter+step/2);
else
    binCount = max(10,min(28,round(1.5*sqrt(numel(values)))));
    edges = linspace(minimumValue,maximumValue,binCount+1);

    % El cero debe ser frontera de bin para no mezclar signos.
    if minimumValue<0 && maximumValue>0
        edges = unique(sort([edges 0]));
    end
end

if numel(edges)<2
    edges = [minimumValue maximumValue];
end
end

function plotGroupDistribution( ...
    ax,trades,groupColumn,preferredOrder,titleText)

variables = string(trades.Properties.VariableNames);

if ~all(ismember(["net_R",groupColumn],variables))
    showNoData(ax,"Agrupación no disponible");
    return;
end

groupValues = upper(string(trades.(groupColumn)));
rValues = trades.net_R;
valid = isfinite(rValues) & strlength(groupValues)>0;

groupValues = groupValues(valid);
rValues = rValues(valid);

availableGroups = preferredOrder( ...
    ismember(preferredOrder,unique(groupValues,"stable")));

if isempty(availableGroups)
    availableGroups = unique(groupValues,"stable")';
end

if isempty(availableGroups)
    showNoData(ax,"Sin grupos disponibles");
    return;
end

palette = getQuantLabPalette();
hold(ax,"on");

for groupIndex = 1:numel(availableGroups)
    groupName = availableGroups(groupIndex);
    groupR = rValues(groupValues==groupName);

    if isempty(groupR)
        continue;
    end

    jitter = deterministicJitter(numel(groupR));
    x = groupIndex+jitter;
    groupColor = getGroupColor(groupName,palette);

    scatter( ...
        ax,x,groupR,20, ...
        groupColor, ...
        "filled", ...
        "HandleVisibility","off");

    medianValue = median(groupR);

    plot( ...
        ax,[groupIndex-0.25 groupIndex+0.25], ...
        [medianValue medianValue], ...
        "Color",[0.08 0.08 0.08], ...
        "LineWidth",2.0, ...
        "HandleVisibility","off");

    text( ...
        ax,groupIndex,max(groupR), ...
        sprintf("n=%d",numel(groupR)), ...
        "HorizontalAlignment","center", ...
        "VerticalAlignment","bottom", ...
        "FontSize",8, ...
        "Color",groupColor, ...
        "FontWeight","bold");
end

yline( ...
    ax,0,"--", ...
    "Color",palette.neutral, ...
    "LineWidth",0.8, ...
    "HandleVisibility","off");

hold(ax,"off");

ax.XTick = 1:numel(availableGroups);
ax.XTickLabel = cellstr(availableGroups);
xlim(ax,[0.5 numel(availableGroups)+0.5]);

title(ax,titleText);
ylabel(ax,"Net R");
grid(ax,"on");
end

function color = getGroupColor(groupName,palette)
switch upper(string(groupName))
    case "LONG"
        color = palette.long;
    case "SHORT"
        color = palette.short;
    case "TARGET"
        color = palette.target;
    case "STOP"
        color = palette.stop;
    case "BREAKEVEN"
        color = palette.breakeven;
    case "TRAILING_STOP"
        color = palette.trailing;
    case "EOD"
        color = palette.eod;
    otherwise
        color = palette.neutral;
end
end

function jitter = deterministicJitter(count)
if count<=1
    jitter = 0;
else
    jitter = linspace(-0.20,0.20,count)';
end
end

function plotSelectedDetail(ax,trades,detailName)
switch detailName
    case "ORB Range vs R"
        plotOrbRangeScatter(ax,trades);

    case "MFE (R)"
        plotHistogramVariable( ...
            ax,trades,"mfe_R", ...
            "MFE Distribution","MFE (R)","Trades",false);

    case "MAE (R)"
        plotHistogramVariable( ...
            ax,trades,"mae_R", ...
            "MAE Distribution","MAE (R)","Trades",false);

    case "Bars Held"
        plotHistogramVariable( ...
            ax,trades,"bars_held", ...
            "Trade Duration","Bars Held","Trades",false);

    case "Contracts"
        plotHistogramVariable( ...
            ax,trades,"contracts", ...
            "Contracts Distribution","Contracts","Trades",false);

    case "Risk Used (USD)"
        plotHistogramVariable( ...
            ax,trades,"effective_risk_usd", ...
            "Effective Risk","Risk Used (USD)","Trades",false);

    otherwise
        showNoData(ax,"Detalle desconocido");
end
end

function plotOrbRangeScatter(ax,trades)
variables = string(trades.Properties.VariableNames);

if ~all(ismember(["orb_range_points","net_R"],variables))
    showNoData(ax,"ORB range no disponible");
    return;
end

x = trades.orb_range_points;
y = trades.net_R;
valid = isfinite(x) & isfinite(y);

x = x(valid);
y = y(valid);

if isempty(x)
    showNoData(ax,"Sin valores ORB válidos");
    return;
end

palette = getQuantLabPalette();
hold(ax,"on");

if ismember("direction",variables)
    direction = upper(string(trades.direction(valid)));
    longMask = direction=="LONG";
    shortMask = direction=="SHORT";

    if any(longMask)
        scatter( ...
            ax,x(longMask),y(longMask),24, ...
            palette.long, ...
            "filled", ...
            "DisplayName","LONG");
    end

    if any(shortMask)
        scatter( ...
            ax,x(shortMask),y(shortMask),24, ...
            palette.short, ...
            "filled", ...
            "DisplayName","SHORT");
    end
else
    scatter( ...
        ax,x,y,24, ...
        palette.neutral, ...
        "filled", ...
        "HandleVisibility","off");
end

correlationValue = NaN;
rSquared = NaN;

if numel(x)>=2 && numel(unique(x))>=2
    coefficients = polyfit(x,y,1);
    fitX = linspace(min(x),max(x),100);
    fitY = polyval(coefficients,fitX);
    fittedValues = polyval(coefficients,x);

    plot( ...
        ax,fitX,fitY,":", ...
        "Color",palette.trend, ...
        "LineWidth",1.15, ...
        "DisplayName","Tendencia");

    correlationMatrix = corrcoef(x,y);
    correlationValue = correlationMatrix(1,2);

    totalVariation = sum((y-mean(y)).^2);
    residualVariation = sum((y-fittedValues).^2);

    if totalVariation>0
        rSquared = 1-residualVariation/totalVariation;
    end
end

yline( ...
    ax,0,"--", ...
    "Color",palette.neutral, ...
    "LineWidth",0.8, ...
    "HandleVisibility","off");

metricsText = sprintf( ...
    "n = %d   r = %.3f   R² = %.3f", ...
    numel(x),correlationValue,rSquared);

text( ...
    ax,0.02,0.97,metricsText, ...
    "Units","normalized", ...
    "HorizontalAlignment","left", ...
    "VerticalAlignment","top", ...
    "FontWeight","bold", ...
    "BackgroundColor",[1.00 1.00 1.00], ...
    "EdgeColor",[0.70 0.70 0.70], ...
    "Margin",4, ...
    "Interpreter","none");

hold(ax,"off");

title(ax,"ORB Range vs Net R");
xlabel(ax,"ORB Range (points)");
ylabel(ax,"Net R");
grid(ax,"on");
legend(ax,"show","Location","best");
end

function showNoData(axesInput,message)
for i = 1:numel(axesInput)
    text( ...
        axesInput(i),0.5,0.5,message, ...
        "HorizontalAlignment","center", ...
        "VerticalAlignment","middle");
end
end
