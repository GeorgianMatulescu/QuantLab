function report = exportQuantLabDashboardPackage(strategyRun,cfg,options)
%EXPORTQUANTLABDASHBOARDPACKAGE Exportacion auditable del Research Dashboard.
%
% Dos modos:
%   ALL        - vista activa, 24 escenarios, research y optimizacion.
%   ACTIVE_TAB - solo los datos relevantes de la pestana visible.
%
% Los datos historicos de mercado no se duplican. El manifiesto conserva
% ruta, tamano, periodo y huella reproducible del dataset original.

arguments
    strategyRun (1,1) struct
    cfg (1,1) struct
    options (1,1) struct = struct()
end

options = applyDefaults(options);
mode = upper(string(options.Mode));
if ~any(mode==["ALL","ACTIVE_TAB"])
    error("QuantLab:InvalidExportMode", ...
        "Modo de exportacion desconocido: %s",mode);
end

strategyName = upper(string(strategyRun.strategy));
stamp = string(datetime("now","Format","yyyyMMdd_HHmmss_SSS"));
folderName = stamp + "_" + lower(mode);
exportDir = fullfile( ...
    cfg.quantLabRoot,"exports",strategyName,folderName);
if ~isfolder(exportDir), mkdir(exportDir); end

artifacts = emptyArtifactStruct();

% 00_manifest siempre permite reconstruir que se exporto y con que reglas.
manifestContext = buildManifestContext( ...
    strategyRun,cfg,options,mode,stamp);
[artifacts,~] = addTableArtifact( ...
    artifacts,exportDir,"00_manifest/export_context.csv", ...
    manifestContext,"MANIFEST", ...
    "Version, selectores y contexto de la exportacion.");

configuration = flattenForExport(cfg,"cfg");
[artifacts,~] = addTableArtifact( ...
    artifacts,exportDir,"00_manifest/configuration.csv", ...
    configuration,"MANIFEST", ...
    "Configuracion completa aplanada, incluida la gestion de riesgo.");

datasetInventory = buildDatasetInventory(strategyRun,cfg);
[artifacts,~] = addTableArtifact( ...
    artifacts,exportDir,"00_manifest/dataset_inventory.csv", ...
    datasetInventory,"MANIFEST", ...
    "Referencia al historico original; no se duplica dentro del export.");

if mode=="ALL"
    artifacts = exportActiveView( ...
        artifacts,exportDir,strategyRun,cfg,options,true);
    artifacts = exportAllScenarios( ...
        artifacts,exportDir,strategyRun.results,cfg);
    artifacts = exportResearchInputs( ...
        artifacts,exportDir,strategyRun);
    artifacts = exportOptimizationState( ...
        artifacts,exportDir,options);
    artifacts = exportLogs(artifacts,exportDir,options.LogLines);
else
    artifacts = exportSelectedTab( ...
        artifacts,exportDir,strategyRun,cfg,options);
end

% La captura conserva exactamente la vista que estaba viendo el usuario.
if ~isempty(options.Figure)
    figureRelativePath = "05_figures/dashboard_view.png";
    figureFile = fullfile(exportDir,figureRelativePath);
    if ~isfolder(fileparts(figureFile)), mkdir(fileparts(figureFile)); end
    try
        if isvalid(options.Figure)
            exportapp(options.Figure,figureFile);
            artifacts(end+1) = makeArtifact( ...
                figureRelativePath,"FIGURE",1,1,"OK", ...
                "Captura de la vista visible al exportar.",""); %#ok<AGROW>
        end
    catch ME
        artifacts(end+1) = makeArtifact( ...
            figureRelativePath,"FIGURE",0,0,"ERROR", ...
            "No se pudo guardar la captura.",string(ME.message)); %#ok<AGROW>
    end
end

readmeRelativePath = "README_EXPORT.txt";
readmeFile = fullfile(exportDir,readmeRelativePath);
writeExportReadme(readmeFile,strategyName,mode,options);
artifacts(end+1) = makeArtifact( ...
    readmeRelativePath,"MANIFEST",1,1,"OK", ...
    "Guia de estructura y uso del paquete.",""); %#ok<AGROW>

artifactTable = struct2table(artifacts);
manifestFile = fullfile(exportDir,"00_manifest","artifacts.csv");
if ~isfolder(fileparts(manifestFile)), mkdir(fileparts(manifestFile)); end
writetable(artifactTable,manifestFile);

report = struct( ...
    "exportDirectory",string(exportDir), ...
    "manifestFile",string(manifestFile), ...
    "mode",mode, ...
    "artifactCount",height(artifactTable), ...
    "errorCount",nnz(artifactTable.status=="ERROR"));
end


function options = applyDefaults(options)
defaults = struct( ...
    "Mode","ALL", ...
    "ActiveTab","Overview", ...
    "Profile","", ...
    "SessionScenario","", ...
    "ExitManagementScenario","", ...
    "RollingWindow",20, ...
    "DistributionFilter","ALL", ...
    "DistributionDetail","ORB Range vs R", ...
    "SegmentFeature","", ...
    "SegmentGrouping","Auto", ...
    "SegmentMetric","Expectancy (R)", ...
    "SegmentMinimumSample",15, ...
    "SegmentTrainingPct",70, ...
    "SelectedRecord",table(), ...
    "ResearchDetails",table(), ...
    "ResearchSessionData",table(), ...
    "ResearchContext",table(), ...
    "OptimizationResults",table(), ...
    "WalkForwardResult",struct(), ...
    "LogLines",strings(0,1), ...
    "Figure",[]);

names = string(fieldnames(defaults));
for i = 1:numel(names)
    name = names(i);
    if ~isfield(options,name)
        options.(name) = defaults.(name);
    end
end
end


function artifacts = exportSelectedTab( ...
        artifacts,exportDir,strategyRun,cfg,options)
tabName = upper(string(options.ActiveTab));

if contains(tabName,"SESSION COMPARISON")
    artifacts = exportSessionComparison( ...
        artifacts,exportDir,strategyRun.results,options);
elseif contains(tabName,"ORDERS")
    artifacts = exportActiveOrders( ...
        artifacts,exportDir,strategyRun.results,options);
elseif contains(tabName,"TRADES")
    artifacts = exportActiveTrades( ...
        artifacts,exportDir,strategyRun.results,options,cfg);
elseif contains(tabName,"RESEARCH")
    artifacts = exportSelectedResearch( ...
        artifacts,exportDir,options);
elseif contains(tabName,"CALENDAR") || contains(tabName,"ROLLING")
    artifacts = exportActiveCalendarRolling( ...
        artifacts,exportDir,strategyRun.results,options);
elseif contains(tabName,"DISTRIBUTION")
    artifacts = exportActiveDistribution( ...
        artifacts,exportDir,strategyRun.results,options);
elseif contains(tabName,"SEGMENT")
    artifacts = exportActiveSegments( ...
        artifacts,exportDir,strategyRun,options);
elseif contains(tabName,"OPTIMIZATION")
    artifacts = exportOptimizationState( ...
        artifacts,exportDir,options);
elseif contains(tabName,"LOG")
    artifacts = exportLogs(artifacts,exportDir,options.LogLines);
elseif contains(tabName,"REPORT")
    artifacts = exportActiveReport( ...
        artifacts,exportDir,strategyRun.results,cfg,options);
else
    % Overview y cualquier pestana nueva conservan las series principales.
    artifacts = exportActiveOverview( ...
        artifacts,exportDir,strategyRun.results,cfg,options);
end
end


function artifacts = exportActiveView( ...
        artifacts,exportDir,strategyRun,cfg,options,includeAnalytics)
artifacts = exportActiveOrders( ...
    artifacts,exportDir,strategyRun.results,options);
artifacts = exportActiveTrades( ...
    artifacts,exportDir,strategyRun.results,options,cfg);
artifacts = exportActiveReport( ...
    artifacts,exportDir,strategyRun.results,cfg,options);
artifacts = exportSessionComparison( ...
    artifacts,exportDir,strategyRun.results,options);

if includeAnalytics
    artifacts = exportActiveCalendarRolling( ...
        artifacts,exportDir,strategyRun.results,options);
    artifacts = exportActiveDistribution( ...
        artifacts,exportDir,strategyRun.results,options);
    artifacts = exportActiveSegments( ...
        artifacts,exportDir,strategyRun,options);
end

artifacts = exportSelectedResearch(artifacts,exportDir,options);
end


function artifacts = exportActiveOverview( ...
        artifacts,exportDir,results,cfg,options)
[orders,trades] = resolveActiveTables(results,options);
equity = buildEquitySeries(trades,cfg.risk.initialEquityUSD);
daily = buildDailyTradeResults(trades);
equity = annotateScenarioTable(equity,options);
daily = annotateScenarioTable(daily,options);
[artifacts,~] = addTableArtifact( ...
    artifacts,exportDir,"01_active_view/equity_drawdown.csv", ...
    equity,"ACTIVE_VIEW","Equity y drawdown despues de cada trade.");
[artifacts,~] = addTableArtifact( ...
    artifacts,exportDir,"01_active_view/daily_results.csv", ...
    daily,"ACTIVE_VIEW","Resultados agregados por fecha operada.");

metrics = struct2table(calculateResearchMetrics(orders,cfg));
metrics = annotateScenarioTable(metrics,options);
[artifacts,~] = addTableArtifact( ...
    artifacts,exportDir,"01_active_view/report_metrics.csv", ...
    metrics,"ACTIVE_VIEW","Metricas de la vista activa.");
end


function artifacts = exportActiveReport( ...
        artifacts,exportDir,results,cfg,options)
[orders,~] = resolveActiveTables(results,options);
metrics = struct2table(calculateResearchMetrics(orders,cfg));
metrics = annotateScenarioTable(metrics,options);
[artifacts,~] = addTableArtifact( ...
    artifacts,exportDir,"01_active_view/report_metrics.csv", ...
    metrics,"ACTIVE_VIEW","Metricas completas del Report.");
end


function artifacts = exportSessionComparison( ...
        artifacts,exportDir,results,options)
comparison = table();
if isfield(results,"summaryTable")
    comparison = buildSessionScenarioComparisonTable( ...
        results.summaryTable,string(options.Profile), ...
        string(options.ExitManagementScenario));
end
comparison = annotateScenarioTable(comparison,options);
[artifacts,~] = addTableArtifact( ...
    artifacts,exportDir,"01_active_view/session_comparison.csv", ...
    comparison,"ACTIVE_VIEW", ...
    "Comparacion Londres/NY del perfil y salida seleccionados.");
end


function artifacts = exportActiveOrders( ...
        artifacts,exportDir,results,options)
[orders,~] = resolveActiveTables(results,options);
orders = annotateScenarioTable(orders,options);
[artifacts,~] = addTableArtifact( ...
    artifacts,exportDir,"01_active_view/orders_all.csv", ...
    orders,"ACTIVE_VIEW", ...
    "Todas las oportunidades, incluidas las no ejecutadas.");
end


function artifacts = exportActiveTrades( ...
        artifacts,exportDir,results,options,cfg)
[~,trades] = resolveActiveTables(results,options);
trades = annotateScenarioTable(trades,options);
[artifacts,~] = addTableArtifact( ...
    artifacts,exportDir,"01_active_view/trades_executed.csv", ...
    trades,"ACTIVE_VIEW","Solo operaciones ejecutadas.");
[artifacts,~] = addTableArtifact( ...
    artifacts,exportDir,"01_active_view/equity_drawdown.csv", ...
    annotateScenarioTable( ...
        buildEquitySeries(trades,cfg.risk.initialEquityUSD),options), ...
    "ACTIVE_VIEW","Equity y drawdown despues de cada trade.");
[artifacts,~] = addTableArtifact( ...
    artifacts,exportDir,"01_active_view/daily_results.csv", ...
    annotateScenarioTable(buildDailyTradeResults(trades),options), ...
    "ACTIVE_VIEW", ...
    "Resultados diarios agregados.");
end


function artifacts = exportActiveCalendarRolling( ...
        artifacts,exportDir,results,options)
[~,trades] = resolveActiveTables(results,options);
calendar = calculateCalendarReturns(trades);
calendar.monthlyObservations = annotateScenarioTable( ...
    calendar.monthlyObservations,options);
[artifacts,~] = addTableArtifact( ...
    artifacts,exportDir,"01_active_view/monthly_returns.csv", ...
    calendar.monthlyObservations,"ANALYTICS", ...
    "Rentabilidad mensual calculada con equity real.");

annual = table(calendar.years,calendar.yearReturns, ...
    'VariableNames',{'year','return_pct'});
annual = annotateScenarioTable(annual,options);
[artifacts,~] = addTableArtifact( ...
    artifacts,exportDir,"01_active_view/annual_returns.csv", ...
    annual,"ANALYTICS","Rentabilidad anual de la vista activa.");

rolling = calculateRollingMetrics( ...
    trades,round(options.RollingWindow));
rollingTable = table( ...
    rolling.dates,rolling.win_rate_pct,rolling.expectancy_r, ...
    rolling.profit_factor,rolling.sharpe,rolling.drawdown_pct, ...
    rolling.execution_rate_pct, ...
    'VariableNames',{'date','win_rate_pct','expectancy_r', ...
    'profit_factor','sharpe','drawdown_pct','execution_rate_pct'});
rollingTable = annotateScenarioTable(rollingTable,options);
[artifacts,~] = addTableArtifact( ...
    artifacts,exportDir,"01_active_view/rolling_metrics.csv", ...
    rollingTable,"ANALYTICS", ...
    "Metricas rolling con la ventana seleccionada.");
end


function artifacts = exportActiveDistribution( ...
        artifacts,exportDir,results,options)
[~,trades] = resolveActiveTables(results,options);
filtered = filterTradeDistributionData( ...
    trades,string(options.DistributionFilter));
filtered = annotateScenarioTable(filtered,options);
stats = struct2table(calculateTradeDistributionStatistics(filtered));
stats = annotateScenarioTable(stats,options);
[artifacts,~] = addTableArtifact( ...
    artifacts,exportDir,"01_active_view/distribution_filtered_trades.csv", ...
    filtered,"ANALYTICS", ...
    "Trades del filtro de distribucion seleccionado.");
[artifacts,~] = addTableArtifact( ...
    artifacts,exportDir,"01_active_view/distribution_summary.csv", ...
    stats,"ANALYTICS", ...
    "Percentiles, MFE, MAE y concentracion de resultados.");
end


function artifacts = exportActiveSegments( ...
        artifacts,exportDir,strategyRun,options)
if strlength(string(options.SegmentFeature))==0
    return;
end

[~,trades] = resolveActiveTables(strategyRun.results,options);
catalog = getAvailableFeatureCatalog( ...
    strategyRun.feature_catalog,trades);
try
    analysis = analyzeStrategySegments( ...
        trades,string(options.SegmentFeature), ...
        string(options.SegmentGrouping), ...
        round(options.SegmentMinimumSample), ...
        options.SegmentTrainingPct);
    ranking = rankStrategyFeatures( ...
        trades,catalog,round(options.SegmentMinimumSample), ...
        options.SegmentTrainingPct);
    segmentResults = annotateScenarioTable(analysis.segments,options);
    ranking = annotateScenarioTable(ranking,options);
    [artifacts,~] = addTableArtifact( ...
        artifacts,exportDir,"01_active_view/segment_results.csv", ...
        segmentResults,"ANALYTICS", ...
        "Segmentos y validacion temporal de la feature seleccionada.");
    [artifacts,~] = addTableArtifact( ...
        artifacts,exportDir,"01_active_view/feature_ranking.csv", ...
        ranking,"ANALYTICS", ...
        "Ranking descriptivo de features; no implica causalidad.");
catch ME
    artifacts(end+1) = makeArtifact( ...
        "01_active_view/segment_results.csv","ANALYTICS",0,0, ...
        "ERROR","No se pudo calcular Segment Explorer.", ...
        string(ME.message)); %#ok<AGROW>
end
end


function artifacts = exportSelectedResearch(artifacts,exportDir,options)
[selectedRecord,researchDetails,researchSession,researchContext] = deal( ...
    annotateScenarioTable(options.SelectedRecord,options), ...
    annotateScenarioTable(options.ResearchDetails,options), ...
    annotateScenarioTable(options.ResearchSessionData,options), ...
    annotateScenarioTable(options.ResearchContext,options));
[artifacts,~] = addTableArtifact( ...
    artifacts,exportDir,"01_active_view/research_selected_record.csv", ...
    selectedRecord,"RESEARCH", ...
    "Fila completa del trade u orden seleccionado.");
[artifacts,~] = addTableArtifact( ...
    artifacts,exportDir,"01_active_view/research_details.csv", ...
    researchDetails,"RESEARCH", ...
    "Ficha legible mostrada en Research.");
[artifacts,~] = addTableArtifact( ...
    artifacts,exportDir,"01_active_view/research_session_bars.csv", ...
    researchSession,"RESEARCH", ...
    "Velas utilizadas para representar la operacion seleccionada.");
[artifacts,~] = addTableArtifact( ...
    artifacts,exportDir,"01_active_view/research_context.csv", ...
    researchContext,"RESEARCH", ...
    "Contexto precalculado de la sesion seleccionada.");
end


function artifacts = exportAllScenarios( ...
        artifacts,exportDir,results,cfg)
profiles = getDashboardProfiles(results);

for i = 1:numel(profiles)
    profile = string(profiles(i));
    sessionCatalog = getDashboardSessionScenarios(results,profile);
    for j = 1:height(sessionCatalog)
        sessionName = string(sessionCatalog.name(j));
        exitCatalog = getDashboardExitManagementScenarios( ...
            results,profile,sessionName);
        for k = 1:height(exitCatalog)
            exitName = string(exitCatalog.name(k));
            scenario = getDashboardScenario( ...
                results,profile,sessionName,exitName);
            orders = scenario.trades;
            trades = executedTrades(orders);
            scenarioOptions = struct( ...
                "Profile",profile, ...
                "SessionScenario",sessionName, ...
                "ExitManagementScenario",exitName);
            orders = annotateScenarioTable(orders,scenarioOptions);
            trades = annotateScenarioTable(trades,scenarioOptions);
            relativeRoot = fullfile( ...
                "02_all_scenarios",safeName(profile), ...
                safeName(sessionName),safeName(exitName));

            [artifacts,~] = addTableArtifact( ...
                artifacts,exportDir,fullfile(relativeRoot,"orders.csv"), ...
                orders,"ALL_SCENARIOS", ...
                "Oportunidades y motivos de no ejecucion.");
            [artifacts,~] = addTableArtifact( ...
                artifacts,exportDir,fullfile(relativeRoot,"trades.csv"), ...
                trades,"ALL_SCENARIOS","Operaciones ejecutadas.");
            [artifacts,~] = addTableArtifact( ...
                artifacts,exportDir,fullfile(relativeRoot,"summary.csv"), ...
                struct2table(scenario.summary),"ALL_SCENARIOS", ...
                "Resumen estadistico del backtest independiente.");
            [artifacts,~] = addTableArtifact( ...
                artifacts,exportDir, ...
                fullfile(relativeRoot,"equity_drawdown.csv"), ...
                annotateScenarioTable( ...
                    buildEquitySeries( ...
                        trades,cfg.risk.initialEquityUSD), ...
                    scenarioOptions), ...
                "ALL_SCENARIOS","Equity y drawdown cronologicos.");
            [artifacts,~] = addTableArtifact( ...
                artifacts,exportDir, ...
                fullfile(relativeRoot,"daily_results.csv"), ...
                annotateScenarioTable( ...
                    buildDailyTradeResults(trades),scenarioOptions), ...
                "ALL_SCENARIOS", ...
                "Resultados agregados por fecha operada.");
        end
    end
end
end


function artifacts = exportResearchInputs( ...
        artifacts,exportDir,strategyRun)
if isfield(strategyRun.results,"summaryTable")
    [artifacts,~] = addTableArtifact( ...
        artifacts,exportDir,"03_research/scenario_summary_all.csv", ...
        strategyRun.results.summaryTable,"RESEARCH", ...
        "Comparacion completa de todas las combinaciones.");
end
if isfield(strategyRun,"events")
    [artifacts,~] = addTableArtifact( ...
        artifacts,exportDir,"03_research/events.csv", ...
        strategyRun.events,"RESEARCH","Eventos generados por la estrategia.");
end
if isfield(strategyRun,"daily")
    [artifacts,~] = addTableArtifact( ...
        artifacts,exportDir,"03_research/daily_context.csv", ...
        strategyRun.daily,"RESEARCH","Contexto diario de la ejecucion.");
end
if isfield(strategyRun,"feature_catalog")
    [artifacts,~] = addTableArtifact( ...
        artifacts,exportDir,"03_research/feature_catalog.csv", ...
        strategyRun.feature_catalog,"RESEARCH", ...
        "Diccionario de features disponibles.");
end
if isfield(strategyRun,"parameter_schema")
    [artifacts,~] = addTableArtifact( ...
        artifacts,exportDir,"03_research/parameter_schema.csv", ...
        strategyRun.parameter_schema,"RESEARCH", ...
        "Parametros optimizables y sus dominios.");
end
if isfield(strategyRun,"metadata") && isstruct(strategyRun.metadata)
    [artifacts,~] = addTableArtifact( ...
        artifacts,exportDir,"03_research/run_metadata.csv", ...
        flattenForExport(strategyRun.metadata,"metadata"), ...
        "RESEARCH","Metadata de la ejecucion que alimenta el dashboard.");
end
end


function artifacts = exportOptimizationState(artifacts,exportDir,options)
[artifacts,~] = addTableArtifact( ...
    artifacts,exportDir,"04_optimization/full_grid_results.csv", ...
    options.OptimizationResults,"OPTIMIZATION", ...
    "Resultados disponibles del ultimo Full Grid.");

wf = options.WalkForwardResult;
if isempty(fieldnames(wf)), return; end

tableFields = ["grid","window_results","aggregate_results","consensus"];
fileNames = ["grid.csv","window_results.csv", ...
    "aggregate_results.csv","consensus.csv"];
for i = 1:numel(tableFields)
    field = tableFields(i);
    if isfield(wf,field) && istable(wf.(field))
        [artifacts,~] = addTableArtifact( ...
            artifacts,exportDir,fullfile("04_optimization",fileNames(i)), ...
            wf.(field),"OPTIMIZATION", ...
            "Resultado disponible del ultimo Walk-Forward.");
    end
end

structFields = ["plan","holdout","run_state"];
for i = 1:numel(structFields)
    field = structFields(i);
    if isfield(wf,field) && isstruct(wf.(field))
        [artifacts,~] = addTableArtifact( ...
            artifacts,exportDir, ...
            fullfile("04_optimization",field + ".csv"), ...
            flattenForExport(wf.(field),field),"OPTIMIZATION", ...
            "Configuracion o estado del ultimo Walk-Forward.");
    end
end

cellFields = ["training_sweeps","validation_sweeps"];
for f = 1:numel(cellFields)
    field = cellFields(f);
    if ~isfield(wf,field) || ~iscell(wf.(field)), continue; end
    sweeps = wf.(field);
    for i = 1:numel(sweeps)
        if ~istable(sweeps{i}), continue; end
        relative = fullfile( ...
            "04_optimization",field, ...
            sprintf("window_%03d.csv",i));
        [artifacts,~] = addTableArtifact( ...
            artifacts,exportDir,relative,sweeps{i}, ...
            "OPTIMIZATION","Barrido completo de una ventana Walk-Forward.");
    end
end
end


function artifacts = exportLogs(artifacts,exportDir,logLines)
relative = "06_logs/dashboard_logs.txt";
file = fullfile(exportDir,relative);
if ~isfolder(fileparts(file)), mkdir(fileparts(file)); end
fid = fopen(file,"w");
if fid<0
    artifacts(end+1) = makeArtifact( ...
        relative,"LOG",0,0,"ERROR","Logs del dashboard.", ...
        "No se pudo crear el archivo."); %#ok<AGROW>
    return;
end
cleanup = onCleanup(@() fclose(fid));
lines = string(logLines);
for i = 1:numel(lines), fprintf(fid,"%s\n",lines(i)); end
clear cleanup;
artifacts(end+1) = makeArtifact( ...
    relative,"LOG",numel(lines),1,"OK","Logs del dashboard.",""); %#ok<AGROW>
end


function [orders,trades] = resolveActiveTables(results,options)
profile = string(options.Profile);
if strlength(profile)==0
    profiles = getDashboardProfiles(results);
    profile = profiles(1);
end
scenario = getDashboardScenario( ...
    results,profile,string(options.SessionScenario), ...
    string(options.ExitManagementScenario));
orders = scenario.trades;
trades = executedTrades(orders);
end


function trades = executedTrades(orders)
trades = orders;
if isempty(orders), return; end
variables = string(orders.Properties.VariableNames);
mask = true(height(orders),1);
if ismember("valid",variables), mask = mask & logical(orders.valid); end
if ismember("quantity",variables)
    mask = mask & isfinite(orders.quantity) & orders.quantity>0;
elseif ismember("contracts",variables)
    mask = mask & isfinite(orders.contracts) & orders.contracts>0;
end
trades = orders(mask,:);
end


function data = annotateScenarioTable(data,options)
if width(data)==0, return; end
n = height(data);
data.execution_profile = repmat(string(options.Profile),n,1);
data.session_scenario = repmat(string(options.SessionScenario),n,1);
data.exit_management = repmat( ...
    string(options.ExitManagementScenario),n,1);
end


function daily = buildDailyTradeResults(trades)
daily = table();
if isempty(trades) || ...
        ~ismember("session_date",string(trades.Properties.VariableNames))
    return;
end

trades = sortrows(trades,"session_date");
dates = dateshift(trades.session_date,"start","day");
[group,uniqueDates] = findgroups(dates);
n = numel(uniqueDates);
tradeCount = zeros(n,1);
wins = zeros(n,1);
losses = zeros(n,1);
breakeven = zeros(n,1);
netR = zeros(n,1);
netPnL = zeros(n,1);
fees = zeros(n,1);
endingEquity = nan(n,1);

for i = 1:n
    rows = trades(group==i,:);
    tradeCount(i) = height(rows);
    if ismember("net_pnl_usd",string(rows.Properties.VariableNames))
        pnl = rows.net_pnl_usd;
        wins(i) = nnz(pnl>0);
        losses(i) = nnz(pnl<0);
        breakeven(i) = nnz(pnl==0);
        netPnL(i) = sum(pnl,"omitnan");
    end
    if ismember("net_R",string(rows.Properties.VariableNames))
        netR(i) = sum(rows.net_R,"omitnan");
    end
    if ismember("commission_usd",string(rows.Properties.VariableNames))
        fees(i) = sum(rows.commission_usd,"omitnan");
    end
    if ismember("equity_after_usd",string(rows.Properties.VariableNames))
        endingEquity(i) = rows.equity_after_usd(end);
    end
end

daily = table( ...
    uniqueDates,tradeCount,wins,losses,breakeven,netR,netPnL,fees, ...
    endingEquity,cumsum(netR),cumsum(netPnL), ...
    'VariableNames',{'date','trade_count','wins','losses','breakeven', ...
    'net_R','net_pnl_usd','commission_usd','ending_equity_usd', ...
    'cumulative_net_R','cumulative_net_pnl_usd'});
end


function context = buildManifestContext( ...
        strategyRun,cfg,options,mode,stamp)
name = [ ...
    "export_timestamp";"quantlab_version";"strategy";"mode"; ...
    "active_tab";"execution_profile";"session_scenario"; ...
    "exit_management";"market_timezone";"rolling_window"; ...
    "distribution_filter";"segment_feature"; ...
    "raw_market_data_copied"];
value = [ ...
    stamp;"0.25.25";string(strategyRun.strategy);mode; ...
    string(options.ActiveTab);string(options.Profile); ...
    string(options.SessionScenario); ...
    string(options.ExitManagementScenario); ...
    string(cfg.marketTimezone);string(options.RollingWindow); ...
    string(options.DistributionFilter);string(options.SegmentFeature); ...
    "false"];
context = table(name,value);
end


function inventory = buildDatasetInventory(strategyRun,cfg)
name = strings(0,1);
value = strings(0,1);
add("configured_path",string(cfg.dataFile));
add("exists",string(isfile(cfg.dataFile)));

if isfile(cfg.dataFile)
    info = dir(cfg.dataFile);
    add("size_bytes",string(info.bytes));
    add("modified_at",string(datetime(info.datenum, ...
        "ConvertFrom","datenum","Format","yyyy-MM-dd HH:mm:ss")));
end

data = strategyRun.data;
add("rows",string(height(data)));
add("columns",string(width(data)));
add("variables",strjoin(string(data.Properties.VariableNames),"|"));

try
    add("dataset_fingerprint",buildDatasetFingerprint(data,cfg));
catch ME
    add("dataset_fingerprint","UNAVAILABLE: " + string(ME.message));
end

timeCandidates = ["datetime_local","datetime","datetime_new_york"];
variables = string(data.Properties.VariableNames);
timeField = timeCandidates(find(ismember(timeCandidates,variables),1));
if ~isempty(timeField) && ~isempty(data)
    values = data.(timeField);
    add("time_field",timeField);
    add("first_timestamp",string(values(1),"yyyy-MM-dd HH:mm:ss"));
    add("last_timestamp",string(values(end),"yyyy-MM-dd HH:mm:ss"));
    add("time_zone",string(values.TimeZone));
end

inventory = table(name,value);

    function add(fieldName,fieldValue)
        name(end+1,1) = string(fieldName);
        value(end+1,1) = string(fieldValue);
    end
end


function rows = flattenForExport(value,rootName)
path = strings(0,1);
textValue = strings(0,1);
type = strings(0,1);
visit(value,string(rootName));
rows = table(path,textValue,type, ...
    'VariableNames',{'path','value','type'});

    function visit(item,itemPath)
        if isstruct(item)
            if isempty(item)
                append(itemPath,"<empty struct>","struct");
                return;
            end
            fields = string(fieldnames(item));
            for index = 1:numel(item)
                base = itemPath;
                if numel(item)>1, base = itemPath + "(" + index + ")"; end
                for fieldIndex = 1:numel(fields)
                    field = fields(fieldIndex);
                    visit(item(index).(field),base + "." + field);
                end
            end
        elseif istable(item)
            append(itemPath, ...
                sprintf("<table %dx%d>",height(item),width(item)),"table");
        elseif isdatetime(item)
            append(itemPath,strjoin(string(item(:), ...
                "yyyy-MM-dd HH:mm:ss")," | "),"datetime");
        elseif isduration(item)
            append(itemPath,strjoin(string(item(:))," | "),"duration");
        elseif isstring(item) || ischar(item) || iscategorical(item)
            append(itemPath,strjoin(string(item(:))," | "),class(item));
        elseif isnumeric(item) || islogical(item)
            append(itemPath,string(mat2str(item)),class(item));
        elseif isa(item,"function_handle")
            append(itemPath,string(func2str(item)),"function_handle");
        else
            append(itemPath,"<" + string(class(item)) + ">",class(item));
        end
    end

    function append(itemPath,itemValue,itemType)
        path(end+1,1) = itemPath;
        textValue(end+1,1) = string(itemValue);
        type(end+1,1) = string(itemType);
    end
end


function [artifacts,file] = addTableArtifact( ...
        artifacts,exportDir,relativePath,data,category,description)
relativePath = string(relativePath);
file = fullfile(exportDir,relativePath);
rowCount = height(data);
columnCount = width(data);

if columnCount==0
    artifacts(end+1) = makeArtifact( ...
        relativePath,category,rowCount,columnCount,"NOT_AVAILABLE", ...
        description,"No habia datos disponibles en el dashboard."); %#ok<AGROW>
    return;
end

if ~isfolder(fileparts(file)), mkdir(fileparts(file)); end
try
    writetable(makeCsvSafe(data),file);
    status = "OK";
    errorMessage = "";
catch ME
    status = "ERROR";
    errorMessage = string(ME.message);
end

artifacts(end+1) = makeArtifact( ...
    relativePath,category,rowCount,columnCount,status, ...
    description,errorMessage); %#ok<AGROW>
end


function output = makeCsvSafe(input)
output = input;
for i = 1:width(output)
    name = output.Properties.VariableNames{i};
    values = output.(name);
    if iscell(values)
        converted = strings(size(values));
        for j = 1:numel(values)
            converted(j) = scalarToString(values{j});
        end
        output.(name) = converted;
    elseif isstruct(values)
        converted = strings(size(values));
        for j = 1:numel(values)
            converted(j) = scalarToString(values(j));
        end
        output.(name) = converted;
    end
end
end


function value = scalarToString(item)
if isempty(item)
    value = "";
elseif isstring(item) || ischar(item) || iscategorical(item)
    value = strjoin(string(item(:))," | ");
elseif isnumeric(item) || islogical(item)
    value = string(mat2str(item));
elseif isdatetime(item) || isduration(item)
    value = strjoin(string(item(:))," | ");
elseif isstruct(item)
    try
        value = string(jsonencode(item));
    catch
        value = "<struct>";
    end
else
    value = "<" + string(class(item)) + ">";
end
end


function artifacts = emptyArtifactStruct()
artifacts = struct( ...
    "relative_path",{},"category",{},"row_count",{}, ...
    "column_count",{},"status",{},"description",{}, ...
    "error_message",{});
end


function artifact = makeArtifact( ...
        relativePath,category,rowCount,columnCount,status,description,errorMessage)
artifact = struct( ...
    "relative_path",replace(string(relativePath),string(filesep),"/"), ...
    "category",string(category), ...
    "row_count",double(rowCount), ...
    "column_count",double(columnCount), ...
    "status",string(status), ...
    "description",string(description), ...
    "error_message",string(errorMessage));
end


function value = safeName(value)
value = regexprep(upper(string(value)),"[^A-Z0-9_-]+","_");
if strlength(value)==0, value = "UNNAMED"; end
end


function writeExportReadme(file,strategyName,mode,options)
fid = fopen(file,"w");
if fid<0
    error("QuantLab:ExportReadme", ...
        "No se pudo crear %s.",file);
end
cleanup = onCleanup(@() fclose(fid));

fprintf(fid,"QUANTLAB EXPORT v0.25.37\n");
fprintf(fid,"Strategy: %s\n",strategyName);
fprintf(fid,"Mode: %s\n",mode);
fprintf(fid,"Active view: %s | %s | %s | %s\n\n", ...
    string(options.ActiveTab),string(options.Profile), ...
    string(options.SessionScenario), ...
    string(options.ExitManagementScenario));
fprintf(fid,"STRUCTURE\n");
fprintf(fid,"00_manifest  Version, configuration, dataset inventory and file index.\n");
fprintf(fid,"01_active_view  Orders, executed trades and selected analytics.\n");
fprintf(fid,"02_all_scenarios  Profile/session/exit independent backtests.\n");
fprintf(fid,"03_research  Events, daily context, schemas and global comparison.\n");
fprintf(fid,"04_optimization  Full Grid and Walk-Forward results available in memory.\n");
fprintf(fid,"05_figures  Screenshot of the visible dashboard.\n");
fprintf(fid,"06_logs  Dashboard logs when that tab is exported.\n\n");
fprintf(fid,"IMPORTANT\n");
fprintf(fid,"orders.csv includes non-executed setups and skip reasons.\n");
fprintf(fid,"trades.csv includes only executed trades.\n");
fprintf(fid,"Raw market bars are not copied to avoid duplicating the repository.\n");
fprintf(fid,"dataset_inventory.csv identifies the exact source dataset.\n");
fprintf(fid,"NOT_AVAILABLE in artifacts.csv means that the dashboard had no data for that artifact.\n");
clear cleanup;
end
