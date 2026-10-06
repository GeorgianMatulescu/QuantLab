function filePath = saveAuditWorkspace( ...
    data,daily,results,cfg,strategyName,events,metadata)
%SAVEAUDITWORKSPACE Guarda la última ejecución sin duplicar el mercado.
%
% El histórico permanece en el CSV configurado y se vuelve a cargar al
% abrir el Dashboard. Guardarlo otra vez dentro de un MAT -v7.3 convertía
% la fase 3 de main en una serialización muy lenta dentro de MATLAB Drive.

arguments
    data table
    daily table
    results (1,1) struct
    cfg (1,1) struct
    strategyName (1,1) string = "ORB"
    events table = table()
    metadata (1,1) struct = struct()
end

reportDir = getQuantLabReportDirectory(cfg,strategyName);
if ~isfolder(reportDir)
    mkdir(reportDir);
end

filePath = fullfile(reportDir, "latest_audit_workspace.mat");
dataReference = buildDataReference(data,cfg);
auditSchemaVersion = "2";

% Publicación atómica: si MATLAB se interrumpe durante save, se conserva el
% último workspace válido y solo queda un temporal prescindible.
temporaryFile = string(tempname(reportDir)) + ".mat";
temporaryCleanup = onCleanup(@() deleteIfPresent(temporaryFile));

save(temporaryFile, ...
    "daily","results","cfg","events","metadata", ...
    "dataReference","auditSchemaVersion","-v7");

[moved,message] = movefile(temporaryFile,filePath,"f");
if ~moved
    error("QuantLab:AuditWorkspacePublish", ...
        "No se pudo publicar el workspace de auditoría: %s",message);
end
clear temporaryCleanup;
end

function reference = buildDataReference(data,cfg)
sourceFile = string(cfg.dataFile);
relativePath = "";

if isfield(cfg,"quantLabRoot")
    root = string(cfg.quantLabRoot);
    prefix = root + string(filesep);
    if startsWith(sourceFile,prefix)
        relativePath = extractAfter(sourceFile,strlength(prefix));
    end
end

firstTimestamp = NaT;
lastTimestamp = NaT;
variables = string(data.Properties.VariableNames);
if ~isempty(data)
    if ismember("datetime_local",variables)
        firstTimestamp = data.datetime_local(1);
        lastTimestamp = data.datetime_local(end);
    elseif ismember("datetime",variables)
        firstTimestamp = data.datetime(1);
        lastTimestamp = data.datetime(end);
    end
end

reference = struct( ...
    "storage_mode","SOURCE_REFERENCE", ...
    "source_file",sourceFile, ...
    "relative_path",relativePath, ...
    "row_count",height(data), ...
    "first_timestamp",firstTimestamp, ...
    "last_timestamp",lastTimestamp, ...
    "created_at",datetime("now"));
end

function deleteIfPresent(filePath)
if isfile(filePath)
    delete(filePath);
end
end
