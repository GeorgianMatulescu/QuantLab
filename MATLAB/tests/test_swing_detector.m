clear; clc;
matlabRoot = fileparts(fileparts(mfilename('fullpath')));
addpath(genpath(matlabRoot));
cfg = loadQuantLabConfig(matlabRoot);
[data,~] = loadMarketData(cfg.dataFile,cfg);
events = detectSwingEvents(data,cfg);
validateEventTable(events);
assert(~isempty(events));
assert(all(ismember(unique(string(events.event_type)), ...
    ["SWING_HIGH","SWING_LOW"])));
for i = 1:height(events)
    payload = events.payload{i};
    assert(events.event_time(i) >= payload.pivot_time);
    assert(events.event_time(i) == payload.confirmation_time);
end
fprintf("TEST SWING DETECTOR SUPERADO\n");
fprintf("Swing highs: %d\n",nnz(string(events.event_type)=="SWING_HIGH"));
fprintf("Swing lows:  %d\n",nnz(string(events.event_type)=="SWING_LOW"));
