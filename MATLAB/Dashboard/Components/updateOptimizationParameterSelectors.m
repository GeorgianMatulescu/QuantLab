function schema = updateOptimizationParameterSelectors( ...
    firstDropdown,secondDropdown,parameterSchema)
%UPDATEOPTIMIZATIONPARAMETERSELECTORS Configura los dos selectores.

schema = getOptimizableParameterSchema(parameterSchema);

if isempty(schema)
    firstDropdown.Items = "No parameters";
    firstDropdown.ItemsData = "";
    firstDropdown.Value = "";
    firstDropdown.Enable = "off";

    secondDropdown.Items = "None";
    secondDropdown.ItemsData = "";
    secondDropdown.Value = "";
    secondDropdown.Enable = "off";
    return;
end

labels = reshape( ...
    schema.label + "  [" + schema.name + "]",1,[]);
names = reshape(schema.name,1,[]);

firstDropdown.Items = labels;
firstDropdown.ItemsData = names;
firstDropdown.Value = names(1);
firstDropdown.Enable = "on";

secondDropdown.Items = ["None",labels];
secondDropdown.ItemsData = ["",names];

if numel(names)>=2
    secondDropdown.Value = names(2);
else
    secondDropdown.Value = "";
end

secondDropdown.Enable = "on";
end
