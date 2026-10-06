function catalog = normalizeFeatureCatalog(catalog)
%NORMALIZEFEATURECATALOG Normaliza el contrato de características.
%
% Columnas:
%   name, label, type, unit, role, default_grouping,
%   enabled, source, description

arguments
    catalog table
end

required = [ ...
    "name","label","type","unit","role", ...
    "default_grouping","enabled","source","description"];

if isempty(catalog)
    catalog = table( ...
        strings(0,1),strings(0,1),strings(0,1), ...
        strings(0,1),strings(0,1),strings(0,1), ...
        false(0,1),strings(0,1),strings(0,1), ...
        'VariableNames',cellstr(required));
    return;
end

n = height(catalog);
variables = string(catalog.Properties.VariableNames);

stringDefaults = struct( ...
    "name","", ...
    "label","", ...
    "type","numeric", ...
    "unit","", ...
    "role","input", ...
    "default_grouping","Auto", ...
    "source","trade", ...
    "description","");

stringColumns = [ ...
    "name","label","type","unit","role", ...
    "default_grouping","source","description"];

for column = stringColumns
    if ~ismember(column,variables)
        catalog.(column) = repmat(stringDefaults.(column),n,1);
    else
        catalog.(column) = string(catalog.(column));
    end
end

if ~ismember("enabled",variables)
    catalog.enabled = true(n,1);
else
    catalog.enabled = logical(catalog.enabled);
end

catalog = catalog(:,cellstr(required));
catalog.name = lower(strtrim(catalog.name));
catalog.type = lower(strtrim(catalog.type));
catalog.role = lower(strtrim(catalog.role));

emptyLabel = strlength(catalog.label)==0;
catalog.label(emptyLabel) = catalog.name(emptyLabel);

emptyGrouping = strlength(catalog.default_grouping)==0;
catalog.default_grouping(emptyGrouping) = "Auto";

[~,uniqueIndex] = unique(catalog.name,"stable");
catalog = catalog(sort(uniqueIndex),:);
end
