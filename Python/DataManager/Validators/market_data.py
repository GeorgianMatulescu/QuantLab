from __future__ import annotations

import pandas as pd


def validate_bars(frame: pd.DataFrame) -> tuple[pd.DataFrame, dict[str, int]]:
    """Ordena, deduplica y valida barras OHLC."""
    required = {"datetime", "open", "high", "low", "close"}
    missing = required.difference(frame.columns)
    if missing:
        raise ValueError(f"Faltan columnas obligatorias: {sorted(missing)}")

    original_rows = len(frame)
    frame = (
        frame.sort_values("datetime")
        .drop_duplicates(subset=["datetime"], keep="last")
        .copy()
    )
    duplicates_removed = original_rows - len(frame)

    numeric_columns = [
        column
        for column in ["open", "high", "low", "close", "volume", "average", "barCount"]
        if column in frame.columns
    ]
    for column in numeric_columns:
        frame[column] = pd.to_numeric(frame[column], errors="coerce")

    before_na = len(frame)
    frame = frame.dropna(subset=["datetime", "open", "high", "low", "close"])
    rows_with_missing_values_removed = before_na - len(frame)

    valid_ohlc = (
        (frame["high"] >= frame["low"])
        & (frame["high"] >= frame["open"])
        & (frame["high"] >= frame["close"])
        & (frame["low"] <= frame["open"])
        & (frame["low"] <= frame["close"])
    )
    invalid_ohlc_removed = int((~valid_ohlc).sum())
    frame = frame.loc[valid_ohlc].reset_index(drop=True)

    return frame, {
        "duplicates_removed": duplicates_removed,
        "rows_with_missing_values_removed": rows_with_missing_values_removed,
        "invalid_ohlc_removed": invalid_ohlc_removed,
    }
