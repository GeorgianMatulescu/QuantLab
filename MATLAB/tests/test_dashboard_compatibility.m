clear;
clc;

matlabRoot = fileparts(fileparts(mfilename('fullpath')));
addpath(genpath(matlabRoot));

S = loadAuditWorkspace(matlabRoot, "ORB");

strategyRun = buildStrategyResult( ...
    "ORB", ...
    S.results, ...
    S.cfg, ...
    S.data);

validateStrategyResult(strategyRun);

profiles = getDashboardProfiles(strategyRun.results);
assert(~isempty(profiles), ...
    "No se encontraron perfiles compatibles.");

for i = 1:numel(profiles)
    scenario = getDashboardScenario( ...
        strategyRun.results, profiles(i));

    assert(istable(scenario.trades), ...
        "El escenario no contiene una tabla de trades.");

    executed = scenario.trades(scenario.trades.valid,:);

    if ~isempty(executed)
        assert(all(isfinite(executed.net_pnl_usd)), ...
            "Hay PnL no finito.");
        assert(all(isfinite(executed.net_R)), ...
            "Hay resultados R no finitos.");
    end
end

% Formatos compatibles con componentes UI.
dropdownItems = reshape(string(profiles), 1, []);
assert(isstring(dropdownItems) && size(dropdownItems,1) == 1);

textAreaValue = reshape([ ...
    "QuantLab Research", ...
    "", ...
    "Métricas no disponibles: N/A"], [], 1);

assert(isstring(textAreaValue) && size(textAreaValue,2) == 1);

variableNames = {'Metric','Value','Metric2','Value2'};
assert(iscellstr(variableNames)); %#ok<ISCLSTR>

fprintf("TEST DASHBOARD COMPATIBILITY SUPERADO\n");
fprintf("Perfiles compatibles: %d\n", numel(profiles));
