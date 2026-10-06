function quantity = getDashboardTradeQuantity(trades)
%GETDASHBOARDTRADEQUANTITY Lee quantity con compatibilidad contracts.

arguments
    trades table
end

variables = string(trades.Properties.VariableNames);

if ismember("quantity",variables)
    quantity = double(trades.quantity);
elseif ismember("contracts",variables)
    quantity = double(trades.contracts);
else
    quantity = zeros(height(trades),1);
end

quantity = quantity(:);
end
