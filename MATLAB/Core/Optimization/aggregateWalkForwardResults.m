function aggregate = aggregateWalkForwardResults( ...
    grid,trainingSweeps,validationSweeps,selectedIds,selectionMetric)
%AGGREGATEWALKFORWARDRESULTS Consolida todas las ventanas por combinación.
%
% El score de robustez se define de forma explícita:
%   mean(OOS expectancy)
%   - 0.5 * std(OOS expectancy)
%   + 0.25 * min(worst OOS expectancy, 0)
%
% Después se calcula un Plateau Score usando configuraciones vecinas.

arguments
    grid table
    trainingSweeps cell
    validationSweeps cell
    selectedIds double
    selectionMetric (1,1) string
end

[selectionField,~] = ...
    resolveOptimizationMetricDefinition(selectionMetric);

rows = repmat(createAggregateTemplate(),height(grid),1);

for combinationIndex = 1:height(grid)
    combinationId = grid.combination_id(combinationIndex);

    trainMetric = [];
    oosMetric = [];
    trainExpectancy = [];
    oosExpectancy = [];
    oosPnl = [];
    oosReturn = [];
    oosDrawdown = [];
    oosProfitFactor = [];
    oosReturnDrawdown = [];
    signAgreement = [];
    oosSignatures = strings(0,1);
    oosTradeCount = [];
    oosTargetExits = [];
    oosStopExits = [];
    oosEODExits = [];
    effectiveWindows = [];

    for windowIndex = 1:numel(trainingSweeps)
        training = trainingSweeps{windowIndex};
        validation = validationSweeps{windowIndex};

        if isempty(training) || isempty(validation)
            continue;
        end

        trainRow = training( ...
            training.combination_id==combinationId & ...
            training.status=="OK",:);
        validationRow = validation( ...
            validation.combination_id==combinationId & ...
            validation.status=="OK",:);

        if isempty(trainRow) || isempty(validationRow)
            continue;
        end

        trainMetric(end+1,1) = ... %#ok<AGROW>
            trainRow.(selectionField)(1);
        oosMetric(end+1,1) = ... %#ok<AGROW>
            validationRow.(selectionField)(1);
        trainExpectancy(end+1,1) = ... %#ok<AGROW>
            trainRow.expectancy_r(1);
        oosExpectancy(end+1,1) = ... %#ok<AGROW>
            validationRow.expectancy_r(1);
        oosPnl(end+1,1) = ... %#ok<AGROW>
            validationRow.net_pnl_usd(1);
        oosReturn(end+1,1) = ... %#ok<AGROW>
            validationRow.return_pct(1);
        oosDrawdown(end+1,1) = ... %#ok<AGROW>
            validationRow.max_drawdown_pct(1);
        oosProfitFactor(end+1,1) = ... %#ok<AGROW>
            validationRow.profit_factor(1);
        oosReturnDrawdown(end+1,1) = ... %#ok<AGROW>
            validationRow.return_drawdown_ratio(1);
        oosSignatures(end+1,1) = ... %#ok<AGROW>
            string(validationRow.behavior_signature(1));
        oosTradeCount(end+1,1) = ... %#ok<AGROW>
            validationRow.executed_trades(1);
        oosTargetExits(end+1,1) = ... %#ok<AGROW>
            validationRow.target_exit_count(1);
        oosStopExits(end+1,1) = ... %#ok<AGROW>
            validationRow.stop_exit_count(1);
        oosEODExits(end+1,1) = ... %#ok<AGROW>
            validationRow.eod_exit_count(1);

        if ismember("activity_status", ...
                string(validationRow.Properties.VariableNames))
            effectiveWindows(end+1,1) = ... %#ok<AGROW>
                ~ismember(validationRow.activity_status(1), ...
                    ["INACTIVE_PLATEAU","NO_TRADES"]);
        end

        if isfinite(trainRow.expectancy_r(1)) && ...
                isfinite(validationRow.expectancy_r(1))
            signAgreement(end+1,1) = ... %#ok<AGROW>
                sign(trainRow.expectancy_r(1))== ...
                sign(validationRow.expectancy_r(1));
        end
    end

    meanOOS = safeMean(oosExpectancy);
    stdOOS = safeStd(oosExpectancy);
    worstOOS = safeMin(oosExpectancy);

    robustness = NaN;

    if isfinite(meanOOS)
        penaltyStd = zeroIfNaN(stdOOS);
        downsidePenalty = 0;

        if isfinite(worstOOS)
            downsidePenalty = 0.25*min(worstOOS,0);
        end

        robustness = meanOOS - ...
            0.5*penaltyStd + downsidePenalty;
    end

    rows(combinationIndex) = struct( ...
        "combination_id",combinationId, ...
        "parameter_set",{grid.parameter_set{combinationIndex}}, ...
        "parameter_1_name",grid.parameter_1_name(combinationIndex), ...
        "parameter_1_label",grid.parameter_1_label(combinationIndex), ...
        "parameter_1_value",grid.parameter_1_value(combinationIndex), ...
        "parameter_2_name",grid.parameter_2_name(combinationIndex), ...
        "parameter_2_label",grid.parameter_2_label(combinationIndex), ...
        "parameter_2_value",grid.parameter_2_value(combinationIndex), ...
        "windows_evaluated",numel(finiteOnly(oosExpectancy)), ...
        "selection_count",sum(selectedIds==combinationId), ...
        "mean_train_selection_metric",safeMean(trainMetric), ...
        "mean_oos_selection_metric",safeMean(oosMetric), ...
        "mean_train_expectancy_r",safeMean(trainExpectancy), ...
        "mean_oos_expectancy_r",meanOOS, ...
        "median_oos_expectancy_r",safeMedian(oosExpectancy), ...
        "std_oos_expectancy_r",stdOOS, ...
        "worst_oos_expectancy_r",worstOOS, ...
        "positive_oos_pct",positivePercentage(oosExpectancy), ...
        "sign_agreement_pct",100*safeMean(signAgreement), ...
        "total_oos_pnl_usd",safeSum(oosPnl), ...
        "mean_oos_return_pct",safeMean(oosReturn), ...
        "mean_oos_drawdown_pct",safeMean(oosDrawdown), ...
        "mean_oos_profit_factor",safeMean(oosProfitFactor), ...
        "mean_oos_return_drawdown",safeMean(oosReturnDrawdown), ...
        "total_oos_trades",safeSum(oosTradeCount), ...
        "total_oos_target_exits",safeSum(oosTargetExits), ...
        "total_oos_stop_exits",safeSum(oosStopExits), ...
        "total_oos_eod_exits",safeSum(oosEODExits), ...
        "effective_oos_windows",safeSum(effectiveWindows), ...
        "inactive_oos_pct",inactivePercentage( ...
            effectiveWindows,numel(oosSignatures)), ...
        "aggregate_behavior_signature", ...
            buildAggregateSignature(oosSignatures), ...
        "wf_robustness_score",robustness, ...
        "neighbor_count",0, ...
        "neighborhood_mean_score",NaN, ...
        "neighborhood_std_score",NaN, ...
        "plateau_score",NaN);
end

aggregate = struct2table(rows);
aggregate = annotateParameterActivity( ...
    aggregate,"aggregate_behavior_signature","total_oos_trades");
aggregate = addNeighborhoodStability(aggregate);
end

function template = createAggregateTemplate()
template = struct( ...
    "combination_id",0, ...
    "parameter_set",{{table()}}, ...
    "parameter_1_name","", ...
    "parameter_1_label","", ...
    "parameter_1_value",NaN, ...
    "parameter_2_name","", ...
    "parameter_2_label","", ...
    "parameter_2_value",NaN, ...
    "windows_evaluated",0, ...
    "selection_count",0, ...
    "mean_train_selection_metric",NaN, ...
    "mean_oos_selection_metric",NaN, ...
    "mean_train_expectancy_r",NaN, ...
    "mean_oos_expectancy_r",NaN, ...
    "median_oos_expectancy_r",NaN, ...
    "std_oos_expectancy_r",NaN, ...
    "worst_oos_expectancy_r",NaN, ...
    "positive_oos_pct",NaN, ...
    "sign_agreement_pct",NaN, ...
    "total_oos_pnl_usd",NaN, ...
    "mean_oos_return_pct",NaN, ...
    "mean_oos_drawdown_pct",NaN, ...
    "mean_oos_profit_factor",NaN, ...
    "mean_oos_return_drawdown",NaN, ...
    "total_oos_trades",0, ...
    "total_oos_target_exits",0, ...
    "total_oos_stop_exits",0, ...
    "total_oos_eod_exits",0, ...
    "effective_oos_windows",0, ...
    "inactive_oos_pct",NaN, ...
    "aggregate_behavior_signature","EMPTY", ...
    "wf_robustness_score",NaN, ...
    "neighbor_count",0, ...
    "neighborhood_mean_score",NaN, ...
    "neighborhood_std_score",NaN, ...
    "plateau_score",NaN);
end

function aggregate = addNeighborhoodStability(aggregate)
if isempty(aggregate)
    return;
end

firstValues = unique(aggregate.parameter_1_value,"sorted");
hasSecond = any(strlength(aggregate.parameter_2_name)>0);

if hasSecond
    secondValues = unique( ...
        aggregate.parameter_2_value(isfinite( ...
            aggregate.parameter_2_value)),"sorted");
else
    secondValues = NaN;
end

for i = 1:height(aggregate)
    firstIndex = find( ...
        firstValues==aggregate.parameter_1_value(i),1);

    if hasSecond
        secondIndex = find( ...
            secondValues==aggregate.parameter_2_value(i),1);
    else
        secondIndex = 1;
    end

    neighborMask = false(height(aggregate),1);

    for j = 1:height(aggregate)
        candidateFirstIndex = find( ...
            firstValues==aggregate.parameter_1_value(j),1);

        if hasSecond
            candidateSecondIndex = find( ...
                secondValues==aggregate.parameter_2_value(j),1);
        else
            candidateSecondIndex = 1;
        end

        neighborMask(j) = ...
            abs(candidateFirstIndex-firstIndex)<=1 && ...
            abs(candidateSecondIndex-secondIndex)<=1;
    end

    scores = aggregate.wf_robustness_score(neighborMask);
    scores = scores(isfinite(scores));

    aggregate.neighbor_count(i) = max(0,numel(scores)-1);
    aggregate.neighborhood_mean_score(i) = safeMean(scores);
    aggregate.neighborhood_std_score(i) = safeStd(scores);

    if ~isempty(scores)
        aggregate.plateau_score(i) = ...
            safeMean(scores) - 0.5*zeroIfNaN(safeStd(scores));
    end
end
end

function values = finiteOnly(values)
values = values(isfinite(values));
end

function value = safeMean(values)
values = finiteOnly(double(values));
if isempty(values), value = NaN; else, value = mean(values); end
end

function value = safeMedian(values)
values = finiteOnly(double(values));
if isempty(values), value = NaN; else, value = median(values); end
end

function value = safeStd(values)
values = finiteOnly(double(values));
if numel(values)<2, value = NaN; else, value = std(values); end
end

function value = safeMin(values)
values = finiteOnly(double(values));
if isempty(values), value = NaN; else, value = min(values); end
end

function value = safeSum(values)
values = finiteOnly(double(values));
if isempty(values), value = NaN; else, value = sum(values); end
end

function value = positivePercentage(values)
values = finiteOnly(double(values));
if isempty(values)
    value = NaN;
else
    value = 100*mean(values>0);
end
end

function value = zeroIfNaN(value)
if ~isfinite(value), value = 0; end
end


function signature = buildAggregateSignature(signatures)
signatures = string(signatures);

if isempty(signatures)
    signature = "EMPTY";
else
    signature = strjoin(signatures,"||");
end
end

function value = inactivePercentage(effectiveWindows,totalWindows)
effectiveWindows = finiteOnly(double(effectiveWindows));

if totalWindows<=0 || isempty(effectiveWindows)
    value = NaN;
else
    value = 100*(1-sum(effectiveWindows)/totalWindows);
end
end
