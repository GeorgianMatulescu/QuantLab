function resetDashboardAxes(ax)
%RESETDASHBOARDAXES Limpieza segura de una gráfica del dashboard.
%
% Reinicia contenido, límites y zoom sin tocar la AxesToolbar ni otros
% objetos internos del cliente gráfico.

arguments
    ax
end

clearDashboardAxesSafely(ax);
end
