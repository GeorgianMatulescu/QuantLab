function details = buildTradeResearchDetails( ...
    tradeRow,tradeIndex,profileName,varargin)
%BUILDTRADERESEARCHDETAILS Construye la ficha legible del trade.

recordLabel = "Trade";
if ~isempty(varargin) && strlength(string(varargin{1}))>0
    recordLabel = string(varargin{1});
end

labels = [ ...
    recordLabel;"Fecha";"Perfil";"Ejecutado";"Dirección"; ...
    "Entrada";"Stop";"Target";"Salida";"Motivo salida"; ...
    "Contratos";"Resultado R";"PnL neto";"MFE";"MAE"; ...
    "Equity antes";"Equity después";"Motivo no ejecución"];

values = strings(size(labels));

values(1) = "#" + string(tradeIndex);
values(2) = formatDate(readField(tradeRow,"session_date",NaT));
values(3) = string(profileName);
values(4) = formatLogical(readField(tradeRow,"valid",false));
values(5) = string(readField(tradeRow,"direction",""));
values(6) = formatNumber(readField(tradeRow,"entry_price",NaN),2);
values(7) = formatNumber(readField(tradeRow,"stop_price",NaN),2);
values(8) = formatNumber(readField(tradeRow,"target_price",NaN),2);
values(9) = formatNumber(readField(tradeRow,"exit_price",NaN),2);
values(10) = string(readField(tradeRow,"exit_reason",""));
values(11) = formatNumber(readField(tradeRow,"contracts",NaN),0);
values(12) = appendUnit( ...
    formatNumber(readField(tradeRow,"net_R",NaN),3)," R");
values(13) = formatCurrency(readField(tradeRow,"net_pnl_usd",NaN));
values(14) = appendUnit( ...
    formatNumber(readField(tradeRow,"mfe_R",NaN),3)," R");
values(15) = appendUnit( ...
    formatNumber(readField(tradeRow,"mae_R",NaN),3)," R");
values(16) = formatCurrency( ...
    readField(tradeRow,"equity_before_usd",NaN));
values(17) = formatCurrency( ...
    readField(tradeRow,"equity_after_usd",NaN));
values(18) = translateStatus(readField(tradeRow,"skip_reason",""));

optionalRows = [ ...
    "Sesión","session_name","TEXT"; ...
    "Rango de referencia","reference_range","TEXT"; ...
    "Tipo de señal","signal_name","TEXT"; ...
    "Estado setup","setup_status","STATUS"; ...
    "Estado orden","order_status","STATUS"; ...
    "Entrada permitida desde","entry_start","TIME"; ...
    "Hora barrido","sweep_time","TIME"; ...
    "Último extremo","extreme_time","TIME"; ...
    "Lado barrido","sweep_side","TEXT"; ...
    "Máximo CRT","crt_high","PRICE"; ...
    "Mínimo CRT","crt_low","PRICE"; ...
    "Extremo manipulación","manipulation_extreme","PRICE"; ...
    "Fracción entrada","entry_fraction","DECIMAL"; ...
    "Nivel de entrada","entry_level","PRICE"; ...
    "RR planificado","reward_risk_planned","R"; ...
    "Versión reglas","rules_version","TEXT"; ...
    "Hora orden","order_time","TIME"; ...
    "Precio orden","order_price","PRICE"; ...
    "Riesgo teórico","risk_points","POINTS"; ...
    "Activación break-even","break_even_trigger_r","R"; ...
    "Nivel activación BE","break_even_trigger_price","PRICE"; ...
    "Precio break-even","break_even_price","PRICE"; ...
    "Hora activación BE","break_even_trigger_time","TIME"; ...
    "BE efectivo desde","break_even_effective_time","TIME"; ...
    "Gestión de salida","exit_management","TEXT"; ...
    "Activación trailing","trailing_activation_r","R"; ...
    "Nivel activación trail","trailing_activation_price","PRICE"; ...
    "Escalón TP","trailing_target_step_r","R"; ...
    "Trailing activado","trailing_activated","BOOL"; ...
    "Hora activación trail","trailing_activation_time","TIME"; ...
    "Escalones avanzados","target_steps_advanced","INTEGER"; ...
    "TP virtual final","final_target_r","R"; ...
    "Precio TP virtual final","final_target_price","PRICE"; ...
    "Stop trailing final","trailing_stop_price","PRICE"; ...
    "Stop trailing efectivo","trailing_stop_effective_time","TIME"];

variables = string(tradeRow.Properties.VariableNames);
for i = 1:size(optionalRows,1)
    field = optionalRows(i,2);
    if ~ismember(field,variables)
        continue;
    end

    rawValue = tradeRow.(field)(1);
    switch optionalRows(i,3)
        case "TIME"
            formatted = formatTime(rawValue);
        case "PRICE"
            formatted = formatNumber(rawValue,2);
        case "POINTS"
            formatted = appendUnit(formatNumber(rawValue,2)," pt");
        case "R"
            formatted = appendUnit(formatNumber(rawValue,2)," R");
        case "STATUS"
            formatted = translateStatus(rawValue);
        case "BOOL"
            formatted = formatLogical(rawValue);
        case "INTEGER"
            formatted = formatNumber(rawValue,0);
        case "DECIMAL"
            formatted = formatNumber(rawValue,3);
        otherwise
            formatted = string(rawValue);
    end

    if strlength(formatted)==0
        continue;
    end
    labels(end+1,1) = optionalRows(i,1); %#ok<AGROW>
    values(end+1,1) = formatted; %#ok<AGROW>
end

details = table( ...
    labels,values, ...
    'VariableNames',{'Metric','Value'});
end

function value = readField(row,name,defaultValue)
if ismember(name,string(row.Properties.VariableNames))
    value = row.(name)(1);
else
    value = defaultValue;
end
end

function text = formatNumber(value,decimals)
if isnumeric(value) && isfinite(value)
    text = string(sprintf("%.*f",decimals,value));
else
    text = "";
end
end

function text = appendUnit(value,unit)
if strlength(value)==0
    text = "";
else
    text = value + unit;
end
end

function text = formatCurrency(value)
if isnumeric(value) && isfinite(value)
    text = string(sprintf("%.2f USD",value));
else
    text = "";
end
end

function text = formatDate(value)
if isdatetime(value) && ~isnat(value)
    text = string(value,"yyyy-MM-dd");
else
    text = "";
end
end

function text = formatTime(value)
if isdatetime(value) && ~isnat(value)
    text = string(value,"HH:mm:ss");
else
    text = "";
end
end

function text = translateStatus(value)
value = upper(string(value));
switch value
    case "EXECUTED"
        text = "Ejecutado";
    case "SETUP_DETECTED"
        text = "Setup detectado";
    case "NO_SETUP"
        text = "Sin manipulación válida";
    case "FILLED"
        text = "Ejecutada";
    case "NOT_CREATED"
        text = "No creada";
    case "NOT_TRIGGERED"
        text = "Nivel de entrada no tocado";
    case "REJECTED"
        text = "Rechazada";
    case "RISK_TOO_LARGE"
        text = "Riesgo superior al presupuesto; cantidad 0";
    case "SETUP_NO_ENTRY"
        text = "Setup válido, pero el nivel de entrada no fue tocado";
    case "ENTRY_BEFORE_ALLOWED_TIME"
        text = "Entrada descartada: antes de la hora operable";
    case "LONDON_TP_BLOCK"
        text = "NY omitida porque Londres alcanzó TP";
    case "POSITION_OPEN"
        text = "Ventana bloqueada por una posición abierta";
    case "INCOMPLETE_EXTENDED_DATA"
        text = "Datos extendidos incompletos";
    case "INVALID_EXECUTION_LEVELS"
        text = "Niveles de entrada, stop o target inválidos";
    case "SESSION_DISABLED"
        text = "Sesión desactivada";
    case "NOT_EVALUATED"
        text = "No evaluado";
    case "NOT_EVALUABLE"
        text = "No evaluable";
    case "BLOCKED"
        text = "Bloqueado";
    otherwise
        text = string(value);
end
end

function text = formatLogical(value)
if (islogical(value) && value) || ...
        (isnumeric(value) && value==1)
    text = "Sí";
else
    text = "No";
end
end
