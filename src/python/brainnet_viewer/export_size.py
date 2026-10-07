"""Renderer-independent figure size conversion and allocation limits."""
import math


def unit_scale(units, dpi):
    if units == "Pixels": return 1.
    if units == "Millimetres": return dpi / 25.4
    if units == "Centimetres": return dpi / 2.54
    if units == "Inches": return dpi
    if units == "Points": return dpi / 72.
    raise ValueError("Unknown figure size units.")


def figure_size(width, height, dpi, units="Pixels"):
    values = (width, height, dpi)
    if any(isinstance(value, bool) or not isinstance(value, (int, float)) or not math.isfinite(value) or value <= 0 for value in values):
        raise ValueError("Figure dimensions and DPI must be positive finite numbers.")
    if not 1 <= dpi <= 2400: raise ValueError("DPI must be from 1 to 2400.")
    if units == "Pixels" and (int(width) != width or int(height) != height):
        raise ValueError("Pixel dimensions must be integers.")
    scale = unit_scale(units, dpi)
    pixels = tuple(int(math.floor(value * scale + .5)) for value in (width, height))
    if not all(16 <= value <= 16000 for value in pixels) or pixels[0]*pixels[1] > 64000000:
        raise ValueError("Export must be 16–16000 pixels per side and at most 64 million pixels.")
    return pixels
