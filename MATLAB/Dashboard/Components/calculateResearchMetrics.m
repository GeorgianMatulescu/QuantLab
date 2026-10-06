function m = calculateResearchMetrics(trades,cfg)
%CALCULATERESEARCHMETRICS Métricas comunes del Research Terminal.
%
% Esta función queda desacoplada de la interfaz gráfica para poder
% reutilizarla en informes, tests y estrategias futuras.

arguments
    trades table
    cfg (1,1) struct
end

executed = trades(trades.valid,:);
initial = cfg.risk.initialEquityUSD;

m = struct( ...
    "startEquity",initial, ...
    "endEquity",initial, ...
    "netProfitUSD",0, ...
    "returnPct",0, ...
    "totalFees",0, ...
    "totalContracts",0, ...
    "totalQuantity",0, ...
    "totalOrders",height(executed), ...
    "winRatePct",NaN, ...
    "lossRatePct",NaN, ...
    "averageWinPct",NaN, ...
    "averageLossPct",NaN, ...
    "profitLossRatio",NaN, ...
    "expectancyR",NaN, ...
    "maxDrawdownPct",0, ...
    "sharpeRatio",NaN, ...
    "sortinoRatio",NaN, ...
    "cagrPct",NaN, ...
    "annualStd",NaN, ...
    "annualVariance",NaN, ...
    "turnoverPct",NaN, ...
    "drawdownRecoveryTrades",NaN, ...
    "psrPct",NaN);

if isempty(executed)
    return;
end

m.endEquity = executed.equity_after_usd(end);
m.netProfitUSD = m.endEquity-initial;
m.returnPct = 100*m.netProfitUSD/initial;
m.totalFees = sum(executed.commission_usd,"omitnan");
if ismember("quantity",string(executed.Properties.VariableNames))
    quantity = executed.quantity;
else
    quantity = executed.contracts;
end
m.totalQuantity = sum(quantity,"omitnan");
m.totalContracts = m.totalQuantity; % Alias de compatibilidad.

pnlPct = 100*executed.net_pnl_usd ./ ...
    max(executed.equity_before_usd,eps);

wins = pnlPct(pnlPct>0);
losses = pnlPct(pnlPct<0);

m.winRatePct = 100*numel(wins)/height(executed);
m.lossRatePct = 100*numel(losses)/height(executed);

if ~isempty(wins)
    m.averageWinPct = mean(wins);
end

if ~isempty(losses)
    m.averageLossPct = mean(losses);
end

if ~isempty(wins) && ~isempty(losses) && mean(abs(losses))>0
    m.profitLossRatio = mean(wins)/mean(abs(losses));
end

m.expectancyR = mean(executed.net_R,"omitnan");

equity = [initial;executed.equity_after_usd];
peak = cummax(equity);
drawdownPct = 100*(equity-peak)./peak;
m.maxDrawdownPct = abs(min(drawdownPct));

returns = diff(equity)./equity(1:end-1);
returns = returns(isfinite(returns));

if numel(returns)>1
    volatility = std(returns);
    downsideVolatility = std(min(returns,0));

    if volatility>0
        m.sharpeRatio = sqrt(252)*mean(returns)/volatility;
    end

    if downsideVolatility>0
        m.sortinoRatio = ...
            sqrt(252)*mean(returns)/downsideVolatility;
    end

    m.annualStd = volatility*sqrt(252);
    m.annualVariance = var(returns)*252;
end

years = days( ...
    executed.session_date(end)-executed.session_date(1))/365.25;

if years>0 && m.endEquity>0
    m.cagrPct = ...
        100*((m.endEquity/initial)^(1/years)-1);
end

instrumentSpec = normalizeInstrumentSpec(cfg);
notional = abs( ...
    executed.entry_price .* quantity .* ...
    instrumentSpec.contractMultiplier);

m.turnoverPct = 100*sum(notional) / ...
    max(mean(executed.equity_before_usd),eps);

trough = find(drawdownPct==min(drawdownPct),1,"first");

if ~isempty(trough)
    priorPeak = peak(trough);
    recovery = find( ...
        equity(trough:end)>=priorPeak,1,"first");

    if ~isempty(recovery)
        m.drawdownRecoveryTrades = recovery-1;
    end
end
end
