function stats = calculateTradeDistributionStatistics(trades)
%CALCULATETRADEDISTRIBUTIONSTATISTICS Estadísticas de trades ejecutados.
%
% Los percentiles y la asimetría se calculan sin Statistics Toolbox.

arguments
    trades table
end

stats = struct( ...
    "trade_count",0, ...
    "positive_pct",NaN, ...
    "mean_r",NaN, ...
    "median_r",NaN, ...
    "std_r",NaN, ...
    "p05_r",NaN, ...
    "p25_r",NaN, ...
    "p75_r",NaN, ...
    "p95_r",NaN, ...
    "min_r",NaN, ...
    "max_r",NaN, ...
    "skewness_r",NaN, ...
    "total_pnl_usd",NaN, ...
    "mean_pnl_usd",NaN, ...
    "median_pnl_usd",NaN, ...
    "top_10_contribution_pct",NaN, ...
    "mean_mfe_r",NaN, ...
    "mean_mae_r",NaN, ...
    "mean_bars_held",NaN, ...
    "mean_contracts",NaN, ...
    "mean_risk_usd",NaN, ...
    "mean_orb_range_points",NaN);

if isempty(trades)
    return;
end

variables = string(trades.Properties.VariableNames);

if ~ismember("net_R",variables)
    return;
end

r = trades.net_R;
validR = isfinite(r);
r = r(validR);

if isempty(r)
    return;
end

stats.trade_count = numel(r);
stats.positive_pct = 100*sum(r>0)/numel(r);
stats.mean_r = mean(r);
stats.median_r = median(r);
stats.std_r = std(r);
stats.p05_r = empiricalPercentile(r,5);
stats.p25_r = empiricalPercentile(r,25);
stats.p75_r = empiricalPercentile(r,75);
stats.p95_r = empiricalPercentile(r,95);
stats.min_r = min(r);
stats.max_r = max(r);
stats.skewness_r = adjustedSkewness(r);

if ismember("net_pnl_usd",variables)
    pnl = trades.net_pnl_usd;
    pnl = pnl(isfinite(pnl));

    if ~isempty(pnl)
        stats.total_pnl_usd = sum(pnl);
        stats.mean_pnl_usd = mean(pnl);
        stats.median_pnl_usd = median(pnl);
        stats.top_10_contribution_pct = ...
            calculateTopContribution(pnl,10);
    end
end

stats.mean_mfe_r = meanColumn(trades,"mfe_R");
stats.mean_mae_r = meanColumn(trades,"mae_R");
stats.mean_bars_held = meanColumn(trades,"bars_held");
stats.mean_contracts = meanColumn(trades,"contracts");
stats.mean_risk_usd = meanColumn(trades,"effective_risk_usd");
stats.mean_orb_range_points = ...
    meanColumn(trades,"orb_range_points");
end

function value = meanColumn(trades,columnName)
variables = string(trades.Properties.VariableNames);

if ~ismember(columnName,variables)
    value = NaN;
    return;
end

data = trades.(columnName);
data = data(isfinite(data));

if isempty(data)
    value = NaN;
else
    value = mean(data);
end
end

function value = empiricalPercentile(data,percentile)
data = sort(data(isfinite(data)));

if isempty(data)
    value = NaN;
    return;
end

if numel(data)==1
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

function value = adjustedSkewness(data)
data = data(isfinite(data));
n = numel(data);

if n<3
    value = NaN;
    return;
end

sampleStd = std(data);

if sampleStd==0
    value = 0;
    return;
end

standardized = (data-mean(data))/sampleStd;
value = n/((n-1)*(n-2))*sum(standardized.^3);
end

function contribution = calculateTopContribution(pnl,topPct)
pnl = pnl(isfinite(pnl));
total = sum(pnl);

if isempty(pnl) || total<=0
    contribution = NaN;
    return;
end

sortedPnl = sort(pnl,"descend");
topCount = max(1,ceil(numel(sortedPnl)*topPct/100));
contribution = 100*sum(sortedPnl(1:topCount))/total;
end
