clear;
clc;

matlabRoot = fileparts(fileparts(mfilename('fullpath')));
addpath(genpath(matlabRoot));

session_date = datetime(2025,1,1) + caldays((0:199)');
close = (1:200)';
data = table(session_date,close);

anchored = buildWalkForwardWindows( ...
    data,80,20,20,10,"ANCHORED");

assert(anchored.total_sessions==200);
assert(anchored.development_sessions==180);
assert(anchored.holdout.sessions==20);
assert(height(anchored.windows)==5);
assert(anchored.windows.train_start(1)==session_date(1));
assert(anchored.windows.train_end(2)==session_date(100));
assert(anchored.windows.validation_start(2)==session_date(101));

rolling = buildWalkForwardWindows( ...
    data,80,20,20,10,"ROLLING");

assert(height(rolling.windows)==5);
assert(rolling.windows.train_start(2)==session_date(21));
assert(rolling.windows.train_end(2)==session_date(100));
assert(rolling.holdout.status=="LOCKED");

fprintf("TEST WALK FORWARD WINDOW BUILDER SUPERADO\n");
