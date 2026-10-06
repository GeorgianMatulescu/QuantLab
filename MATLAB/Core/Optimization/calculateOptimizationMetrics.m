function metrics = calculateOptimizationMetrics( ...
    scenario,cfg,trainingPct)
%CALCULATEOPTIMIZATIONMETRICS Métricas comparables del optimizador.

arguments
    scenario (1,1) struct
    cfg (1,1) struct
    trainingPct (1,1) double ...
        {mustBeGreaterThan(trainingPct,0), ...
         mustBeLessThan(trainingPct,100)} = 70
end

metrics = createEmptyOptimizationMetrics();
metrics.status = "OK";

if ~isfield(scenario,"trades") || ...
        ~istable(scenario.trades)
    metrics.status = "ERROR";
    metrics.error_message = "Scenario has no trade table";
    return;
end

trades = scenario.trades;
variables = string(trades.Properties.VariableNames);

if ismember("valid",variables)
    trades = trades(logical(trades.valid),:);
end

if ismember("contracts",variables)
    trades = trades( ...
        isfinite(trades.contracts) & trades.contracts>0,:);
end

trades = sortExecutedTrades(trades);
metrics.executed_trades = height(trades);

fullDiagnostics = buildTradeBehaviorDiagnostics(trades);
metrics.target_exit_count = fullDiagnostics.target_exit_count;
metrics.stop_exit_count = fullDiagnostics.stop_exit_count;
metrics.eod_exit_count = fullDiagnostics.eod_exit_count;
metrics.other_exit_count = fullDiagnostics.other_exit_count;
metrics.behavior_signature = fullDiagnostics.signature;

if isempty(trades)
    return;
end

fullMetrics = calculateSlice(trades,cfg.risk.initialEquityUSD);

metrics.win_rate_pct = fullMetrics.win_rate_pct;
metrics.net_r = fullMetrics.net_r;
metrics.net_pnl_usd = fullMetrics.net_pnl_usd;
metrics.return_pct = fullMetrics.return_pct;
metrics.profit_factor = fullMetrics.profit_factor;
metrics.expectancy_r = fullMetrics.expectancy_r;
metrics.max_drawdown_pct = fullMetrics.max_drawdown_pct;
metrics.final_equity_usd = fullMetrics.final_equity_usd;
metrics.top_10_contribution_pct = ...
    fullMetrics.top_10_contribution_pct;

trainingEnd = max(1,min(height(trades)-1, ...
    floor(height(trades)*trainingPct/100)));

if height(trades)==1
    isTrades = trades;
    oosTrades = trades([],:);
else
    isTrades = trades(1:trainingEnd,:);
    oosTrades = trades(trainingEnd+1:end,:);
end

isMetrics = calculateSlice( ...
    isTrades,cfg.risk.initialEquityUSD);

oosStartingEquity = cfg.risk.initialEquityUSD + ...
    zeroIfNaN(isMetrics.net_pnl_usd);

oosMetrics = calculateSlice( ...
    oosTrades,oosStartingEquity);

metrics.is_count = height(isTrades);
metrics.is_expectancy_r = isMetrics.expectancy_r;
metrics.is_net_pnl_usd = isMetrics.net_pnl_usd;
metrics.oos_count = height(oosTrades);
metrics.oos_expectancy_r = oosMetrics.expectancy_r;
metrics.oos_net_pnl_usd = oosMetrics.net_pnl_usd;
metrics.oos_profit_factor = oosMetrics.profit_factor;
metrics.oos_max_drawdown_pct = oosMetrics.max_drawdown_pct;

oosDiagnostics = buildTradeBehaviorDiagnostics(oosTrades);
metrics.oos_target_exit_count = oosDiagnostics.target_exit_count;
metrics.oos_stop_exit_count = oosDiagnostics.stop_exit_count;
metrics.oos_eod_exit_count = oosDiagnostics.eod_exit_count;
metrics.oos_behavior_signature = oosDiagnostics.signature;

if isfinite(metrics.return_pct) && ...
        isfinite(metrics.max_drawdown_pct)
    metrics.return_drawdown_ratio = ...
        metrics.return_pct/max(metrics.max_drawdown_pct,0.10);
end

if isfinite(metrics.is_expectancy_r) && ...
        isfinite(metrics.oos_expectancy_r)
    metrics.robustness_score = ...
        min(metrics.is_expectancy_r, ...
            metrics.oos_expectancy_r) - ...
        0.5*abs( ...
            metrics.is_expectancy_r - ...
            metrics.oos_expectancy_r);

    if sign(metrics.is_expectancy_r)== ...
            sign(metrics.oos_expectancy_r)
        metrics.stable_sign = "YES";
    else
        metrics.stable_sign = "NO";
    end
end
end

function trades = sortExecutedTrades(trades)
variables = string(trades.Properties.VariableNames);

if ismember("session_date",variables)
    trades = sortrows(trades,"session_date");
elseif ismember("entry_time",variables)
    trades = sortrows(trades,"entry_time");
end
end

function metrics = calculateSlice(trades,startingEquity)
metrics = struct( ...
    "win_rate_pct",NaN, ...
    "net_r",NaN, ...
    "net_pnl_usd",NaN, ...
    "return_pct",NaN, ...
    "profit_factor",NaN, ...
    "expectancy_r",NaN, ...
    "max_drawdown_pct",NaN, ...
    "final_equity_usd",startingEquity, ...
    "top_10_contribution_pct",NaN);

if isempty(trades)
    return;
end

variables = string(trades.Properties.VariableNames);

if ismember("net_pnl_usd",variables)
    pnl = trades.net_pnl_usd;
    pnl = pnl(isfinite(pnl));
else
    pnl = [];
end

if ismember("net_R",variables)
    r = trades.net_R;
    r = r(isfinite(r));
else
    r = [];
end

if ~isempty(pnl)
    metrics.net_pnl_usd = sum(pnl);
    metrics.final_equity_usd = ...
        startingEquity + metrics.net_pnl_usd;
    metrics.return_pct = ...
        100*metrics.net_pnl_usd/startingEquity;
    metrics.win_rate_pct = ...
        100*sum(pnl>0)/numel(pnl);

    grossProfit = sum(pnl(pnl>0));
    grossLoss = abs(sum(pnl(pnl<0)));

    if grossLoss>0
        metrics.profit_factor = ...
            grossProfit/grossLoss;
    elseif grossProfit>0
        metrics.profit_factor = Inf;
    end

    equity = startingEquity + [0;cumsum(pnl)];
    runningPeak = cummax(equity);
    drawdownPct = 100*(equity-runningPeak)./runningPeak;
    metrics.max_drawdown_pct = ...
        abs(min(drawdownPct,[],"omitnan"));

    if metrics.net_pnl_usd>0
        sortedPnl = sort(pnl,"descend");
        topCount = max(1,ceil(numel(sortedPnl)*0.10));
        metrics.top_10_contribution_pct = ...
            100*sum(sortedPnl(1:topCount))/ ...
            metrics.net_pnl_usd;
    end
end

if ~isempty(r)
    metrics.net_r = sum(r);
    metrics.expectancy_r = mean(r);
elseif ~isempty(pnl)
    pnlScale = std(pnl);

    if ~isfinite(pnlScale) || pnlScale==0
        pnlScale = 1;
    end

    metrics.expectancy_r = mean(pnl/pnlScale);
end
end

function value = zeroIfNaN(value)
if ~isfinite(value)
    value = 0;
end
end
