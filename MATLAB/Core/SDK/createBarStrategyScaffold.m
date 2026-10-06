function targetFolder = createBarStrategyScaffold( ...
    strategyId,displayName,targetStrategiesRoot)
%CREATEBARSTRATEGYSCAFFOLD Copia la plantilla oficial de estrategia.
%
% Ejemplo:
%   createBarStrategyScaffold("MyMomentum","My Momentum")
%
% Después de ejecutar rehash, el plugin será descubierto sin modificar
% getStrategyRegistry ni ningún archivo del Core.

arguments
    strategyId (1,1) string
    displayName (1,1) string = strategyId
    targetStrategiesRoot (1,1) string = ""
end

if isempty(regexp(strategyId,'^[A-Za-z][A-Za-z0-9]*$','once'))
    error("QuantLab:ScaffoldIdentifier", ...
        "strategyId debe ser un identificador MATLAB simple.");
end

sdkRoot = fileparts(mfilename("fullpath"));
matlabRoot = fileparts(fileparts(sdkRoot));
templateRoot = fullfile( ...
    matlabRoot,"Strategies","TemplateBarStrategy");

if strlength(targetStrategiesRoot)==0
    targetStrategiesRoot = fullfile(matlabRoot,"Strategies");
end

targetFolder = fullfile(targetStrategiesRoot,strategyId);

if isfolder(targetFolder)
    error("QuantLab:ScaffoldExists", ...
        "La carpeta ya existe: %s",targetFolder);
end

copyfile(templateRoot,targetFolder);
files = dir(fullfile(targetFolder,"*.m"));

for i = 1:numel(files)
    oldPath = fullfile(targetFolder,files(i).name);
    text = string(fileread(oldPath));
    text = replace(text,"TemplateBar",strategyId);
    text = replace(text,"TEMPLATE_BAR",upper(strategyId));
    text = replace(text,"Template Bar Strategy",displayName);
    text = replace(text,'plugin.enabled = false;', ...
        'plugin.enabled = true;');

    newName = replace(string(files(i).name), ...
        "TemplateBar",strategyId);
    newPath = fullfile(targetFolder,newName);

    fileId = fopen(newPath,"w");
    cleaner = onCleanup(@() fclose(fileId));
    fwrite(fileId,char(text),"char");
    clear cleaner;

    if string(oldPath)~=string(newPath)
        delete(oldPath);
    end
end

fprintf("Strategy scaffold created:\n%s\n",targetFolder);
fprintf("Run: rehash; listStrategies();\n");
end
