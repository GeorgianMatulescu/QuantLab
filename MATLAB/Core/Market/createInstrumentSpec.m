function spec = createInstrumentSpec(symbol,assetClass,options)
%CREATEINSTRUMENTSPEC Construye el contrato común de un instrumento.
%
% El PnL en moneda cotizada se calcula como:
%   priceMove * quantity * contractMultiplier
%
% Ejemplos de contractMultiplier:
%   MNQ future: 2 USD por punto y contrato
%   Stock:       1 USD por punto y acción
%   EURUSD:      1 USD por punto y unidad cuando USD es quote currency
%   BTCUSD:      1 USD por punto y BTC

arguments
    symbol (1,1) string
    assetClass (1,1) string
    options.quoteCurrency (1,1) string = "USD"
    options.accountCurrency (1,1) string = ""
    options.tickSize (1,1) double {mustBePositive} = 0.01
    options.contractMultiplier (1,1) double {mustBePositive} = 1
    options.quantityStep (1,1) double {mustBePositive} = 1
    options.minimumQuantity (1,1) double {mustBeNonnegative} = 0
    options.maximumQuantity (1,1) double {mustBePositive} = Inf
    options.marketTimezone (1,1) string = "UTC"
    options.sessionTemplate (1,1) string = "REGULAR"
end

assetClass = upper(strtrim(assetClass));
allowed = ["FUTURE","STOCK","FOREX","CRYPTO"];

accountCurrency = options.accountCurrency;
if strlength(accountCurrency)==0
    accountCurrency = options.quoteCurrency;
end

minimumQuantity = options.minimumQuantity;
if minimumQuantity==0
    minimumQuantity = options.quantityStep;
end

if ~ismember(assetClass,allowed)
    error("QuantLab:InstrumentAssetClass", ...
        "Asset class no soportada: %s",assetClass);
end

allowsFractional = options.quantityStep<1;
tickValue = options.tickSize*options.contractMultiplier;

spec = struct( ...
    "symbol",upper(strtrim(symbol)), ...
    "assetClass",assetClass, ...
    "quoteCurrency",upper(options.quoteCurrency), ...
    "accountCurrency",upper(accountCurrency), ...
    "tickSize",options.tickSize, ...
    "tickValue",tickValue, ...
    "tickValueUSD",tickValue, ...
    "contractMultiplier",options.contractMultiplier, ...
    "pointValueUSD",options.contractMultiplier, ...
    "quantityStep",options.quantityStep, ...
    "minimumQuantity",minimumQuantity, ...
    "maximumQuantity",options.maximumQuantity, ...
    "allowsFractionalQuantity",allowsFractional, ...
    "marketTimezone",options.marketTimezone, ...
    "sessionTemplate",upper(options.sessionTemplate));

validateInstrumentSpec(spec);
end
