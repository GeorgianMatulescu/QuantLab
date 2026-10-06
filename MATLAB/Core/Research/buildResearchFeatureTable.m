function researchTable = buildResearchFeatureTable(trades)
%BUILDRESEARCHFEATURETABLE Añade características temporales genéricas.
%
% No contiene conocimiento de una estrategia concreta. Las variables
% derivadas se construyen únicamente a partir de columnas comunes.

arguments
    trades table
end

researchTable = trades;

if isempty(trades)
    return;
end

variables = string(trades.Properties.VariableNames);

dateColumn = "";

if ismember("session_date",variables)
    dateColumn = "session_date";
elseif ismember("session_date_new_york",variables)
    dateColumn = "session_date_new_york";
end

if strlength(dateColumn)>0
    sessionDate = trades.(dateColumn);

    if isdatetime(sessionDate)
        researchTable.day_of_week = string(day(sessionDate,"name"));
        researchTable.month_name = string(month(sessionDate,"name"));
        researchTable.year_number = year(sessionDate);
        researchTable.quarter = ...
            "Q" + string(ceil(month(sessionDate)/3));
    end
end

if ismember("entry_time",variables) && ...
        isdatetime(trades.entry_time)

    entryTime = trades.entry_time;
    researchTable.entry_hour = ...
        hour(entryTime) + minute(entryTime)/60;
end

if all(ismember(["entry_time","exit_time"],variables)) && ...
        isdatetime(trades.entry_time) && ...
        isdatetime(trades.exit_time)

    entryTime = trades.entry_time;
    exitTime = trades.exit_time;

    entryZone = string(entryTime.TimeZone);
    exitZone = string(exitTime.TimeZone);

    if strlength(entryZone)>0
        exitTime.TimeZone = char(entryZone);
    elseif strlength(exitZone)>0
        entryTime.TimeZone = char(exitZone);
    end

    researchTable.duration_minutes = ...
        minutes(exitTime-entryTime);
end
end
