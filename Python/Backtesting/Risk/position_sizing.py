from __future__ import annotations

import math


def contracts_for_fixed_risk(risk_budget: float, stop_points: float, point_value: float, max_contracts: int) -> int:
    if risk_budget <= 0 or stop_points <= 0 or point_value <= 0:
        return 0
    return max(0, min(math.floor(risk_budget / (stop_points * point_value)), max_contracts))
