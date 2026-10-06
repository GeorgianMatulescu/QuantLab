function request = buildOptimizationRequest( ...
    parameterSchema,firstName,firstStart,firstStop,firstStep, ...
    secondName,secondStart,secondStop,secondStep)
%BUILDOPTIMIZATIONREQUEST Valida los controles del dashboard.

arguments
    parameterSchema table
    firstName (1,1) string
    firstStart (1,1) double
    firstStop (1,1) double
    firstStep (1,1) double
    secondName (1,1) string = ""
    secondStart (1,1) double = NaN
    secondStop (1,1) double = NaN
    secondStep (1,1) double = NaN
end

schema = getOptimizableParameterSchema(parameterSchema);

if strlength(firstName)==0
    error("QuantLab:OptimizationFirstParameter", ...
        "Selecciona el primer parámetro.");
end

if strlength(secondName)>0 && firstName==secondName
    error("QuantLab:OptimizationDuplicateParameter", ...
        "Los dos parámetros deben ser diferentes.");
end

names = firstName;
starts = firstStart;
stops = firstStop;
steps = firstStep;

if strlength(secondName)>0
    names = [names;secondName];
    starts = [starts;secondStart];
    stops = [stops;secondStop];
    steps = [steps;secondStep];
end

rows = cell(numel(names),6);

for i = 1:numel(names)
    schemaRow = schema(schema.name==names(i),:);

    if isempty(schemaRow)
        error("QuantLab:OptimizationUnknownParameter", ...
            "Parámetro no registrado: %s",names(i));
    end

    validateRange( ...
        names(i),starts(i),stops(i),steps(i),schemaRow);

    rows(i,:) = { ...
        names(i),schemaRow.label(1),schemaRow.type(1), ...
        starts(i),stops(i),steps(i)};
end

request = cell2table(rows, ...
    'VariableNames',{ ...
    'name','label','type', ...
    'start_value','stop_value','step_value'});

request.name = string(request.name);
request.label = string(request.label);
request.type = string(request.type);
request.start_value = double(request.start_value);
request.stop_value = double(request.stop_value);
request.step_value = double(request.step_value);
end

function validateRange(name,startValue,stopValue,stepValue,schemaRow)
if ~all(isfinite([startValue stopValue stepValue])) || ...
        stepValue<=0 || startValue>stopValue
    error("QuantLab:OptimizationInvalidRange", ...
        "Rango no válido para %s.",name);
end

tolerance = max(1,abs(schemaRow.maximum(1)))*1e-10;

if startValue<schemaRow.minimum(1)-tolerance || ...
        stopValue>schemaRow.maximum(1)+tolerance
    error("QuantLab:OptimizationOutOfBounds", ...
        "%s debe permanecer entre %s y %s.", ...
        name, ...
        formatPlainNumber(schemaRow.minimum(1),8,true), ...
        formatPlainNumber(schemaRow.maximum(1),8,true));
end

if schemaRow.type(1)=="integer" && ...
        (startValue~=round(startValue) || ...
         stopValue~=round(stopValue) || ...
         stepValue~=round(stepValue))
    error("QuantLab:OptimizationIntegerRange", ...
        "%s requiere valores enteros.",name);
end
end
