function events = createEventTable()
%CREATEEVENTTABLE Crea una tabla de eventos vacía con esquema estándar.

events = table( ...
    strings(0,1), ...              % event_type
    NaT(0,1), ...                 % event_time
    NaT(0,1), ...                 % session_date
    strings(0,1), ...             % symbol
    zeros(0,1), ...               % bar_index
    nan(0,1), ...                 % price
    strings(0,1), ...             % direction
    strings(0,1), ...             % source
    cell(0,1), ...                % payload
    'VariableNames', { ...
    'event_type','event_time','session_date','symbol', ...
    'bar_index','price','direction','source','payload'});
end
