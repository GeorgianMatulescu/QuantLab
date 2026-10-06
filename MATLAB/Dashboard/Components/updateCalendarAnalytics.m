function updateCalendarAnalytics(calendarAxes,summaryTable,trades)
%UPDATECALENDARANALYTICS Actualiza heatmap y resumen mensual.

resetDashboardAxes(calendarAxes);

calendar = calculateCalendarReturns(trades);
summaryTable.Data = buildCalendarSummaryTable(calendar);

if isempty(calendar.years)
    text(calendarAxes,0.5,0.5, ...
        "No hay datos de calendario", ...
        "HorizontalAlignment","center");
    return;
end

values = calendar.matrix;
finiteValues = values(isfinite(values));

if isempty(finiteValues)
    maxAbs = 1;
else
    maxAbs = max(abs(finiteValues));
    maxAbs = max(maxAbs,0.25);
end

imageHandle = imagesc(calendarAxes,values);
imageHandle.AlphaData = isfinite(values);

calendarAxes.Color = [0.92 0.92 0.92];
calendarAxes.YDir = "normal";

colormap(calendarAxes,redWhiteGreenMap(256));
caxis(calendarAxes,[-maxAbs maxAbs]);

calendarAxes.XTick = 1:13;
calendarAxes.XTickLabel = cellstr(calendar.monthLabels);
calendarAxes.YTick = 1:numel(calendar.years);
calendarAxes.YTickLabel = cellstr(string(calendar.years));

xlabel(calendarAxes,"Mes");
ylabel(calendarAxes,"Año");
title(calendarAxes,"Rentabilidad mensual y anual (%)");

for row = 1:size(values,1)
    for column = 1:size(values,2)
        value = values(row,column);

        if ~isfinite(value)
            continue;
        end

        if abs(value) > 0.55*maxAbs
            textColor = [1 1 1];
        else
            textColor = [0.10 0.10 0.10];
        end

        text( ...
            calendarAxes, ...
            column,row, ...
            sprintf("%.2f",value), ...
            "HorizontalAlignment","center", ...
            "VerticalAlignment","middle", ...
            "FontSize",9, ...
            "FontWeight","bold", ...
            "Color",textColor);
    end
end

colorbar(calendarAxes);
end

function map = redWhiteGreenMap(n)
if nargin<1
    n = 256;
end

half = floor(n/2);

red = [0.78 0.08 0.08];
white = [1.00 1.00 1.00];
green = [0.00 0.55 0.10];

first = [ ...
    linspace(red(1),white(1),half)', ...
    linspace(red(2),white(2),half)', ...
    linspace(red(3),white(3),half)'];

secondCount = n-half;

second = [ ...
    linspace(white(1),green(1),secondCount)', ...
    linspace(white(2),green(2),secondCount)', ...
    linspace(white(3),green(3),secondCount)'];

map = [first;second];
end
