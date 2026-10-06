function definition = getQuantLabInstrumentDefinition(symbol)
%GETQUANTLABINSTRUMENTDEFINITION Especificaciones congeladas de futuros USA.

% Los tres micros son la cesta oficial para la comparación multi-activo.
% Se incluyen los minis para permitir comprobaciones de sensibilidad sin
% mezclar silenciosamente su multiplicador con el del micro.

arguments
    symbol (1,1) string
end

symbol = upper(strtrim(symbol));
switch symbol
    case "MNQ"
        definition = makeDefinition(symbol,"CME",0.25,2.0,40);
    case "MES"
        definition = makeDefinition(symbol,"CME",0.25,5.0,40);
    case "MYM"
        definition = makeDefinition(symbol,"CBOT",1.0,0.5,40);
    case "NQ"
        definition = makeDefinition(symbol,"CME",0.25,20.0,40);
    case "ES"
        definition = makeDefinition(symbol,"CME",0.25,50.0,40);
    case "YM"
        definition = makeDefinition(symbol,"CBOT",1.0,5.0,40);
    otherwise
        error("QuantLab:UnknownInstrument", ...
            "Activo no soportado: %s. Usa MNQ, MES, MYM, NQ, ES o YM.", ...
            symbol);
end
end

function definition = makeDefinition( ...
    symbol,exchange,tickSize,contractMultiplier,maximumQuantity)
definition = struct( ...
    "symbol",string(symbol), ...
    "exchange",string(exchange), ...
    "tickSize",double(tickSize), ...
    "contractMultiplier",double(contractMultiplier), ...
    "maximumQuantity",double(maximumQuantity));
end
