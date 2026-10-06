function sessionData = buildORBSessionDataCache(data,daily)
%BUILDORBSESSIONDATACACHE Preagrupa las barras por sesión una sola vez.
%
% Evita filtrar toda la tabla de mercado para cada sesión y para cada
% combinación del optimizador.

arguments
    data table
    daily table
end

sessionData = cell(height(daily),1);

if isempty(data) || isempty(daily)
    return;
end

data = sortrows( ...
    data,["session_date_new_york","datetime_new_york"]);

dataKeys = string( ...
    data.session_date_new_york,"yyyyMMdd");
dailyKeys = string( ...
    daily.session_date,"yyyyMMdd");

[groupId,groupKeys] = findgroups(dataKeys);
groupRows = cell(numel(groupKeys),1);

for groupIndex = 1:numel(groupKeys)
    groupRows{groupIndex} = find(groupId==groupIndex);
end

keyToGroup = containers.Map( ...
    cellstr(groupKeys), ...
    num2cell(1:numel(groupKeys)));

for i = 1:height(daily)
    key = char(dailyKeys(i));

    if isKey(keyToGroup,key)
        rows = groupRows{keyToGroup(key)};
        sessionData{i} = data(rows,:);
    else
        sessionData{i} = data([],:);
    end
end
end
