function S = loadAuditWorkspace(matlabRoot,strategyName,instrument)
%LOADAUDITWORKSPACE Carga el último workspace de auditoría.

arguments
    matlabRoot (1,1) string
    strategyName (1,1) string = "ORB"
    instrument (1,1) string = ""
end

strategyName = upper(strtrim(strategyName));
instrument = upper(strtrim(instrument));
filePath = resolveAuditFile(matlabRoot,strategyName,instrument);

S = load(filePath);
if isfield(S,"cfg")
    storedInstrument = resolveStoredInstrument(S.cfg);
    if strlength(instrument)>0 && strlength(storedInstrument)>0 && ...
            storedInstrument~=instrument
        error("QuantLab:AuditInstrumentMismatch", ...
            "La última auditoría disponible es %s, no %s.", ...
            storedInstrument,instrument);
    end
    S.cfg.reportDirectory = string(fileparts(filePath));
end

% v2 guarda una referencia reproducible al CSV en vez de duplicar cientos
% de miles de velas dentro del MAT. Los workspaces v1, que sí contienen
% data, siguen abriéndose sin cambios.
if ~isfield(S,"data")
    if ~isfield(S,"cfg")
        error("QuantLab:AuditWorkspaceConfigMissing", ...
            "El workspace no contiene cfg y no puede recargar el mercado.");
    end

    S.cfg = rebaseConfiguredPaths( ...
        S.cfg,matlabRoot,S,strategyName,instrument);
    fprintf('[Dashboard 1/2] Cargando mercado desde el CSV original...\n');
    drawnow;
    [S.data,S.dataReport] = loadConfiguredMarketData(S.cfg);
    validateDataReference(S);
    fprintf('[Dashboard 2/2] Mercado cargado: %d velas.\n',height(S.data));
    drawnow;
end
end

function filePath = resolveAuditFile(matlabRoot,strategyName,instrument)
root = fullfile(matlabRoot,"Reports",strategyName);
legacy = fullfile(root,"latest_audit_workspace.mat");

if strlength(instrument)>0
    scoped = fullfile(root,instrument,"latest_audit_workspace.mat");
    if isfile(scoped)
        filePath = scoped;
        return;
    end
end

if isfile(legacy)
    filePath = legacy;
    return;
end

if strlength(instrument)==0
    candidates = dir(fullfile(root,"*","latest_audit_workspace.mat"));
    if ~isempty(candidates)
        [~,order] = sort([candidates.datenum],"descend");
        selected = candidates(order(1));
        filePath = fullfile(selected.folder,selected.name);
        return;
    end
end

if strlength(instrument)>0
    expected = fullfile(root,instrument,"latest_audit_workspace.mat");
else
    expected = legacy;
end
error("QuantLab:AuditWorkspaceNotFound", ...
    "No existe %s. Ejecuta la estrategia desde `quantlab` primero.",expected);
end

function symbol = resolveStoredInstrument(cfg)
symbol = "";
if isfield(cfg,"instrumentSpec") && ...
        isfield(cfg.instrumentSpec,"symbol")
    symbol = upper(string(cfg.instrumentSpec.symbol));
elseif isfield(cfg,"instrument")
    symbol = upper(string(cfg.instrument));
end
end

function cfg = rebaseConfiguredPaths( ...
    cfg,matlabRoot,S,strategyName,instrument)
cfg.matlabRoot = matlabRoot;
cfg.quantLabRoot = string(fileparts(matlabRoot));

if isfield(S,"dataReference") && ...
        isfield(S.dataReference,"relative_path") && ...
        strlength(string(S.dataReference.relative_path))>0
    cfg.dataFile = fullfile( ...
        cfg.quantLabRoot,string(S.dataReference.relative_path));
elseif ~isfield(cfg,"dataFile") || ~isfile(cfg.dataFile)
    storedInstrument = resolveStoredInstrument(cfg);
    if strlength(instrument)==0, instrument = storedInstrument; end
    if strlength(instrument)==0, instrument = "MNQ"; end
    currentCfg = loadQuantLabConfig( ...
        matlabRoot,instrument,strategyName);
    cfg.dataFile = currentCfg.dataFile;
end
end

function validateDataReference(S)
if ~isfield(S,"dataReference")
    return;
end

reference = S.dataReference;
if isfield(reference,"row_count") && ...
        height(S.data)~=double(reference.row_count)
    warning("QuantLab:AuditDatasetRowsChanged", ...
        ["El CSV contiene %d velas y la ejecución guardada usó %d. " + ...
        "Los resultados pertenecen al dataset anterior."], ...
        height(S.data),double(reference.row_count));
end
end
