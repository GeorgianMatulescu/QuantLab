function validateFeatureCatalog(catalog)
%VALIDATEFEATURECATALOG Valida el contrato genérico de características.

arguments
    catalog table
end

catalog = normalizeFeatureCatalog(catalog);

allowedTypes = ["numeric","categorical","boolean","datetime"];
allowedRoles = [ ...
    "input","context","outcome","execution", ...
    "identifier","time"];

invalidTypes = setdiff(unique(catalog.type),allowedTypes);
invalidRoles = setdiff(unique(catalog.role),allowedRoles);

if any(strlength(catalog.name)==0)
    error("QuantLab:FeatureCatalogEmptyName", ...
        "El catálogo contiene características sin nombre.");
end

if ~isempty(invalidTypes)
    error("QuantLab:FeatureCatalogType", ...
        "Tipos de característica no válidos: %s", ...
        strjoin(invalidTypes,", "));
end

if ~isempty(invalidRoles)
    error("QuantLab:FeatureCatalogRole", ...
        "Roles de característica no válidos: %s", ...
        strjoin(invalidRoles,", "));
end
end
