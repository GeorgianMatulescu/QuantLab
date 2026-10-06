clear;
clc;

matlabRoot = fileparts(fileparts(mfilename('fullpath')));
addpath(genpath(matlabRoot));

fig = uifigure("Visible","off");
cleanup = onCleanup(@() delete(fig));

T = table( ...
    (1:3)', ...
    ["LONG";"SHORT";"LONG"], ...
    'VariableNames',{'Trade','Direction'});

tbl = uitable(fig,"Data",T);

highlightTradeTableRow(tbl,2);

assert(~isempty(tbl.StyleConfigurations), ...
    "No se añadió el estilo de fila.");

clearTradeTableHighlight(tbl);

assert(isempty(tbl.StyleConfigurations), ...
    "No se eliminó el estilo anterior.");

fprintf("TEST TRADE TABLE ROW HIGHLIGHT SUPERADO\n");
