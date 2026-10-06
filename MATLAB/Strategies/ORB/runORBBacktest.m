function [trades,summary] = runORBBacktest(T,daily,cfg)
%RUNORBBACKTEST Legacy helper using the IDEAL execution profile.

arguments
    T table
    daily table
    cfg (1,1) struct
end

profile = cfg.executionProfiles(1);
results = cell(height(daily),1);
keep = false(height(daily),1);
equity = cfg.risk.initialEquityUSD;

for i = 1:height(daily)
    dayInfo = daily(i,:);
    if ~dayInfo.orb_valid, continue; end
    if cfg.orb.requireFullSession && ~dayInfo.is_full_session, continue; end
    if dayInfo.orb_direction=="DOJI" && ~cfg.orb.tradeDoji, continue; end

    D = T(T.session_date_new_york==dayInfo.session_date,:);
    D = sortrows(D,"datetime_new_york");
    trade = simulateORBTrade(D,dayInfo,cfg,profile,equity);

    if trade.valid
        results{i} = trade;
        keep(i) = true;
        equity = trade.equity_after_usd;
    end
end

results = results(keep);
if isempty(results)
    trades = table();
else
    trades = struct2table(vertcat(results{:}));
end
summary = calculateORBStatistics(trades);
end
