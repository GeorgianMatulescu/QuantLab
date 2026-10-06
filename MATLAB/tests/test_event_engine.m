clear;
clc;

matlabRoot = fileparts(fileparts(mfilename('fullpath')));
addpath(genpath(matlabRoot));

cfg = loadQuantLabConfig(matlabRoot);
[data, ~] = loadMarketData(cfg.dataFile, cfg);
daily = buildDailySessions(data, cfg);

baseEvents = buildBaseMarketEvents(data, cfg);
orbEvents = detectORBEvents(data, daily, cfg);
events = [baseEvents; orbEvents];
events = sortrows(events, ["event_time","bar_index","event_type"]);

validateEventTable(events);

assert(height(filterEvents(events,"NEW_BAR")) == height(data));
assert(height(filterEvents(events,"NEW_SESSION")) == height(daily));
assert(height(filterEvents(events,"SESSION_CLOSED")) == height(daily));
assert(height(filterEvents(events,"ORB_COMPLETED")) == nnz(daily.orb_valid));

fprintf("TEST EVENT ENGINE SUPERADO\n");
disp(groupsummary(events, "event_type", "numel"));
