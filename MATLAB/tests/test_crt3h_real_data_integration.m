matlabRoot = fileparts(fileparts(mfilename('fullpath')));
addpath(genpath(matlabRoot));

cfg = loadQuantLabConfig(matlabRoot);
% Esta regresión conserva el baseline histórico 0,50/1R. La nueva regla
% 0,75/0,5R se valida en test_crt3h_entry_075_target_05.m.
cfg.crt3h.entryFraction = 0.5;
cfg.crt3h.rewardRisk = 1.0;
assert(string(cfg.strategyName)=="CRT_3H_MADRID");
assert(isfile(cfg.dataFile));

[data,report] = loadConfiguredMarketData(cfg);
assert(height(data)==354805);
assert(report.duplicatesRemoved==0);
assert(all(double(data.use_rth)==0));
assert(all(string(data.bar_size)=="1 min"));

[~,context] = buildCRT3HContext(data,cfg);
daily = context.daily;

assert(nnz(daily.london_complete)==259);
assert(nnz(daily.new_york_complete)==258);
assert(nnz(daily.london_complete & daily.new_york_complete)==258);

earlyClose = datetime(2026,4,3,"TimeZone",char(cfg.marketTimezone));
row = daily.session_date==earlyClose;
assert(nnz(row)==1);
assert(daily.london_complete(row));
assert(~daily.new_york_complete(row));

% Regresión 2025-11-11, Nueva York: con el umbral de un tick (0.25), el
% exceso de 0.75 sobre el máximo CRT es el primer sweep válido. Debe fijar
% SHORT y el barrido posterior del mínimo no puede cambiar la dirección.
caseDate = datetime(2025,11,11,"TimeZone",char(cfg.marketTimezone));
caseWindow = context.windows( ...
    [context.windows.session_date]==caseDate & ...
    string({context.windows.session_name})=="NUEVA_YORK");
assert(numel(caseWindow)==1);
assert(abs(caseWindow.crt_high-26389.25)<1e-9);
assert(abs(caseWindow.crt_low-26314.25)<1e-9);

caseManipulation = data(caseWindow.man_indices,:);
assert(abs(max(caseManipulation.high)-26390.00)<1e-9);
assert(cfg.crt3h.newYork.thresholdPoints==cfg.instrumentSpec.tickSize);

validHighSweep = caseManipulation.high>= ...
    caseWindow.crt_high+cfg.crt3h.newYork.thresholdPoints;
firstHighSweep = find(validHighSweep,1,"first");
assert(~isempty(firstHighSweep));
assert(caseManipulation.datetime_local(firstHighSweep)== ...
    datetime(2025,11,11,15,37,0, ...
    "TimeZone",char(cfg.marketTimezone)));

caseData = data(data.session_date==caseDate,:);
caseOutput = runStrategy("CRT_3H_MADRID",caseData,cfg);
caseScenario = caseOutput.results.IDEAL.sessionScenarios.NEW_YORK_ONLY;
caseTrades = caseScenario.exitManagementScenarios.FIXED_TARGET.trades;
caseNy = caseTrades.session_name=="NUEVA_YORK";
assert(nnz(caseNy)==1);
assert(caseTrades.valid(caseNy));
assert(caseTrades.direction(caseNy)=="SHORT");
assert(caseTrades.sweep_side(caseNy)=="HIGH");
assert(caseTrades.sweep_time(caseNy)== ...
    datetime(2025,11,11,15,37,0, ...
    "TimeZone",char(cfg.marketTimezone)));
assert(caseTrades.entry_time(caseNy)== ...
    datetime(2025,11,11,15,38,0, ...
    "TimeZone",char(cfg.marketTimezone)));
assert(abs(caseTrades.entry_level_50(caseNy)-26352.00)<1e-9);
assert(abs(caseTrades.entry_price(caseNy)-26352.00)<1e-9);
assert(abs(caseTrades.target_price(caseNy)-26314.00)<1e-9);
assert(~caseTrades.break_even_triggered(caseNy));
assert(abs(caseTrades.break_even_trigger_price(caseNy)-26314.00)<1e-9);
assert(abs(caseTrades.break_even_price(caseNy)-26352.00)<1e-9);
assert(isnat(caseTrades.break_even_trigger_time(caseNy)));
assert(isnat(caseTrades.break_even_effective_time(caseNy)));
assert(caseTrades.exit_reason(caseNy)=="TARGET");
assert(caseTrades.exit_time(caseNy)== ...
    datetime(2025,11,11,15,50,0, ...
    "TimeZone",char(cfg.marketTimezone)));
assert(abs(caseTrades.gross_R(caseNy)-1.0)<1e-12);

% Regresión 2026-07-06, Nueva York: al abrir la ventana a las 15:00, el
% sweep HIGH de esa hora es elegible y fija SHORT. La señal posterior no
% puede reinterpretarse como LONG.
openDate = datetime(2026,7,6,"TimeZone",char(cfg.marketTimezone));
openWindow = context.windows( ...
    [context.windows.session_date]==openDate & ...
    string({context.windows.session_name})=="NUEVA_YORK");
assert(numel(openWindow)==1);
assert(abs(openWindow.crt_high-29936.25)<1e-9);
assert(abs(openWindow.crt_low-29841.00)<1e-9);
assert(openWindow.man_start==datetime(2026,7,6,15,0,0, ...
    "TimeZone",char(cfg.marketTimezone)));
assert(all(data.datetime_local(openWindow.man_indices)>= ...
    openWindow.man_start));

openData = data(data.session_date==openDate,:);
openOutput = runStrategy("CRT_3H_MADRID",openData,cfg);
openScenario = openOutput.results.IDEAL.sessionScenarios.NEW_YORK_ONLY;
openTrades = openScenario.exitManagementScenarios.FIXED_TARGET.trades;
openNy = openTrades.session_name=="NUEVA_YORK";
assert(nnz(openNy)==1);
assert(openTrades.valid(openNy));
assert(openTrades.direction(openNy)=="SHORT");
assert(openTrades.sweep_side(openNy)=="HIGH");
assert(openTrades.sweep_time(openNy)==datetime(2026,7,6,15,0,0, ...
    "TimeZone",char(cfg.marketTimezone)));
assert(openTrades.entry_time(openNy)==datetime(2026,7,6,15,8,0, ...
    "TimeZone",char(cfg.marketTimezone)));
assert(abs(openTrades.entry_level_50(openNy)-29889.50)<1e-9);
assert(abs(openTrades.target_price(openNy)-29840.75)<1e-9);
assert(openTrades.exit_reason(openNy)=="TARGET");
assert(openTrades.exit_time(openNy)==datetime(2026,7,6,15,18,0, ...
    "TimeZone",char(cfg.marketTimezone)));
assert(abs(openTrades.gross_R(openNy)-1.0)<1e-12);

disp("TEST CRT3H REAL DATA INTEGRATION SUPERADO");
