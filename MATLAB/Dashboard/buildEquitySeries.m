function equity = buildEquitySeries(trades, initialEquityUSD)
executed = trades(trades.valid,:);
if isempty(executed)
    equity = table();
    return;
end
tradeTimeline = buildTradeTimeline(executed);
dates = [tradeTimeline(1)-milliseconds(1); tradeTimeline];
values = [initialEquityUSD; executed.equity_after_usd];
peak = cummax(values);
ddUSD = values-peak;
ddPct = 100*ddUSD./peak;
equity = table(dates,values,ddUSD,ddPct, ...
    'VariableNames',{'date','equity_usd','drawdown_usd','drawdown_pct'});
end
