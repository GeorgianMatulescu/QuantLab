function scenario = runEMACrossProfileOptimization( ...
    data,context,events,cfg,profileName)
%RUNEMACROSSPROFILEOPTIMIZATION Fast path de un único perfil.

profiles = cfg.executionProfiles;
names = string({profiles.name});
index = find(names==profileName,1,"first");
if isempty(index)
    error("QuantLab:EMAProfile", ...
        "Perfil desconocido: %s",profileName);
end

[trades,summary] = runEMACrossScenario( ...
    data,context,cfg,profiles(index));
scenario = struct("trades",trades,"summary",summary);
end
