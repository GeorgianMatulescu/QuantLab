function catalog = getAvailableFeatureCatalog(baseCatalog,trades)
%GETAVAILABLEFEATURECATALOG Filtra variables presentes y utilizables.

arguments
    baseCatalog table
    trades table
end

researchTable = buildResearchFeatureTable(trades);

if isempty(baseCatalog)
    baseCatalog = inferFeatureCatalog(trades);
end

baseCatalog = normalizeFeatureCatalog(baseCatalog);
variables = lower(string(researchTable.Properties.VariableNames));

keep = false(height(baseCatalog),1);

for i = 1:height(baseCatalog)
    name = baseCatalog.name(i);
    columnIndex = find(variables==name,1,"first");

    if isempty(columnIndex) || ~baseCatalog.enabled(i) || ...
            ~ismember(baseCatalog.role(i),["input","context"])
        continue;
    end

    values = researchTable.( ...
        researchTable.Properties.VariableNames{columnIndex});

    keep(i) = hasVariation(values,baseCatalog.type(i));
end

catalog = baseCatalog(keep,:);
end

function result = hasVariation(values,featureType)
result = false;

switch featureType
    case "numeric"
        values = values(isfinite(values));
        result = numel(unique(values))>=2;

    case {"categorical","boolean"}
        if iscategorical(values) || iscellstr(values)
            values = string(values);
        end

        values = values(~ismissing(values));
        result = numel(unique(values))>=2;

    otherwise
        result = false;
end
end
