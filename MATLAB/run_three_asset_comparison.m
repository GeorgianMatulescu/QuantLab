function result = run_three_asset_comparison()
%RUN_THREE_ASSET_COMPARISON Compara MNQ/MES/MYM y crea cartera combinada.
%
% La comparación usa exclusivamente el intervalo común de los tres CSV.
% La cartera asigna 1/3 del riesgo normal a cada trade de activo. Así, tres
% señales en la misma sesión suman como máximo el riesgo de una operación
% individual del backtest mono-activo, sin elegir retrospectivamente cuál
% habría sido el mejor mercado.

clc;

matlabRoot = string(fileparts(mfilename('fullpath')));
addpath(genpath(matlabRoot));

assets = ["MNQ","MES","MYM"];
assetCount = numel(assets);
cfgByAsset = cell(assetCount,1);
coverageByAsset = cell(assetCount,1);

fprintf('\n=== QUANTLAB MULTI-ASSET v0.25.37 ===\n');
fprintf('Activos: MNQ + MES + MYM\n');
fprintf('Regla cartera: 1/3 del riesgo por trade de activo.\n\n');

for i = 1:assetCount
    cfgByAsset{i} = loadQuantLabConfig(matlabRoot,assets(i));
    coverageByAsset{i} = readCoverage(cfgByAsset{i});
end
coverage = vertcat(coverageByAsset{:});

firstAvailable = [coverage.firstDateLocal];
lastAvailable = [coverage.lastDateLocal];
commonFirstDate = max(firstAvailable)+caldays(1);
commonLastDate = min(lastAvailable)-caldays(1);
if commonLastDate<commonFirstDate
    error("QuantLab:NoCommonCoverage", ...
        "MNQ, MES y MYM no tienen un intervalo diario completo en común.");
end

fprintf('Muestra común congelada: %s -> %s\n\n', ...
    char(commonFirstDate,"yyyy-MM-dd"), ...
    char(commonLastDate,"yyyy-MM-dd"));

resultsByAsset = cell(assetCount,1);
summaryTables = cell(assetCount,1);

for i = 1:assetCount
    cfg = cfgByAsset{i};
    fprintf('[%d/%d] Cargando %s...\n',i,assetCount,assets(i));
    [data,dataReport] = loadConfiguredMarketData(cfg);
    coverage(i).validRows = height(data);
    coverage(i).duplicatesRemoved = dataReport.duplicatesRemoved;
    coverage(i).missingMinuteIntervals = dataReport.missingMinuteIntervals;

    keep = data.session_date>=commonFirstDate & ...
        data.session_date<=commonLastDate;
    data = data(keep,:);
    coverage(i).commonRows = height(data);
    if isempty(data)
        error("QuantLab:EmptyCommonCoverage", ...
            "%s no contiene filas dentro del intervalo común.",assets(i));
    end

    fprintf('[%d/%d] Ejecutando CRT 3H en %s (%d filas)...\n', ...
        i,assetCount,assets(i),height(data));
    output = runStrategy(string(cfg.strategyName),data,cfg);
    resultsByAsset{i} = output.results;
    assetSummary = output.results.summaryTable;
    assetSummary = addvars(assetSummary, ...
        repmat(assets(i),height(assetSummary),1), ...
        repmat(string(cfg.crt3h.rulesVersion),height(assetSummary),1), ...
        repmat(cfg.crt3h.entryFraction,height(assetSummary),1), ...
        repmat(cfg.crt3h.rewardRisk,height(assetSummary),1), ...
        'Before',1,'NewVariableNames', ...
        ["asset","rulesVersion","entryFraction","fixedTargetR"]);
    summaryTables{i} = assetSummary;
    clear data output;
end

assetComparison = vertcat(summaryTables{:});
[combinedSummary,defaultCombinedTrades] = buildCombinedResults( ...
    assets,resultsByAsset,cfgByAsset{1});

coverageTable = struct2table(coverage);
coverageTable.commonFirstDate(:) = commonFirstDate;
coverageTable.commonLastDate(:) = commonLastDate;

reportDir = fullfile(matlabRoot,"Reports","CRT_3H_MADRID","MULTI_ASSET");
if ~isfolder(reportDir), mkdir(reportDir); end
writetable(coverageTable,fullfile(reportDir,"coverage_audit.csv"));
writetable(assetComparison, ...
    fullfile(reportDir,"asset_comparison_common_sample.csv"));
writetable(combinedSummary, ...
    fullfile(reportDir,"combined_portfolio_summary.csv"));

profiles = fieldnames(defaultCombinedTrades);
for i = 1:numel(profiles)
    field = profiles{i};
    trades = defaultCombinedTrades.(field);
    if ~isempty(trades)
        writetable(trades,fullfile( ...
            reportDir,"combined_trades_" + lower(string(field)) + ".csv"));
    end
end

fprintf('\nComparación terminada. Archivos:\n%s\n',reportDir);
fprintf(['La tabla por activo y la cartera usan las mismas fechas. ' ...
    'No se anualizan muestras ni se selecciona el mejor activo a posteriori.\n']);

result = struct( ...
    "assets",assets, ...
    "commonFirstDate",commonFirstDate, ...
    "commonLastDate",commonLastDate, ...
    "coverage",coverageTable, ...
    "assetComparison",assetComparison, ...
    "combinedSummary",combinedSummary, ...
    "combinedTrades",defaultCombinedTrades, ...
    "reportDir",string(reportDir));
end

function coverage = readCoverage(cfg)
if ~isfile(cfg.dataFile)
    error("QuantLab:MissingAssetData", ...
        "Falta %s. Ejecuta primero DESCARGAR_MES_MYM_IBKR_2Y.bat.", ...
        cfg.dataFile);
end

metadataFile = replace(cfg.dataFile,".csv",".metadata.json");
if ~isfile(metadataFile)
    error("QuantLab:MissingAssetMetadata", ...
        "Falta el metadata requerido para congelar cobertura: %s", ...
        metadataFile);
end

metadata = jsondecode(fileread(metadataFile));
firstUTC = parseMetadataDateTime(string(metadata.first_timestamp_utc));
lastUTC = parseMetadataDateTime(string(metadata.last_timestamp_utc));
firstLocal = firstUTC;
lastLocal = lastUTC;
firstLocal.TimeZone = char(cfg.marketTimezone);
lastLocal.TimeZone = char(cfg.marketTimezone);

coverage = struct( ...
    "asset",string(cfg.instrument), ...
    "exchange",string(cfg.exchange), ...
    "configuredPath",string(cfg.dataFile), ...
    "metadataRows",double(metadata.rows), ...
    "firstTimestampUTC",firstUTC, ...
    "lastTimestampUTC",lastUTC, ...
    "firstDateLocal",dateshift(firstLocal,"start","day"), ...
    "lastDateLocal",dateshift(lastLocal,"start","day"), ...
    "validRows",NaN, ...
    "commonRows",NaN, ...
    "duplicatesRemoved",NaN, ...
    "missingMinuteIntervals",NaN, ...
    "commonFirstDate",NaT("TimeZone",char(cfg.marketTimezone)), ...
    "commonLastDate",NaT("TimeZone",char(cfg.marketTimezone)));
end

function value = parseMetadataDateTime(text)
formats = ["yyyy-MM-dd HH:mm:ssXXX","yyyy-MM-dd'T'HH:mm:ssXXX"];
lastError = [];
for format = formats
    try
        value = datetime(text,"InputFormat",format,"TimeZone","UTC");
        return;
    catch ME
        lastError = ME;
    end
end
error("QuantLab:MetadataDateTime", ...
    "Fecha de metadata no válida: %s (%s)",text,lastError.message);
end

function [summary,defaultTrades] = buildCombinedResults( ...
    assets,resultsByAsset,cfg)
scenarioTable = resultsByAsset{1}.summaryTable;
rows = cell(height(scenarioTable),1);
defaultTrades = struct();

for i = 1:height(scenarioTable)
    profile = string(scenarioTable.executionProfile(i));
    sessionScenario = string(scenarioTable.sessionScenario(i));
    exitScenario = string(scenarioTable.exitManagementScenario(i));
    tradeParts = cell(numel(assets),1);

    for j = 1:numel(assets)
        trades = getScenarioTrades(resultsByAsset{j}, ...
            profile,sessionScenario,exitScenario);
        tradeParts{j} = trades(trades.valid,:);
    end

    nonEmpty = ~cellfun(@isempty,tradeParts);
    if any(nonEmpty)
        combined = vertcat(tradeParts{nonEmpty});
        combined = sortrows(combined,["exit_time","entry_time","symbol"]);
        combined.portfolio_R = combined.net_R/numel(assets);
    else
        combined = table();
    end

    rows{i} = summarizeCombined( ...
        combined,profile,sessionScenario, ...
        string(scenarioTable.sessionScenarioLabel(i)), ...
        exitScenario, ...
        string(scenarioTable.exitManagementScenarioLabel(i)), ...
        cfg.risk.percentRisk,numel(assets), ...
        string(cfg.crt3h.rulesVersion), ...
        cfg.crt3h.entryFraction,cfg.crt3h.rewardRisk);

    isDefaultSession = sessionScenario==string( ...
        cfg.crt3h.defaultSessionScenario);
    isDefaultExit = exitScenario==string( ...
        cfg.crt3h.defaultExitManagementScenario);
    if isDefaultSession && isDefaultExit
        field = matlab.lang.makeValidName(upper(profile));
        defaultTrades.(field) = combined;
    end
end

summary = struct2table(vertcat(rows{:}));
end

function trades = getScenarioTrades( ...
    results,profile,sessionScenario,exitScenario)
profileField = matlab.lang.makeValidName(upper(profile));
sessionField = matlab.lang.makeValidName(upper(sessionScenario));
exitField = matlab.lang.makeValidName(upper(exitScenario));
trades = results.(profileField).sessionScenarios.(sessionField). ...
    exitManagementScenarios.(exitField).trades;
end

function row = summarizeCombined( ...
    trades,profile,sessionScenario,sessionLabel, ...
    exitScenario,exitLabel,baseRiskFraction,assetCount, ...
    rulesVersion,entryFraction,fixedTargetR)

row = struct( ...
    "rulesVersion",rulesVersion, ...
    "entryFraction",entryFraction, ...
    "fixedTargetR",fixedTargetR, ...
    "executionProfile",profile, ...
    "sessionScenario",sessionScenario, ...
    "sessionScenarioLabel",sessionLabel, ...
    "exitManagementScenario",exitScenario, ...
    "exitManagementScenarioLabel",exitLabel, ...
    "allocationPolicy","FIXED_ONE_THIRD_PER_ASSET_TRADE", ...
    "riskPerAssetTradePct",100*baseRiskFraction/assetCount, ...
    "maximumThreeAssetSessionRiskPct",100*baseRiskFraction, ...
    "executedTrades",height(trades), ...
    "winningTrades",0, ...
    "losingTrades",0, ...
    "breakevenTrades",0, ...
    "winRatePct",NaN, ...
    "rawNetR",0, ...
    "portfolioNetR",0, ...
    "expectancyRawRPerTrade",NaN, ...
    "profitFactorR",NaN, ...
    "maximumDrawdownR",NaN);

if isempty(trades), return; end
rawR = trades.net_R;
portfolioR = trades.portfolio_R;
row.winningTrades = nnz(rawR>0);
row.losingTrades = nnz(rawR<0);
row.breakevenTrades = nnz(rawR==0);
row.winRatePct = 100*row.winningTrades/height(trades);
row.rawNetR = sum(rawR,"omitnan");
row.portfolioNetR = sum(portfolioR,"omitnan");
row.expectancyRawRPerTrade = mean(rawR,"omitnan");

grossProfit = sum(portfolioR(portfolioR>0),"omitnan");
grossLoss = abs(sum(portfolioR(portfolioR<0),"omitnan"));
if grossLoss>0
    row.profitFactorR = grossProfit/grossLoss;
elseif grossProfit>0
    row.profitFactorR = Inf;
end

curve = [0;cumsum(portfolioR,"omitnan")];
drawdown = curve-cummax(curve);
row.maximumDrawdownR = abs(min(drawdown));
end
