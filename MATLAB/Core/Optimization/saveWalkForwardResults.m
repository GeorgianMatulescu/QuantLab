function files = saveWalkForwardResults( ...
    walkForwardResult,request,cfg,strategyName,profileName)
%SAVEWALKFORWARDRESULTS Persiste resultados completos y tablas de lectura.

arguments
    walkForwardResult (1,1) struct
    request table
    cfg (1,1) struct
    strategyName (1,1) string
    profileName (1,1) string
end

outputDir = fullfile( ...
    getQuantLabReportDirectory(cfg,strategyName), ...
    "Optimization","WalkForward");

if ~isfolder(outputDir)
    mkdir(outputDir);
end

stamp = string(datetime("now","Format","yyyyMMdd_HHmmss"));
baseName = "walk_forward_" + profileName + "_" + stamp;

matFile = fullfile(outputDir,baseName + ".mat");
windowCsv = fullfile(outputDir,baseName + "_windows.csv");
aggregateCsv = fullfile(outputDir,baseName + "_aggregate.csv");
latestFile = fullfile(outputDir,"latest_walk_forward.mat");

save(matFile,"walkForwardResult","request","-v7.3");
save(latestFile,"walkForwardResult","request","-v7.3");

windowResults = walkForwardResult.window_results;
aggregateResults = walkForwardResult.aggregate_results;

if ~isempty(windowResults)
    writetable(windowResults,windowCsv);
end

if ~isempty(aggregateResults)
    exportAggregate = aggregateResults;

    if ismember("parameter_set", ...
            string(exportAggregate.Properties.VariableNames))
        exportAggregate.parameter_set = [];
    end

    writetable(exportAggregate,aggregateCsv);
end

files = struct( ...
    "mat_file",string(matFile), ...
    "window_csv",string(windowCsv), ...
    "aggregate_csv",string(aggregateCsv), ...
    "latest_file",string(latestFile));
end
