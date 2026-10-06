clear; clc;
matlabRoot = fileparts(fileparts(mfilename('fullpath')));
addpath(genpath(matlabRoot));

cfg = loadQuantLabConfig(matlabRoot);
tick = cfg.instrumentSpec.tickSize;

assert(tick==0.25);
assert(cfg.crt3h.london.thresholdPoints==tick);
assert(cfg.crt3h.newYork.thresholdPoints==tick);

schema = buildCRT3HParameterSchema();
londonRow = schema.name=="crt3h.london.thresholdPoints";
newYorkRow = schema.name=="crt3h.newYork.thresholdPoints";

assert(nnz(londonRow)==1);
assert(nnz(newYorkRow)==1);
assert(schema.default_value(londonRow)==tick);
assert(schema.default_value(newYorkRow)==tick);
assert(schema.step(londonRow)==tick);
assert(schema.step(newYorkRow)==tick);

plugin = createCRT3HStrategy();
assert(plugin.version=="1.10.0");

fprintf("TEST CRT3H MINIMUM TICK THRESHOLD SUPERADO\n");
