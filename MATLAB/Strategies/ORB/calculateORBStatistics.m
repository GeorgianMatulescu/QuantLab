function summary = calculateORBStatistics(trades)
%CALCULATEORBSTATISTICS Métricas principales de la estrategia ORB.

summary = struct( ...
    "totalTrades", 0, ...
    "winningTrades", 0, ...
    "losingTrades", 0, ...
    "breakevenTrades", 0, ...
    "winRatePct", NaN, ...
    "grossR", 0, ...
    "netR", 0, ...
    "averageWinR", NaN, ...
    "averageLossR", NaN, ...
    "profitFactor", NaN, ...
    "expectancyR", NaN, ...
    "maxDrawdownR", NaN, ...
    "stopTrades", 0, ...
    "targetTrades", 0, ...
    "eodTrades", 0, ...
    "longTrades", 0, ...
    "shortTrades", 0);

if isempty(trades)
    return;
end

r = trades.net_R;
summary.totalTrades = height(trades);
summary.winningTrades = nnz(r > 0);
summary.losingTrades = nnz(r < 0);
summary.breakevenTrades = nnz(r == 0);
summary.winRatePct = 100 * summary.winningTrades / summary.totalTrades;
summary.grossR = sum(trades.gross_R, "omitnan");
summary.netR = sum(r, "omitnan");
summary.expectancyR = mean(r, "omitnan");

wins = r(r > 0);
losses = r(r < 0);

if ~isempty(wins)
    summary.averageWinR = mean(wins);
end
if ~isempty(losses)
    summary.averageLossR = mean(losses);
end

grossProfit = sum(wins);
grossLoss = abs(sum(losses));

if grossLoss > 0
    summary.profitFactor = grossProfit / grossLoss;
elseif grossProfit > 0
    summary.profitFactor = Inf;
end

equity = cumsum(r);
runningPeak = cummax([0; equity]);
drawdown = [0; equity] - runningPeak;
summary.maxDrawdownR = abs(min(drawdown));

summary.stopTrades = nnz(trades.exit_reason == "STOP");
summary.targetTrades = nnz(trades.exit_reason == "TARGET");
summary.eodTrades = nnz(trades.exit_reason == "EOD");
summary.longTrades = nnz(trades.direction == "LONG");
summary.shortTrades = nnz(trades.direction == "SHORT");
end
