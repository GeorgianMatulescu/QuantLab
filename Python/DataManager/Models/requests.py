from __future__ import annotations

from dataclasses import dataclass


@dataclass(slots=True)
class HistoricalRequest:
    symbol: str
    sec_type: str
    exchange: str
    currency: str = "USD"
    expiry: str = ""
    local_symbol: str = ""
    bar_size: str = "1 min"
    duration: str = "1 Y"
    end_datetime: str = ""
    use_rth: bool = False
    start_filter: str = ""
    end_filter: str = ""


@dataclass(slots=True)
class DatabentoRequest:
    """Petición reproducible de barras de un futuro continuo."""

    symbol: str
    start: str
    end: str
    roll_rule: str = "v"
    rank: int = 0
    dataset: str = "GLBX.MDP3"
    schema: str = "ohlcv-1m"
    exchange: str = "CME"
    currency: str = "USD"
    bar_size: str = "1 min"

    @property
    def continuous_symbol(self) -> str:
        return f"{self.symbol}.{self.roll_rule}.{self.rank}"


@dataclass(slots=True)
class FuturesChainRequest:
    """Petición reproducible de una cadena trimestral descargada desde IBKR."""

    symbol: str
    start: str
    end: str
    exchange: str = "CME"
    currency: str = "USD"
    bar_size: str = "1 min"
    use_rth: bool = False
    roll_lookback_days: int = 45
    request_pause_seconds: float = 2.1

    @property
    def session_name(self) -> str:
        return "RTH" if self.use_rth else "ALL"
