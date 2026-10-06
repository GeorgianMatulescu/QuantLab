function app = launchQuantLabDashboard(strategyRun, cfg)
%LAUNCHQUANTLABDASHBOARD Dashboard inspirado en QuantConnect.
% Research Terminal revision: v0.25.37.
% Usa la interfaz genérica de QuantLab:
%   strategyRun.strategy
%   strategyRun.results.<PROFILE>.trades
%   strategyRun.results.summaryTable

arguments
    strategyRun (1,1) struct
    cfg (1,1) struct
end

results = strategyRun.results;
strategyName = string(strategyRun.strategy);
instrumentName = string(cfg.instrumentSpec.symbol);
profiles = getDashboardProfiles(results);
initialSessionCatalog = getDashboardSessionScenarios(results,profiles(1));
initialSessionScenario = string( ...
    initialSessionCatalog.Properties.UserData.defaultName);
initialExitCatalog = getDashboardExitManagementScenarios( ...
    results,profiles(1),initialSessionScenario);
initialExitScenario = string( ...
    initialExitCatalog.Properties.UserData.defaultName);

% La caché se construye una sola vez al abrir el dashboard.
% El coste se traslada al inicio y cada selección posterior es inmediata.
researchCache = buildTradeResearchCache(strategyRun.data);

initialScenario = getDashboardScenario( ...
    results,profiles(1),initialSessionScenario,initialExitScenario);
researchSchema = getStrategyResearchSchema( ...
    strategyRun,initialScenario.trades);
segmentFeatureCatalog = getAvailableFeatureCatalog( ...
    researchSchema.featureCatalog,initialScenario.trades);
optimizationParameterSchema = ...
    getOptimizableParameterSchema( ...
        researchSchema.parameterSchema);

fig = uifigure( ...
    "Name", "QuantLab Research - " + strategyName + ...
        " - " + instrumentName, ...
    "Position", [30 30 1700 950]);

root = uigridlayout(fig,[4 1]);
root.RowHeight = {38,78,"1x",34};
root.Padding = [8 8 8 8];
root.RowSpacing = 6;

%% Barra superior de exportacion
topToolbar = uigridlayout(root,[1 3]);
topToolbar.ColumnWidth = {"1x",155,155};
topToolbar.Padding = [0 0 0 0];
topToolbar.ColumnSpacing = 8;

dashboardTitle = uilabel(topToolbar);
dashboardTitle.Text = "QuantLab Research — " + strategyName + ...
    " — " + instrumentName;
dashboardTitle.FontSize = 16;
dashboardTitle.FontWeight = "bold";

exportTabButton = uibutton(topToolbar,"push");
exportTabButton.Text = "Exportar pestaña";
exportTabButton.Tooltip = ...
    "Guarda los datos de la pestaña y los selectores visibles.";

exportAllButton = uibutton(topToolbar,"push");
exportAllButton.Text = "Exportar todo";
exportAllButton.FontWeight = "bold";
exportAllButton.Tooltip = ...
    "Guarda vista activa, 24 escenarios, research y optimización.";

%% KPIs superiores
kpiGrid = uigridlayout(root,[1 8]);
kpiGrid.ColumnWidth = repmat({"1x"},1,8);
kpiGrid.Padding = [0 0 0 0];
kpiGrid.ColumnSpacing = 4;

kpiNames = ["Equity","Fees","Holdings","Net Profit", ...
    "PSR","Return","Unrealized","Quantity Traded"];
kpiCards = gobjects(1,8);

for i = 1:8
    p = uipanel(kpiGrid);
    p.BorderType = "none";
    g = uigridlayout(p,[2 1]);
    g.RowHeight = {"1x",22};
    g.Padding = [4 4 4 4];

    value = uilabel(g);
    value.Text = "-";
    value.FontSize = 18;
    value.FontWeight = "bold";
    value.HorizontalAlignment = "center";

    name = uilabel(g);
    name.Text = kpiNames(i);
    name.HorizontalAlignment = "center";
    name.FontSize = 11;

    p.UserData = value;
    kpiCards(i) = p;
end

%% Cuerpo principal
body = uigridlayout(root,[1 2]);
body.ColumnWidth = {"1x",250};
body.Padding = [0 0 0 0];
body.ColumnSpacing = 6;

leftTabs = uitabgroup(body);
overviewTab = uitab(leftTabs,"Title","Overview");
reportTab = uitab(leftTabs,"Title","Report");
sessionComparisonTab = uitab(leftTabs,"Title","Session Comparison");
ordersTab = uitab(leftTabs,"Title","Orders");
tradesTab = uitab(leftTabs,"Title","Trades");
researchTab = uitab(leftTabs,"Title","Research");
analyticsTab = uitab(leftTabs,"Title","Analytics");
optimizationTab = uitab(leftTabs,"Title","Optimization");
logsTab = uitab(leftTabs,"Title","Logs");

%% Overview
ov = uigridlayout(overviewTab,[2 3]);
ov.RowHeight = {"1.4x","1x"};
ov.ColumnWidth = {"1.5x","1x","1x"};
ov.Padding = [6 6 6 6];
ov.RowSpacing = 6;
ov.ColumnSpacing = 6;

pEquity = uipanel(ov);
pEquity.Layout.Row = 1;
pEquity.Layout.Column = [1 2];
pEquity.Title = "Strategy Equity";

gEq = uigridlayout(pEquity,[2 1]);
gEq.RowHeight = {"4x","1x"};
gEq.Padding = [6 6 6 6];
equityAxes = uiaxes(gEq);
returnAxes = uiaxes(gEq);

pVolume = uipanel(ov);
pVolume.Layout.Row = 1;
pVolume.Layout.Column = 3;
pVolume.Title = "Assets Sales Volume";

gVolume = uigridlayout(pVolume,[1 1]);
gVolume.Padding = [6 6 6 6];

volumeAxes = uiaxes(gVolume);

pDD = uipanel(ov);
pDD.Layout.Row = 2;
pDD.Layout.Column = 1;
pDD.Title = "Drawdown";

gDrawdown = uigridlayout(pDD,[1 1]);
gDrawdown.Padding = [6 6 6 6];

drawdownAxes = uiaxes(gDrawdown);

pExposure = uipanel(ov);
pExposure.Layout.Row = 2;
pExposure.Layout.Column = 2;
pExposure.Title = "Exposure";
exposureAxes = uiaxes(pExposure);

pTurn = uipanel(ov);
pTurn.Layout.Row = 2;
pTurn.Layout.Column = 3;
pTurn.Title = "Portfolio Turnover";
turnoverAxes = uiaxes(pTurn);

%% Otras pestañas
reportGrid = uigridlayout(reportTab,[1 1]);
reportGrid.Padding = [8 8 8 8];
reportTable = uitable(reportGrid);
reportTable.RowStriping = "on";
reportTable.ColumnSortable = true;
reportTable.ColumnWidth = {220,120,220,120};

sessionComparisonGrid = uigridlayout(sessionComparisonTab,[1 1]);
sessionComparisonGrid.Padding = [8 8 8 8];
sessionComparisonTable = uitable(sessionComparisonGrid);
sessionComparisonTable.RowStriping = "on";
sessionComparisonTable.ColumnSortable = true;

ordersGrid = uigridlayout(ordersTab,[1 1]);
ordersGrid.Padding = [8 8 8 8];
ordersTable = uitable(ordersGrid);
ordersTable.RowStriping = "on";
ordersTable.ColumnSortable = true;

tradesGrid = uigridlayout(tradesTab,[2 1]);
tradesGrid.RowHeight = {"1x",34};
tradesGrid.Padding = [8 8 8 8];

tradesTable = uitable(tradesGrid);
tradesTable.RowStriping = "on";
tradesTable.ColumnSortable = true;

tradeSelectionLabel = uilabel(tradesGrid);
tradeSelectionLabel.Text = ...
    "Selecciona una operación para abrir Research Mode.";
tradeSelectionLabel.HorizontalAlignment = "left";

%% Trade Research Mode
tradeResearchGrid = uigridlayout(researchTab,[1 2]);
tradeResearchGrid.ColumnWidth = {"2x","1x"};
tradeResearchGrid.Padding = [8 8 8 8];
tradeResearchGrid.ColumnSpacing = 8;

tradeChartPanel = uipanel(tradeResearchGrid);
tradeChartPanel.Title = "Trade Session";

tradeChartGrid = uigridlayout(tradeChartPanel,[1 1]);
tradeChartGrid.Padding = [6 6 6 6];

tradeResearchAxes = uiaxes(tradeChartGrid);
grid(tradeResearchAxes,"on");

tradeInfoPanel = uipanel(tradeResearchGrid);
tradeInfoPanel.Title = "Trade Details";

tradeInfoGrid = uigridlayout(tradeInfoPanel,[4 1]);
tradeInfoGrid.RowHeight = {34,38,"1x",170};
tradeInfoGrid.Padding = [8 8 8 8];

tradeResearchNavigation = uigridlayout(tradeInfoGrid,[1 2]);
tradeResearchNavigation.ColumnWidth = {"1x","1x"};
tradeResearchNavigation.Padding = [0 0 0 0];
tradeResearchNavigation.ColumnSpacing = 8;

previousResearchButton = uibutton(tradeResearchNavigation,"push");
previousResearchButton.Text = "← Anterior";
previousResearchButton.Enable = "off";

nextResearchButton = uibutton(tradeResearchNavigation,"push");
nextResearchButton.Text = "Siguiente →";
nextResearchButton.Enable = "off";

tradeResearchTitle = uilabel(tradeInfoGrid);
tradeResearchTitle.Text = "No trade selected";
tradeResearchTitle.FontSize = 18;
tradeResearchTitle.FontWeight = "bold";

tradeResearchDetails = uitable(tradeInfoGrid);
tradeResearchDetails.RowStriping = "on";
tradeResearchDetails.ColumnWidth = {170,120};

tradeResearchFeatures = uitextarea(tradeInfoGrid);
tradeResearchFeatures.Editable = "off";
tradeResearchFeatures.Value = reshape([ ...
    "Características del trade:", ...
    "• contexto registrado por la estrategia", ...
    "• parámetros de entrada y riesgo", ...
    "• resultado, MFE y MAE si están disponibles"],[],1);


%% Analytics
% Un uitabgroup creado directamente sobre un uitab conserva un tamaño
% fijo por defecto. Lo alojamos en un grid 1x1 para que ocupe siempre
% toda la pestaña, también después de maximizar o redimensionar.
analyticsHost = uigridlayout(analyticsTab,[1 1]);
analyticsHost.Padding = [0 0 0 0];

analyticsTabs = uitabgroup(analyticsHost);
calendarRollingTab = uitab( ...
    analyticsTabs, ...
    "Title","Calendar & Rolling");
distributionTab = uitab( ...
    analyticsTabs, ...
    "Title","Trade Distribution");
segmentExplorerTab = uitab( ...
    analyticsTabs, ...
    "Title","Segment Explorer");

%% Calendar & Rolling Analytics
analyticsRoot = uigridlayout(calendarRollingTab,[3 2]);
analyticsRoot.RowHeight = {38,"1x","1.25x"};
analyticsRoot.ColumnWidth = {"1.55x","1x"};
analyticsRoot.Padding = [8 8 8 8];
analyticsRoot.RowSpacing = 8;
analyticsRoot.ColumnSpacing = 8;

analyticsToolbar = uigridlayout(analyticsRoot,[1 4]);
analyticsToolbar.Layout.Row = 1;
analyticsToolbar.Layout.Column = [1 2];
analyticsToolbar.ColumnWidth = {145,100,160,"1x"};
analyticsToolbar.Padding = [0 0 0 0];

rollingWindowLabel = uilabel(analyticsToolbar);
rollingWindowLabel.Text = "Ventana (sesiones):";
rollingWindowLabel.HorizontalAlignment = "right";

rollingWindowDropdown = uidropdown(analyticsToolbar);
rollingWindowDropdown.Items = ["20","40","60"];
rollingWindowDropdown.Value = "20";

analyticsProfileLabel = uilabel(analyticsToolbar);
analyticsProfileLabel.Text = "Perfil activo:";
analyticsProfileLabel.HorizontalAlignment = "right";

analyticsProfileValue = uilabel(analyticsToolbar);
analyticsProfileValue.Text = "-";
analyticsProfileValue.FontWeight = "bold";

calendarPanel = uipanel(analyticsRoot);
calendarPanel.Layout.Row = 2;
calendarPanel.Layout.Column = 1;
calendarPanel.Title = "Calendar Returns (%)";

calendarGrid = uigridlayout(calendarPanel,[1 1]);
calendarGrid.Padding = [6 6 6 6];

calendarAxes = uiaxes(calendarGrid);

calendarSummaryPanel = uipanel(analyticsRoot);
calendarSummaryPanel.Layout.Row = 2;
calendarSummaryPanel.Layout.Column = 2;
calendarSummaryPanel.Title = "Calendar Summary";

calendarSummaryGrid = uigridlayout(calendarSummaryPanel,[1 1]);
calendarSummaryGrid.Padding = [6 6 6 6];

calendarSummaryTable = uitable(calendarSummaryGrid);
calendarSummaryTable.RowStriping = "on";
calendarSummaryTable.ColumnWidth = {190,120};

rollingPanel = uipanel(analyticsRoot);
rollingPanel.Layout.Row = 3;
rollingPanel.Layout.Column = [1 2];
rollingPanel.Title = "Rolling Metrics";

rollingGrid = uigridlayout(rollingPanel,[2 3]);
rollingGrid.RowHeight = {"1x","1x"};
rollingGrid.ColumnWidth = {"1x","1x","1x"};
rollingGrid.Padding = [6 6 6 6];
rollingGrid.RowSpacing = 6;
rollingGrid.ColumnSpacing = 6;

rollingWinRateAxes = uiaxes(rollingGrid);
rollingExpectancyAxes = uiaxes(rollingGrid);
rollingProfitFactorAxes = uiaxes(rollingGrid);
rollingSharpeAxes = uiaxes(rollingGrid);
rollingDrawdownAxes = uiaxes(rollingGrid);
rollingExecutionAxes = uiaxes(rollingGrid);


%% Trade Distribution
distributionRoot = uigridlayout(distributionTab,[3 3]);
distributionRoot.RowHeight = {38,"1x","1x"};
distributionRoot.ColumnWidth = {"1x","1x","1x"};
distributionRoot.Padding = [8 8 8 8];
distributionRoot.RowSpacing = 8;
distributionRoot.ColumnSpacing = 8;

distributionToolbar = uigridlayout(distributionRoot,[1 6]);
distributionToolbar.Layout.Row = 1;
distributionToolbar.Layout.Column = [1 3];
distributionToolbar.ColumnWidth = {65,125,75,170,120,"1x"};
distributionToolbar.Padding = [0 0 0 0];

distributionFilterLabel = uilabel(distributionToolbar);
distributionFilterLabel.Text = "Filtro:";
distributionFilterLabel.HorizontalAlignment = "right";

distributionFilterDropdown = uidropdown(distributionToolbar);
distributionFilterDropdown.Items = [ ...
    "ALL","LONG","SHORT","TARGET","STOP","BREAKEVEN", ...
    "TRAILING_STOP","EOD"];
distributionFilterDropdown.Value = "ALL";

distributionDetailLabel = uilabel(distributionToolbar);
distributionDetailLabel.Text = "Detalle:";
distributionDetailLabel.HorizontalAlignment = "right";

distributionDetailDropdown = uidropdown(distributionToolbar);
distributionDetailDropdown.Items = [ ...
    "ORB Range vs R","MFE (R)","MAE (R)", ...
    "Bars Held","Contracts","Risk Used (USD)"];
distributionDetailDropdown.Value = "ORB Range vs R";

distributionProfileLabel = uilabel(distributionToolbar);
distributionProfileLabel.Text = "Perfil activo:";
distributionProfileLabel.HorizontalAlignment = "right";

distributionProfileValue = uilabel(distributionToolbar);
distributionProfileValue.Text = "-";
distributionProfileValue.FontWeight = "bold";

rDistributionPanel = uipanel(distributionRoot);
rDistributionPanel.Layout.Row = 2;
rDistributionPanel.Layout.Column = 1;
rDistributionPanel.Title = "Net R Distribution";

rDistributionGrid = uigridlayout(rDistributionPanel,[1 1]);
rDistributionGrid.Padding = [6 6 6 6];
rDistributionAxes = uiaxes(rDistributionGrid);

pnlDistributionPanel = uipanel(distributionRoot);
pnlDistributionPanel.Layout.Row = 2;
pnlDistributionPanel.Layout.Column = 2;
pnlDistributionPanel.Title = "Net PnL Distribution";

pnlDistributionGrid = uigridlayout(pnlDistributionPanel,[1 1]);
pnlDistributionGrid.Padding = [6 6 6 6];
pnlDistributionAxes = uiaxes(pnlDistributionGrid);

distributionSummaryPanel = uipanel(distributionRoot);
distributionSummaryPanel.Layout.Row = 2;
distributionSummaryPanel.Layout.Column = 3;
distributionSummaryPanel.Title = "Distribution Summary";

distributionSummaryGrid = uigridlayout( ...
    distributionSummaryPanel,[1 1]);
distributionSummaryGrid.Padding = [6 6 6 6];

distributionSummaryTable = uitable(distributionSummaryGrid);
distributionSummaryTable.RowStriping = "on";
distributionSummaryTable.ColumnWidth = {205,125};

directionDistributionPanel = uipanel(distributionRoot);
directionDistributionPanel.Layout.Row = 3;
directionDistributionPanel.Layout.Column = 1;
directionDistributionPanel.Title = "R by Direction";

directionDistributionGrid = uigridlayout( ...
    directionDistributionPanel,[1 1]);
directionDistributionGrid.Padding = [6 6 6 6];
directionDistributionAxes = uiaxes(directionDistributionGrid);

exitDistributionPanel = uipanel(distributionRoot);
exitDistributionPanel.Layout.Row = 3;
exitDistributionPanel.Layout.Column = 2;
exitDistributionPanel.Title = "R by Exit Reason";

exitDistributionGrid = uigridlayout( ...
    exitDistributionPanel,[1 1]);
exitDistributionGrid.Padding = [6 6 6 6];
exitDistributionAxes = uiaxes(exitDistributionGrid);

detailDistributionPanel = uipanel(distributionRoot);
detailDistributionPanel.Layout.Row = 3;
detailDistributionPanel.Layout.Column = 3;
detailDistributionPanel.Title = "Selected Detail";

detailDistributionGrid = uigridlayout( ...
    detailDistributionPanel,[1 1]);
detailDistributionGrid.Padding = [6 6 6 6];
detailDistributionAxes = uiaxes(detailDistributionGrid);


%% Generic Segment Explorer
segmentRoot = uigridlayout(segmentExplorerTab,[3 3]);
segmentRoot.RowHeight = {42,"1x","1.15x"};
segmentRoot.ColumnWidth = {"1x","1x","0.85x"};
segmentRoot.Padding = [8 8 8 8];
segmentRoot.RowSpacing = 8;
segmentRoot.ColumnSpacing = 8;

segmentToolbar = uigridlayout(segmentRoot,[1 12]);
segmentToolbar.Layout.Row = 1;
segmentToolbar.Layout.Column = [1 3];
segmentToolbar.ColumnWidth = { ...
    55,225,70,110,55,145,100,80,85,75,95,"1x"};
segmentToolbar.Padding = [0 0 0 0];

segmentFeatureLabel = uilabel(segmentToolbar);
segmentFeatureLabel.Text = "Feature:";
segmentFeatureLabel.HorizontalAlignment = "right";

segmentFeatureDropdown = uidropdown(segmentToolbar);
segmentFeatureDropdown.Items = "No available features";
segmentFeatureDropdown.ItemsData = "";
segmentFeatureDropdown.Value = "";

segmentGroupingLabel = uilabel(segmentToolbar);
segmentGroupingLabel.Text = "Grouping:";
segmentGroupingLabel.HorizontalAlignment = "right";

segmentGroupingDropdown = uidropdown(segmentToolbar);
segmentGroupingDropdown.Items = [ ...
    "Auto","Quartiles","Quintiles","Deciles","Categories"];
segmentGroupingDropdown.Value = "Auto";

segmentMetricLabel = uilabel(segmentToolbar);
segmentMetricLabel.Text = "Metric:";
segmentMetricLabel.HorizontalAlignment = "right";

segmentMetricDropdown = uidropdown(segmentToolbar);
segmentMetricDropdown.Items = [ ...
    "Expectancy (R)","Win Rate (%)","Profit Factor", ...
    "Net PnL (USD)","Median R","Max Drawdown (%)","Trades"];
segmentMetricDropdown.Value = "Expectancy (R)";

segmentMinimumLabel = uilabel(segmentToolbar);
segmentMinimumLabel.Text = "Minimum N:";
segmentMinimumLabel.HorizontalAlignment = "right";

segmentMinimumField = uieditfield(segmentToolbar,"numeric");
segmentMinimumField.Value = 15;
segmentMinimumField.Limits = [2 Inf];

segmentSplitLabel = uilabel(segmentToolbar);
segmentSplitLabel.Text = "Training %:";
segmentSplitLabel.HorizontalAlignment = "right";

segmentSplitField = uieditfield(segmentToolbar,"numeric");
segmentSplitField.Value = 70;
segmentSplitField.Limits = [50 90];

segmentProfileLabel = uilabel(segmentToolbar);
segmentProfileLabel.Text = "Profile:";
segmentProfileLabel.HorizontalAlignment = "right";

segmentProfileValue = uilabel(segmentToolbar);
segmentProfileValue.Text = "-";
segmentProfileValue.FontWeight = "bold";

segmentChartPanel = uipanel(segmentRoot);
segmentChartPanel.Layout.Row = 2;
segmentChartPanel.Layout.Column = [1 2];
segmentChartPanel.Title = "Selected Feature Segments";

segmentChartGrid = uigridlayout(segmentChartPanel,[1 1]);
segmentChartGrid.Padding = [6 6 6 6];
segmentMetricAxes = uiaxes(segmentChartGrid);

featureRankingPanel = uipanel(segmentRoot);
featureRankingPanel.Layout.Row = 2;
featureRankingPanel.Layout.Column = 3;
featureRankingPanel.Title = "Feature Ranking";

featureRankingGrid = uigridlayout(featureRankingPanel,[1 1]);
featureRankingGrid.Padding = [6 6 6 6];
featureRankingAxes = uiaxes(featureRankingGrid);

segmentResultsPanel = uipanel(segmentRoot);
segmentResultsPanel.Layout.Row = 3;
segmentResultsPanel.Layout.Column = [1 2];
segmentResultsPanel.Title = "Segment Metrics and Temporal Validation";

segmentResultsGrid = uigridlayout(segmentResultsPanel,[1 1]);
segmentResultsGrid.Padding = [6 6 6 6];

segmentResultsTable = uitable(segmentResultsGrid);
segmentResultsTable.RowStriping = "on";
segmentResultsTable.ColumnSortable = true;

segmentSummaryPanel = uipanel(segmentRoot);
segmentSummaryPanel.Layout.Row = 3;
segmentSummaryPanel.Layout.Column = 3;
segmentSummaryPanel.Title = "Research Summary";

segmentSummaryGrid = uigridlayout(segmentSummaryPanel,[1 1]);
segmentSummaryGrid.Padding = [6 6 6 6];

segmentSummaryTable = uitable(segmentSummaryGrid);
segmentSummaryTable.RowStriping = "on";
segmentSummaryTable.ColumnWidth = {155,150};


%% Optimization
optimizationHost = uigridlayout(optimizationTab,[1 1]);
optimizationHost.Padding = [0 0 0 0];

optimizationTabs = uitabgroup(optimizationHost);
fullGridOptimizationTab = uitab( ...
    optimizationTabs,"Title","Full Grid");
walkForwardOptimizationTab = uitab( ...
    optimizationTabs,"Title","Walk-Forward");

%% Optimization — Generic Full Grid
optimizationRoot = uigridlayout(fullGridOptimizationTab,[3 3]);
optimizationRoot.RowHeight = {220,"1x","1.10x"};
optimizationRoot.ColumnWidth = {"1.20x","1x","0.80x"};
optimizationRoot.Padding = [8 8 8 8];
optimizationRoot.RowSpacing = 8;
optimizationRoot.ColumnSpacing = 8;

optimizationControlsPanel = uipanel(optimizationRoot);
optimizationControlsPanel.Layout.Row = 1;
optimizationControlsPanel.Layout.Column = [1 3];
optimizationControlsPanel.Title = ...
    "Optimization Setup — exhaustive full grid";

optimizationControls = uigridlayout( ...
    optimizationControlsPanel,[5 1]);
optimizationControls.RowHeight = {34,34,34,34,28};
optimizationControls.Padding = [8 5 8 5];
optimizationControls.RowSpacing = 5;

% Row 1 — execution profile, ranking and limits
optimizationPlanRow = uigridlayout(optimizationControls,[1 10]);
optimizationPlanRow.ColumnWidth = { ...
    55,125,72,205,86,72,72,72,78,"1x"};
optimizationPlanRow.Padding = [0 0 0 0];

optimizationProfileLabel = uilabel(optimizationPlanRow);
optimizationProfileLabel.Text = "Profile:";
optimizationProfileLabel.HorizontalAlignment = "right";

optimizationProfileDropdown = uidropdown(optimizationPlanRow);
optimizationProfileDropdown.Items = reshape(string(profiles),1,[]);
optimizationProfileDropdown.Value = string(profiles(1));

optimizationMetricLabel = uilabel(optimizationPlanRow);
optimizationMetricLabel.Text = "Ranking:";
optimizationMetricLabel.HorizontalAlignment = "right";

optimizationMetricDropdown = uidropdown(optimizationPlanRow);
optimizationMetricDropdown.Items = [ ...
    "Net PnL (USD)","Net R","Return / Drawdown", ...
    "Expectancy (R)","Profit Factor", ...
    "OOS Expectancy (R)","Robustness", ...
    "Lowest Drawdown (%)"];
optimizationMetricDropdown.Value = "Robustness";

optimizationSplitLabel = uilabel(optimizationPlanRow);
optimizationSplitLabel.Text = "Inner split %:";
optimizationSplitLabel.HorizontalAlignment = "right";

optimizationSplitField = uieditfield( ...
    optimizationPlanRow,"numeric");
optimizationSplitField.Value = 70;
optimizationSplitField.Limits = [50 90];

optimizationLimitLabel = uilabel(optimizationPlanRow);
optimizationLimitLabel.Text = "Max runs:";
optimizationLimitLabel.HorizontalAlignment = "right";

optimizationLimitField = uieditfield( ...
    optimizationPlanRow,"numeric");
optimizationLimitField.Value = 200;
optimizationLimitField.Limits = [1 2000];

optimizationModeLabel = uilabel(optimizationPlanRow);
optimizationModeLabel.Text = "Full grid";
optimizationModeLabel.FontWeight = "bold";

optimizationModeHint = uilabel(optimizationPlanRow);
optimizationModeHint.Text = ...
    "Every parameter combination is executed once.";

% Row 2 — required first parameter
optimizationParameter1Row = uigridlayout(optimizationControls,[1 10]);
optimizationParameter1Row.ColumnWidth = { ...
    90,250,45,82,42,82,42,82,75,"1x"};
optimizationParameter1Row.Padding = [0 0 0 0];

optimizationParameter1Label = uilabel(optimizationParameter1Row);
optimizationParameter1Label.Text = "Parameter 1:";
optimizationParameter1Label.HorizontalAlignment = "right";

optimizationParameter1Dropdown = uidropdown(optimizationParameter1Row);

optimizationStart1Label = uilabel(optimizationParameter1Row);
optimizationStart1Label.Text = "Start:";
optimizationStart1Label.HorizontalAlignment = "right";

optimizationStart1Field = uieditfield( ...
    optimizationParameter1Row,"numeric");

optimizationStop1Label = uilabel(optimizationParameter1Row);
optimizationStop1Label.Text = "Stop:";
optimizationStop1Label.HorizontalAlignment = "right";

optimizationStop1Field = uieditfield( ...
    optimizationParameter1Row,"numeric");

optimizationStep1Label = uilabel(optimizationParameter1Row);
optimizationStep1Label.Text = "Step:";
optimizationStep1Label.HorizontalAlignment = "right";

optimizationStep1Field = uieditfield( ...
    optimizationParameter1Row,"numeric");

optimizationParameter1ModeLabel = uilabel(optimizationParameter1Row);
optimizationParameter1ModeLabel.Text = "Required";
optimizationParameter1ModeLabel.FontWeight = "bold";

optimizationParameter1Hint = uilabel(optimizationParameter1Row);
optimizationParameter1Hint.Text = ...
    "Primary optimization dimension.";

% Row 3 — optional second parameter
optimizationParameter2Row = uigridlayout(optimizationControls,[1 10]);
optimizationParameter2Row.ColumnWidth = { ...
    90,250,45,82,42,82,42,82,75,"1x"};
optimizationParameter2Row.Padding = [0 0 0 0];

optimizationParameter2Label = uilabel(optimizationParameter2Row);
optimizationParameter2Label.Text = "Parameter 2:";
optimizationParameter2Label.HorizontalAlignment = "right";

optimizationParameter2Dropdown = uidropdown(optimizationParameter2Row);

optimizationStart2Label = uilabel(optimizationParameter2Row);
optimizationStart2Label.Text = "Start:";
optimizationStart2Label.HorizontalAlignment = "right";

optimizationStart2Field = uieditfield( ...
    optimizationParameter2Row,"numeric");

optimizationStop2Label = uilabel(optimizationParameter2Row);
optimizationStop2Label.Text = "Stop:";
optimizationStop2Label.HorizontalAlignment = "right";

optimizationStop2Field = uieditfield( ...
    optimizationParameter2Row,"numeric");

optimizationStep2Label = uilabel(optimizationParameter2Row);
optimizationStep2Label.Text = "Step:";
optimizationStep2Label.HorizontalAlignment = "right";

optimizationStep2Field = uieditfield( ...
    optimizationParameter2Row,"numeric");

optimizationParameter2ModeLabel = uilabel(optimizationParameter2Row);
optimizationParameter2ModeLabel.Text = "Optional";
optimizationParameter2ModeLabel.FontWeight = "bold";

optimizationParameter2Hint = uilabel(optimizationParameter2Row);
optimizationParameter2Hint.Text = ...
    "Select None for a one-dimensional grid.";

% Row 4 — execution and complete estimate
optimizationExecutionRow = uigridlayout(optimizationControls,[1 6]);
optimizationExecutionRow.ColumnWidth = { ...
    135,82,"1x",145,360,16};
optimizationExecutionRow.Padding = [0 0 0 0];

optimizationRunButton = uibutton( ...
    optimizationExecutionRow,"push");
optimizationRunButton.Text = "Run Full Grid";

optimizationCancelButton = uibutton( ...
    optimizationExecutionRow,"push");
optimizationCancelButton.Text = "Cancel";
optimizationCancelButton.Enable = "off";

optimizationExecutionSpacer = uilabel(optimizationExecutionRow);
optimizationExecutionSpacer.Text = "";

optimizationEstimateLabel = uilabel(optimizationExecutionRow);
optimizationEstimateLabel.Text = "Estimated runs: —";
optimizationEstimateLabel.HorizontalAlignment = "right";
optimizationEstimateLabel.FontWeight = "bold";

optimizationEstimateDetailLabel = uilabel(optimizationExecutionRow);
optimizationEstimateDetailLabel.Text = ...
    "Select valid parameter ranges.";
optimizationEstimateDetailLabel.HorizontalAlignment = "left";

optimizationExecutionRightPadding = uilabel(optimizationExecutionRow);
optimizationExecutionRightPadding.Text = "";

% Row 5 — full-width status
optimizationStatusRow = uigridlayout(optimizationControls,[1 1]);
optimizationStatusRow.Padding = [0 0 0 0];

optimizationStatusLabel = uilabel(optimizationStatusRow);
optimizationStatusLabel.Text = ...
    "Ready — select one or two parameters.";
optimizationStatusLabel.FontWeight = "bold";

optimizationSurfacePanel = uipanel(optimizationRoot);
optimizationSurfacePanel.Layout.Row = 2;
optimizationSurfacePanel.Layout.Column = [1 2];
optimizationSurfacePanel.Title = "Optimization Surface";

optimizationSurfaceGrid = uigridlayout( ...
    optimizationSurfacePanel,[1 1]);
optimizationSurfaceGrid.Padding = [6 6 6 6];

optimizationSurfaceAxes = uiaxes(optimizationSurfaceGrid);

optimizationRiskPanel = uipanel(optimizationRoot);
optimizationRiskPanel.Layout.Row = 2;
optimizationRiskPanel.Layout.Column = 3;
optimizationRiskPanel.Title = "Risk / Return";

optimizationRiskGrid = uigridlayout( ...
    optimizationRiskPanel,[1 1]);
optimizationRiskGrid.Padding = [6 6 6 6];

optimizationRiskReturnAxes = uiaxes(optimizationRiskGrid);

optimizationResultsPanel = uipanel(optimizationRoot);
optimizationResultsPanel.Layout.Row = 3;
optimizationResultsPanel.Layout.Column = [1 2];
optimizationResultsPanel.Title = "Optimization Results";

optimizationResultsGrid = uigridlayout( ...
    optimizationResultsPanel,[1 1]);
optimizationResultsGrid.Padding = [6 6 6 6];

optimizationResultsTable = uitable(optimizationResultsGrid);
optimizationResultsTable.RowStriping = "on";
optimizationResultsTable.ColumnSortable = true;

optimizationSummaryPanel = uipanel(optimizationRoot);
optimizationSummaryPanel.Layout.Row = 3;
optimizationSummaryPanel.Layout.Column = 3;
optimizationSummaryPanel.Title = "Optimization Summary";

optimizationSummaryGrid = uigridlayout( ...
    optimizationSummaryPanel,[1 1]);
optimizationSummaryGrid.Padding = [6 6 6 6];

optimizationSummaryTable = uitable(optimizationSummaryGrid);
optimizationSummaryTable.RowStriping = "on";
optimizationSummaryTable.ColumnWidth = {165,190};

optimizationParameterSchema = ...
    updateOptimizationParameterSelectors( ...
        optimizationParameter1Dropdown, ...
        optimizationParameter2Dropdown, ...
        optimizationParameterSchema);


%% Walk-Forward & Robustness
walkForwardRoot = uigridlayout(walkForwardOptimizationTab,[3 3]);
walkForwardRoot.RowHeight = {238,"1x","1.15x"};
walkForwardRoot.ColumnWidth = {"1.15x","1x","0.82x"};
walkForwardRoot.Padding = [8 8 8 8];
walkForwardRoot.RowSpacing = 8;
walkForwardRoot.ColumnSpacing = 8;

walkForwardControlsPanel = uipanel(walkForwardRoot);
walkForwardControlsPanel.Layout.Row = 1;
walkForwardControlsPanel.Layout.Column = [1 3];
walkForwardControlsPanel.Title = ...
    "Walk-Forward Setup — the final holdout remains outside optimization";

walkForwardControls = uigridlayout( ...
    walkForwardControlsPanel,[5 1]);
walkForwardControls.RowHeight = {34,34,34,34,28};
walkForwardControls.Padding = [8 5 8 5];
walkForwardControls.RowSpacing = 5;

% Row 1 — temporal plan and protected holdout
wfPlanRow = uigridlayout(walkForwardControls,[1 14]);
wfPlanRow.ColumnWidth = { ...
    55,110,48,112,92,72,96,72, ...
    82,72,76,72,165,"1x"};
wfPlanRow.Padding = [0 0 0 0];

wfProfileLabel = uilabel(wfPlanRow);
wfProfileLabel.Text = "Profile:";
wfProfileLabel.HorizontalAlignment = "right";

wfProfileDropdown = uidropdown(wfPlanRow);
wfProfileDropdown.Items = reshape(string(profiles),1,[]);
wfProfileDropdown.Value = string(profiles(1));

wfModeLabel = uilabel(wfPlanRow);
wfModeLabel.Text = "Mode:";
wfModeLabel.HorizontalAlignment = "right";

wfModeDropdown = uidropdown(wfPlanRow);
wfModeDropdown.Items = ["ANCHORED","ROLLING"];
wfModeDropdown.Value = "ANCHORED";

wfTrainingLabel = uilabel(wfPlanRow);
wfTrainingLabel.Text = "Train sessions:";
wfTrainingLabel.HorizontalAlignment = "right";

wfTrainingField = uieditfield(wfPlanRow,"numeric");
wfTrainingField.Value = 100;
wfTrainingField.Limits = [20 Inf];

wfValidationLabel = uilabel(wfPlanRow);
wfValidationLabel.Text = "OOS sessions:";
wfValidationLabel.HorizontalAlignment = "right";

wfValidationField = uieditfield(wfPlanRow,"numeric");
wfValidationField.Value = 20;
wfValidationField.Limits = [5 Inf];

wfStepLabel = uilabel(wfPlanRow);
wfStepLabel.Text = "Step sessions:";
wfStepLabel.HorizontalAlignment = "right";

wfStepField = uieditfield(wfPlanRow,"numeric");
wfStepField.Value = 20;
wfStepField.Limits = [1 Inf];

wfHoldoutLabel = uilabel(wfPlanRow);
wfHoldoutLabel.Text = "Holdout %:";
wfHoldoutLabel.HorizontalAlignment = "right";

wfHoldoutField = uieditfield(wfPlanRow,"numeric");
wfHoldoutField.Value = 15;
wfHoldoutField.Limits = [0 40];

wfEvaluateHoldoutCheckbox = uicheckbox(wfPlanRow);
wfEvaluateHoldoutCheckbox.Text = "Evaluate final holdout";
wfEvaluateHoldoutCheckbox.Value = false;

wfHoldoutWarning = uilabel(wfPlanRow);
wfHoldoutWarning.Text = ...
    "Keep locked while tuning.";
wfHoldoutWarning.FontAngle = "italic";

% Row 2 — first optimization dimension
wfParameter1Row = uigridlayout(walkForwardControls,[1 10]);
wfParameter1Row.ColumnWidth = { ...
    90,250,45,82,42,82,42,82,75,"1x"};
wfParameter1Row.Padding = [0 0 0 0];

wfParameter1Label = uilabel(wfParameter1Row);
wfParameter1Label.Text = "Parameter 1:";
wfParameter1Label.HorizontalAlignment = "right";

wfParameter1Dropdown = uidropdown(wfParameter1Row);

wfStart1Label = uilabel(wfParameter1Row);
wfStart1Label.Text = "Start:";
wfStart1Label.HorizontalAlignment = "right";

wfStart1Field = uieditfield(wfParameter1Row,"numeric");

wfStop1Label = uilabel(wfParameter1Row);
wfStop1Label.Text = "Stop:";
wfStop1Label.HorizontalAlignment = "right";

wfStop1Field = uieditfield(wfParameter1Row,"numeric");

wfStep1Label = uilabel(wfParameter1Row);
wfStep1Label.Text = "Step:";
wfStep1Label.HorizontalAlignment = "right";

wfStep1Field = uieditfield(wfParameter1Row,"numeric");

wfGridLabel = uilabel(wfParameter1Row);
wfGridLabel.Text = "Full grid";
wfGridLabel.FontWeight = "bold";

wfGridHint = uilabel(wfParameter1Row);
wfGridHint.Text = ...
    "Every configuration is evaluated in every OOS window.";

% Row 3 — optional second optimization dimension
wfParameter2Row = uigridlayout(walkForwardControls,[1 10]);
wfParameter2Row.ColumnWidth = { ...
    90,250,45,82,42,82,42,82,75,"1x"};
wfParameter2Row.Padding = [0 0 0 0];

wfParameter2Label = uilabel(wfParameter2Row);
wfParameter2Label.Text = "Parameter 2:";
wfParameter2Label.HorizontalAlignment = "right";

wfParameter2Dropdown = uidropdown(wfParameter2Row);

wfStart2Label = uilabel(wfParameter2Row);
wfStart2Label.Text = "Start:";
wfStart2Label.HorizontalAlignment = "right";

wfStart2Field = uieditfield(wfParameter2Row,"numeric");

wfStop2Label = uilabel(wfParameter2Row);
wfStop2Label.Text = "Stop:";
wfStop2Label.HorizontalAlignment = "right";

wfStop2Field = uieditfield(wfParameter2Row,"numeric");

wfStep2Label = uilabel(wfParameter2Row);
wfStep2Label.Text = "Step:";
wfStep2Label.HorizontalAlignment = "right";

wfStep2Field = uieditfield(wfParameter2Row,"numeric");

wfParameter2ModeLabel = uilabel(wfParameter2Row);
wfParameter2ModeLabel.Text = "Optional";
wfParameter2ModeLabel.FontWeight = "bold";

wfParameter2Hint = uilabel(wfParameter2Row);
wfParameter2Hint.Text = ...
    "Select None for a one-dimensional optimization.";

% Row 4 — ranking and execution
wfExecutionRow = uigridlayout(walkForwardControls,[1 12]);
wfExecutionRow.ColumnWidth = { ...
    92,185,82,72,80,200,72,72, ...
    135,82,"1x",20};
wfExecutionRow.Padding = [0 0 0 0];

wfSelectionMetricLabel = uilabel(wfExecutionRow);
wfSelectionMetricLabel.Text = "Train ranking:";
wfSelectionMetricLabel.HorizontalAlignment = "right";

wfSelectionMetricDropdown = uidropdown(wfExecutionRow);
wfSelectionMetricDropdown.Items = [ ...
    "Net PnL (USD)","Net R","Return / Drawdown", ...
    "Expectancy (R)","Profit Factor", ...
    "Robustness","Lowest Drawdown (%)"];
wfSelectionMetricDropdown.Value = "Robustness";

wfInnerSplitLabel = uilabel(wfExecutionRow);
wfInnerSplitLabel.Text = "Inner split %:";
wfInnerSplitLabel.HorizontalAlignment = "right";

wfInnerSplitField = uieditfield(wfExecutionRow,"numeric");
wfInnerSplitField.Value = 70;
wfInnerSplitField.Limits = [50 90];

wfRankingLabel = uilabel(wfExecutionRow);
wfRankingLabel.Text = "WF ranking:";
wfRankingLabel.HorizontalAlignment = "right";

wfRankingDropdown = uidropdown(wfExecutionRow);
wfRankingDropdown.Items = [ ...
    "Plateau Score","WF Robustness", ...
    "Mean OOS Expectancy (R)", ...
    "Positive OOS Windows (%)", ...
    "Worst OOS Expectancy (R)", ...
    "Total OOS PnL (USD)", ...
    "Mean OOS Return / Drawdown", ...
    "Lowest Mean OOS Drawdown (%)"];
wfRankingDropdown.Value = "Plateau Score";

wfLimitLabel = uilabel(wfExecutionRow);
wfLimitLabel.Text = "Max runs:";
wfLimitLabel.HorizontalAlignment = "right";

wfLimitField = uieditfield(wfExecutionRow,"numeric");
wfLimitField.Value = 500;
wfLimitField.Limits = [1 10000];

wfRunButton = uibutton(wfExecutionRow,"push");
wfRunButton.Text = "Run Walk-Forward";

wfCancelButton = uibutton(wfExecutionRow,"push");
wfCancelButton.Text = "Cancel";
wfCancelButton.Enable = "off";

wfExecutionSpacer = uilabel(wfExecutionRow);
wfExecutionSpacer.Text = "";

wfExecutionRightPadding = uilabel(wfExecutionRow);
wfExecutionRightPadding.Text = "";

% Row 5 — status and estimate have independent full-width areas
wfStatusRow = uigridlayout(walkForwardControls,[1 3]);
wfStatusRow.ColumnWidth = {"1x",165,430};
wfStatusRow.Padding = [0 0 0 0];
wfStatusRow.ColumnSpacing = 8;

wfStatusLabel = uilabel(wfStatusRow);
wfStatusLabel.Text = "Ready — holdout locked.";
wfStatusLabel.FontWeight = "bold";

wfEstimateLabel = uilabel(wfStatusRow);
wfEstimateLabel.Text = "Estimated runs: —";
wfEstimateLabel.HorizontalAlignment = "right";
wfEstimateLabel.FontWeight = "bold";

wfEstimateDetailLabel = uilabel(wfStatusRow);
wfEstimateDetailLabel.Text = "Configure a valid walk-forward plan.";
wfEstimateDetailLabel.HorizontalAlignment = "left";
wfWindowPanel = uipanel(walkForwardRoot);
wfWindowPanel.Layout.Row = 2;
wfWindowPanel.Layout.Column = [1 2];
wfWindowPanel.Title = "Selected Configuration OOS by Window";
wfWindowGrid = uigridlayout(wfWindowPanel,[1 1]);
wfWindowGrid.Padding = [6 6 6 6];
wfWindowAxes = uiaxes(wfWindowGrid);

wfStabilityPanel = uipanel(walkForwardRoot);
wfStabilityPanel.Layout.Row = 2;
wfStabilityPanel.Layout.Column = 3;
wfStabilityPanel.Title = "Parameter Stability";
wfStabilityGrid = uigridlayout(wfStabilityPanel,[1 1]);
wfStabilityGrid.Padding = [6 6 6 6];
wfStabilityAxes = uiaxes(wfStabilityGrid);

wfTablesPanel = uipanel(walkForwardRoot);
wfTablesPanel.Layout.Row = 3;
wfTablesPanel.Layout.Column = [1 2];
wfTablesPanel.Title = "Walk-Forward Results";
wfTablesTabs = uitabgroup(wfTablesPanel);
wfWindowsTableTab = uitab(wfTablesTabs,"Title","Windows");
wfAggregateTableTab = uitab(wfTablesTabs,"Title","Aggregate Configurations");

wfWindowTableGrid = uigridlayout(wfWindowsTableTab,[1 1]);
wfWindowTableGrid.Padding = [5 5 5 5];
wfWindowResultsTable = uitable(wfWindowTableGrid);
wfWindowResultsTable.RowStriping = "on";
wfWindowResultsTable.ColumnSortable = true;

wfAggregateTableGrid = uigridlayout(wfAggregateTableTab,[1 1]);
wfAggregateTableGrid.Padding = [5 5 5 5];
wfAggregateResultsTable = uitable(wfAggregateTableGrid);
wfAggregateResultsTable.RowStriping = "on";
wfAggregateResultsTable.ColumnSortable = true;

wfSummaryPanel = uipanel(walkForwardRoot);
wfSummaryPanel.Layout.Row = 3;
wfSummaryPanel.Layout.Column = 3;
wfSummaryPanel.Title = "Robustness & Holdout Summary";
wfSummaryGrid = uigridlayout(wfSummaryPanel,[1 1]);
wfSummaryGrid.Padding = [6 6 6 6];
wfSummaryTable = uitable(wfSummaryGrid);
wfSummaryTable.RowStriping = "on";
wfSummaryTable.ColumnWidth = {170,200};

updateOptimizationParameterSelectors( ...
    wfParameter1Dropdown,wfParameter2Dropdown, ...
    optimizationParameterSchema);
wfParameter2Dropdown.Value = "";

logsGrid = uigridlayout(logsTab,[1 1]);
logsGrid.Padding = [8 8 8 8];
logsArea = uitextarea(logsGrid);
logsArea.Editable = "off";

%% Panel derecho
right = uipanel(body);
rg = uigridlayout(right,[5 1]);
rg.RowHeight = {104,250,130,"1x",38};
rg.Padding = [8 8 8 8];

pg = uigridlayout(rg,[3 2]);
pg.RowHeight = {28,28,28};
pg.ColumnWidth = {65,"1x"};
pg.RowSpacing = 4;
pg.Padding = [0 0 0 0];
lab = uilabel(pg); lab.Text = "Profile:";
profileDropdown = uidropdown(pg);
profileDropdown.Items = reshape(string(profiles), 1, []);
profileDropdown.Value = string(profiles(1));

sessionScenarioLabel = uilabel(pg);
sessionScenarioLabel.Text = "Sessions:";
sessionScenarioDropdown = uidropdown(pg);
sessionScenarioDropdown.Items = reshape( ...
    string(initialSessionCatalog.label),1,[]);
sessionScenarioDropdown.ItemsData = reshape( ...
    string(initialSessionCatalog.name),1,[]);
sessionScenarioDropdown.Value = initialSessionScenario;

exitManagementLabel = uilabel(pg);
exitManagementLabel.Text = "Exit:";
exitManagementDropdown = uidropdown(pg);
exitManagementDropdown.Items = reshape( ...
    string(initialExitCatalog.label),1,[]);
exitManagementDropdown.ItemsData = reshape( ...
    string(initialExitCatalog.name),1,[]);
exitManagementDropdown.Value = initialExitScenario;

chartPanel = uipanel(rg);
chartPanel.Title = "Select Chart";

chartPanelGrid = uigridlayout(chartPanel,[1 1]);
chartPanelGrid.Padding = [6 6 6 6];

chartGroup = uibuttongroup(chartPanelGrid);
chartGroup.BorderType = "none";

chartNames = ["Strategy Equity","Drawdown","Exposure", ...
    "Portfolio Turnover","Report","Trades","Research", ...
    "Analytics","Optimization"];

buttonHeight = 22;
buttonGap = 3;
topY = 215;

for i = 1:numel(chartNames)
    b = uiradiobutton(chartGroup);
    b.Text = chartNames(i);
    b.Position = [8, topY-(i-1)*(buttonHeight+buttonGap), 190, buttonHeight];

    if i == 1
        b.Value = true;
    end
end

researchPanel = uipanel(rg);
researchPanel.Title = "Research Guide";

researchGrid = uigridlayout(researchPanel,[1 1]);
researchGrid.Padding = [6 6 6 6];

researchText = uitextarea(researchGrid);
researchText.Editable = "off";
researchText.Value = reshape([ ...
    "Backtests: 1", ...
    "Parameters: current profile", ...
    "Research status: experimental"], [], 1);

infoArea = uitextarea(rg);
infoArea.Editable = "off";
infoArea.Value = reshape([ ...
    "QuantLab Research", ...
    "", ...
    "Métricas no disponibles: N/A", ...
    "No se inventan benchmark, capacity ni PSR."], [], 1);

exportButton = uibutton(rg,"push");
exportButton.Text = "Exportar vista PNG";

footer = uilabel(root);
footer.Text = "QuantLab — Research Dashboard";
footer.HorizontalAlignment = "right";

%% Callbacks
profileDropdown.ValueChangedFcn = @(~,~) handleProfileChanged();
sessionScenarioDropdown.ValueChangedFcn = @(~,~) handleSessionChanged();
exitManagementDropdown.ValueChangedFcn = @(~,~) refreshAll();
rollingWindowDropdown.ValueChangedFcn = @(~,~) requestAnalyticsRefresh();
distributionFilterDropdown.ValueChangedFcn = ...
    @(~,~) requestDistributionRefresh();
distributionDetailDropdown.ValueChangedFcn = ...
    @(~,~) requestDistributionRefresh();
segmentFeatureDropdown.ValueChangedFcn = ...
    @(~,~) requestSegmentRefresh();
segmentGroupingDropdown.ValueChangedFcn = ...
    @(~,~) requestSegmentRefresh();
segmentMetricDropdown.ValueChangedFcn = ...
    @(~,~) requestSegmentRefresh();
segmentMinimumField.ValueChangedFcn = ...
    @(~,~) requestSegmentRefresh();
segmentSplitField.ValueChangedFcn = ...
    @(~,~) requestSegmentRefresh();
optimizationParameter1Dropdown.ValueChangedFcn = ...
    @(~,~) applyOptimizationParameterDefaults(1);
optimizationParameter2Dropdown.ValueChangedFcn = ...
    @(~,~) applyOptimizationParameterDefaults(2);
optimizationStart1Field.ValueChangedFcn = ...
    @(~,~) updateOptimizationEstimate();
optimizationStop1Field.ValueChangedFcn = ...
    @(~,~) updateOptimizationEstimate();
optimizationStep1Field.ValueChangedFcn = ...
    @(~,~) updateOptimizationEstimate();
optimizationStart2Field.ValueChangedFcn = ...
    @(~,~) updateOptimizationEstimate();
optimizationStop2Field.ValueChangedFcn = ...
    @(~,~) updateOptimizationEstimate();
optimizationStep2Field.ValueChangedFcn = ...
    @(~,~) updateOptimizationEstimate();
optimizationLimitField.ValueChangedFcn = ...
    @(~,~) updateOptimizationEstimate();
optimizationMetricDropdown.ValueChangedFcn = ...
    @(~,~) refreshOptimizationResults();
optimizationRunButton.ButtonPushedFcn = ...
    @(~,~) runOptimization();
optimizationCancelButton.ButtonPushedFcn = ...
    @(~,~) cancelOptimization();
optimizationTabs.SelectionChangedFcn = ...
    @(~,~) refreshVisibleOptimization();
wfParameter1Dropdown.ValueChangedFcn = ...
    @(~,~) applyWalkForwardParameterDefaults(1);
wfParameter2Dropdown.ValueChangedFcn = ...
    @(~,~) applyWalkForwardParameterDefaults(2);
wfRankingDropdown.ValueChangedFcn = ...
    @(~,~) refreshWalkForwardResults();
wfModeDropdown.ValueChangedFcn = ...
    @(~,~) updateWalkForwardEstimate();
wfTrainingField.ValueChangedFcn = ...
    @(~,~) updateWalkForwardEstimate();
wfValidationField.ValueChangedFcn = ...
    @(~,~) updateWalkForwardEstimate();
wfStepField.ValueChangedFcn = ...
    @(~,~) updateWalkForwardEstimate();
wfHoldoutField.ValueChangedFcn = ...
    @(~,~) updateWalkForwardEstimate();
wfStart1Field.ValueChangedFcn = ...
    @(~,~) updateWalkForwardEstimate();
wfStop1Field.ValueChangedFcn = ...
    @(~,~) updateWalkForwardEstimate();
wfStep1Field.ValueChangedFcn = ...
    @(~,~) updateWalkForwardEstimate();
wfStart2Field.ValueChangedFcn = ...
    @(~,~) updateWalkForwardEstimate();
wfStop2Field.ValueChangedFcn = ...
    @(~,~) updateWalkForwardEstimate();
wfStep2Field.ValueChangedFcn = ...
    @(~,~) updateWalkForwardEstimate();
wfEvaluateHoldoutCheckbox.ValueChangedFcn = ...
    @(~,~) updateWalkForwardEstimate();
wfLimitField.ValueChangedFcn = ...
    @(~,~) updateWalkForwardEstimate();
wfRunButton.ButtonPushedFcn = ...
    @(~,~) runWalkForward();
wfCancelButton.ButtonPushedFcn = ...
    @(~,~) cancelWalkForward();
chartGroup.SelectionChangedFcn = @(~,e) selectTab(string(e.NewValue.Text));
leftTabs.SelectionChangedFcn = @(~,~) handleMainTabChanged();
analyticsTabs.SelectionChangedFcn = @(~,~) refreshVisibleAnalytics();
exportButton.ButtonPushedFcn = @(~,~) exportDashboard();
exportTabButton.ButtonPushedFcn = @(~,~) exportActiveTab();
exportAllButton.ButtonPushedFcn = @(~,~) exportEverything();
ordersTable.CellSelectionCallback = @(~,e) selectOrdersRow(e);
tradesTable.CellSelectionCallback = @(~,e) selectResearchTrade(e);
previousResearchButton.ButtonPushedFcn = @(~,~) navigateResearch(-1);
nextResearchButton.ButtonPushedFcn = @(~,~) navigateResearch(1);

dashboardState = struct( ...
    "currentProfile","", ...
    "currentSessionScenario","", ...
    "currentExitManagementScenario","", ...
    "currentTrades",table(), ...
    "currentOrders",table(), ...
    "selectedTradeIndex",NaN, ...
    "selectedOrderIndex",NaN, ...
    "researchSource","", ...
    "analyticsDirty",true, ...
    "distributionDirty",true, ...
    "segmentDirty",true, ...
    "isRefreshing",false, ...
    "isStartupRefresh",true, ...
    "optimizationRunning",false, ...
    "optimizationCancelRequested",false, ...
    "optimizationResults",table(), ...
    "optimizationRunState",struct( ...
        "requested",0,"completed",0, ...
        "cancelled",false,"cache_size",0), ...
    "optimizationCache",containers.Map( ...
        "KeyType","char","ValueType","any"), ...
    "optimizationPreparedCache",containers.Map( ...
        "KeyType","char","ValueType","any"), ...
    "fullGridUiInitialized",false, ...
    "walkForwardUiInitialized",false, ...
    "walkForwardRunning",false, ...
    "walkForwardCancelRequested",false, ...
    "walkForwardResult",struct());

isInitializingDashboard = true;

applyOptimizationParameterDefaults(1);
applyOptimizationParameterDefaults(2);
applyWalkForwardParameterDefaults(1);
applyWalkForwardParameterDefaults(2);

isInitializingDashboard = false;

% Startup critical path: render only the visible core dashboard.
% Optimization estimates, axes and tables are initialized lazily when
% the user opens the corresponding subtab.
refreshAll();
dashboardState.isStartupRefresh = false;

app = struct( ...
    "Figure",fig, ...
    "ProfileDropdown",profileDropdown, ...
    "SessionScenarioDropdown",sessionScenarioDropdown, ...
    "ExitManagementDropdown",exitManagementDropdown, ...
    "ReportTable",reportTable, ...
    "SessionComparisonTable",sessionComparisonTable, ...
    "OrdersTable",ordersTable, ...
    "TradesTable",tradesTable, ...
    "TradeResearchAxes",tradeResearchAxes, ...
    "TradeResearchDetails",tradeResearchDetails, ...
    "PreviousResearchButton",previousResearchButton, ...
    "NextResearchButton",nextResearchButton, ...
    "RollingWindowDropdown",rollingWindowDropdown, ...
    "CalendarAxes",calendarAxes, ...
    "DistributionFilterDropdown",distributionFilterDropdown, ...
    "DistributionDetailDropdown",distributionDetailDropdown, ...
    "RDistributionAxes",rDistributionAxes, ...
    "PnLDistributionAxes",pnlDistributionAxes, ...
    "SegmentFeatureDropdown",segmentFeatureDropdown, ...
    "SegmentMetricAxes",segmentMetricAxes, ...
    "FeatureRankingAxes",featureRankingAxes, ...
    "SegmentResultsTable",segmentResultsTable, ...
    "OptimizationTab",optimizationTab, ...
    "OptimizationParameter1Dropdown", ...
        optimizationParameter1Dropdown, ...
    "OptimizationParameter2Dropdown", ...
        optimizationParameter2Dropdown, ...
    "OptimizationResultsTable", ...
        optimizationResultsTable, ...
    "OptimizationSurfaceAxes", ...
        optimizationSurfaceAxes, ...
    "OptimizationRiskReturnAxes", ...
        optimizationRiskReturnAxes, ...
    "OptimizationTabs",optimizationTabs, ...
    "WalkForwardTab",walkForwardOptimizationTab, ...
    "WalkForwardWindowAxes",wfWindowAxes, ...
    "WalkForwardStabilityAxes",wfStabilityAxes, ...
    "WalkForwardWindowResultsTable",wfWindowResultsTable, ...
    "WalkForwardAggregateResultsTable",wfAggregateResultsTable, ...
    "ExportTabButton",exportTabButton, ...
    "ExportAllButton",exportAllButton);

    function handleProfileChanged()
        profile = string(profileDropdown.Value);
        catalog = getDashboardSessionScenarios(results,profile);
        sessionScenarioDropdown.Items = reshape( ...
            string(catalog.label),1,[]);
        sessionScenarioDropdown.ItemsData = reshape( ...
            string(catalog.name),1,[]);
        sessionScenarioDropdown.Value = string( ...
            catalog.Properties.UserData.defaultName);
        updateExitManagementSelector();
        refreshAll();
    end

    function handleSessionChanged()
        updateExitManagementSelector();
        refreshAll();
    end

    function updateExitManagementSelector()
        profile = string(profileDropdown.Value);
        sessionScenario = string(sessionScenarioDropdown.Value);
        catalog = getDashboardExitManagementScenarios( ...
            results,profile,sessionScenario);
        exitManagementDropdown.Items = reshape( ...
            string(catalog.label),1,[]);
        exitManagementDropdown.ItemsData = reshape( ...
            string(catalog.name),1,[]);
        exitManagementDropdown.Value = string( ...
            catalog.Properties.UserData.defaultName);
    end

    function refreshAll()
        % Evitar callbacks simultáneos si el usuario cambia de perfil
        % mientras MATLAB todavía está actualizando el anterior.
        if dashboardState.isRefreshing
            return;
        end

        dashboardState.isRefreshing = true;
        profileDropdown.Enable = "off";
        sessionScenarioDropdown.Enable = "off";
        exitManagementDropdown.Enable = "off";
        refreshCleanup = onCleanup(@() finishCoreRefresh());

        profile = string(profileDropdown.Value);
        sessionScenario = string(sessionScenarioDropdown.Value);
        exitManagementScenario = string(exitManagementDropdown.Value);
        scenarioCatalog = getDashboardSessionScenarios(results,profile);
        labelIndex = find( ...
            scenarioCatalog.name==sessionScenario,1,"first");
        if isempty(labelIndex)
            sessionScenarioLabelText = sessionScenario;
        else
            sessionScenarioLabelText = scenarioCatalog.label(labelIndex);
        end
        exitCatalog = getDashboardExitManagementScenarios( ...
            results,profile,sessionScenario);
        exitLabelIndex = find( ...
            exitCatalog.name==exitManagementScenario,1,"first");
        if isempty(exitLabelIndex)
            exitManagementLabelText = exitManagementScenario;
        else
            exitManagementLabelText = exitCatalog.label(exitLabelIndex);
        end
        activeViewLabel = profile + " | " + sessionScenarioLabelText + ...
            " | " + exitManagementLabelText;
        scenario = getDashboardScenario( ...
            results,profile,sessionScenario,exitManagementScenario);
        trades = scenario.trades;
        executedMask = logical(trades.valid);
        tradeVariables = string(trades.Properties.VariableNames);
        if ismember("quantity",tradeVariables)
            executedMask = executedMask & ...
                isfinite(trades.quantity) & trades.quantity>0;
        elseif ismember("contracts",tradeVariables)
            executedMask = executedMask & ...
                isfinite(trades.contracts) & trades.contracts>0;
        end
        executed = trades(executedMask,:);

        dashboardState.currentProfile = profile;
        dashboardState.currentSessionScenario = sessionScenario;
        dashboardState.currentExitManagementScenario = ...
            exitManagementScenario;
        dashboardState.currentTrades = executed;
        dashboardState.currentOrders = trades;
        dashboardState.selectedTradeIndex = NaN;
        dashboardState.selectedOrderIndex = NaN;
        dashboardState.researchSource = "";
        dashboardState.analyticsDirty = true;
        dashboardState.distributionDirty = true;
        dashboardState.segmentDirty = true;

        % El selector se construye desde el contrato de características
        % y desde las columnas realmente presentes en el perfil.
        segmentFeatureCatalog = updateSegmentFeatureSelector( ...
            segmentFeatureDropdown, ...
            researchSchema.featureCatalog, ...
            trades);

        % Camino crítico: todos los componentes principales se actualizan
        % antes de ejecutar análisis secundarios.
        m = calculateResearchMetrics(trades,cfg);
        updateResearchKPIBar(kpiCards,m);
        updateEquityCharts(equityAxes,returnAxes,executed,m);
        updateVolumeChart(volumeAxes,executed,cfg);
        updateDrawdownChart(drawdownAxes,executed,cfg);
        updateExposureChart(exposureAxes,executed);
        updateTurnoverChart(turnoverAxes,executed,cfg);
        reportTable.Data = buildResearchReportTable(m);
        sessionComparisonTable.Data = ...
            buildSessionScenarioComparisonTable( ...
                results.summaryTable,profile,exitManagementScenario);
        updateOrdersTable(ordersTable,trades);
        updateTradesTable(tradesTable,executed);

        updateLogsPanel( ...
            logsArea, ...
            strategyName, ...
            activeViewLabel, ...
            m);

        clearTradeResearchView( ...
            tradeResearchAxes, ...
            tradeResearchTitle, ...
            tradeResearchDetails, ...
            tradeResearchFeatures);

        clearTradeTableHighlight(ordersTable);
        clearTradeTableHighlight(tradesTable);
        updateResearchNavigationControls();

        tradeSelectionLabel.Text = ...
            "Selecciona una operación para abrir Research Mode.";

        analyticsProfileValue.Text = activeViewLabel;
        distributionProfileValue.Text = activeViewLabel;
        segmentProfileValue.Text = activeViewLabel;

        % En callbacks interactivos se publica una actualización limitada.
        % Durante el arranque se deja que la función termine y MATLAB Online
        % pinte de forma asíncrona: drawnow bloqueante puede esperar 30 s por
        % cada eje cuando el cliente gráfico web todavía no responde.
        if ~dashboardState.isStartupRefresh
            drawnow limitrate nocallbacks;
        end

        % Solo renderizar Analytics si el usuario está en esa pestaña.
        if isequal(leftTabs.SelectedTab,analyticsTab)
            refreshVisibleAnalytics();
        elseif isequal(leftTabs.SelectedTab,optimizationTab)
            refreshVisibleOptimization();
        end

        clear refreshCleanup;
    end

    function finishCoreRefresh()
        dashboardState.isRefreshing = false;

        if isvalid(profileDropdown)
            profileDropdown.Enable = "on";
        end
        if isvalid(sessionScenarioDropdown)
            sessionScenarioDropdown.Enable = "on";
        end
        if isvalid(exitManagementDropdown)
            exitManagementDropdown.Enable = "on";
        end
    end

    function requestAnalyticsRefresh()
        dashboardState.analyticsDirty = true;

        if isequal(leftTabs.SelectedTab,analyticsTab) && ...
                isequal(analyticsTabs.SelectedTab,calendarRollingTab)
            safeRefreshCalendarRolling();
        end
    end

    function requestDistributionRefresh()
        dashboardState.distributionDirty = true;

        if isequal(leftTabs.SelectedTab,analyticsTab) && ...
                isequal(analyticsTabs.SelectedTab,distributionTab)
            safeRefreshDistribution();
        end
    end

    function requestSegmentRefresh()
        dashboardState.segmentDirty = true;

        if dashboardState.isRefreshing
            return;
        end

        if isequal(leftTabs.SelectedTab,analyticsTab) && ...
                isequal(analyticsTabs.SelectedTab,segmentExplorerTab)
            safeRefreshSegmentExplorer();
        end
    end

    function applyOptimizationParameterDefaults(slot)
        if isempty(optimizationParameterSchema)
            return;
        end

        if slot==1
            parameterName = string( ...
                optimizationParameter1Dropdown.Value);

            range = getOptimizationParameterRange( ...
                optimizationParameterSchema,parameterName);

            optimizationStart1Field.Value = range.start;
            optimizationStop1Field.Value = range.stop;
            optimizationStep1Field.Value = range.step;

            if ~isInitializingDashboard
                updateOptimizationEstimate();
            end
            return;
        end

        parameterName = string( ...
            optimizationParameter2Dropdown.Value);

        controls = [ ...
            optimizationStart2Field, ...
            optimizationStop2Field, ...
            optimizationStep2Field];

        if strlength(parameterName)==0
            for control = controls
                control.Enable = "off";
                control.Value = 0;
            end
            if ~isInitializingDashboard
                updateOptimizationEstimate();
            end
            return;
        end

        range = getOptimizationParameterRange( ...
            optimizationParameterSchema,parameterName);

        for control = controls
            control.Enable = "on";
        end

        optimizationStart2Field.Value = range.start;
        optimizationStop2Field.Value = range.stop;
        optimizationStep2Field.Value = range.step;

        if ~isInitializingDashboard
            updateOptimizationEstimate();
        end
    end

    function updateOptimizationEstimate()
        dashboardState.fullGridUiInitialized = true;

        try
            request = buildOptimizationRequest( ...
                optimizationParameterSchema, ...
                string(optimizationParameter1Dropdown.Value), ...
                optimizationStart1Field.Value, ...
                optimizationStop1Field.Value, ...
                optimizationStep1Field.Value, ...
                string(optimizationParameter2Dropdown.Value), ...
                optimizationStart2Field.Value, ...
                optimizationStop2Field.Value, ...
                optimizationStep2Field.Value);

            grid = buildParameterSweepGrid( ...
                request,round(optimizationLimitField.Value));

            firstCount = countSweepValues( ...
                request.start_value(1), ...
                request.stop_value(1), ...
                request.step_value(1), ...
                request.type(1));

            optimizationEstimateLabel.Text = sprintf( ...
                "Estimated runs: %d",height(grid));

            if height(request)==1
                optimizationEstimateDetailLabel.Text = sprintf( ...
                    "%d values × 1 backtest per value", ...
                    firstCount);
            else
                secondCount = countSweepValues( ...
                    request.start_value(2), ...
                    request.stop_value(2), ...
                    request.step_value(2), ...
                    request.type(2));

                optimizationEstimateDetailLabel.Text = sprintf( ...
                    "%d × %d parameter values = %d configurations", ...
                    firstCount,secondCount,height(grid));
            end

        catch ME
            optimizationEstimateLabel.Text = ...
                "Estimated runs: invalid";
            optimizationEstimateDetailLabel.Text = ...
                string(ME.message);
        end
    end

    function count = countSweepValues( ...
            startValue,stopValue,stepValue,parameterType)

        tolerance = max(1,abs(stopValue))*1e-10;
        values = startValue:stepValue:(stopValue+tolerance);
        values = values(values<=stopValue+tolerance);

        if parameterType=="integer"
            values = unique(round(values),"stable");
        end

        count = numel(values);
    end

    function runOptimization()
        if dashboardState.optimizationRunning || ...
                dashboardState.walkForwardRunning
            return;
        end

        if isempty(strategyRun.data)
            uialert( ...
                fig, ...
                "Optimization requires the source market data.", ...
                "Data unavailable");
            return;
        end

        try
            request = buildOptimizationRequest( ...
                optimizationParameterSchema, ...
                string(optimizationParameter1Dropdown.Value), ...
                optimizationStart1Field.Value, ...
                optimizationStop1Field.Value, ...
                optimizationStep1Field.Value, ...
                string(optimizationParameter2Dropdown.Value), ...
                optimizationStart2Field.Value, ...
                optimizationStop2Field.Value, ...
                optimizationStep2Field.Value);

            grid = buildParameterSweepGrid( ...
                request,round(optimizationLimitField.Value));

            selectedSchema = optimizationParameterSchema( ...
                ismember( ...
                    optimizationParameterSchema.name, ...
                    request.name),:);

        catch ME
            uialert( ...
                fig,ME.message, ...
                "Invalid optimization setup");
            return;
        end

        dashboardState.optimizationRunning = true;
        dashboardState.optimizationCancelRequested = false;

        setOptimizationControlsEnabled(false);
        optimizationCancelButton.Enable = "on";
        optimizationStatusLabel.Text = sprintf( ...
            "Preparing reusable context — %d configurations...", ...
            height(grid));
        drawnow;

        optimizationCleanup = onCleanup( ...
            @() finishOptimizationRun());

        profileName = string( ...
            optimizationProfileDropdown.Value);
        trainingPct = optimizationSplitField.Value;

        try
            prepared = getPreparedOptimizationContext( ...
                request,selectedSchema);

            optimizationStatusLabel.Text = sprintf( ...
                "Running 0/%d — context ready.", ...
                height(grid));
            drawnow limitrate;

            runnerFcn = @(parameterSet) ...
                runStrategyOptimizationCombination( ...
                    strategyName, ...
                    strategyRun.data, ...
                    cfg, ...
                    parameterSet, ...
                    profileName, ...
                    trainingPct, ...
                    prepared);

            callbacks = struct( ...
                "progress",@updateOptimizationProgress, ...
                "cancel",@isOptimizationCancelled, ...
                "progress_stride", ...
                    max(1,ceil(height(grid)/20)), ...
                "progress_interval_seconds",0.20);

            [optimizationResults, ...
             dashboardState.optimizationCache, ...
             runState] = runParameterSweep( ...
                strategyName,profileName,trainingPct, ...
                grid,runnerFcn, ...
                dashboardState.optimizationCache, ...
                callbacks,"FULL_GRID");

            dashboardState.optimizationResults = ...
                optimizationResults;
            dashboardState.optimizationRunState = runState;

            refreshOptimizationResults();

            files = saveOptimizationResults( ...
                optimizationResults,request,runState, ...
                cfg,strategyName,profileName);

            if runState.cancelled
                optimizationStatusLabel.Text = sprintf( ...
                    "Cancelled — %d/%d combinations completed.", ...
                    runState.completed,runState.requested);
            else
                optimizationStatusLabel.Text = sprintf( ...
                    "Completed — %d combinations. Saved: %s", ...
                    runState.completed,files.csv_file);
            end

        catch ME
            optimizationStatusLabel.Text = ...
                "Optimization failed: " + string(ME.message);

            warning( ...
                "QuantLab:OptimizationRun", ...
                "%s", ...
                getReport(ME,"extended","hyperlinks","off"));
        end

        clear optimizationCleanup;
    end

    function prepared = getPreparedOptimizationContext( ...
            request,selectedSchema)

        parameterNames = sort(string(request.name));
        cacheKey = strategyName + "|" + ...
            strjoin(parameterNames,";");

        if isKey( ...
                dashboardState.optimizationPreparedCache, ...
                char(cacheKey))
            prepared = ...
                dashboardState.optimizationPreparedCache( ...
                    char(cacheKey));
            return;
        end

        prepared = prepareStrategyOptimization( ...
            strategyName,strategyRun.data,cfg,selectedSchema);

        dashboardState.optimizationPreparedCache( ...
            char(cacheKey)) = prepared;
    end

    function updateOptimizationProgress(completed,total,currentResult)
        configuration = formatPlainNumber( ...
            currentResult.parameter_1_value,6,true);

        if strlength(currentResult.parameter_2_name)>0
            configuration = configuration + " / " + ...
                formatPlainNumber( ...
                    currentResult.parameter_2_value,6,true);
        end

        optimizationStatusLabel.Text = sprintf( ...
            "Running %d/%d — %s — %s", ...
            completed,total,configuration, ...
            currentResult.status);

        drawnow limitrate;
    end

    function result = isOptimizationCancelled()
        result = ...
            dashboardState.optimizationCancelRequested;
    end

    function cancelOptimization()
        if ~dashboardState.optimizationRunning
            return;
        end

        dashboardState.optimizationCancelRequested = true;
        optimizationCancelButton.Enable = "off";
        optimizationStatusLabel.Text = ...
            "Cancellation requested — finishing current run...";
        drawnow;
    end

    function finishOptimizationRun()
        dashboardState.optimizationRunning = false;
        optimizationCancelButton.Enable = "off";
        setOptimizationControlsEnabled(true);
    end

    function setOptimizationControlsEnabled(enabled)
        if enabled
            state = "on";
        else
            state = "off";
        end

        controls = [ ...
            optimizationProfileDropdown, ...
            optimizationParameter1Dropdown, ...
            optimizationParameter2Dropdown, ...
            optimizationStart1Field, ...
            optimizationStop1Field, ...
            optimizationStep1Field, ...
            optimizationStart2Field, ...
            optimizationStop2Field, ...
            optimizationStep2Field, ...
            optimizationMetricDropdown, ...
            optimizationSplitField, ...
            optimizationLimitField, ...
            optimizationRunButton];

        for control = controls
            if isvalid(control)
                control.Enable = state;
            end
        end

        if enabled && ...
                strlength(string( ...
                    optimizationParameter2Dropdown.Value))==0
            optimizationStart2Field.Enable = "off";
            optimizationStop2Field.Enable = "off";
            optimizationStep2Field.Enable = "off";
        end
    end

    function refreshOptimizationResults()
        updateOptimizationDashboard( ...
            optimizationSurfaceAxes, ...
            optimizationRiskReturnAxes, ...
            optimizationResultsTable, ...
            optimizationSummaryTable, ...
            dashboardState.optimizationResults, ...
            string(optimizationMetricDropdown.Value), ...
            string(optimizationProfileDropdown.Value), ...
            dashboardState.optimizationRunState);

        drawnow nocallbacks;
    end


    function applyWalkForwardParameterDefaults(slot)
        if isempty(optimizationParameterSchema)
            return;
        end

        if slot==1
            parameterName = string(wfParameter1Dropdown.Value);
            range = getOptimizationParameterRange( ...
                optimizationParameterSchema,parameterName);
            wfStart1Field.Value = range.start;
            wfStop1Field.Value = range.stop;
            wfStep1Field.Value = range.step;

            if ~isInitializingDashboard
                updateWalkForwardEstimate();
            end
            return;
        end

        parameterName = string(wfParameter2Dropdown.Value);
        controls = [wfStart2Field,wfStop2Field,wfStep2Field];

        if strlength(parameterName)==0
            for control = controls
                control.Enable = "off";
                control.Value = 0;
            end
            if ~isInitializingDashboard
                updateWalkForwardEstimate();
            end
            return;
        end

        range = getOptimizationParameterRange( ...
            optimizationParameterSchema,parameterName);

        for control = controls
            control.Enable = "on";
        end

        wfStart2Field.Value = range.start;
        wfStop2Field.Value = range.stop;
        wfStep2Field.Value = range.step;

        if ~isInitializingDashboard
            updateWalkForwardEstimate();
        end
    end

    function updateWalkForwardEstimate()
        dashboardState.walkForwardUiInitialized = true;

        try
            [request,grid,plan] = buildWalkForwardSetup();
            totalRuns = height(plan.windows)*height(grid)*2;

            if wfEvaluateHoldoutCheckbox.Value && ...
                    plan.holdout.reserved
                totalRuns = totalRuns+1;
            end

            wfEstimateLabel.Text = sprintf( ...
                "Estimated runs: %d",totalRuns);

            if wfEvaluateHoldoutCheckbox.Value && ...
                    plan.holdout.reserved
                holdoutText = " + 1 final holdout";
            else
                holdoutText = "";
            end

            wfEstimateDetailLabel.Text = sprintf( ...
                "%d windows × %d configurations × 2 phases%s", ...
                height(plan.windows),height(grid),holdoutText);

            wfStatusLabel.Text = sprintf( ...
                "Ready — %d development sessions, %d holdout sessions.", ...
                plan.development_sessions,plan.holdout.sessions);
        catch ME
            wfEstimateLabel.Text = "Estimated runs: invalid";
            wfEstimateDetailLabel.Text = string(ME.message);
            wfStatusLabel.Text = string(ME.message);
        end
    end

    function [request,grid,plan] = buildWalkForwardSetup()
        request = buildOptimizationRequest( ...
            optimizationParameterSchema, ...
            string(wfParameter1Dropdown.Value), ...
            wfStart1Field.Value,wfStop1Field.Value,wfStep1Field.Value, ...
            string(wfParameter2Dropdown.Value), ...
            wfStart2Field.Value,wfStop2Field.Value,wfStep2Field.Value);

        plan = buildWalkForwardWindows( ...
            strategyRun.data, ...
            round(wfTrainingField.Value), ...
            round(wfValidationField.Value), ...
            round(wfStepField.Value), ...
            wfHoldoutField.Value, ...
            string(wfModeDropdown.Value));

        combinationLimit = floor( ...
            wfLimitField.Value/(2*height(plan.windows)));

        if combinationLimit<1
            error("QuantLab:WalkForwardRunLimit", ...
                ["Max runs is too low for the selected windows. " + ...
                 "Increase Max runs or reduce the grid."]);
        end

        grid = buildParameterSweepGrid( ...
            request,combinationLimit);

        totalRuns = height(plan.windows)*height(grid)*2;

        if wfEvaluateHoldoutCheckbox.Value && ...
                plan.holdout.reserved
            totalRuns = totalRuns+1;
        end

        if totalRuns>wfLimitField.Value
            error("QuantLab:WalkForwardRunLimit", ...
                "The setup generates %d runs; limit: %d.", ...
                totalRuns,round(wfLimitField.Value));
        end
    end

    function runWalkForward()
        if dashboardState.optimizationRunning || ...
                dashboardState.walkForwardRunning
            return;
        end

        if isempty(strategyRun.data)
            uialert(fig, ...
                "Walk-forward requires source market data.", ...
                "Data unavailable");
            return;
        end

        try
            [request,grid,plan] = buildWalkForwardSetup();
            selectedSchema = optimizationParameterSchema( ...
                ismember(optimizationParameterSchema.name,request.name),:);
        catch ME
            uialert(fig,ME.message,"Invalid walk-forward setup");
            return;
        end

        if wfEvaluateHoldoutCheckbox.Value && plan.holdout.reserved
            choice = uiconfirm( ...
                fig, ...
                ["This reveals the final holdout. " + ...
                 "Do not use its result to tune the strategy. " + ...
                 "Continue only after the research rules are frozen."], ...
                "Final holdout warning", ...
                "Options",["Evaluate","Keep locked"], ...
                "DefaultOption",2, ...
                "CancelOption",2);

            if string(choice)~="Evaluate"
                wfEvaluateHoldoutCheckbox.Value = false;
                updateWalkForwardEstimate();
                return;
            end
        end

        dashboardState.walkForwardRunning = true;
        dashboardState.walkForwardCancelRequested = false;
        setWalkForwardControlsEnabled(false);
        setOptimizationControlsEnabled(false);
        wfCancelButton.Enable = "on";

        profileName = string(wfProfileDropdown.Value);
        innerSplit = wfInnerSplitField.Value;
        selectionMetric = string(wfSelectionMetricDropdown.Value);

        runnerFactory = @(dataSlice,phase,windowId) ...
            createWalkForwardRunner( ...
                dataSlice,selectedSchema,profileName, ...
                innerSplit,phase,windowId);

        callbacks = struct( ...
            "progress",@updateWalkForwardProgress, ...
            "cancel",@isWalkForwardCancelled);

        cleanup = onCleanup(@() finishWalkForwardRun());

        try
            [walkForwardResult, ...
             dashboardState.optimizationCache, ...
             runState] = runWalkForwardOptimization( ...
                strategyName,profileName,strategyRun.data, ...
                grid,plan,selectionMetric,innerSplit, ...
                runnerFactory,dashboardState.optimizationCache, ...
                callbacks,wfEvaluateHoldoutCheckbox.Value);

            dashboardState.walkForwardResult = walkForwardResult;
            refreshWalkForwardResults();

            files = saveWalkForwardResults( ...
                walkForwardResult,request,cfg, ...
                strategyName,profileName);

            if runState.cancelled
                wfStatusLabel.Text = sprintf( ...
                    "Cancelled — %d/%d runs, %d/%d windows.", ...
                    runState.completed_runs,runState.requested_runs, ...
                    runState.completed_windows,runState.requested_windows);
            else
                wfStatusLabel.Text = sprintf( ...
                    "Completed — %d runs, %d windows. Saved: %s", ...
                    runState.completed_runs,runState.completed_windows, ...
                    files.aggregate_csv);
            end
        catch ME
            wfStatusLabel.Text = ...
                "Walk-forward failed: " + string(ME.message);
            warning("QuantLab:WalkForwardRun","%s", ...
                getReport(ME,"extended","hyperlinks","off"));
        end

        clear cleanup;
    end

    function runner = createWalkForwardRunner( ...
            dataSlice,selectedSchema,profileName, ...
            innerSplit,phase,windowId)
        %#ok<INUSD>
        prepared = prepareStrategyOptimization( ...
            strategyName,dataSlice,cfg,selectedSchema);

        runner = @(parameterSet) ...
            runStrategyOptimizationCombination( ...
                strategyName,dataSlice,cfg,parameterSet, ...
                profileName,innerSplit,prepared);
    end

    function updateWalkForwardProgress( ...
            completed,total,phase,windowNumber,currentResult)
        configuration = formatPlainNumber( ...
            currentResult.parameter_1_value,6,true);

        if strlength(currentResult.parameter_2_name)>0
            configuration = configuration + " / " + ...
                formatPlainNumber( ...
                    currentResult.parameter_2_value,6,true);
        end

        wfStatusLabel.Text = sprintf( ...
            "%s W%d — %d/%d runs — %s — %s", ...
            phase,windowNumber,completed,total, ...
            configuration,currentResult.status);
        drawnow limitrate;
    end

    function result = isWalkForwardCancelled()
        result = dashboardState.walkForwardCancelRequested;
    end

    function cancelWalkForward()
        if ~dashboardState.walkForwardRunning
            return;
        end

        dashboardState.walkForwardCancelRequested = true;
        wfCancelButton.Enable = "off";
        wfStatusLabel.Text = ...
            "Cancellation requested — finishing current backtest...";
        drawnow;
    end

    function finishWalkForwardRun()
        dashboardState.walkForwardRunning = false;
        wfCancelButton.Enable = "off";
        setWalkForwardControlsEnabled(true);
        setOptimizationControlsEnabled(true);
    end

    function setWalkForwardControlsEnabled(enabled)
        if enabled, state = "on"; else, state = "off"; end

        controls = [ ...
            wfProfileDropdown,wfModeDropdown, ...
            wfTrainingField,wfValidationField,wfStepField, ...
            wfHoldoutField,wfEvaluateHoldoutCheckbox, ...
            wfParameter1Dropdown,wfParameter2Dropdown, ...
            wfStart1Field,wfStop1Field,wfStep1Field, ...
            wfStart2Field,wfStop2Field,wfStep2Field, ...
            wfSelectionMetricDropdown,wfInnerSplitField, ...
            wfRankingDropdown,wfLimitField,wfRunButton];

        for control = controls
            if isvalid(control), control.Enable = state; end
        end

        if enabled && ...
                strlength(string(wfParameter2Dropdown.Value))==0
            wfStart2Field.Enable = "off";
            wfStop2Field.Enable = "off";
            wfStep2Field.Enable = "off";
        end
    end

    function refreshWalkForwardResults()
        updateWalkForwardDashboard( ...
            wfWindowAxes,wfStabilityAxes, ...
            wfWindowResultsTable,wfAggregateResultsTable, ...
            wfSummaryTable,dashboardState.walkForwardResult, ...
            string(wfRankingDropdown.Value), ...
            string(wfProfileDropdown.Value));
        drawnow nocallbacks;
    end

    function refreshVisibleOptimization()
        if ~isequal(leftTabs.SelectedTab,optimizationTab)
            return;
        end

        if isequal(optimizationTabs.SelectedTab, ...
                fullGridOptimizationTab)

            if ~dashboardState.fullGridUiInitialized
                updateOptimizationEstimate();
                dashboardState.fullGridUiInitialized = true;
                drawnow limitrate nocallbacks;
            end

            if ~isempty(dashboardState.optimizationResults)
                refreshOptimizationResults();
            end

        elseif isequal(optimizationTabs.SelectedTab, ...
                walkForwardOptimizationTab)

            if ~dashboardState.walkForwardUiInitialized
                updateWalkForwardEstimate();
                dashboardState.walkForwardUiInitialized = true;
                drawnow limitrate nocallbacks;
            end

            if ~isempty(fieldnames( ...
                    dashboardState.walkForwardResult))
                refreshWalkForwardResults();
            end
        end
    end

    function handleMainTabChanged()
        if isequal(leftTabs.SelectedTab,analyticsTab)
            refreshVisibleAnalytics();
        elseif isequal(leftTabs.SelectedTab,optimizationTab)
            refreshVisibleOptimization();
        end
    end

    function refreshVisibleAnalytics()
        if ~isequal(leftTabs.SelectedTab,analyticsTab)
            return;
        end

        if isequal(analyticsTabs.SelectedTab,calendarRollingTab)
            safeRefreshCalendarRolling();
        elseif isequal(analyticsTabs.SelectedTab,distributionTab)
            safeRefreshDistribution();
        elseif isequal(analyticsTabs.SelectedTab,segmentExplorerTab)
            safeRefreshSegmentExplorer();
        end
    end

    function safeRefreshCalendarRolling()
        if ~dashboardState.analyticsDirty
            return;
        end

        trades = dashboardState.currentTrades;

        if isempty(trades)
            return;
        end

        try
            updateAnalyticsDashboard( ...
                calendarAxes, ...
                calendarSummaryTable, ...
                rollingWinRateAxes, ...
                rollingExpectancyAxes, ...
                rollingProfitFactorAxes, ...
                rollingSharpeAxes, ...
                rollingDrawdownAxes, ...
                rollingExecutionAxes, ...
                trades, ...
                str2double(rollingWindowDropdown.Value));

            dashboardState.analyticsDirty = false;
            drawnow nocallbacks;

        catch ME
            dashboardState.analyticsDirty = true;

            showAnalyticsError( ...
                calendarAxes, ...
                calendarSummaryTable, ...
                "Calendar & Rolling", ...
                ME);

            warning( ...
                "QuantLab:AnalyticsRender", ...
                "%s", ...
                getReport(ME,"extended","hyperlinks","off"));
        end
    end

    function safeRefreshDistribution()
        if ~dashboardState.distributionDirty
            return;
        end

        trades = dashboardState.currentTrades;

        if isempty(trades)
            return;
        end

        try
            updateTradeDistributionDashboard( ...
                rDistributionAxes, ...
                pnlDistributionAxes, ...
                directionDistributionAxes, ...
                exitDistributionAxes, ...
                detailDistributionAxes, ...
                distributionSummaryTable, ...
                trades, ...
                string(distributionFilterDropdown.Value), ...
                string(distributionDetailDropdown.Value));

            dashboardState.distributionDirty = false;
            drawnow nocallbacks;

        catch ME
            dashboardState.distributionDirty = true;

            showAnalyticsError( ...
                rDistributionAxes, ...
                distributionSummaryTable, ...
                "Trade Distribution", ...
                ME);

            warning( ...
                "QuantLab:DistributionRender", ...
                "%s", ...
                getReport(ME,"extended","hyperlinks","off"));
        end
    end

    function safeRefreshSegmentExplorer()
        if ~dashboardState.segmentDirty
            return;
        end

        trades = dashboardState.currentTrades;

        if isempty(trades) || isempty(segmentFeatureCatalog) || ...
                strlength(string(segmentFeatureDropdown.Value))==0
            return;
        end

        try
            updateSegmentExplorerDashboard( ...
                segmentMetricAxes, ...
                featureRankingAxes, ...
                segmentResultsTable, ...
                segmentSummaryTable, ...
                trades, ...
                segmentFeatureCatalog, ...
                string(segmentFeatureDropdown.Value), ...
                string(segmentGroupingDropdown.Value), ...
                string(segmentMetricDropdown.Value), ...
                round(segmentMinimumField.Value), ...
                segmentSplitField.Value);

            dashboardState.segmentDirty = false;
            drawnow nocallbacks;

        catch ME
            dashboardState.segmentDirty = true;

            showAnalyticsError( ...
                segmentMetricAxes, ...
                segmentSummaryTable, ...
                "Segment Explorer", ...
                ME);

            warning( ...
                "QuantLab:SegmentExplorerRender", ...
                "%s", ...
                getReport(ME,"extended","hyperlinks","off"));
        end
    end

    function selectOrdersRow(event)
        if isempty(event.Indices)
            return;
        end

        rowIndex = event.Indices(1,1);
        openOrdersResearchRow(rowIndex);
    end

    function openOrdersResearchRow(rowIndex)
        trades = dashboardState.currentOrders;

        if isempty(trades) || rowIndex < 1 || rowIndex > height(trades)
            return;
        end

        if dashboardState.selectedOrderIndex==rowIndex
            dashboardState.researchSource = "ORDERS";
            updateResearchNavigationControls();
            leftTabs.SelectedTab = researchTab;
            return;
        end

        tradeRow = trades(rowIndex,:);

        highlightTradeTableRow( ...
            ordersTable, ...
            rowIndex);

        % Fuerza el repintado para que toda la fila quede resaltada
        % inmediatamente al hacer clic.
        drawnow;

        leftTabs.SelectedTab = researchTab;
        showTradeResearchLoading(tradeResearchTitle,rowIndex);
        ordersTable.Enable = "off";
        cleanupTable = onCleanup(@() restoreOrdersTable());

        try
            updateTradeResearchMode( ...
                tradeResearchAxes, ...
                tradeResearchTitle, ...
                tradeResearchDetails, ...
                tradeResearchFeatures, ...
                researchCache, ...
                tradeRow, ...
                rowIndex, ...
                dashboardState.currentProfile, ...
                "Orden");

            dashboardState.selectedOrderIndex = rowIndex;
            dashboardState.selectedTradeIndex = NaN;
            dashboardState.researchSource = "ORDERS";
            updateResearchNavigationControls();
            drawnow limitrate nocallbacks;
        catch ME
            dashboardState.selectedOrderIndex = NaN;
            dashboardState.researchSource = "";
            updateResearchNavigationControls();
            showTradeResearchError( ...
                tradeResearchAxes,tradeResearchTitle, ...
                tradeResearchDetails,tradeResearchFeatures, ...
                rowIndex,ME);
            warning("QuantLab:OrderResearchRender","%s", ...
                getReport(ME,"extended","hyperlinks","off"));
        end

        clear cleanupTable;
    end

    function selectResearchTrade(event)
        if isempty(event.Indices)
            return;
        end

        rowIndex = event.Indices(1,1);
        openTradeResearchRow(rowIndex);
    end

    function openTradeResearchRow(rowIndex)
        trades = dashboardState.currentTrades;

        if isempty(trades) || rowIndex < 1 || rowIndex > height(trades)
            return;
        end

        % No recalcular si se vuelve a pulsar otra celda de la misma fila
        % y el render anterior terminó correctamente.
        if dashboardState.selectedTradeIndex==rowIndex
            dashboardState.researchSource = "TRADES";
            updateResearchNavigationControls();
            leftTabs.SelectedTab = researchTab;
            return;
        end

        tradeRow = trades(rowIndex,:);

        highlightTradeTableRow( ...
            tradesTable, ...
            rowIndex);

        tradeSelectionLabel.Text = sprintf( ...
            "Trade #%d seleccionado.", ...
            rowIndex);

        leftTabs.SelectedTab = researchTab;
        showTradeResearchLoading( ...
            tradeResearchTitle, ...
            rowIndex);

        % El índice solo se confirma después de renderizar correctamente.
        % Si ocurre un error, se permite volver a pulsar la misma fila.
        tradesTable.Enable = "off";
        cleanupTable = onCleanup(@() restoreTradesTable());

        try
            updateTradeResearchMode( ...
                tradeResearchAxes, ...
                tradeResearchTitle, ...
                tradeResearchDetails, ...
                tradeResearchFeatures, ...
                researchCache, ...
                tradeRow, ...
                rowIndex, ...
                dashboardState.currentProfile, ...
                "Trade");

            dashboardState.selectedTradeIndex = rowIndex;
            dashboardState.selectedOrderIndex = NaN;
            dashboardState.researchSource = "TRADES";
            updateResearchNavigationControls();
            drawnow limitrate nocallbacks;

        catch ME
            dashboardState.selectedTradeIndex = NaN;
            dashboardState.researchSource = "";
            updateResearchNavigationControls();

            showTradeResearchError( ...
                tradeResearchAxes, ...
                tradeResearchTitle, ...
                tradeResearchDetails, ...
                tradeResearchFeatures, ...
                rowIndex, ...
                ME);

            warning( ...
                "QuantLab:TradeResearchRender", ...
                "%s", ...
                getReport(ME,"extended","hyperlinks","off"));
        end

        clear cleanupTable;
    end

    function navigateResearch(step)
        source = dashboardState.researchSource;
        previousResearchButton.Enable = "off";
        nextResearchButton.Enable = "off";

        switch source
            case "ORDERS"
                rowIndex = dashboardState.selectedOrderIndex + step;
                if isfinite(rowIndex) && rowIndex>=1 && ...
                        rowIndex<=height(dashboardState.currentOrders)
                    openOrdersResearchRow(rowIndex);
                else
                    updateResearchNavigationControls();
                end
            case "TRADES"
                rowIndex = dashboardState.selectedTradeIndex + step;
                if isfinite(rowIndex) && rowIndex>=1 && ...
                        rowIndex<=height(dashboardState.currentTrades)
                    openTradeResearchRow(rowIndex);
                else
                    updateResearchNavigationControls();
                end
            otherwise
                updateResearchNavigationControls();
        end
    end

    function updateResearchNavigationControls()
        source = dashboardState.researchSource;
        switch source
            case "ORDERS"
                rowIndex = dashboardState.selectedOrderIndex;
                rowCount = height(dashboardState.currentOrders);
                previousResearchButton.Text = "← Orden anterior";
                nextResearchButton.Text = "Orden siguiente →";
            case "TRADES"
                rowIndex = dashboardState.selectedTradeIndex;
                rowCount = height(dashboardState.currentTrades);
                previousResearchButton.Text = "← Trade anterior";
                nextResearchButton.Text = "Trade siguiente →";
            otherwise
                rowIndex = NaN;
                rowCount = 0;
                previousResearchButton.Text = "← Anterior";
                nextResearchButton.Text = "Siguiente →";
        end

        if isfinite(rowIndex) && rowIndex>1
            previousResearchButton.Enable = "on";
        else
            previousResearchButton.Enable = "off";
        end
        if isfinite(rowIndex) && rowIndex<rowCount
            nextResearchButton.Enable = "on";
        else
            nextResearchButton.Enable = "off";
        end
    end

    function restoreTradesTable()
        if isvalid(tradesTable)
            tradesTable.Enable = "on";
        end
    end


    function restoreOrdersTable()
        if isvalid(ordersTable)
            ordersTable.Enable = "on";
        end
    end

    function selectTab(name)
        switch name
            case {"Strategy Equity","Drawdown","Exposure","Portfolio Turnover"}
                leftTabs.SelectedTab = overviewTab;
            case "Report"
                leftTabs.SelectedTab = reportTab;
            case "Trades"
                leftTabs.SelectedTab = tradesTab;
            case "Research"
                leftTabs.SelectedTab = researchTab;
            case "Analytics"
                leftTabs.SelectedTab = analyticsTab;
                refreshVisibleAnalytics();
            case "Optimization"
                leftTabs.SelectedTab = optimizationTab;
                refreshVisibleOptimization();
        end
    end

    function exportActiveTab()
        runDashboardExport("ACTIVE_TAB");
    end

    function exportEverything()
        runDashboardExport("ALL");
    end

    function runDashboardExport(mode)
        if dashboardState.optimizationRunning || ...
                dashboardState.walkForwardRunning
            uialert(fig, ...
                ["Espera a que termine o cancela el cálculo activo " + ...
                 "antes de exportar."], ...
                "Exportación no disponible");
            return;
        end

        exportTabButton.Enable = "off";
        exportAllButton.Enable = "off";
        exportCleanup = onCleanup(@() restoreExportButtons());

        try
            options = collectExportOptions(mode);
            report = exportQuantLabDashboardPackage( ...
                strategyRun,cfg,options);

            if report.errorCount>0
                message = "Exportación completada con " + ...
                    report.errorCount + " avisos:" + newline + ...
                    report.exportDirectory;
                titleText = "Exportación con avisos";
            else
                message = "Datos guardados en:" + newline + ...
                    report.exportDirectory;
                titleText = "Exportación completada";
            end

            uialert(fig,message,titleText);
        catch ME
            uialert(fig, ...
                "No se pudo completar la exportación:" + newline + ...
                string(ME.message), ...
                "Error de exportación");
            warning("QuantLab:DashboardExport","%s", ...
                getReport(ME,"extended","hyperlinks","off"));
        end

        clear exportCleanup;
    end

    function options = collectExportOptions(mode)
        [selectedRecord,researchDetails, ...
         researchSessionData,researchContext] = ...
            collectSelectedResearchExport();

        options = struct( ...
            "Mode",string(mode), ...
            "ActiveTab",currentExportTabName(), ...
            "Profile",dashboardState.currentProfile, ...
            "SessionScenario", ...
                dashboardState.currentSessionScenario, ...
            "ExitManagementScenario", ...
                dashboardState.currentExitManagementScenario, ...
            "RollingWindow", ...
                str2double(rollingWindowDropdown.Value), ...
            "DistributionFilter", ...
                string(distributionFilterDropdown.Value), ...
            "DistributionDetail", ...
                string(distributionDetailDropdown.Value), ...
            "SegmentFeature", ...
                string(segmentFeatureDropdown.Value), ...
            "SegmentGrouping", ...
                string(segmentGroupingDropdown.Value), ...
            "SegmentMetric", ...
                string(segmentMetricDropdown.Value), ...
            "SegmentMinimumSample", ...
                round(segmentMinimumField.Value), ...
            "SegmentTrainingPct",segmentSplitField.Value, ...
            "SelectedRecord",selectedRecord, ...
            "ResearchDetails",researchDetails, ...
            "ResearchSessionData",researchSessionData, ...
            "ResearchContext",researchContext, ...
            "OptimizationResults", ...
                dashboardState.optimizationResults, ...
            "WalkForwardResult", ...
                dashboardState.walkForwardResult, ...
            "LogLines",string(logsArea.Value), ...
            "Figure",fig);
    end

    function name = currentExportTabName()
        name = string(leftTabs.SelectedTab.Title);
        if isequal(leftTabs.SelectedTab,analyticsTab)
            name = name + " / " + ...
                string(analyticsTabs.SelectedTab.Title);
        elseif isequal(leftTabs.SelectedTab,optimizationTab)
            name = name + " / " + ...
                string(optimizationTabs.SelectedTab.Title);
        end
    end

    function [record,details,sessionData,contextTable] = ...
            collectSelectedResearchExport()
        record = table();
        details = table();
        sessionData = table();
        contextTable = table();
        rowIndex = NaN;
        recordLabel = "Trade";

        switch dashboardState.researchSource
            case "ORDERS"
                rowIndex = dashboardState.selectedOrderIndex;
                source = dashboardState.currentOrders;
                recordLabel = "Orden";
            case "TRADES"
                rowIndex = dashboardState.selectedTradeIndex;
                source = dashboardState.currentTrades;
            otherwise
                source = table();
        end

        if isempty(source) || ~isfinite(rowIndex) || ...
                rowIndex<1 || rowIndex>height(source)
            return;
        end

        record = source(rowIndex,:);
        details = buildTradeResearchDetails( ...
            record,rowIndex,dashboardState.currentProfile,recordLabel);
        [sessionData,context] = getCachedTradeResearchData( ...
            researchCache,record);
        if isstruct(context) && ~isempty(fieldnames(context))
            contextTable = struct2table(context);
        end
    end

    function restoreExportButtons()
        if isvalid(exportTabButton), exportTabButton.Enable = "on"; end
        if isvalid(exportAllButton), exportAllButton.Enable = "on"; end
    end

    function exportDashboard()
        out = fullfile( ...
            getQuantLabReportDirectory(cfg,strategyName),"Dashboard");
        if ~isfolder(out), mkdir(out); end
        stamp = string(datetime("now","Format","yyyyMMdd_HHmmss"));
        file = fullfile(out,"quantconnect_style_" + ...
            string(profileDropdown.Value) + "_" + stamp + ".png");
        exportapp(fig,file);
        uialert(fig,"Dashboard guardado en:" + newline + file, ...
            "Exportación completada");
    end
end



function s = money(v)
if isnan(v), s = "N/A"; else, s = sprintf("$%.2f",v); end
end

function s = pctOrNA(v)
if isnan(v), s = "N/A"; else, s = sprintf("%.3f %%",v); end
end

function s = numOrNA(v)
if isnan(v), s = "N/A"; else, s = sprintf("%.3f",v); end
end
