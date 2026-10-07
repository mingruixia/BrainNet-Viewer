"""Read-only MATLAB session bridge, verified against source JSON tokens."""
from copy import deepcopy
import hashlib
import json
import re
import numpy as np
from .session import signature, validate_session
from .settings import finite_json
from .export_size import figure_size


class _Number(str): pass


def source_signature_matches(text, expected):
    """Match MATLAB writer token spelling/order; never guess a stale binding.

    Equivalent files rewritten with different numeric spelling may not match.
    Camera replay then fails closed; input/settings loading remains available.
    """
    def unique(pairs):
        result={}
        for key,value in pairs:
            if key in result: raise ValueError("Duplicate JSON object field.")
            result[key]=value
        return result
    data=json.loads(text,parse_int=_Number,parse_float=_Number,object_pairs_hook=unique)
    if not isinstance(data,dict) or not all(key in data for key in ("inputs","options")): return False
    def compact(value):
        if isinstance(value,_Number): return str(value)
        if isinstance(value,dict): return "{"+",".join(json.dumps(k,ensure_ascii=False)+":"+compact(v) for k,v in value.items())+"}"
        if isinstance(value,list): return "["+",".join(compact(v) for v in value)+"]"
        return json.dumps(value,ensure_ascii=False,allow_nan=False,separators=(",",":"))
    encoded=compact({"inputs":data["inputs"],"options":data["options"]})
    return hashlib.sha256(encoded.encode("utf-8")).hexdigest()==expected


def validate_matlab_session(state):
    if not isinstance(state,dict) or state.get("version")!="1.0" or not isinstance(state.get("scene_signature"),str) or not re.fullmatch("[0-9a-f]{64}",state["scene_signature"]):
        raise ValueError("Invalid MATLAB session version/signature.")
    finite_json(state); export=state.get("export")
    if not isinstance(export,dict): raise ValueError("Invalid MATLAB export preferences.")
    enums={"format":("png","jpg","tif","bmp","pdf","svg"),"units":("pixels","millimeters","centimeters","inches","points"),
           "content_type":("auto","image","vector"),"background_color":("current","white","black","none")}
    if any(export.get(k) not in choices for k,choices in enums.items()): raise ValueError("Unsupported MATLAB export preferences.")
    for key in ("width","height","resolution_dpi"):
        x=export.get(key)
        if isinstance(x,bool) or not isinstance(x,(float,int)) or not np.isfinite(x) or x<=0: raise ValueError("Invalid MATLAB export dimensions.")
    if int(export["resolution_dpi"])!=export["resolution_dpi"]: raise ValueError("MATLAB export DPI must be an integer.")
    if export["format"] in ("png","jpg","tif","bmp") and export["content_type"]=="vector": raise ValueError("Raster format cannot request vector content.")
    if export["format"] in ("jpg","bmp") and export["background_color"]=="none": raise ValueError("JPEG/BMP cannot be transparent.")
    camera=state.get("camera")
    if camera not in (None,[]):
        if not isinstance(camera,dict) or isinstance(camera.get("layout"),bool) or camera.get("layout") not in (1,2,3,4,5): raise ValueError("Invalid MATLAB camera layout.")
        views=camera.get("views")
        if isinstance(views,dict): views=[views]  # MATLAB jsonencode scalar struct
        if not isinstance(views,list) or len(views) not in {1:(1,),2:(6,8),3:(4,6),4:(6,),5:(5,6)}[camera["layout"]]:
            raise ValueError("Invalid MATLAB camera view count.")
        heights=camera.get("viewport_heights")
        if heights is not None:
            heights=np.asarray(heights,float).ravel()
            if heights.shape!=(len(views),) or not np.isfinite(heights).all() or (heights<=0).any() or (heights>1).any(): raise ValueError("Invalid MATLAB viewport heights.")
            camera=deepcopy(camera); camera["viewport_heights"]=heights.tolist()
        distances=[]; angles=[]
        for view in views:
            if not isinstance(view,dict): raise ValueError("Invalid MATLAB camera view.")
            for key in ("position","target","up"):
                value=np.asarray(view.get(key),float)
                if value.shape!=(3,) or not np.isfinite(value).all(): raise ValueError("Invalid MATLAB camera vectors.")
            direction=np.asarray(view["position"])-view["target"]
            if np.linalg.norm(direction)<=0 or np.linalg.norm(np.cross(direction,view["up"]))<=1e-10: raise ValueError("Degenerate MATLAB camera.")
            angle=view.get("view_angle")
            if isinstance(angle,bool) or not isinstance(angle,(float,int)) or not 0<angle<180: raise ValueError("Invalid MATLAB camera angle.")
            if view.get("projection") not in ("orthographic","perspective") or (camera["layout"]>1 and view["projection"]!="orthographic"): raise ValueError("Invalid MATLAB projection.")
            for key in ("xlim","ylim","zlim"):
                limits=np.asarray(view.get(key),float)
                if limits.shape!=(2,) or not np.isfinite(limits).all() or limits[1]<=limits[0]: raise ValueError("Invalid MATLAB axis limits.")
            distances.append(np.linalg.norm(direction)); angles.append(angle)
        if camera["layout"]>1:
            scales=np.tan(np.deg2rad(angles)/2)/(heights if heights is not None else 1)
            if np.ptp(distances)>=1e-7*max(distances) or np.ptp(scales)>=1e-7*max(scales): raise ValueError("Inconsistent MATLAB montage scale.")
        camera=deepcopy(camera); camera["views"]=deepcopy(views)
    else: camera=None
    result=deepcopy(state); result["camera"]=camera
    return result


def export_preferences(state):
    export=state["export"]; width,height=export["width"],export["height"]; units=export["units"]
    units={"pixels":"Pixels","millimeters":"Millimetres","centimeters":"Centimetres","inches":"Inches","points":"Points"}[units]
    dpi=export["resolution_dpi"]; figure_size(width,height,dpi,units)
    warnings=[]
    if export["content_type"]!="auto": warnings.append("MATLAB content type retained as metadata; Python uses its documented export route.")
    if export["background_color"] in ("white","black"): warnings.append("MATLAB export-only background override retained as metadata; Python uses the current scene background.")
    return dict(units=units,width=width,height=height,dpi=dpi,transparent=export["background_color"]=="none",format=export["format"]),warnings


def convert_camera(state, renderer):
    """Convert MATLAB's shortest-side angle to VTK's vertical scale."""
    if state["camera"] is None: return None
    saved=state["camera"]; width,height=renderer.plotter.window_size; pixel=renderer.pixel_scale(width,height)
    if saved["layout"]!=renderer.prepared.settings["layout"]["preset"] or len(saved["views"])!=len(renderer.viewports): return None
    old_heights=saved.get("viewport_heights",[max(v[3] for v in renderer.viewports)]*len(saved["views"]))
    views=[]
    for view,(_,_,w,h),old_h in zip(saved["views"],renderer.viewports,old_heights):
        distance=float(np.linalg.norm(np.asarray(view["position"])-view["target"]))
        tangent=np.tan(np.deg2rad(view["view_angle"])/2)
        tangent*=h/old_h if saved["layout"]>1 else max(1,height*h/(width*w))
        scale=float(distance*tangent)
        views.append({key:deepcopy(view[key]) for key in ("position","target","up","projection")})
        views[-1].update(view_angle=float(np.rad2deg(2*np.arctan(tangent))),parallel_scale=scale,
                         zoom_factor=scale/(height*h/(2*pixel)))
    return dict(layout=saved["layout"],views=views)


def pending_session(state, renderer, identity):
    camera=convert_camera(state,renderer); preferences,_=export_preferences(state)
    return validate_session(dict(version="1.0",producer="python-vtk",scene_signature=identity,camera=camera,export=preferences))
