function [trades,summary] = runORBScenario( ...
    T,daily,cfg,profile,sessionData)
%RUNORBSCENARIO Ejecuta ORB usando sesiones previamente agrupadas.

if nargin<5
    sessionData = cell(0,1);
end

[minRange,maxRange] = resolveORBRangeFilters(cfg);

rows = cell(height(daily),1);
equityUSD = cfg.risk.initialEquityUSD;

for i = 1:height(daily)
    dayInfo = daily(i,:);

    if ~dayInfo.orb_valid
        continue;
    end

    if cfg.orb.requireFullSession && ...
            ~dayInfo.is_full_session
        continue;
    end

    if dayInfo.orb_direction=="DOJI" && ...
            ~cfg.orb.tradeDoji
        continue;
    end

    if dayInfo.orb_range_points<minRange || ...
            dayInfo.orb_range_points>maxRange
        continue;
    end

    if numel(sessionData)>=i && ...
            ~isempty(sessionData{i})
        D = sessionData{i};
    else
        D = T( ...
            T.session_date_new_york==dayInfo.session_date,:);
        D = sortrows(D,"datetime_new_york");
    end

    trade = simulateORBTrade( ...
        D,dayInfo,cfg,profile,equityUSD);

    rows{i} = trade;

    if trade.valid
        equityUSD = trade.equity_after_usd;
    end
end

rows = rows(~cellfun("isempty",rows));

if isempty(rows)
    trades = table();
else
    trades = struct2table(vertcat(rows{:}));
end

summary = calculateScenarioStatistics( ...
    trades,cfg,profile);
end

function [minimumRange,maximumRange] = resolveORBRangeFilters(cfg)
minimumRange = 0;
maximumRange = Inf;

if isfield(cfg.orb,"filters")
    filters = cfg.orb.filters;

    if isfield(filters,"minimumRangePoints")
        minimumRange = filters.minimumRangePoints;
    end

    if isfield(filters,"maximumRangePoints")
        maximumRange = filters.maximumRangePoints;
    end
end

if ~isfinite(minimumRange) || minimumRange<0
    error("QuantLab:ORBMinimumRange", ...
        "Minimum ORB range must be finite and non-negative.");
end

if ~(isfinite(maximumRange) || isinf(maximumRange)) || ...
        maximumRange<=0
    error("QuantLab:ORBMaximumRange", ...
        "Maximum ORB range must be positive.");
end

if minimumRange>maximumRange
    error("QuantLab:ORBRangeFilterOrder", ...
        "Minimum ORB range cannot exceed maximum ORB range.");
end
end
