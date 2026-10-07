"""Bundled dual-atlas lookup in the default MNI frame, without registration."""
from functools import lru_cache
from pathlib import Path
import numpy as np
from scipy.io import loadmat
from .io import sha256


@lru_cache(maxsize=4)
def load_atlas(root, name):
    if name == "aal":
        path=Path(root)/"BrainNet_AAL_Label.mat"
        expected="1fe217ef443cff395884e3c5f672891085cb10858a028048b454d02591316ec9"
        variables=["AAL_vol","AAL_label"]
    elif name == "brodmann":
        path=Path(root)/"BrainNet_Brodmann_Label.mat"
        expected="ed057cd513391e3aefae46e4ade5dea5b23b72da5b7cdb0064b7ebb44f347f8e"
        variables=["Brodmann_vol"]
    else: raise ValueError("Unknown built-in atlas.")
    if sha256(path)!=expected: raise ValueError("Bundled Inspect atlas integrity mismatch.")
    data=loadmat(path,variable_names=variables,simplify_cells=True)
    return (data["AAL_vol"], list(data["AAL_label"])) if name=="aal" else (data["Brodmann_vol"],None)


def lookup(root, xyz):
    point=np.asarray(xyz,dtype=float)
    if point.shape!=(3,) or not np.isfinite(point).all(): raise ValueError("Inspect point must be a finite XYZ triplet.")
    # Original one-based affine is identity with translation [-91,-126,-72].
    voxel_one=point+[91,126,72]
    index=(np.sign(voxel_one)*np.floor(np.abs(voxel_one)+.5)).astype(int)-1
    output={}
    for name in ("aal","brodmann"):
        volume,labels=load_atlas(str(Path(root).resolve()),name)
        if (index<0).any() or (index>=volume.shape).any(): output[name]="Outside atlas"; continue
        label=int(volume[tuple(index)])
        if not label: output[name]="Unassigned"
        elif name=="aal": output[name]=str(labels[label-1]) if label<=len(labels) else f"Label {label}"
        else: output[name]=f"Brodmann Area {label}"
    return output
