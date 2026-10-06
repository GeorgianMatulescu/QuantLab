function validateORBConfig(cfg)
%VALIDATEORBCONFIG Valida únicamente reglas específicas ORB.

if cfg.orb.rewardRisk<=0
    error("QuantLab:ORBRewardRisk", ...
        "orb.rewardRisk debe ser positivo.");
end

if cfg.orbEnd<=cfg.orbStart
    error("QuantLab:ORBWindow", ...
        "orbEnd debe ser posterior a orbStart.");
end
end
