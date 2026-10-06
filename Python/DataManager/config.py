from __future__ import annotations

from pathlib import Path
from typing import Any

import yaml


def load_settings(primary: Path, fallback: Path) -> dict[str, Any]:
    path = primary if primary.exists() else fallback
    if not path.exists():
        raise FileNotFoundError("No existe ningún archivo de configuración.")
    with path.open("r", encoding="utf-8") as handle:
        return yaml.safe_load(handle)
