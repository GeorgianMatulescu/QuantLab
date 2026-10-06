clear; clc;
matlabRoot = string(fileparts(fileparts(mfilename("fullpath"))));
addpath(genpath(matlabRoot));

cfg = loadQuantLabConfig(matlabRoot,"MNQ","SESSION_RANGE_MADRID");
cfg.reportDirectory = fullfile( ...
    matlabRoot,"Reports","SESSION_RANGE_MADRID","MNQ");
resolved = getQuantLabReportDirectory(cfg,"SESSION_RANGE_MADRID");
assert(resolved==cfg.reportDirectory);

legacy = rmfield(cfg,"reportDirectory");
legacyResolved = getQuantLabReportDirectory( ...
    legacy,"SESSION_RANGE_MADRID");
assert(legacyResolved==fullfile( ...
    matlabRoot,"Reports","SESSION_RANGE_MADRID"));

batchSource = fileread(fullfile(matlabRoot,"runQuantLabBatch.m"));
launcherSource = fileread(fullfile(matlabRoot,"quantlab.m"));
workflowSource = fileread(fullfile(matlabRoot,"runQuantLabWorkflow.m"));
assert(contains(batchSource,"for i = 1:numel(instruments)"));
assert(contains(batchSource,"runQuantLabWorkflow("));
assert(contains(launcherSource,"runQuantLabBatch("));
assert(contains(launcherSource,"\"Multiselect\",\"on\""));
assert(contains(workflowSource,"cfg.reportDirectory"));
assert(contains(workflowSource, ...
    "loadAuditWorkspace(matlabRoot,strategyName,instrument)"));

fprintf("TEST QUANTLAB MULTI-INSTRUMENT LAUNCHER SUPERADO\n");
