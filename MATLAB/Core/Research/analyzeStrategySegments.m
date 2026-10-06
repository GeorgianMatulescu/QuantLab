function analysis = analyzeStrategySegments( ...
    trades,featureName,groupingMethod,minimumSample,trainingPct)
%ANALYZESTRATEGYSEGMENTS Segmenta cualquier característica registrada.
%
% No contiene nombres ni reglas de una estrategia concreta.
%
% Devuelve métricas globales y una validación temporal descriptiva
% mediante un split inicial/final.

arguments
    trades table
    featureName (1,1) string
    groupingMethod (1,1) string = "Auto"
    minimumSample (1,1) double {mustBeInteger,mustBePositive} = 15
    trainingPct (1,1) double {mustBeGreaterThan(trainingPct,0), ...
        mustBeLessThan(trainingPct,100)} = 70
end

researchTable = buildResearchFeatureTable(trades);
researchTable = filterExecutedTrades(researchTable);
researchTable = sortResearchTrades(researchTable);

analysis = struct( ...
    "feature_name",featureName, ...
    "feature_type","", ...
    "grouping_used",groupingMethod, ...
    "segments",table(), ...
    "total_trades",height(researchTable), ...
    "excluded_missing",0, ...
    "minimum_sample",minimumSample, ...
    "training_pct",trainingPct, ...
    "outcome_unit","R");

variables = lower(string(researchTable.Properties.VariableNames));
columnIndex = find(variables==lower(featureName),1,"first");

if isempty(columnIndex) || isempty(researchTable)
    return;
end

featureValues = researchTable.( ...
    researchTable.Properties.VariableNames{columnIndex});

[segmentId,segmentLabels,featureType,groupingUsed,validFeature] = ...
    assignFeatureSegments(featureValues,groupingMethod);

analysis.feature_type = featureType;
analysis.grouping_used = groupingUsed;
analysis.excluded_missing = sum(~validFeature);

researchTable = researchTable(validFeature,:);
segmentId = segmentId(validFeature);

if isempty(researchTable)
    return;
end

rowCount = height(researchTable);
trainingEnd = max(1,min(rowCount-1, ...
    floor(rowCount*trainingPct/100)));

isMask = false(rowCount,1);
isMask(1:trainingEnd) = true;
oosMask = ~isMask;

rows = cell(0,20);

for segmentIndex = 1:numel(segmentLabels)
    mask = segmentId==segmentIndex;

    if ~any(mask)
        continue;
    end

    segmentTrades = researchTable(mask,:);
    globalMetrics = calculateSegmentMetrics(segmentTrades);
    inSampleMetrics = calculateSegmentMetrics( ...
        researchTable(mask & isMask,:));
    outSampleMetrics = calculateSegmentMetrics( ...
        researchTable(mask & oosMask,:));

    sampleOK = globalMetrics.trade_count>=minimumSample;

    stableSign = evaluateStableSign( ...
        inSampleMetrics.mean_outcome, ...
        outSampleMetrics.mean_outcome, ...
        inSampleMetrics.trade_count, ...
        outSampleMetrics.trade_count);

    rows(end+1,:) = { ...
        segmentLabels(segmentIndex), ...
        globalMetrics.trade_count, ...
        globalMetrics.win_rate_pct, ...
        globalMetrics.expectancy_r, ...
        globalMetrics.mean_outcome, ...
        globalMetrics.profit_factor, ...
        globalMetrics.net_pnl_usd, ...
        globalMetrics.median_r, ...
        globalMetrics.max_drawdown_pct, ...
        globalMetrics.top_10_contribution_pct, ...
        inSampleMetrics.trade_count, ...
        inSampleMetrics.expectancy_r, ...
        inSampleMetrics.mean_outcome, ...
        outSampleMetrics.trade_count, ...
        outSampleMetrics.expectancy_r, ...
        outSampleMetrics.mean_outcome, ...
        stableSign, ...
        sampleOK, ...
        globalMetrics.minimum_outcome, ...
        globalMetrics.maximum_outcome}; %#ok<AGROW>
end

if isempty(rows)
    return;
end

segments = cell2table(rows, ...
    'VariableNames',{ ...
    'segment','trade_count','win_rate_pct','expectancy_r', ...
    'mean_outcome','profit_factor','net_pnl_usd','median_r', ...
    'max_drawdown_pct','top_10_contribution_pct', ...
    'is_count','is_expectancy_r','is_mean_outcome', ...
    'oos_count','oos_expectancy_r','oos_mean_outcome', ...
    'stable_sign','sample_ok','minimum_outcome','maximum_outcome'});

analysis.segments = segments;

if ~ismember("net_R",string(researchTable.Properties.VariableNames))
    analysis.outcome_unit = "normalized PnL";
end
end

function trades = filterExecutedTrades(trades)
if isempty(trades)
    return;
end

variables = string(trades.Properties.VariableNames);
mask = true(height(trades),1);

if ismember("valid",variables)
    mask = mask & logical(trades.valid);
end

if ismember("contracts",variables)
    mask = mask & isfinite(trades.contracts) & trades.contracts>0;
end

if ismember("net_R",variables)
    mask = mask & isfinite(trades.net_R);
elseif ismember("net_pnl_usd",variables)
    mask = mask & isfinite(trades.net_pnl_usd);
end

trades = trades(mask,:);
end

function trades = sortResearchTrades(trades)
variables = string(trades.Properties.VariableNames);

if ismember("session_date",variables)
    trades = sortrows(trades,"session_date");
elseif ismember("entry_time",variables)
    trades = sortrows(trades,"entry_time");
end
end

function [segmentId,labels,featureType,groupingUsed,valid] = ...
    assignFeatureSegments(values,groupingMethod)

if isnumeric(values)
    featureType = "numeric";
    valid = isfinite(values);
    cleanValues = values(valid);
    groupingUsed = normalizeNumericGrouping( ...
        groupingMethod,cleanValues);

    if groupingUsed=="Categories"
        [segmentIdValid,labels] = assignCategories( ...
            string(cleanValues));
    else
        binCount = groupingToBinCount(groupingUsed);
        [segmentIdValid,labels] = assignNumericBins( ...
            cleanValues,binCount);
    end
elseif islogical(values)
    featureType = "boolean";
    valid = ~ismissing(values);
    groupingUsed = "Categories";
    [segmentIdValid,labels] = assignCategories( ...
        string(values(valid)));
else
    featureType = "categorical";

    if iscategorical(values) || iscellstr(values)
        values = string(values);
    end

    valid = ~ismissing(values) & strlength(strtrim(string(values)))>0;
    groupingUsed = "Categories";
    [segmentIdValid,labels] = assignCategories( ...
        string(values(valid)));
end

segmentId = zeros(numel(values),1);
segmentId(valid) = segmentIdValid;
end

function grouping = normalizeNumericGrouping(requested,values)
requested = string(requested);
uniqueCount = numel(unique(values));

if requested=="Auto"
    if uniqueCount<=10
        grouping = "Categories";
    else
        grouping = "Quintiles";
    end
elseif requested=="Categories" && uniqueCount>20
    grouping = "Quintiles";
else
    grouping = requested;
end
end

function count = groupingToBinCount(grouping)
switch grouping
    case "Quartiles"
        count = 4;
    case "Deciles"
        count = 10;
    otherwise
        count = 5;
end
end

function [segmentId,labels] = assignCategories(values)
[labels,~,segmentId] = unique(values,"stable");
labels = string(labels);
end

function [segmentId,labels] = assignNumericBins(values,binCount)
cutPoints = nan(binCount-1,1);

for i = 1:binCount-1
    cutPoints(i) = empiricalPercentile( ...
        values,100*i/binCount);
end

cutPoints = unique(cutPoints(isfinite(cutPoints)));

if isempty(cutPoints)
    segmentId = ones(numel(values),1);
    labels = "All values";
    return;
end

edges = [-Inf;cutPoints(:);Inf];
segmentId = discretize(values,edges);

labels = strings(numel(edges)-1,1);

for i = 1:numel(labels)
    if i==1
        labels(i) = "≤ " + formatBoundary(edges(i+1));
    elseif i==numel(labels)
        labels(i) = "> " + formatBoundary(edges(i));
    else
        labels(i) = "(" + formatBoundary(edges(i)) + ...
            ", " + formatBoundary(edges(i+1)) + "]";
    end
end
end

function text = formatBoundary(value)
text = formatPlainNumber(value,4,true);
end

function value = empiricalPercentile(data,percentile)
data = sort(data(isfinite(data)));

if isempty(data)
    value = NaN;
    return;
elseif numel(data)==1
    value = data(1);
    return;
end

position = 1 + (numel(data)-1)*(percentile/100);
lowerIndex = floor(position);
upperIndex = ceil(position);

if lowerIndex==upperIndex
    value = data(lowerIndex);
else
    fraction = position-lowerIndex;
    value = data(lowerIndex) + ...
        fraction*(data(upperIndex)-data(lowerIndex));
end
end

function metrics = calculateSegmentMetrics(trades)
metrics = struct( ...
    "trade_count",height(trades), ...
    "win_rate_pct",NaN, ...
    "expectancy_r",NaN, ...
    "mean_outcome",NaN, ...
    "profit_factor",NaN, ...
    "net_pnl_usd",NaN, ...
    "median_r",NaN, ...
    "max_drawdown_pct",NaN, ...
    "top_10_contribution_pct",NaN, ...
    "minimum_outcome",NaN, ...
    "maximum_outcome",NaN);

if isempty(trades)
    return;
end

variables = string(trades.Properties.VariableNames);

if ismember("net_R",variables)
    outcome = trades.net_R;
    outcome = outcome(isfinite(outcome));

    if ~isempty(outcome)
        metrics.expectancy_r = mean(outcome);
        metrics.median_r = median(outcome);
    end
elseif ismember("net_pnl_usd",variables)
    rawOutcome = trades.net_pnl_usd;
    scale = std(rawOutcome,"omitnan");

    if ~isfinite(scale) || scale==0
        scale = 1;
    end

    outcome = rawOutcome/scale;
    outcome = outcome(isfinite(outcome));
else
    outcome = [];
end

if ~isempty(outcome)
    metrics.mean_outcome = mean(outcome);
    metrics.minimum_outcome = min(outcome);
    metrics.maximum_outcome = max(outcome);

    gains = outcome(outcome>0);
    losses = outcome(outcome<0);
    grossGain = sum(gains,"omitnan");
    grossLoss = abs(sum(losses,"omitnan"));

    if grossLoss>0
        metrics.profit_factor = grossGain/grossLoss;
    elseif grossGain>0
        metrics.profit_factor = Inf;
    end
end

if ismember("net_pnl_usd",variables)
    pnl = trades.net_pnl_usd;
    pnl = pnl(isfinite(pnl));

    if ~isempty(pnl)
        metrics.net_pnl_usd = sum(pnl);
        metrics.win_rate_pct = 100*sum(pnl>0)/numel(pnl);
        metrics.top_10_contribution_pct = ...
            topContribution(pnl);

        startEquity = inferStartEquity(trades);
        equity = startEquity + [0;cumsum(pnl)];
        runningPeak = cummax(equity);
        drawdown = 100*(equity-runningPeak)./runningPeak;
        metrics.max_drawdown_pct = min(drawdown,[],"omitnan");
    end
elseif ~isempty(outcome)
    metrics.win_rate_pct = ...
        100*sum(outcome>0)/numel(outcome);
end
end

function startEquity = inferStartEquity(trades)
variables = string(trades.Properties.VariableNames);

if ismember("equity_before_usd",variables)
    candidate = trades.equity_before_usd(1);

    if isfinite(candidate) && candidate>0
        startEquity = candidate;
        return;
    end
end

startEquity = 1;
end

function contribution = topContribution(pnl)
total = sum(pnl);

if total<=0
    contribution = NaN;
    return;
end

sorted = sort(pnl,"descend");
count = max(1,ceil(numel(sorted)*0.10));
contribution = 100*sum(sorted(1:count))/total;
end

function result = evaluateStableSign( ...
    inSampleValue,outSampleValue,inCount,outCount)

minimumValidationCount = 3;

if inCount<minimumValidationCount || ...
        outCount<minimumValidationCount || ...
        ~isfinite(inSampleValue) || ...
        ~isfinite(outSampleValue)
    result = "N/A";
elseif sign(inSampleValue)==sign(outSampleValue)
    result = "YES";
else
    result = "NO";
end
end
