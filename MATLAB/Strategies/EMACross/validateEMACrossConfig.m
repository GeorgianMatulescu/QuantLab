function validateEMACrossConfig(cfg)
%VALIDATEEMACROSSCONFIG Reglas propias del plugin EMA Cross.

p = cfg.emaCross;

if p.fastPeriod<2 || p.slowPeriod<=p.fastPeriod
    error("QuantLab:EMAPeriods", ...
        "slowPeriod debe ser mayor que fastPeriod >= 2.");
end

if p.atrPeriod<2 || p.atrStopMultiple<=0 || p.rewardRisk<=0
    error("QuantLab:EMAATR", ...
        "ATR period, stop multiple y RR deben ser positivos.");
end

if p.entryEnd<=p.entryStart
    error("QuantLab:EMAEntryWindow", ...
        "entryEnd debe ser posterior a entryStart.");
end
end
