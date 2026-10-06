function validateParameterSchema(schema)
%VALIDATEPARAMETERSCHEMA Valida parámetros y rangos sugeridos.

arguments
    schema table
end

schema = normalizeParameterSchema(schema);
allowedTypes = ["numeric","integer"];

if any(strlength(schema.name)==0)
    error("QuantLab:ParameterSchemaName", ...
        "El esquema contiene parámetros sin nombre.");
end

invalidTypes = setdiff(unique(schema.type),allowedTypes);

if ~isempty(invalidTypes)
    error("QuantLab:ParameterSchemaType", ...
        "Tipos no soportados: %s", ...
        strjoin(invalidTypes,", "));
end

invalidBounds = ...
    schema.optimizable & ...
    (~isfinite(schema.minimum) | ...
     ~isfinite(schema.maximum) | ...
     schema.minimum>schema.maximum);

if any(invalidBounds)
    error("QuantLab:ParameterSchemaBounds", ...
        "Hay parámetros optimizables con límites no válidos.");
end

invalidSteps = schema.optimizable & ...
    (~isfinite(schema.step) | schema.step<=0);

if any(invalidSteps)
    error("QuantLab:ParameterSchemaStep", ...
        "Hay parámetros optimizables con un paso no válido.");
end

invalidSweep = schema.optimizable & ...
    (~isfinite(schema.sweep_start) | ...
     ~isfinite(schema.sweep_stop) | ...
     schema.sweep_start<schema.minimum | ...
     schema.sweep_stop>schema.maximum | ...
     schema.sweep_start>schema.sweep_stop);

if any(invalidSweep)
    error("QuantLab:ParameterSchemaSweepRange", ...
        "Hay rangos sugeridos fuera de los límites permitidos.");
end
end
