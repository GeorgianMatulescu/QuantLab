from __future__ import annotations

import logging
import os
from pathlib import Path
from typing import Any

import pandas as pd

from DataManager.Database.writer import DatabaseWriter
from DataManager.Models.requests import DatabentoRequest, HistoricalRequest
from DataManager.Models.results import DownloadResult
from DataManager.Validators.market_data import validate_bars


ROLL_RULE_NAMES = {
    "c": "calendar",
    "n": "previous_day_open_interest",
    "v": "previous_day_volume",
}


class DatabentoHistoricalDownloader:
    """Descarga OHLCV de Databento con coste acotado y roll auditable."""

    def __init__(self, settings: dict[str, Any], client: Any | None = None) -> None:
        self.settings = settings
        self._client = client
        self.log = logging.getLogger(__name__)

    def _client_or_create(self) -> Any:
        if self._client is not None:
            return self._client
        if not os.environ.get("DATABENTO_API_KEY"):
            raise RuntimeError(
                "Falta DATABENTO_API_KEY. Configúrala como variable de entorno; "
                "no la escribas en settings.yaml ni la compartas."
            )
        try:
            import databento as db
        except ImportError as exc:
            raise RuntimeError(
                "Falta la librería databento. Ejecuta "
                "scripts\\windows\\01_instalar_dependencias.bat."
            ) from exc
        self._client = db.Historical()
        return self._client

    @staticmethod
    def _params(request: DatabentoRequest) -> dict[str, Any]:
        if request.roll_rule not in ROLL_RULE_NAMES:
            raise ValueError("roll_rule debe ser c, n o v.")
        if request.rank < 0:
            raise ValueError("rank no puede ser negativo.")
        if pd.Timestamp(request.end) <= pd.Timestamp(request.start):
            raise ValueError("La fecha final debe ser posterior a la inicial.")
        return {
            "dataset": request.dataset,
            "schema": request.schema,
            "symbols": request.continuous_symbol,
            "stype_in": "continuous",
            "start": request.start,
            "end": request.end,
        }

    def estimate_cost(self, request: DatabentoRequest) -> float:
        client = self._client_or_create()
        cost = float(client.metadata.get_cost(**self._params(request)))
        self.log.info(
            "Estimación Databento: %s | %s -> %s | USD %.4f",
            request.continuous_symbol,
            request.start,
            request.end,
            cost,
        )
        return cost

    @staticmethod
    def _result_dict(result: Any) -> dict[str, Any]:
        if isinstance(result, dict):
            return result
        if hasattr(result, "model_dump"):
            return result.model_dump()
        if hasattr(result, "dict"):
            return result.dict()
        raise TypeError("Respuesta de simbología no reconocida.")

    def _resolve_raw_symbols(
        self, request: DatabentoRequest, instrument_ids: list[int]
    ) -> list[dict[str, Any]]:
        if not instrument_ids:
            return []
        client = self._client_or_create()
        response = client.symbology.resolve(
            dataset=request.dataset,
            symbols=[str(value) for value in instrument_ids],
            stype_in="instrument_id",
            stype_out="raw_symbol",
            start_date=request.start[:10],
            end_date=request.end[:10],
        )
        payload = self._result_dict(response)
        intervals: list[dict[str, Any]] = []
        for instrument_id, entries in payload.get("result", {}).items():
            for entry in entries:
                intervals.append(
                    {
                        "instrument_id": int(instrument_id),
                        "start": pd.to_datetime(entry["d0"], utc=True),
                        "end": pd.to_datetime(entry["d1"], utc=True),
                        "local_symbol": str(entry["s"]),
                    }
                )
        return intervals

    @staticmethod
    def _attach_raw_symbols(
        frame: pd.DataFrame, intervals: list[dict[str, Any]]
    ) -> pd.DataFrame:
        frame = frame.copy()
        frame["local_symbol"] = ""
        for interval in intervals:
            mask = (
                (frame["instrument_id"] == interval["instrument_id"])
                & (frame["datetime"] >= interval["start"])
                & (frame["datetime"] < interval["end"])
            )
            frame.loc[mask, "local_symbol"] = interval["local_symbol"]
        return frame

    def _normalise_frame(
        self, data: Any, request: DatabentoRequest
    ) -> pd.DataFrame:
        frame = data.to_df()
        if frame is None or frame.empty:
            raise RuntimeError("Databento no devolvió barras.")

        if "ts_event" not in frame.columns:
            frame = frame.reset_index()
        if "ts_event" not in frame.columns and "index" in frame.columns:
            frame = frame.rename(columns={"index": "ts_event"})
        if "ts_event" not in frame.columns:
            raise RuntimeError("La respuesta no contiene ts_event.")

        frame = frame.rename(columns={"ts_event": "datetime"})
        frame["datetime"] = pd.to_datetime(frame["datetime"], utc=True)
        if "instrument_id" not in frame.columns:
            raise RuntimeError("La respuesta no contiene instrument_id.")
        frame["instrument_id"] = pd.to_numeric(
            frame["instrument_id"], errors="raise"
        ).astype("int64")

        ids = sorted(int(value) for value in frame["instrument_id"].unique())
        intervals = self._resolve_raw_symbols(request, ids)
        frame = self._attach_raw_symbols(frame, intervals)

        target_time_zone = self.settings["historical"].get(
            "target_time_zone", "America/New_York"
        )
        frame["datetime_new_york"] = frame["datetime"].dt.tz_convert(
            target_time_zone
        )
        frame["session_date_new_york"] = frame["datetime_new_york"].dt.strftime(
            "%Y-%m-%d"
        )
        frame["time_new_york"] = frame["datetime_new_york"].dt.strftime(
            "%H:%M:%S"
        )
        frame["symbol"] = request.symbol
        frame["continuous_symbol"] = request.continuous_symbol
        frame["con_id"] = frame["instrument_id"]
        frame["sec_type"] = "CONTFUT"
        frame["exchange"] = request.exchange
        frame["bar_size"] = request.bar_size
        frame["use_rth"] = 0
        return frame

    def download(
        self, request: DatabentoRequest, max_cost_usd: float
    ) -> DownloadResult:
        if max_cost_usd <= 0:
            raise ValueError("--max-cost-usd debe ser mayor que cero.")
        cost = self.estimate_cost(request)
        if cost > max_cost_usd:
            raise RuntimeError(
                f"Descarga cancelada antes de generar cargos: estimación USD {cost:.4f} "
                f"> límite autorizado USD {max_cost_usd:.4f}."
            )

        self.log.info(
            "Descargando %s (estimación USD %.4f; límite USD %.4f)...",
            request.continuous_symbol,
            cost,
            max_cost_usd,
        )
        data = self._client_or_create().timeseries.get_range(
            **self._params(request)
        )
        frame = self._normalise_frame(data, request)
        frame, validation = validate_bars(frame)
        if frame.empty:
            raise RuntimeError("No quedan barras después de la validación.")

        roll_segments = frame["instrument_id"].ne(
            frame["instrument_id"].shift()
        ).cumsum()
        roll_audit = (
            frame.assign(_roll_segment=roll_segments)
            .groupby("_roll_segment", sort=True)
            .agg(
                instrument_id=("instrument_id", "first"),
                local_symbol=("local_symbol", "first"),
                first_timestamp_utc=("datetime", "min"),
                last_timestamp_utc=("datetime", "max"),
                bars=("datetime", "size"),
            )
            .reset_index(drop=True)
        )
        unresolved_contract_rows = int(frame["local_symbol"].eq("").sum())
        roll_filename = f"{request.symbol}_CONTFUT_1_min_ALL.rolls.csv"

        output_request = HistoricalRequest(
            symbol=request.symbol,
            sec_type="CONTFUT",
            exchange=request.exchange,
            currency=request.currency,
            bar_size=request.bar_size,
            duration=f"{request.start}/{request.end}",
            use_rth=False,
        )
        writer = DatabaseWriter(self.settings)
        files = writer.write(
            frame,
            output_request,
            validation=validation,
            provider="DATABENTO",
            extra_metadata={
                "dataset": request.dataset,
                "schema": request.schema,
                "continuous_symbol": request.continuous_symbol,
                "roll_rule": ROLL_RULE_NAMES[request.roll_rule],
                "rank": request.rank,
                "price_adjustment": "none_original_exchange_prices",
                "requested_start_utc": request.start,
                "requested_end_utc_exclusive": request.end,
                "estimated_cost_usd": round(cost, 6),
                "authorized_max_cost_usd": round(max_cost_usd, 6),
                "raw_contract_column": "local_symbol",
                "instrument_id_column": "instrument_id",
                "roll_transitions": max(len(roll_audit) - 1, 0),
                "unresolved_contract_rows": unresolved_contract_rows,
                "roll_segments_file": roll_filename,
            },
        )
        storage_root = Path(self.settings["storage"]["root"])
        roll_path = (
            storage_root
            / request.symbol
            / request.bar_size.replace(" ", "_")
            / roll_filename
        )
        roll_audit.to_csv(roll_path, index=False)
        files.append(roll_path)
        if unresolved_contract_rows:
            self.log.warning(
                "%s barras no pudieron asociarse a un raw symbol; "
                "se conservan con instrument_id para auditoría.",
                unresolved_contract_rows,
            )
        self.log.info(
            "Descarga terminada: %s barras | %s -> %s",
            len(frame),
            frame["datetime"].min(),
            frame["datetime"].max(),
        )
        return DownloadResult(
            rows=len(frame),
            first_timestamp=str(frame["datetime"].min()),
            last_timestamp=str(frame["datetime"].max()),
            files=files,
            duplicates_removed=validation["duplicates_removed"],
        )
