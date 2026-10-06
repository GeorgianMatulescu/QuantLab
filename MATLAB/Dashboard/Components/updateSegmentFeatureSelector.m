function catalog = updateSegmentFeatureSelector( ...
    dropdown,baseCatalog,trades)
%UPDATESEGMENTFEATURESELECTOR Sincroniza selector y catálogo disponible.

catalog = getAvailableFeatureCatalog(baseCatalog,trades);

if isempty(catalog)
    dropdown.ItemsData = "";
    dropdown.Items = "No available features";
    dropdown.Value = "";
    dropdown.Enable = "off";
    return;
end

currentValue = string(dropdown.Value);
names = reshape(catalog.name,1,[]);
labels = reshape( ...
    catalog.label + "  [" + catalog.name + "]",1,[]);

dropdown.Enable = "on";
dropdown.Items = labels;
dropdown.ItemsData = names;

if any(names==currentValue)
    dropdown.Value = currentValue;
else
    dropdown.Value = names(1);
end
end
