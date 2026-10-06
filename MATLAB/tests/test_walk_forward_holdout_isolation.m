clear;
clc;

matlabRoot = fileparts(fileparts(mfilename('fullpath')));
addpath(genpath(matlabRoot));

session_date = datetime(2025,1,1) + caldays((0:119)');
value = (1:120)';
data = table(session_date,value);
plan = buildWalkForwardWindows(data,50,15,15,20,"ANCHORED");

assert(plan.holdout.sessions==24);
assert(plan.windows.validation_end(end)<plan.holdout.start);

for i = 1:height(plan.windows)
    train = sliceMarketDataBySession( ...
        data,plan.windows.train_start(i),plan.windows.train_end(i));
    validation = sliceMarketDataBySession( ...
        data,plan.windows.validation_start(i), ...
        plan.windows.validation_end(i));

    assert(max(train.session_date)<plan.holdout.start);
    assert(max(validation.session_date)<plan.holdout.start);
end

fprintf("TEST WALK FORWARD HOLDOUT ISOLATION SUPERADO\n");
