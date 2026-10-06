function [events,context] = buildTemplateBarContext(data,cfg)
%BUILDTEMPLATEBARCONTEXT Replace with strategy-specific features/signals.

data = ensureCanonicalBarData(data,cfg);
events = buildBaseMarketEvents(data,cfg);
grouped = groupBarDataBySession(data,cfg);
context = struct( ...
    "daily",buildGenericSessionSummary(data,cfg), ...
    "session_dates",grouped.session_dates, ...
    "session_data",{grouped.session_data});
end
