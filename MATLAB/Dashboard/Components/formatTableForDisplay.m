function displayTable = formatTableForDisplay(sourceTable)
%FORMATTABLEFORDISPLAY Convierte números a texto legible para UITable.
%
% Evita representaciones como 2.4315e+04. La tabla de origen no se
% modifica; solo se genera una copia destinada a presentación.
%
% Formatos:
% - precios, equity y PnL: 2 decimales;
% - R y porcentajes: 3 decimales;
% - contratos e identificadores: enteros;
% - NaN: cadena vacía.

arguments
    sourceTable table
end

displayTable = sourceTable;
names = string(displayTable.Properties.VariableNames);

priceFields = [ ...
    "order_price","entry_level","entry_level_50","manipulation_extreme", ...
    "crt_high","crt_low","entry_price","entry_price_raw", ...
    "stop_price","target_price", ...
    "exit_price","orb_open","orb_high","orb_low","orb_close", ...
    "orb_range_points","risk_points","mfe_points","mae_points"];

moneyFields = [ ...
    "risk_budget_usd","risk_per_contract_usd", ...
    "effective_risk_usd","gross_pnl_usd","commission_usd", ...
    "net_pnl_usd","equity_before_usd","equity_after_usd"];

ratioFields = [ ...
    "gross_R","net_R","mfe_R","mae_R", ...
    "risk_utilization_pct","entry_fraction","reward_risk_planned"];

quantityFields = ["quantity","contracts"];

integerFields = [ ...
    "bars_held","con_id","barCount"];

for i = 1:numel(names)
    name = names(i);
    value = displayTable.(name);

    if ~isnumeric(value)
        continue;
    end

    if ismember(name,quantityFields)
        displayTable.(name) = formatNumericColumn(value,"%.6f");
        displayTable.(name) = stripTrailingZeros(displayTable.(name));

    elseif ismember(name,integerFields)
        displayTable.(name) = formatNumericColumn(value,"%.0f");

    elseif ismember(name,ratioFields)
        displayTable.(name) = formatNumericColumn(value,"%.3f");

    elseif ismember(name,priceFields) || ismember(name,moneyFields)
        displayTable.(name) = formatNumericColumn(value,"%.2f");

    else
        displayTable.(name) = formatNumericColumn(value,"%.2f");
    end
end
end

function output = formatNumericColumn(values,formatSpec)
output = strings(size(values));

for j = 1:numel(values)
    if isfinite(values(j))
        output(j) = string(sprintf(formatSpec,values(j)));
    else
        output(j) = "";
    end
end
end


function output = stripTrailingZeros(values)
output = string(values);
for i = 1:numel(output)
    if strlength(output(i))==0, continue; end
    output(i) = regexprep(output(i),'0+$','');
    output(i) = regexprep(output(i),'\.$','');
end
end
