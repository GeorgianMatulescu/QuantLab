function report = validateDataAgainstDictionary(data, requiredFields)
arguments
    data table
    requiredFields string = string(data.Properties.VariableNames)
end
dictionary = getDataDictionary();
known = string(dictionary.field);
available = string(data.Properties.VariableNames);
unknown = requiredFields(~ismember(requiredFields, known));
missing = requiredFields(~ismember(requiredFields, available));
report = struct("requiredFields",requiredFields, ...
    "unknownRequiredFields",unknown, ...
    "missingRequiredFields",missing, ...
    "isValid",isempty(unknown) && isempty(missing));
if ~isempty(unknown)
    error("QuantLab:UnknownDataDictionaryFields", ...
        "Campos no definidos: %s", strjoin(unknown,", "));
end
if ~isempty(missing)
    error("QuantLab:MissingRequiredDataFields", ...
        "Faltan campos: %s", strjoin(missing,", "));
end
end
