clear;
clc;

matlabRoot = fileparts(fileparts(mfilename('fullpath')));
addpath(genpath(matlabRoot));

parameter_1_value = (1:6)';
parameter_2_value = nan(6,1);
parameter_2_name = repmat("",6,1);
executed_trades = 10*ones(6,1);
behavior_signature = ["A";"B";"C";"C";"C";"C"];

results = table( ...
    parameter_1_value,parameter_2_value,parameter_2_name, ...
    executed_trades,behavior_signature);

results = annotateParameterActivity(results);

assert(results.activity_status(2)=="ACTIVE");
assert(results.activity_status(3)=="PLATEAU_EDGE");
assert(all(results.activity_status(4:6)=="INACTIVE_PLATEAU"));
assert(all(results.equivalent_configurations(3:6)==4));

fprintf("TEST PARAMETER ACTIVITY DETECTION SUPERADO\n");
