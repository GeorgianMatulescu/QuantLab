from __future__ import annotations

import json
from pathlib import Path
import tempfile
import unittest

import pandas as pd

from DataManager.Downloaders.databento_downloader import DatabentoHistoricalDownloader
from DataManager.Models.requests import DatabentoRequest


class _FakeData:
    def to_df(self) -> pd.DataFrame:
        index = pd.DatetimeIndex(
            ["2025-03-17T13:30:00Z", "2025-03-17T13:31:00Z"],
            name="ts_event",
        )
        return pd.DataFrame(
            {
                "instrument_id": [123, 123],
                "open": [20000.0, 20001.0],
                "high": [20002.0, 20003.0],
                "low": [19999.0, 20000.0],
                "close": [20001.0, 20002.0],
                "volume": [5, 8],
            },
            index=index,
        )


class _FakeMetadata:
    def __init__(self, cost: float) -> None:
        self.cost = cost

    def get_cost(self, **_: object) -> float:
        return self.cost


class _FakeTimeseries:
    def __init__(self) -> None:
        self.calls = 0

    def get_range(self, **_: object) -> _FakeData:
        self.calls += 1
        return _FakeData()


class _FakeSymbology:
    def resolve(self, **_: object) -> dict:
        return {
            "result": {
                "123": [
                    {"d0": "2025-01-01", "d1": "2026-01-01", "s": "MNQH5"}
                ]
            }
        }


class _FakeClient:
    def __init__(self, cost: float) -> None:
        self.metadata = _FakeMetadata(cost)
        self.timeseries = _FakeTimeseries()
        self.symbology = _FakeSymbology()


class DatabentoDownloaderTests(unittest.TestCase):
    def _settings(self, root: Path) -> dict:
        return {
            "storage": {
                "root": str(root),
                "sqlite": False,
                "csv": True,
                "parquet": False,
            },
            "historical": {
                "target_time_zone": "America/New_York",
                "what_to_show": "TRADES",
            },
        }

    def _request(self) -> DatabentoRequest:
        return DatabentoRequest(
            symbol="MNQ", start="2025-01-01", end="2026-01-01"
        )

    def test_cost_limit_stops_before_timeseries_download(self) -> None:
        client = _FakeClient(cost=3.25)
        with tempfile.TemporaryDirectory() as folder:
            downloader = DatabentoHistoricalDownloader(
                self._settings(Path(folder)), client=client
            )
            with self.assertRaisesRegex(RuntimeError, "límite autorizado"):
                downloader.download(self._request(), max_cost_usd=2.0)
        self.assertEqual(client.timeseries.calls, 0)

    def test_download_writes_auditable_contract_and_metadata(self) -> None:
        client = _FakeClient(cost=0.75)
        with tempfile.TemporaryDirectory() as folder:
            downloader = DatabentoHistoricalDownloader(
                self._settings(Path(folder)), client=client
            )
            result = downloader.download(self._request(), max_cost_usd=1.0)
            csv_path = next(path for path in result.files if path.suffix == ".csv")
            metadata_path = next(
                path for path in result.files if path.name.endswith(".metadata.json")
            )
            rolls_path = next(path for path in result.files if path.name.endswith(".rolls.csv"))
            frame = pd.read_csv(csv_path)
            rolls = pd.read_csv(rolls_path)
            metadata = json.loads(metadata_path.read_text(encoding="utf-8"))

        self.assertEqual(result.rows, 2)
        self.assertEqual(set(frame["local_symbol"]), {"MNQH5"})
        self.assertEqual(set(frame["continuous_symbol"]), {"MNQ.v.0"})
        self.assertEqual(metadata["provider"], "DATABENTO")
        self.assertEqual(metadata["roll_rule"], "previous_day_volume")
        self.assertEqual(metadata["price_adjustment"], "none_original_exchange_prices")
        self.assertEqual(metadata["unresolved_contract_rows"], 0)
        self.assertEqual(len(rolls), 1)
        self.assertEqual(rolls.loc[0, "local_symbol"], "MNQH5")


if __name__ == "__main__":
    unittest.main()
