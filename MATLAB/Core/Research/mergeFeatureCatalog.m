function catalog = mergeFeatureCatalog(baseCatalog,overrideCatalog)
%MERGEFEATURECATALOG Combina inferencia automática y metadatos del plugin.

baseCatalog = normalizeFeatureCatalog(baseCatalog);
overrideCatalog = normalizeFeatureCatalog(overrideCatalog);

catalog = baseCatalog;

for i = 1:height(overrideCatalog)
    name = overrideCatalog.name(i);
    index = find(catalog.name==name,1,"first");

    if isempty(index)
        catalog = [catalog;overrideCatalog(i,:)]; %#ok<AGROW>
    else
        catalog(index,:) = overrideCatalog(i,:);
    end
end

catalog = normalizeFeatureCatalog(catalog);
end
