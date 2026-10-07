"""Settings subset with explicit preservation of unimplemented MATLAB fields."""
from copy import deepcopy
import math
import re
import numpy as np
from .palettes import PALETTES, palette

VERSION = "1.22.0"
DEFAULTS = {
    "schema_version": VERSION,
    "layout": {"preset": 1, "view_direction": 1, "custom_azimuth": [], "custom_elevation": []},
    "global": {"background_color": [1, 1, 1], "shading": "interp", "lighting": "phong",
               "light_direction": "right", "show_orientation_labels": False,
               "render_detail": "adaptive", "material_profile": "dull", "material_coefficients": [0.5]*3},
    "surface": {"double_brain": False, "color_mode": "uniform", "color": [.95]*3, "opacity": .3,
                "colormap": "parula", "color_limits": [], "show_colorbar": True, "boundary_mode": "none",
                "boundary_color": [0]*3, "boundary_threshold": 0, "boundary_mask": [],
                "boundary_mesh_sha256": "", "boundary_mask_source": "", "vertex_colors": [],
                "vertex_colors_mesh_sha256": "", "vertex_colors_source": ""},
    "node": {"selection_mode": "all", "selection_basis": "value", "threshold": 0,
             "label_mode": "none", "label_basis": "value", "label_threshold": 0,
             "label_font_name": "Arial", "label_font_size": 10, "label_font_weight": "normal",
             "label_font_angle": "normal", "label_font_units": "points", "label_color": [0]*3,
             "label_in_front": False, "size_mode": "mapped", "size_basis": "value", "size": 3,
             "size_scale": 1, "size_threshold": 0, "size_threshold_basis": "mapped",
             "color_mode": "uniform", "color": [37/255, 89/255, 152/255], "colormap": "jet",
             "color_limits": [], "color_threshold": 0, "color_low": [37/255, 89/255, 152/255], "color_high": [1, 0, 0]},
    "edge": {"selection_mode": "all", "threshold": 0, "sparsity": .1, "value_mode": "absolute",
             "inter_hemisphere_only": False, "directed": False, "arrow_length_scale": 1, "arrow_width_scale": .7,
             "size_mode": "mapped", "size": 1, "size_scale": .7, "size_threshold": 0,
             "size_threshold_basis": "mapped", "size_value_mode": "absolute",
             "color_mode": "uniform", "color": [1, .9, .73], "colormap": "jet", "color_limits": [],
             "color_threshold": 0, "length_threshold": 75, "color_low": [.38]*3, "color_high": [1, .9, .73],
             "threshold_value_mode": "absolute", "mapped_value_mode": "absolute", "inter_module_color": [.5]*3,
             "custom_color": {"matrix": [], "indices": [], "node_sha256": "", "source": ""},
             "opacity_mode": "uniform", "opacity": .7, "opacity_value_mode": "absolute", "opacity_range": [.1, .9]},
    "volume": {"display": False, "type": "surface-map", "map_algorithm": 2, "threshold_mode": "none",
               "statistical_threshold": 0, "p_value": .05, "cluster_size": 0, "voxel_connectivity": 18,
               "positive_minimum": [], "positive_maximum": [], "negative_minimum": [], "negative_maximum": [],
               "display_mode": "both", "adjust_null": True, "null_color": [.95]*3, "colormap": "bwr"},
    "roi": {"draw_all": True, "selection": [], "color_mode": "index", "color": [.8, .2, .2],
            "custom_colors": [], "palette": "hsv", "show_legend": False, "smoothing": "gaussian", "smoothing_kernel": 3},
    "image": {"width": 2000, "height": 1500, "dpi": 300, "show_colorbar": False,
              "colorbar_location": "eastoutside", "colorbar_label": "", "title": ""},
    "fiber": {"visible": False, "color_mode": "direction", "color": [.7]*3, "colormap": "turbo",
              "opacity": .8, "radius": .25, "sampling_stride": 1, "tube_sides": 6},
}


def merge(base, patch):
    result = deepcopy(base)
    for key, value in patch.items():
        if isinstance(value, dict) and isinstance(result.get(key), dict):
            result[key] = merge(result[key], value)
        else:
            result[key] = deepcopy(value)
    return result


def finite_json(value):
    if isinstance(value, float) and not math.isfinite(value):
        raise ValueError("JSON cannot contain NaN or Infinity.")
    if isinstance(value, dict):
        for v in value.values(): finite_json(v)
    elif isinstance(value, list):
        for v in value: finite_json(v)


def normalize(options):
    if not isinstance(options, dict):
        raise ValueError("Scene options must be an object.")
    full = options.get("visualization_settings")
    if full is not None:
        if not isinstance(full, dict): raise ValueError("Full settings must be an object.")
        full = migrate(full)
        result = merge(DEFAULTS, full)
    else:
        result = deepcopy(DEFAULTS)
        result["layout"].update(preset=options.get("layout", 1), view_direction=options.get("view_direction", 1))
        result["surface"]["opacity"] = options.get("mesh_alpha", .3)
        labels = {0: "none", 1: "all", 2: "none", 3: "threshold"}
        result["node"]["label_mode"] = labels[options.get("node_labels", 2)]
        result["edge"].update(selection_mode="all" if options.get("edge_draw_mode", 1) == 1 else "threshold",
                              threshold=options.get("edge_threshold", 0))
        result["volume"].update(display=options.get("volume_display", False),
                                type="surface-map" if options.get("volume_type", 1) == 1 else "roi",
                                map_algorithm=options.get("map_algorithm", 5),
                                positive_maximum=options.get("positive_maximum", []),
                                negative_minimum=options.get("negative_minimum", []))
        result["roi"]["draw_all"] = options.get("roi_draw_all", True)
        if result["volume"]["display"] and result["volume"]["type"]=="surface-map": result["surface"]["color_mode"]="scalar"
    # MATLAB jsonencode flattens a one-row matrix to a vector.
    for section,key,columns in (("surface","vertex_colors",3),("roi","custom_colors",4)):
        rows=result[section][key]
        if isinstance(rows,list) and len(rows)==columns and all(isinstance(x,(int,float)) and not isinstance(x,bool) for x in rows):
            result[section][key]=[rows]
    finite_json(result)
    if result["edge"]["selection_mode"]=="legacy-sparsity": result["edge"]["selection_mode"]="sparsity"
    if result["node"]["color_mode"] in ("module", "modules"):
        result["node"]["color_mode"] = "modular"  # earlier Python development files
    if result["global"]["material_profile"] == "default":
        result["global"].update(material_profile="custom",material_coefficients=[.3,.6,.9,10])
    validate(result)
    return result


def migrate(settings):
    result = deepcopy(settings)
    version = result.get("schema_version", "")
    if version not in {f"1.{minor}.0" for minor in range(23)}:
        raise ValueError("Unsupported visualization settings version.")
    minor = int(version.split(".")[1])
    for section in DEFAULTS:
        if section != "schema_version" and section in result and not isinstance(result[section], dict):
            raise ValueError(f"{section} settings must be an object.")
    node, edge, surface, volume = [result.get(section, {}) for section in ("node", "edge", "surface", "volume")]
    for target, last_minor in ((node, 2), (edge, 5)):
        if minor <= last_minor:
            target.setdefault("color_low", target.get("color", DEFAULTS["node" if target is node else "edge"]["color"]))
            target.setdefault("color_high", palette(target.get("colormap", "jet"), 2)[-1].tolist())
    if minor <= 7: edge.setdefault("mapped_value_mode", "signed")
    if minor < 21:
        edge.setdefault("arrow_length_scale", 1)
        edge.setdefault("arrow_width_scale", 1)
    if minor <= 1 and surface.get("boundary_mode") in ("threshold", "custom") and "boundary_threshold" not in surface:
        raise ValueError("Review the threshold/custom boundary of this older Scene before migrating.")
    if minor < 22:
        old = ("positive_colormap" in volume, "negative_colormap" in volume)
        if old == (True, True):
            volume["colormap"] = np.vstack((palette(volume.pop("negative_colormap"), 128)[::-1],
                                           palette(volume.pop("positive_colormap"), 128))).tolist()
        elif any(old):
            raise ValueError("Both positive and negative colormaps are needed to migrate the older volume settings.")
    result["schema_version"] = VERSION
    return result


def validate(settings):
    """Reject invalid known values early; preserve extension metadata separately."""
    def number(value, name, low=-math.inf, high=math.inf, integer=False, positive=False):
        if (isinstance(value, bool) or not isinstance(value, (int, float)) or not math.isfinite(value)
                or not low <= value <= high or (integer and int(value) != value) or (positive and value <= 0)):
            raise ValueError(f"Invalid {name}: expected {'integer' if integer else 'number'} in [{low},{high}].")

    enums = {
        "layout": {"preset": range(1, 6), "view_direction": range(1, 9)},
        "global": {"shading": ("flat", "faceted", "interp"), "lighting": ("none", "flat", "gouraud", "phong"),
                   "light_direction": ("headlight", "right", "left"), "render_detail": ("adaptive", "low", "moderate", "high"),
                   "material_profile": ("dull", "shiny", "metal", "custom", "default")},
        "surface": {"color_mode": ("uniform", "scalar", "vertex-rgb"), "boundary_mode": ("none", "automatic", "legacy-automatic", "threshold", "custom")},
        "node": {"selection_mode": ("all", "threshold", "connected"), "selection_basis": ("value", "module"),
                 "label_mode": ("all", "none", "threshold"), "label_basis": ("value", "module"),
                 "label_font_weight": ("normal", "bold"), "label_font_angle": ("normal", "italic"),
                 "label_font_units": ("points", "pixels", "normalized", "inches", "centimeters"),
                 "size_mode": ("uniform", "mapped", "raw", "threshold"), "size_basis": ("value", "module"),
                 "size_threshold_basis": ("mapped", "raw"), "color_mode": ("uniform", "mapped", "modular", "threshold", "custom")},
        "edge": {"selection_mode": ("all", "threshold", "sparsity", "legacy-sparsity"),
                 "size_mode": ("uniform", "mapped", "raw", "threshold"), "size_threshold_basis": ("mapped", "raw"),
                 "color_mode": ("uniform", "mapped", "threshold", "length", "node-module", "custom"), "opacity_mode": ("uniform", "mapped")},
        "volume": {"type": ("surface-map", "roi"), "threshold_mode": ("none", "value", "p-value", "cluster"),
                   "map_algorithm": range(1, 9), "voxel_connectivity": (6, 18, 26), "display_mode": ("both", "positive", "negative")},
        "roi": {"color_mode": ("uniform", "index", "custom"), "palette": PALETTES, "smoothing": ("none", "box", "gaussian")},
        "image": {"colorbar_location": ("northoutside", "southoutside", "eastoutside", "westoutside")},
        "fiber": {"color_mode": ("direction", "uniform", "scalar", "bundle")},
    }
    enums["edge"].update({key: ("signed", "absolute") for key in
                          ("value_mode", "size_value_mode", "threshold_value_mode", "mapped_value_mode", "opacity_value_mode")})
    for section, defaults in DEFAULTS.items():
        if section == "schema_version": continue
        values = settings[section]
        if not isinstance(values, dict): raise ValueError(f"{section} must be an object.")
        for key, allowed in enums.get(section, {}).items():
            value = values[key]
            if value not in allowed or (not isinstance(value, str) and isinstance(value, bool)):
                raise ValueError(f"Invalid {section}.{key}.")
        for key, default in defaults.items():
            value, name = values[key], f"{section}.{key}"
            if isinstance(default, bool) and not isinstance(value, bool): raise ValueError(f"{name} must be Boolean.")
            if isinstance(default, (int, float)) and not isinstance(default, bool): number(value, name)
            if key in ("color", "background_color", "label_color", "color_low", "color_high", "null_color", "inter_module_color", "boundary_color"):
                rgb = np.asarray(value, dtype=float)
                if rgb.shape != (3,) or not np.isfinite(rgb).all() or ((rgb < 0) | (rgb > 1)).any():
                    raise ValueError(f"{name} needs three RGB numbers in [0,1].")
            if key == "colormap": palette(value, 2)
            if key in ("color_limits", "opacity_range"):
                if not isinstance(value, list) or (len(value) != 2 and (value or key == "opacity_range")):
                    raise ValueError(f"{name} requires two ordered numbers or empty color limits.")
                if value:
                    for bound in value: number(bound, name, 0 if key == "opacity_range" else -math.inf, 1 if key == "opacity_range" else math.inf)
                    if value[0] > value[1]: raise ValueError(f"{name} is reversed.")
            if isinstance(default, str) and key != "colormap" and not isinstance(value, str): raise ValueError(f"{name} must be text.")
            if key.endswith("_sha256") and value and not re.fullmatch(r"[0-9a-f]{64}", value): raise ValueError(f"Invalid {name} fingerprint.")
        if "opacity" in values: number(values["opacity"], f"{section}.opacity", 0, 1)
    for key, low, high in (("custom_azimuth", -360, 360), ("custom_elevation", -90, 90)):
        value = settings["layout"][key]
        if value != []: number(value, f"layout.{key}", low, high)
    if (settings["layout"]["custom_azimuth"] == []) != (settings["layout"]["custom_elevation"] == []):
        raise ValueError("Custom azimuth and elevation must be set together.")
    for section, key, low, high in (("layout", "preset", 1, 5), ("layout", "view_direction", 1, 8),
                                    ("volume", "map_algorithm", 1, 8), ("volume", "cluster_size", 0, math.inf),
                                    ("roi", "smoothing_kernel", 1, math.inf), ("fiber", "sampling_stride", 1, math.inf),
                                    ("fiber", "tube_sides", 3, 64), ("image", "width", 1, math.inf), ("image", "height", 1, math.inf)):
        number(settings[section][key], f"{section}.{key}", low, high, integer=True)
    for section, keys in (("node", ("size", "size_scale", "label_font_size")), ("edge", ("size", "size_scale")),
                          ("fiber", ("radius",)), ("image", ("dpi",))):
        for key in keys: number(settings[section][key], f"{section}.{key}", positive=True)
    number(settings["node"]["label_font_size"], "node.label_font_size", 0, 100, positive=True)
    number(settings["edge"]["sparsity"], "edge.sparsity", 0, 1)
    for key in ("arrow_length_scale", "arrow_width_scale"): number(settings["edge"][key], f"edge.{key}", .25, 3)
    volume = settings["volume"]
    number(volume["p_value"], "volume.p_value", 0, 1)
    if volume["threshold_mode"] == "p-value" and not 0 < volume["p_value"] < 1: raise ValueError("P value must be strictly between 0 and 1.")
    for direction in ("positive", "negative"):
        low, high = volume[direction + "_minimum"], volume[direction + "_maximum"]
        for bound in (low, high):
            if bound != []: number(bound, "volume range")
        if low != [] and high != [] and low > high: raise ValueError("Volume range is reversed.")
    selection = settings["roi"]["selection"]
    if not isinstance(selection, list): raise ValueError("ROI selection must be a list of positive labels.")
    for label in selection: number(label, "ROI label", 1, math.inf, integer=True)
    colors=settings["roi"]["custom_colors"]
    if not isinstance(colors,list): raise ValueError("Custom ROI Colors must be a list of ID/RGB rows.")
    labels=set()
    for row in colors:
        if not isinstance(row,list) or len(row)!=4: raise ValueError("Custom ROI Colors need ID/RGB rows.")
        number(row[0],"Custom ROI ID",1,math.inf,integer=True)
        if row[0] in labels: raise ValueError("Custom ROI Colors require unique IDs.")
        labels.add(row[0])
        for channel in row[1:]: number(channel,"Custom ROI RGB",0,1)
    coefficients = np.asarray(settings["global"]["material_coefficients"], dtype=float)
    if coefficients.ndim != 1 or len(coefficients) not in (3, 4, 5) or not np.isfinite(coefficients).all():
        raise ValueError("Material coefficients need three to five finite numbers.")
    if ((coefficients[:3] < 0) | (coefficients[:3] > 1)).any() or (len(coefficients) > 3 and coefficients[3] < 0):
        raise ValueError("Invalid material coefficients.")
    if len(coefficients)==5 and not 0<=coefficients[4]<=1:
        raise ValueError("Specular color reflectance must be in [0,1].")
