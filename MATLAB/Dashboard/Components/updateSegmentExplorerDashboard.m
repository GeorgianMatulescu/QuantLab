function updateSegmentExplorerDashboard( ...
    segmentAxes,rankingAxes,resultsTable,summaryTable, ...
    trades,catalog,featureName,groupingMethod,metricName, ...
    minimumSample,trainingPct)
%UPDATESEGMENTEXPLORERDASHBOARD Research Lab genérico por segmentos.

resetDashboardAxes(segmentAxes);
resetDashboardAxes(rankingAxes);

catalog = getAvailableFeatureCatalog(catalog,trades);

if isempty(catalog) || ...
        ~any(catalog.name==lower(featureName))
    showNoData(segmentAxes,"No analysable features");
    showNoData(rankingAxes,"No feature ranking");
    resultsTable.Data = table();
    summaryTable.Data = table();
    return;
end

catalogRow = catalog(catalog.name==lower(featureName),:);
analysis = analyzeStrategySegments( ...
    trades,featureName,groupingMethod, ...
    minimumSample,trainingPct);

ranking = rankStrategyFeatures( ...
    trades,catalog,minimumSample,trainingPct);

resultsTable.Data = ...
    buildSegmentResultsDisplayTable(analysis.segments);

plotSegmentMetric( ...
    segmentAxes,analysis,catalogRow,metricName);

plotFeatureRanking(rankingAxes,ranking);

summaryTable.Data = buildSegmentSummaryTable( ...
    analysis,catalogRow,ranking);
end

function plotSegmentMetric(ax,analysis,catalogRow,metricName)
segments = analysis.segments;

if isempty(segments)
    showNoData(ax,"No segments available");
    return;
end

[fieldName,yLabel,referenceValue] = metricDefinition(metricName);
values = segments.(fieldName);
plotValues = values;

if fieldName=="profit_factor"
    finite = plotValues(isfinite(plotValues));

    if isempty(finite)
        plotValues(:) = NaN;
    else
        cap = max(2,max(finite)*1.10);
        plotValues(isinf(plotValues)) = cap;
    end
end

x = (1:height(segments))';
bars = bar(ax,x,plotValues,0.72);
bars.FaceColor = "flat";
bars.CData = buildBarColors( ...
    values,segments.sample_ok,fieldName,referenceValue);

ax.XTick = x;
ax.XTickLabel = cellstr(segments.segment);
ax.XTickLabelRotation = 20;

if ~isempty(referenceValue)
    yline(ax,referenceValue,"--", ...
        "Color",[0.35 0.35 0.35], ...
        "LineWidth",0.8, ...
        "HandleVisibility","off");
end

for i = 1:height(segments)
    if isfinite(plotValues(i))
        text( ...
            ax,x(i),plotValues(i), ...
            sprintf("n=%d",segments.trade_count(i)), ...
            "HorizontalAlignment","center", ...
            "VerticalAlignment",verticalAlignment(plotValues(i)), ...
            "FontSize",8);
    end
end

title(ax,catalogRow.label + " — " + metricName);
ylabel(ax,yLabel);
grid(ax,"on");
end

function alignment = verticalAlignment(value)
if value>=0
    alignment = "bottom";
else
    alignment = "top";
end
end

function colors = buildBarColors(values,sampleOK,fieldName,reference)
palette = getQuantLabPalette();
colors = repmat(palette.neutral,numel(values),1);

for i = 1:numel(values)
    if ~sampleOK(i) || ~isfinite(values(i))
        colors(i,:) = [0.72 0.72 0.72];
        continue;
    end

    if fieldName=="max_drawdown_pct"
        if values(i)>=-5
            colors(i,:) = palette.positive;
        else
            colors(i,:) = palette.negative;
        end
    elseif isempty(reference)
        if values(i)>=0
            colors(i,:) = palette.positive;
        else
            colors(i,:) = palette.negative;
        end
    elseif values(i)>=reference
        colors(i,:) = palette.positive;
    else
        colors(i,:) = palette.negative;
    end
end
end

function [fieldName,yLabel,reference] = metricDefinition(metricName)
switch metricName
    case "Win Rate (%)"
        fieldName = "win_rate_pct";
        yLabel = "Win Rate (%)";
        reference = 50;

    case "Profit Factor"
        fieldName = "profit_factor";
        yLabel = "Profit Factor";
        reference = 1;

    case "Net PnL (USD)"
        fieldName = "net_pnl_usd";
        yLabel = "Net PnL (USD)";
        reference = 0;

    case "Median R"
        fieldName = "median_r";
        yLabel = "Median R";
        reference = 0;

    case "Max Drawdown (%)"
        fieldName = "max_drawdown_pct";
        yLabel = "Max Drawdown (%)";
        reference = 0;

    case "Trades"
        fieldName = "trade_count";
        yLabel = "Trades";
        reference = [];

    otherwise
        fieldName = "expectancy_r";
        yLabel = "Expectancy (R)";
        reference = 0;
end
end

function plotFeatureRanking(ax,ranking)
if isempty(ranking)
    showNoData(ax,"Not enough qualified features");
    return;
end

count = min(10,height(ranking));
ranking = ranking(1:count,:);
ranking = flipud(ranking);

y = (1:count)';
bars = barh(ax,y,ranking.score,0.70);
bars.FaceColor = [0.00 0.4470 0.7410];

ax.YTick = y;
ax.YTickLabel = cellstr(ranking.label);

for i = 1:count
    text( ...
        ax,ranking.score(i),y(i), ...
        sprintf(" %.3f",ranking.score(i)), ...
        "HorizontalAlignment","left", ...
        "VerticalAlignment","middle", ...
        "FontSize",8);
end

title(ax,"Feature ranking (descriptive)");
xlabel(ax,"Separation score");
grid(ax,"on");
end

function summary = buildSegmentSummaryTable( ...
    analysis,catalogRow,ranking)

segments = analysis.segments;
qualifiedCount = 0;
bestSegment = "N/A";
worstSegment = "N/A";
score = NaN;
agreement = NaN;

if ~isempty(segments)
    qualified = segments.sample_ok & ...
        isfinite(segments.mean_outcome);
    qualifiedCount = sum(qualified);

    if any(qualified)
        qualifiedSegments = segments(qualified,:);
        [bestValue,bestIndex] = ...
            max(qualifiedSegments.mean_outcome);
        [worstValue,worstIndex] = ...
            min(qualifiedSegments.mean_outcome);

        bestSegment = qualifiedSegments.segment(bestIndex) + ...
            " (" + sprintf("%.3f",bestValue) + ")";
        worstSegment = qualifiedSegments.segment(worstIndex) + ...
            " (" + sprintf("%.3f",worstValue) + ")";
    end
end

if ~isempty(ranking)
    row = ranking(ranking.feature==analysis.feature_name,:);

    if ~isempty(row)
        score = row.score(1);
        agreement = row.agreement_pct(1);
    end
end

metrics = [ ...
    "Feature"; ...
    "Internal name"; ...
    "Type"; ...
    "Unit"; ...
    "Role"; ...
    "Grouping"; ...
    "Executed trades"; ...
    "Missing excluded"; ...
    "Segments"; ...
    "Qualified segments"; ...
    "Minimum sample"; ...
    "Training split"; ...
    "Best segment"; ...
    "Worst segment"; ...
    "Ranking score"; ...
    "IS/OOS agreement"; ...
    "Interpretation"];

values = [ ...
    catalogRow.label; ...
    catalogRow.name; ...
    catalogRow.type; ...
    replace(catalogRow.unit,"","—"); ...
    catalogRow.role; ...
    analysis.grouping_used; ...
    string(analysis.total_trades); ...
    string(analysis.excluded_missing); ...
    string(height(segments)); ...
    string(qualifiedCount); ...
    string(analysis.minimum_sample); ...
    sprintf("%.0f / %.0f", ...
        analysis.training_pct,100-analysis.training_pct); ...
    bestSegment; ...
    worstSegment; ...
    formatNumber(score); ...
    formatPercent(agreement); ...
    "Descriptive, not causal"];

summary = table(metrics,values, ...
    'VariableNames',{'Metric','Value'});
end

function value = formatNumber(number)
if isfinite(number)
    value = string(sprintf("%.4f",number));
else
    value = "N/A";
end
end

function value = formatPercent(number)
if isfinite(number)
    value = string(sprintf("%.1f %%",number));
else
    value = "N/A";
end
end

function showNoData(ax,message)
text( ...
    ax,0.5,0.5,message, ...
    "HorizontalAlignment","center", ...
    "VerticalAlignment","middle");
end
