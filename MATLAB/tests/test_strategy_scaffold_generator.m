clear; clc;
matlabRoot = fileparts(fileparts(mfilename('fullpath')));
addpath(genpath(matlabRoot));

targetRoot = fullfile(tempdir,"QuantLabStrategyScaffoldTest");
if isfolder(targetRoot), rmdir(targetRoot,"s"); end
mkdir(targetRoot);
cleanup = onCleanup(@() rmdir(targetRoot,"s"));

folder = createBarStrategyScaffold( ...
    "MyTestStrategy","My Test Strategy",targetRoot);
assert(isfile(fullfile(folder,"createMyTestStrategyStrategy.m")));
text = fileread(fullfile(folder,"createMyTestStrategyStrategy.m"));
assert(contains(text,'plugin.enabled = true;'));
assert(contains(text,'plugin.name = "MYTESTSTRATEGY";'));

fprintf("TEST STRATEGY SCAFFOLD GENERATOR SUPERADO\n");
