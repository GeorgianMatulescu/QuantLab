clear;
clc;

matlabRoot = fileparts(fileparts(mfilename('fullpath')));
addpath(genpath(matlabRoot));

fig = uifigure("Visible","off");
cleanup = onCleanup(@() delete(fig));

ax = uiaxes(fig);

lineHandle = plot( ...
    ax,1:3,[1 2 1], ...
    "HandleVisibility","off");

drawnow nocallbacks;

assert(isvalid(lineHandle));
assert(isempty(ax.Children), ...
    "Este test espera que ax.Children oculte el objeto.");

assert(~isempty(findall(ax,"Type","line")), ...
    "findall no encontró la línea oculta.");

clearDashboardAxesSafely(ax);
drawnow nocallbacks;

assert(isempty(findall(ax,"Type","line")), ...
    "La línea con HandleVisibility off no fue eliminada.");

fprintf("TEST HIDDEN GRAPHICS CLEANUP SUPERADO\n");
