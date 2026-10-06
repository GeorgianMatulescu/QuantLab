function validateCRT3HConfig(cfg)
%VALIDATECRT3HCONFIG Reglas estructurales de CRT 3H.

if ~isfield(cfg,"crt3h")
    error("QuantLab:CRT3HConfigMissing", ...
        "Falta cfg.crt3h en loadQuantLabConfig.m.");
end

requiresThreeHourRange = true;
if isfield(cfg.crt3h,"referenceMode") && ...
        upper(string(cfg.crt3h.referenceMode))=="SESSION_RANGES"
    requiresThreeHourRange = false;
end
validateWindow(cfg.crt3h.london,"Londres",requiresThreeHourRange);
validateWindow(cfg.crt3h.newYork,"Nueva York",requiresThreeHourRange);
validateSessionScenarios(cfg.crt3h);
validateExitManagement(cfg.crt3h);

if ~isfield(cfg.crt3h,"entryFraction") || ...
        ~isscalar(cfg.crt3h.entryFraction) || ...
        ~isfinite(cfg.crt3h.entryFraction) || ...
        cfg.crt3h.entryFraction<=0 || cfg.crt3h.entryFraction>=1
    error("QuantLab:CRT3HEntryFraction", ...
        "crt3h.entryFraction debe estar estrictamente entre 0 y 1.");
end

if ~isfield(cfg.crt3h,"rewardRisk") || ...
        ~isfinite(cfg.crt3h.rewardRisk) || cfg.crt3h.rewardRisk<=0
    error("QuantLab:CRT3HRewardRisk", ...
        "crt3h.rewardRisk debe ser finito y mayor que cero.");
end

if ~isfield(cfg.crt3h,"breakEven") || ...
        ~isstruct(cfg.crt3h.breakEven)
    error("QuantLab:CRT3HBreakEvenMissing", ...
        "Falta cfg.crt3h.breakEven.");
end

breakEven = cfg.crt3h.breakEven;
requiredBreakEvenFields = [ ...
    "enabled","triggerR","offsetTicks","activateOnNextBar"];
if ~all(isfield(breakEven,requiredBreakEvenFields))
    error("QuantLab:CRT3HBreakEvenFields", ...
        "La configuración break-even está incompleta.");
end
if ~isBinaryScalar(breakEven.enabled)
    error("QuantLab:CRT3HBreakEvenEnabled", ...
        "breakEven.enabled debe valer true/false o 1/0.");
end
if ~isscalar(breakEven.triggerR) || ...
        ~isfinite(breakEven.triggerR) || breakEven.triggerR<=0
    error("QuantLab:CRT3HBreakEvenTrigger", ...
        "breakEven.triggerR debe ser finito y mayor que cero.");
end
if ~isscalar(breakEven.offsetTicks) || ...
        ~isfinite(breakEven.offsetTicks) || ...
        breakEven.offsetTicks<0 || ...
        breakEven.offsetTicks~=floor(breakEven.offsetTicks)
    error("QuantLab:CRT3HBreakEvenOffset", ...
        "breakEven.offsetTicks debe ser un entero no negativo.");
end
if ~isBinaryScalar(breakEven.activateOnNextBar)
    error("QuantLab:CRT3HBreakEvenPolicy", ...
        "breakEven.activateOnNextBar debe valer true/false o 1/0.");
end

if cfg.expectedBarMinutes~=1
    error("QuantLab:CRT3HBarSize", ...
        "CRT_3H_MADRID requiere barras de 1 minuto.");
end

if string(cfg.marketTimezone)~="Europe/Madrid"
    error("QuantLab:CRT3HTimezone", ...
        "CRT_3H_MADRID debe ejecutarse con Europe/Madrid.");
end
end

function validateExitManagement(crt3h)
if ~isfield(crt3h,"exitManagement") || ...
        ~isstruct(crt3h.exitManagement)
    error("QuantLab:CRT3HExitManagementMissing", ...
        "Falta cfg.crt3h.exitManagement.");
end

management = crt3h.exitManagement;
if ~isfield(management,"mode") || ...
        ~any(upper(string(management.mode))== ...
        ["FIXED_TARGET","SWING_TRAILING_STEP_TARGET"])
    error("QuantLab:CRT3HExitManagementMode", ...
        "Modo de salida CRT desconocido.");
end
if ~isfield(management,"trailing") || ~isstruct(management.trailing)
    error("QuantLab:CRT3HTrailingMissing", ...
        "Falta cfg.crt3h.exitManagement.trailing.");
end

p = management.trailing;
required = ["enabled","activationR","targetStepR", ...
    "swingLeftBars","swingRightBars","swingOffsetTicks", ...
    "activateOnNextBar"];
if ~all(isfield(p,required))
    error("QuantLab:CRT3HTrailingFields", ...
        "La configuración trailing está incompleta.");
end
if ~isBinaryScalar(p.enabled) || ~isBinaryScalar(p.activateOnNextBar)
    error("QuantLab:CRT3HTrailingFlags", ...
        "Las banderas trailing deben ser booleanas.");
end
if ~isscalar(p.activationR) || ~isfinite(p.activationR) || ...
        p.activationR<=0 || ~isscalar(p.targetStepR) || ...
        ~isfinite(p.targetStepR) || p.targetStepR<=0
    error("QuantLab:CRT3HTrailingR", ...
        "activationR y targetStepR deben ser positivos.");
end
integerFields = ["swingLeftBars","swingRightBars", ...
    "swingOffsetTicks"];
for field = integerFields
    value = p.(field);
    minimum = double(field~="swingOffsetTicks");
    if ~isscalar(value) || ~isfinite(value) || value<minimum || ...
            value~=floor(value)
        error("QuantLab:CRT3HTrailingSwing", ...
            "%s debe ser un entero válido.",field);
    end
end

if isfield(crt3h,"exitManagementScenarios") && ...
        ~isempty(crt3h.exitManagementScenarios)
    scenarios = crt3h.exitManagementScenarios;
    requiredScenario = ["name","displayName","mode"];
    if ~all(isfield(scenarios,requiredScenario))
        error("QuantLab:CRT3HExitScenarioFields", ...
            "Los escenarios de salida están incompletos.");
    end
    names = upper(string({scenarios.name}));
    modes = upper(string({scenarios.mode}));
    if any(strlength(names)==0) || numel(unique(names))~=numel(names) || ...
            any(~ismember(modes, ...
            ["FIXED_TARGET","SWING_TRAILING_STEP_TARGET"]))
        error("QuantLab:CRT3HExitScenarios", ...
            "Los escenarios de salida no son válidos.");
    end
    if isfield(crt3h,"defaultExitManagementScenario") && ...
            ~any(names==upper(string( ...
            crt3h.defaultExitManagementScenario)))
        error("QuantLab:CRT3HDefaultExitScenario", ...
            "El escenario de salida predeterminado no existe.");
    end
end
end

function validateSessionScenarios(crt3h)
if ~isfield(crt3h,"sessionScenarios") || isempty(crt3h.sessionScenarios)
    return;
end

required = ["name","displayName","enableLondon", ...
    "enableNewYork","blockNyAfterLondonTP"];
if ~all(isfield(crt3h.sessionScenarios,required))
    error("QuantLab:CRT3HSessionScenarioFields", ...
        "La definicion de escenarios Londres/NY esta incompleta.");
end

names = upper(string({crt3h.sessionScenarios.name}));
if any(strlength(names)==0) || numel(unique(names))~=numel(names)
    error("QuantLab:CRT3HSessionScenarioNames", ...
        "Los escenarios Londres/NY deben tener nombres unicos.");
end

for i = 1:numel(crt3h.sessionScenarios)
    item = crt3h.sessionScenarios(i);
    if ~isBinaryScalar(item.enableLondon) || ...
            ~isBinaryScalar(item.enableNewYork) || ...
            ~isBinaryScalar(item.blockNyAfterLondonTP)
        error("QuantLab:CRT3HSessionScenarioFlags", ...
            "Las banderas de cada escenario deben ser booleanas.");
    end
    if item.blockNyAfterLondonTP && ...
            ~(item.enableLondon && item.enableNewYork)
        error("QuantLab:CRT3HSessionScenarioBlock", ...
            "El bloqueo por TP requiere Londres y NY activados.");
    end
end

if isfield(crt3h,"defaultSessionScenario") && ...
        ~any(names==upper(string(crt3h.defaultSessionScenario)))
    error("QuantLab:CRT3HDefaultSessionScenario", ...
        "El escenario predeterminado no existe en sessionScenarios.");
end
end

function tf = isBinaryScalar(value)
tf = isscalar(value) && ...
    (islogical(value) || ...
    (isnumeric(value) && isfinite(value) && ...
    (value==0 || value==1)));
end

function validateWindow(p,name,requiresThreeHourRange)
requiredFields = ["refStart","refEnd","entryStart","manEnd", ...
    "thresholdPoints"];
if ~all(isfield(p,requiredFields))
    error("QuantLab:CRT3HWindowFields", ...
        "La ventana de %s está incompleta.",name);
end
if p.refEnd<=p.refStart || p.entryStart<p.refEnd || ...
        p.entryStart>=p.manEnd || p.manEnd<=p.refEnd
    error("QuantLab:CRT3HWindowOrder", ...
        "La ventana de %s no está ordenada correctamente.",name);
end
if requiresThreeHourRange && p.refEnd-p.refStart~=hours(3)
    error("QuantLab:CRT3HReferenceLength", ...
        "El rango de referencia de %s debe durar 3 horas.",name);
end
if p.thresholdPoints<0 || ~isfinite(p.thresholdPoints)
    error("QuantLab:CRT3HThreshold", ...
        "El umbral de %s debe ser finito y no negativo.",name);
end
end
