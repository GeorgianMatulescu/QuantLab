function grid = buildParameterSweepGrid(request,maxCombinations)
%BUILDPARAMETERSWEEPGRID Construye un full grid de uno o dos parámetros.
%
% request:
%   name, label, type, start_value, stop_value, step_value

arguments
    request table
    maxCombinations (1,1) double ...
        {mustBeInteger,mustBePositive} = 200
end

required = [ ...
    "name","label","type", ...
    "start_value","stop_value","step_value"];

if ~all(ismember(required, ...
        string(request.Properties.VariableNames)))
    error("QuantLab:InvalidSweepRequest", ...
        "La solicitud de optimización está incompleta.");
end

if height(request)<1 || height(request)>2
    error("QuantLab:SweepParameterCount", ...
        "La v0.20 admite uno o dos parámetros simultáneos.");
end

valueVectors = cell(height(request),1);

for i = 1:height(request)
    startValue = request.start_value(i);
    stopValue = request.stop_value(i);
    stepValue = request.step_value(i);

    if ~all(isfinite([startValue stopValue stepValue])) || ...
            stepValue<=0 || startValue>stopValue
        error("QuantLab:SweepRange", ...
            "Rango no válido para %s.",request.name(i));
    end

    values = buildValueVector( ...
        startValue,stopValue,stepValue,request.type(i));

    if isempty(values)
        error("QuantLab:SweepEmptyRange", ...
            "El rango de %s no genera valores.",request.name(i));
    end

    valueVectors{i} = values;
end

combinationCount = prod(cellfun(@numel,valueVectors));

if combinationCount>maxCombinations
    error("QuantLab:SweepTooLarge", ...
        "El barrido genera %d combinaciones; límite actual: %d.", ...
        combinationCount,maxCombinations);
end

if height(request)==1
    firstValues = valueVectors{1}(:);
    secondValues = nan(size(firstValues));
else
    [firstGrid,secondGrid] = ndgrid( ...
        valueVectors{1},valueVectors{2});

    firstValues = firstGrid(:);
    secondValues = secondGrid(:);
end

combinationCount = numel(firstValues);
parameterSets = cell(combinationCount,1);

for combinationIndex = 1:combinationCount
    if height(request)==1
        names = request.name(1);
        values = firstValues(combinationIndex);
    else
        names = request.name;
        values = [ ...
            firstValues(combinationIndex); ...
            secondValues(combinationIndex)];
    end

    parameterSets{combinationIndex} = table( ...
        string(names),double(values), ...
        'VariableNames',{'name','value'});
end

parameter2Name = repmat("",combinationCount,1);

if height(request)==2
    parameter2Name(:) = request.name(2);
end

grid = table( ...
    (1:combinationCount)', ...
    parameterSets, ...
    repmat(request.name(1),combinationCount,1), ...
    repmat(request.label(1),combinationCount,1), ...
    firstValues, ...
    parameter2Name, ...
    repmat(conditionalLabel(request),combinationCount,1), ...
    secondValues, ...
    'VariableNames',{ ...
    'combination_id','parameter_set', ...
    'parameter_1_name','parameter_1_label','parameter_1_value', ...
    'parameter_2_name','parameter_2_label','parameter_2_value'});
end

function label = conditionalLabel(request)
if height(request)==2
    label = request.label(2);
else
    label = "";
end
end

function values = buildValueVector( ...
    startValue,stopValue,stepValue,parameterType)

tolerance = max(1,abs(stopValue))*1e-10;
count = floor((stopValue-startValue)/stepValue + tolerance)+1;
values = startValue + (0:max(0,count-1))*stepValue;
values = values(values<=stopValue+tolerance);

if parameterType=="integer"
    values = unique(round(values),"stable");
end

values = double(values);
end
