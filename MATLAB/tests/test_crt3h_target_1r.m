clear; clc;
matlabRoot = fileparts(fileparts(mfilename('fullpath')));
addpath(genpath(matlabRoot));

cfg = loadQuantLabConfig(matlabRoot);
assert(cfg.crt3h.entryFraction==0.75);
assert(cfg.crt3h.rewardRisk==0.5);
assert(cfg.crt3h.rulesVersion=="CRT3H_ENTRY_075_RR_050");

schema = buildCRT3HParameterSchema();
entryRow = schema.name=="crt3h.entryFraction";
assert(nnz(entryRow)==1);
assert(schema.default_value(entryRow)==0.75);
assert(schema.unit(entryRow)=="fraction");
assert(schema.optimizable(entryRow));
targetRow = schema.name=="crt3h.rewardRisk";
assert(nnz(targetRow)==1);
assert(schema.default_value(targetRow)==0.5);
assert(schema.unit(targetRow)=="R");
assert(schema.optimizable(targetRow));

exitNames = upper(string({cfg.crt3h.exitManagementScenarios.name}));
assert(isequal(exitNames,["FIXED_TARGET","SWING_TRAILING_STEP_TARGET"]));
assert(cfg.crt3h.exitManagement.trailing.activationR==1.5);

source = fileread(fullfile(matlabRoot, ...
    "Strategies","CRT3H","runCRT3HScenario.m"));
assert(contains(source,"entry+rewardRisk*risk"));
assert(contains(source,"entry-rewardRisk*risk"));
assert(~contains(source,"min(entry+(entry-stop),crtHigh)"));
assert(~contains(source,"max(entry-(stop-entry),crtLow)"));

fprintf("TEST CRT3H ENTRY 075 TARGET 05R SUPERADO\n");
