function trade = simulateBarSignalTrade( ...
    sessionBars,signal,cfg,profile,equityBeforeUSD)
%SIMULATEBARSIGNALTRADE Simulador reusable para una señal de barras.
%
% signal requiere:
%   entryBarIndex, side, direction, stopDistance, targetDistance
% Opcional:
%   signalName

arguments
    sessionBars table
    signal (1,1) struct
    cfg (1,1) struct
    profile (1,1) struct
    equityBeforeUSD (1,1) double {mustBePositive}
end

D = ensureCanonicalBarData(sessionBars,cfg);
spec = normalizeInstrumentSpec(cfg);
trade = createEmptyTradeRecord(cfg,profile.name);
trade.equity_before_usd = equityBeforeUSD;
trade.equity_after_usd = equityBeforeUSD;

required = ["entryBarIndex","side","direction", ...
    "stopDistance","targetDistance"];
missing = required(~isfield(signal,required));
if ~isempty(missing)
    trade.skip_reason = "INVALID_SIGNAL_CONTRACT";
    return;
end

entryIndex = signal.entryBarIndex;
side = signal.side;

if entryIndex<1 || entryIndex>height(D)
    trade.skip_reason = "ENTRY_BAR_OUT_OF_RANGE";
    return;
end

if ~ismember(side,[-1 1]) || signal.stopDistance<=0 || ...
        signal.targetDistance<=0
    trade.skip_reason = "INVALID_SIGNAL_VALUES";
    return;
end

rawEntry = D.open(entryIndex);
entryPrice = resolveExecutionPrice( ...
    rawEntry,side,"ENTRY",profile,spec);

if side==1
    stopPrice = entryPrice-signal.stopDistance;
    targetPrice = entryPrice+signal.targetDistance;
else
    stopPrice = entryPrice+signal.stopDistance;
    targetPrice = entryPrice-signal.targetDistance;
end

riskPoints = abs(entryPrice-stopPrice);
sizing = calculatePositionSize(riskPoints,equityBeforeUSD,cfg);

trade.session_date = D.session_date(entryIndex);
trade.direction = string(signal.direction);
trade.entry_time = D.datetime_local(entryIndex);
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

if isfield(signal,"signalName")
    trade.signal_name = string(signal.signalName);
end

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

for j = entryIndex:height(D)
    if side==1
        favorable = D.high(j)-entryPrice;
        adverse = entryPrice-D.low(j);
    else
        favorable = entryPrice-D.low(j);
        adverse = D.high(j)-entryPrice;
    end

    maxFav = max(maxFav,favorable);
    maxAdv = max(maxAdv,adverse);

    hit = resolveIntrabarExit( ...
        side,D.high(j),D.low(j),stopPrice,targetPrice,profile);

    if strlength(hit.exitReason)>0
        exitReason = hit.exitReason;
        if exitReason=="STOP"
            rawExit = stopPrice;
        else
            rawExit = targetPrice;
        end
        exitPrice = resolveExecutionPrice( ...
            rawExit,side,exitReason,profile,spec);
        exitTime = D.datetime_local(j);
        exitBarIndex = j;
        break;
    end
end

if strlength(exitReason)==0
    exitReason = "EOD";
    exitPrice = resolveExecutionPrice( ...
        D.close(end),side,"EOD",profile,spec);
    exitTime = D.datetime_local(end);
    exitBarIndex = height(D);
end

grossPoints = side*(exitPrice-entryPrice);
grossPnL = calculateInstrumentPnL( ...
    entryPrice,exitPrice,side,sizing.quantity,spec);
commission = calculateRoundTripCommission( ...
    profile,sizing.quantity,entryPrice,exitPrice,spec);
netPnL = grossPnL-commission;

trade.valid = true;
trade.exit_time = exitTime;
trade.exit_price = exitPrice;
trade.exit_reason = exitReason;
trade.bars_held = exitBarIndex-entryIndex+1;
trade.gross_points = grossPoints;
trade.gross_R = grossPoints/riskPoints;
trade.net_R = netPnL/sizing.effectiveRiskUSD;
trade.gross_pnl_usd = grossPnL;
trade.commission_usd = commission;
trade.net_pnl_usd = netPnL;
trade.equity_after_usd = equityBeforeUSD+netPnL;
trade.mfe_points = maxFav;
trade.mae_points = maxAdv;
trade.mfe_R = maxFav/riskPoints;
trade.mae_R = maxAdv/riskPoints;
end
