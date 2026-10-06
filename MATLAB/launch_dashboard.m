clear;
clc;
matlabRoot = string(fileparts(mfilename('fullpath')));
addpath(genpath(matlabRoot));

% Compatibilidad con el acceso antiguo al último CRT/MNQ.
workflow = runQuantLabWorkflow( ...
    "CRT_3H_MADRID","MNQ", ...
    RunBacktest=false,ExportResults=false,OpenDashboard=true); %#ok<NASGU>
