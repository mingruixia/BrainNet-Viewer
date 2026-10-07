"""Surface operations shared by desktop and Web, without GUI imports."""
from pathlib import Path
import numpy as np
from .io import Surface


def merge_surfaces(surfaces):
    if len(surfaces)<2: raise ValueError('Add at least two surfaces to merge.')
    offsets=np.cumsum([0]+[len(s.points) for s in surfaces[:-1]])
    return Surface(np.vstack([s.points for s in surfaces]),
                   np.vstack([s.faces+offset for s,offset in zip(surfaces,offsets)]),Path('merged.nv'))
