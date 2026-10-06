function output = formatPlainNumber(value,decimalPlaces,trimTrailingZeros)
%FORMATPLAINNUMBER Convierte un escalar numérico sin notación científica.
%
% Ejemplos:
%   formatPlainNumber(1213.9,2,false) -> "1213.90"
%   formatPlainNumber(0.00012,6,true) -> "0.00012"
%   formatPlainNumber(NaN,2,false)    -> ""

arguments
    value (1,1) double
    decimalPlaces (1,1) double ...
        {mustBeInteger,mustBeNonnegative} = 4
    trimTrailingZeros (1,1) logical = false
end

if isnan(value)
    output = "";
    return;
elseif isinf(value)
    if value>0
        output = "Inf";
    else
        output = "-Inf";
    end
    return;
end

formatSpec = "%." + string(decimalPlaces) + "f";
output = string(sprintf(char(formatSpec),value));

if trimTrailingZeros && contains(output,".")
    output = regexprep(output,'0+$','');
    output = regexprep(output,'\.$','');
end

if output=="-0" || ...
        ~isempty(regexp(output,'^-0\.0+$','once'))
    if trimTrailingZeros
        output = "0";
    else
        output = string(sprintf(char(formatSpec),0));
    end
end
end
