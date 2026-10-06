function price = resolveExecutionPrice( ...
    rawPrice,side,leg,profile,instrumentSpec)
%RESOLVEEXECUTIONPRICE Aplica slippage/spread adverso de forma común.

arguments
    rawPrice (1,1) double
    side (1,1) double
    leg (1,1) string
    profile (1,1) struct
    instrumentSpec (1,1) struct
end

spec = normalizeInstrumentSpec(instrumentSpec);
leg = upper(leg);
slippage = getSlippage(profile,leg,spec);
spread = getSpread(profile,spec);

% ENTRY: un largo paga más y un corto vende más bajo.
% EXIT:  un largo vende más bajo y un corto recompra más alto.
if leg=="ENTRY"
    adverseDirection = side;
else
    adverseDirection = -side;
end

price = rawPrice + adverseDirection*(slippage+spread/2);
price = round(price/spec.tickSize)*spec.tickSize;
end

function value = getSlippage(profile,leg,spec)
value = 0;

if isfield(profile,"slippageModel")
    model = profile.slippageModel;
    type = upper(string(model.type));
    field = lower(leg);
    if isfield(model,field)
        amount = model.(field);
    elseif isfield(model,"entry")
        amount = model.entry;
    else
        amount = 0;
    end

    if type=="FIXED_TICKS"
        value = amount*spec.tickSize;
    elseif type=="FIXED_PRICE"
        value = amount;
    elseif type~="NONE"
        error("QuantLab:SlippageModel", ...
            "Modelo de slippage desconocido: %s",type);
    end
    return;
end

switch leg
    case "ENTRY"
        if isfield(profile,"entrySlippagePoints")
            value = profile.entrySlippagePoints;
        end
    case "STOP"
        if isfield(profile,"stopSlippagePoints")
            value = profile.stopSlippagePoints;
        end
    case "TARGET"
        if isfield(profile,"targetSlippagePoints")
            value = profile.targetSlippagePoints;
        end
    otherwise
        if isfield(profile,"entrySlippagePoints")
            value = profile.entrySlippagePoints;
        end
end
end

function value = getSpread(profile,spec)
value = 0;
if ~isfield(profile,"spreadModel"), return; end
model = profile.spreadModel;
type = upper(string(model.type));

switch type
    case "NONE"
        value = 0;
    case "FIXED_PRICE"
        value = model.amount;
    case "FIXED_TICKS"
        value = model.amount*spec.tickSize;
    otherwise
        error("QuantLab:SpreadModel", ...
            "Modelo de spread desconocido: %s",type);
end
end
