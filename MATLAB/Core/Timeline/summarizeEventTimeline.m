function summary = summarizeEventTimeline(timeline)
types = unique(string(timeline.event_type));
count = zeros(numel(types),1);
first_time = NaT(numel(types),1,"TimeZone",timeline.event_time.TimeZone);
last_time = NaT(numel(types),1,"TimeZone",timeline.event_time.TimeZone);
for i = 1:numel(types)
    mask = string(timeline.event_type) == types(i);
    count(i) = nnz(mask);
    first_time(i) = timeline.event_time(find(mask,1,"first"));
    last_time(i) = timeline.event_time(find(mask,1,"last"));
end
summary = table(types,count,first_time,last_time, ...
    'VariableNames',{'event_type','count','first_time','last_time'});
end
