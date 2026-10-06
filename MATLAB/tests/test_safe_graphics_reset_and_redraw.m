clear;
clc;

matlabRoot = fileparts(fileparts(mfilename('fullpath')));
addpath(genpath(matlabRoot));

fig = uifigure("Visible","off");
cleanup = onCleanup(@() delete(fig));

ax = uiaxes(fig);

hold(ax,"on");

plot(ax,1:4,[1 2 1 3], ...
    "HandleVisibility","off");

area(ax,1:4,[0 -1 -2 -1], ...
    "HandleVisibility","off");

xline(ax,2,"--", ...
    "HandleVisibility","off");

text(ax,2,2.5,"TEST", ...
    "HandleVisibility","off");

drawnow nocallbacks;

assert(countDashboardPrimitives(ax)>0, ...
    "No se crearon objetos gráficos de prueba.");

resetDashboardAxes(ax);
drawnow nocallbacks;

assert(countDashboardPrimitives(ax)==0, ...
    "resetDashboardAxes no eliminó las primitivas anteriores.");

% El mismo UIAxes debe poder dibujar otra vez después de limpiarse.
plot(ax,1:3,[3 1 2], ...
    "LineWidth",1.2);

drawnow nocallbacks;

assert(countDashboardPrimitives(ax)>0, ...
    "El eje no pudo volver a dibujar después del reset seguro.");

resetResearchAxes(ax);
drawnow nocallbacks;

assert(countDashboardPrimitives(ax)==0, ...
    "resetResearchAxes no limpió el eje.");

plot(ax,1:3,[1 3 2], ...
    "HandleVisibility","off");

drawnow nocallbacks;

assert(countDashboardPrimitives(ax)>0, ...
    "Research no pudo redibujar después de la limpieza.");

fprintf("TEST SAFE GRAPHICS RESET AND REDRAW SUPERADO\n");

function count = countDashboardPrimitives(ax)
types = [ ...
    "line"; ...
    "area"; ...
    "bar"; ...
    "histogram"; ...
    "scatter"; ...
    "text"; ...
    "constantline"; ...
    "image"; ...
    "surface"; ...
    "patch"; ...
    "rectangle"; ...
    "quiver"; ...
    "errorbar"; ...
    "stem"];

count = 0;

for i = 1:numel(types)
    count = count + numel(findall(ax,"Type",types(i)));
end
end
