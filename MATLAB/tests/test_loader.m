clear;
clc;

matlabRoot = fileparts(fileparts(mfilename('fullpath')));
addpath(genpath(matlabRoot));

cfg = loadQuantLabConfig(matlabRoot);
[T, report] = loadMarketData(cfg.dataFile, cfg);
daily = buildDailySessions(T, cfg);

assert(~isempty(T), "El histórico está vacío.");
assert(issorted(T.datetime_new_york), ...
    "Las barras no están ordenadas.");
assert(all(T.high >= T.low), ...
    "Existe alguna barra con high < low.");
assert(all(T.time_new_york >= cfg.sessionStart), ...
    "Hay barras anteriores a las 09:30.");
assert(all(T.time_new_york < cfg.sessionEnd), ...
    "Hay barras iguales o posteriores a las 16:00.");

valid = daily.orb_valid;
assert(any(valid), ...
    "No se ha construido ninguna ORB válida.");
assert(all(daily.orb_high(valid) >= daily.orb_low(valid)));

fprintf("TEST SUPERADO\n");
fprintf("Filas: %d\n", height(T));
fprintf("Sesiones: %d\n", height(daily));
fprintf("ORB válidas: %d\n", nnz(valid));
fprintf("Duplicados eliminados: %d\n", report.duplicatesRemoved);
