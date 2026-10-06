function updateOptimizationDashboard( ...
    surfaceAxes,riskReturnAxes,resultsTable,summaryTable, ...
    results,metricName,profileName,runState)
%UPDATEOPTIMIZATIONDASHBOARD Renderiza un barrido genérico.

resetDashboardAxes(surfaceAxes);
resetDashboardAxes(riskReturnAxes);

resultsTable.Data = ...
    buildOptimizationDisplayTable(results,metricName);

if isempty(results)
    showNoData(surfaceAxes,"No optimization has been run");
    showNoData(riskReturnAxes,"No optimization results");
    summaryTable.Data = table();
    return;
end

validResults = results(results.status=="OK",:);

if isempty(validResults)
    showNoData(surfaceAxes,"All combinations failed");
    showNoData(riskReturnAxes,"No valid combinations");
    summaryTable.Data = ...
        buildOptimizationSummary( ...
            results,metricName,profileName,runState);
    return;
end

plotOptimizationSurface( ...
    surfaceAxes,validResults,metricName);

plotRiskReturn( ...
    riskReturnAxes,validResults,metricName);

summaryTable.Data = ...
    buildOptimizationSummary( ...
        results,metricName,profileName,runState);

styleOptimizationResultsTable(resultsTable);
end

function plotOptimizationSurface(ax,results,metricName)
[fieldName,direction,metricLabel] = ...
    getOptimizationMetricDefinition(metricName);

hasSecondParameter = any( ...
    strlength(results.parameter_2_name)>0 & ...
    isfinite(results.parameter_2_value));

if ~hasSecondParameter
    [x,order] = sort(results.parameter_1_value);
    y = results.(fieldName);
    y = y(order);

    orderedResults = results(order,:);
    inactive = ismember(orderedResults.activity_status, ...
        ["INACTIVE_PLATEAU","NO_TRADES"]);

    hold(ax,"on");
    plot(ax,x,y,"-", ...
        "LineWidth",1.25, ...
        "Color",[0.00 0.4470 0.7410], ...
        "HandleVisibility","off");

    scatter(ax,x(~inactive),y(~inactive),30, ...
        [0.00 0.4470 0.7410],"filled", ...
        "DisplayName","Active / transition");

    if any(inactive)
        scatter(ax,x(inactive),y(inactive),38, ...
            [0.55 0.55 0.55],"s","filled", ...
            "DisplayName","Inactive equivalent");
    end
    hold(ax,"off");

    xlabel(ax,results.parameter_1_label(1));
    ylabel(ax,metricLabel);
    title(ax,"One-parameter optimization — activity diagnostics");
    grid(ax,"on");
    legend(ax,"show","Location","best");
    return;
end

xValues = unique(results.parameter_2_value,"sorted");
yValues = unique(results.parameter_1_value,"sorted");
matrix = nan(numel(yValues),numel(xValues));

for i = 1:height(results)
    rowIndex = find( ...
        yValues==results.parameter_1_value(i),1);
    columnIndex = find( ...
        xValues==results.parameter_2_value(i),1);

    matrix(rowIndex,columnIndex) = ...
        results.(fieldName)(i);
end

imagesc(ax,xValues,yValues,matrix);
ax.YDir = "normal";
colormap(ax,parula(256));
colorbar(ax);

xlabel(ax,results.parameter_2_label(1));
ylabel(ax,results.parameter_1_label(1));
title(ax,metricLabel + " surface");

if numel(matrix)<=100
    for row = 1:size(matrix,1)
        for column = 1:size(matrix,2)
            value = matrix(row,column);

            if isfinite(value)
                text( ...
                    ax,xValues(column),yValues(row), ...
                    formatPlainNumber(value,3,true), ...
                    "HorizontalAlignment","center", ...
                    "FontSize",8, ...
                    "Color",chooseTextColor( ...
                        value,matrix,direction));
            end
        end
    end
end
end

function color = chooseTextColor(value,matrix,direction)
finiteValues = matrix(isfinite(matrix));

if isempty(finiteValues)
    color = [0 0 0];
    return;
end

middle = median(finiteValues);

if direction=="descend"
    isStrong = value>=middle;
else
    isStrong = value<=middle;
end

if isStrong
    color = [1 1 1];
else
    color = [0 0 0];
end
end

function plotRiskReturn(ax,results,metricName)
[fieldName,direction,~] = ...
    getOptimizationMetricDefinition(metricName);

x = results.max_drawdown_pct;
y = results.return_pct;
colorValue = results.(fieldName);

valid = isfinite(x) & isfinite(y) & isfinite(colorValue);
x = x(valid);
y = y(valid);
colorValue = colorValue(valid);
plotResults = results(valid,:);

if isempty(x)
    showNoData(ax,"Risk/return unavailable");
    return;
end

scatter(ax,x,y,42,colorValue,"filled");
colormap(ax,parula(256));
colorbar(ax);

xlabel(ax,"Max Drawdown (%)");
ylabel(ax,"Return (%)");
title(ax,"Return versus drawdown");
grid(ax,"on");

[~,order] = sort(colorValue,direction);
annotationCount = min(3,numel(order));

for i = 1:annotationCount
    row = order(i);

    if strlength(plotResults.parameter_2_name(row))>0
        label = formatPlainNumber( ...
            plotResults.parameter_1_value(row),6,true) + ...
            " / " + formatPlainNumber( ...
            plotResults.parameter_2_value(row),6,true);
    else
        label = formatPlainNumber( ...
            plotResults.parameter_1_value(row),6,true);
    end

    text( ...
        ax,x(row),y(row),"  " + label, ...
        "FontSize",8, ...
        "VerticalAlignment","bottom");
end
end

function summary = buildOptimizationSummary( ...
    results,metricName,profileName,runState)

[fieldName,direction,metricLabel] = ...
    getOptimizationMetricDefinition(metricName);

valid = results.status=="OK" & ...
    isfinite(results.(fieldName));
validResults = results(valid,:);

bestConfiguration = "N/A";
bestValue = "N/A";
bestOOS = "N/A";
bestDrawdown = "N/A";
bestActivity = "N/A";
bestEquivalent = "N/A";
bestTargetHits = "N/A";
activityWarning = "N/A";
cachedCount = sum(results.from_cache);
errorCount = sum(results.status~="OK");

if ~isempty(validResults)
    validResults = sortrows( ...
        validResults,fieldName,direction);
    best = validResults(1,:);

    bestConfiguration = formatConfiguration(best);
    bestValue = formatPlainNumber( ...
        best.(fieldName)(1),6,true);
    bestOOS = string(sprintf( ...
        "%.4f R",best.oos_expectancy_r(1)));
    bestDrawdown = string(sprintf( ...
        "%.3f %%",best.max_drawdown_pct(1)));
    bestActivity = best.activity_status(1);
    bestEquivalent = string( ...
        best.equivalent_configurations(1));
    bestTargetHits = string(best.target_exit_count(1));

    if best.target_exit_count(1)==0
        activityWarning = ...
            "No target exits: parameter may be unreachable";
    elseif best.equivalent_configurations(1)>1
        activityWarning = ...
            "Equivalent configurations detected";
    else
        activityWarning = "No inactivity warning";
    end
end

metrics = [ ...
    "Profile"; ...
    "Ranking metric"; ...
    "Requested"; ...
    "Completed"; ...
    "Cancelled"; ...
    "Valid combinations"; ...
    "Errors"; ...
    "Loaded from cache"; ...
    "Best configuration"; ...
    "Best metric value"; ...
    "Best OOS expectancy"; ...
    "Best max drawdown"; ...
    "Best activity"; ...
    "Equivalent configurations"; ...
    "Target exits"; ...
    "Activity warning"; ...
    "Interpretation"];

values = [ ...
    profileName; ...
    metricLabel; ...
    string(runState.requested); ...
    string(runState.completed); ...
    yesNo(runState.cancelled); ...
    string(sum(results.status=="OK")); ...
    string(errorCount); ...
    string(cachedCount); ...
    bestConfiguration; ...
    bestValue; ...
    bestOOS; ...
    bestDrawdown; ...
    bestActivity; ...
    bestEquivalent; ...
    bestTargetHits; ...
    activityWarning; ...
    "Search for stable active regions, not only the maximum"];

summary = table(metrics,values, ...
    'VariableNames',{'Metric','Value'});
end

function textValue = formatConfiguration(row)
textValue = row.parameter_1_label(1) + ...
    "=" + formatPlainNumber( ...
        row.parameter_1_value(1),6,true);

if strlength(row.parameter_2_name(1))>0
    textValue = textValue + ", " + ...
        row.parameter_2_label(1) + "=" + ...
        formatPlainNumber( ...
            row.parameter_2_value(1),6,true);
end
end

function value = yesNo(flag)
if flag
    value = "YES";
else
    value = "NO";
end
end

function styleOptimizationResultsTable(tableHandle)
try
    removeStyle(tableHandle);

    bestStyle = uistyle( ...
        "BackgroundColor",[0.88 0.96 0.88], ...
        "FontWeight","bold");

    errorStyle = uistyle( ...
        "BackgroundColor",[1.00 0.90 0.90], ...
        "FontColor",[0.65 0.00 0.00]);

    inactiveStyle = uistyle( ...
        "BackgroundColor",[0.93 0.93 0.93], ...
        "FontColor",[0.35 0.35 0.35]);

    if height(tableHandle.Data)>=1
        addStyle(tableHandle,bestStyle,"row",1);
    end

    if istable(tableHandle.Data) && ...
            ismember("Status", ...
                string(tableHandle.Data.Properties.VariableNames))
        errorRows = find(tableHandle.Data.Status~="OK");

        for row = reshape(errorRows,1,[])
            addStyle(tableHandle,errorStyle,"row",row);
        end
    end

    if istable(tableHandle.Data) && ...
            ismember("Activity", ...
                string(tableHandle.Data.Properties.VariableNames))
        inactiveRows = find(ismember( ...
            tableHandle.Data.Activity, ...
            ["INACTIVE_PLATEAU","NO_TRADES"]));

        for row = reshape(inactiveRows,1,[])
            addStyle(tableHandle,inactiveStyle,"row",row);
        end
    end
catch
end
end

function showNoData(ax,message)
text( ...
    ax,0.5,0.5,message, ...
    "HorizontalAlignment","center", ...
    "VerticalAlignment","middle");
end
