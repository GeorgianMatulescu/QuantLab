function app = quantlab()
%QUANTLAB Selector visual universal de estrategia e instrumento.
%
% Ejecuta `quantlab` desde MATLAB. Las estrategias se descubren desde
% MATLAB/Strategies, de modo que instalar otro plugin no requiere modificar
% este lanzador ni crear nuevos scripts run/launch.

matlabRoot = string(fileparts(mfilename('fullpath')));
addpath(genpath(matlabRoot));
registry = getStrategyRegistry();
registry = registry([registry.enabled]);
if isempty(registry)
    error("QuantLab:NoEnabledStrategies", ...
        "No hay estrategias habilitadas para ejecutar.");
end

strategyNames = string({registry.name});
strategyLabels = string({registry.displayName}) + ...
    "  [" + strategyNames + "]  v" + string({registry.version});
instruments = ["MNQ","MES","MYM","NQ","ES","YM"];

app = uifigure( ...
    "Name","QuantLab — Strategy Launcher", ...
    "Position",[180 130 620 470], ...
    "Color",[0.965 0.97 0.98]);
grid = uigridlayout(app,[7 2]);
grid.RowHeight = {58,28,42,28,100,54,'1x'};
grid.ColumnWidth = {'1x','1x'};
grid.Padding = [28 24 28 22];
grid.RowSpacing = 8;
grid.ColumnSpacing = 14;

titleLabel = uilabel(grid, ...
    "Text","QuantLab Strategy Launcher", ...
    "FontSize",22,"FontWeight","bold", ...
    "FontColor",[0.07 0.12 0.20]);
titleLabel.Layout.Row = 1;
titleLabel.Layout.Column = [1 2];

strategyLabel = uilabel(grid,"Text","Estrategia", ...
    "FontWeight","bold");
strategyLabel.Layout.Row = 2;
strategyLabel.Layout.Column = 1;
strategyDropDown = uidropdown(grid, ...
    "Items",cellstr(strategyLabels), ...
    "ItemsData",cellstr(strategyNames));
strategyDropDown.Layout.Row = 3;
strategyDropDown.Layout.Column = [1 2];
defaultIndex = find(strategyNames=="CRT_3H_MADRID",1,"first");
if isempty(defaultIndex), defaultIndex = 1; end
strategyDropDown.Value = char(strategyNames(defaultIndex));

instrumentLabel = uilabel(grid,"Text","Instrumento(s)", ...
    "FontWeight","bold");
instrumentLabel.Layout.Row = 4;
instrumentLabel.Layout.Column = 1;
instrumentList = uilistbox(grid, ...
    "Items",cellstr(instruments), ...
    "Multiselect","on", ...
    "Value",{"MNQ"});
instrumentList.Layout.Row = 5;
instrumentList.Layout.Column = [1 2];

runButton = uibutton(grid,"push", ...
    "Text","Ejecutar y abrir dashboard", ...
    "FontWeight","bold", ...
    "BackgroundColor",[0.10 0.36 0.68], ...
    "FontColor",[1 1 1], ...
    "ButtonPushedFcn",@runSelectedStrategy);
runButton.Layout.Row = 6;
runButton.Layout.Column = 1;

openButton = uibutton(grid,"push", ...
    "Text","Abrir último resultado", ...
    "ButtonPushedFcn",@openLatestResult);
openButton.Layout.Row = 6;
openButton.Layout.Column = 2;

statusArea = uitextarea(grid, ...
    "Editable","off", ...
    "Value",[ ...
    "Selecciona una estrategia y uno o varios instrumentos."; ...
    "El botón azul recalcula y guarda; el otro reutiliza la última ejecución."], ...
    "FontName","Consolas", ...
    "BackgroundColor",[0.985 0.987 0.992]);
statusArea.Layout.Row = 7;
statusArea.Layout.Column = [1 2];

    function runSelectedStrategy(~,~)
        strategy = string(strategyDropDown.Value);
        selected = string(instrumentList.Value);
        setBusy(true,"Ejecutando " + strategy + " sobre " + ...
            strjoin(selected,", ") + "...");
        try
            batch = runQuantLabBatch( ...
                strategy,selected,RunBacktest=true, ...
                ExportResults=true,OpenDashboard=true);
            setBusy(false,formatBatchStatus(batch));
            showBatchFailures(batch);
        catch ME
            setBusy(false,"Error: " + string(ME.message));
            uialert(app,ME.message,"No se pudo ejecutar la estrategia", ...
                "Icon","error");
        end
    end

    function openLatestResult(~,~)
        strategy = string(strategyDropDown.Value);
        selected = string(instrumentList.Value);
        setBusy(true,"Abriendo resultados de " + strategy + "...");
        try
            batch = runQuantLabBatch( ...
                strategy,selected,RunBacktest=false, ...
                ExportResults=false,OpenDashboard=true);
            setBusy(false,formatBatchStatus(batch));
            showBatchFailures(batch);
        catch ME
            setBusy(false,"Error: " + string(ME.message));
            uialert(app,ME.message,"No existe un resultado compatible", ...
                "Icon","error");
        end
    end

    function setBusy(isBusy,message)
        state = "on";
        if isBusy, state = "off"; end
        runButton.Enable = state;
        openButton.Enable = state;
        strategyDropDown.Enable = state;
        instrumentList.Enable = state;
        statusArea.Value = cellstr(string(message));
        drawnow;
    end

    function message = formatBatchStatus(batch)
        completed = batch.successfulInstruments;
        message = "Completado: " + batch.strategy + " / " + ...
            strjoin(completed,", ") + ".";
        if ~isempty(batch.failedInstruments)
            message = message + newline + "No disponibles: " + ...
                strjoin(batch.failedInstruments,", ") + ".";
        end
    end

    function showBatchFailures(batch)
        if isempty(batch.failedInstruments), return; end
        failed = batch.summary(~batch.summary.success,:);
        details = join(failed.instrument + ": " + failed.message,newline);
        uialert(app,details,"Algunos instrumentos no se ejecutaron", ...
            "Icon","warning");
    end
end
