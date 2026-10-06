function report = validateInstalledStrategies()
%VALIDATEINSTALLEDSTRATEGIES Valida todos los factories descubiertos.

registry = getStrategyRegistry();
report = table( ...
    string({registry.name})', ...
    logical([registry.enabled])', ...
    string({registry.validationError})', ...
    'VariableNames',{'strategy','valid_and_enabled','message'});

disp(report);

invalid = strlength(report.message)>0;
if any(invalid)
    warning("QuantLab:InvalidInstalledStrategies", ...
        "%d plugins tienen errores de validación.",nnz(invalid));
end
end
