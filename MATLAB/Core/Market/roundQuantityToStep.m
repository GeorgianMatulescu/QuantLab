function quantity = roundQuantityToStep(rawQuantity,spec,roundingMode)
%ROUNDQUANTITYTOSTEP Normaliza contratos, acciones, unidades o cripto.
%
% El cociente se redondea primero a un número entero de pasos y después
% se normaliza la precisión decimal del resultado. Esto evita residuos
% binarios como:
%
%   1234 * 0.0001 = 0.12340000000000001
%
% que pueden provocar comparaciones y validaciones inconsistentes.

arguments
    rawQuantity double
    spec (1,1) struct
    roundingMode (1,1) string = "FLOOR"
end

spec = normalizeInstrumentSpec(spec);
step = spec.quantityStep;

switch upper(roundingMode)
    case "FLOOR"
        stepCount = floor(rawQuantity/step + 1e-12);

    case "CEIL"
        stepCount = ceil(rawQuantity/step - 1e-12);

    case "NEAREST"
        stepCount = round(rawQuantity/step);

    otherwise
        error("QuantLab:QuantityRounding", ...
            "Modo de redondeo desconocido: %s",roundingMode);
end

quantity = stepCount*step;

% Normaliza únicamente los decimales definidos por quantityStep.
decimalPlaces = localDecimalPlaces(step);
quantity = round(quantity,decimalPlaces);

quantity = min(quantity,spec.maximumQuantity);
quantity(abs(quantity)<step*1e-10) = 0;
end

function decimalPlaces = localDecimalPlaces(step)
%LOCALDECIMALPLACES Obtiene los decimales efectivos de quantityStep.

step = abs(step);
decimalPlaces = 0;

while decimalPlaces < 12
    scaledStep = step*10^decimalPlaces;
    tolerance = max(1,abs(scaledStep))*1e-12;

    if abs(scaledStep-round(scaledStep)) <= tolerance
        return;
    end

    decimalPlaces = decimalPlaces + 1;
end
end
