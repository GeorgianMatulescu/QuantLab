function results = runCRT3HPlugin(data,context,events,cfg)
%RUNCRT3HPLUGIN Ejecuta perfiles, sesiones y gestiones de salida.

arguments
    data table
    context (1,1) struct
    events table
    cfg (1,1) struct
end

profiles = cfg.executionProfiles;
sessionScenarios = resolveSessionScenarios(cfg);
exitScenarios = resolveExitManagementScenarios(cfg);
scenarioCount = numel(profiles)*numel(sessionScenarios)* ...
    numel(exitScenarios);
rows = cell(scenarioCount,1);
rowIndex = 0;
results = struct();
runTimer = tic;

for i = 1:numel(profiles)
    sessionResults = struct();
    sessionOrder = strings(numel(sessionScenarios),1);
    sessionLabels = strings(numel(sessionScenarios),1);

    for j = 1:numel(sessionScenarios)
        sessionScenario = sessionScenarios(j);
        sessionCfg = applySessionScenario(cfg,sessionScenario);
        exitResults = struct();
        exitOrder = strings(numel(exitScenarios),1);
        exitLabels = strings(numel(exitScenarios),1);

        for k = 1:numel(exitScenarios)
            exitScenario = exitScenarios(k);
            rowIndex = rowIndex+1;
            fprintf('[%02d/%02d] %s | %s | %s\n', ...
                rowIndex,scenarioCount,string(profiles(i).name), ...
                string(sessionScenario.name),string(exitScenario.name));
            drawnow limitrate;
            scenarioCfg = applyExitManagementScenario( ...
                sessionCfg,exitScenario);
            [trades,summary] = runCRT3HScenario( ...
                data,context,scenarioCfg,profiles(i));

            summary.executionProfile = string(profiles(i).name);
            summary.sessionScenario = string(sessionScenario.name);
            summary.sessionScenarioLabel = ...
                string(sessionScenario.displayName);
            summary.exitManagementScenario = string(exitScenario.name);
            summary.exitManagementScenarioLabel = ...
                string(exitScenario.displayName);

            exitField = matlab.lang.makeValidName( ...
                upper(string(exitScenario.name)));
            exitResults.(exitField) = struct( ...
                "trades",trades,"summary",summary);
            exitOrder(k) = string(exitScenario.name);
            exitLabels(k) = string(exitScenario.displayName);

            rows{rowIndex} = summary;
        end

        defaultExit = resolveDefaultExitScenario(cfg,exitOrder);
        defaultExitField = matlab.lang.makeValidName(upper(defaultExit));
        baselineExit = exitResults.(defaultExitField);
        sessionField = matlab.lang.makeValidName( ...
            upper(string(sessionScenario.name)));
        sessionResults.(sessionField) = struct( ...
            "trades",baselineExit.trades, ...
            "summary",baselineExit.summary, ...
            "exitManagementScenarios",exitResults, ...
            "exitManagementScenarioOrder",exitOrder, ...
            "exitManagementScenarioLabels",exitLabels, ...
            "defaultExitManagementScenario",defaultExit);
        sessionOrder(j) = string(sessionScenario.name);
        sessionLabels(j) = string(sessionScenario.displayName);
    end

    defaultSession = resolveDefaultSessionScenario(cfg,sessionOrder);
    defaultSessionField = matlab.lang.makeValidName(upper(defaultSession));
    baseline = sessionResults.(defaultSessionField);
    field = matlab.lang.makeValidName(profiles(i).name);
    results.(field) = struct( ...
        "trades",baseline.trades, ...
        "summary",baseline.summary, ...
        "sessionScenarios",sessionResults, ...
        "sessionScenarioOrder",sessionOrder, ...
        "sessionScenarioLabels",sessionLabels, ...
        "defaultSessionScenario",defaultSession);
end

results.summaryTable = struct2table(vertcat(rows{:}));
results.event_summary = summarizeEvents(events);
fprintf('CRT3H: %d escenarios completados en %.1f s.\n', ...
    scenarioCount,toc(runTimer));
end

function scenarios = resolveSessionScenarios(cfg)
if isfield(cfg.crt3h,"sessionScenarios") && ...
        ~isempty(cfg.crt3h.sessionScenarios)
    scenarios = cfg.crt3h.sessionScenarios;
    return;
end

scenarios = struct( ...
    "name","CUSTOM", ...
    "displayName","Configuracion CRT", ...
    "enableLondon",logical(cfg.crt3h.enableLondon), ...
    "enableNewYork",logical(cfg.crt3h.enableNewYork), ...
    "blockNyAfterLondonTP",logical(cfg.crt3h.blockNyAfterLondonTP));
end

function scenarios = resolveExitManagementScenarios(cfg)
if isfield(cfg.crt3h,"exitManagementScenarios") && ...
        ~isempty(cfg.crt3h.exitManagementScenarios)
    scenarios = cfg.crt3h.exitManagementScenarios;
    return;
end

scenarios = struct( ...
    "name",upper(string(cfg.crt3h.exitManagement.mode)), ...
    "displayName","Gestion de salida actual", ...
    "mode",upper(string(cfg.crt3h.exitManagement.mode)));
end

function scenarioCfg = applySessionScenario(cfg,scenario)
scenarioCfg = cfg;
scenarioCfg.crt3h.enableLondon = logical(scenario.enableLondon);
scenarioCfg.crt3h.enableNewYork = logical(scenario.enableNewYork);
scenarioCfg.crt3h.blockNyAfterLondonTP = ...
    logical(scenario.blockNyAfterLondonTP);
end

function scenarioCfg = applyExitManagementScenario(cfg,scenario)
scenarioCfg = cfg;
scenarioCfg.crt3h.exitManagement.mode = upper(string(scenario.mode));
end

function name = resolveDefaultSessionScenario(cfg,scenarioOrder)
name = scenarioOrder(1);
if isfield(cfg.crt3h,"defaultSessionScenario")
    requested = upper(string(cfg.crt3h.defaultSessionScenario));
    index = find(upper(scenarioOrder)==requested,1,"first");
    if ~isempty(index), name = scenarioOrder(index); end
end
end

function name = resolveDefaultExitScenario(cfg,scenarioOrder)
name = scenarioOrder(1);
if isfield(cfg.crt3h,"defaultExitManagementScenario")
    requested = upper(string( ...
        cfg.crt3h.defaultExitManagementScenario));
    index = find(upper(scenarioOrder)==requested,1,"first");
    if ~isempty(index), name = scenarioOrder(index); end
end
end

function summary = summarizeEvents(events)
types = unique(string(events.event_type));
counts = zeros(numel(types),1);
for i = 1:numel(types)
    counts(i) = nnz(string(events.event_type)==types(i));
end
summary = table(types,counts, ...
    'VariableNames',{'event_type','count'});
end
