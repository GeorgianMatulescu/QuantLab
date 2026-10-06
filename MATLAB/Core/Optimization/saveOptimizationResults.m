function files = saveOptimizationResults( ...
    results,request,runState,cfg,strategyName,profileName)
%SAVEOPTIMIZATIONRESULTS Guarda el último barrido y una copia fechada.

arguments
    results table
    request table
    runState (1,1) struct
    cfg (1,1) struct
    strategyName (1,1) string
    profileName (1,1) string
end

outputDir = fullfile( ...
    getQuantLabReportDirectory(cfg,strategyName),"Optimization");

if ~isfolder(outputDir)
    mkdir(outputDir);
end

stamp = string(datetime("now","Format","yyyyMMdd_HHmmss"));
baseName = "parameter_sweep_" + profileName + "_" + stamp;

matFile = fullfile(outputDir,baseName + ".mat");
csvFile = fullfile(outputDir,baseName + ".csv");
latestFile = fullfile(outputDir,"latest_parameter_sweep.mat");

save(matFile,"results","request","runState","-v7.3");
save(latestFile,"results","request","runState","-v7.3");

exportTable = results;

if ~isempty(exportTable) && ...
        ismember("parameter_set", ...
            string(exportTable.Properties.VariableNames))
    exportTable.parameter_set = [];
end

writetable(exportTable,csvFile);

files = struct( ...
    "mat_file",string(matFile), ...
    "csv_file",string(csvFile), ...
    "latest_file",string(latestFile));
end
