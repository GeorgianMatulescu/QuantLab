function [tradeRow, rowIndex] = resolveTradeSelector(trades, selector)
%RESOLVETRADESELECTOR Selecciona un trade por índice o fecha de sesión.

arguments
    trades table
    selector
end

if isempty(trades)
    error("QuantLab:EmptyTrades", "La tabla de operaciones está vacía.");
end

if isnumeric(selector) && isscalar(selector)
    rowIndex = double(selector);
    if rowIndex < 1 || rowIndex > height(trades) || fix(rowIndex) ~= rowIndex
        error("QuantLab:TradeIndexOutOfRange", ...
            "Índice de trade fuera de rango: %g.", rowIndex);
    end
elseif isdatetime(selector) && isscalar(selector)
    targetDate = dateshift(selector, "start", "day");
    dates = dateshift(trades.session_date, "start", "day");
    rowIndex = find(dates == targetDate, 1, "first");
    if isempty(rowIndex)
        error("QuantLab:TradeDateNotFound", ...
            "No se encontró una fila para la fecha %s.", string(targetDate));
    end
elseif ischar(selector) || (isstring(selector) && isscalar(selector))
    targetDate = datetime(string(selector), "InputFormat", "yyyy-MM-dd");
    dates = dateshift(trades.session_date, "start", "day");
    rowIndex = find(dates == targetDate, 1, "first");
    if isempty(rowIndex)
        error("QuantLab:TradeDateNotFound", ...
            "No se encontró una fila para la fecha %s.", string(targetDate));
    end
else
    error("QuantLab:InvalidTradeSelector", ...
        "Usa un índice numérico o una fecha yyyy-MM-dd.");
end

tradeRow = trades(rowIndex,:);
end
