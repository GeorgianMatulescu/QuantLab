function plotTradeSessionChart(ax,sessionData,tradeRow)
%PLOTTRADESESSIONCHART Dibuja la sesión y los niveles operativos.
%
% Convención visual:
% - Entrada: flecha azul; la orientación indica compra o venta.
% - Salida TARGET: flecha verde.
% - Salida STOP: flecha roja.
% - Salida BREAKEVEN: flecha gris.
% - Salida TRAILING_STOP: flecha morada.
% - Salida EOD: flecha naranja.
% - ORB High/Low: línea negra discontinua.
% - Stop: rojo, independientemente de la dirección.
% - Target: verde, independientemente de la dirección.
% - Entrada: azul, independientemente de la dirección.
% - Salida EOD: naranja, independientemente de la dirección.
% - Entrada y salida exactas: unidas mediante línea de puntos gris oscuro fina.

resetResearchAxes(ax);
hold(ax,"on");

time = resolveChartTime(sessionData);

% Colores semánticos de los niveles operativos.
stopColor = [0.85 0.10 0.10];
targetColor = [0.10 0.60 0.20];
entryColor = [0.00 0.4470 0.7410];
eodColor = [0.95 0.45 0.05];
breakEvenColor = [0.40 0.40 0.40];
trailingColor = [0.4940 0.1840 0.5560];

orbColor = [0.00 0.00 0.00];
direction = upper(string(readField(tradeRow,"direction","")));
executedTrade = isExecutedTrade(tradeRow);
crtMode = isCRTContext(tradeRow);

priceRange = max(sessionData.high)-min(sessionData.low);

if priceRange<=0
    priceRange = max(abs(sessionData.close(1))*0.01,1);
end

xStart = time(1);
xEnd = time(end);
xSpan = xEnd-xStart;
leftLevelLabelX = xStart+xSpan*0.02;

if crtMode
    drawCRTContext( ...
        ax,tradeRow,time,priceRange,executedTrade);
end

drawOHLCBarsVectorized(ax,sessionData);

if ~crtMode
    % ORB en negro y discontinuo.
    drawLevel( ...
        ax,tradeRow,"orb_high","ORB High","--", ...
        orbColor,0.9, ...
        xStart+xSpan*0.70, ...
        priceRange*0.030);

    drawLevel( ...
        ax,tradeRow,"orb_low","ORB Low","--", ...
        orbColor,0.9, ...
        xStart+xSpan*0.82, ...
        -priceRange*0.032);
end

% Los precios teóricos pueden existir aunque el trade haya sido descartado.
% Solo se dibujan niveles y ejecuciones cuando la operación fue real.
if executedTrade
    exitManagement = upper(string(readField( ...
        tradeRow,"exit_management","FIXED_TARGET")));
    if exitManagement=="SWING_TRAILING_STEP_TARGET"
        drawTargetStepLevels( ...
            ax,tradeRow,time,priceRange,targetColor);
    else
        drawLevel( ...
            ax,tradeRow,"target_price","Target","-", ...
            targetColor,0.8, ...
            leftLevelLabelX, ...
            priceRange*0.018);
    end

    drawLevel( ...
        ax,tradeRow,"stop_price","Stop","-", ...
        stopColor,0.8, ...
        leftLevelLabelX, ...
        -priceRange*0.022);

    drawLevel( ...
        ax,tradeRow,"entry_price","Entrada","-", ...
        entryColor,0.9, ...
        leftLevelLabelX, ...
        priceRange*0.018);

    drawBreakEvenLevel( ...
        ax,tradeRow,time,priceRange,breakEvenColor);
    drawTrailingStopLevels( ...
        ax,tradeRow,time,priceRange,trailingColor);

    exitReason = upper(string(readField( ...
        tradeRow,"exit_reason","")));
    if exitReason=="EOD"
        drawLevel( ...
            ax,tradeRow,"exit_price","Salida EOD","-", ...
            eodColor,0.9, ...
            xStart+xSpan*0.78, ...
            -priceRange*0.022);
    end

    drawTradeConnection(ax,tradeRow);

    entryMarkerColor = resolveResearchExecutionMarkerColor( ...
        "ENTRY","");
    drawExecutionArrow( ...
        ax,sessionData,tradeRow, ...
        "entry_time","entry_price", ...
        getEntrySide(direction), ...
        entryMarkerColor,priceRange);

    exitMarkerColor = resolveResearchExecutionMarkerColor( ...
        "EXIT",exitReason);
    drawExecutionArrow( ...
        ax,sessionData,tradeRow, ...
        "exit_time","exit_price", ...
        getExitSide(direction), ...
        exitMarkerColor,priceRange);
end

chartTitle = string(tradeRow.session_date(1),"yyyy-MM-dd");
sessionName = string(readField(tradeRow,"session_name",""));
if strlength(sessionName)>0
    chartTitle = chartTitle + " — " + sessionName;
end
if strlength(direction)>0
    chartTitle = chartTitle + " — " + direction;
end

if ~executedTrade
    chartTitle = chartTitle + " — NO EJECUTADO";
end

title(ax,chartTitle);

if crtMode
    xlabel(ax,"Hora de Madrid");
else
    xlabel(ax,"Hora de Nueva York");
end
ylabel(ax,"Precio");
xlim(ax,[time(1) time(end)]);
grid(ax,"on");

try
    ax.YAxis.Exponent = 0;
catch
end

try
    ytickformat(ax,"%.2f");
catch
end

hold(ax,"off");
end

function drawTargetStepLevels(ax,row,axisTime,priceRange,lineColor)
entryTime = readDateTime(row,"entry_time",NaT);
exitTime = readDateTime(row,"exit_time",NaT);
initialPrice = readField(row,"target_price",NaN);
if isnat(entryTime) || isnat(exitTime) || ~isfinite(initialPrice)
    return;
end

times = readEncodedTimeSeries(row,"target_step_times",axisTime);
prices = readEncodedNumericSeries(row,"target_step_prices");
entryTime = alignToAxisZone(entryTime,axisTime);
exitTime = alignToAxisZone(exitTime,axisTime);
[entryTime,exitTime] = alignDateTimePair(entryTime,exitTime);

% Un trade gestionado con TP escalonado puede cerrar antes de alcanzar
% 1,5R. En ese caso no existe todavía ningún escalón y `times` es un
% datetime vacío. MATLAB no permite concatenar un datetime vacío sin zona
% con `entryTime` zonado, aunque el array vacío no aporte elementos.
% Evitar esa concatenación mantiene representables también esos trades.
starts = entryTime;
if ~isempty(times)
    [entryTime,times] = alignDateTimePair(entryTime,times);
    starts = [entryTime; times(:)];
end
levels = [initialPrice; prices(:)];
if numel(starts)==1
    ends = exitTime;
else
    ends = [starts(2:end); exitTime];
end
for i = 1:min([numel(starts),numel(ends),numel(levels)])
    drawBoundedLevel(ax,starts(i),ends(i),levels(i), ...
        "TP escalón","-",lineColor,0.9,priceRange*0.014);
end
end

function drawTrailingStopLevels(ax,row,axisTime,priceRange,lineColor)
times = readEncodedTimeSeries(row,"trailing_stop_times",axisTime);
prices = readEncodedNumericSeries(row,"trailing_stop_prices");
exitTime = readDateTime(row,"exit_time",NaT);
if isempty(times) || isempty(prices) || isnat(exitTime)
    return;
end

exitTime = alignToAxisZone(exitTime,axisTime);
[times,exitTime] = alignDateTimePair(times,exitTime);
ends = [times(2:end); exitTime];
for i = 1:min([numel(times),numel(ends),numel(prices)])
    drawBoundedLevel(ax,times(i),ends(i),prices(i), ...
        "Trail swing","-.",lineColor,1.2,priceRange*0.014);
end
end

function values = readEncodedNumericSeries(row,fieldName)
values = zeros(0,1);
if ~ismember(fieldName,string(row.Properties.VariableNames))
    return;
end
encoded = string(row.(fieldName)(1));
if strlength(encoded)==0, return; end
values = str2double(split(encoded,";"));
values = values(isfinite(values));
end

function values = readEncodedTimeSeries(row,fieldName,axisTime)
epoch = readEncodedNumericSeries(row,fieldName);
if isempty(epoch)
    values = NaT(0,1);
    return;
end
timezone = string(axisTime.TimeZone);
if strlength(timezone)==0, timezone = "UTC"; end
values = datetime(epoch,"ConvertFrom","posixtime", ...
    "TimeZone",char(timezone));
end

function drawBreakEvenLevel(ax,row,axisTime,priceRange,lineColor)
%DRAWBREAKEVENLEVEL Dibuja el stop dinámico solo cuando llegó a activarse.

triggered = logical(readField(row,"break_even_triggered",false));
if ~triggered
    return;
end

startTime = readDateTime(row,"break_even_effective_time",NaT);
endTime = readDateTime(row,"exit_time",NaT);
price = readField(row,"break_even_price",NaN);
if isnat(startTime) || isnat(endTime) || ...
        ~isnumeric(price) || ~isfinite(price)
    return;
end

startTime = alignToAxisZone(startTime,axisTime);
endTime = alignToAxisZone(endTime,axisTime);
drawBoundedLevel( ...
    ax,startTime,endTime,price,"Break-even","--", ...
    lineColor,1.1,priceRange*0.014);
end

function tf = isCRTContext(row)
required = [ ...
    "ref_start","ref_end","man_end","crt_high","crt_low"];
tf = all(ismember(required,string(row.Properties.VariableNames)));
if ~tf
    return;
end

tf = isdatetime(row.ref_start(1)) && ~isnat(row.ref_start(1)) && ...
    isdatetime(row.ref_end(1)) && ~isnat(row.ref_end(1)) && ...
    isdatetime(row.man_end(1)) && ~isnat(row.man_end(1)) && ...
    isfinite(row.crt_high(1)) && isfinite(row.crt_low(1));
end

function drawCRTContext(ax,row,axisTime,priceRange,executedTrade)
%DRAWCRTCONTEXT Replica el indicador CRT de TradingView para auditoría.

refStart = alignToAxisZone(row.ref_start(1),axisTime);
refEnd = alignToAxisZone(row.ref_end(1),axisTime);
manEnd = alignToAxisZone(row.man_end(1),axisTime);
crtHigh = row.crt_high(1);
crtLow = row.crt_low(1);

boxColor = [0.00 0.4470 0.7410];
levelColor = [0.05 0.05 0.05];
midColor = [0.85 0.3250 0.0980];

% Sombreado suave de la vela/rango de referencia de tres horas. Algunas
% versiones antiguas de MATLAB no admiten datetime en fill; el borde sigue
% dibujándose como fallback y mantiene la auditoría exacta de niveles.
try
    fill(ax, ...
        [refStart refEnd refEnd refStart], ...
        [crtHigh crtHigh crtLow crtLow], ...
        boxColor, ...
        "FaceAlpha",0.08, ...
        "EdgeColor","none", ...
        "HandleVisibility","off");
catch
end

plot(ax,[refStart refEnd],[crtHigh crtHigh],"-", ...
    "Color",boxColor,"LineWidth",1.0,"HandleVisibility","off");
plot(ax,[refStart refEnd],[crtLow crtLow],"-", ...
    "Color",boxColor,"LineWidth",1.0,"HandleVisibility","off");
plot(ax,[refStart refStart],[crtLow crtHigh],"-", ...
    "Color",boxColor,"LineWidth",1.0,"HandleVisibility","off");
plot(ax,[refEnd refEnd],[crtLow crtHigh],"-", ...
    "Color",boxColor,"LineWidth",1.0,"HandleVisibility","off");

drawBoundedLevel(ax,refEnd,manEnd,crtHigh, ...
    "CRT máximo","--",levelColor,0.9,priceRange*0.018);
drawBoundedLevel(ax,refEnd,manEnd,crtLow, ...
    "CRT mínimo","--",levelColor,0.9,-priceRange*0.020);

entryLevel = readField(row,"entry_level", ...
    readField(row,"entry_level_50",NaN));
entryFraction = readField(row,"entry_fraction",0.5);
if isnumeric(entryLevel) && isfinite(entryLevel)
    midStart = readDateTime(row,"extreme_time",NaT);
    if isnat(midStart)
        midStart = readDateTime(row,"sweep_time",refEnd);
    end
    midStart = alignToAxisZone(midStart,axisTime);

    midEnd = manEnd;
    touchTime = readDateTime(row,"order_time",NaT);
    if isnat(touchTime) && executedTrade
        touchTime = readDateTime(row,"entry_time",NaT);
    end
    if ~isnat(touchTime)
        touchTime = alignToAxisZone(touchTime,axisTime);
        if touchTime>=midStart && touchTime<=manEnd
            midEnd = touchTime;
        end
    end

    entryLabel = string(sprintf("%.1f %%",100*entryFraction));
    drawBoundedLevel(ax,midStart,midEnd,entryLevel, ...
        entryLabel,"--",midColor,1.1,priceRange*0.014);
end

extreme = readField(row,"manipulation_extreme",NaN);
extremeTime = readDateTime(row,"extreme_time",NaT);
if isnumeric(extreme) && isfinite(extreme) && ~isnat(extremeTime)
    extremeTime = alignToAxisZone(extremeTime,axisTime);
    plot(ax,extremeTime,extreme,"o", ...
        "MarkerSize",4, ...
        "MarkerFaceColor",midColor, ...
        "MarkerEdgeColor",midColor, ...
        "HandleVisibility","off");
end
end

function drawBoundedLevel( ...
    ax,startTime,endTime,value,labelText,lineStyle,lineColor, ...
    lineWidth,labelOffset)

if isnat(startTime) || isnat(endTime) || ~isfinite(value) || ...
        endTime<startTime
    return;
end

plot(ax,[startTime endTime],[value value],lineStyle, ...
    "Color",lineColor, ...
    "LineWidth",lineWidth, ...
    "HandleVisibility","off");

text(ax,endTime,value+labelOffset,labelText, ...
    "HorizontalAlignment","right", ...
    "VerticalAlignment","middle", ...
    "FontSize",8, ...
    "Color",lineColor, ...
    "BackgroundColor",[1 1 1], ...
    "Margin",1, ...
    "Clipping","on");
end

function value = readDateTime(row,name,defaultValue)
value = readField(row,name,defaultValue);
if ~isdatetime(value)
    value = defaultValue;
end
end

function value = alignToAxisZone(value,axisTime)
if ~isdatetime(value) || isnat(value) || isempty(axisTime)
    return;
end
if ~isempty(axisTime.TimeZone)
    value.TimeZone = axisTime.TimeZone;
end
end

function time = resolveChartTime(sessionData)
variables = string(sessionData.Properties.VariableNames);
if ismember("datetime_local",variables)
    time = sessionData.datetime_local;
elseif ismember("datetime_new_york",variables)
    time = sessionData.datetime_new_york;
else
    error("QuantLab:TradeResearchMissingTime", ...
        "La sesión no contiene datetime_local ni datetime_new_york.");
end
end


function drawOHLCBarsVectorized(ax,sessionData)
%DRAWOHLCBARSVECTORIZED Dibuja todas las barras con solo tres objetos.
%
% La versión anterior realizaba tres llamadas a plot por barra:
% 390 barras x 3 = aproximadamente 1.170 objetos gráficos.
%
% Esta versión agrupa mechas, aperturas y cierres mediante separadores
% NaT/NaN y crea únicamente tres objetos Line.

time = resolveChartTime(sessionData);
time = time(:);
openPrice = sessionData.open(:);
highPrice = sessionData.high(:);
lowPrice = sessionData.low(:);
closePrice = sessionData.close(:);

n = numel(time);

separatorTime = NaT(n,1);

try
    separatorTime.TimeZone = time.TimeZone;
catch
end

separatorPrice = nan(n,1);
halfWidth = seconds(18);

wickX = reshape( ...
    [time time separatorTime].', ...
    [],1);

wickY = reshape( ...
    [lowPrice highPrice separatorPrice].', ...
    [],1);

openX = reshape( ...
    [time-halfWidth time separatorTime].', ...
    [],1);

openY = reshape( ...
    [openPrice openPrice separatorPrice].', ...
    [],1);

closeX = reshape( ...
    [time time+halfWidth separatorTime].', ...
    [],1);

closeY = reshape( ...
    [closePrice closePrice separatorPrice].', ...
    [],1);

barColor = [0.35 0.35 0.35];

plot(ax,wickX,wickY, ...
    "Color",barColor, ...
    "LineWidth",0.5, ...
    "HandleVisibility","off");

plot(ax,openX,openY, ...
    "Color",barColor, ...
    "LineWidth",0.7, ...
    "HandleVisibility","off");

plot(ax,closeX,closeY, ...
    "Color",barColor, ...
    "LineWidth",0.7, ...
    "HandleVisibility","off");
end

function drawLevel( ...
    ax,row,field,labelText,lineStyle,lineColor,lineWidth, ...
    labelX,labelOffset)

if ~ismember(field,string(row.Properties.VariableNames))
    return;
end

value = row.(field)(1);

if ~isnumeric(value) || ~isfinite(value)
    return;
end

yline(ax,value,lineStyle, ...
    "Color",lineColor, ...
    "LineWidth",lineWidth, ...
    "HandleVisibility","off");

text(ax,labelX,value+labelOffset,labelText, ...
    "HorizontalAlignment","left", ...
    "VerticalAlignment","middle", ...
    "FontSize",9, ...
    "Color",lineColor, ...
    "BackgroundColor",[1 1 1], ...
    "Margin",2, ...
    "Clipping","on");
end

function drawTradeConnection(ax,row)
%DRAWTRADECONNECTION Une entrada y salida exactas.

requiredFields = [ ...
    "entry_time","entry_price", ...
    "exit_time","exit_price"];

if ~all(ismember( ...
        requiredFields, ...
        string(row.Properties.VariableNames)))
    return;
end

entryTime = row.entry_time(1);
entryPrice = row.entry_price(1);
exitTime = row.exit_time(1);
exitPrice = row.exit_price(1);

if ~isdatetime(entryTime) || isnat(entryTime) || ...
        ~isdatetime(exitTime) || isnat(exitTime) || ...
        ~isnumeric(entryPrice) || ~isfinite(entryPrice) || ...
        ~isnumeric(exitPrice) || ~isfinite(exitPrice)
    return;
end

[entryTime,exitTime] = alignDateTimePair( ...
    entryTime,exitTime);

plot(ax, ...
    [entryTime exitTime], ...
    [entryPrice exitPrice], ...
    ":", ...
    "Color",[0.25 0.25 0.25], ...
    "LineWidth",0.75, ...
    "HandleVisibility","off");
end

function drawExecutionArrow( ...
    ax,sessionData,row,timeField,priceField,side, ...
    markerColor,priceRange)

if strlength(side)==0
    return;
end

if ~ismember(timeField,string(row.Properties.VariableNames)) || ...
        ~ismember(priceField,string(row.Properties.VariableNames))
    return;
end

executionTime = row.(timeField)(1);
executionPrice = row.(priceField)(1);

if ~isdatetime(executionTime) || isnat(executionTime) || ...
        ~isnumeric(executionPrice) || ~isfinite(executionPrice)
    return;
end

sessionTime = resolveChartTime(sessionData);

if ~isempty(sessionTime.TimeZone)
    executionTime.TimeZone = sessionTime.TimeZone;
elseif ~isempty(executionTime.TimeZone)
    sessionTime.TimeZone = executionTime.TimeZone;
end

[~,barIndex] = min(abs(sessionTime-executionTime));

barTime = sessionTime(barIndex);
markerOffset = max(priceRange*0.028,0.5);

switch side
    case "BUY"
        markerY = sessionData.low(barIndex)-markerOffset;

        plot(ax,barTime,markerY,"^", ...
            "MarkerSize",9, ...
            "MarkerFaceColor",markerColor, ...
            "MarkerEdgeColor",markerColor, ...
            "LineWidth",1.0, ...
            "HandleVisibility","off");

    case "SELL"
        markerY = sessionData.high(barIndex)+markerOffset;

        plot(ax,barTime,markerY,"v", ...
            "MarkerSize",9, ...
            "MarkerFaceColor",markerColor, ...
            "MarkerEdgeColor",markerColor, ...
            "LineWidth",1.0, ...
            "HandleVisibility","off");
end
end


function [firstTime,secondTime] = alignDateTimePair( ...
    firstTime,secondTime)
%ALIGNDATETIMEPAIR Alinea dos datetime para poder concatenarlos.

firstZone = string(firstTime.TimeZone);
secondZone = string(secondTime.TimeZone);

if strlength(firstZone)>0
    secondTime.TimeZone = char(firstZone);
elseif strlength(secondZone)>0
    firstTime.TimeZone = char(secondZone);
end
end

function side = getEntrySide(direction)
switch direction
    case "LONG"
        side = "BUY";
    case "SHORT"
        side = "SELL";
    otherwise
        side = "";
end
end

function side = getExitSide(direction)
switch direction
    case "LONG"
        side = "SELL";
    case "SHORT"
        side = "BUY";
    otherwise
        side = "";
end
end


function executed = isExecutedTrade(row)
valid = readField(row,"valid",false);
contracts = readField(row,"contracts",0);
entryTime = readField(row,"entry_time",NaT);
entryPrice = readField(row,"entry_price",NaN);

validFlag = ...
    (islogical(valid) && valid) || ...
    (isnumeric(valid) && isfinite(valid) && valid==1);

contractsFlag = ...
    isnumeric(contracts) && isfinite(contracts) && contracts>0;

timeFlag = isdatetime(entryTime) && ~isnat(entryTime);
priceFlag = isnumeric(entryPrice) && isfinite(entryPrice);

executed = validFlag && contractsFlag && timeFlag && priceFlag;
end

function value = readField(row,name,defaultValue)
if ismember(name,string(row.Properties.VariableNames))
    value = row.(name)(1);
else
    value = defaultValue;
end
end
