"""Reviewed geometry refinement and atlas centroids, independent of Qt/VTK."""
from dataclasses import dataclass
from datetime import datetime, timezone
from pathlib import Path
import json
import shutil
import tempfile
import numpy as np
from .io import Surface, Nodes, Volume, read_surface, read_nodes, read_volume, sha256, gifti_dependencies


def positive_integer(value, name):
    if isinstance(value,bool) or not np.isfinite(value) or int(value)!=value or value<=0:
        raise ValueError(f"{name} must be a positive integer.")
    return int(value)


def subdivide_surface(surface, levels=1, max_vertices=5_000_000, max_faces=10_000_000):
    """Stable MATLAB edge ordering; retain all old vertices including unused ones."""
    levels=positive_integer(levels,"Levels")
    max_vertices=positive_integer(max_vertices,"Vertex limit"); max_faces=positive_integer(max_faces,"Face limit")
    if levels>3: raise ValueError("Choose 1 to 3 subdivision levels.")
    points=surface.points.copy(); faces=surface.faces.copy(); counts=[]
    if len(points)>max_vertices or len(faces)>max_faces:
        raise ValueError("Source mesh exceeds the configured resource limit.")
    for _ in range(levels):
        if 4*len(faces)>max_faces: raise ValueError("Subdivision exceeds the face limit.")
        edges=np.sort(np.vstack((faces[:,[0,1]],faces[:,[1,2]],faces[:,[2,0]])),axis=1)
        unique,first,inverse=np.unique(edges,axis=0,return_index=True,return_inverse=True)
        if len(points)+len(unique)>max_vertices: raise ValueError("Subdivision exceeds the vertex limit.")
        order=np.argsort(first); remap=np.empty(len(order),dtype=np.int64); remap[order]=np.arange(len(order))
        unique=unique[order]; mapped=remap[inverse]+len(points)
        ab,bc,ca=np.split(mapped,3)
        midpoints=(points[unique[:,0]]+points[unique[:,1]])/2
        faces=np.vstack((np.column_stack((faces[:,0],ab,ca)),np.column_stack((ab,faces[:,1],bc)),
                         np.column_stack((ca,bc,faces[:,2])),np.column_stack((ab,bc,ca))))
        points=np.vstack((points,midpoints)); counts.append([len(points),len(faces)])
    result=Surface(points,faces,Path("subdivided.nv"))
    report={"kind":"brainnet-surface-subdivision","schema_version":"1.0",
            "operation":"linear midpoint triangle subdivision; each triangle becomes four; no smoothing, registration, resampling or attribute transfer",
            "initial_vertices":len(surface.points),"initial_faces":len(surface.faces),"levels":levels,
            "level_counts":counts,"vertices":len(points),"faces":len(faces)}
    return result,report


def atlas_nodes(volume, regions=None, module=0., size=0., *, chunk_size=1_000_000):
    """Means in the supplied affine frame, not a region-snapping operation."""
    data=np.asarray(volume.data); dims=data.shape
    if data.ndim<2 or any(n!=1 for n in dims[3:]) or not np.isrealobj(data):
        raise ValueError("Use one 3-D discrete label atlas, not a time series.")
    dims=tuple(dims[:3])+tuple([1]*max(0,3-len(dims)))
    flat=data.ravel(order="F")
    ids=np.unique(flat); ids=ids[ids!=0]
    if (len(ids)==0 or len(ids)>100_000 or not np.isfinite(ids).all()
            or np.any(ids!=np.floor(ids)) or np.any(ids>2**53) or np.any(ids<-(2**53))):
        raise ValueError("Atlas needs 1 to 100000 finite nonzero integer labels; background is zero. Probability/statistical maps are not label atlases.")
    requested=np.asarray([] if regions is None else regions)
    if requested.size:
        if (requested.ndim>2 or requested.ndim==2 and min(requested.shape)>1 or not np.isrealobj(requested)
                or not np.isfinite(requested).all() or np.any(requested==0) or np.any(requested!=np.floor(requested))
                or len(np.unique(requested))!=requested.size or not np.isin(requested,ids).all()):
            raise ValueError("Requested labels must be unique nonzero integer IDs present in the atlas.")
        ids=requested.reshape(-1).astype(float)
    for value,name in ((module,"Module"),(size,"Size")):
        if not np.isscalar(value) or not np.isreal(value) or not np.isfinite(value):
            raise ValueError(f"{name} must be a finite real number.")
    if size<0: raise ValueError("Size must be nonnegative.")
    if not np.isrealobj(volume.affine): raise ValueError("Atlas affine must be real-valued.")
    affine=np.asarray(volume.affine,dtype=float)
    if (affine.shape!=(4,4) or not np.isfinite(affine).all() or np.any(np.abs(affine[3]-[0,0,0,1])>1e-12)
            or 1/np.linalg.cond(affine[:3,:3],p=1)<=np.finfo(float).eps):
        raise ValueError("Atlas needs a nonsingular spatial affine with last row [0 0 0 1].")
    chunk_size=positive_integer(chunk_size,"Chunk size")
    order=np.argsort(ids); sorted_ids=ids[order]; counts=np.zeros(len(ids),dtype=np.int64); sums=np.zeros((len(ids),3))
    for first in range(0,len(flat),chunk_size):
        chunk=flat[first:first+chunk_size]; group=np.searchsorted(sorted_ids,chunk)
        selected=group<len(ids)
        selected[selected] &= sorted_ids[group[selected]]==chunk[selected]
        linear=np.flatnonzero(selected)+first
        if not len(linear): continue
        group=order[group[selected]]; counts+=np.bincount(group,minlength=len(ids))
        xyz=(linear%dims[0]+1,(linear//dims[0])%dims[1]+1,linear//(dims[0]*dims[1])+1)
        for axis,coordinates in enumerate(xyz): sums[:,axis]+=np.bincount(group,weights=coordinates,minlength=len(ids))
    centres=sums/counts[:,None]
    # Match VolumeData.Affine's 1-based convention, while native Python volumes
    # retain the NIfTI zero-based affine used by all other Python operations.
    one_based=affine.copy(); one_based[:3,3]-=affine[:3,:3]@np.ones(3)
    world=np.column_stack((centres,np.ones(len(ids))))@one_based.T
    if not np.isfinite(world).all(): raise ValueError("Affine produced nonfinite node coordinates.")
    labels=[f"{label:.0f}" for label in ids]
    nodes=Nodes(world[:,:3],np.full(len(ids),float(module)),np.full(len(ids),float(size)),labels,Path("atlas.node"))
    report={"kind":"brainnet-atlas-nodes","schema_version":"1.0",
            "method":"unweighted mean of 1-based voxel centres, then VolumeData.Affine; no registration or snapping",
            "region_ids":ids.tolist(),"voxel_counts":counts.tolist(),"voxel_centres_one_based":centres.tolist(),
            "affine_one_based":one_based.tolist(),"affine_method":volume.affine_source,"dimensions":list(dims),
            "module_value":float(module),"size_value":float(size),"node_count":len(ids),"background_id":0,
            "label_rule":"original numeric region ID","centroid_inside_region_guaranteed":False}
    return nodes,report


def source_records(path):
    path=Path(path).resolve(); dependencies=gifti_dependencies(path) if path.suffix.lower()==".gii" else []
    if path.suffix.lower() in (".hdr",".img"):
        dependencies.append(path.with_suffix(".img" if path.suffix.lower()==".hdr" else ".hdr"))
    return [{"path":str(p),"sha256":sha256(p)} for p in dict.fromkeys([path,*dependencies])]


def verify_inputs(sources):
    for source in sources:
        path=Path(source["path"])
        if not path.is_file() or sha256(path)!=source["sha256"]:
            raise ValueError("Input or dependency changed after review. Review again before saving.")


def publish_new(destination, extension, report, writer, reader, matches):
    """Validate a temporary file and claim the output exclusively, never overwrite."""
    destination=Path(destination).resolve()
    if destination.suffix.lower()!=extension: raise ValueError(f"Choose a new {extension} output filename.")
    if not destination.parent.is_dir(): raise ValueError("Output folder must already exist.")
    if destination.exists(): raise ValueError("Output exists; choose a new filename. Overwrite is disabled.")
    verify_inputs(report["sources"])
    temporary=None; claimed=False
    try:
        with tempfile.NamedTemporaryFile(mode="w",encoding="utf-8",newline="\n",suffix=extension,
                                         prefix=".brainnet-",dir=destination.parent,delete=False) as stream:
            temporary=Path(stream.name)
            stream.write("# BrainNet Viewer tool output; provenance JSON follows.\n")
            stream.write("# "+json.dumps(report,ensure_ascii=False,allow_nan=False,separators=(",",":"))+"\n")
            writer(stream)
        if not matches(reader(temporary)): raise ValueError("Exact output read-back validation failed.")
        verify_inputs(report["sources"])
        with destination.open("xb") as output:
            claimed=True
            with temporary.open("rb") as source: shutil.copyfileobj(source,output)
        if sha256(destination)!=sha256(temporary): raise ValueError("Published output hash differs from reviewed output.")
        return {**report,"output_path":str(destination),"output_sha256":sha256(destination)}
    except Exception:
        if claimed: destination.unlink(missing_ok=True)
        raise
    finally:
        if temporary is not None: temporary.unlink(missing_ok=True)


@dataclass
class SubdivisionPlan:
    surface: Surface
    report: dict

    @classmethod
    def review(cls,path,levels=1,**limits):
        sources=source_records(path); surface=read_surface(path); verify_inputs(sources)
        result,report=subdivide_surface(surface,levels,**limits)
        report["sources"]=sources
        return cls(result,report)

    def write(self,destination,*,confirmed=False,space="",units="",note=""):
        if not confirmed: raise ValueError("Confirm linear subdivision; geometry changes and maps/colors are not transferred.")
        report={**self.report,"coordinate_space":space.strip(),"units":units.strip(),"confirmation_note":note.strip(),
                "created_utc":datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ")}
        def writer(stream):
            stream.write(f"{len(self.surface.points)}\n"); np.savetxt(stream,self.surface.points,fmt="%.17g")
            stream.write(f"{len(self.surface.faces)}\n"); np.savetxt(stream,self.surface.faces+1,fmt="%d")
        def matches(other): return np.array_equal(other.points,self.surface.points) and np.array_equal(other.faces,self.surface.faces)
        return publish_new(destination,".nv",report,writer,read_surface,matches)


@dataclass
class AtlasNodePlan:
    nodes: Nodes
    report: dict

    @classmethod
    def review(cls,path,regions=None,module=0.,size=0.):
        sources=source_records(path); volume=read_volume(path,allow_singleton=True); verify_inputs(sources)
        nodes,report=atlas_nodes(volume,regions,module,size); report["sources"]=sources
        return cls(nodes,report)

    def write(self,destination,*,confirmed=False,space="",units=""):
        space=space.strip(); units=units.strip()
        if not confirmed or any(not value or value.lower() in ("unknown","unverified") for value in (space,units)):
            raise ValueError("Review the atlas, declare its affine space and units, then confirm. No conversion to MNI or mm is inferred.")
        report={**self.report,"coordinate_space":space,"units":units,
                "created_utc":datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ")}
        def writer(stream):
            for point,module,size,label in zip(self.nodes.positions,self.nodes.modules,self.nodes.values,self.nodes.labels):
                stream.write(" ".join(f"{v:.17g}" for v in (*point,module,size))+f" {label}\n")
        def matches(other):
            return (np.array_equal(other.positions,self.nodes.positions) and np.array_equal(other.modules,self.nodes.modules)
                    and np.array_equal(other.values,self.nodes.values) and other.labels==self.nodes.labels)
        return publish_new(destination,".node",report,writer,read_nodes,matches)
