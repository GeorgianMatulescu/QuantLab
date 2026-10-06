from __future__ import annotations

import argparse
import asyncio
from pathlib import Path

# Compatibilidad con librerías antiguas que esperan un event loop ya creado.
# Python 3.14 dejó de crearlo de forma implícita.
try:
    asyncio.get_event_loop()
except RuntimeError:
    asyncio.set_event_loop(asyncio.new_event_loop())

from DataManager.Downloaders.ibkr_downloader import IBKRHistoricalDownloader
from DataManager.Models.requests import HistoricalRequest
from DataManager.config import load_settings


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(
        description="QuantLab Data Manager - históricos de IBKR"
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

    return parser


def main() -> None:
    args = build_parser().parse_args()
    settings = load_settings(
        Path("Config/settings.yaml"), Path("Config/settings.example.yaml")
    )
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
    main()
