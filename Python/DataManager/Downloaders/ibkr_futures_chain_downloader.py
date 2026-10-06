from __future__ import annotations

import calendar
from dataclasses import dataclass
from datetime import date, datetime, time as datetime_time, timedelta, timezone
import logging
from pathlib import Path
import sqlite3
import time
from typing import Any
from zoneinfo import ZoneInfo

import pandas as pd
from ib_insync import util

from DataManager.Database.writer import DatabaseWriter
from DataManager.Downloaders.ibkr_downloader import IBKRHistoricalDownloader
from DataManager.Models.requests import FuturesChainRequest, HistoricalRequest
from DataManager.Models.results import DownloadResult
from DataManager.Validators.market_data import validate_bars


QUARTER_CODES = {3: "H", 6: "M", 9: "U", 12: "Z"}
PRICE_COLUMNS = ["open", "high", "low", "close"]
FUTURES_TICK_SIZES = {
    "ES": 0.25,
    "MES": 0.25,
    "NQ": 0.25,
    "MNQ": 0.25,
    "YM": 1.0,
    "MYM": 1.0,
}
CACHE_BAR_COLUMNS = [
    "local_symbol",
    "datetime",
    "open",
    "high",
    "low",
    "close",
    "volume",
    "average",
    "barCount",
    "con_id",
]


@dataclass(frozen=True, slots=True)
class ResolvedFuture:
    local_symbol: str
    con_id: int
    expiry: date
    contract: Any


@dataclass(frozen=True, slots=True)
class RollDecision:
    outgoing: str
    incoming: str
    trigger_session: date
    effective_session: date
    boundary_utc: pd.Timestamp
    outgoing_volume: float
    incoming_volume: float


@dataclass(frozen=True, slots=True)
class ContractSegment:
    number: int
    contract: ResolvedFuture
    start_utc: pd.Timestamp
    end_utc: pd.Timestamp
    roll_out: RollDecision | None


def quarterly_local_symbols(symbol: str, start: date, end: date) -> list[str]:
    """Devuelve los vencimientos trimestrales que pueden ser front entre dos fechas."""
    if end <= start:
        raise ValueError("La fecha final debe ser posterior a la inicial.")

    quarter_month = next(month for month in QUARTER_CODES if month >= start.month)
    end_quarter_month = next(month for month in QUARTER_CODES if month >= end.month)
    year = start.year
    result: list[str] = []
    while (year, quarter_month) <= (end.year, end_quarter_month):
        result.append(f"{symbol}{QUARTER_CODES[quarter_month]}{year % 10}")
        quarter_month += 3
        if quarter_month > 12:
            quarter_month = 3
            year += 1
    return result


def _third_friday(year: int, month: int) -> date:
    month_calendar = calendar.monthcalendar(year, month)
    fridays = [week[calendar.FRIDAY] for week in month_calendar if week[calendar.FRIDAY]]
    return date(year, month, fridays[2])


def _parse_expiry(value: str, local_symbol: str) -> date:
    digits = "".join(character for character in str(value) if character.isdigit())
    if len(digits) >= 8:
        return datetime.strptime(digits[:8], "%Y%m%d").date()
    if len(digits) >= 6:
        return _third_friday(int(digits[:4]), int(digits[4:6]))

    code = local_symbol[-2:-1]
    year_digit = int(local_symbol[-1])
    month = {value: key for key, value in QUARTER_CODES.items()}[code]
    current_year = datetime.now(timezone.utc).year
    decade = current_year - (current_year % 10)
    year = decade + year_digit
    if year > current_year + 3:
        year -= 10
    return _third_friday(year, month)


def _globex_boundary(effective_session: date) -> pd.Timestamp:
    """Inicio de la sesión Globex etiquetada con effective_session."""
    new_york = ZoneInfo("America/New_York")
    local_start = datetime.combine(
        effective_session - timedelta(days=1),
        datetime_time(18, 0),
        tzinfo=new_york,
    )
    return pd.Timestamp(local_start.astimezone(timezone.utc))


def _is_expected_weekend_closure(
    chunk_start: pd.Timestamp, chunk_end: pd.Timestamp
) -> bool:
    """Indica si todo el bloque cae dentro del cierre semanal Globex."""
    span = chunk_end - chunk_start
    if span <= pd.Timedelta(days=1) and chunk_start.weekday() == calendar.SATURDAY:
        return True

    new_york = ZoneInfo("America/New_York")
    start_local = chunk_start.tz_convert(new_york)
    end_local = (chunk_end - pd.Timedelta(nanoseconds=1)).tz_convert(new_york)

    def is_closed(value: pd.Timestamp) -> bool:
        weekday = value.weekday()
        local_time = value.time()
        return (
            (weekday == calendar.FRIDAY and local_time >= datetime_time(17, 0))
            or weekday == calendar.SATURDAY
            or (weekday == calendar.SUNDAY and local_time < datetime_time(18, 0))
        )

    return is_closed(start_local) and is_closed(end_local)


def _minimum_expected_chunk_rows(
    chunk_start: pd.Timestamp,
    chunk_end: pd.Timestamp,
    use_rth: bool,
) -> int:
    """Umbral defensivo para no aceptar un día UTC recortado a dos horas."""
    if chunk_end - chunk_start < pd.Timedelta(hours=20):
        return 0
    if chunk_start.weekday() >= calendar.SATURDAY:
        return 0
    if (chunk_start.month, chunk_start.day) in {(1, 1), (12, 25)}:
        return 0
    return 300 if use_rth else 600


class _ChainCache:
    """Checkpoint SQLite para reanudar sin repetir días ya descargados."""

    def __init__(self, path: Path) -> None:
        self.path = path
        path.parent.mkdir(parents=True, exist_ok=True)
        with sqlite3.connect(path) as connection:
            connection.execute(
                """
                CREATE TABLE IF NOT EXISTS contract_bars (
                    local_symbol TEXT NOT NULL,
                    datetime TEXT NOT NULL,
                    open REAL,
                    high REAL,
                    low REAL,
                    close REAL,
                    volume REAL,
                    average REAL,
                    barCount REAL,
                    con_id INTEGER,
                    PRIMARY KEY(local_symbol, datetime)
                )
                """
            )
            connection.execute(
                """
                CREATE TABLE IF NOT EXISTS completed_chunks (
                    local_symbol TEXT NOT NULL,
                    chunk_start TEXT NOT NULL,
                    chunk_end TEXT NOT NULL,
                    rows INTEGER NOT NULL,
                    completed_at TEXT NOT NULL,
                    PRIMARY KEY(local_symbol, chunk_start, chunk_end)
                )
                """
            )

    def is_complete(
        self, local_symbol: str, chunk_start: pd.Timestamp, chunk_end: pd.Timestamp
    ) -> bool:
        with sqlite3.connect(self.path) as connection:
            row = connection.execute(
                """
                SELECT 1 FROM completed_chunks
                WHERE local_symbol=? AND chunk_start=? AND chunk_end=?
                """,
                (local_symbol, str(chunk_start), str(chunk_end)),
            ).fetchone()
        return row is not None

    def store(
        self,
        local_symbol: str,
        chunk_start: pd.Timestamp,
        chunk_end: pd.Timestamp,
        frame: pd.DataFrame,
    ) -> None:
        values: list[tuple[Any, ...]] = []
        if not frame.empty:
            cached = frame.copy()
            for column in ["average", "barCount"]:
                if column not in cached.columns:
                    cached[column] = 0.0
            cached["local_symbol"] = local_symbol
            cached["datetime"] = cached["datetime"].astype(str)
            values = list(
                cached[CACHE_BAR_COLUMNS].itertuples(index=False, name=None)
            )

        with sqlite3.connect(self.path) as connection:
            if values:
                connection.executemany(
                    """
                    INSERT OR REPLACE INTO contract_bars (
                        local_symbol, datetime, open, high, low, close,
                        volume, average, barCount, con_id
                    ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
                    """,
                    values,
                )
            connection.execute(
                """
                INSERT OR REPLACE INTO completed_chunks (
                    local_symbol, chunk_start, chunk_end, rows, completed_at
                ) VALUES (?, ?, ?, ?, ?)
                """,
                (
                    local_symbol,
                    str(chunk_start),
                    str(chunk_end),
                    len(frame),
                    datetime.now(timezone.utc).isoformat(),
                ),
            )

    def read_segment(
        self, local_symbol: str, start_utc: pd.Timestamp, end_utc: pd.Timestamp
    ) -> pd.DataFrame:
        with sqlite3.connect(self.path) as connection:
            frame = pd.read_sql_query(
                """
                SELECT datetime, open, high, low, close, volume, average,
                       barCount, con_id, local_symbol
                FROM contract_bars
                WHERE local_symbol=? AND datetime>=? AND datetime<?
                ORDER BY datetime
                """,
                connection,
                params=(local_symbol, str(start_utc), str(end_utc)),
            )
        if not frame.empty:
            frame["datetime"] = pd.to_datetime(frame["datetime"], utc=True)
        return frame


class IBKRFuturesChainDownloader:
    """Construye un continuo auditable a partir de futuros trimestrales IBKR."""

    def __init__(self, settings: dict[str, Any]) -> None:
        self.settings = settings
        self.base = IBKRHistoricalDownloader(settings)
        self.log = logging.getLogger(__name__)
        self.unavailable_contracts: list[str] = []

    def disconnect(self) -> None:
        self.base.disconnect()

    def _resolve_contracts(self, request: FuturesChainRequest) -> list[ResolvedFuture]:
        start = date.fromisoformat(request.start)
        end = date.fromisoformat(request.end)
        local_symbols = quarterly_local_symbols(request.symbol, start, end)
        resolved_descending: list[ResolvedFuture] = []
        self.unavailable_contracts = []

        self.log.info(
            "Descubriendo contratos desde el más reciente: %s",
            " -> ".join(reversed(local_symbols)),
        )
        for index, local_symbol in enumerate(reversed(local_symbols)):
            try:
                contract = self.base.resolve(
                    HistoricalRequest(
                        symbol=request.symbol,
                        sec_type="FUT",
                        exchange=request.exchange,
                        currency=request.currency,
                        local_symbol=local_symbol,
                    )
                )
            except RuntimeError as exc:
                if not resolved_descending:
                    raise RuntimeError(
                        f"IBKR no pudo resolver ni siquiera el contrato más reciente "
                        f"{local_symbol}. Revisa permisos de {request.exchange} "
                        "y conexión."
                    ) from exc
                remaining = list(reversed(local_symbols))
                self.unavailable_contracts.extend(remaining[index:])
                self.log.warning(
                    "%s ya no está disponible en IBKR. Se detiene la búsqueda "
                    "hacia atrás y se conservarán %s contratos recientes.",
                    local_symbol,
                    len(resolved_descending),
                )
                break
            expiry = _parse_expiry(
                getattr(contract, "lastTradeDateOrContractMonth", ""),
                local_symbol,
            )
            resolved_descending.append(
                ResolvedFuture(
                    local_symbol=str(contract.localSymbol or local_symbol),
                    con_id=int(contract.conId),
                    expiry=expiry,
                    contract=contract,
                )
            )
            self.log.info(
                "Contrato: %s | conId=%s | vencimiento=%s",
                local_symbol,
                contract.conId,
                expiry,
            )
        return list(reversed(resolved_descending))

    def _load_available_daily_volume(
        self,
        contracts: list[ResolvedFuture],
        request: FuturesChainRequest,
    ) -> tuple[list[ResolvedFuture], dict[str, pd.DataFrame]]:
        """Comprueba histórico diario del más reciente al más antiguo."""
        usable_descending: list[ResolvedFuture] = []
        daily: dict[str, pd.DataFrame] = {}
        descending = list(reversed(contracts))
        for index, item in enumerate(descending):
            try:
                frame = self._daily_volume(item, request)
            except RuntimeError as exc:
                if not usable_descending:
                    raise RuntimeError(
                        f"IBKR no devolvió histórico ni para el contrato más reciente "
                        f"{item.local_symbol}."
                    ) from exc
                unavailable = [entry.local_symbol for entry in descending[index:]]
                self.unavailable_contracts.extend(
                    symbol
                    for symbol in unavailable
                    if symbol not in self.unavailable_contracts
                )
                self.log.warning(
                    "Sin histórico diario para %s. La cobertura comenzará en %s.",
                    item.local_symbol,
                    usable_descending[-1].local_symbol,
                )
                break
            usable_descending.append(item)
            daily[item.local_symbol] = frame
        return list(reversed(usable_descending)), daily

    @staticmethod
    def _effective_start_utc(
        request: FuturesChainRequest,
        contracts: list[ResolvedFuture],
        daily: dict[str, pd.DataFrame],
    ) -> pd.Timestamp:
        requested_start = pd.Timestamp(request.start, tz="UTC")
        expected_oldest = quarterly_local_symbols(
            request.symbol,
            date.fromisoformat(request.start),
            date.fromisoformat(request.end),
        )[0]
        oldest = contracts[0]
        if oldest.local_symbol == expected_oldest:
            return requested_start

        previous_month = oldest.expiry.month - 3
        previous_year = oldest.expiry.year
        if previous_month <= 0:
            previous_month += 12
            previous_year -= 1
        previous_expiry = _third_friday(previous_year, previous_month)
        later_sessions = sorted(
            value
            for value in daily[oldest.local_symbol]["session_date"].unique()
            if value > previous_expiry
        )
        if not later_sessions:
            raise RuntimeError(
                f"No se puede establecer un inicio conservador para "
                f"{oldest.local_symbol}."
            )
        conservative_start = _globex_boundary(later_sessions[0])
        return max(requested_start, conservative_start)

    def _daily_volume(
        self, item: ResolvedFuture, request: FuturesChainRequest
    ) -> pd.DataFrame:
        request_end = pd.Timestamp(request.end, tz="UTC")
        expiry_end = pd.Timestamp(item.expiry + timedelta(days=2), tz="UTC")
        end_datetime = min(request_end, expiry_end).to_pydatetime()
        historical = self.settings["historical"]
        bars = self.base.ib.reqHistoricalData(
            item.contract,
            endDateTime=end_datetime,
            durationStr="1 Y",
            barSizeSetting="1 day",
            whatToShow=historical.get("what_to_show", "TRADES"),
            useRTH=False,
            formatDate=int(historical.get("format_date", 2)),
            keepUpToDate=False,
            timeout=float(self.settings["ibkr"].get("historical_timeout_seconds", 45)),
        )
        frame = util.df(bars)
        if frame is None or frame.empty:
            raise RuntimeError(
                f"IBKR no devolvió volumen diario para {item.local_symbol}. "
                "No se puede justificar el rollover sin inventar datos."
            )
        frame = frame.rename(columns={"date": "session_date"})
        frame["session_date"] = pd.to_datetime(
            frame["session_date"], errors="coerce"
        ).dt.date
        frame["volume"] = pd.to_numeric(frame["volume"], errors="coerce")
        frame = frame.dropna(subset=["session_date", "volume"])
        frame = frame[frame["volume"] >= 0].copy()
        frame["local_symbol"] = item.local_symbol
        frame["con_id"] = item.con_id
        return frame[["session_date", "volume", "local_symbol", "con_id"]]

    def _build_segments(
        self,
        contracts: list[ResolvedFuture],
        daily: dict[str, pd.DataFrame],
        request: FuturesChainRequest,
        start_utc_override: pd.Timestamp | None = None,
    ) -> tuple[list[ContractSegment], list[RollDecision]]:
        start_utc = start_utc_override or pd.Timestamp(request.start, tz="UTC")
        end_utc = pd.Timestamp(request.end, tz="UTC")
        all_decisions: list[RollDecision] = []

        for outgoing, incoming in zip(contracts, contracts[1:]):
            old = daily[outgoing.local_symbol][["session_date", "volume"]].rename(
                columns={"volume": "outgoing_volume"}
            )
            new = daily[incoming.local_symbol][["session_date", "volume"]].rename(
                columns={"volume": "incoming_volume"}
            )
            overlap = old.merge(new, on="session_date", how="inner")
            window_start = outgoing.expiry - timedelta(
                days=request.roll_lookback_days
            )
            overlap = overlap[
                (overlap["session_date"] >= window_start)
                & (overlap["session_date"] <= outgoing.expiry)
                & (overlap["outgoing_volume"] > 0)
                & (overlap["incoming_volume"] > overlap["outgoing_volume"])
            ].sort_values("session_date")
            if overlap.empty:
                raise RuntimeError(
                    f"No existe cruce de volumen verificable {outgoing.local_symbol} -> "
                    f"{incoming.local_symbol} en los {request.roll_lookback_days} días "
                    "previos al vencimiento. La cadena no se construirá."
                )

            crossover = overlap.iloc[0]
            trigger = crossover["session_date"]
            next_sessions = sorted(
                value
                for value in daily[incoming.local_symbol]["session_date"].unique()
                if value > trigger
            )
            if not next_sessions:
                raise RuntimeError(
                    f"No hay una sesión posterior al cruce de volumen de "
                    f"{incoming.local_symbol}."
                )
            effective = next_sessions[0]
            boundary = _globex_boundary(effective)
            all_decisions.append(
                RollDecision(
                    outgoing=outgoing.local_symbol,
                    incoming=incoming.local_symbol,
                    trigger_session=trigger,
                    effective_session=effective,
                    boundary_utc=boundary,
                    outgoing_volume=float(crossover["outgoing_volume"]),
                    incoming_volume=float(crossover["incoming_volume"]),
                )
            )

        segments: list[ContractSegment] = []
        segment_start = start_utc
        contract_by_symbol = {item.local_symbol: item for item in contracts}
        active = contracts[0]
        decisions: list[RollDecision] = []
        for decision in all_decisions:
            if decision.boundary_utc <= start_utc:
                active = contract_by_symbol[decision.incoming]
                continue
            if decision.boundary_utc >= end_utc:
                break
            if active.local_symbol != decision.outgoing:
                raise RuntimeError(
                    "El plan de rollover dejó de ser monotónico: "
                    f"activo={active.local_symbol}, saliente={decision.outgoing}."
                )
            decisions.append(decision)
            segments.append(
                ContractSegment(
                    number=len(segments) + 1,
                    contract=active,
                    start_utc=segment_start,
                    end_utc=decision.boundary_utc,
                    roll_out=decision,
                )
            )
            segment_start = decision.boundary_utc
            active = contract_by_symbol[decision.incoming]
        segments.append(
            ContractSegment(
                number=len(segments) + 1,
                contract=active,
                start_utc=segment_start,
                end_utc=end_utc,
                roll_out=None,
            )
        )
        return segments, decisions

    def _fetch_intraday_chunk(
        self,
        item: ResolvedFuture,
        chunk_start: pd.Timestamp,
        chunk_end: pd.Timestamp,
        request: FuturesChainRequest,
    ) -> pd.DataFrame:
        historical = self.settings["historical"]
        timeout = float(self.settings["ibkr"].get("historical_timeout_seconds", 45))
        retries = int(self.settings["ibkr"].get("historical_retries", 3))
        last_exception: Exception | None = None
        expected_weekend_closure = _is_expected_weekend_closure(
            chunk_start, chunk_end
        )
        minimum_rows = _minimum_expected_chunk_rows(
            chunk_start, chunk_end, request.use_rth
        )
        for attempt in range(1, retries + 1):
            try:
                if not self.base.ib.isConnected():
                    self.base.connect()
                bars = self.base.ib.reqHistoricalData(
                    item.contract,
                    endDateTime=chunk_end.to_pydatetime(),
                    # IBKR interpreta 1 D como una sesión de negociación, no
                    # como las 24 horas UTC que filtramos después. Pedir 2 D
                    # garantiza que el bloque UTC quede completamente cubierto.
                    durationStr="2 D",
                    barSizeSetting=request.bar_size,
                    whatToShow=historical.get("what_to_show", "TRADES"),
                    useRTH=request.use_rth,
                    formatDate=int(historical.get("format_date", 2)),
                    keepUpToDate=False,
                    timeout=timeout,
                )
                if bars:
                    frame = util.df(bars).rename(columns={"date": "datetime"})
                    frame["datetime"] = pd.to_datetime(frame["datetime"], utc=True)
                    frame = frame[
                        (frame["datetime"] >= chunk_start)
                        & (frame["datetime"] < chunk_end)
                    ].copy()
                    if len(frame) >= minimum_rows:
                        frame["con_id"] = item.con_id
                        return frame
                elif expected_weekend_closure:
                    return pd.DataFrame(columns=["datetime", *PRICE_COLUMNS])

                self.log.warning(
                    "IBKR devolvió un bloque vacío o incompleto para %s "
                    "(%s -> %s): %s/%s barras, intento %s/%s.",
                    item.local_symbol,
                    chunk_start,
                    chunk_end,
                    0 if not bars else len(frame),
                    minimum_rows,
                    attempt,
                    retries,
                )
            except Exception as exc:
                last_exception = exc
                self.log.warning(
                    "Intento %s/%s fallido para %s (%s -> %s): %s",
                    attempt,
                    retries,
                    item.local_symbol,
                    chunk_start,
                    chunk_end,
                    exc,
                )
            if attempt < retries:
                time.sleep(
                    max(
                        request.request_pause_seconds,
                        min(30.0, 10.0 * attempt),
                    )
                )

        if last_exception is not None:
            raise RuntimeError(
                f"No se pudo descargar {item.local_symbol} entre "
                f"{chunk_start} y {chunk_end}. Vuelve a ejecutar el script para reanudar."
            ) from last_exception
        raise RuntimeError(
            f"IBKR devolvió un bloque vacío o incompleto para {item.local_symbol} "
            f"entre {chunk_start} y {chunk_end}. No se marcará como completado; "
            "vuelve a ejecutar el script para reanudar."
        )

    def _download_segment(
        self,
        segment: ContractSegment,
        request: FuturesChainRequest,
        cache: _ChainCache,
    ) -> pd.DataFrame:
        cursor = segment.start_utc
        chunks_total = 0
        chunks_downloaded = 0
        while cursor < segment.end_utc:
            next_midnight = cursor.normalize() + pd.Timedelta(days=1)
            chunk_end = min(next_midnight, segment.end_utc)
            chunks_total += 1
            if not cache.is_complete(segment.contract.local_symbol, cursor, chunk_end):
                frame = self._fetch_intraday_chunk(
                    segment.contract, cursor, chunk_end, request
                )
                cache.store(
                    segment.contract.local_symbol, cursor, chunk_end, frame
                )
                chunks_downloaded += 1
                self.log.info(
                    "%s | %s -> %s | %s barras",
                    segment.contract.local_symbol,
                    cursor,
                    chunk_end,
                    len(frame),
                )
                time.sleep(max(0.0, request.request_pause_seconds))
            cursor = chunk_end

        self.log.info(
            "%s completado: %s bloques (%s recuperados de la caché).",
            segment.contract.local_symbol,
            chunks_total,
            chunks_total - chunks_downloaded,
        )
        return cache.read_segment(
            segment.contract.local_symbol, segment.start_utc, segment.end_utc
        )

    @staticmethod
    def _audit_quality(
        frame: pd.DataFrame, symbol: str
    ) -> tuple[pd.DataFrame, dict[str, Any]]:
        normalized_symbol = symbol.strip().upper()
        try:
            tick = FUTURES_TICK_SIZES[normalized_symbol]
        except KeyError as exc:
            raise ValueError(
                f"No existe un tick auditado para {normalized_symbol}. "
                "Añádelo a FUTURES_TICK_SIZES antes de activar el dataset."
            ) from exc
        off_tick = pd.Series(False, index=frame.index)
        for column in PRICE_COLUMNS:
            scaled = pd.to_numeric(frame[column], errors="coerce") / tick
            off_tick |= (scaled - scaled.round()).abs() > 1e-6

        quality_rows: list[dict[str, Any]] = []
        for local_symbol, group in frame.groupby("local_symbol", sort=False):
            zero_volume = int((group.get("volume", 0) <= 0).sum())
            zero_bar_count = int((group.get("barCount", 0) <= 0).sum())
            group_off_tick = int(off_tick.loc[group.index].sum())
            quality_rows.append(
                {
                    "local_symbol": local_symbol,
                    "rows": len(group),
                    "first_timestamp_utc": str(group["datetime"].min()),
                    "last_timestamp_utc": str(group["datetime"].max()),
                    "zero_volume_rows": zero_volume,
                    "zero_volume_pct": round(100 * zero_volume / len(group), 6),
                    "zero_bar_count_rows": zero_bar_count,
                    "off_tick_rows": group_off_tick,
                    "quality": "COMPLETE" if group_off_tick == 0 else "NOT_EVALUABLE",
                }
            )
        report = pd.DataFrame(quality_rows)
        summary = {
            "symbol": normalized_symbol,
            "tick_size": tick,
            "off_tick_rows": int(off_tick.sum()),
            "zero_volume_rows": int((frame.get("volume", 0) <= 0).sum()),
            "zero_bar_count_rows": int((frame.get("barCount", 0) <= 0).sum()),
        }
        if summary["off_tick_rows"]:
            raise RuntimeError(
                f"Se detectaron {summary['off_tick_rows']} barras fuera del tick "
                f"de {tick:g} para {normalized_symbol}. "
                "El dataset se conserva en la caché pero no sustituirá al activo."
            )
        return report, summary

    def download(self, request: FuturesChainRequest) -> DownloadResult:
        if request.bar_size.strip().lower() != "1 min":
            raise ValueError("La cadena v0.25.32 está congelada para barras de 1 minuto.")
        if request.roll_lookback_days < 10:
            raise ValueError("--roll-lookback-days debe ser al menos 10.")

        contracts = self._resolve_contracts(request)
        if not contracts:
            raise RuntimeError("No se resolvió ningún contrato trimestral.")

        contracts, daily = self._load_available_daily_volume(contracts, request)
        if not contracts:
            raise RuntimeError("IBKR no proporcionó histórico para ningún contrato.")
        effective_start_utc = self._effective_start_utc(request, contracts, daily)
        if effective_start_utc >= pd.Timestamp(request.end, tz="UTC"):
            raise RuntimeError(
                "La cobertura disponible comienza después del final solicitado."
            )
        segments, decisions = self._build_segments(
            contracts,
            daily,
            request,
            start_utc_override=effective_start_utc,
        )

        if effective_start_utc > pd.Timestamp(request.start, tz="UTC"):
            self.log.warning(
                "COBERTURA PARCIAL: solicitado desde %s; verificable desde %s. "
                "Contratos no disponibles: %s",
                request.start,
                effective_start_utc,
                ", ".join(self.unavailable_contracts),
            )

        self.log.info("Plan contractual congelado:")
        for segment in segments:
            self.log.info(
                "  %s | %s -> %s",
                segment.contract.local_symbol,
                segment.start_utc,
                segment.end_utc,
            )

        root = Path(self.settings["storage"]["root"])
        folder = root / request.symbol / request.bar_size.replace(" ", "_")
        # ALL y RTH no pueden compartir checkpoints: una caché RTH marcada como
        # completa impediría recuperar posteriormente las barras extendidas.
        cache_path = folder / (
            f"{request.symbol}_FUT_CHAIN_1_min_"
            f"{request.session_name}_v2.cache.sqlite"
        )
        cache = _ChainCache(cache_path)

        frames: list[pd.DataFrame] = []
        for segment in segments:
            frame = self._download_segment(segment, request, cache)
            if frame.empty:
                raise RuntimeError(
                    f"El segmento {segment.contract.local_symbol} quedó vacío. "
                    "Vuelve a ejecutar el script; la descarga se reanudará."
                )
            frame["roll_segment"] = segment.number
            frames.append(frame)

        combined = pd.concat(frames, ignore_index=True)
        combined["datetime"] = pd.to_datetime(combined["datetime"], utc=True)
        combined["symbol"] = request.symbol
        combined["sec_type"] = "FUT"
        combined["exchange"] = request.exchange
        combined["bar_size"] = request.bar_size
        combined["use_rth"] = int(request.use_rth)
        target_time_zone = self.settings["historical"].get(
            "target_time_zone", "America/New_York"
        )
        combined["datetime_new_york"] = combined["datetime"].dt.tz_convert(
            target_time_zone
        )
        combined["session_date_new_york"] = combined[
            "datetime_new_york"
        ].dt.strftime("%Y-%m-%d")
        combined["time_new_york"] = combined["datetime_new_york"].dt.strftime(
            "%H:%M:%S"
        )
        combined, validation = validate_bars(combined)
        if combined.empty:
            raise RuntimeError("La cadena final no contiene barras válidas.")

        quality, quality_summary = self._audit_quality(combined, request.symbol)
        folder.mkdir(parents=True, exist_ok=True)
        stem = f"{request.symbol}_CONTFUT_1_min_{request.session_name}"
        rolls_path = folder / f"{stem}.rolls.csv"
        quality_path = folder / f"{stem}.quality.csv"
        volume_path = folder / f"{stem}.contract_volume.csv"

        roll_rows = []
        for segment in segments:
            decision = segment.roll_out
            roll_rows.append(
                {
                    "segment": segment.number,
                    "local_symbol": segment.contract.local_symbol,
                    "con_id": segment.contract.con_id,
                    "expiry": segment.contract.expiry.isoformat(),
                    "start_utc": str(segment.start_utc),
                    "end_utc_exclusive": str(segment.end_utc),
                    "roll_rule": "next_session_after_volume_crossover",
                    "roll_trigger_session": (
                        decision.trigger_session.isoformat() if decision else ""
                    ),
                    "roll_effective_session": (
                        decision.effective_session.isoformat() if decision else ""
                    ),
                    "outgoing_volume": (
                        decision.outgoing_volume if decision else ""
                    ),
                    "incoming_volume": (
                        decision.incoming_volume if decision else ""
                    ),
                }
            )
        pd.DataFrame(roll_rows).to_csv(rolls_path, index=False)
        quality.to_csv(quality_path, index=False)
        pd.concat(daily.values(), ignore_index=True).sort_values(
            ["session_date", "local_symbol"]
        ).to_csv(volume_path, index=False)

        canonical_request = HistoricalRequest(
            symbol=request.symbol,
            sec_type="CONTFUT",
            exchange=request.exchange,
            currency=request.currency,
            bar_size=request.bar_size,
            use_rth=request.use_rth,
        )
        files = DatabaseWriter(self.settings).write(
            combined,
            canonical_request,
            validation=validation,
            provider="IBKR_FUT_CHAIN",
            extra_metadata={
                "sec_type": "FUT_CHAIN",
                "source_contracts": [item.local_symbol for item in contracts],
                "roll_rule": "next_session_after_volume_crossover",
                "roll_lookback_days": request.roll_lookback_days,
                "prices_adjusted": False,
                "requested_start_utc": request.start,
                "requested_end_utc_exclusive": request.end,
                "effective_start_utc": str(effective_start_utc),
                "coverage_status": (
                    "FULL_REQUESTED"
                    if effective_start_utc == pd.Timestamp(request.start, tz="UTC")
                    else "PARTIAL_IBKR_LIMIT"
                ),
                "unavailable_contracts": self.unavailable_contracts,
                "cache_file": str(cache_path),
                "rolls_file": str(rolls_path),
                "quality_file": str(quality_path),
                "quality": quality_summary,
            },
        )
        files.extend([rolls_path, quality_path, volume_path, cache_path])
        self.log.info(
            "Cadena terminada: %s barras | %s -> %s | %s rolls",
            len(combined),
            combined["datetime"].min(),
            combined["datetime"].max(),
            len(decisions),
        )
        return DownloadResult(
            rows=len(combined),
            first_timestamp=str(combined["datetime"].min()),
            last_timestamp=str(combined["datetime"].max()),
            files=files,
            duplicates_removed=validation["duplicates_removed"],
        )
