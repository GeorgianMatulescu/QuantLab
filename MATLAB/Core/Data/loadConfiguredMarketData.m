function [data,report] = loadConfiguredMarketData(cfg)
%LOADCONFIGUREDMARKETDATA Selecciona el adaptador declarado en cfg.

if isfield(cfg,"dataLoader")
    loader = upper(string(cfg.dataLoader));
else
    loader = "QUANTLAB_IBKR_CSV";
end

switch loader
    case "QUANTLAB_IBKR_CSV"
        [data,report] = loadMarketData(cfg.dataFile,cfg);
    case "GENERIC_OHLCV_CSV"
        [data,report] = loadGenericBarData(cfg.dataFile,cfg);
    otherwise
        error("QuantLab:UnknownDataLoader", ...
            "Data loader desconocido: %s",loader);
end
end
