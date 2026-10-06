function formatAxesNatural(ax,mode)
%FORMATAXESNATURAL Evita notación científica en ejes numéricos.
%
% No aplica ytickformat a ejes categóricos, porque MATLAB no lo permite.
%
% mode:
%   money   -> cantidades monetarias sin exponente
%   percent -> porcentajes con dos decimales
%   ratio   -> ratios entre 0 y 1
%   decimal -> valores decimales legibles
%   integer -> enteros

arguments
    ax
    mode (1,1) string = "decimal"
end

% Detectar el tipo de ruler del eje Y.
try
    yRuler = ax.YAxis;
catch
    return;
end

% Los ejes categóricos no admiten ytickformat.
if isa(yRuler, "matlab.graphics.axis.decorator.CategoricalRuler")
    return;
end

% Desactivar exponente científico cuando la propiedad esté disponible.
try
    yRuler.Exponent = 0;
catch
end

% Aplicar formato solo en ejes numéricos compatibles.
try
    switch lower(mode)
        case "money"
            ytickformat(ax, "%.0f");

        case "percent"
            ytickformat(ax, "%.2f");

        case "ratio"
            ytickformat(ax, "%.2f");

        case "integer"
            ytickformat(ax, "%.0f");

        otherwise
            ytickformat(ax, "%.2f");
    end
catch
    % Mantener el formato predeterminado si la versión de MATLAB o el
    % tipo de eje no admite ytickformat.
end
end
