clear; clc;
matlabRoot = string(fileparts(fileparts(mfilename("fullpath"))));
addpath(genpath(matlabRoot));

registry = getStrategyRegistry();
enabledNames = string({registry([registry.enabled]).name});
assert(any(enabledNames=="CRT_3H_MADRID"));
assert(any(enabledNames=="SESSION_RANGE_MADRID"));

launcherSource = fileread(fullfile(matlabRoot,"quantlab.m"));
workflowSource = fileread(fullfile(matlabRoot,"runQuantLabWorkflow.m"));
assert(contains(launcherSource,"getStrategyRegistry()"));
assert(contains(launcherSource,"runQuantLabBatch("));
assert(contains(launcherSource,"uilistbox("));
assert(contains(launcherSource,"\"Multiselect\",\"on\""));
assert(contains(launcherSource,"Ejecutar y abrir dashboard"));
assert(contains(launcherSource,"Abrir último resultado"));
assert(contains(launcherSource,'"Value",[ ...'));
assert(~contains(launcherSource,'"Value",{ ...'));
assert(contains(workflowSource,"loadQuantLabConfig("));
assert(contains(workflowSource,"runStrategy("));
assert(contains(workflowSource,"exportStrategyRun("));
assert(contains(workflowSource,"launchQuantLabDashboard("));

wrappers = ["main.m","launch_dashboard.m", ...
    "run_session_range.m","launch_session_range_dashboard.m"];
for wrapper = wrappers
    source = fileread(fullfile(matlabRoot,wrapper));
    assert(contains(source,"runQuantLabWorkflow("));
    assert(numel(splitlines(string(source)))<20);
end

fprintf("TEST QUANTLAB UNIVERSAL LAUNCHER SUPERADO\n");
