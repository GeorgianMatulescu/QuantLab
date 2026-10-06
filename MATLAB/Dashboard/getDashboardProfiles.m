function profiles = getDashboardProfiles(results)
fields = string(fieldnames(results));
fields(fields == "summaryTable") = [];
fields(fields == "event_summary") = [];
keep = false(size(fields));
for i = 1:numel(fields)
    item = results.(fields(i));
    keep(i) = isstruct(item) && isfield(item,"trades") && isfield(item,"summary");
end
profiles = fields(keep);
if isempty(profiles)
    error("QuantLab:DashboardNoProfiles", ...
        "No se encontraron perfiles compatibles con el dashboard.");
end
end
