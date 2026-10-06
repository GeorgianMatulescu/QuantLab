import pandas as pd

from DataManager.Validators.market_data import validate_bars


def test_removes_duplicate_timestamps():
    frame = pd.DataFrame({
        "datetime": pd.to_datetime(["2026-01-01T00:00:00Z", "2026-01-01T00:00:00Z"]),
        "open": [1.0, 1.0],
        "high": [2.0, 2.0],
        "low": [0.5, 0.5],
        "close": [1.5, 1.5],
    })
    cleaned, stats = validate_bars(frame)
    assert len(cleaned) == 1
    assert stats["duplicates_removed"] == 1
