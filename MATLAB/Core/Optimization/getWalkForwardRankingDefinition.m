function [fieldName,direction,label] = ...
    getWalkForwardRankingDefinition(metricName)
%GETWALKFORWARDRANKINGDEFINITION Ranking agregado de robustez temporal.

arguments
    metricName (1,1) string
end

switch metricName
    case "WF Robustness"
        fieldName = "wf_robustness_score";
        direction = "descend";
        label = "WF Robustness";

    case "Mean OOS Expectancy (R)"
        fieldName = "mean_oos_expectancy_r";
        direction = "descend";
        label = "Mean OOS Expectancy (R)";

    case "Positive OOS Windows (%)"
        fieldName = "positive_oos_pct";
        direction = "descend";
        label = "Positive OOS Windows (%)";

    case "Worst OOS Expectancy (R)"
        fieldName = "worst_oos_expectancy_r";
        direction = "descend";
        label = "Worst OOS Expectancy (R)";

    case "Total OOS PnL (USD)"
        fieldName = "total_oos_pnl_usd";
        direction = "descend";
        label = "Total OOS PnL (USD)";

    case "Mean OOS Return / Drawdown"
        fieldName = "mean_oos_return_drawdown";
        direction = "descend";
        label = "Mean OOS Return / Drawdown";

    case "Lowest Mean OOS Drawdown (%)"
        fieldName = "mean_oos_drawdown_pct";
        direction = "ascend";
        label = "Mean OOS Drawdown (%)";

    otherwise
        fieldName = "plateau_score";
        direction = "descend";
        label = "Plateau Score";
end
end
