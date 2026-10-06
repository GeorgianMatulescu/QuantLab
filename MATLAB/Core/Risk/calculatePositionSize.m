function sizing = calculatePositionSize(riskPoints,equityUSD,cfg)
%CALCULATEPOSITIONSIZE Sizing genérico por cantidad normalizada.
%
% Conserva aliases contracts/riskPerContractUSD para compatibilidad.

arguments
    riskPoints (1,1) double {mustBePositive}
    equityUSD (1,1) double {mustBePositive}
    cfg (1,1) struct
end

spec = normalizeInstrumentSpec(cfg);
riskPerQuantityUSD = calculateRiskPerQuantity(riskPoints,spec);

switch upper(string(cfg.risk.mode))
    case "FIXED_USD"
        riskBudgetUSD = cfg.risk.fixedRiskUSD;
    case "PERCENT_EQUITY"
        riskBudgetUSD = equityUSD*cfg.risk.percentRisk;
    otherwise
        error("QuantLab:UnknownRiskMode", ...
            "Modo desconocido: %s",cfg.risk.mode);
end

rawQuantity = riskBudgetUSD/riskPerQuantityUSD;
quantity = roundQuantityToStep(rawQuantity,spec,"FLOOR");

minimumQuantity = spec.minimumQuantity;
maximumQuantity = spec.maximumQuantity;

if isfield(cfg.risk,"minimumQuantity")
    minimumQuantity = cfg.risk.minimumQuantity;
elseif isfield(cfg.risk,"minimumContracts")
    minimumQuantity = cfg.risk.minimumContracts;
end

if isfield(cfg.risk,"maximumQuantity")
    maximumQuantity = cfg.risk.maximumQuantity;
elseif isfield(cfg.risk,"maximumContracts")
    maximumQuantity = cfg.risk.maximumContracts;
end

quantity = min(quantity,maximumQuantity);
skipTrade = false;
skipReason = "";

if quantity<minimumQuantity
    policy = upper(string(cfg.risk.insufficientRiskPolicy));
    switch policy
        case "SKIP"
            quantity = 0;
            skipTrade = true;
            skipReason = "RISK_TOO_LARGE";
        case "FORCE_MINIMUM"
            quantity = roundQuantityToStep( ...
                minimumQuantity,spec,"CEIL");
        case "FORCE_ONE"
            quantity = roundQuantityToStep( ...
                max(1,minimumQuantity),spec,"CEIL");
        otherwise
            error("QuantLab:UnknownRiskPolicy", ...
                "Política desconocida: %s",policy);
    end
end

effectiveRiskUSD = quantity*riskPerQuantityUSD;

sizing = struct( ...
    "quantity",quantity, ...
    "contracts",quantity, ...
    "riskBudgetUSD",riskBudgetUSD, ...
    "riskPerQuantityUSD",riskPerQuantityUSD, ...
    "riskPerContractUSD",riskPerQuantityUSD, ...
    "effectiveRiskUSD",effectiveRiskUSD, ...
    "skipTrade",skipTrade, ...
    "skipReason",skipReason);
end
