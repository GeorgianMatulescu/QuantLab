function audit = inspectTrade(results, selector, profileName)
%INSPECTTRADE Muestra y devuelve la ficha completa de una operación.
%
% Ejemplos:
%   inspectTrade(results, 12, "REALISTIC")
%   inspectTrade(results, "2025-10-15", "REALISTIC")

arguments
    results (1,1) struct
    selector
    profileName (1,1) string = "REALISTIC"
end

trades = getScenarioTrades(results, profileName);
[tradeRow, rowIndex] = resolveTradeSelector(trades, selector);

audit = tradeRow;
audit.trade_index = rowIndex;
audit.profile_requested = profileName;

fprintf('\n=== TRADE INSPECTOR ===\n');
fprintf('Perfil:             %s\n', profileName);
fprintf('Índice:             %d\n', rowIndex);
fprintf('Fecha:              %s\n', string(tradeRow.session_date));
fprintf('Válido/ejecutado:   %d\n', tradeRow.valid);
fprintf('Dirección:          %s\n', string(tradeRow.direction));

if ~tradeRow.valid
    fprintf('Motivo descarte:    %s\n', string(tradeRow.skip_reason));
    fprintf('Riesgo presupuesto: %.2f USD\n', tradeRow.risk_budget_usd);
    fprintf('Riesgo/contrato:    %.2f USD\n', tradeRow.risk_per_contract_usd);
    return;
end

fprintf('Entrada:            %.2f\n', tradeRow.entry_price);
fprintf('Stop:               %.2f\n', tradeRow.stop_price);
fprintf('Target:             %.2f\n', tradeRow.target_price);
fprintf('Salida:              %.2f\n', tradeRow.exit_price);
fprintf('Motivo salida:       %s\n', string(tradeRow.exit_reason));
fprintf('Contratos:           %d\n', tradeRow.contracts);
fprintf('Riesgo efectivo:     %.2f USD\n', tradeRow.effective_risk_usd);
fprintf('PnL bruto:           %.2f USD\n', tradeRow.gross_pnl_usd);
fprintf('Comisiones:          %.2f USD\n', tradeRow.commission_usd);
fprintf('PnL neto:            %.2f USD\n', tradeRow.net_pnl_usd);
fprintf('Resultado:           %.3f R\n', tradeRow.net_R);
fprintf('MFE:                 %.3f R\n', tradeRow.mfe_R);
fprintf('MAE:                 %.3f R\n', tradeRow.mae_R);
fprintf('Equity antes:        %.2f USD\n', tradeRow.equity_before_usd);
fprintf('Equity después:      %.2f USD\n', tradeRow.equity_after_usd);
end
