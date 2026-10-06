clear;
clc;

matlabRoot = fileparts(fileparts(mfilename('fullpath')));
addpath(genpath(matlabRoot));

dashboardFile = fullfile( ...
    matlabRoot, ...
    "Dashboard", ...
    "launchQuantLabDashboard.m");

source = fileread(dashboardFile);

highlightPosition = strfind(source, ...
    "highlightTradeTableRow(");

drawnowPosition = strfind(source, ...
    "drawnow;");

researchPosition = strfind(source, ...
    "updateTradeResearchMode(");

assert(~isempty(highlightPosition), ...
    "Falta la llamada de resaltado.");

assert(~isempty(drawnowPosition), ...
    "Falta drawnow para repintado inmediato.");

assert(~isempty(researchPosition), ...
    "Falta la actualización de Research Mode.");

assert(highlightPosition(end) < drawnowPosition(end), ...
    "drawnow debe ejecutarse después del resaltado.");

assert(drawnowPosition(end) < researchPosition(end), ...
    "drawnow debe ejecutarse antes del análisis Research.");

fprintf("TEST TRADE TABLE IMMEDIATE HIGHLIGHT SUPERADO\n");
