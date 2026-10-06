function pnl = calculateInstrumentPnL( ...
    entryPrice,exitPrice,side,quantity,instrumentSpec)
%CALCULATEINSTRUMENTPNL PnL genérico en account/quote currency.

arguments
    entryPrice double
    exitPrice double
    side double
    quantity double
    instrumentSpec (1,1) struct
end

spec = normalizeInstrumentSpec(instrumentSpec);

if any(~ismember(side,[-1 1]))
    error("QuantLab:TradeSide","side debe ser +1 o -1.");
end

pnl = side .* (exitPrice-entryPrice) .* ...
    quantity .* spec.contractMultiplier;
end
