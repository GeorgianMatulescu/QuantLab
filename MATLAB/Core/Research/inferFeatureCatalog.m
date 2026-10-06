function catalog = inferFeatureCatalog(trades)
%INFERFEATURECATALOG Infiere variables analizables sin conocer la estrategia.
%
% La inferencia es deliberadamente conservadora:
% - excluye outcomes y métricas posteriores al trade;
% - excluye identificadores, fechas y precios absolutos;
% - incorpora variables temporales derivadas;
% - una estrategia puede sobrescribir cualquier clasificación.

arguments
    trades table
end

researchTable = buildResearchFeatureTable(trades);
variables = string(researchTable.Properties.VariableNames);

rows = cell(0,9);

for i = 1:numel(variables)
    name = lower(variables(i));
    values = researchTable.(variables(i));

    [featureType,supported] = inferType(values);

    if ~supported
        continue;
    end

    role = inferRole(name);
    enabled = ismember(role,["input","context"]);

    if featureType=="categorical"
        uniqueCount = countUniqueValues(values);

        if uniqueCount<2 || uniqueCount>30
            enabled = false;
        end
    elseif featureType=="numeric"
        finiteValues = values(isfinite(values));

        if numel(unique(finiteValues))<2
            enabled = false;
        end
    elseif featureType=="boolean"
        if numel(unique(values(~ismissing(values))))<2
            enabled = false;
        end
    else
        enabled = false;
    end

    label = humanizeFeatureName(name);
    unit = inferUnit(name);

    if ismember(featureType,["categorical","boolean"])
        grouping = "Categories";
    else
        grouping = "Auto";
    end

    source = "trade";

    if ismember(name,[ ...
            "day_of_week","month_name","year_number", ...
            "quarter","entry_hour","duration_minutes"])
        source = "derived";
    end

    rows(end+1,:) = { ...
        name,label,featureType,unit,role,grouping, ...
        enabled,source,"Automatically inferred"}; %#ok<AGROW>
end

if isempty(rows)
    catalog = normalizeFeatureCatalog(table());
    return;
end

catalog = cell2table(rows, ...
    'VariableNames',{ ...
    'name','label','type','unit','role', ...
    'default_grouping','enabled','source','description'});

catalog = normalizeFeatureCatalog(catalog);
end

function [featureType,supported] = inferType(values)
supported = true;

if isnumeric(values)
    featureType = "numeric";
elseif islogical(values)
    featureType = "boolean";
elseif isstring(values) || iscategorical(values) || iscellstr(values)
    featureType = "categorical";
elseif isdatetime(values)
    featureType = "datetime";
else
    featureType = "";
    supported = false;
end
end

function role = inferRole(name)
outcomeTokens = [ ...
    "net_r","gross_r","net_pnl","gross_pnl","pnl", ...
    "mfe","mae","equity_after","equity_before", ...
    "commission","exit_reason","exit_price","exit_time", ...
    "skip_reason","valid","bars_held","duration_minutes", ...
    "profit","return"];

identifierTokens = [ ...
    "session_date","datetime","symbol","local_symbol", ...
    "con_id","trade_id","profile"];

absolutePriceTokens = [ ...
    "entry_price","stop_price","target_price", ...
    "orb_open","orb_high","orb_low","orb_close", ...
    "open","high","low","close","average"];

if any(contains(name,outcomeTokens))
    role = "outcome";
elseif any(contains(name,identifierTokens))
    role = "identifier";
elseif any(name==absolutePriceTokens) || endsWith(name,"_price")
    role = "execution";
elseif ismember(name,[ ...
        "day_of_week","month_name","year_number", ...
        "quarter","entry_hour"])
    role = "context";
else
    role = "input";
end
end

function unit = inferUnit(name)
if endsWith(name,"_usd")
    unit = "USD";
elseif endsWith(name,"_pct") || contains(name,"percent")
    unit = "%";
elseif endsWith(name,"_points")
    unit = "points";
elseif endsWith(name,"_minutes")
    unit = "min";
elseif endsWith(name,"_hour")
    unit = "hour";
elseif endsWith(name,"_r") || name=="r"
    unit = "R";
elseif contains(name,"contracts")
    unit = "contracts";
else
    unit = "";
end
end

function label = humanizeFeatureName(name)
words = split(replace(name,"_"," "));
words = upper(extractBefore(words,2)) + extractAfter(words,1);
label = strjoin(words," ");

label = replace(label,"Orb","ORB");
label = replace(label,"Usd","USD");
label = replace(label,"Atr","ATR");
label = replace(label,"Mfe","MFE");
label = replace(label,"Mae","MAE");
end

function count = countUniqueValues(values)
if iscategorical(values)
    values = string(values);
elseif iscellstr(values)
    values = string(values);
end

values = values(~ismissing(values));
count = numel(unique(values));
end
