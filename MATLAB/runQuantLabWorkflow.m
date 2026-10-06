function workflow = runQuantLabWorkflow(strategyName,instrument,options)
%RUNQUANTLABWORKFLOW Flujo común para cualquier plugin de estrategia.
%
% Ejemplos:
%   runQuantLabWorkflow("CRT_3H_MADRID","MNQ")
%   runQuantLabWorkflow("SESSION_RANGE_MADRID","MNQ", ...
%       OpenDashboard=true)
%   runQuantLabWorkflow("SESSION_RANGE_MADRID","MNQ", ...
%       RunBacktest=false,OpenDashboard=true)

arguments
    strategyName (1,1) string
    instrument (1,1) string = "MNQ"
    options.RunBacktest (1,1) logical = true
    options.ExportResults (1,1) logical = true
    options.OpenDashboard (1,1) logical = true
end

matlabRoot = string(fileparts(mfilename('fullpath')));
addpath(genpath(matlabRoot));
strategyName = upper(strtrim(strategyName));
instrument = upper(strtrim(instrument));

% Falla pronto si el nombre no corresponde a un plugin habilitado.
plugin = resolveStrategyPlugin(strategyName);
files = struct("reportDir","","auditFile","");
output = struct();

if options.RunBacktest
    cfg = loadQuantLabConfig(matlabRoot,instrument,strategyName);
    cfg.reportDirectory = fullfile( ...
        matlabRoot,"Reports",strategyName,instrument);
    fprintf('\n=== QUANTLAB WORKFLOW v0.25.37 ===\n');
    fprintf('Strategy:   %s v%s\n',plugin.name,plugin.version);
    fprintf('Instrument: %s (%s)\n', ...
        cfg.instrumentSpec.symbol,cfg.instrumentSpec.assetClass);
    fprintf('Data:       %s\n\n',cfg.dataFile);

    stageTimer = tic;
    fprintf('[1/3] Cargando y validando mercado...\n');
    drawnow;
    [data,dataReport] = loadConfiguredMarketData(cfg);
    fprintf('Valid rows: %d | Duplicates: %d | Gaps: %d\n', ...
        height(data),dataReport.duplicatesRemoved, ...
        dataReport.missingMinuteIntervals);
    fprintf('Carga completada en %.1f s.\n\n',toc(stageTimer));

    stageTimer = tic;
    fprintf('[2/3] Ejecutando %s...\n',strategyName);
    drawnow;
    output = runStrategy(strategyName,data,cfg);
    fprintf('Backtest completado en %.1f s.\n\n',toc(stageTimer));
    if isfield(output.results,"summaryTable")
        disp(output.results.summaryTable);
    end

    if options.ExportResults
        stageTimer = tic;
        fprintf('[3/3] Guardando informes y auditoría...\n');
        drawnow;
        files = exportStrategyRun(output,cfg,data);
        fprintf('Guardado completado en %.1f s.\n\n',toc(stageTimer));
    else
        fprintf('[3/3] Exportación omitida.\n\n');
    end

    strategyRun = buildStrategyResult( ...
        strategyName,output.results,cfg,data,output.events);
    strategyRun.daily = output.daily;
    strategyRun.metadata = output.metadata;
else
    fprintf('\n=== QUANTLAB: ÚLTIMO RESULTADO ===\n');
    fprintf('Strategy: %s\n',strategyName);
    S = loadAuditWorkspace(matlabRoot,strategyName,instrument);
    cfg = S.cfg;
    data = S.data;
    events = table();
    if isfield(S,"events"), events = S.events; end
    strategyRun = buildStrategyResult( ...
        strategyName,S.results,cfg,data,events);
    if isfield(S,"daily"), strategyRun.daily = S.daily; end
    if isfield(S,"metadata"), strategyRun.metadata = S.metadata; end
end

validateStrategyResult(strategyRun);
dashboard = [];
if options.OpenDashboard
    dashboard = launchQuantLabDashboard(strategyRun,cfg);
end

workflow = struct( ...
    "strategy",strategyName, ...
    "instrument",string(cfg.instrumentSpec.symbol), ...
    "config",cfg, ...
    "strategyRun",strategyRun, ...
    "output",output, ...
    "files",files, ...
    "dashboard",dashboard);
end
