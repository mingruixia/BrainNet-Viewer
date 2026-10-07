"""Display-only transforms and camera-relative label anchors."""
from dataclasses import dataclass
import numpy as np


@dataclass
class DoubleBrain:
    matrix: np.ndarray
    offset: np.ndarray
    first_moved_node: int

    def forward(self, points): return np.asarray(points) @ self.matrix.T + self.offset
    def inverse(self, points): return (np.asarray(points) - self.offset) @ self.matrix


def double_brain(surface, node_count, settings, has_mapping=False):
    if not settings["surface"]["double_brain"]: return None
    direction = settings["layout"]["view_direction"]
    if settings["layout"]["preset"] != 1 or direction not in (1, 2, 3):
        raise ValueError("Double Brain requires Single View and Left, Superior or Anterior direction.")
    if surface is None or has_mapping or settings["surface"]["color_mode"] not in ("uniform", "vertex-rgb"):
        raise ValueError("Double Brain requires a uniform/vertex-RGB surface without volume, ROI or scalar mapping.")
    low, high = surface.points.min(axis=0), surface.points.max(axis=0)
    span = high-low; matrix = np.eye(3); offset = np.zeros(3)
    if direction == 1:
        matrix = np.diag([-1., -1., 1.]); offset[1] = 2*low[1]-.1*span[1]; separation = span[1]
    else:
        offset[0] = (1.1 if direction == 2 else -1.1)*span[0]; separation = span[0]
    if separation <= 0: raise ValueError("Double Brain requires nonzero surface extent in the separation direction.")
    return DoubleBrain(matrix, offset, node_count//2)


def label_positions(coordinates, radii, low, high, camera, target, up, perspective=False, front=False):
    coordinates = np.asarray(coordinates, dtype=float)
    camera,target,up = [np.asarray(value,dtype=float) for value in (camera,target,up)]
    direction = np.asarray(camera)-target; direction /= np.linalg.norm(direction)
    up = np.asarray(up)-np.dot(up, direction)*direction; up /= np.linalg.norm(up)
    positions = coordinates+(np.asarray(radii)+1)[:, None]*up
    if not front or not len(positions): return positions, False
    corner = np.where(direction >= 0, high, low)
    depth, camera_depth = np.dot(corner, direction), np.dot(camera, direction)
    gap = camera_depth-depth
    if gap <= np.spacing(max(1., abs(camera_depth))): return positions, False
    plane = depth+min(max(1., np.linalg.norm(np.asarray(high)-low)*.01), gap/2)
    if perspective:
        rays = positions-camera; denominators = rays @ direction
        if (denominators >= -np.finfo(float).eps).any(): return positions, False
        positions = camera+rays*((plane-camera_depth)/denominators)[:, None]
    else: positions += (plane-positions @ direction)[:, None]*direction
    return positions, True


def label_font(settings, dpi, viewport_height):
    names = {"arial": "arial", "helvetica": "arial", "times": "times", "times new roman": "times",
             "courier": "courier", "courier new": "courier"}
    family = names.get(settings["label_font_name"].lower())
    if family is None: raise ValueError("Label font is not supported by VTK; choose Arial, Times or Courier.")
    factors = {"points": dpi/72, "pixels": 1, "normalized": viewport_height, "inches": dpi, "centimeters": dpi/2.54}
    pixels = int(np.floor(settings["label_font_size"]*factors[settings["label_font_units"]]+.5))
    if not 1 <= pixels <= 4096: raise ValueError("The selected label size must resolve to 1–4096 pixels.")
    return family, pixels
