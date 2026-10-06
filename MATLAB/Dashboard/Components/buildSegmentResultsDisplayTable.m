function displayTable = buildSegmentResultsDisplayTable(segments)
%BUILDSEGMENTRESULTSDISPLAYTABLE Formatea resultados para UITable.

if isempty(segments)
    displayTable = table();
    return;
end

displayTable = table( ...
    segments.segment, ...
    string(segments.trade_count), ...
    formatPercent(segments.win_rate_pct), ...
    formatR(segments.expectancy_r), ...
    formatNumber(segments.profit_factor), ...
    formatUSD(segments.net_pnl_usd), ...
    formatR(segments.median_r), ...
    formatPercent(segments.max_drawdown_pct), ...
    string(segments.is_count), ...
    formatR(segments.is_expectancy_r), ...
    string(segments.oos_count), ...
    formatR(segments.oos_expectancy_r), ...
    segments.stable_sign, ...
    yesNo(segments.sample_ok), ...
    'VariableNames',{ ...
    'Segment','N','WinRate','Expectancy','ProfitFactor', ...
    'NetPnL','MedianR','MaxDD','IS_N','IS_Expectancy', ...
    'OOS_N','OOS_Expectancy','StableSign','SampleOK'});
end

function values = formatR(data)
values = strings(size(data));

for i = 1:numel(data)
    if isfinite(data(i))
        values(i) = sprintf("%.3f R",data(i));
    else
        values(i) = "N/A";
    end
end
end

function values = formatUSD(data)
values = strings(size(data));

for i = 1:numel(data)
    if isfinite(data(i))
        values(i) = sprintf("$%.2f",data(i));
    else
        values(i) = "N/A";
    end
end
end

function values = formatPercent(data)
values = strings(size(data));

for i = 1:numel(data)
    if isfinite(data(i))
        values(i) = sprintf("%.2f %%",data(i));
    else
        values(i) = "N/A";
    end
end
end

function values = formatNumber(data)
values = strings(size(data));

for i = 1:numel(data)
    if isinf(data(i))
        values(i) = "Inf";
    elseif isfinite(data(i))
        values(i) = sprintf("%.3f",data(i));
    else
        values(i) = "N/A";
    end
end
end

function values = yesNo(data)
values = repmat("NO",size(data));
values(data) = "YES";
end
