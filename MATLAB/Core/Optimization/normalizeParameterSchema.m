function schema = normalizeParameterSchema(schema)
%NORMALIZEPARAMETERSCHEMA Normaliza el contrato genérico del optimizador.
%
% Columnas:
%   name, label, type, default_value, minimum, maximum, step,
%   sweep_start, sweep_stop, unit, enabled, optimizable,
%   rebuild_events, description
%
% minimum/maximum son límites de seguridad.
% sweep_start/sweep_stop son el rango sugerido al abrir el dashboard.

arguments
    schema table
end

columnNames = [ ...
    "name","label","type","default_value","minimum","maximum", ...
    "step","sweep_start","sweep_stop","unit","enabled", ...
    "optimizable","rebuild_events","description"];

if isempty(schema)
    schema = table( ...
        strings(0,1),strings(0,1),strings(0,1), ...
        zeros(0,1),zeros(0,1),zeros(0,1),zeros(0,1), ...
        zeros(0,1),zeros(0,1),strings(0,1), ...
        false(0,1),false(0,1),false(0,1),strings(0,1), ...
        'VariableNames',cellstr(columnNames));
    return;
end

n = height(schema);
variables = string(schema.Properties.VariableNames);

stringColumns = ["name","label","type","unit","description"];

for column = stringColumns
    if ~ismember(column,variables)
        schema.(column) = strings(n,1);
    else
        schema.(column) = string(schema.(column));
    end
end

numericColumns = [ ...
    "default_value","minimum","maximum","step", ...
    "sweep_start","sweep_stop"];

for column = numericColumns
    if ~ismember(column,variables)
        schema.(column) = nan(n,1);
    else
        schema.(column) = double(schema.(column));
    end
end

logicalDefaults = struct( ...
    "enabled",true, ...
    "optimizable",true, ...
    "rebuild_events",true);

logicalColumns = ["enabled","optimizable","rebuild_events"];

for column = logicalColumns
    if ~ismember(column,variables)
        schema.(column) = ...
            repmat(logicalDefaults.(column),n,1);
    else
        schema.(column) = logical(schema.(column));
    end
end

schema = schema(:,cellstr(columnNames));
schema.name = strtrim(schema.name);
schema.label = strtrim(schema.label);
schema.type = lower(strtrim(schema.type));

emptyLabels = strlength(schema.label)==0;
schema.label(emptyLabels) = schema.name(emptyLabels);

for i = 1:n
    if ~isfinite(schema.step(i)) || schema.step(i)<=0
        range = schema.maximum(i)-schema.minimum(i);

        if schema.type(i)=="integer"
            schema.step(i) = max(1,round(range/10));
        elseif isfinite(range) && range>0
            schema.step(i) = range/10;
        else
            schema.step(i) = 1;
        end
    end

    if ~isfinite(schema.sweep_start(i))
        schema.sweep_start(i) = schema.minimum(i);
    end

    if ~isfinite(schema.sweep_stop(i))
        schema.sweep_stop(i) = schema.maximum(i);
    end
end

[~,uniqueIndex] = unique(schema.name,"stable");
schema = schema(sort(uniqueIndex),:);
end
