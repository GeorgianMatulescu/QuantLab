function ranking = rankStrategyFeatures( ...
    trades,catalog,minimumSample,trainingPct)
%RANKSTRATEGYFEATURES Ranking descriptivo de características.
%
% El score mide separación entre segmentos, cobertura de muestra y
% consistencia temporal. No implica causalidad ni poder predictivo.

arguments
    trades table
    catalog table
    minimumSample (1,1) double {mustBeInteger,mustBePositive} = 15
    trainingPct (1,1) double = 70
end

catalog = getAvailableFeatureCatalog(catalog,trades);
rows = cell(0,10);

for i = 1:height(catalog)
    featureName = catalog.name(i);

    analysis = analyzeStrategySegments( ...
        trades,featureName, ...
        catalog.default_grouping(i), ...
        minimumSample,trainingPct);

    segments = analysis.segments;

    if isempty(segments)
        continue;
    end

    qualified = segments.sample_ok & ...
        isfinite(segments.mean_outcome);

    if sum(qualified)<2
        continue;
    end

    qualifiedSegments = segments(qualified,:);
    spread = max(qualifiedSegments.mean_outcome) - ...
        min(qualifiedSegments.mean_outcome);

    minimumCount = min(qualifiedSegments.trade_count);
    coverage = sum(qualifiedSegments.trade_count) / ...
        max(1,sum(segments.trade_count));

    stabilityAvailable = ...
        qualifiedSegments.stable_sign~="N/A";

    if any(stabilityAvailable)
        agreement = 100*mean( ...
            qualifiedSegments.stable_sign(stabilityAvailable)=="YES");
        stabilityFactor = 0.5 + 0.5*agreement/100;
    else
        agreement = NaN;
        stabilityFactor = 0.5;
    end

    sampleFactor = sqrt( ...
        minimumCount/max(1,sum(segments.trade_count)));

    score = spread*coverage*sampleFactor*stabilityFactor;

    [bestOutcome,bestIndex] = ...
        max(qualifiedSegments.mean_outcome);
    [worstOutcome,worstIndex] = ...
        min(qualifiedSegments.mean_outcome);

    rows(end+1,:) = { ...
        featureName,catalog.label(i),catalog.type(i), ...
        height(segments),sum(qualified),minimumCount, ...
        score,bestOutcome,worstOutcome,agreement}; %#ok<AGROW>
end

if isempty(rows)
    ranking = table();
    return;
end

ranking = cell2table(rows, ...
    'VariableNames',{ ...
    'feature','label','type','segments', ...
    'qualified_segments','minimum_count','score', ...
    'best_outcome','worst_outcome','agreement_pct'});

ranking = sortrows(ranking,"score","descend");
end
