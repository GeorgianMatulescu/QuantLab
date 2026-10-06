clear;
clc;
matlabRoot = string(fileparts(mfilename('fullpath')));
addpath(genpath(matlabRoot));

% Acceso histórico: conserva el backtest CRT/MNQ sin abrir el dashboard.
% Para seleccionar estrategia e instrumento visualmente, ejecuta `quantlab`.
workflow = runQuantLabWorkflow( ...
    "CRT_3H_MADRID","MNQ", ...
    RunBacktest=true,ExportResults=true,OpenDashboard=false); %#ok<NASGU>

fprintf('\nMAIN terminado. Ejecuta `quantlab` para usar el selector universal.\n');
