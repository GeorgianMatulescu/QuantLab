clear;
clc;

matlabRoot = fileparts(fileparts(mfilename('fullpath')));
sourcePath = fullfile( ...
    matlabRoot,"Dashboard","Components", ...
    "clearDashboardAxesSafely.m");

source = fileread(sourcePath);

assert(contains(source,"findall("));
assert(contains(source,'"Type",graphicTypes(typeIndex)'));
assert(~contains(source,"allchild("));
assert(~contains(source,'cla(ax,"reset")'));

fprintf("TEST SAFE GRAPHICS RESET SOURCE SCAN SUPERADO\n");
