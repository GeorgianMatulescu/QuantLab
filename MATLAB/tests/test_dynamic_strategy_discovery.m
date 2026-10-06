clear; clc;
matlabRoot = fileparts(fileparts(mfilename('fullpath')));
addpath(genpath(matlabRoot));

registry = getStrategyRegistry();
names = string({registry.name});
assert(any(names=="ORB"));
assert(any(names=="EMA_CROSS"));
assert(any(names=="TEMPLATE_BAR"));
assert(registry(names=="ORB").enabled);
assert(registry(names=="EMA_CROSS").enabled);
assert(~registry(names=="TEMPLATE_BAR").enabled);

source = fileread(fullfile(matlabRoot,"Core","Engine","getStrategyRegistry.m"));
assert(~contains(source,'"ORB"'));
assert(contains(source,"discoverStrategyPlugins"));

fprintf("TEST DYNAMIC STRATEGY DISCOVERY SUPERADO\n");
