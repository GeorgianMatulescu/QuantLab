clear;
clc;
matlabRoot = string(fileparts(mfilename('fullpath')));
addpath(genpath(matlabRoot));

% Wrapper legado. El flujo recomendado es ejecutar `quantlab`.
workflow = runQuantLabWorkflow( ...
    "SESSION_RANGE_MADRID","MNQ", ...
    RunBacktest=false,ExportResults=false,OpenDashboard=true); %#ok<NASGU>
