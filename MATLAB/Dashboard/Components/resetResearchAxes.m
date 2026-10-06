function resetResearchAxes(ax)
%RESETRESEARCHAXES Limpieza segura del gráfico Trade Research.
%
% Elimina velas, niveles, flechas, textos y conexiones anteriores,
% incluidas las primitivas con HandleVisibility="off", sin borrar la
% AxesToolbar ni utilizar el reset gráfico interno.

arguments
    ax
end

clearDashboardAxesSafely(ax);
end
