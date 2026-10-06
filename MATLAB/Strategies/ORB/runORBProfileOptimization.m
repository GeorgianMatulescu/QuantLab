function scenario = runORBProfileOptimization( ...
    data,context,events,cfg,profileName)
%RUNORBPROFILEOPTIMIZATION Ejecuta solo el perfil solicitado.
%
% El optimizador no necesita calcular IDEAL y REALISTIC en cada
% combinación. Este adaptador reduce aproximadamente a la mitad el
% trabajo del plugin cuando se optimiza un único perfil.

arguments
    data table
    context (1,1) struct
    events table
    cfg (1,1) struct
    profileName (1,1) string
end

orbCompleted = filterEvents(events,"ORB_COMPLETED");

if height(orbCompleted)~=nnz(context.daily.orb_valid)
    error("QuantLab:ORBEventMismatch", ...
        "ORB_COMPLETED no coincide con las ORB válidas.");
end

profiles = cfg.executionProfiles;
profileNames = string({profiles.name});
profileIndex = find( ...
    profileNames==profileName,1,"first");

if isempty(profileIndex)
    error("QuantLab:ORBOptimizationProfile", ...
        "Perfil de ejecución desconocido: %s",profileName);
end

sessionData = cell(0,1);

if isfield(context,"session_data")
    sessionData = context.session_data;
end

[trades,summary] = runORBScenario( ...
    data,context.daily,cfg, ...
    profiles(profileIndex),sessionData);

scenario = struct( ...
    "trades",trades, ...
    "summary",summary);
end
