function markerColor = resolveResearchExecutionMarkerColor( ...
    markerRole,exitReason)
%RESOLVERESEARCHEXECUTIONMARKERCOLOR Color semántico de flechas Research.
%
% La orientación de la flecha representa BUY/SELL. El color representa:
% - ENTRY: azul.
% - TARGET: verde.
% - STOP: rojo.
% - BREAKEVEN: gris.
% - TRAILING_STOP: morado.
% - EOD: naranja.

markerRole = upper(string(markerRole));
exitReason = upper(string(exitReason));

switch markerRole
    case "ENTRY"
        markerColor = [0.00 0.4470 0.7410];

    case "EXIT"
        switch exitReason
            case "TARGET"
                markerColor = [0.10 0.60 0.20];
            case "STOP"
                markerColor = [0.85 0.10 0.10];
            case "BREAKEVEN"
                markerColor = [0.40 0.40 0.40];
            case "TRAILING_STOP"
                markerColor = [0.4940 0.1840 0.5560];
            case "EOD"
                markerColor = [0.95 0.45 0.05];
            otherwise
                markerColor = [0.25 0.25 0.25];
        end

    otherwise
        markerColor = [0.25 0.25 0.25];
end
end
