function fig = plotSessionAudit(data, results, sessionDate, profileName)
%PLOTSESSIONAUDIT Dibuja una sesión completa, exista o no trade ejecutado.

arguments
    data table
    results (1,1) struct
    sessionDate
    profileName (1,1) string = "REALISTIC"
end

fig = plotTradeAudit(data, results, sessionDate, profileName);
end
