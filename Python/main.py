from __future__ import annotations

import argparse
import asyncio
from datetime import date, datetime, timezone
import logging
from pathlib import Path

# Compatibilidad con librerías antiguas que esperan un event loop ya creado.
# Python 3.14 dejó de crearlo de forma implícita.
try:
    asyncio.get_running_loop()
except RuntimeError:
    asyncio.set_event_loop(asyncio.new_event_loop())

from DataManager.Downloaders.databento_downloader import DatabentoHistoricalDownloader
from DataManager.Downloaders.ibkr_futures_chain_downloader import (
    IBKRFuturesChainDownloader,
)
from DataManager.Downloaders.ibkr_downloader import IBKRHistoricalDownloader
from DataManager.Models.requests import (
    DatabentoRequest,
    FuturesChainRequest,
    HistoricalRequest,
)
from DataManager.config import load_settings


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(
        description="QuantLab Data Manager - históricos de IBKR y Databento"
    )
    sub = parser.add_subparsers(dest="command", required=True)

    common = argparse.ArgumentParser(add_help=False)
    common.add_argument("--symbol", required=True)
    common.add_argument(
        "--sec-type",
        default="CONTFUT",
        choices=["CONTFUT", "FUT", "STK", "CASH"],
    )
    common.add_argument("--exchange", required=True)
    common.add_argument("--currency", default="USD")
    common.add_argument("--expiry", default="")
    common.add_argument("--local-symbol", default="")
    common.add_argument(
        "--use-rth",
        action="store_true",
        help="Solicita solamente Regular Trading Hours.",
    )

    sub.add_parser("info", parents=[common], help="Resuelve el contrato")
    sub.add_parser(
        "head", parents=[common], help="Consulta la primera fecha disponible"
    )

    download = sub.add_parser("download", parents=[common], help="Descarga histórico")
    download.add_argument("--bar-size", default="1 min")
    download.add_argument("--duration", default="1 Y")
    download.add_argument("--end", default="")
    download.add_argument("--start-filter", default="")
    download.add_argument("--end-filter", default="")

    def add_databento_arguments(command: argparse.ArgumentParser) -> None:
        command.add_argument("--symbol", default="MNQ")
        command.add_argument("--start", default="")
        command.add_argument("--end", default="")
        command.add_argument(
            "--years",
            type=int,
            default=4,
            help="Años completos hasta hoy; se ignora si se indican start/end.",
        )
        command.add_argument("--roll-rule", choices=["v", "n", "c"], default=None)
        command.add_argument("--rank", type=int, default=None)

    estimate = sub.add_parser(
        "databento-estimate",
        help="Estima el coste sin descargar ni generar cargos de datos.",
    )
    add_databento_arguments(estimate)

    db_download = sub.add_parser(
        "databento-download",
        help="Descarga MNQ continuo con un límite de coste explícito.",
    )
    add_databento_arguments(db_download)
    db_download.add_argument("--max-cost-usd", type=float, required=True)

    chain = sub.add_parser(
        "ibkr-chain-download",
        help=(
            "Descarga contratos trimestrales de futuros y construye "
            "un continuo auditable."
        ),
    )
    chain.add_argument("--symbol", default="MNQ")
    chain.add_argument("--exchange", default="CME")
    chain.add_argument("--currency", default="USD")
    chain.add_argument("--start", default="")
    chain.add_argument("--end", default="")
    chain.add_argument("--years", type=int, default=2)
    chain.add_argument("--roll-lookback-days", type=int, default=45)
    chain.add_argument("--request-pause-seconds", type=float, default=2.1)
    chain.add_argument("--use-rth", action="store_true")

    return parser


def _subtract_years(value: date, years: int) -> date:
    try:
        return value.replace(year=value.year - years)
    except ValueError:
        return value.replace(year=value.year - years, day=28)


def _databento_dates(args: argparse.Namespace) -> tuple[str, str]:
    if bool(args.start) != bool(args.end):
        raise ValueError("Indica --start y --end juntos, o ninguno.")
    if args.start and args.end:
        start = date.fromisoformat(args.start)
        end = date.fromisoformat(args.end)
    else:
        if args.years <= 0:
            raise ValueError("--years debe ser mayor que cero.")
        end = datetime.now(timezone.utc).date()
        start = _subtract_years(end, args.years)
    if end <= start:
        raise ValueError("La fecha final debe ser posterior a la inicial.")
    return start.isoformat(), end.isoformat()


def _configure_logging(settings: dict) -> None:
    folder = Path(settings["logging"]["folder"])
    folder.mkdir(parents=True, exist_ok=True)
    logging.basicConfig(
        level=getattr(
            logging,
            str(settings["logging"].get("level", "INFO")).upper(),
            logging.INFO,
        ),
        format="%(asctime)s | %(levelname)s | %(message)s",
        handlers=[
            logging.FileHandler(folder / "quantlab.log", encoding="utf-8"),
            logging.StreamHandler(),
        ],
        force=True,
    )


def main() -> None:
    args = build_parser().parse_args()
    settings = load_settings(
        Path("Config/settings.yaml"), Path("Config/settings.example.yaml")
    )

    if args.command.startswith("databento-"):
        _configure_logging(settings)
        start, end = _databento_dates(args)
        cfg = settings.get("databento", {})
        request = DatabentoRequest(
            symbol=args.symbol,
            start=start,
            end=end,
            roll_rule=args.roll_rule or str(cfg.get("roll_rule", "v")),
            rank=args.rank if args.rank is not None else int(cfg.get("rank", 0)),
            dataset=str(cfg.get("dataset", "GLBX.MDP3")),
            schema=str(cfg.get("schema", "ohlcv-1m")),
        )
        downloader = DatabentoHistoricalDownloader(settings)
        if args.command == "databento-estimate":
            cost = downloader.estimate_cost(request)
            print(
                f"Símbolo continuo: {request.continuous_symbol}\n"
                f"Periodo UTC: {request.start} -> {request.end} (fin exclusivo)\n"
                f"Coste estimado: USD {cost:.4f}\n"
                "Estimación solamente: no se descargaron datos."
            )
        else:
            print(downloader.download(request, args.max_cost_usd).summary())
        return

    if args.command == "ibkr-chain-download":
        _configure_logging(settings)
        start, end = _databento_dates(args)
        request = FuturesChainRequest(
            symbol=args.symbol,
            start=start,
            end=end,
            exchange=args.exchange,
            currency=args.currency,
            use_rth=args.use_rth,
            roll_lookback_days=args.roll_lookback_days,
            request_pause_seconds=args.request_pause_seconds,
        )
        downloader = IBKRFuturesChainDownloader(settings)
        try:
            print(downloader.download(request).summary())
        finally:
            downloader.disconnect()
        return

    downloader = IBKRHistoricalDownloader(settings)

    request = HistoricalRequest(
        symbol=args.symbol,
        sec_type=args.sec_type,
        exchange=args.exchange,
        currency=args.currency,
        expiry=args.expiry,
        local_symbol=args.local_symbol,
        bar_size=getattr(args, "bar_size", "1 min"),
        duration=getattr(args, "duration", "1 Y"),
        end_datetime=getattr(args, "end", ""),
        use_rth=args.use_rth,
        start_filter=getattr(args, "start_filter", ""),
        end_filter=getattr(args, "end_filter", ""),
    )

    try:
        if args.command == "info":
            print(downloader.resolve(request))
        elif args.command == "head":
            print(downloader.head_timestamp(request))
        elif args.command == "download":
            print(downloader.download(request).summary())
    finally:
        downloader.disconnect()


if __name__ == "__main__":
    try:
        main()
    except (ConnectionError, RuntimeError, ValueError) as exc:
        raise SystemExit(f"ERROR: {exc}") from None
