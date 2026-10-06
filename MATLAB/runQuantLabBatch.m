function batch = runQuantLabBatch(strategyName,instruments,options)
%RUNQUANTLABBATCH Ejecuta una estrategia sobre uno o varios instrumentos.

arguments
    strategyName (1,1) string
    instruments string
    options.RunBacktest (1,1) logical = true
    options.ExportResults (1,1) logical = true
    options.OpenDashboard (1,1) logical = true
end

strategyName = upper(strtrim(strategyName));
instruments = reshape(string(instruments),1,[]);
instruments = unique(upper(strtrim(instruments)),"stable");
instruments = instruments(strlength(instruments)>0);
if isempty(instruments)
    error("QuantLab:NoInstrumentsSelected", ...
        "Selecciona al menos un instrumento.");
end

workflows = cell(numel(instruments),1);
failures = cell(numel(instruments),1);
success = false(numel(instruments),1);
messages = strings(numel(instruments),1);

for i = 1:numel(instruments)
    fprintf('\n=== ACTIVO %d/%d: %s ===\n', ...
        i,numel(instruments),instruments(i));
    try
        workflows{i} = runQuantLabWorkflow( ...
            strategyName,instruments(i), ...
            RunBacktest=options.RunBacktest, ...
            ExportResults=options.ExportResults, ...
            OpenDashboard=options.OpenDashboard);
        success(i) = true;
        messages(i) = "OK";
    catch ME
        failures{i} = ME;
        messages(i) = string(ME.message);
        warning("QuantLab:InstrumentRunFailed", ...
            "%s / %s: %s",strategyName,instruments(i),ME.message);
    end
end

summary = table(instruments',success,messages, ...
    'VariableNames',{'instrument','success','message'});
batch = struct( ...
    "strategy",strategyName, ...
    "instruments",instruments, ...
    "workflows",{workflows}, ...
    "summary",summary, ...
    "successfulInstruments",instruments(success), ...
    "failedInstruments",instruments(~success));

if ~any(success)
    if numel(instruments)==1 && ~isempty(failures{1})
        rethrow(failures{1});
    end
    details = join(instruments + ": " + messages,newline);
    error("QuantLab:BatchFailed", ...
        "No se pudo ejecutar %s en ninguno de los instrumentos.%s%s", ...
        strategyName,newline,details);
end
end
