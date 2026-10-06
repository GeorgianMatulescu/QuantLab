function showTradeResearchLoading(titleLabel,tradeIndex)
%SHOWTRADERESEARCHLOADING Muestra respuesta visual inmediata al clic.
%
% No limpia ni modifica el eje. La limpieza se realiza una sola vez dentro
% de updateTradeResearchMode. Así se evita el doble reset consecutivo y
% posibles problemas de repintado/reentrada de callbacks.

titleLabel.Text = sprintf( ...
    "Cargando Trade #%d...", ...
    tradeIndex);

% Repinta solo los cambios gráficos imprescindibles, sin ejecutar otros
% callbacks que puedan reentrar en la selección de la tabla.
drawnow limitrate nocallbacks;
end
