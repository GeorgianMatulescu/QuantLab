function files = exportStrategyRun(output,cfg,data)
%EXPORTSTRATEGYRUN Exporta cualquier StrategyResult compatible.

arguments
    output (1,1) struct
    cfg (1,1) struct
    data table = table()
end

strategyName = string(output.strategy);
reportDir = getQuantLabReportDirectory(cfg,strategyName);
if ~isfolder(reportDir), mkdir(reportDir); end

fprintf('  [3.1/3] Guardando eventos, metadatos y resumen...\n');
drawnow;
auditEvents = selectAuditEvents(output.events);
writetable(auditEvents, ...
    fullfile(reportDir,strategyName + "_events.csv"));
writetable(struct2table(output.metadata), ...
    fullfile(reportDir,strategyName + "_run_metadata.csv"));

if isfield(output.results,"summaryTable")
    writetable(output.results.summaryTable, ...
        fullfile(reportDir,strategyName + "_scenario_summary.csv"));
end

% Los CSV de los 24 escenarios se generan bajo demanda desde los botones
% Exportar pestaña / Exportar todo del Dashboard. Escribirlos todos durante
% cada main duplicaba trabajo y era especialmente lento dentro de MATLAB
% Drive.
fprintf('  [3.2/3] Guardando resultados para el Dashboard...\n');
drawnow;

if ~isempty(data)
    auditFile = saveAuditWorkspace( ...
        data,output.daily,output.results,cfg,strategyName, ...
        auditEvents,output.metadata);
else
    auditFile = "";
end

fprintf('  [3.3/3] Workspace ligero listo.\n');
drawnow;

files = struct("reportDir",string(reportDir), ...
    "auditFile",string(auditFile));
end

function events = selectAuditEvents(events)
% NEW_BAR reproduce el histórico fila por fila y no añade información al
% workspace. El resumen de resultados mantiene sus conteos completos.
if isempty(events) || ...
        ~ismember("event_type",string(events.Properties.VariableNames))
    return;
end
events = events(string(events.event_type)~="NEW_BAR",:);
end
