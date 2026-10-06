function results = annotateParameterActivity( ...
    results,signatureColumn,tradeCountColumn)
%ANNOTATEPARAMETERACTIVITY Marca regiones activas e inactivas del grid.
%
% Estados:
%   ACTIVE             vecinos producen comportamientos distintos
%   PLATEAU_EDGE       transición hacia una región equivalente
%   INACTIVE_PLATEAU   vecinos producen el mismo comportamiento
%   NO_TRADES          configuración sin operaciones
%   N/A                no hay dimensión comparable

arguments
    results table
    signatureColumn (1,1) string = "behavior_signature"
    tradeCountColumn (1,1) string = "executed_trades"
end

if isempty(results)
    return;
end

variables = string(results.Properties.VariableNames);

if ~ismember(signatureColumn,variables)
    results.behavior_group_id = zeros(height(results),1);
    results.equivalent_configurations = ones(height(results),1);
    results.parameter_1_activity = repmat("N/A",height(results),1);
    results.parameter_2_activity = repmat("N/A",height(results),1);
    results.activity_status = repmat("N/A",height(results),1);
    return;
end

signatures = string(results.(signatureColumn));
groupId = zeros(height(results),1);
uniqueSignatures = unique(signatures,"stable");

for groupIndex = 1:numel(uniqueSignatures)
    groupId(signatures==uniqueSignatures(groupIndex)) = groupIndex;
end

groupCount = zeros(height(results),1);

for i = 1:height(results)
    groupCount(i) = sum(groupId==groupId(i));
end

results.behavior_group_id = groupId;
results.equivalent_configurations = groupCount;
results.parameter_1_activity = repmat("N/A",height(results),1);
results.parameter_2_activity = repmat("N/A",height(results),1);
results.activity_status = repmat("N/A",height(results),1);

hasSecondDimension = ...
    ismember("parameter_2_name",variables) && ...
    any(strlength(string(results.parameter_2_name))>0);

for i = 1:height(results)
    if ismember(tradeCountColumn,variables) && ...
            results.(tradeCountColumn)(i)<=0
        results.activity_status(i) = "NO_TRADES";
        continue;
    end

    firstState = classifyDimension( ...
        results,signatures,i,1,hasSecondDimension);
    results.parameter_1_activity(i) = firstState;

    if hasSecondDimension
        secondState = classifyDimension( ...
            results,signatures,i,2,hasSecondDimension);
        results.parameter_2_activity(i) = secondState;
        results.activity_status(i) = ...
            combineStates(firstState,secondState);
    else
        results.activity_status(i) = firstState;
    end
end
end

function state = classifyDimension( ...
    results,signatures,rowIndex,dimension,hasSecond)

if dimension==1
    valueColumn = "parameter_1_value";

    if hasSecond
        sliceMask = sameValues( ...
            results.parameter_2_value, ...
            results.parameter_2_value(rowIndex));
    else
        sliceMask = true(height(results),1);
    end
else
    valueColumn = "parameter_2_value";
    sliceMask = sameValues( ...
        results.parameter_1_value, ...
        results.parameter_1_value(rowIndex));
end

candidateRows = find(sliceMask & ...
    isfinite(results.(valueColumn)));

if numel(candidateRows)<2
    state = "N/A";
    return;
end

[~,order] = sort(results.(valueColumn)(candidateRows));
candidateRows = candidateRows(order);
position = find(candidateRows==rowIndex,1);

neighborRows = [];

if position>1
    neighborRows(end+1) = candidateRows(position-1); %#ok<AGROW>
end

if position<numel(candidateRows)
    neighborRows(end+1) = candidateRows(position+1); %#ok<AGROW>
end

if isempty(neighborRows)
    state = "N/A";
    return;
end

sameBehavior = signatures(neighborRows)==signatures(rowIndex);
hasSame = any(sameBehavior);
hasDifferent = any(~sameBehavior);

if hasSame && hasDifferent
    state = "PLATEAU_EDGE";
elseif hasSame
    state = "INACTIVE_PLATEAU";
else
    state = "ACTIVE";
end
end

function mask = sameValues(values,reference)
if isnan(reference)
    mask = isnan(values);
else
    tolerance = max(1,abs(reference))*1e-10;
    mask = abs(values-reference)<=tolerance;
end
end

function combined = combineStates(firstState,secondState)
states = [firstState secondState];
states = states(states~="N/A");

if isempty(states)
    combined = "N/A";
elseif any(states=="PLATEAU_EDGE")
    combined = "PLATEAU_EDGE";
elseif all(states=="INACTIVE_PLATEAU")
    combined = "INACTIVE_PLATEAU";
elseif any(states=="ACTIVE") && ...
        any(states=="INACTIVE_PLATEAU")
    combined = "MIXED";
elseif any(states=="ACTIVE")
    combined = "ACTIVE";
else
    combined = states(1);
end
end
