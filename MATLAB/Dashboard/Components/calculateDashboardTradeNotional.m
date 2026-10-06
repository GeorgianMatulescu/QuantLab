function notional = calculateDashboardTradeNotional(trades,cfg)
%CALCULATEDASHBOARDTRADENOTIONAL Notional genérico por operación.
%
% Funciona con futuros, acciones, Forex y cripto usando el multiplicador
% normalizado del InstrumentSpec y la cantidad canónica del trade.

arguments
    trades table
    cfg (1,1) struct
end

if isempty(trades)
    notional = zeros(0,1);
    return;
end

spec = normalizeInstrumentSpec(cfg);
quantity = getDashboardTradeQuantity(trades);
notional = abs(double(trades.entry_price) .* quantity .* ...
    spec.contractMultiplier);
notional = notional(:);
end
