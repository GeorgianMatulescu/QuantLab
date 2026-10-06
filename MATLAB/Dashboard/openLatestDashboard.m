function app = openLatestDashboard(matlabRoot,strategyName,instrument)
arguments
    matlabRoot (1,1) string = ...
        string(fileparts(fileparts(mfilename('fullpath'))))
    strategyName (1,1) string = "ORB"
    instrument (1,1) string = ""
end

S = loadAuditWorkspace(matlabRoot,strategyName,instrument);

strategyRun = buildStrategyResult( ...
    strategyName,S.results,S.cfg,S.data);

validateStrategyResult(strategyRun);

app = launchQuantLabDashboard(strategyRun,S.cfg);
end
