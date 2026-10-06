clear;
clc;

matlabRoot = fileparts(fileparts(mfilename('fullpath')));
addpath(genpath(matlabRoot));

session_date = datetime(2025,1,1) + caldays((0:159)');
regime = [ones(80,1);2*ones(80,1)];
data = table(session_date,regime);

request = table( ...
    "alpha","Alpha","numeric",1,3,1, ...
    'VariableNames',{ ...
    'name','label','type','start_value','stop_value','step_value'});

grid = buildParameterSweepGrid(request,10);
plan = buildWalkForwardWindows(data,60,20,20,10,"ROLLING");
runnerFactory = @(slice,phase,windowId) ...
    createMockRunner(slice,phase,windowId);
cache = containers.Map("KeyType","char","ValueType","any");
callbacks = struct("cancel",@() false);

[result,cache,state] = runWalkForwardOptimization( ...
    "MOCK","REALISTIC",data,grid,plan, ...
    "Net PnL (USD)",70,runnerFactory, ...
    cache,callbacks,false);

assert(state.completed_windows==height(plan.windows));
assert(~state.cancelled);
assert(height(result.aggregate_results)==3);
assert(height(result.window_results)==height(plan.windows));
assert(result.holdout.status=="LOCKED");
assert(~isempty(result.consensus));
assert(all(result.aggregate_results.windows_evaluated==height(plan.windows)));
assert(any(isfinite(result.aggregate_results.plateau_score)));

[resultCached,~,stateCached] = runWalkForwardOptimization( ...
    "MOCK","REALISTIC",data,grid,plan, ...
    "Net PnL (USD)",70,runnerFactory, ...
    cache,callbacks,false);

assert(stateCached.completed_runs==state.completed_runs);
assert(height(resultCached.aggregate_results)==3);

fprintf("TEST GENERIC WALK FORWARD ENGINE SUPERADO\n");

function runner = createMockRunner(slice,phase,windowId)
runner = @(parameterSet) mockMetrics( ...
    slice,parameterSet,phase,windowId);
end

function metrics = mockMetrics(slice,parameterSet,phase,windowId) %#ok<INUSD>
alpha = parameterSet.value(parameterSet.name=="alpha");
regimeMean = mean(slice.regime);

% Alpha 2 is intentionally stable. Alpha 1/3 depend more on regime.
base = 0.20 - 0.18*abs(alpha-2);
regimePenalty = 0.10*abs(alpha-2)*(regimeMean-1.5);
expectancy = base-regimePenalty;

metrics = createEmptyOptimizationMetrics();
metrics.status = "OK";
metrics.executed_trades = height(slice);
metrics.win_rate_pct = 50+10*expectancy;
metrics.net_r = expectancy*height(slice);
metrics.net_pnl_usd = 100*metrics.net_r;
metrics.return_pct = metrics.net_pnl_usd/500;
metrics.profit_factor = max(0.1,1+expectancy);
metrics.expectancy_r = expectancy;
metrics.max_drawdown_pct = 4+abs(alpha-2);
metrics.final_equity_usd = 50000+metrics.net_pnl_usd;
metrics.is_count = round(0.7*height(slice));
metrics.is_expectancy_r = expectancy*1.05;
metrics.oos_count = height(slice)-metrics.is_count;
metrics.oos_expectancy_r = expectancy*0.95;
metrics.return_drawdown_ratio = ...
    metrics.return_pct/metrics.max_drawdown_pct;
metrics.robustness_score = min( ...
    metrics.is_expectancy_r,metrics.oos_expectancy_r) - ...
    0.5*abs(metrics.is_expectancy_r-metrics.oos_expectancy_r);
metrics.stable_sign = "YES";
end
