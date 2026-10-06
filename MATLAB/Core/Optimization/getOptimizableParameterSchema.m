function schema = getOptimizableParameterSchema(parameterSchema)
%GETOPTIMIZABLEPARAMETERSCHEMA Filtra parámetros utilizables en v0.20.

arguments
    parameterSchema table
end

schema = normalizeParameterSchema(parameterSchema);
validateParameterSchema(schema);

keep = ...
    schema.enabled & ...
    schema.optimizable & ...
    ismember(schema.type,["numeric","integer"]);

schema = schema(keep,:);
end
