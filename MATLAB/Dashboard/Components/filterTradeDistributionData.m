function filtered = filterTradeDistributionData(trades,filterName)
%FILTERTRADEDISTRIBUTIONDATA Filtra operaciones ejecutadas.
%
% Filtros disponibles:
% - ALL
% - LONG / SHORT
% - TARGET / STOP / BREAKEVEN / TRAILING_STOP / EOD

arguments
    trades table
    filterName (1,1) string = "ALL"
end

filtered = trades;

if isempty(trades)
    return;
end

variables = string(trades.Properties.VariableNames);
executedMask = true(height(trades),1);

if ismember("valid",variables)
    executedMask = executedMask & logical(trades.valid);
end

if ismember("contracts",variables)
    executedMask = executedMask & ...
        isfinite(trades.contracts) & trades.contracts>0;
end

filtered = trades(executedMask,:);
filterName = upper(strtrim(filterName));

if isempty(filtered) || filterName=="ALL"
    return;
end

switch filterName
    case {"LONG","SHORT"}
        if ismember("direction",variables)
            filtered = filtered( ...
                upper(string(filtered.direction))==filterName,:);
        else
            filtered = filtered([],:);
        end

    case {"TARGET","STOP","BREAKEVEN","TRAILING_STOP","EOD"}
        if ismember("exit_reason",variables)
            filtered = filtered( ...
                upper(string(filtered.exit_reason))==filterName,:);
        else
            filtered = filtered([],:);
        end

    otherwise
        error( ...
            "QuantLab:UnknownDistributionFilter", ...
            "Filtro de distribución desconocido: %s", ...
            filterName);
end
end
