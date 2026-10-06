function commission = calculateRoundTripCommission( ...
    profile,quantity,entryPrice,exitPrice,instrumentSpec)
%CALCULATEROUNDTRIPCOMMISSION Modelos comunes de comisión.

spec = normalizeInstrumentSpec(instrumentSpec);

if isfield(profile,"commissionModel")
    model = profile.commissionModel;
    type = upper(string(model.type));
    amount = model.amount;

    switch type
        case "NONE"
            commission = 0;
        case "PER_QUANTITY_ROUND_TRIP"
            commission = amount*quantity;
        case "PER_ORDER"
            commission = 2*amount;
        case "FIXED_ROUND_TRIP"
            commission = amount;
        case "PERCENT_NOTIONAL"
            notional = (abs(entryPrice)+abs(exitPrice))/2 * ...
                quantity*spec.contractMultiplier;
            commission = amount*notional;
        otherwise
            error("QuantLab:CommissionModel", ...
                "Modelo de comisión desconocido: %s",type);
    end
elseif isfield(profile,"commissionRoundTripUSDPerContract")
    commission = ...
        profile.commissionRoundTripUSDPerContract*quantity;
else
    commission = 0;
end
end
