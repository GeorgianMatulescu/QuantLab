function [value,found] = getNestedStructValue(inputStruct,path)
%GETNESTEDSTRUCTVALUE Lee una ruta como "risk.fixedRiskUSD".

arguments
    inputStruct (1,1) struct
    path (1,1) string
end

parts = split(path,".");
current = inputStruct;
found = true;

for i = 1:numel(parts)
    fieldName = char(parts(i));

    if ~isstruct(current) || ~isfield(current,fieldName)
        value = [];
        found = false;
        return;
    end

    current = current.(fieldName);
end

value = current;
end
