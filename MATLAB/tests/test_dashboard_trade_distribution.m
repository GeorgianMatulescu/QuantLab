clear;
clc;

matlabRoot = fileparts(fileparts(mfilename('fullpath')));
addpath(genpath(matlabRoot));

n = 40;
sessionDate = datetime( ...
    2026,1,1, ...
    "TimeZone","America/New_York") + ...
    caldays((0:n-1)');

valid = true(n,1);
contracts = 1+mod((1:n)',3);
direction = repmat(["LONG";"SHORT"],n/2,1);
exitReason = repmat( ...
    ["STOP";"TARGET";"BREAKEVEN";"EOD";"TARGET"],n/5,1);

netR = linspace(-1.2,2.8,n)';
netPnlUSD = 100*netR;
mfeR = max(netR+0.8,0);
maeR = abs(min(netR-0.4,0));
barsHeld = 5+mod((1:n)',70);
effectiveRiskUSD = 100+5*mod((1:n)',8);
orbRangePoints = 8+0.5*(1:n)';

trades = table( ...
    sessionDate,valid,direction,exitReason,contracts, ...
    netR,netPnlUSD,mfeR,maeR,barsHeld, ...
    effectiveRiskUSD,orbRangePoints, ...
    'VariableNames',{ ...
    'session_date','valid','direction','exit_reason', ...
    'contracts','net_R','net_pnl_usd','mfe_R','mae_R', ...
    'bars_held','effective_risk_usd','orb_range_points'});

allTrades = filterTradeDistributionData(trades,"ALL");
longTrades = filterTradeDistributionData(trades,"LONG");
targetTrades = filterTradeDistributionData(trades,"TARGET");
breakEvenTrades = filterTradeDistributionData(trades,"BREAKEVEN");

assert(height(allTrades)==n);
assert(all(upper(string(longTrades.direction))=="LONG"));
assert(all(upper(string(targetTrades.exit_reason))=="TARGET"));
assert(all(upper(string(breakEvenTrades.exit_reason))=="BREAKEVEN"));

stats = calculateTradeDistributionStatistics(allTrades);

assert(stats.trade_count==n);
assert(isfinite(stats.mean_r));
assert(isfinite(stats.p05_r));
assert(isfinite(stats.p95_r));
assert(isfinite(stats.skewness_r));
assert(isfinite(stats.top_10_contribution_pct));

summary = buildTradeDistributionSummaryTable(stats,"ALL");

assert(istable(summary));
assert(height(summary)==23);

fig = uifigure("Visible","off");
cleanup = onCleanup(@() delete(fig));

gridLayout = uigridlayout(fig,[2 3]);
axesList = gobjects(1,5);

for i = 1:5
    axesList(i) = uiaxes(gridLayout);
end

summaryTable = uitable(gridLayout);

updateTradeDistributionDashboard( ...
    axesList(1),axesList(2),axesList(3), ...
    axesList(4),axesList(5),summaryTable, ...
    trades,"ALL","ORB Range vs R");

assert(~isempty(allchild(axesList(1))));
assert(~isempty(allchild(axesList(2))));
assert(height(summaryTable.Data)==23);

dashboardSource = fileread(fullfile( ...
    matlabRoot,"Dashboard","launchQuantLabDashboard.m"));

assert(contains(dashboardSource, ...
    '"Title","Trade Distribution"'));

assert(contains(dashboardSource, ...
    "distributionFilterDropdown.ValueChangedFcn"));
assert(contains(dashboardSource,'"BREAKEVEN"'));
assert(contains(dashboardSource,'"TRAILING_STOP"'));

fprintf("TEST DASHBOARD TRADE DISTRIBUTION SUPERADO\n");
fprintf("Trades analizados: %d\n",stats.trade_count);
fprintf("Media: %.3f R\n",stats.mean_r);
fprintf("Aporte mejor 10 %%: %.2f %%\n", ...
    stats.top_10_contribution_pct);
