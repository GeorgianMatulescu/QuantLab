function trades = getScenarioTrades(results, profileName)
%GETSCENARIOTRADES Devuelve la tabla de operaciones de un escenario.
%
% Función genérica: funciona con cualquier estrategia cuyos resultados
% sigan la interfaz:
%   results.<PERFIL>.trades
%   results.<PERFIL>.summary

arguments
    results (1,1) struct
    profileName (1,1) string
end

fieldName = matlab.lang.makeValidName(upper(profileName));

if ~isfield(results, fieldName)
    available = string(fieldnames(results));
    available(available == "summaryTable") = [];
    error("QuantLab:UnknownProfile", ...
        "No existe el perfil %s. Perfiles disponibles: %s", ...
        profileName, strjoin(available, ", "));
end

scenario = results.(fieldName);

if ~isstruct(scenario) || ~isfield(scenario, "trades")
    error("QuantLab:InvalidScenarioInterface", ...
        "El escenario %s no contiene una tabla trades.", profileName);
end

trades = scenario.trades;
end
