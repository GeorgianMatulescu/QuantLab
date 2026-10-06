clear; clc;

matlabRoot = string(fileparts(mfilename("fullpath")));
addpath(genpath(matlabRoot));

cfg = loadQuantLabConfig(matlabRoot);
[data,report] = loadConfiguredMarketData(cfg);

fprintf("\n=== AUDITORIA IBKR ===\n");
fprintf("Archivo: %s\n",cfg.dataFile);
fprintf("Filas cargadas: %d\n",height(data));
fprintf("Desde: %s\n",string(min(data.datetime_local)));
fprintf("Hasta: %s\n",string(max(data.datetime_local)));
fprintf("Duplicados eliminados: %d\n",report.duplicatesRemoved);
fprintf("Saltos temporales detectados: %d\n",report.missingMinuteIntervals);

tick = cfg.instrumentSpec.tickSize;
prices = [data.open data.high data.low data.close];
scaled = prices./tick;
offTick = any(abs(scaled-round(scaled))>1e-6,2);
fprintf("Velas con precios fuera del tick: %d\n",sum(offTick));

metadataPath = replace(cfg.dataFile,".csv",".metadata.json");
if isfile(metadataPath)
    metadata = jsondecode(fileread(metadataPath));
    if isfield(metadata,"rows")
        fprintf("Filas indicadas por metadata: %d\n",metadata.rows);
        fprintf("Diferencia metadata/CSV: %d\n",metadata.rows-height(data));
    end
else
    fprintf("AVISO: no existe metadata.json\n");
end

[~,context] = buildCRT3HContext(data,cfg);
windows = context.windows(:);
session_date = vertcat(windows.session_date);
session_name = string({windows.session_name})';
ref_bars = [windows.ref_bars]';
expected_ref_bars = [windows.expected_ref_bars]';
man_bars = [windows.man_bars]';
expected_man_bars = [windows.expected_man_bars]';
data_complete = [windows.data_complete]';

audit = table(session_date,session_name,ref_bars,expected_ref_bars, ...
    man_bars,expected_man_bars,data_complete);

fprintf("\nVentanas CRT analizadas: %d\n",height(audit));
fprintf("Ventanas completas: %d\n",sum(audit.data_complete));
fprintf("Ventanas incompletas: %d\n",sum(~audit.data_complete));
fprintf("Cobertura completa: %.2f %%\n",100*mean(audit.data_complete));

targetDate = datetime(2026,9,17,"TimeZone","Europe/Madrid");
fprintf("\n=== 17/09/2026 ===\n");
disp(audit(audit.session_date==targetDate,:));

outputFile = fullfile(matlabRoot,"ibkr_session_audit.csv");
writetable(audit,outputFile);
fprintf("Informe guardado en:\n%s\n",outputFile);
