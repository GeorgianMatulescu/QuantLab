function grouped = groupBarDataBySession(data,cfg)
%GROUPBARDATABYSESSION Índices y tablas por sesión reutilizables.

data = ensureCanonicalBarData(data,cfg);
data = sortrows(data,"datetime_local");
[ids,dates] = findgroups(data.session_date);
sessions = cell(numel(dates),1);

for i = 1:numel(dates)
    sessions{i} = data(ids==i,:);
end

grouped = struct( ...
    "data",data, ...
    "session_dates",dates, ...
    "session_data",{sessions});
end
