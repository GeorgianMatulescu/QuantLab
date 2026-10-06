function trade = simulateORBTrade(D,dayInfo,cfg,profile,equityBeforeUSD)
%SIMULATEORBTRADE Adaptador ORB sobre contratos genéricos de mercado.

D = ensureCanonicalBarData(D,cfg);
spec = normalizeInstrumentSpec(cfg);
trade = createEmptyTradeRecord(cfg,profile.name);
trade.session_date = dayInfo.session_date;
trade.equity_before_usd = equityBeforeUSD;
trade.equity_after_usd = equityBeforeUSD;
trade.signal_name = "ORB";
trade.orb_open = dayInfo.orb_open;
trade.orb_high = dayInfo.orb_high;
trade.orb_low = dayInfo.orb_low;
trade.orb_close = dayInfo.orb_close;
trade.orb_range_points = dayInfo.orb_range_points;

M = D(D.time_local>=cfg.orbEnd & D.time_local<cfg.sessionEnd,:);
if isempty(M), trade.skip_reason="NO_POST_ORB_DATA"; return; end

direction = string(dayInfo.orb_direction);

switch direction
    case "LONG"
        side = 1;
        rawEntry = dayInfo.orb_close;
        entryPrice = resolveExecutionPrice(rawEntry,side,"ENTRY",profile,spec);
        stopPrice = dayInfo.orb_low;
        riskPoints = entryPrice-stopPrice;
        targetPrice = entryPrice+cfg.orb.rewardRisk*riskPoints;
    case "SHORT"
        side = -1;
        rawEntry = dayInfo.orb_close;
        entryPrice = resolveExecutionPrice(rawEntry,side,"ENTRY",profile,spec);
        stopPrice = dayInfo.orb_high;
        riskPoints = stopPrice-entryPrice;
        targetPrice = entryPrice-cfg.orb.rewardRisk*riskPoints;
    otherwise
        trade.skip_reason = "INVALID_DIRECTION";
        return;
end

if ~isfinite(riskPoints) || riskPoints<=0
    trade.skip_reason = "INVALID_RISK";
    return;
end

sizing = calculatePositionSize(riskPoints,equityBeforeUSD,cfg);
trade.direction = direction;
trade.entry_time = M.datetime_local(1);
trade.entry_price_raw = rawEntry;
trade.entry_price = entryPrice;
trade.stop_price = stopPrice;
trade.target_price = targetPrice;
trade.risk_points = riskPoints;
trade.risk_budget_usd = sizing.riskBudgetUSD;
trade.risk_per_quantity_usd = sizing.riskPerQuantityUSD;
trade.risk_per_contract_usd = sizing.riskPerQuantityUSD;
trade.quantity = sizing.quantity;
trade.contracts = sizing.quantity;
trade.effective_risk_usd = sizing.effectiveRiskUSD;

if sizing.skipTrade
    trade.skip_reason = sizing.skipReason;
    return;
end

exitPrice = NaN;
exitTime = NaT("TimeZone",char(spec.marketTimezone));
exitReason = "";
exitBarIndex = NaN;
maxFav = 0;
maxAdv = 0;

for j = 1:height(M)
    if side==1
        fav = M.high(j)-entryPrice;
        adv = entryPrice-M.low(j);
    else
        fav = entryPrice-M.low(j);
        adv = M.high(j)-entryPrice;
    end
    maxFav = max(maxFav,fav);
    maxAdv = max(maxAdv,adv);

    hit = resolveIntrabarExit( ...
        side,M.high(j),M.low(j),stopPrice,targetPrice,profile);
    if strlength(hit.exitReason)>0
        exitReason = hit.exitReason;
        if exitReason=="STOP", rawExit=stopPrice; else, rawExit=targetPrice; end
        exitPrice = resolveExecutionPrice( ...
            rawExit,side,exitReason,profile,spec);
        exitTime = M.datetime_local(j);
        exitBarIndex = j;
        break;
    end
end

if strlength(exitReason)==0
    exitReason = "EOD";
    exitPrice = resolveExecutionPrice( ...
        M.close(end),side,"EOD",profile,spec);
    exitTime = M.datetime_local(end);
    exitBarIndex = height(M);
end

grossPoints = side*(exitPrice-entryPrice);
grossPnLUSD = calculateInstrumentPnL( ...
    entryPrice,exitPrice,side,sizing.quantity,spec);
commissionUSD = calculateRoundTripCommission( ...
    profile,sizing.quantity,entryPrice,exitPrice,spec);
netPnLUSD = grossPnLUSD-commissionUSD;

trade.valid = true;
trade.exit_time = exitTime;
trade.exit_price = exitPrice;
trade.exit_reason = exitReason;
trade.bars_held = exitBarIndex;
trade.gross_points = grossPoints;
trade.gross_R = grossPoints/riskPoints;
trade.net_R = netPnLUSD/sizing.effectiveRiskUSD;
trade.gross_pnl_usd = grossPnLUSD;
trade.commission_usd = commissionUSD;
trade.net_pnl_usd = netPnLUSD;
trade.equity_after_usd = equityBeforeUSD+netPnLUSD;
trade.mfe_points = maxFav;
trade.mae_points = maxAdv;
trade.mfe_R = maxFav/riskPoints;
trade.mae_R = maxAdv/riskPoints;
end
