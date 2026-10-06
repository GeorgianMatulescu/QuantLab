function timeline = buildTradeTimeline(executed)
%BUILDTRADETIMELINE Devuelve una coordenada temporal única por operación.
%
% Las estrategias pueden ejecutar varias operaciones en una misma sesión.
% Por ello session_date no es una XData válida para gráficos bar(), que
% exige valores únicos. Se prioriza entry_time y se desempatan los valores
% repetidos mediante incrementos de un milisegundo.

arguments
    executed table
end

n = height(executed);
if n==0
    timeline = NaT(0,1);
    return;
end

variables = string(executed.Properties.VariableNames);

if ismember("entry_time",variables) && ...
        isdatetime(executed.entry_time)
    timeline = executed.entry_time;
elseif ismember("exit_time",variables) && ...
        isdatetime(executed.exit_time)
    timeline = executed.exit_time;
elseif ismember("session_date",variables) && ...
        isdatetime(executed.session_date)
    timeline = executed.session_date;
else
    timeline = datetime(2000,1,1) + seconds((0:n-1)');
end

timeline = timeline(:);

% Construir un fallback compatible con la zona horaria de la serie.
if ismember("session_date",variables) && ...
        isdatetime(executed.session_date)
    fallback = executed.session_date(:);
else
    fallback = datetime(2000,1,1) + days((0:n-1)');
end

try
    fallback.TimeZone = timeline.TimeZone;
catch
end

for i = 1:n
    if isnat(timeline(i))
        timeline(i) = fallback(i);
    end

    if i>1 && timeline(i)<=timeline(i-1)
        timeline(i) = timeline(i-1) + milliseconds(1);
    end
end
end
