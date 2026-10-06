clear;
clc;

matlabRoot = fileparts(fileparts(mfilename('fullpath')));
addpath(genpath(matlabRoot));

fig = uifigure("Visible","off");
cleanup = onCleanup(@() delete(fig));

ax = uiaxes(fig);

session_date = datetime(2026,1,1) + caldays((0:5)');
direction = ["LONG";"SHORT";"LONG";"LONG";"SHORT";"SHORT"];

executed = table(session_date,direction);

updateExposureChart(ax,executed);
drawnow nocallbacks;

lines = findall(ax,"Type","line");
displayNames = string(get(lines,"DisplayName"));

palette = getQuantLabPalette();

longLine = lines(displayNames=="Long Ratio");
shortLine = lines(displayNames=="Short Ratio");

assert(numel(longLine)==1);
assert(numel(shortLine)==1);
assert(max(abs(longLine.Color-palette.long))<1e-12);
assert(max(abs(shortLine.Color-palette.short))<1e-12);

fprintf("TEST EXPOSURE FIXED COLORS SUPERADO\n");
