function scenario = runCRT3HProfileOptimization( ...
    data,context,events,cfg,profileName) %#ok<INUSD>
%RUNCRT3HPROFILEOPTIMIZATION Fast path de un único perfil.

profiles = cfg.executionProfiles;
names = string({profiles.name});
index = find(names==profileName,1,"first");
if isempty(index)
    error("QuantLab:CRT3HProfile", ...
        "Perfil desconocido: %s",profileName);
end

[trades,summary] = runCRT3HScenario( ...
    data,context,cfg,profiles(index));
scenario = struct("trades",trades,"summary",summary);
end
