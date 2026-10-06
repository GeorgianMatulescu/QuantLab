function calendar = calculateCalendarReturns(trades)
%CALCULATECALENDARRETURNS Rendimientos mensuales y anuales de la estrategia.
%
% El rendimiento de cada mes se calcula con la equity real:
%
%   último equity_after / primer equity_before - 1
%
% De esta forma se respetan el interés compuesto, las sesiones sin
% operación y el dimensionamiento variable.

arguments
    trades table
end

calendar = struct( ...
    "years",zeros(0,1), ...
    "monthReturns",nan(0,12), ...
    "yearReturns",nan(0,1), ...
    "matrix",nan(0,13), ...
    "monthLabels",["Ene","Feb","Mar","Abr","May","Jun", ...
        "Jul","Ago","Sep","Oct","Nov","Dic","Total"], ...
    "monthlyObservations",table());

required = [ ...
    "session_date","equity_before_usd","equity_after_usd"];

if isempty(trades) || ...
        ~all(ismember(required,string(trades.Properties.VariableNames)))
    return;
end

trades = sortrows(trades,"session_date");
validDate = ~isnat(trades.session_date);
trades = trades(validDate,:);

if isempty(trades)
    return;
end

years = unique(year(trades.session_date));
monthReturns = nan(numel(years),12);
yearReturns = nan(numel(years),1);

obsYear = zeros(0,1);
obsMonth = zeros(0,1);
obsReturn = zeros(0,1);

for y = 1:numel(years)
    yearValue = years(y);
    yearMask = year(trades.session_date)==yearValue;
    yearTrades = trades(yearMask,:);

    yearReturns(y) = calculatePeriodReturn(yearTrades);

    for m = 1:12
        monthMask = month(yearTrades.session_date)==m;
        monthTrades = yearTrades(monthMask,:);

        if isempty(monthTrades)
            continue;
        end

        value = calculatePeriodReturn(monthTrades);
        monthReturns(y,m) = value;

        obsYear(end+1,1) = yearValue; %#ok<AGROW>
        obsMonth(end+1,1) = m; %#ok<AGROW>
        obsReturn(end+1,1) = value; %#ok<AGROW>
    end
end

calendar.years = years;
calendar.monthReturns = monthReturns;
calendar.yearReturns = yearReturns;
calendar.matrix = [monthReturns yearReturns];
calendar.monthlyObservations = table( ...
    obsYear,obsMonth,obsReturn, ...
    'VariableNames',{'year','month','return_pct'});
end

function returnPct = calculatePeriodReturn(periodTrades)
periodTrades = sortrows(periodTrades,"session_date");

startEquity = periodTrades.equity_before_usd(1);
endEquity = periodTrades.equity_after_usd(end);

if ~isfinite(startEquity) || startEquity<=0 || ~isfinite(endEquity)
    returnPct = NaN;
else
    returnPct = 100*(endEquity/startEquity-1);
end
end
