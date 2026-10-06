function [fieldName,direction,label] = ...
    resolveOptimizationMetricDefinition(metricName)
%RESOLVEOPTIMIZATIONMETRICDEFINITION Shared optimization metric contract.

arguments
    metricName (1,1) string
end

switch metricName
    case "Return / Drawdown"
        fieldName = "return_drawdown_ratio";
        direction = "descend";
        label = "Return / Drawdown";

    case "Expectancy (R)"
        fieldName = "expectancy_r";
        direction = "descend";
        label = "Expectancy (R)";

    case "Profit Factor"
        fieldName = "profit_factor";
        direction = "descend";
        label = "Profit Factor";

    case "OOS Expectancy (R)"
        fieldName = "oos_expectancy_r";
        direction = "descend";
        label = "OOS Expectancy (R)";

    case "Robustness"
        fieldName = "robustness_score";
        direction = "descend";
        label = "Robustness Score";

    case "Lowest Drawdown (%)"
        fieldName = "max_drawdown_pct";
        direction = "ascend";
        label = "Max Drawdown (%)";

    case "Net R"
        fieldName = "net_r";
        direction = "descend";
        label = "Net R";

    otherwise
        fieldName = "net_pnl_usd";
        direction = "descend";
        label = "Net PnL (USD)";
end
end
