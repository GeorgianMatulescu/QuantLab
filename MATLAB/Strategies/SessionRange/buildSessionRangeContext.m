function [events,context] = buildSessionRangeContext(data,cfg)
%BUILDSESSIONRANGECONTEXT Construye Asia y Londres sin mirar al futuro.
%
% Horario Europe/Madrid congelado:
%   Londres:    rango Asia 00:00-09:00, entrada 09:00-11:00.
%   Nueva York: rango Asia 00:00-09:00 y rango Londres 09:00-15:00,
%                entrada 15:00-17:00; el primer fill válido gana.

data = ensureCanonicalBarData(data,cfg);

if ismember("use_rth",string(data.Properties.VariableNames)) && ...
        all(double(data.use_rth)==1)
    error("QuantLab:SessionRangeExtendedDataRequired", ...
        "SESSION_RANGE_MADRID necesita datos de 1 minuto use_rth=0.");
end

isNewDay = [true; data.session_date(2:end)~=data.session_date(1:end-1)];
dayFirstIndex = find(isNewDay);
dayLastIndex = [dayFirstIndex(2:end)-1; height(data)];
days = data.session_date(dayFirstIndex);
windows = repmat(emptyRangeWindow(data,cfg),2*numel(days),1);

asiaLondonComplete = false(numel(days),1);
asiaNyComplete = false(numel(days),1);
londonNyComplete = false(numel(days),1);

for i = 1:numel(days)
    dayStart = dateshift(days(i),"start","day");
    dayIndices = (dayFirstIndex(i):dayLastIndex(i))';

    london = buildRangeWindow( ...
        data,dayIndices,dayStart,"LONDRES","ASIA", ...
        cfg.crt3h.london,cfg);

    asiaForNy = cfg.crt3h.london;
    asiaForNy.entryStart = cfg.crt3h.newYork.entryStart;
    asiaForNy.manEnd = cfg.crt3h.newYork.manEnd;
    asiaForNy.thresholdPoints = ...
        cfg.crt3h.newYork.thresholdPoints;
    nyAsia = buildRangeWindow( ...
        data,dayIndices,dayStart,"NUEVA_YORK","ASIA", ...
        asiaForNy,cfg);
    nyLondon = buildRangeWindow( ...
        data,dayIndices,dayStart,"NUEVA_YORK","LONDRES", ...
        cfg.crt3h.newYork,cfg);

    candidates = orderNewYorkCandidates( ...
        [nyAsia; nyLondon],cfg.crt3h.newYorkRangeOrder);
    newYork = candidates(1);
    newYork.range_candidates = candidates;

    windows(2*i-1,1) = london;
    windows(2*i,1) = newYork;
    asiaLondonComplete(i) = london.data_complete;
    asiaNyComplete(i) = nyAsia.data_complete;
    londonNyComplete(i) = nyLondon.data_complete;
end

if isempty(windows) || ...
        ~any(asiaLondonComplete | asiaNyComplete | londonNyComplete)
    error("QuantLab:SessionRangeNoCompleteRange", ...
        "No hay rangos de sesión completos; revisa use_rth=0, barras de " + ...
        "1 minuto y la conversión a Europe/Madrid.");
end

eventMask = data.time_local>=duration(0,0,0) & ...
    data.time_local<duration(17,0,0);
events = buildBaseMarketEvents(data(eventMask,:),cfg);

context = struct( ...
    "daily",buildSessionRangeDailyTable(days,windows), ...
    "windows",windows, ...
    "strategy_name","SESSION_RANGE_MADRID");
end

function candidates = orderNewYorkCandidates(candidates,requestedOrder)
names = upper(string({candidates.reference_name}));
order = upper(string(requestedOrder));
if numel(order)~=numel(candidates) || ...
        ~all(ismember(order,names)) || numel(unique(order))~=numel(order)
    error("QuantLab:SessionRangeCandidateOrder", ...
        "newYorkRangeOrder debe contener ASIA y LONDRES una sola vez.");
end
indices = zeros(numel(order),1);
for i = 1:numel(order)
    indices(i) = find(names==order(i),1,"first");
end
candidates = candidates(indices);
end

function w = buildRangeWindow( ...
    data,dayIndices,dayStart,sessionName,referenceName,p,cfg)

w = emptyRangeWindow(data,cfg);
w.session_date = dayStart;
w.session_name = string(sessionName);
w.reference_name = string(referenceName);
w.ref_start = dayStart+p.refStart;
w.ref_end = dayStart+p.refEnd;
w.entry_start = dayStart+p.entryStart;
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

function daily = buildSessionRangeDailyTable(days,windows)
n = numel(days);
asia_high = nan(n,1);
asia_low = nan(n,1);
asia_range_points = nan(n,1);
asia_london_complete = false(n,1);
asia_new_york_complete = false(n,1);
london_high = nan(n,1);
london_low = nan(n,1);
london_range_points = nan(n,1);
london_new_york_complete = false(n,1);

for i = 1:n
    london = windows(2*i-1);
    candidates = windows(2*i).range_candidates;
    names = upper(string({candidates.reference_name}));
    asia = candidates(find(names=="ASIA",1,"first"));
    londonRange = candidates(find(names=="LONDRES",1,"first"));

    asia_high(i) = london.crt_high;
    asia_low(i) = london.crt_low;
    asia_range_points(i) = london.crt_range_points;
    asia_london_complete(i) = london.data_complete;
    asia_new_york_complete(i) = asia.data_complete;
    london_high(i) = londonRange.crt_high;
    london_low(i) = londonRange.crt_low;
    london_range_points(i) = londonRange.crt_range_points;
    london_new_york_complete(i) = londonRange.data_complete;
end

daily = table(days,asia_high,asia_low,asia_range_points, ...
    asia_london_complete,asia_new_york_complete, ...
    london_high,london_low,london_range_points, ...
    london_new_york_complete, ...
    'VariableNames',{ ...
    'session_date','asia_high','asia_low','asia_range_points', ...
    'asia_london_complete','asia_new_york_complete', ...
    'london_high','london_low','london_range_points', ...
    'london_new_york_complete'});
end

function w = emptyRangeWindow(data,cfg)
spec = normalizeInstrumentSpec(cfg);
tz = char(spec.marketTimezone);
if ~isempty(data) && isdatetime(data.datetime_local)
    tz = char(data.datetime_local.TimeZone);
end
zonedNaT = NaT("TimeZone",tz);
w = struct( ...
    "session_date",zonedNaT, ...
    "session_name","", ...
    "reference_name","", ...
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
    "crt_range_points",NaN, ...
    "range_candidates",struct([]));
end
