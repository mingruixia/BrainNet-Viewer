"""Shared MATLAB-compatible numerical palette tables, not MATLAB code."""
from functools import lru_cache
from pathlib import Path
import numpy as np

PALETTES = ["bwr", "viridis", "plasma", "inferno", "magma", "cividis", "parula",
            "jet", "turbo", "hsv", "hot", "cool", "spring", "summer", "autumn",
            "winter", "gray", "bone", "copper", "pink", "lines", "colorcube", "prism", "flag"]


@lru_cache(maxsize=1)
def _tables():
    path = Path(__file__).with_name("data") / "palettes.npz"
    with np.load(path, allow_pickle=False) as archive:
        return {name: archive[name] for name in PALETTES}


def palette(name, count=256):
    if isinstance(count, bool) or not isinstance(count, (int, np.integer)) or not 1 <= count <= 4096:
        raise ValueError("Palette size must be an integer from 1 to 4096.")
    if isinstance(name, str):
        if name not in PALETTES:
            raise ValueError(f"Unknown colormap '{name}'.")
        if count <= 256:
            start = count * (count - 1) // 2
            return _tables()[name][start:start + count].copy()
        # Larger categorical tables are resampled; exact MATLAB references cover 1–256.
        data = palette(name, 256)
    else:
        data = np.asarray(name, dtype=float)
        if (data.ndim != 2 or data.shape[1] != 3 or not 2 <= len(data) <= 4096
                or not np.isfinite(data).all() or ((data < 0) | (data > 1)).any()):
            raise ValueError("Colormap needs 2-to-4096 RGB rows in [0,1].")
    positions = np.array([1.]) if count == 1 else np.linspace(0, 1, count)
    return np.column_stack([np.interp(positions, np.linspace(0, 1, len(data)), data[:, i]) for i in range(3)])
