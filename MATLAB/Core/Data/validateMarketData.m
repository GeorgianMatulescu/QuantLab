function [T,report] = validateMarketData(T,cfg)
%VALIDATEMARKETDATA Valida BarData v1 y la sesión configurada.

arguments
    T table
    cfg (1,1) struct
end

T = ensureCanonicalBarData(T,cfg);
session = normalizeSessionSpec(cfg);

report = struct( ...
    "originalRows",height(T), ...
    "duplicatesRemoved",0, ...
    "rowsRemovedOutsideRTH",0, ...
    "missingMinuteIntervals",0, ...
    "invalidPriceRows",0, ...
    "negativeVolumeRows",0, ...
    "finalRows",0);

if isempty(T)
    error("QuantLab:EmptyData","El archivo no contiene filas.");
end

missingDate = isnat(T.datetime_local);
T(missingDate,:) = [];

if isfield(cfg,"requireSortedData") && cfg.requireSortedData
    T = sortrows(T,"datetime_local");
end

if isfield(cfg,"removeDuplicates") && cfg.removeDuplicates
    [~,uniqueIndex] = unique(T.datetime_local,"stable");
    report.duplicatesRemoved = height(T)-numel(uniqueIndex);
    T = T(uniqueIndex,:);
end

invalidOHLC = ...
    T.high<T.low | T.high<T.open | T.high<T.close | ...
    T.low>T.open | T.low>T.close;

nonPositive = T.open<=0 | T.high<=0 | T.low<=0 | T.close<=0;
invalidPrice = invalidOHLC;

if ~isfield(cfg,"rejectNonPositivePrices") || ...
        cfg.rejectNonPositivePrices
    invalidPrice = invalidPrice | nonPositive;
end

report.invalidPriceRows = nnz(invalidPrice);
if report.invalidPriceRows>0
    error("QuantLab:InvalidOHLC", ...
        "Se detectaron %d filas con OHLC inválido.", ...
        report.invalidPriceRows);
end

negativeVolume = T.volume<0;
report.negativeVolumeRows = nnz(negativeVolume);

if (~isfield(cfg,"rejectNegativeVolume") || ...
        cfg.rejectNegativeVolume) && any(negativeVolume)
    error("QuantLab:NegativeVolume", ...
        "Se detectaron %d filas con volumen negativo.", ...
        report.negativeVolumeRows);
end

filterToSession = isfield(cfg,"filterToSession") && cfg.filterToSession;

if filterToSession && session.mode~="24X7"
    inSession = T.time_local>=session.startTime & ...
        T.time_local<session.endTime;
    report.rowsRemovedOutsideRTH = nnz(~inSession);
    T = T(inSession,:);
end

sessionDates = unique(T.session_date);
missingIntervals = 0;

for i = 1:numel(sessionDates)
    dt = T.datetime_local(T.session_date==sessionDates(i));
    if numel(dt)<2, continue; end
    gaps = minutes(diff(dt));
    missingIntervals = missingIntervals + ...
        nnz(gaps>session.expectedBarMinutes+1e-9);
end

report.missingMinuteIntervals = missingIntervals;
report.finalRows = height(T);
end
