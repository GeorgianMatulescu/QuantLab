function timeline = buildEventTimeline(events)
validateEventTable(events);
timeline = sortrows(events,["event_time","bar_index","event_type"]);
timeline.timeline_index = (1:height(timeline))';
timeline = movevars(timeline,"timeline_index","Before",1);
end
