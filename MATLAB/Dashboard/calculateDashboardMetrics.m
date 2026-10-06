function metrics = calculateDashboardMetrics(trades, initialEquityUSD)
arguments
    trades table
    initialEquityUSD (1,1) double = 50000
end

executed = trades(trades.valid,:);

metrics = struct( ...
    "totalRows",height(trades), ...
    "executedTrades",height(executed), ...
    "skippedTrades",height(trades)-height(executed), ...
    "winRatePct",NaN, ...
    "netPnLUSD",0, ...
    "netR",0, ...
    "profitFactor",NaN, ...
    "expectancyR",NaN, ...
    "maxDrawdownPct",0, ...
    "finalEquityUSD",initialEquityUSD);

if isempty(executed)
    return;
end

pnl = executed.net_pnl_usd;
r = executed.net_R;

metrics.winRatePct = 100*nnz(pnl>0)/height(executed);
metrics.netPnLUSD = sum(pnl,"omitnan");
metrics.netR = sum(r,"omitnan");
metrics.expectancyR = mean(r,"omitnan");
metrics.finalEquityUSD = executed.equity_after_usd(end);

wins = pnl(pnl>0);
losses = pnl(pnl<0);
gp = sum(wins);
gl = abs(sum(losses));

if gl > 0
    metrics.profitFactor = gp/gl;
elseif gp > 0
    metrics.profitFactor = Inf;
end

equity = [initialEquityUSD; executed.equity_after_usd];
peak = cummax(equity);
ddPct = 100*(equity-peak)./peak;
metrics.maxDrawdownPct = abs(min(ddPct));
end
