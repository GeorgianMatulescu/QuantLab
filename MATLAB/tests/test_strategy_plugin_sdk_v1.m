clear; clc;
matlabRoot = fileparts(fileparts(mfilename('fullpath')));
addpath(genpath(matlabRoot));

registry = getStrategyRegistry();
for i = 1:numel(registry)
    plugin = registry(i).factory();
    validateStrategyPlugin(plugin);
end

orb = resolveStrategyPlugin("ORB");
ema = resolveStrategyPlugin("EMA_CROSS");
assert(orb.dataContractVersion=="BAR_V1");
assert(ema.tradeContractVersion=="TRADE_V1");

fprintf("TEST STRATEGY PLUGIN SDK V1 SUPERADO\n");
