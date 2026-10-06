function reportDir = getQuantLabReportDirectory(cfg,strategyName)
%GETQUANTLABREPORTDIRECTORY Resuelve informes legacy o por instrumento.

arguments
    cfg (1,1) struct
    strategyName (1,1) string
end

if isfield(cfg,"reportDirectory") && ...
        strlength(string(cfg.reportDirectory))>0
    reportDir = string(cfg.reportDirectory);
else
    reportDir = fullfile(cfg.matlabRoot,"Reports",strategyName);
end
end
