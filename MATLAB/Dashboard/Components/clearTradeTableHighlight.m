function clearTradeTableHighlight(tableHandle)
%CLEARTRADETABLEHIGHLIGHT Elimina el resaltado de selección anterior.
%
% El dashboard no aplica otros estilos persistentes a la tabla Trades,
% por lo que se eliminan todos los estilos añadidos mediante uistyle.

arguments
    tableHandle
end

try
    removeStyle(tableHandle);
catch
    % Compatibilidad defensiva con versiones donde no haya estilos activos.
end
end
