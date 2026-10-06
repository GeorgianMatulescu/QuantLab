from __future__ import annotations

import json
import logging
import sqlite3
from pathlib import Path
from typing import Any

import pandas as pd

from DataManager.Models.requests import HistoricalRequest


class DatabaseWriter:
    """Guarda el mismo histórico en formatos reutilizables."""

    def __init__(self, settings: dict[str, Any]) -> None:
        self.settings = settings
        self.log = logging.getLogger(__name__)

    def write(
        self,
        frame: pd.DataFrame,
        request: HistoricalRequest,
        validation: dict[str, int],
        head_timestamp: str = "",
        provider: str = "IBKR",
        extra_metadata: dict[str, Any] | None = None,
    ) -> list[Path]:
        root = Path(self.settings["storage"]["root"])
        resolution = request.bar_size.replace(" ", "_")
        folder = root / request.symbol / resolution
        folder.mkdir(parents=True, exist_ok=True)

        session = "RTH" if request.use_rth else "ALL"
        stem = f"{request.symbol}_{request.sec_type.upper()}_{resolution}_{session}"
        files: list[Path] = []

        if self.settings["storage"].get("sqlite", True):
            path = folder / f"{stem}.sqlite"
            sqlite_frame = frame.copy()
            for column in ["datetime", "datetime_new_york"]:
                if column in sqlite_frame.columns:
                    sqlite_frame[column] = sqlite_frame[column].astype(str)
            with sqlite3.connect(path) as connection:
                sqlite_frame.to_sql("bars", connection, if_exists="replace", index=False)
                connection.execute(
                    "CREATE UNIQUE INDEX IF NOT EXISTS idx_bars_datetime ON bars(datetime)"
                )
            files.append(path)

        if self.settings["storage"].get("csv", True):
            path = folder / f"{stem}.csv"
            frame.to_csv(path, index=False)
            files.append(path)

        if self.settings["storage"].get("parquet", False):
            path = folder / f"{stem}.parquet"
            try:
                frame.to_parquet(path, index=False)
                files.append(path)
            except (ImportError, ModuleNotFoundError) as exc:
                self.log.warning(
                    "No se creó Parquet porque falta pyarrow o fastparquet: %s", exc
                )

        metadata_path = folder / f"{stem}.metadata.json"
        metadata = {
            "provider": provider,
            "symbol": request.symbol,
            "sec_type": request.sec_type.upper(),
            "exchange": request.exchange,
            "currency": request.currency,
            "bar_size": request.bar_size,
            "what_to_show": self.settings["historical"].get("what_to_show", "TRADES"),
            "use_rth": request.use_rth,
            "rows": int(len(frame)),
            "first_timestamp_utc": str(frame["datetime"].min()),
            "last_timestamp_utc": str(frame["datetime"].max()),
            "head_timestamp": head_timestamp,
            "validation": validation,
        }
        if extra_metadata:
            metadata.update(extra_metadata)
        metadata_path.write_text(
            json.dumps(metadata, indent=2, ensure_ascii=False), encoding="utf-8"
        )
        files.append(metadata_path)

        return files
