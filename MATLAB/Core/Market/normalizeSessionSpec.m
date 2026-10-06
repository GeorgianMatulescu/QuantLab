function session = normalizeSessionSpec(cfg)
%NORMALIZESESSIONSPEC Convierte la configuración histórica al contrato v1.

if isfield(cfg,"sessionSpec")
    session = cfg.sessionSpec;
else
    session = struct();
end

if ~isfield(session,"name"), session.name = "REGULAR"; end
if ~isfield(session,"timezone")
    if isfield(cfg,"marketTimezone")
        session.timezone = string(cfg.marketTimezone);
    else
        session.timezone = "UTC";
    end
end
if ~isfield(session,"mode"), session.mode = "REGULAR"; end
if ~isfield(session,"startTime")
    if isfield(cfg,"sessionStart")
        session.startTime = cfg.sessionStart;
    else
        session.startTime = duration(0,0,0);
    end
end
if ~isfield(session,"endTime")
    if isfield(cfg,"sessionEnd")
        session.endTime = cfg.sessionEnd;
    else
        session.endTime = duration(24,0,0);
    end
end
if ~isfield(session,"expectedBarMinutes")
    if isfield(cfg,"expectedBarMinutes")
        session.expectedBarMinutes = cfg.expectedBarMinutes;
    else
        session.expectedBarMinutes = 1;
    end
end
if ~isfield(session,"expectedBarsPerSession")
    if isfield(cfg,"expectedBarsPerFullSession")
        session.expectedBarsPerSession = cfg.expectedBarsPerFullSession;
    else
        session.expectedBarsPerSession = 0;
    end
end
if ~isfield(session,"weekdays"), session.weekdays = 1:7; end

session.mode = upper(string(session.mode));
session.timezone = string(session.timezone);
end
