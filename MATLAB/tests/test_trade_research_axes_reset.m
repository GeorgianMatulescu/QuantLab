clear;
clc;

matlabRoot = fileparts(fileparts(mfilename('fullpath')));
addpath(genpath(matlabRoot));

fig = uifigure("Visible","off");
cleanup = onCleanup(@() delete(fig));

ax = uiaxes(fig);

hold(ax,"on");

line1 = yline(ax,100,"--", ...
    "HandleVisibility","off"); %#ok<NASGU>

line2 = plot(ax,1,2,"^", ...
    "HandleVisibility","off"); %#ok<NASGU>

assert(~isempty(allchild(ax)), ...
    "No se pudieron crear objetos de prueba.");

resetResearchAxes(ax);

assert(isempty(allchild(ax)), ...
    "resetResearchAxes no eliminó todos los objetos.");

fprintf("TEST TRADE RESEARCH AXES RESET SUPERADO\n");
