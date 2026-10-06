clear;
clc;

matlabRoot = fileparts(fileparts(mfilename('fullpath')));
addpath(genpath(matlabRoot));

n = 120;
session_date = datetime(2025,1,1) + caldays((0:n-1)');
valid = true(n,1);
contracts = ones(n,1);

signal_family = repmat(["A";"B";"C"],40,1);
volatility_score = linspace(0.1,2.5,n)';
setup_quality = mod((1:n)',5)+1;

net_R = -0.8 + ...
    0.55*(signal_family=="A") + ...
    0.35*volatility_score + ...
    0.05*setup_quality;

net_R(1:7:end) = net_R(1:7:end)+2.5;
net_pnl_usd = 100*net_R;
equity_before_usd = 50000 + [0;cumsum(net_pnl_usd(1:end-1))];
equity_after_usd = equity_before_usd + net_pnl_usd;

trades = table( ...
    session_date,valid,contracts,signal_family, ...
    volatility_score,setup_quality,net_R,net_pnl_usd, ...
    equity_before_usd,equity_after_usd);

catalog = inferFeatureCatalog(trades);

assert(any(catalog.name=="signal_family"));
assert(any(catalog.name=="volatility_score"));
assert(any(catalog.name=="setup_quality"));
assert(any(catalog.name=="day_of_week"));

assert(~any( ...
    catalog.name=="net_r" & catalog.enabled), ...
    "Net R no puede clasificarse como feature pre-trade.");

available = getAvailableFeatureCatalog(catalog,trades);

analysis = analyzeStrategySegments( ...
    trades,"volatility_score","Quintiles",10,70);

assert(~isempty(analysis.segments));
assert(all(analysis.segments.trade_count>0));
assert(any(analysis.segments.sample_ok));

ranking = rankStrategyFeatures(trades,available,10,70);

assert(~isempty(ranking));
assert(any(ranking.feature=="volatility_score"));

coreSource = fileread(fullfile( ...
    matlabRoot,"Core","Research", ...
    "analyzeStrategySegments.m"));

assert(~contains(lower(coreSource),"orb"), ...
    "El motor genérico contiene una dependencia ORB.");

fprintf("TEST GENERIC SEGMENT EXPLORER SUPERADO\n");
fprintf("Features disponibles: %d\n",height(available));
fprintf("Segmentos: %d\n",height(analysis.segments));
fprintf("Features rankeadas: %d\n",height(ranking));
