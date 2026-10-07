"""Data-only EC MAT import with explicit review; never eval MATLAB text."""
from copy import deepcopy
from pathlib import Path
import re
import numpy as np
from scipy.io import loadmat, whosmat
from .settings import DEFAULTS, normalize
from .palettes import palette, PALETTES
from .io import sha256


def _raw_mat(value):
    # Keep the MAT class information until cells/objects have been rejected.
    # simplify_cells would erase the distinction for singleton cells.
    if type(value) is not np.ndarray: raise ValueError("EC objects/functions are unsupported.")
    if value.dtype.names is not None:
        if value.shape!=(1,1): raise ValueError("Nested EC structures must be scalar.")
        return {name:_raw_mat(value[name][0,0]) for name in value.dtype.names}
    if value.dtype.kind not in "biufUS" or value.size>16_000_000:
        raise ValueError("EC cells/objects/functions are unsupported; only bounded numeric/text structures are allowed.")
    if not value.size: return []
    if value.size==1: return _data(value.item())
    if value.ndim==2 and min(value.shape)==1: return _data(value.ravel())
    return _data(value)


def _data(value):
    if isinstance(value,dict): return {k:_data(v) for k,v in value.items()}
    if isinstance(value,list):
        if len(value)>16_000_000: raise ValueError("EC numeric data exceed the import limit.")
        return [_data(v) for v in value]
    if isinstance(value,np.ndarray):
        if value.dtype.kind not in "biufUS" or value.size>16_000_000: raise ValueError("EC must contain only bounded numeric/text data, not objects, functions or cells.")
        if value.dtype.kind in "biuf" and not np.isfinite(value).all(): raise ValueError("EC numbers must be finite.")
        return value.tolist()
    if isinstance(value,np.generic): return _data(value.item())
    if isinstance(value,(bool,int,float,str)):
        if isinstance(value,(float,int)) and not np.isfinite(value): raise ValueError("EC numbers must be finite.")
        return value
    raise ValueError("EC must contain only numeric/text scalar structures; MATLAB objects/functions are unsupported.")


def migrate_ec(ec, map_mode=0):
    if not isinstance(ec,dict) or map_mode not in (0,1,2): raise ValueError("A scalar EC structure and map mode 0/1/2 are required.")
    ec=_data(ec); result=deepcopy(DEFAULTS); mapped=[]
    result["volume"]["colormap"]=np.vstack((palette("cool",128)[::-1],palette("hot",128))).tolist()
    def get(path,default=None):
        current=ec
        for part in path.split("."):
            if not isinstance(current,dict) or part not in current: return default
            current=current[part]
        return current
    def found(path): return get(path) is not None
    def mark(path):
        if "EC."+path not in mapped: mapped.append("EC."+path)
    def put(path,destination,value=None):
        if not found(path): return
        section,key=destination.split("."); result[section][key]=get(path) if value is None else value; mark(path)
    def scalar(path,default=None):
        value=get(path,default)
        if isinstance(value,bool): return int(value)
        if not isinstance(value,(int,float)) or not np.isfinite(value): raise ValueError(f"EC.{path} must be a finite scalar.")
        return value
    def code(path,names,offset=0):
        value=scalar(path)+offset
        # Historical nameFor rounds/clamps; retain that deterministic behavior.
        return names[min(max(int(np.floor(value+.5)),1),len(names))-1]
    def flag(path):
        value=scalar(path)
        if value not in (0,1): raise ValueError(f"EC.{path} must be 0 or 1.")
        return bool(value)
    direct={"lot.view":"layout.preset","lot.view_direction":"layout.view_direction","lot.view_az":"layout.custom_azimuth","lot.view_el":"layout.custom_elevation",
            "glb.shading":"global.shading","glb.lighting":"global.lighting","glb.lightdirection":"global.light_direction",
            "msh.alpha":"surface.opacity","msh.color":"surface.color","msh.boundary_color":"surface.boundary_color",
            "lbl_threshold":"node.label_threshold","lbl_font.FontName":"node.label_font_name","lbl_font.FontSize":"node.label_font_size",
            "lbl_font.FontWeight":"node.label_font_weight","lbl_font.FontAngle":"node.label_font_angle","lbl_font.FontUnits":"node.label_font_units",
            "nod.draw_threshold":"node.threshold","nod.size_size":"node.size","nod.size_ratio":"node.size_scale","nod.size_threshold":"node.size_threshold",
            "nod.color_threshold":"node.color_threshold","edg.draw_threshold":"edge.threshold","edg.size_size":"edge.size","edg.size_ratio":"edge.size_scale",
            "edg.size_threshold":"edge.size_threshold","edg.color_threshold":"edge.color_threshold","edg.color_distance":"edge.length_threshold",
            "edg.opacity_same":"edge.opacity","vol.mapalgorithm":"volume.map_algorithm","vol.threshold":"volume.statistical_threshold",
            "vol.p":"volume.p_value","vol.clustersize":"volume.cluster_size","vol.rmm":"volume.voxel_connectivity","vol.pn":"volume.positive_minimum",
            "vol.px":"volume.positive_maximum","vol.nx":"volume.negative_minimum","vol.nn":"volume.negative_maximum","vol.null":"volume.null_color",
            "vol.roi.drawt":"roi.selection","img.width":"image.width","img.height":"image.height","img.dpi":"image.dpi"}
    for path,destination in direct.items():
        if found(path) and get(path)!=[]:
            value=get(path)
            if destination=="roi.selection": value=np.asarray(value).ravel().tolist()
            put(path,destination,value)
    enum={"glb.detail":("global.render_detail",("low","moderate","high")),"msh.color_type":("surface.color_mode",("uniform","scalar")),
          "msh.boundary":("surface.boundary_mode",("none","legacy-automatic","threshold","custom")),
          "lbl":("node.label_mode",("all","none","threshold")),"lbl_threshold_type":("node.label_basis",("value","module")),
          "nod.draw":("node.selection_mode",("all","threshold","connected")),"nod.draw_threshold_type":("node.selection_basis",("value","module")),
          "nod.size":("node.size_mode",("uniform","mapped","threshold")),"nod.color":("node.color_mode",("uniform","mapped","modular","threshold")),
          "edg.draw":("edge.selection_mode",("all","threshold")),"edg.size":("edge.size_mode",("uniform","mapped","threshold")),
          "edg.color":("edge.color_mode",("uniform","mapped","threshold","length","node-module","custom")),
          "edg.opacity":("edge.opacity_mode",("uniform","mapped")),"vol.type":("volume.type",("surface-map","roi"))}
    for path,(destination,names) in enum.items():
        if found(path): put(path,destination,code(path,names))
    for path,destination in {"glb.lr":"global.show_orientation_labels","msh.doublebrain":"surface.double_brain","lbl_front":"node.label_in_front",
                             "edg.interhemiedges":"edge.inter_hemisphere_only","edg.directed":"edge.directed","vol.adjustCM":"volume.adjust_null","vol.roi.drawall":"roi.draw_all"}.items():
        if found(path): put(path,destination,flag(path))
    if found("glb.material"):
        material=get("glb.material")
        if not isinstance(material,str): raise ValueError("EC material must be inert text.")
        name=material.strip().lower(); coefficients=[.5]*3
        if name not in ("dull","shiny","metal"):
            if not re.fullmatch(r"\(\[\s*[-+\d.eE,\s]+\]\)",name): raise ValueError("Unsupported EC material expression; no code is executed.")
            parts=name[2:-2].replace(","," ").split()
            try: coefficients=[float(v) for v in parts]
            except ValueError: raise ValueError("Invalid EC material coefficients.") from None
            if len(coefficients)!=3 or not np.isfinite(coefficients).all() or any(v<0 or v>1 for v in coefficients): raise ValueError("Invalid EC material coefficients.")
            name="custom"
            for path in ("glb.material_ka","glb.material_kd","glb.material_ks"):
                if found(path):
                    try: v=float(get(path))
                    except (ValueError,TypeError): raise ValueError("Invalid EC material coefficient fields.") from None
                    if not np.isfinite(v) or not 0<=v<=1: raise ValueError("Invalid EC material coefficient fields.")
        result["global"].update(material_profile=name,material_coefficients=coefficients); mark("glb.material")
    if not found("msh.color_type") and map_mode>0: result["surface"]["color_mode"]="scalar"
    def rgb(path,minimum=1):
        data=np.atleast_2d(np.asarray(get(path),float))
        if data.ndim!=2 or data.shape[1]!=3 or len(data)<minimum or len(data)>4096 or not np.isfinite(data).all() or ((data<0)|(data>1)).any(): raise ValueError(f"EC.{path} requires finite RGB rows in [0,1].")
        return data
    if found("msh.color_table") and get("msh.color_table")!=[]:
        data=np.atleast_2d(np.asarray(get("msh.color_table"),float))
        if data.ndim!=2 or data.shape[1]!=3: raise ValueError("EC vertex colors need N x 3 values.")
        result["surface"].update(vertex_colors=data.tolist(),vertex_colors_source="Legacy EC; vertex-order confirmation and binding required")
        if result["surface"]["color_mode"]=="scalar" and map_mode==0: result["surface"]["color_mode"]="vertex-rgb"
        mark("msh.color_table")
    if result["surface"]["boundary_mode"] in ("threshold","custom"):
        if not found("msh.boundary_value") or get("msh.boundary_value")==[]: raise ValueError("EC threshold/custom boundary requires boundary_value.")
        if result["surface"]["boundary_mode"]=="threshold": put("msh.boundary_value","surface.boundary_threshold")
        else:
            put("msh.boundary_value","surface.boundary_mask",np.asarray(get("msh.boundary_value")).ravel().tolist())
            result["surface"]["boundary_mask_source"]="Legacy EC import; surface binding required"
    for prefix,section in (("nod","node"),("edg","edge")):
        if found(prefix+".size_value"):
            transform=code(prefix+".size_value",("mapped","raw")); put(prefix+".size_value",section+".size_threshold_basis",transform)
            if result[section]["size_mode"]=="mapped" and transform=="raw": result[section]["size_mode"]="raw"
    for path,destination in {"edg.draw_abs":"edge.value_mode","edg.size_abs":"edge.size_value_mode","edg.opacity_abs":"edge.opacity_value_mode"}.items():
        if found(path): put(path,destination,"absolute" if flag(path) else "signed")
    node=result["node"]; low=get("nod.color_map_low",[]); high=get("nod.color_map_high",[])
    if low!=[] and high!=[]: node["color_limits"]=[low,high]; mark("nod.color_map_low"); mark("nod.color_map_high")
    if found("nod.color_map_type"):
        value=scalar("nod.color_map_type")
        if value==1: node["color_limits"]=[]
        elif value!=2 or low==[] or high==[]: raise ValueError("Fixed EC node mapping requires both limits.")
        mark("nod.color_map_type")
    mode=node["color_mode"]
    if found("nod.CM"):
        cm=rgb("nod.CM")
        if mode=="mapped": node["colormap"]=cm.tolist()
        elif mode=="uniform": node["color"]=cm[0].tolist()
        if mode in ("uniform","mapped","threshold"): mark("nod.CM")
    if mode=="threshold":
        cm=rgb("nod.CM",64); node.update(color_high=cm[0].tolist(),color_low=cm[63].tolist()); mark("nod.CM")
    edge=result["edge"]; mode=edge["color_mode"]
    if mode in ("mapped","threshold","length","node-module","custom"):
        cm=rgb("edg.CM",64 if mode in ("mapped","threshold","length") else 21 if mode=="node-module" else 1); mark("edg.CM")
        if mode in ("threshold","length"): edge.update(color_high=cm[0].tolist(),color_low=cm[63].tolist())
        if mode=="node-module": edge.update(colormap=cm[:20].tolist(),inter_module_color=cm[20].tolist())
        if mode in ("mapped","threshold"):
            if found("edg.color_abs"): put("edg.color_abs","edge."+("mapped_value_mode" if mode=="mapped" else "threshold_value_mode"),"absolute" if flag("edg.color_abs") else "signed")
        if mode=="mapped":
            edge["colormap"]=cm[:64].tolist(); range_type=scalar("edg.color_map_type",1)
            if range_type==2:
                edge["color_limits"]=[scalar("edg.color_map_low"),scalar("edg.color_map_high")]; mark("edg.color_map_low"); mark("edg.color_map_high")
            elif range_type!=1: raise ValueError("EC edge range type must be Auto/Fixed.")
            if found("edg.color_map_type"): mark("edg.color_map_type")
        if mode=="custom":
            if not found("edg.color_custom_matrix") or not found("edg.color_custom_index"): raise ValueError("EC custom edges need matrix, category indices and RGB table.")
            indices=np.asarray(get("edg.color_custom_index")).ravel().tolist()
            matrix=np.asarray(get("edg.color_custom_matrix"),float)
            if matrix.ndim==0: matrix=matrix.reshape(1,1)
            edge["custom_color"]={"matrix":matrix.tolist(),"indices":indices,"node_sha256":"","source":"legacy EC"}
            edge["colormap"]=(np.vstack((cm,cm)) if len(cm)==1 else cm).tolist(); mark("edg.color_custom_matrix"); mark("edg.color_custom_index")
    for path,index in (("edg.opacity_min",0),("edg.opacity_max",1)):
        if found(path): edge["opacity_range"][index]=scalar(path); mark(path)
    volume=result["volume"]; volume["display"]=map_mode>0
    if found("vol.display") and get("vol.display")!=[]:
        display=scalar("vol.display")
        if display not in (0,1,2,3): raise ValueError("EC volume display must be 0–3.")
        volume["display"]=display>0 or map_mode>0
        if display>0: volume["display_mode"]=("both","positive","negative")[int(display)-1]
        mark("vol.display")
    if volume["statistical_threshold"]!=0: volume["threshold_mode"]="value"
    roi=result["roi"]
    if volume["display"] and volume["type"]=="roi" and found("vol.roi.color") and get("vol.roi.color")!=[]:
        ids=np.asarray(get("vol.roi.draw",roi["selection"])).ravel()
        if not len(ids): raise ValueError("EC positional ROI colors require matching draw/drawt IDs.")
        cm=rgb("vol.roi.color",len(ids)); roi.update(selection=ids.tolist(),color_mode="custom",custom_colors=np.column_stack((ids,cm[:len(ids)])).tolist()); mark("vol.roi.color")
    smooth=get("vol.roi.smooth",0); kernel=get("vol.roi.smooth_kernal",1)
    roi["smoothing"]="none" if not smooth else "gaussian" if kernel==2 else "box"
    expression=get("vol.cmstring","")
    if not isinstance(expression,str): raise ValueError("EC colormap expression must be inert text.")
    match=re.match(r"^\s*([A-Za-z]\w*)\s*\(",expression)
    if match and match[1].lower() in PALETTES: volume["colormap"]=match[1].lower()
    result=normalize({"visualization_settings":result})
    def leaves(value,prefix="EC"):
        return [leaf for k,v in value.items() for leaf in (leaves(v,prefix+"."+k) if isinstance(v,dict) and v else [prefix+"."+k])]
    fields=leaves(ec); bindings=[]
    if result["surface"]["color_mode"]=="vertex-rgb" and result["surface"]["vertex_colors"]: bindings.append("Vertex RGB requires ordered-surface binding.")
    if result["surface"]["boundary_mode"]=="custom": bindings.append("Boundary mask requires ordered-surface binding.")
    if edge["color_mode"]=="custom": bindings.append("Custom edge matrix requires ordered-node binding.")
    report=dict(schema_version="1.0.0",import_mode="settings-only",mapped_fields=mapped,input_fields=fields,
                fields_requiring_review=[p for p in fields if p not in mapped],lossless_claimed=False,
                implementation_review=[],
                warnings=["Unmapped fields use modern defaults. Colormap text is never executed; only recognized function names are used.",*bindings])
    return result,report


def read_ec(path, map_mode=0):
    path=Path(path)
    if not path.is_file() or path.stat().st_size>64*1024*1024: raise ValueError("Choose an EC MAT file of at most 64 MiB.")
    digest=sha256(path)
    try: variables=whosmat(path)
    except (NotImplementedError,ValueError) as error: raise ValueError("Unsupported MAT format. Export EC as a MATLAB v7 MAT file.") from error
    selected=[x for x in variables if x[0]=="EC"]
    if len(selected)!=1 or selected[0][1]!=(1,1) or selected[0][2]!="struct": raise ValueError("MAT file must contain a scalar EC structure.")
    payload=loadmat(path,variable_names=["EC"],struct_as_record=True,squeeze_me=False,verify_compressed_data_integrity=True)
    settings,report=migrate_ec(_raw_mat(payload["EC"]),map_mode)
    if sha256(path)!=digest: raise ValueError("EC file changed during import.")
    report.update(source_sha256=digest,source_file=str(path.resolve()))
    if any(name in ("File","FLAG") for name,_,_ in variables): report["warnings"].append("File/FLAG ignored: current selected files own the scene and map mode.")
    return settings,report
