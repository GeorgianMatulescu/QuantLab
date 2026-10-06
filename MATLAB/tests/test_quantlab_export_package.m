matlabRoot = string(fileparts(fileparts(mfilename("fullpath"))));
addpath(genpath(matlabRoot));

temporaryRoot = string(tempname);
mkdir(temporaryRoot);
cleanup = onCleanup(@() rmdir(temporaryRoot,"s"));
temporaryMatlabRoot = fullfile(temporaryRoot,"MATLAB");
mkdir(temporaryMatlabRoot);

cfg = loadQuantLabConfig(temporaryMatlabRoot);

sessionDate = datetime(2026,1,2,"TimeZone","Europe/Madrid");
entryTime = sessionDate + hours(9) + minutes(15);
valid = true;
direction = "LONG";
entryPrice = 20000;
exitPrice = 20015;
netR = 1.5;
netPnL = 150;
commission = 1.24;
equityBefore = 50000;
equityAfter = 50150;
quantity = 5;
contracts = 5;
exitReason = "TARGET";

trades = table( ...
    sessionDate,entryTime,valid,direction,entryPrice,exitPrice, ...
    netR,netPnL,commission,equityBefore,equityAfter,quantity, ...
    contracts,exitReason, ...
    'VariableNames',{'session_date','entry_time','valid','direction', ...
    'entry_price','exit_price','net_R','net_pnl_usd', ...
    'commission_usd','equity_before_usd','equity_after_usd', ...
    'quantity','contracts','exit_reason'});

summary = calculateScenarioStatistics( ...
    trades,cfg,cfg.executionProfiles(1));
summary.executionProfile = "IDEAL";
summary.sessionScenario = "DEFAULT";
summary.sessionScenarioLabel = "Configuracion actual";
summary.exitManagementScenario = "DEFAULT";
summary.exitManagementScenarioLabel = "Gestion actual";

results = struct();
results.IDEAL = struct("trades",trades,"summary",summary);
results.summaryTable = struct2table(summary);

strategyRun = struct( ...
    "strategy","CRT_3H_MADRID", ...
    "results",results, ...
    "data",table(), ...
    "events",table(), ...
    "feature_catalog",table(), ...
    "parameter_schema",table());

options = struct( ...
    "Mode","ACTIVE_TAB", ...
    "ActiveTab","Orders", ...
    "Profile","IDEAL");

report = exportQuantLabDashboardPackage( ...
    strategyRun,cfg,options);

assert(isfolder(report.exportDirectory));
assert(isfile(report.manifestFile));
assert(isfile(fullfile( ...
    report.exportDirectory,"01_active_view","orders_all.csv")));
assert(isfile(fullfile( ...
    report.exportDirectory,"00_manifest","configuration.csv")));

manifest = readtable(report.manifestFile, ...
    "TextType","string");
ordersRow = manifest(endsWith( ...
    manifest.relative_path,"orders_all.csv"),:);
assert(height(ordersRow)==1);
assert(ordersRow.status=="OK");
assert(ordersRow.row_count==1);

clear cleanup;
fprintf("TEST QUANTLAB EXPORT PACKAGE SUPERADO\n");
