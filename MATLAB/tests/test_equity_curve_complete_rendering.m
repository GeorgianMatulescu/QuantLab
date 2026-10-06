clear;
clc;

matlabRoot = fileparts(fileparts(mfilename('fullpath')));
addpath(genpath(matlabRoot));

source = fileread(fullfile( ...
    matlabRoot,"Dashboard","Components", ...
    "updateEquityCharts.m"));

assert(contains(source,'cla(equityAxes,"reset")'), ...
    "El eje de equity no restablece zoom y límites anteriores.");

assert(contains(source,"insertZeroCrossings"), ...
    "No se insertan cruces exactos por 0 %%.");

assert(contains(source,"crossingDate"), ...
    "No se calcula la fecha exacta del cruce.");

assert(contains(source, ...
    "xlim(equityAxes,[plotDates(1) plotDates(end)])"), ...
    "El eje X no se fuerza al histórico completo.");

assert(contains(source,"positiveLine(positiveLine<0) = NaN"));
assert(contains(source,"negativeLine(negativeLine>0) = NaN"));

fprintf("TEST EQUITY CURVE COMPLETE RENDERING SUPERADO\n");
