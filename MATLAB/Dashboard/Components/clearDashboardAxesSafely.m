function clearDashboardAxesSafely(ax)
%CLEARDASHBOARDAXESSAFELY Limpia un UIAxes sin tocar la AxesToolbar.
%
% `ax.Children` puede no mostrar objetos con HandleVisibility="off".
% Por eso la limpieza se realiza con `findall` limitado exclusivamente
% a tipos de primitivas gráficas conocidas.
%
% No se utiliza:
% - allchild(ax)
% - cla con reset
%
% De esta forma se eliminan líneas, áreas, barras, textos y demás objetos
% dibujados, pero no se alcanzan controles internos de la toolbar.

arguments
    ax
end

if isempty(ax) || ~isvalid(ax)
    return;
end

graphicTypes = [ ...
    "line"; ...
    "area"; ...
    "bar"; ...
    "histogram"; ...
    "scatter"; ...
    "text"; ...
    "constantline"; ...
    "image"; ...
    "surface"; ...
    "patch"; ...
    "rectangle"; ...
    "quiver"; ...
    "errorbar"; ...
    "stem"];

objectsToDelete = gobjects(0,1);

for typeIndex = 1:numel(graphicTypes)
    matches = findall( ...
        ax, ...
        "Type",graphicTypes(typeIndex));

    if ~isempty(matches)
        objectsToDelete = [ ...
            objectsToDelete; ...
            matches(:)]; %#ok<AGROW>
    end
end

if ~isempty(objectsToDelete)
    objectsToDelete = unique(objectsToDelete);

    validMask = isvalid(objectsToDelete);
    objectsToDelete = objectsToDelete(validMask);

    if ~isempty(objectsToDelete)
        delete(objectsToDelete);
    end
end

hold(ax,"off");
ax.NextPlot = "replace";

setAutomaticMode(ax,"XLimMode");
setAutomaticMode(ax,"YLimMode");
setAutomaticMode(ax,"ZLimMode");
setAutomaticMode(ax,"CLimMode");
setAutomaticMode(ax,"ALimMode");
setAutomaticMode(ax,"XTickMode");
setAutomaticMode(ax,"YTickMode");
setAutomaticMode(ax,"ZTickMode");
setAutomaticMode(ax,"XTickLabelMode");
setAutomaticMode(ax,"YTickLabelMode");
setAutomaticMode(ax,"ZTickLabelMode");
end

function setAutomaticMode(ax,propertyName)
if isprop(ax,propertyName)
    try
        ax.(propertyName) = "auto";
    catch
        % No bloquear el render por diferencias entre versiones.
    end
end
end
