function comparison = compareTradeScenarios(results, selector, referenceProfile)
%COMPARETRADESCENARIOS Compara la misma sesión entre perfiles de ejecución.
%
% El selector puede ser:
% - índice dentro del perfil de referencia;
% - fecha "yyyy-MM-dd";
% - datetime.

arguments
    results (1,1) struct
    selector
    referenceProfile (1,1) string = "REALISTIC"
end

referenceTrades = getScenarioTrades(results, referenceProfile);
[referenceRow, ~] = resolveTradeSelector(referenceTrades, selector);
targetDate = referenceRow.session_date;

fields = string(fieldnames(results));
fields(fields == "summaryTable") = [];

rows = cell(numel(fields),1);
keep = false(numel(fields),1);

for i = 1:numel(fields)
    profile = fields(i);
    trades = getScenarioTrades(results, profile);

    dates = dateshift(trades.session_date, "start", "day");
    idx = find(dates == dateshift(targetDate, "start", "day"), 1, "first");

    if isempty(idx)
        continue;
    end

    t = trades(idx,:);

    rows{i} = table( ...
        string(profile), ...
        t.valid, ...
        string(t.skip_reason), ...
        string(t.direction), ...
        t.entry_price, ...
        t.stop_price, ...
        t.target_price, ...
        t.exit_price, ...
        string(t.exit_reason), ...
        t.contracts, ...
        t.net_R, ...
        t.net_pnl_usd, ...
        'VariableNames', { ...
        'profile','executed','skip_reason','direction', ...
        'entry_price','stop_price','target_price','exit_price', ...
        'exit_reason','contracts','net_R','net_pnl_usd'});
    keep(i) = true;
end

rows = rows(keep);
if isempty(rows)
    comparison = table();
else
    comparison = vertcat(rows{:});
end

fprintf('\n=== COMPARACIÓN DE ESCENARIOS: %s ===\n', string(targetDate));
disp(comparison);
end
