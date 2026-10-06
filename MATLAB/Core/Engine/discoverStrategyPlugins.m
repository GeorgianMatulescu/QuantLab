function registry = discoverStrategyPlugins()
%DISCOVERSTRATEGYPLUGINS Descubre plugins sin editar el Core.
%
% Convención:
%   Strategies/<Folder>/create<Folder>Strategy.m

engineRoot = fileparts(mfilename("fullpath"));
matlabRoot = fileparts(fileparts(engineRoot));
strategiesRoot = fullfile(matlabRoot,"Strategies");
folders = dir(strategiesRoot);
folders = folders([folders.isdir]);
folders = folders(~ismember({folders.name},{'.','..'}));

registry = struct( ...
    "name",{},"displayName",{},"version",{}, ...
    "assetClasses",{},"factory",{},"enabled",{}, ...
    "folder",{},"validationError",{});

for i = 1:numel(folders)
    folderName = string(folders(i).name);
    strategyFolder = fullfile(strategiesRoot,folderName);
    factoryName = "create" + folderName + "Strategy";
    factoryFile = fullfile(strategyFolder,factoryName + ".m");

    if ~isfile(factoryFile)
        candidates = dir(fullfile(strategyFolder,"create*Strategy.m"));
        if numel(candidates)~=1
            continue;
        end
        [~,candidateName] = fileparts(candidates(1).name);
        factoryName = string(candidateName);
        factoryFile = fullfile(strategyFolder,candidates(1).name);
    end

    addpath(strategyFolder);
    factory = str2func(char(factoryName));

    try
        plugin = factory();
        validateStrategyPlugin(plugin);

        enabled = true;
        if isfield(plugin,"enabled")
            enabled = logical(plugin.enabled);
        end

        registry(end+1) = struct( ... %#ok<AGROW>
            "name",string(plugin.name), ...
            "displayName",string(plugin.displayName), ...
            "version",string(plugin.version), ...
            "assetClasses",strjoin(string(plugin.assetClasses),","), ...
            "factory",factory, ...
            "enabled",enabled, ...
            "folder",string(strategyFolder), ...
            "validationError","");

    catch ME
        registry(end+1) = struct( ... %#ok<AGROW>
            "name",upper(folderName), ...
            "displayName",folderName, ...
            "version","INVALID", ...
            "assetClasses","", ...
            "factory",factory, ...
            "enabled",false, ...
            "folder",string(strategyFolder), ...
            "validationError",string(ME.message));
    end
end

if ~isempty(registry)
    [~,order] = sort(upper(string({registry.name})));
    registry = registry(order);
end
end
