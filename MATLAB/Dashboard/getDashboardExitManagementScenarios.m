function catalog = getDashboardExitManagementScenarios( ...
    results,profileName,sessionScenarioName)
%GETDASHBOARDEXITMANAGEMENTSCENARIOS Gestiones de salida disponibles.

profileField = matlab.lang.makeValidName(upper(profileName));
if ~isfield(results,profileField)
    error("QuantLab:DashboardUnknownProfile", ...
        "Perfil desconocido: %s",profileName);
end
profile = results.(profileField);

sessionField = matlab.lang.makeValidName(upper(sessionScenarioName));
if ~isfield(profile,"sessionScenarios") || ...
        ~isfield(profile.sessionScenarios,sessionField)
    names = "DEFAULT";
    labels = "Gestión actual";
    defaultName = names;
else
    sessionScenario = profile.sessionScenarios.(sessionField);
    if isfield(sessionScenario,"exitManagementScenarioOrder") && ...
            isfield(sessionScenario,"exitManagementScenarioLabels")
        names = reshape(string( ...
            sessionScenario.exitManagementScenarioOrder),[],1);
        labels = reshape(string( ...
            sessionScenario.exitManagementScenarioLabels),[],1);
    else
        names = "DEFAULT";
        labels = "Gestión actual";
    end
    defaultName = names(1);
    if isfield(sessionScenario,"defaultExitManagementScenario")
        candidate = string( ...
            sessionScenario.defaultExitManagementScenario);
        if any(names==candidate), defaultName = candidate; end
    end
end

catalog = table(names,labels, ...
    'VariableNames',{'name','label'});
catalog.Properties.UserData = struct("defaultName",defaultName);
end
