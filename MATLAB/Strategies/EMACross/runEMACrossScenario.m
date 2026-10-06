function [trades,summary] = runEMACrossScenario( ...
    data,context,cfg,profile)
%RUNEMACROSSSCENARIO Ejecuta señales secuenciales sin posiciones solapadas.

p = cfg.emaCross;
rows = cell(0,1);
equity = cfg.risk.initialEquityUSD;

for sessionIndex = 1:numel(context.session_dates)
    D = context.session_data{sessionIndex};
    if isempty(D), continue; end

    dailyRow = context.daily( ...
        context.daily.session_date==context.session_dates(sessionIndex),:);

    if p.requireFullSession && ...
            ~isempty(dailyRow) && ~dailyRow.is_full_session(1)
        continue;
    end

    indicators = context.indicators( ...
        context.indicators.session_date== ...
        context.session_dates(sessionIndex),:);

    signalRows = find( ...
        indicators.long_signal | indicators.short_signal);
    tradesThisSession = 0;
    nextAllowedTime = NaT("TimeZone",char(cfg.marketTimezone));

    for signalIndex = reshape(signalRows,1,[])
        if tradesThisSession>=p.maximumTradesPerSession
            break;
        end

        signalTime = indicators.datetime_local(signalIndex);
        if ~isnat(nextAllowedTime) && signalTime<=nextAllowedTime
            continue;
        end

        entryIndex = signalIndex+1;
        if entryIndex>height(D), continue; end

        atrPoints = indicators.atr_points(signalIndex);
        if ~isfinite(atrPoints) || atrPoints<=0, continue; end

        if indicators.long_signal(signalIndex)
            side = 1;
            direction = "LONG";
        else
            side = -1;
            direction = "SHORT";
        end

        stopDistance = atrPoints*p.atrStopMultiple;
        signal = struct( ...
            "entryBarIndex",entryIndex, ...
            "side",side, ...
            "direction",direction, ...
            "stopDistance",stopDistance, ...
            "targetDistance",stopDistance*p.rewardRisk, ...
            "signalName","EMA_CROSS");

        trade = simulateBarSignalTrade( ...
            D,signal,cfg,profile,equity);

        trade.fast_ema = indicators.fast_ema(signalIndex);
        trade.slow_ema = indicators.slow_ema(signalIndex);
        trade.ema_spread_points = abs( ...
            trade.fast_ema-trade.slow_ema);
        trade.atr_points = atrPoints;
        trade.atr_stop_multiple = p.atrStopMultiple;
        trade.reward_risk = p.rewardRisk;
        trade.close_distance_to_fast = ...
            D.close(signalIndex)-trade.fast_ema;

        rows{end+1,1} = trade; %#ok<AGROW>

        if trade.valid
            equity = trade.equity_after_usd;
            nextAllowedTime = trade.exit_time;
            tradesThisSession = tradesThisSession+1;
        end
    end
end

if isempty(rows)
    trades = table();
else
    trades = struct2table(vertcat(rows{:}));
end

summary = calculateScenarioStatistics(trades,cfg,profile);
end
