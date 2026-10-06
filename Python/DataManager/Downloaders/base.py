from __future__ import annotations

from abc import ABC, abstractmethod

from DataManager.Models.requests import HistoricalRequest
from DataManager.Models.results import DownloadResult


class HistoricalDownloader(ABC):
    @abstractmethod
    def resolve(self, request: HistoricalRequest):
        raise NotImplementedError

    @abstractmethod
    def download(self, request: HistoricalRequest) -> DownloadResult:
        raise NotImplementedError

    @abstractmethod
    def disconnect(self) -> None:
        raise NotImplementedError
