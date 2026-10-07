"""MATLAB-compatible node/tube detail; original surface geometry is retained."""
from dataclasses import dataclass


@dataclass(frozen=True)
class DetailPolicy:
    level: str
    node_detail: int
    edge_sides: int
    high_load: bool


def resolve_detail(level, node_count, edge_count):
    """Use input node count and selected edge count for all montage views."""
    levels = {"low": (10, 5), "moderate": (50, 10), "high": (100, 20)}
    if level not in (*levels, "adaptive"):
        raise ValueError("Render detail must be adaptive, low, moderate or high.")
    high_load = node_count >= 300 or edge_count >= 1500
    node_detail, edge_sides = levels.get(level, (8, 6) if high_load else (12, 8))
    return DetailPolicy(level, node_detail, edge_sides, high_load)
