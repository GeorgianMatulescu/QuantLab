from __future__ import annotations

import logging
from pathlib import Path
from typing import Any

import pandas as pd
from ib_insync import ContFuture, Forex, Future, IB, Stock, util

from DataManager.Database.writer import DatabaseWriter
from DataManager.Models.requests import HistoricalRequest
from DataManager.Models.results import DownloadResult
from DataManager.Validators.market_data import validate_bars


class IBKRHistoricalDownloader:
    """Descarga barras históricas desde TWS o IB Gateway."""

    STANDARD_ENDPOINTS = {
        4001: ("IB Gateway", "LIVE"),
        4002: ("IB Gateway", "PAPER"),
        7496: ("TWS", "LIVE"),
        7497: ("TWS", "PAPER"),
    }

    def __init__(self, settings: dict[str, Any]) -> None:
        self.settings = settings
        self.ib = IB()
        self._configure_logging()

    def _configure_logging(self) -> None:
        folder = Path(self.settings["logging"]["folder"])
        folder.mkdir(parents=True, exist_ok=True)
        level_name = str(self.settings["logging"].get("level", "INFO")).upper()
        logging.basicConfig(
            level=getattr(logging, level_name, logging.INFO),
            format="%(asctime)s | %(levelname)s | %(message)s",
            handlers=[
                logging.FileHandler(folder / "quantlab.log", encoding="utf-8"),
                logging.StreamHandler(),
            ],
            force=True,
        )
        self.log = logging.getLogger(__name__)

    @classmethod
    def _connection_candidates(cls, cfg: dict[str, Any]) -> list[int]:
        """Devuelve puertos únicos, conservando primero el configurado."""
        configured_port = int(cfg["port"])
        if not bool(cfg.get("auto_detect", True)):
            return [configured_port]

        configured_candidates = cfg.get(
            "auto_detect_ports", [4001, 4002, 7496, 7497]
        )
        ordered = [configured_port, *[int(port) for port in configured_candidates]]
        return list(dict.fromkeys(ordered))

    @classmethod
    def _endpoint_name(cls, port: int) -> tuple[str, str]:
        return cls.STANDARD_ENDPOINTS.get(port, ("IBKR", "CUSTOM"))

    def connect(self) -> None:
        if self.ib.isConnected():
            return
        cfg = self.settings["ibkr"]
        host = str(cfg["host"])
        client_id = int(cfg["client_id"])
        connect_timeout = float(cfg.get("connect_timeout_seconds", 20))
        candidates = self._connection_candidates(cfg)
        attempts: list[str] = []

        self.log.info(
            "Buscando API de IBKR en %s; puertos candidatos: %s",
            host,
            ", ".join(str(port) for port in candidates),
        )

        for port in candidates:
            application, environment = self._endpoint_name(port)
            self.log.info(
                "Probando %s %s en %s:%s (clientId=%s)...",
                application,
                environment,
                host,
                port,
                client_id,
            )
            candidate = IB()
            try:
                candidate.connect(
                    host,
                    port,
                    clientId=client_id,
                    timeout=connect_timeout,
                    readonly=True,
                )
                if not candidate.isConnected():
                    raise ConnectionError("la API no confirmó la conexión")
            except Exception as exc:
                if candidate.isConnected():
                    candidate.disconnect()
                attempts.append(f"{port}={type(exc).__name__}")
                self.log.warning(
                    "No se pudo completar la conexión IBKR en el puerto %s: %s",
                    port,
                    exc,
                )
                continue

            self.ib = candidate
            cfg["port"] = port
            cfg["detected_application"] = application
            cfg["detected_environment"] = environment
            self.log.info(
                "API detectada: %s %s en %s:%s (clientId=%s).",
                application,
                environment,
                host,
                port,
                client_id,
            )
            return

        detail = "; ".join(attempts) if attempts else "sin intentos"
        raise ConnectionError(
            "No se encontró una API de IBKR disponible. Abre IB Gateway o TWS, "
            "habilita 'Enable ActiveX and Socket Clients' y revisa los puertos. "
            f"Diagnóstico: {detail}."
        )

    def _build_contract(self, request: HistoricalRequest):
        sec_type = request.sec_type.upper()
        if sec_type == "CONTFUT":
            return ContFuture(request.symbol, request.exchange, request.currency)
        if sec_type == "FUT":
            if request.local_symbol:
                return Future(
                    localSymbol=request.local_symbol,
                    exchange=request.exchange,
                    currency=request.currency,
                    includeExpired=True,
                )
            if not request.expiry:
                raise ValueError("Para secType=FUT debes indicar --expiry o --local-symbol.")
            return Future(
                symbol=request.symbol,
                lastTradeDateOrContractMonth=request.expiry,
                exchange=request.exchange,
                currency=request.currency,
                includeExpired=True,
            )
        if sec_type == "STK":
            return Stock(request.symbol, request.exchange, request.currency)
        if sec_type == "CASH":
            return Forex(request.symbol)
        raise ValueError(f"secType no soportado: {request.sec_type}")

    def resolve(self, request: HistoricalRequest):
        self.connect()
        contract = self._build_contract(request)
        self.log.info(
            "Resolviendo contrato %s / %s / %s...",
            request.symbol,
            request.sec_type.upper(),
            request.exchange,
        )
        details = self.ib.reqContractDetails(contract)
        if not details:
            raise RuntimeError(
                f"IBKR no pudo resolver {request.symbol}/{request.sec_type}."
            )
        resolved = details[0].contract
        detail = details[0]
        self.log.info(
            "Contrato resuelto: conId=%s, symbol=%s, localSymbol=%s, "
            "secType=%s, exchange=%s, currency=%s, zona=%s",
            resolved.conId,
            resolved.symbol,
            resolved.localSymbol,
            resolved.secType,
            resolved.exchange,
            resolved.currency,
            getattr(detail, "timeZoneId", ""),
        )
        return resolved

    @staticmethod
    def _format_head_timestamp(timestamp: Any) -> str:
        """Convierte HeadTimestamp a texto y detecta respuestas vacías."""
        if timestamp is None:
            return ""
        try:
            converted = pd.to_datetime(timestamp, utc=True)
        except Exception:
            return ""
        if isinstance(converted, pd.DatetimeIndex):
            if converted.empty:
                return ""
            converted = converted[0]
        if pd.isna(converted):
            return ""
        return str(converted)

    def head_timestamp(self, request: HistoricalRequest) -> str:
        contract = self.resolve(request)
        historical_cfg = self.settings["historical"]
        timestamp = self.ib.reqHeadTimeStamp(
            contract,
            whatToShow=historical_cfg.get("what_to_show", "TRADES"),
            useRTH=request.use_rth,
            formatDate=int(historical_cfg.get("format_date", 2)),
        )
        result = self._format_head_timestamp(timestamp)
        if not result:
            raise RuntimeError(
                "IBKR no devolvió una fecha válida en reqHeadTimeStamp. "
                "La granja HMDS puede estar desconectada o la petición haber expirado."
            )
        self.log.info("Primera fecha histórica indicada por IBKR: %s", result)
        return result

    def download(self, request: HistoricalRequest) -> DownloadResult:
        self._validate_historical_request(request)
        contract = self.resolve(request)
        historical_cfg = self.settings["historical"]
        head_timestamp = ""

        # HeadTimestamp es opcional y no debe bloquear la descarga real.
        if bool(historical_cfg.get("query_head_before_download", False)):
            try:
                timestamp = self.ib.reqHeadTimeStamp(
                    contract,
                    whatToShow=historical_cfg.get("what_to_show", "TRADES"),
                    useRTH=request.use_rth,
                    formatDate=int(historical_cfg.get("format_date", 2)),
                )
                head_timestamp = self._format_head_timestamp(timestamp)
                if head_timestamp:
                    self.log.info(
                        "Primera fecha histórica indicada por IBKR: %s",
                        head_timestamp,
                    )
                else:
                    self.log.warning(
                        "HeadTimestamp devolvió una respuesta vacía; se continúa sin ella."
                    )
            except Exception as exc:
                self.log.warning("No se pudo consultar HeadTimestamp: %s", exc)
        else:
            self.log.info(
                "HeadTimestamp omitido para evitar que bloquee o retrase la descarga."
            )

        end_datetime = request.end_datetime
        if end_datetime:
            self.log.info("La petición finalizará en: %s", end_datetime)
        else:
            self.log.info("endDateTime vacío: la petición finalizará en el momento actual.")

        request_timeout = float(
            self.settings["ibkr"].get("historical_timeout_seconds", 45)
        )
        self.log.info(
            "Solicitando histórico: símbolo=%s, secType=%s, duración=%s, "
            "barra=%s, whatToShow=%s, RTH=%s, timeout=%.0f s",
            request.symbol,
            request.sec_type.upper(),
            request.duration,
            request.bar_size,
            historical_cfg.get("what_to_show", "TRADES"),
            int(request.use_rth),
            request_timeout,
        )

        bars = self.ib.reqHistoricalData(
            contract,
            endDateTime=end_datetime,
            durationStr=request.duration,
            barSizeSetting=request.bar_size,
            whatToShow=historical_cfg.get("what_to_show", "TRADES"),
            useRTH=request.use_rth,
            formatDate=int(historical_cfg.get("format_date", 2)),
            keepUpToDate=False,
            timeout=request_timeout,
        )

        if not bars:
            raise RuntimeError(
                "IBKR no devolvió barras y la petición fue cancelada al alcanzar "
                f"el timeout de {request_timeout:.0f} segundos. Revisa los mensajes "
                "2105/2106, la conexión de Gateway y los permisos de mercado."
            )

        frame = util.df(bars)
        if frame is None or frame.empty:
            raise RuntimeError("La respuesta histórica está vacía.")

        frame = frame.rename(columns={"date": "datetime"})
        frame["datetime"] = pd.to_datetime(frame["datetime"], utc=True)

        target_time_zone = historical_cfg.get(
            "target_time_zone", "America/New_York"
        )
        frame["datetime_new_york"] = frame["datetime"].dt.tz_convert(
            target_time_zone
        )
        frame["session_date_new_york"] = frame["datetime_new_york"].dt.strftime(
            "%Y-%m-%d"
        )
        frame["time_new_york"] = frame["datetime_new_york"].dt.strftime("%H:%M:%S")

        frame["symbol"] = request.symbol
        frame["local_symbol"] = getattr(contract, "localSymbol", "")
        frame["con_id"] = getattr(contract, "conId", 0)
        frame["sec_type"] = request.sec_type.upper()
        frame["exchange"] = request.exchange
        frame["bar_size"] = request.bar_size
        frame["use_rth"] = int(request.use_rth)

        if request.start_filter:
            start = pd.to_datetime(request.start_filter, utc=True)
            frame = frame[frame["datetime"] >= start]
        if request.end_filter:
            end = pd.to_datetime(request.end_filter, utc=True)
            frame = frame[frame["datetime"] <= end]

        frame, validation = validate_bars(frame)
        if frame.empty:
            raise RuntimeError(
                "No quedan barras después de aplicar filtros y validación."
            )

        writer = DatabaseWriter(self.settings)
        files = writer.write(
            frame,
            request,
            validation=validation,
            head_timestamp=head_timestamp,
        )

        self.log.info(
            "Descarga terminada: %s barras | %s -> %s",
            len(frame),
            frame["datetime"].min(),
            frame["datetime"].max(),
        )
        for path in files:
            self.log.info("Archivo creado: %s", path)

        return DownloadResult(
            rows=len(frame),
            first_timestamp=str(frame["datetime"].min()),
            last_timestamp=str(frame["datetime"].max()),
            files=files,
            duplicates_removed=validation["duplicates_removed"],
        )

    @staticmethod
    def _validate_historical_request(request: HistoricalRequest) -> None:
        """Evita peticiones que IBKR no admite y que parecen quedarse colgadas."""
        duration_parts = request.duration.strip().upper().split()
        if len(duration_parts) != 2:
            return
        try:
            amount = int(duration_parts[0])
        except ValueError:
            return
        unit = duration_parts[1]
        is_longer_than_day = unit in {"W", "M", "Y"} or (
            unit == "D" and amount > 1
        )
        if request.bar_size.strip().lower() == "1 min" and is_longer_than_day:
            raise ValueError(
                "IBKR no admite una petición única de barras de 1 minuto con "
                f"duración {request.duration}. Para construir el histórico usa "
                "ibkr-chain-download; no aumentes el timeout."
            )
        if request.sec_type.upper() == "CONTFUT" and request.end_datetime:
            raise ValueError(
                "IBKR exige endDateTime vacío para CONTFUT; por eso no se puede "
                "paginar hacia atrás un contrato continuo."
            )

    def disconnect(self) -> None:
        if self.ib.isConnected():
            self.ib.disconnect()
            self.log.info("Conexión cerrada.")
