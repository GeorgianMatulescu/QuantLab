function metrics = runStrategyOptimizationCombination( ...
    strategyName,data,baseCfg,parameterSet, ...
    profileName,trainingPct,prepared)
%RUNSTRATEGYOPTIMIZATIONCOMBINATION Ejecuta una configuración genérica.
%
% Los plugins pueden exponer opcionalmente runProfile para evitar
% calcular perfiles que el optimizador no ha solicitado.

arguments
    strategyName (1,1) string
    data table
    baseCfg (1,1) struct
    parameterSet table
    profileName (1,1) string
    trainingPct (1,1) double
    prepared (1,1) struct
end

trialCfg = applyOptimizationParameters( ...
    baseCfg,parameterSet);

if prepared.use_prepared_context && ...
        isfield(prepared.plugin,"runProfile") && ...
        isa(prepared.plugin.runProfile,"function_handle")

    scenario = prepared.plugin.runProfile( ...
        data,prepared.context,prepared.events, ...
        trialCfg,profileName);

elseif prepared.use_prepared_context
    results = prepared.plugin.run( ...
        data,prepared.context, ...
        prepared.events,trialCfg);

    scenario = getDashboardScenario( ...
        results,profileName);

else
    output = runStrategy( ...
        strategyName,data,trialCfg);

    scenario = getDashboardScenario( ...
        output.results,profileName);
end

metrics = calculateOptimizationMetrics( ...
    scenario,trialCfg,trainingPct);
end
