function highlightTradeTableRow(tableHandle,rowIndex)
%HIGHLIGHTTRADETABLEROW Resalta la fila completa del trade seleccionado.
%
% Se elimina el estilo de selección anterior y se aplica inmediatamente un fondo azul
% claro con texto oscuro a toda la fila seleccionada.

arguments
    tableHandle
    rowIndex (1,1) double
end

clearTradeTableHighlight(tableHandle);

if rowIndex < 1
    return;
end

rowStyle = uistyle( ...
    "BackgroundColor",[0.82 0.91 1.00], ...
    "FontColor",[0.05 0.12 0.22], ...
    "FontWeight","bold");

addStyle( ...
    tableHandle, ...
    rowStyle, ...
    "row", ...
    rowIndex);
end
