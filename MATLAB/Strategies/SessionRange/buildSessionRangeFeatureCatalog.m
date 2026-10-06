function catalog = buildSessionRangeFeatureCatalog()
%BUILDSESSIONRANGEFEATURECATALOG Variables para comparar el rango origen.

catalog = buildCRT3HFeatureCatalog();
catalog.label(catalog.name=="crt_range_points") = "Session Range";
catalog.description(catalog.name=="crt_range_points") = ...
    "Asia or London reference range";

reference = cell2table({ ...
    "reference_range","Reference Range","categorical","", ...
    "context","Categories",true,"SESSION_RANGE", ...
    "Range that originated the setup: ASIA or LONDRES"}, ...
    'VariableNames',catalog.Properties.VariableNames);
reference = normalizeFeatureCatalog(reference);
catalog = [reference; catalog];
catalog = normalizeFeatureCatalog(catalog);
end
