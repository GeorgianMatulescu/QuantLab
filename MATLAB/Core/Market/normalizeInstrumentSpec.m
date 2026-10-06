function spec = normalizeInstrumentSpec(input)
%NORMALIZEINSTRUMENTSPEC Acepta cfg completo o instrumentSpec legado.

arguments
    input (1,1) struct
end

if isfield(input,"instrumentSpec")
    spec = input.instrumentSpec;
    cfg = input;
else
    spec = input;
    cfg = struct();
end

if ~isfield(spec,"symbol")
    if isfield(cfg,"instrument")
        spec.symbol = string(cfg.instrument);
    else
        spec.symbol = "UNKNOWN";
    end
end

if ~isfield(spec,"assetClass")
    spec.assetClass = "FUTURE";
end

if ~isfield(spec,"quoteCurrency")
    spec.quoteCurrency = "USD";
end

if ~isfield(spec,"accountCurrency")
    spec.accountCurrency = spec.quoteCurrency;
end

if ~isfield(spec,"tickSize")
    spec.tickSize = 0.01;
end

if ~isfield(spec,"contractMultiplier")
    if isfield(spec,"pointValueUSD")
        spec.contractMultiplier = spec.pointValueUSD;
    else
        spec.contractMultiplier = 1;
    end
end

if ~isfield(spec,"tickValue")
    if isfield(spec,"tickValueUSD")
        spec.tickValue = spec.tickValueUSD;
    else
        spec.tickValue = spec.tickSize*spec.contractMultiplier;
    end
end

if ~isfield(spec,"tickValueUSD")
    spec.tickValueUSD = spec.tickValue;
end

if ~isfield(spec,"pointValueUSD")
    spec.pointValueUSD = spec.contractMultiplier;
end

if ~isfield(spec,"quantityStep")
    spec.quantityStep = 1;
end

if ~isfield(spec,"minimumQuantity")
    if isfield(cfg,"risk") && isfield(cfg.risk,"minimumContracts")
        spec.minimumQuantity = cfg.risk.minimumContracts;
    else
        spec.minimumQuantity = spec.quantityStep;
    end
end

if ~isfield(spec,"maximumQuantity")
    if isfield(cfg,"risk") && isfield(cfg.risk,"maximumContracts")
        spec.maximumQuantity = cfg.risk.maximumContracts;
    else
        spec.maximumQuantity = Inf;
    end
end

if ~isfield(spec,"allowsFractionalQuantity")
    spec.allowsFractionalQuantity = spec.quantityStep<1;
end

if ~isfield(spec,"marketTimezone")
    if isfield(cfg,"marketTimezone")
        spec.marketTimezone = string(cfg.marketTimezone);
    else
        spec.marketTimezone = "UTC";
    end
end

if ~isfield(spec,"sessionTemplate")
    spec.sessionTemplate = "REGULAR";
end

spec.symbol = upper(string(spec.symbol));
spec.assetClass = upper(string(spec.assetClass));
spec.quoteCurrency = upper(string(spec.quoteCurrency));
spec.accountCurrency = upper(string(spec.accountCurrency));
spec.marketTimezone = string(spec.marketTimezone);
spec.sessionTemplate = upper(string(spec.sessionTemplate));

validateInstrumentSpec(spec);
end
