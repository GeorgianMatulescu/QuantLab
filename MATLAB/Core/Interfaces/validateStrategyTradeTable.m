function validateStrategyTradeTable(trades,strategyName,profileName)
%VALIDATESTRATEGYTRADETABLE Valida Trade v1 con compatibilidad legada.

arguments
    trades table
    strategyName (1,1) string = "STRATEGY"
    profileName (1,1) string = "PROFILE"
end

if isempty(trades)
    return;
end

required = [ ...
    "valid","profile","session_date","direction", ...
    "entry_time","exit_time","entry_price","exit_price", ...
    "net_R","net_pnl_usd","equity_before_usd", ...
    "equity_after_usd","exit_reason","skip_reason"];

missing = required(~ismember( ...
    required,string(trades.Properties.VariableNames)));

if ~isempty(missing)
    error("QuantLab:TradeContractMissing", ...
        "%s/%s no cumple Trade v1. Faltan: %s", ...
        strategyName,profileName,strjoin(missing,", "));
end

variables = string(trades.Properties.VariableNames);

if ~ismember("quantity",variables) && ~ismember("contracts",variables)
    error("QuantLab:TradeQuantityMissing", ...
        "%s/%s necesita quantity o contracts.", ...
        strategyName,profileName);
end

if ~islogical(trades.valid)
    error("QuantLab:TradeValidType", ...
        "Trade.valid debe ser logical.");
end
end
