clear;
clc;

matlabRoot = string(fileparts(fileparts(mfilename("fullpath"))));
addpath(genpath(matlabRoot));

source = fileread(fullfile( ...
    matlabRoot,"Dashboard","launchQuantLabDashboard.m"));

assert(contains(source,"previousResearchButton"));
assert(contains(source,"nextResearchButton"));
assert(contains(source,"navigateResearch(-1)"));
assert(contains(source,"navigateResearch(1)"));
assert(contains(source,'dashboardState.researchSource = "ORDERS";'));
assert(contains(source,'dashboardState.researchSource = "TRADES";'));
assert(contains(source,'previousResearchButton.Text = "← Orden anterior";'));
assert(contains(source,'nextResearchButton.Text = "Orden siguiente →";'));
assert(contains(source,'previousResearchButton.Text = "← Trade anterior";'));
assert(contains(source,'nextResearchButton.Text = "Trade siguiente →";'));
assert(contains(source,"rowIndex>1"));
assert(contains(source,"rowIndex<rowCount"));

fprintf("TEST TRADE RESEARCH NAVIGATION SUPERADO\n");
