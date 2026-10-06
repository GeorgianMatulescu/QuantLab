function validateInstrumentSpec(spec)
%VALIDATEINSTRUMENTSPEC Valida el contrato de instrumento v1.

required = [ ...
    "symbol","assetClass","quoteCurrency","accountCurrency", ...
    "tickSize","contractMultiplier","quantityStep", ...
    "minimumQuantity","maximumQuantity","marketTimezone", ...
    "sessionTemplate"];

missing = required(~isfield(spec,required));

if ~isempty(missing)
    error("QuantLab:InstrumentSpecMissing", ...
        "InstrumentSpec incompleto. Faltan: %s", ...
        strjoin(missing,", "));
end

if strlength(string(spec.symbol))==0
    error("QuantLab:InstrumentSymbol","Symbol no puede estar vacío.");
end

allowed = ["FUTURE","STOCK","FOREX","CRYPTO"];

if ~ismember(upper(string(spec.assetClass)),allowed)
    error("QuantLab:InstrumentAssetClass", ...
        "Asset class no soportada: %s",spec.assetClass);
end

positiveFields = ["tickSize","contractMultiplier","quantityStep"];

for field = positiveFields
    if ~isfinite(spec.(field)) || spec.(field)<=0
        error("QuantLab:InstrumentPositiveField", ...
            "%s debe ser positivo.",field);
    end
end

if spec.minimumQuantity<0 || ...
        spec.maximumQuantity<spec.minimumQuantity
    error("QuantLab:InstrumentQuantityBounds", ...
        "Límites de cantidad no válidos.");
end

if string(spec.accountCurrency)~=string(spec.quoteCurrency)
    error("QuantLab:CurrencyConversionRequired", ...
        ["La v0.25 requiere accountCurrency=quoteCurrency. " + ...
         "Añade un modelo FX antes de usar monedas distintas."]);
end
end
