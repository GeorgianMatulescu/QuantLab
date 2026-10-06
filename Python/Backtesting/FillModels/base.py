from __future__ import annotations


class FillModel:
    """Base para fills ideal, conservador y basado en ticks."""

    def fill(self, order, market_data):
        raise NotImplementedError
