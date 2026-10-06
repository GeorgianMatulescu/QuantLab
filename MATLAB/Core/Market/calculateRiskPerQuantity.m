function risk = calculateRiskPerQuantity(riskPoints,instrumentSpec)
%CALCULATERISKPERQUANTITY Riesgo monetario por una unidad de cantidad.

arguments
    riskPoints double {mustBeNonnegative}
    instrumentSpec (1,1) struct
end

spec = normalizeInstrumentSpec(instrumentSpec);
risk = riskPoints*spec.contractMultiplier;
end
