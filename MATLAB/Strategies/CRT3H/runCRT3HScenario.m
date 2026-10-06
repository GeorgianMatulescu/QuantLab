function [trades,summary] = runCRT3HScenario(data,context,cfg,profile)
%RUNCRT3HSCENARIO Ejecuta Londres y NY de forma secuencial.

% RUNSTRATEGY ya entrega BarData canónico. Evitamos ordenar y duplicar la
% tabla completa en cada una de las combinaciones del Dashboard. Se mantiene
% el fallback para pruebas o llamadas directas con una tabla mínima.
required = ["datetime_local","session_date","time_local", ...
    "open","high","low","close","volume","symbol"];
if ~all(ismember(required,string(data.Properties.VariableNames)))
    data = ensureCanonicalBarData(data,cfg);
end
windows = context.windows;
if mod(numel(windows),2)~=0
    error("QuantLab:CRT3HWindowPairs", ...
        "Las ventanas CRT deben llegar en pares Londres/Nueva York.");
end
days = [windows(1:2:end).session_date];
rows = cell(0,1);
equityUSD = cfg.risk.initialEquityUSD;
activeUntil = NaT("TimeZone",char(cfg.marketTimezone));

for i = 1:numel(days)
    london = windows(2*i-1);
    newYork = windows(2*i);
    if london.session_name~="LONDRES" || ...
            newYork.session_name~="NUEVA_YORK" || ...
            london.session_date~=days(i) || newYork.session_date~=days(i)
        error("QuantLab:CRT3HWindowOrder", ...
            "Orden de ventanas CRT no válido para %s.",string(days(i)));
    end

    if cfg.crt3h.enableLondon
        londonTrade = evaluateRangeCandidates( ...
            data,london,cfg,profile,equityUSD,activeUntil);
    else
        londonTrade = makeSessionTrade( ...
            cfg,profile,london,equityUSD,"SESSION_DISABLED");
    end
    rows{end+1,1} = londonTrade; %#ok<AGROW>

    if londonTrade.valid
        equityUSD = londonTrade.equity_after_usd;
        activeUntil = londonTrade.exit_time;
    end

    londonTpBlocksNy = logical(cfg.crt3h.blockNyAfterLondonTP) && ...
        londonTrade.valid && londonTrade.exit_reason=="TARGET" && ...
        londonTrade.exit_time<=newYork.man_end;

    if ~cfg.crt3h.enableNewYork
        newYorkTrade = makeSessionTrade( ...
            cfg,profile,newYork,equityUSD,"SESSION_DISABLED");
    elseif londonTpBlocksNy
        newYorkTrade = makeSessionTrade( ...
            cfg,profile,newYork,equityUSD,"LONDON_TP_BLOCK");
    else
        newYorkTrade = evaluateRangeCandidates( ...
            data,newYork,cfg,profile,equityUSD,activeUntil);
    end
    rows{end+1,1} = newYorkTrade; %#ok<AGROW>

    if newYorkTrade.valid
        equityUSD = newYorkTrade.equity_after_usd;
        activeUntil = newYorkTrade.exit_time;
    end
end

if isempty(rows)
    trades = table();
else
    trades = struct2table(vertcat(rows{:}));
end

summary = calculateScenarioStatistics(trades,cfg,profile);
end

function trade = evaluateRangeCandidates( ...
    data,w,cfg,profile,equityBeforeUSD,activeUntil)
%EVALUATERANGECANDIDATES Aplica "primera señal" entre rangos paralelos.
%
% Una ventana CRT normal no contiene candidatos y conserva exactamente el
% comportamiento histórico. SESSION_RANGE_MADRID puede adjuntar Asia y
% Londres a la misma sesión de Nueva York; se ejecuta como máximo el setup
% cuyo fill válido aparece primero. Los empates exactos respetan el orden
% configurado de los candidatos (Asia antes que Londres por defecto).

if ~isfield(w,"range_candidates") || isempty(w.range_candidates)
    trade = evaluateCRTWindow( ...
        data,w,cfg,profile,equityBeforeUSD,activeUntil);
    return;
end

candidates = w.range_candidates;
candidateTrades = cell(numel(candidates),1);
candidateValid = false(numel(candidates),1);
candidateComplete = false(numel(candidates),1);
candidateEntryTimes = NaT(numel(candidates),1, ...
    "TimeZone",char(cfg.marketTimezone));
candidateSweepTimes = NaT(numel(candidates),1, ...
    "TimeZone",char(cfg.marketTimezone));
for i = 1:numel(candidates)
    candidateTrade = evaluateCRTWindow( ...
        data,candidates(i),cfg,profile,equityBeforeUSD,activeUntil);
    if ~isstruct(candidateTrade) || ~isscalar(candidateTrade)
        error("QuantLab:CRT3HCandidateTradeShape", ...
            "El candidato %d de %s no devolvió un registro escalar.", ...
            i,string(w.session_name));
    end
    candidateTrades{i} = candidateTrade;
    candidateValid(i) = logical(candidateTrade.valid);
    candidateComplete(i) = logical(candidateTrade.data_complete);
    candidateEntryTimes(i) = candidateTrade.entry_time;
    candidateSweepTimes(i) = candidateTrade.sweep_time;
end

validIndices = find(candidateValid);
if ~isempty(validIndices)
    selected = validIndices(1);
    selectedTime = candidateEntryTimes(selected);
    for i = validIndices(2:end)'
        candidateTime = candidateEntryTimes(i);
        if candidateTime<selectedTime
            selected = i;
            selectedTime = candidateTime;
        end
    end
    trade = candidateTrades{selected};
    return;
end

% Si no hubo fill, conserva para auditoría el primer setup detectado. Si
% ninguno barrió un rango, devuelve el primer rango completo configurado.
selected = 0;
selectedTime = NaT("TimeZone",char(cfg.marketTimezone));
for i = 1:numel(candidates)
    candidateTime = candidateSweepTimes(i);
    if ~isnat(candidateTime) && ...
            (selected==0 || candidateTime<selectedTime)
        selected = i;
        selectedTime = candidateTime;
    end
end
if selected==0
    complete = find(candidateComplete,1,"first");
    if isempty(complete), complete = 1; end
    selected = complete;
end
trade = candidateTrades{selected};
end

function trade = evaluateCRTWindow( ...
    data,w,cfg,profile,equityBeforeUSD,activeUntil)

trade = makeSessionTrade(cfg,profile,w,equityBeforeUSD,"");

if ~w.data_complete
    trade = markSkipped(trade,"INCOMPLETE_EXTENDED_DATA");
    return;
end

if ~isnat(activeUntil) && activeUntil>=w.man_end
    trade = markSkipped(trade,"POSITION_OPEN");
    return;
end

threshold = resolveThreshold(cfg,w.session_name);
tick = cfg.instrumentSpec.tickSize;
state = 0;
extreme = NaN;
entryLevel = NaN;
stopLevel = NaN;
sweepTime = NaT("TimeZone",char(cfg.marketTimezone));
lastExtremeIndex = NaN;
extremeTime = NaT("TimeZone",char(cfg.marketTimezone));

for k = 1:numel(w.man_indices)
    index = w.man_indices(k);
    if ~isnat(activeUntil) && data.datetime_local(index)<=activeUntil
        continue;
    end

    if state==0
        sweptLow = data.low(index)<=w.crt_low-threshold;
        sweptHigh = data.high(index)>=w.crt_high+threshold;
        if sweptLow==sweptHigh
            continue;
        end

        if sweptLow
            state = 1;
            extreme = data.low(index);
        else
            state = -1;
            extreme = data.high(index);
        end
        [entryLevel,stopLevel] = entryAndStop( ...
            state,extreme,w.crt_high,w.crt_low,tick, ...
            cfg.crt3h.entryFraction);
        sweepTime = data.datetime_local(index);
        lastExtremeIndex = index;
        extremeTime = sweepTime;
        continue;
    end

    if state==1 && data.low(index)<extreme
        extreme = data.low(index);
        [entryLevel,stopLevel] = entryAndStop( ...
            state,extreme,w.crt_high,w.crt_low,tick, ...
            cfg.crt3h.entryFraction);
        lastExtremeIndex = index;
        extremeTime = data.datetime_local(index);
        continue;
    elseif state==-1 && data.high(index)>extreme
        extreme = data.high(index);
        [entryLevel,stopLevel] = entryAndStop( ...
            state,extreme,w.crt_high,w.crt_low,tick, ...
            cfg.crt3h.entryFraction);
        lastExtremeIndex = index;
        extremeTime = data.datetime_local(index);
        continue;
    end

    touched = (state==1 && data.high(index)>=entryLevel) || ...
        (state==-1 && data.low(index)<=entryLevel);

    if touched && index>lastExtremeIndex
        trade = simulateCRTTrade( ...
            data,index,state,entryLevel,stopLevel,extreme, ...
            sweepTime,extremeTime,w,threshold,cfg,profile,equityBeforeUSD);
        return;
    end
end

if state==0
    trade = markSkipped(trade,"NO_SETUP");
else
    trade.setup_status = "SETUP_DETECTED";
    trade.order_status = "NOT_TRIGGERED";
    trade.direction = directionName(state);
    trade.sweep_time = sweepTime;
    trade.extreme_time = extremeTime;
    trade.sweep_side = sweepSide(state);
    trade.manipulation_extreme = extreme;
    trade.entry_level = entryLevel;
    trade.entry_level_50 = entryAndStop( ...
        state,extreme,w.crt_high,w.crt_low,tick,0.5);
    trade.stop_price = stopLevel;
    trade.manipulation_points = manipulationSize(state,extreme,w);
    trade.skip_reason = "SETUP_NO_ENTRY";
end
end

function trade = simulateCRTTrade( ...
    data,entryIndex,side,entryLevel,stopLevel,extreme,sweepTime, ...
    extremeTime,w,threshold,cfg,profile,equityBeforeUSD)

spec = normalizeInstrumentSpec(cfg);
trade = makeSessionTrade(cfg,profile,w,equityBeforeUSD,"");
trade.setup_status = "SETUP_DETECTED";
trade.order_status = "TRIGGERED";
trade.direction = directionName(side);
signalPrefix = "CRT_3H";
if isfield(cfg.crt3h,"signalPrefix")
    signalPrefix = upper(string(cfg.crt3h.signalPrefix));
end
referenceName = resolveReferenceName(w);
if signalPrefix=="CRT_3H"
    trade.signal_name = signalPrefix + "_RETURN_" + ...
        string(round(100*cfg.crt3h.entryFraction));
else
    trade.signal_name = signalPrefix + "_" + referenceName + ...
        "_RETURN_" + string(round(100*cfg.crt3h.entryFraction));
end
trade.sweep_time = sweepTime;
trade.extreme_time = extremeTime;
trade.sweep_side = sweepSide(side);
trade.manipulation_extreme = extreme;
trade.manipulation_points = manipulationSize(side,extreme,w);
trade.entry_level = entryLevel;
trade.entry_level_50 = entryAndStop( ...
    side,extreme,w.crt_high,w.crt_low,spec.tickSize,0.5);
trade.threshold_points = threshold;

% La entrada es una orden stop pendiente. Si la barra abre atravesando el
% nivel, TradingView/mercado la ejecuta en la apertura adversa, no en el
% nivel fraccional teórico.
if side==1
    rawEntry = max(entryLevel,data.open(entryIndex));
else
    rawEntry = min(entryLevel,data.open(entryIndex));
end
entryPrice = resolveExecutionPrice( ...
    rawEntry,side,"ENTRY",profile,spec);
riskPoints = abs(entryPrice-stopLevel);
managementMode = upper(string(cfg.crt3h.exitManagement.mode));
trailing = trailingFromFill( ...
    side,entryPrice,riskPoints, ...
    cfg.crt3h.exitManagement.trailing,spec.tickSize);
if managementMode=="FIXED_TARGET"
    initialTargetR = cfg.crt3h.rewardRisk;
else
    initialTargetR = trailing.activationR;
end
targetLevel = targetFromFill( ...
    side,entryPrice,stopLevel,initialTargetR,spec.tickSize);
breakEven = breakEvenFromFill( ...
    side,entryPrice,riskPoints,cfg.crt3h.breakEven,spec.tickSize);

trade.order_time = data.datetime_local(entryIndex);
trade.order_price = entryLevel;
trade.stop_price = stopLevel;
trade.initial_stop_price = stopLevel;
trade.target_price = targetLevel;
trade.exit_management = managementMode;
trade.trailing_enabled = managementMode== ...
    "SWING_TRAILING_STEP_TARGET" && trailing.enabled;
trade.trailing_activation_r = trailing.activationR;
trade.trailing_activation_price = trailing.activationPrice;
trade.trailing_target_step_r = trailing.targetStepR;
trade.trailing_swing_left_bars = trailing.swingLeftBars;
trade.trailing_swing_right_bars = trailing.swingRightBars;
trade.trailing_swing_offset_ticks = trailing.swingOffsetTicks;
trade.final_target_r = initialTargetR;
trade.final_target_price = targetLevel;
trade.break_even_enabled = breakEven.enabled;
trade.break_even_trigger_r = breakEven.triggerR;
trade.break_even_trigger_price = breakEven.triggerPrice;
trade.break_even_price = breakEven.stopPrice;
trade.risk_points = riskPoints;

if riskPoints<=0 || ...
        (side==1 && targetLevel<=entryPrice) || ...
        (side==-1 && targetLevel>=entryPrice) || ...
        ~breakEven.valid || ~trailing.valid
    trade = markSkipped(trade,"INVALID_EXECUTION_LEVELS");
    return;
end

sizing = calculatePositionSize(riskPoints,equityBeforeUSD,cfg);
trade.risk_budget_usd = sizing.riskBudgetUSD;
trade.risk_per_quantity_usd = sizing.riskPerQuantityUSD;
trade.risk_per_contract_usd = sizing.riskPerQuantityUSD;
trade.quantity = sizing.quantity;
trade.contracts = sizing.quantity;
trade.effective_risk_usd = sizing.effectiveRiskUSD;

if sizing.skipTrade
    trade = markSkipped(trade,sizing.skipReason);
    return;
end

% A partir de este punto existe un fill real. Los campos entry_* nunca se
% rellenan en una sesión sin ejecución o en una orden rechazada.
trade.valid = true;
trade.record_type = "TRADE";
trade.setup_status = "EXECUTED";
trade.order_status = "FILLED";
trade.entry_time = data.datetime_local(entryIndex);
trade.entry_price_raw = rawEntry;
trade.entry_price = entryPrice;

if managementMode=="FIXED_TARGET" || ~trailing.enabled
    [trade,exitState] = simulateFixedTargetExit( ...
        data,entryIndex,side,entryPrice,stopLevel,targetLevel, ...
        breakEven,cfg,profile,spec,trade);
else
    [trade,exitState] = simulateSwingTrailingExit( ...
        data,entryIndex,side,entryPrice,riskPoints,stopLevel, ...
        targetLevel,breakEven,trailing,cfg,profile,spec,trade);
end

exitPrice = exitState.exitPrice;
exitTime = exitState.exitTime;
exitReason = exitState.exitReason;
exitBarIndex = exitState.exitBarIndex;
maxFav = exitState.maxFav;
maxAdv = exitState.maxAdv;

grossPoints = side*(exitPrice-entryPrice);
grossPnL = calculateInstrumentPnL( ...
    entryPrice,exitPrice,side,sizing.quantity,spec);
commission = calculateRoundTripCommission( ...
    profile,sizing.quantity,entryPrice,exitPrice,spec);
netPnL = grossPnL-commission;

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

function [trade,state] = simulateFixedTargetExit( ...
    data,entryIndex,side,entryPrice,stopLevel,targetLevel, ...
    breakEven,cfg,profile,spec,trade)
%SIMULATEFIXEDTARGETEXIT Conserva la gestión fija de la v0.25.16.

state = emptyExitState(spec.marketTimezone);
firstExitIndex = entryIndex + double(~cfg.crt3h.allowExitOnEntryBar);
activeStopLevel = stopLevel;
breakEvenActive = false;

for j = entryIndex:height(data)
    [state.maxFav,state.maxAdv] = updateExcursion( ...
        state.maxFav,state.maxAdv,side,entryPrice, ...
        data.high(j),data.low(j));
    if j<firstExitIndex, continue; end

    hit = resolveIntrabarExit( ...
        side,data.high(j),data.low(j),activeStopLevel,targetLevel,profile);
    if strlength(hit.exitReason)==0
        if breakEven.enabled && ~breakEvenActive && ...
                breakEvenTriggerTouched( ...
                side,data.high(j),data.low(j),breakEven.triggerPrice)
            trade.break_even_triggered = true;
            trade.break_even_trigger_time = data.datetime_local(j);
            breakEvenActive = true;
            activeStopLevel = breakEven.stopPrice;
            trade.break_even_effective_time = effectiveTime( ...
                data,j,breakEven.activateOnNextBar);

            if breakEven.activateOnNextBar
                continue;
            end
            hit = resolveIntrabarExit( ...
                side,data.high(j),data.low(j), ...
                activeStopLevel,targetLevel,profile);
            if hit.exitReason~="STOP", continue; end
        else
            continue;
        end
    end

    reason = hit.exitReason;
    if reason=="STOP"
        rawExit = activeStopLevel;
        if breakEvenActive, reason = "BREAKEVEN"; end
    else
        rawExit = targetLevel;
    end
    state = closeExitState(state,data,j,rawExit,reason, ...
        side,profile,spec);
    break;
end

state = closeAtEndOfDataIfNeeded(state,data,side,profile,spec);
end

function [trade,state] = simulateSwingTrailingExit( ...
    data,entryIndex,side,entryPrice,riskPoints,stopLevel,targetLevel, ...
    breakEven,trailing,cfg,profile,spec,trade)
%SIMULATESWINGTRAILINGEXIT TP virtual escalonado y stop estructural.
%
% Cada barra puede avanzar como máximo un escalón. Los cambios confirmados
% al cierre pasan a ser ejecutables en la barra siguiente, salvo que la
% configuración solicite explícitamente aplicación inmediata.

state = emptyExitState(spec.marketTimezone);
firstExitIndex = entryIndex + double(~cfg.crt3h.allowExitOnEntryBar);
activeStopLevel = stopLevel;
breakEvenActive = false;
trailingActive = false;
structuralStopActive = false;
activeTargetR = trailing.activationR;
latestSwingStop = NaN;
stopTimes = NaT(0,1,"TimeZone",char(spec.marketTimezone));
stopPrices = zeros(0,1);
targetTimes = NaT(0,1,"TimeZone",char(spec.marketTimezone));
targetPrices = zeros(0,1);

for j = entryIndex:height(data)
    [state.maxFav,state.maxAdv] = updateExcursion( ...
        state.maxFav,state.maxAdv,side,entryPrice, ...
        data.high(j),data.low(j));
    if j<firstExitIndex, continue; end

    % STOP_FIRST: el stop que ya estaba vigente se resuelve antes de
    % utilizar hitos o swings confirmados por esta misma vela.
    if stopTouched(side,data.high(j),data.low(j),activeStopLevel)
        if structuralStopActive
            reason = "TRAILING_STOP";
            trade.trailing_stop_triggered = true;
        elseif breakEvenActive
            reason = "BREAKEVEN";
        else
            reason = "STOP";
        end
        state = closeExitState(state,data,j,activeStopLevel,reason, ...
            side,profile,spec);
        break;
    end

    immediateStopUpdate = false;

    if breakEven.enabled && ~breakEvenActive && ...
            breakEvenTriggerTouched( ...
            side,data.high(j),data.low(j),breakEven.triggerPrice)
        trade.break_even_triggered = true;
        trade.break_even_trigger_time = data.datetime_local(j);
        trade.break_even_effective_time = effectiveTime( ...
            data,j,breakEven.activateOnNextBar);
        breakEvenActive = true;
        activeStopLevel = improveStop( ...
            side,activeStopLevel,breakEven.stopPrice);
        immediateStopUpdate = ~breakEven.activateOnNextBar;
    end

    confirmedStop = confirmedSwingStop( ...
        data,j,entryIndex,side,trailing,spec.tickSize);
    if isfinite(confirmedStop)
        latestSwingStop = confirmedStop;
    end

    if favorableLevelTouched( ...
            side,data.high(j),data.low(j),targetLevel)
        if ~trailingActive
            trailingActive = true;
            trade.trailing_activated = true;
            trade.trailing_activation_time = data.datetime_local(j);
        end

        activeTargetR = activeTargetR+trailing.targetStepR;
        targetLevel = targetFromRisk( ...
            side,entryPrice,riskPoints,activeTargetR,spec.tickSize);
        trade.target_steps_advanced = trade.target_steps_advanced+1;
        trade.final_target_r = activeTargetR;
        trade.final_target_price = targetLevel;
        targetTimes(end+1,1) = effectiveTime( ...
            data,j,trailing.activateOnNextBar); %#ok<AGROW>
        targetPrices(end+1,1) = targetLevel; %#ok<AGROW>
    end

    if trailingActive && isfinite(latestSwingStop)
        improvedStop = improveStop( ...
            side,activeStopLevel,latestSwingStop);
        validBehindMarket = (side==1 && improvedStop<data.close(j)) || ...
            (side==-1 && improvedStop>data.close(j));
        if improvedStop~=activeStopLevel && validBehindMarket
            activeStopLevel = improvedStop;
            structuralStopActive = true;
            trade.trailing_stop_price = activeStopLevel;
            trade.trailing_stop_effective_time = effectiveTime( ...
                data,j,trailing.activateOnNextBar);
            stopTimes(end+1,1) = ...
                trade.trailing_stop_effective_time; %#ok<AGROW>
            stopPrices(end+1,1) = activeStopLevel; %#ok<AGROW>
            immediateStopUpdate = immediateStopUpdate || ...
                ~trailing.activateOnNextBar;
        end
    end

    if immediateStopUpdate && ...
            stopTouched(side,data.high(j),data.low(j),activeStopLevel)
        if structuralStopActive
            reason = "TRAILING_STOP";
            trade.trailing_stop_triggered = true;
        elseif breakEvenActive
            reason = "BREAKEVEN";
        else
            reason = "STOP";
        end
        state = closeExitState(state,data,j,activeStopLevel,reason, ...
            side,profile,spec);
        break;
    end
end

trade.trailing_stop_times = encodeDateTimeSeries(stopTimes);
trade.trailing_stop_prices = encodeNumericSeries(stopPrices);
trade.target_step_times = encodeDateTimeSeries(targetTimes);
trade.target_step_prices = encodeNumericSeries(targetPrices);
state = closeAtEndOfDataIfNeeded(state,data,side,profile,spec);
end

function state = emptyExitState(timezone)
state = struct( ...
    "exitPrice",NaN, ...
    "exitTime",NaT("TimeZone",char(timezone)), ...
    "exitReason","", ...
    "exitBarIndex",NaN, ...
    "maxFav",0, ...
    "maxAdv",0);
end

function state = closeExitState( ...
    state,data,index,rawExit,reason,side,profile,spec)
state.exitReason = string(reason);
state.exitPrice = resolveExecutionPrice( ...
    rawExit,side,executionLeg(state.exitReason),profile,spec);
state.exitTime = data.datetime_local(index);
state.exitBarIndex = index;
end

function state = closeAtEndOfDataIfNeeded( ...
    state,data,side,profile,spec)
if strlength(state.exitReason)>0, return; end
state.exitReason = "END_OF_DATA";
state.exitPrice = resolveExecutionPrice( ...
    data.close(end),side,"EOD",profile,spec);
state.exitTime = data.datetime_local(end);
state.exitBarIndex = height(data);
end

function [maxFav,maxAdv] = updateExcursion( ...
    maxFav,maxAdv,side,entryPrice,barHigh,barLow)
if side==1
    favorable = barHigh-entryPrice;
    adverse = entryPrice-barLow;
else
    favorable = entryPrice-barLow;
    adverse = barHigh-entryPrice;
end
maxFav = max(maxFav,favorable);
maxAdv = max(maxAdv,adverse);
end

function time = effectiveTime(data,index,onNextBar)
if onNextBar && index<height(data)
    time = data.datetime_local(index+1);
else
    time = data.datetime_local(index);
end
end

function tf = stopTouched(side,barHigh,barLow,stopPrice)
if side==1
    tf = barLow<=stopPrice;
else
    tf = barHigh>=stopPrice;
end
end

function tf = favorableLevelTouched(side,barHigh,barLow,price)
if side==1
    tf = barHigh>=price;
else
    tf = barLow<=price;
end
end

function stop = improveStop(side,currentStop,candidateStop)
if side==1
    stop = max(currentStop,candidateStop);
else
    stop = min(currentStop,candidateStop);
end
end

function stop = confirmedSwingStop( ...
    data,confirmationIndex,entryIndex,side,p,tick)
stop = NaN;
candidate = confirmationIndex-p.swingRightBars;
firstWindow = candidate-p.swingLeftBars;
lastWindow = candidate+p.swingRightBars;
if firstWindow<entryIndex || lastWindow>height(data)
    return;
end

indices = firstWindow:lastWindow;
other = indices(indices~=candidate);
if side==1
    isSwing = all(data.low(candidate)<data.low(other));
    if isSwing
        stop = floor((data.low(candidate)- ...
            p.swingOffsetTicks*tick)/tick)*tick;
    end
else
    isSwing = all(data.high(candidate)>data.high(other));
    if isSwing
        stop = ceil((data.high(candidate)+ ...
            p.swingOffsetTicks*tick)/tick)*tick;
    end
end
end

function value = encodeDateTimeSeries(values)
if isempty(values)
    value = "";
else
    value = join(compose("%.0f",posixtime(values)),";");
end
end

function value = encodeNumericSeries(values)
if isempty(values)
    value = "";
else
    value = join(compose("%.10g",values),";");
end
end

function trade = makeSessionTrade(cfg,profile,w,equityBeforeUSD,reason)
trade = createEmptyTradeRecord(cfg,profile.name);
trade.entry_fraction = cfg.crt3h.entryFraction;
if isfield(cfg.crt3h,"rulesVersion")
    trade.rules_version = string(cfg.crt3h.rulesVersion);
end
trade.exit_management = upper(string(cfg.crt3h.exitManagement.mode));
trailing = cfg.crt3h.exitManagement.trailing;
if trade.exit_management=="FIXED_TARGET"
    trade.reward_risk_planned = cfg.crt3h.rewardRisk;
else
    trade.reward_risk_planned = trailing.activationR;
end
trade.trailing_enabled = trade.exit_management== ...
    "SWING_TRAILING_STEP_TARGET" && logical(trailing.enabled);
trade.trailing_activation_r = trailing.activationR;
trade.trailing_target_step_r = trailing.targetStepR;
trade.trailing_swing_left_bars = trailing.swingLeftBars;
trade.trailing_swing_right_bars = trailing.swingRightBars;
trade.trailing_swing_offset_ticks = trailing.swingOffsetTicks;
trade.session_date = w.session_date;
trade.equity_before_usd = equityBeforeUSD;
trade.equity_after_usd = equityBeforeUSD;
trade.session_name = w.session_name;
trade.reference_range = resolveReferenceName(w);
trade.crt_high = w.crt_high;
trade.crt_low = w.crt_low;
trade.crt_range_points = w.crt_range_points;
trade.ref_start = w.ref_start;
trade.ref_end = w.ref_end;
trade.entry_start = w.entry_start;
trade.man_end = w.man_end;
trade.ref_bars = w.ref_bars;
trade.man_bars = w.man_bars;
trade.data_complete = w.data_complete;
trade.sweep_time = NaT("TimeZone",char(cfg.marketTimezone));
trade.extreme_time = NaT("TimeZone",char(cfg.marketTimezone));
trade.sweep_side = "";
trade.manipulation_extreme = NaN;
trade.manipulation_points = NaN;
trade.entry_level_50 = NaN;
trade.entry_level = NaN;
trade.threshold_points = resolveThreshold(cfg,w.session_name);
if strlength(string(reason))>0
    trade = markSkipped(trade,reason);
end
end

function name = resolveReferenceName(w)
if isfield(w,"reference_name") && ...
        strlength(string(w.reference_name))>0
    name = upper(string(w.reference_name));
else
    name = upper(string(w.session_name));
end
end

function trade = markSkipped(trade,reason)
reason = string(reason);
trade.skip_reason = reason;

switch reason
    case "NO_SETUP"
        trade.setup_status = "NO_SETUP";
        trade.order_status = "NOT_CREATED";
    case "SETUP_NO_ENTRY"
        trade.setup_status = "SETUP_DETECTED";
        trade.order_status = "NOT_TRIGGERED";
    case "ENTRY_BEFORE_ALLOWED_TIME"
        trade.setup_status = "SETUP_DETECTED";
        trade.order_status = "NOT_CREATED";
    case {"RISK_TOO_LARGE","INVALID_EXECUTION_LEVELS"}
        trade.setup_status = "SETUP_DETECTED";
        trade.order_status = "REJECTED";
    case "INCOMPLETE_EXTENDED_DATA"
        trade.setup_status = "NOT_EVALUABLE";
        trade.order_status = "NOT_CREATED";
    case {"POSITION_OPEN","LONDON_TP_BLOCK","SESSION_DISABLED"}
        trade.setup_status = "BLOCKED";
        trade.order_status = "NOT_CREATED";
    otherwise
        trade.setup_status = "SKIPPED";
        trade.order_status = "NOT_CREATED";
end
end

function threshold = resolveThreshold(cfg,name)
if name=="LONDRES"
    threshold = cfg.crt3h.london.thresholdPoints;
else
    threshold = cfg.crt3h.newYork.thresholdPoints;
end
end

function [entry,stop] = entryAndStop( ...
    side,extreme,crtHigh,crtLow,tick,entryFraction)
if side==1
    rawEntry = extreme+entryFraction*(crtHigh-extreme);
    entry = ceil(rawEntry/tick)*tick;
else
    rawEntry = extreme-entryFraction*(extreme-crtLow);
    entry = floor(rawEntry/tick)*tick;
end
stop = round(extreme/tick)*tick;
end

function target = targetFromFill(side,entry,stop,rewardRisk,tick)
% El objetivo se expresa desde el fill real en múltiplos del riesgo inicial.
% La extensión concreta depende de entryFraction/rewardRisk y forma parte de
% la versión de reglas congelada por cada estrategia.
risk = abs(entry-stop);
target = targetFromRisk(side,entry,risk,rewardRisk,tick);
end

function target = targetFromRisk(side,entry,risk,rewardRisk,tick)
if side==1
    target = floor((entry+rewardRisk*risk)/tick)*tick;
else
    target = ceil((entry-rewardRisk*risk)/tick)*tick;
end
end

function result = trailingFromFill( ...
    side,entry,riskPoints,trailingConfig,tick)
enabled = logical(trailingConfig.enabled);
activationR = double(trailingConfig.activationR);
activationPrice = targetFromRisk( ...
    side,entry,riskPoints,activationR,tick);
result = struct( ...
    "enabled",enabled, ...
    "activationR",activationR, ...
    "activationPrice",activationPrice, ...
    "targetStepR",double(trailingConfig.targetStepR), ...
    "swingLeftBars",double(trailingConfig.swingLeftBars), ...
    "swingRightBars",double(trailingConfig.swingRightBars), ...
    "swingOffsetTicks",double(trailingConfig.swingOffsetTicks), ...
    "activateOnNextBar",logical( ...
        trailingConfig.activateOnNextBar), ...
    "valid",isfinite(activationPrice) && riskPoints>0);
end

function result = breakEvenFromFill( ...
    side,entry,riskPoints,breakEvenConfig,tick)
%BREAKVENFROMFILL Resuelve niveles de activación y protección al tick.

enabled = logical(breakEvenConfig.enabled);
triggerR = double(breakEvenConfig.triggerR);
offsetTicks = double(breakEvenConfig.offsetTicks);

if side==1
    triggerPrice = ceil( ...
        (entry+triggerR*riskPoints)/tick)*tick;
else
    triggerPrice = floor( ...
        (entry-triggerR*riskPoints)/tick)*tick;
end

stopPrice = entry+side*offsetTicks*tick;
valid = ~enabled || ...
    (side==1 && stopPrice<=triggerPrice) || ...
    (side==-1 && stopPrice>=triggerPrice);

result = struct( ...
    "enabled",enabled, ...
    "triggerR",triggerR, ...
    "triggerPrice",triggerPrice, ...
    "stopPrice",stopPrice, ...
    "activateOnNextBar",logical( ...
        breakEvenConfig.activateOnNextBar), ...
    "valid",valid);
end

function touched = breakEvenTriggerTouched( ...
    side,barHigh,barLow,triggerPrice)
if side==1
    touched = barHigh>=triggerPrice;
else
    touched = barLow<=triggerPrice;
end
end

function leg = executionLeg(exitReason)
% Las salidas dinámicas se ejecutan como stops y heredan su slippage.
if any(exitReason==["BREAKEVEN","TRAILING_STOP"])
    leg = "STOP";
else
    leg = exitReason;
end
end

function value = manipulationSize(side,extreme,w)
if side==1
    value = w.crt_low-extreme;
else
    value = extreme-w.crt_high;
end
end

function value = directionName(side)
if side==1, value = "LONG"; else, value = "SHORT"; end
end

function value = sweepSide(side)
if side==1, value = "LOW"; else, value = "HIGH"; end
end
