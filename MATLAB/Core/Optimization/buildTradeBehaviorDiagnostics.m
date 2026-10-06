function diagnostics = buildTradeBehaviorDiagnostics(trades)
%BUILDTRADEBEHAVIORDIAGNOSTICS Resume el comportamiento de una configuración.
%
% La firma se usa para detectar configuraciones que producen exactamente
% el mismo conjunto de resultados. No depende de una estrategia concreta.

arguments
    trades table
end

diagnostics = struct( ...
    "signature","EMPTY", ...
    "target_exit_count",0, ...
    "stop_exit_count",0, ...
    "eod_exit_count",0, ...
    "other_exit_count",0);

if isempty(trades)
    return;
end

variables = string(trades.Properties.VariableNames);

if ismember("valid",variables)
    trades = trades(logical(trades.valid),:);
end

if ismember("contracts",variables)
    trades = trades( ...
        isfinite(trades.contracts) & trades.contracts>0,:);
end

if isempty(trades)
    return;
end

if ismember("session_date",variables)
    trades = sortrows(trades,"session_date");
elseif ismember("entry_time",variables)
    trades = sortrows(trades,"entry_time");
end

n = height(trades);
index = (1:n)';

r = readNumericColumn(trades,"net_R");
pnl = readNumericColumn(trades,"net_pnl_usd");
contracts = readNumericColumn(trades,"contracts");

if isempty(r), r = zeros(n,1); end
if isempty(pnl), pnl = zeros(n,1); end
if isempty(contracts), contracts = zeros(n,1); end

r(~isfinite(r)) = 0;
pnl(~isfinite(pnl)) = 0;
contracts(~isfinite(contracts)) = 0;

dateChecksum = calculateDateChecksum(trades,index);

exitReason = strings(n,1);

if ismember("exit_reason",variables)
    exitReason = upper(string(trades.exit_reason));
end

diagnostics.target_exit_count = ...
    sum(contains(exitReason,"TARGET"));
diagnostics.stop_exit_count = ...
    sum(contains(exitReason,"STOP"));
diagnostics.eod_exit_count = ...
    sum(contains(exitReason,"EOD"));

knownExit = ...
    contains(exitReason,"TARGET") | ...
    contains(exitReason,"STOP") | ...
    contains(exitReason,"EOD");

diagnostics.other_exit_count = sum(~knownExit);

diagnostics.signature = string(sprintf( ...
    ['N=%d|R=%.10f|RW=%.10f|R2=%.10f|' ...
     'P=%.6f|PW=%.6f|C=%.6f|D=%.6f|' ...
     'T=%d|S=%d|E=%d|O=%d'], ...
    n, ...
    sum(r),sum(index.*r),sum(r.^2), ...
    sum(pnl),sum(index.*pnl),sum(contracts), ...
    dateChecksum, ...
    diagnostics.target_exit_count, ...
    diagnostics.stop_exit_count, ...
    diagnostics.eod_exit_count, ...
    diagnostics.other_exit_count));
end

function values = readNumericColumn(trades,columnName)
variables = string(trades.Properties.VariableNames);

if ismember(columnName,variables)
    values = double(trades.(columnName));
else
    values = [];
end
end

function checksum = calculateDateChecksum(trades,index)
variables = string(trades.Properties.VariableNames);
checksum = 0;

dateColumn = "";

if ismember("session_date",variables)
    dateColumn = "session_date";
elseif ismember("entry_time",variables)
    dateColumn = "entry_time";
end

if strlength(dateColumn)==0
    return;
end

dates = trades.(dateColumn);

if ~isdatetime(dates) || isempty(dates)
    return;
end

dates.TimeZone = "";
baseDate = min(dates);
offset = days(dates-baseDate);
offset(~isfinite(offset)) = 0;
checksum = sum(index.*offset);
end
