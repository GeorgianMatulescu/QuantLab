function rolling = calculateRollingMetrics(trades,windowSize)
%CALCULATEROLLINGMETRICS Métricas móviles por ventana de observaciones.
%
% La ventana utiliza filas de la tabla de trades, que en ORB equivalen a
% oportunidades/sesiones. Dentro de cada ventana, las métricas de
% rendimiento se calculan solo con operaciones ejecutadas.

arguments
    trades table
    windowSize (1,1) double {mustBeInteger,mustBePositive}
end

rolling = struct( ...
    "dates",NaT(0,1), ...
    "win_rate_pct",zeros(0,1), ...
    "expectancy_r",zeros(0,1), ...
    "profit_factor",zeros(0,1), ...
    "sharpe",zeros(0,1), ...
    "drawdown_pct",zeros(0,1), ...
    "execution_rate_pct",zeros(0,1), ...
    "window_size",windowSize);

required = [ ...
    "session_date","valid","net_R", ...
    "net_pnl_usd","equity_before_usd","equity_after_usd"];

if isempty(trades) || height(trades)<windowSize || ...
        ~all(ismember(required,string(trades.Properties.VariableNames)))
    return;
end

trades = sortrows(trades,"session_date");
n = height(trades);
count = n-windowSize+1;

% Conservar exactamente la zona horaria de session_date.
% Evitamos preasignar con NaT(count,1), porque ese datetime no tiene
% TimeZone y MATLAB no permite asignarle fechas con zona horaria.
dates = trades.session_date(windowSize:end);

winRate = nan(count,1);
expectancy = nan(count,1);
profitFactor = nan(count,1);
sharpe = nan(count,1);
drawdown = nan(count,1);
executionRate = nan(count,1);

for k = 1:count
    firstRow = k;
    lastRow = k+windowSize-1;
    window = trades(firstRow:lastRow,:);

    executedMask = logical(window.valid);

    if ismember("contracts",string(window.Properties.VariableNames))
        executedMask = executedMask & ...
            isfinite(window.contracts) & ...
            window.contracts>0;
    end

    executionRate(k) = 100*sum(executedMask)/height(window);
    executed = window(executedMask,:);

    if isempty(executed)
        continue;
    end

    pnl = executed.net_pnl_usd;
    rValues = executed.net_R;

    winRate(k) = 100*sum(pnl>0)/height(executed);
    expectancy(k) = mean(rValues,"omitnan");

    gains = rValues(rValues>0);
    losses = rValues(rValues<0);

    grossGain = sum(gains,"omitnan");
    grossLoss = abs(sum(losses,"omitnan"));

    if grossLoss>0
        profitFactor(k) = grossGain/grossLoss;
    end

    tradeReturns = executed.net_pnl_usd ./ ...
        max(executed.equity_before_usd,eps);

    tradeReturns = tradeReturns(isfinite(tradeReturns));

    if numel(tradeReturns)>1 && std(tradeReturns)>0
        sharpe(k) = sqrt(numel(tradeReturns)) * ...
            mean(tradeReturns) / std(tradeReturns);
    end

    equity = [ ...
        window.equity_before_usd(1); ...
        window.equity_after_usd];

    runningPeak = cummax(equity);
    localDrawdown = 100*(equity-runningPeak)./runningPeak;
    drawdown(k) = min(localDrawdown,[],"omitnan");
end

rolling.dates = dates;
rolling.win_rate_pct = winRate;
rolling.expectancy_r = expectancy;
rolling.profit_factor = profitFactor;
rolling.sharpe = sharpe;
rolling.drawdown_pct = drawdown;
rolling.execution_rate_pct = executionRate;
end
