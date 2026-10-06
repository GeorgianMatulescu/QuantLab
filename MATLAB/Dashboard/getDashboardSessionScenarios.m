function catalog = getDashboardSessionScenarios(results,profileName)
%GETDASHBOARDSESSIONSCENARIOS Escenarios de Londres/NY de un perfil.

arguments
    results (1,1) struct
    profileName (1,1) string
end

fieldName = matlab.lang.makeValidName(upper(profileName));
if ~isfield(results,fieldName)
    error("QuantLab:DashboardUnknownProfile", ...
        "Perfil desconocido: %s",profileName);
end

profile = results.(fieldName);
if isfield(profile,"sessionScenarioOrder") && ...
        isfield(profile,"sessionScenarioLabels")
    names = reshape(string(profile.sessionScenarioOrder),[],1);
    labels = reshape(string(profile.sessionScenarioLabels),[],1);
else
    names = "DEFAULT";
    labels = "Configuracion actual";
end

defaultName = names(1);
if isfield(profile,"defaultSessionScenario")
    candidate = string(profile.defaultSessionScenario);
    if any(names==candidate)
        defaultName = candidate;
    end
end

catalog = table(names,labels, ...
    'VariableNames',{'name','label'});
catalog.Properties.UserData = struct("defaultName",defaultName);
end
