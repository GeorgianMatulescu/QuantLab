clear; clc;
matlabRoot=fileparts(fileparts(mfilename('fullpath'))); addpath(genpath(matlabRoot)); cfg=loadQuantLabConfig(matlabRoot); [T,~]=loadMarketData(cfg.dataFile,cfg); daily=buildDailySessions(T,cfg); results=runORBScenarioComparison(T,daily,cfg); S=results.summaryTable;
assert(height(S)==numel(cfg.executionProfiles)); assert(all(S.executedTrades+S.skippedTrades==S.totalSessions)); assert(all(S.maximumContracts<=cfg.risk.maximumContracts)); assert(all(S.finalEquityUSD>0)); assert(all(ismember(["IDEAL","REALISTIC","CONSERVATIVE"],string(S.profile))));
fprintf('TEST EXECUTION & RISK SUPERADO
'); disp(S(:,["profile","executedTrades","skippedTrades","netPnLUSD","finalEquityUSD","maxDrawdownPct"]));
