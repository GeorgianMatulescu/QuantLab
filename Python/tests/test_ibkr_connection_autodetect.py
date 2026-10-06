from unittest.mock import patch

import DataManager.Downloaders.ibkr_downloader as downloader_module
from DataManager.Downloaders.ibkr_downloader import IBKRHistoricalDownloader


class _SilentLog:
    def info(self, *_args, **_kwargs):
        pass

    def warning(self, *_args, **_kwargs):
        pass


class _FakeIB:
    def __init__(self):
        self.connected = False
        self.port = None

    def isConnected(self):
        return self.connected

    def connect(self, _host, port, **_kwargs):
        if port != 7496:
            raise ConnectionError("puerto de prueba incorrecto")
        self.port = port
        self.connected = True

    def disconnect(self):
        self.connected = False


def test_configured_port_has_priority_and_duplicates_are_removed():
    cfg = {
        "port": 7496,
        "auto_detect": True,
        "auto_detect_ports": [4001, 4002, 7496, 7497],
    }
    assert IBKRHistoricalDownloader._connection_candidates(cfg) == [
        7496,
        4001,
        4002,
        7497,
    ]


def test_detection_can_be_disabled():
    cfg = {"port": 4002, "auto_detect": False}
    assert IBKRHistoricalDownloader._connection_candidates(cfg) == [4002]


def test_standard_port_labels():
    expected = {
        4001: ("IB Gateway", "LIVE"),
        4002: ("IB Gateway", "PAPER"),
        7496: ("TWS", "LIVE"),
        7497: ("TWS", "PAPER"),
    }
    for port, label in expected.items():
        assert IBKRHistoricalDownloader._endpoint_name(port) == label
    assert IBKRHistoricalDownloader._endpoint_name(5000) == ("IBKR", "CUSTOM")


def test_connect_falls_back_from_gateway_to_tws():
    settings = {
        "ibkr": {
            "host": "127.0.0.1",
            "port": 4001,
            "client_id": 12,
            "auto_detect": True,
        }
    }
    downloader = IBKRHistoricalDownloader.__new__(IBKRHistoricalDownloader)
    downloader.settings = settings
    downloader.ib = _FakeIB()
    downloader.log = _SilentLog()

    with patch.object(downloader_module, "IB", _FakeIB):
        downloader.connect()

    assert downloader.ib.isConnected()
    assert settings["ibkr"]["port"] == 7496
    assert settings["ibkr"]["detected_application"] == "TWS"
    assert settings["ibkr"]["detected_environment"] == "LIVE"


if __name__ == "__main__":
    test_configured_port_has_priority_and_duplicates_are_removed()
    test_detection_can_be_disabled()
    test_standard_port_labels()
    test_connect_falls_back_from_gateway_to_tws()
    print("TEST IBKR CONNECTION AUTODETECT SUPERADO")
