function outputConfig = applyOptimizationParameters(baseConfig,parameterSet)
%APPLYOPTIMIZATIONPARAMETERS Aplica rutas genéricas a una configuración.
%
% parameterSet debe ser una tabla con:
%   name, value

arguments
    baseConfig (1,1) struct
    parameterSet table
end

required = ["name","value"];

if ~all(ismember(required, ...
        string(parameterSet.Properties.VariableNames)))
    error("QuantLab:InvalidParameterSet", ...
        "parameterSet debe contener name y value.");
end

outputConfig = baseConfig;

for i = 1:height(parameterSet)
    path = string(parameterSet.name(i));
    value = parameterSet.value(i);
    parts = split(path,".");

    outputConfig = setNestedValue( ...
        outputConfig,parts,value);
end
end

function output = setNestedValue(input,parts,value)
fieldName = char(parts(1));
output = input;

if numel(parts)==1
    output.(fieldName) = value;
    return;
end

if ~isfield(output,fieldName) || ...
        ~isstruct(output.(fieldName))
    output.(fieldName) = struct();
end

output.(fieldName) = setNestedValue( ...
    output.(fieldName),parts(2:end),value);
end
