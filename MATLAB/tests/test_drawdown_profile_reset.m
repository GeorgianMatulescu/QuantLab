clear;
clc;

matlabRoot = fileparts(fileparts(mfilename('fullpath')));
addpath(genpath(matlabRoot));

fig = uifigure("Visible","off");
cleanup = onCleanup(@() delete(fig));

ax = uiaxes(fig);

% Objetos ocultos equivalentes a línea y sombreado de un perfil anterior.
hold(ax,"on");

area(ax,1:3,[0 -1 -2], ...
    "HandleVisibility","off");

plot(ax,1:3,[0 -1 -2], ...
    "HandleVisibility","off");

yline(ax,0, ...
    "HandleVisibility","off");

assert(~isempty(allchild(ax)), ...
    "No se crearon objetos de prueba.");

resetDashboardAxes(ax);

assert(isempty(allchild(ax)), ...
    "El eje conserva objetos del perfil anterior.");

source = fileread(fullfile( ...
    matlabRoot,"Dashboard","Components", ...
    "updateDrawdownChart.m"));

assert(contains(source, ...
    "resetDashboardAxes(drawdownAxes)"), ...
    "Drawdown no utiliza la limpieza completa.");

fprintf("TEST DRAWDOWN PROFILE RESET SUPERADO\n");
