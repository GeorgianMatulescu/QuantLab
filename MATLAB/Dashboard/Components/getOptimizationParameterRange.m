function range = getOptimizationParameterRange(schema,parameterName)
%GETOPTIMIZATIONPARAMETERRANGE Devuelve el barrido sugerido.

arguments
    schema table
    parameterName (1,1) string
end

schema = getOptimizableParameterSchema(schema);
row = schema(schema.name==parameterName,:);

if isempty(row)
    range = struct( ...
        "start",NaN,"stop",NaN,"step",NaN, ...
        "type","numeric","label","");
    return;
end

range = struct( ...
    "start",row.sweep_start(1), ...
    "stop",row.sweep_stop(1), ...
    "step",row.step(1), ...
    "type",row.type(1), ...
    "label",row.label(1));
end
