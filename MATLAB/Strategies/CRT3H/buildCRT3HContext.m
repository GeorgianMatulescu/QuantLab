function [events,context] = buildCRT3HContext(data,cfg)
%BUILDCRT3HCONTEXT Precalcula los rangos sin ejecutar operaciones.

data = ensureCanonicalBarData(data,cfg);

if ismember("use_rth",string(data.Properties.VariableNames)) && ...
        all(double(data.use_rth)==1)
    error("QuantLab:CRT3HExtendedDataRequired", ...
        "CRT_3H_MADRID necesita MNQ de 1 minuto con use_rth=0 " + ...
        "(MNQ_CONTFUT_1_min_ALL.csv).");
end

% DATA llega ordenado por el contrato BarData. Resolver una vez los límites
% de cada día evita buscar cada ventana sobre todo el histórico (la versión
% anterior hacía O(días x velas) comparaciones y parecía bloquear MAIN).
isNewDay = [true; data.session_date(2:end)~=data.session_date(1:end-1)];
dayFirstIndex = find(isNewDay);
dayLastIndex = [dayFirstIndex(2:end)-1; height(data)];
days = data.session_date(dayFirstIndex);
windows = repmat(emptyWindow(data,cfg),2*numel(days),1);

for i = 1:numel(days)
    dayStart = dateshift(days(i),"start","day");
    dayIndices = (dayFirstIndex(i):dayLastIndex(i))';
    windows(2*i-1,1) = buildWindow( ...
        data,dayIndices,dayStart,"LONDRES",cfg.crt3h.london,cfg);
    windows(2*i,1) = buildWindow( ...
        data,dayIndices,dayStart,"NUEVA_YORK",cfg.crt3h.newYork,cfg);
end

if isempty(windows) || ~any([windows.data_complete])
    error("QuantLab:CRT3HNoCompleteRange", ...
        "No hay ningún rango CRT 3H completo. Comprueba que el CSV sea " + ...
        "de 1 minuto, use_rth=0 y esté convertido a Europe/Madrid.");
end

% Los eventos se limitan al tramo relevante para evitar materializar barras
% nocturnas que no intervienen en la detección. La ejecución conserva DATA
% completo para poder cerrar una posición fuera de la ventana de entrada.
eventMask = data.time_local>=duration(6,0,0) & ...
    data.time_local<duration(17,0,0);
events = buildBaseMarketEvents(data(eventMask,:),cfg);

context = struct( ...
    "daily",buildCRT3HDailyTable(days,windows), ...
    "windows",windows, ...
    "strategy_name","CRT_3H_MADRID");
end

function w = buildWindow(data,dayIndices,dayStart,name,p,cfg)
w = emptyWindow(data,cfg);
w.session_date = dayStart;
w.session_name = name;
w.ref_start = dayStart+p.refStart;
w.ref_end = dayStart+p.refEnd;
w.entry_start = dayStart+p.entryStart;
% La sesión operable nace en entry_start: las barras anteriores no pueden
% fijar dirección, extremo de manipulación, nivel fraccional ni orden pendiente.
w.man_start = w.entry_start;
w.man_end = dayStart+p.manEnd;

dayTimes = data.datetime_local(dayIndices);
w.ref_indices = dayIndices(dayTimes>=w.ref_start & dayTimes<w.ref_end);
w.man_indices = dayIndices(dayTimes>=w.man_start & dayTimes<w.man_end);
w.expected_ref_bars = round(minutes(w.ref_end-w.ref_start) / ...
    cfg.expectedBarMinutes);
w.expected_man_bars = round(minutes(w.man_end-w.man_start) / ...
    cfg.expectedBarMinutes);
w.ref_bars = numel(w.ref_indices);
w.man_bars = numel(w.man_indices);
w.data_complete = w.ref_bars==w.expected_ref_bars && ...
    w.man_bars==w.expected_man_bars;

if ~isempty(w.ref_indices)
    w.crt_high = max(data.high(w.ref_indices),[],"omitnan");
    w.crt_low = min(data.low(w.ref_indices),[],"omitnan");
    w.crt_range_points = w.crt_high-w.crt_low;
end
end

function daily = buildCRT3HDailyTable(days,windows)
n = numel(days);
london_high = nan(n,1);
london_low = nan(n,1);
london_range_points = nan(n,1);
london_complete = false(n,1);
new_york_high = nan(n,1);
new_york_low = nan(n,1);
new_york_range_points = nan(n,1);
new_york_complete = false(n,1);

for i = 1:n
    % BUILDCRT3HCONTEXT añade exactamente Londres y NY, en ese orden.
    london = windows(2*i-1);
    newYork = windows(2*i);
    london_high(i) = london.crt_high;
    london_low(i) = london.crt_low;
    london_range_points(i) = london.crt_range_points;
    london_complete(i) = london.data_complete;
    new_york_high(i) = newYork.crt_high;
    new_york_low(i) = newYork.crt_low;
    new_york_range_points(i) = newYork.crt_range_points;
    new_york_complete(i) = newYork.data_complete;
end

daily = table(days,london_high,london_low,london_range_points, ...
    london_complete,new_york_high,new_york_low,new_york_range_points, ...
    new_york_complete, ...
    'VariableNames',{ ...
    'session_date','london_high','london_low','london_range_points', ...
    'london_complete','new_york_high','new_york_low', ...
    'new_york_range_points','new_york_complete'});
end

function w = emptyWindow(data,cfg)
spec = normalizeInstrumentSpec(cfg);
tz = char(spec.marketTimezone);
if ~isempty(data) && isdatetime(data.datetime_local)
    tz = char(data.datetime_local.TimeZone);
end
zonedNaT = NaT("TimeZone",tz);
w = struct( ...
    "session_date",zonedNaT, ...
    "session_name","", ...
    "ref_start",zonedNaT, ...
    "ref_end",zonedNaT, ...
    "man_start",zonedNaT, ...
    "entry_start",zonedNaT, ...
    "man_end",zonedNaT, ...
    "ref_indices",zeros(0,1), ...
    "man_indices",zeros(0,1), ...
    "expected_ref_bars",0, ...
    "expected_man_bars",0, ...
    "ref_bars",0, ...
    "man_bars",0, ...
    "data_complete",false, ...
    "crt_high",NaN, ...
    "crt_low",NaN, ...
    "crt_range_points",NaN);
end
