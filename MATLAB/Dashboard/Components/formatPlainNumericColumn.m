function output = formatPlainNumericColumn( ...
    values,decimalPlaces,trimTrailingZeros)
%FORMATPLAINNUMERICCOLUMN Formatea una columna sin exponentes.

arguments
    values
    decimalPlaces (1,1) double ...
        {mustBeInteger,mustBeNonnegative} = 4
    trimTrailingZeros (1,1) logical = false
end

values = double(values);
output = strings(size(values));

for i = 1:numel(values)
    output(i) = formatPlainNumber( ...
        values(i),decimalPlaces,trimTrailingZeros);
end
end
