function updateResearchKPIBar(kpiCards,m)
%UPDATERESEARCHKPIBAR Actualiza los KPIs superiores del Research Terminal.

arguments
    kpiCards
    m (1,1) struct
end

values = [ ...
    formatCurrency(m.endEquity), ...
    formatCurrency(-m.totalFees), ...
    formatCurrency(0), ...
    formatCurrency(m.netProfitUSD), ...
    formatPercentOrNA(m.psrPct), ...
    sprintf("%.2f %%",m.returnPct), ...
    formatCurrency(0), ...
    formatQuantity(readTotalQuantity(m))];

for i = 1:numel(values)
    kpiCards(i).UserData.Text = values(i);
end

setSignedColor(kpiCards(1).UserData,m.endEquity-m.startEquity);
setSignedColor(kpiCards(2).UserData,-m.totalFees);
setNeutralColor(kpiCards(3).UserData);
setSignedColor(kpiCards(4).UserData,m.netProfitUSD);
setSignedColor(kpiCards(5).UserData,m.psrPct);
setSignedColor(kpiCards(6).UserData,m.returnPct);
setNeutralColor(kpiCards(7).UserData);
setNeutralColor(kpiCards(8).UserData);
end

function setSignedColor(label,value)
if isnan(value)
    label.FontColor = [0.45 0.45 0.45];
elseif value>0
    label.FontColor = [0.00 0.55 0.10];
elseif value<0
    label.FontColor = [0.85 0.05 0.05];
else
    label.FontColor = [0.45 0.45 0.45];
end
end

function setNeutralColor(label)
label.FontColor = [0.45 0.45 0.45];
end

function text = formatCurrency(value)
if isnan(value)
    text = "N/A";
else
    text = string(sprintf("$%.2f",value));
end
end

function text = formatPercentOrNA(value)
if isnan(value)
    text = "N/A";
else
    text = string(sprintf("%.3f %%",value));
end
end


function value = readTotalQuantity(m)
if isfield(m,"totalQuantity")
    value = m.totalQuantity;
else
    value = m.totalContracts;
end
end

function text = formatQuantity(value)
if ~isfinite(value)
    text = "N/A";
    return;
end

raw = sprintf("%.6f",value);
raw = regexprep(raw,"0+$","");
raw = regexprep(raw,"\.$","");
text = string(raw);
end
