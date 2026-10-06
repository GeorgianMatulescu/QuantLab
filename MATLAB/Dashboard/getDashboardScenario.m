function scenario = getDashboardScenario( ...
    results,profileName,sessionScenarioName,exitManagementScenarioName)
arguments
    results (1,1) struct
    profileName (1,1) string
    sessionScenarioName (1,1) string = ""
    exitManagementScenarioName (1,1) string = ""
end

fieldName = matlab.lang.makeValidName(upper(string(profileName)));
if ~isfield(results, fieldName)
    error("QuantLab:DashboardUnknownProfile", ...
        "Perfil desconocido: %s", string(profileName));
end
scenario = results.(fieldName);

if strlength(sessionScenarioName)>0
    if ~isfield(scenario,"sessionScenarios") || ...
            ~isstruct(scenario.sessionScenarios)
        if upper(sessionScenarioName)=="DEFAULT"
            sessionScenarioName = "";
        else
            error("QuantLab:DashboardSessionScenariosMissing", ...
                "El perfil %s no contiene escenarios de sesion.",profileName);
        end
    end
    if strlength(sessionScenarioName)>0
        scenarioField = matlab.lang.makeValidName( ...
            upper(string(sessionScenarioName)));
        if ~isfield(scenario.sessionScenarios,scenarioField)
            error("QuantLab:DashboardUnknownSessionScenario", ...
                "Escenario de sesion desconocido: %s",sessionScenarioName);
        end
        scenario = scenario.sessionScenarios.(scenarioField);
    end
end

if strlength(exitManagementScenarioName)>0
    if ~isfield(scenario,"exitManagementScenarios") || ...
            ~isstruct(scenario.exitManagementScenarios)
        if upper(exitManagementScenarioName)=="DEFAULT"
            exitManagementScenarioName = "";
        else
            error("QuantLab:DashboardExitScenariosMissing", ...
                "El escenario no contiene gestiones de salida.");
        end
    end
    if strlength(exitManagementScenarioName)>0
        exitField = matlab.lang.makeValidName( ...
            upper(exitManagementScenarioName));
        if ~isfield(scenario.exitManagementScenarios,exitField)
            error("QuantLab:DashboardUnknownExitScenario", ...
                "Gestión de salida desconocida: %s", ...
                exitManagementScenarioName);
        end
        scenario = scenario.exitManagementScenarios.(exitField);
    end
end

if ~isfield(scenario,"trades") || ~isfield(scenario,"summary")
    error("QuantLab:DashboardInvalidScenario", ...
        "El perfil no cumple la interfaz del dashboard.");
end
end
