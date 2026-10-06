from __future__ import annotations

from dataclasses import dataclass, field
from pathlib import Path


@dataclass(slots=True)
class DownloadResult:
    rows: int
    first_timestamp: str
    last_timestamp: str
    files: list[Path] = field(default_factory=list)
    duplicates_removed: int = 0

    def summary(self) -> str:
        lines = [
            f"Filas: {self.rows}",
            f"Primera fecha: {self.first_timestamp}",
            f"Última fecha: {self.last_timestamp}",
            f"Duplicados eliminados: {self.duplicates_removed}",
            "Archivos:",
        ]
        lines.extend(f"  - {path}" for path in self.files)
        return "\n".join(lines)
