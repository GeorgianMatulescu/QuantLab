import tempfile
import unittest
from datetime import date
import json
from pathlib import Path
from types import SimpleNamespace
from unittest.mock import patch

import pandas as pd

from DataManager.Downloaders.ibkr_futures_chain_downloader import (
    IBKRFuturesChainDownloader,
    ResolvedFuture,
    _ChainCache,
    _globex_boundary,
    _is_expected_weekend_closure,
    _minimum_expected_chunk_rows,
    quarterly_local_symbols,
)
from DataManager.Models.requests import FuturesChainRequest


class FuturesChainTests(unittest.TestCase):
    def test_contract_discovery_runs_newest_to_oldest_and_keeps_available_tail(self):
        class FakeBase:
            def __init__(self):
                self.calls = []

            def resolve(self, request):
                self.calls.append(request.local_symbol)
                if request.local_symbol == "MNQZ4":
                    raise RuntimeError("IBKR no pudo resolver MNQ/FUT")
                month = {"H": "03", "M": "06", "U": "09", "Z": "12"}[
                    request.local_symbol[-2]
                ]
                year = "202" + request.local_symbol[-1]
                return SimpleNamespace(
                    localSymbol=request.local_symbol,
                    conId=len(self.calls),
                    lastTradeDateOrContractMonth=year + month,
                )

        request = FuturesChainRequest(
            symbol="MNQ", start="2024-10-03", end="2026-10-03"
        )
        downloader = IBKRFuturesChainDownloader.__new__(
            IBKRFuturesChainDownloader
        )
        downloader.base = FakeBase()
        downloader.log = __import__("logging").getLogger(__name__)
        downloader.unavailable_contracts = []
        contracts = downloader._resolve_contracts(request)
        self.assertEqual(downloader.base.calls[0], "MNQZ6")
        self.assertEqual(downloader.base.calls[-1], "MNQZ4")
        self.assertEqual(contracts[0].local_symbol, "MNQH5")
        self.assertEqual(contracts[-1].local_symbol, "MNQZ6")
        self.assertEqual(downloader.unavailable_contracts, ["MNQZ4"])

    def test_partial_coverage_starts_after_previous_contract_expiry(self):
        request = FuturesChainRequest(
            symbol="MNQ", start="2024-10-03", end="2025-02-01"
        )
        oldest = ResolvedFuture("MNQH5", 2, date(2025, 3, 21), object())
        daily = {
            "MNQH5": pd.DataFrame(
                {
                    "session_date": [date(2024, 12, 20), date(2024, 12, 23)],
                    "volume": [100, 1200],
                }
            )
        }
        self.assertEqual(
            IBKRFuturesChainDownloader._effective_start_utc(
                request, [oldest], daily
            ),
            pd.Timestamp("2024-12-22 23:00:00+00:00"),
        )

    def test_quarterly_symbols_cover_requested_period(self):
        self.assertEqual(
            quarterly_local_symbols(
                "MNQ", date(2024, 10, 3), date(2026, 10, 3)
            ),
            [
                "MNQZ4",
                "MNQH5",
                "MNQM5",
                "MNQU5",
                "MNQZ5",
                "MNQH6",
                "MNQM6",
                "MNQU6",
                "MNQZ6",
            ],
        )

    def test_globex_boundary_uses_new_york_dst(self):
        self.assertEqual(
            _globex_boundary(date(2024, 12, 13)),
            pd.Timestamp("2024-12-12 23:00:00+00:00"),
        )
        self.assertEqual(
            _globex_boundary(date(2025, 6, 13)),
            pd.Timestamp("2025-06-12 22:00:00+00:00"),
        )

    def test_volume_crossover_rolls_on_next_session(self):
        old = ResolvedFuture("MNQZ4", 1, date(2024, 12, 20), object())
        new = ResolvedFuture("MNQH5", 2, date(2025, 3, 21), object())
        daily = {
            "MNQZ4": pd.DataFrame(
                {
                    "session_date": [
                        date(2024, 12, 11),
                        date(2024, 12, 12),
                        date(2024, 12, 13),
                    ],
                    "volume": [1000, 900, 700],
                }
            ),
            "MNQH5": pd.DataFrame(
                {
                    "session_date": [
                        date(2024, 12, 11),
                        date(2024, 12, 12),
                        date(2024, 12, 13),
                    ],
                    "volume": [800, 950, 1200],
                }
            ),
        }
        request = FuturesChainRequest(
            symbol="MNQ", start="2024-10-03", end="2025-02-01"
        )
        downloader = IBKRFuturesChainDownloader.__new__(
            IBKRFuturesChainDownloader
        )
        segments, decisions = downloader._build_segments(
            [old, new], daily, request
        )
        self.assertEqual(decisions[0].trigger_session, date(2024, 12, 12))
        self.assertEqual(decisions[0].effective_session, date(2024, 12, 13))
        self.assertEqual(
            segments[0].end_utc,
            pd.Timestamp("2024-12-12 23:00:00+00:00"),
        )
        self.assertEqual(segments[1].contract.local_symbol, "MNQH5")

    def test_start_after_roll_uses_incoming_contract(self):
        old = ResolvedFuture("MNQZ4", 1, date(2024, 12, 20), object())
        new = ResolvedFuture("MNQH5", 2, date(2025, 3, 21), object())
        daily = {
            "MNQZ4": pd.DataFrame(
                {
                    "session_date": [date(2024, 12, 12), date(2024, 12, 13)],
                    "volume": [900, 700],
                }
            ),
            "MNQH5": pd.DataFrame(
                {
                    "session_date": [date(2024, 12, 12), date(2024, 12, 13)],
                    "volume": [950, 1200],
                }
            ),
        }
        request = FuturesChainRequest(
            symbol="MNQ", start="2024-12-16", end="2025-02-01"
        )
        downloader = IBKRFuturesChainDownloader.__new__(
            IBKRFuturesChainDownloader
        )
        segments, decisions = downloader._build_segments(
            [old, new], daily, request
        )
        self.assertEqual(decisions, [])
        self.assertEqual(len(segments), 1)
        self.assertEqual(segments[0].contract.local_symbol, "MNQH5")

    def test_cache_is_resumable_and_deduplicates(self):
        with tempfile.TemporaryDirectory() as temporary:
            cache = _ChainCache(Path(temporary) / "chain.sqlite")
            start = pd.Timestamp("2025-01-01 00:00:00+00:00")
            end = pd.Timestamp("2025-01-02 00:00:00+00:00")
            frame = pd.DataFrame(
                {
                    "datetime": [pd.Timestamp("2025-01-01 00:01:00+00:00")],
                    "open": [20000.0],
                    "high": [20000.25],
                    "low": [19999.75],
                    "close": [20000.0],
                    "volume": [5.0],
                    "average": [20000.0],
                    "barCount": [2],
                    "con_id": [123],
                }
            )
            cache.store("MNQH5", start, end, frame)
            cache.store("MNQH5", start, end, frame)
            self.assertTrue(cache.is_complete("MNQH5", start, end))
            loaded = cache.read_segment("MNQH5", start, end)
            self.assertEqual(len(loaded), 1)

    def test_weekday_empty_chunk_retries_and_is_not_accepted(self):
        class EmptyIB:
            def __init__(self):
                self.calls = 0
                self.durations = []

            def isConnected(self):
                return True

            def reqHistoricalData(self, *_args, **kwargs):
                self.calls += 1
                self.durations.append(kwargs["durationStr"])
                return []

        downloader = IBKRFuturesChainDownloader.__new__(
            IBKRFuturesChainDownloader
        )
        downloader.base = SimpleNamespace(ib=EmptyIB())
        downloader.log = __import__("logging").getLogger(__name__)
        downloader.settings = {
            "ibkr": {"historical_timeout_seconds": 1, "historical_retries": 3},
            "historical": {"what_to_show": "TRADES", "format_date": 2},
        }
        item = ResolvedFuture("MNQZ6", 123, date(2026, 12, 18), object())
        request = FuturesChainRequest(
            symbol="MNQ",
            start="2026-10-05",
            end="2026-10-06",
            request_pause_seconds=0,
        )
        with patch(
            "DataManager.Downloaders.ibkr_futures_chain_downloader.time.sleep"
        ), self.assertRaisesRegex(RuntimeError, "vacío o incompleto"):
            downloader._fetch_intraday_chunk(
                item,
                pd.Timestamp("2026-10-05T00:00:00Z"),
                pd.Timestamp("2026-10-06T00:00:00Z"),
                request,
            )
        self.assertEqual(downloader.base.ib.calls, 3)
        self.assertEqual(downloader.base.ib.durations, ["2 D", "2 D", "2 D"])

    def test_weekend_closure_may_be_empty(self):
        self.assertTrue(
            _is_expected_weekend_closure(
                pd.Timestamp("2026-10-03T00:00:00Z"),
                pd.Timestamp("2026-10-04T00:00:00Z"),
            )
        )
        self.assertFalse(
            _is_expected_weekend_closure(
                pd.Timestamp("2026-10-04T00:00:00Z"),
                pd.Timestamp("2026-10-05T00:00:00Z"),
            )
        )

    def test_full_weekday_rejects_two_hour_partial_response(self):
        start = pd.Timestamp("2025-09-22T00:00:00Z")
        end = pd.Timestamp("2025-09-23T00:00:00Z")
        self.assertEqual(_minimum_expected_chunk_rows(start, end, False), 600)
        self.assertEqual(_minimum_expected_chunk_rows(start, end, True), 300)
        self.assertEqual(
            _minimum_expected_chunk_rows(
                pd.Timestamp("2025-09-27T00:00:00Z"),
                pd.Timestamp("2025-09-28T00:00:00Z"),
                False,
            ),
            0,
        )

    def test_quality_audit_uses_symbol_tick(self):
        mym = pd.DataFrame(
            {
                "local_symbol": ["MYMZ6"],
                "datetime": pd.to_datetime(["2026-10-01T00:00:00Z"]),
                "open": [46000.0],
                "high": [46001.0],
                "low": [45999.0],
                "close": [46000.0],
                "volume": [5.0],
                "barCount": [2],
            }
        )
        _, summary = IBKRFuturesChainDownloader._audit_quality(mym, "MYM")
        self.assertEqual(summary["tick_size"], 1.0)
        self.assertEqual(summary["off_tick_rows"], 0)

        mym.loc[0, "close"] = 46000.25
        with self.assertRaisesRegex(RuntimeError, "tick de 1"):
            IBKRFuturesChainDownloader._audit_quality(mym, "MYM")

    def test_quality_audit_rejects_unknown_symbol(self):
        frame = pd.DataFrame()
        with self.assertRaisesRegex(ValueError, "tick auditado"):
            IBKRFuturesChainDownloader._audit_quality(frame, "UNKNOWN")

    def test_completed_chain_writes_canonical_outputs(self):
        with tempfile.TemporaryDirectory() as temporary:
            root = Path(temporary) / "data"
            settings = {
                "storage": {
                    "root": str(root),
                    "sqlite": True,
                    "csv": True,
                    "parquet": False,
                },
                "historical": {
                    "what_to_show": "TRADES",
                    "target_time_zone": "America/New_York",
                },
            }
            item = ResolvedFuture("MNQZ6", 123, date(2026, 12, 18), object())
            request = FuturesChainRequest(
                symbol="MNQ", start="2026-10-01", end="2026-10-02"
            )
            downloader = IBKRFuturesChainDownloader.__new__(
                IBKRFuturesChainDownloader
            )
            downloader.settings = settings
            downloader.log = __import__("logging").getLogger(__name__)
            downloader.unavailable_contracts = []
            downloader._resolve_contracts = lambda _request: [item]
            downloader._daily_volume = lambda _item, _request: pd.DataFrame(
                {
                    "session_date": [date(2026, 10, 1)],
                    "volume": [1000.0],
                    "local_symbol": ["MNQZ6"],
                    "con_id": [123],
                }
            )

            def fake_segment(segment, _request, _cache):
                return pd.DataFrame(
                    {
                        "datetime": pd.to_datetime(
                            ["2026-10-01T00:00:00Z", "2026-10-01T00:01:00Z"]
                        ),
                        "open": [25000.0, 25000.25],
                        "high": [25000.25, 25000.5],
                        "low": [24999.75, 25000.0],
                        "close": [25000.0, 25000.25],
                        "volume": [5.0, 8.0],
                        "average": [25000.0, 25000.25],
                        "barCount": [2, 3],
                        "con_id": [123, 123],
                        "local_symbol": ["MNQZ6", "MNQZ6"],
                    }
                )

            downloader._download_segment = fake_segment
            result = downloader.download(request)
            folder = root / "MNQ" / "1_min"
            csv_path = folder / "MNQ_CONTFUT_1_min_ALL.csv"
            metadata_path = folder / "MNQ_CONTFUT_1_min_ALL.metadata.json"
            self.assertEqual(result.rows, 2)
            self.assertTrue(csv_path.is_file())
            self.assertTrue((folder / "MNQ_CONTFUT_1_min_ALL.rolls.csv").is_file())
            metadata = json.loads(metadata_path.read_text(encoding="utf-8"))
            self.assertEqual(metadata["provider"], "IBKR_FUT_CHAIN")
            self.assertEqual(metadata["source_contracts"], ["MNQZ6"])
            self.assertTrue(metadata["cache_file"].endswith("_ALL_v2.cache.sqlite"))


if __name__ == "__main__":
    unittest.main()
