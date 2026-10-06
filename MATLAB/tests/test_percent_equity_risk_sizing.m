clear;
clc;

matlabRoot = fileparts(fileparts(mfilename('fullpath')));
addpath(genpath(matlabRoot));

cfg = loadQuantLabConfig(matlabRoot);

assert(string(cfg.risk.mode)=="PERCENT_EQUITY");
assert(abs(cfg.risk.percentRisk-0.01)<1e-12);
assert(cfg.risk.initialEquityUSD==50000);
assert(cfg.risk.maximumQuantity==40);
assert(cfg.risk.maximumContracts==40);
assert(cfg.instrumentSpec.maximumQuantity==40);

% MNQ vale 2 USD por punto y contrato. Con un stop de 20 puntos,
% cada contrato arriesga 40 USD.
initialSizing = calculatePositionSize(20,50000,cfg);
assert(abs(initialSizing.riskBudgetUSD-500)<1e-12);
assert(initialSizing.quantity==12);
assert(abs(initialSizing.effectiveRiskUSD-480)<1e-12);
assert(initialSizing.effectiveRiskUSD<=initialSizing.riskBudgetUSD);

% El presupuesto y los contratos aumentan cuando aumenta la equity.
higherEquitySizing = calculatePositionSize(20,52000,cfg);
assert(abs(higherEquitySizing.riskBudgetUSD-520)<1e-12);
assert(higherEquitySizing.quantity==13);
assert(abs(higherEquitySizing.effectiveRiskUSD-520)<1e-12);

% El presupuesto disminuye junto con la equity.
lowerEquitySizing = calculatePositionSize(20,48000,cfg);
assert(abs(lowerEquitySizing.riskBudgetUSD-480)<1e-12);
assert(lowerEquitySizing.quantity==12);
assert(abs(lowerEquitySizing.effectiveRiskUSD-480)<1e-12);

% El límite de seguridad vigente impide superar 40 contratos aunque el
% riesgo porcentual permitiera una posición mayor.
cappedSizing = calculatePositionSize(5,50000,cfg);
assert(cappedSizing.quantity==40);
assert(abs(cappedSizing.effectiveRiskUSD-400)<1e-12);
assert(cappedSizing.effectiveRiskUSD<=cappedSizing.riskBudgetUSD);

fprintf("TEST PERCENT EQUITY RISK SIZING SUPERADO\n");
