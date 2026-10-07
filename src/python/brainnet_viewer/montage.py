"""Disjoint montage packing ported from the current MATLAB renderer."""
import numpy as np


def pack(spans, preset):
    n=len(spans)
    if n==1: return [(0.,0.,1.,1.)]
    sizes=np.asarray(spans,dtype=float).copy()
    sizes[:,0]/=4/3
    sizes=np.maximum(sizes,max(float(sizes.max()),1)*1e-6)
    gap,margin,bottom=.022,.025,.065
    available=np.array([1-2*margin,1-margin-bottom])
    result=np.zeros((n,4))
    if n==8 or preset==5 and n==5:
        columns=[[0,3,6],[1,4],[2,5,7]] if n==8 else [[0,3],[1],[2,4]]
        left,right=columns[0],columns[2]
        sizes[left+right,0]=sizes[left+right,0].max()
        for a,b in zip(left,right): sizes[[a,b],1]=sizes[[a,b],1].max()
        widths=np.array([sizes[ids,0].max() for ids in columns])
        heights=np.array([sizes[ids,1].sum() for ids in columns])
        gaps=np.array([len(ids)-1 for ids in columns])*gap
        scale=min((available[0]-2*gap)/widths.sum(),*((available[1]-gaps)/heights))
        total_width=scale*widths.sum()+2*gap; total_height=max(scale*heights+gaps)
        x=(1-total_width)/2; top=bottom+(available[1]+total_height)/2
        for col,ids in enumerate(columns):
            y=top-(total_height-scale*heights[col])/2 if n==5 and col==1 else top
            for index in ids:
                w,h=scale*widths[col],scale*sizes[index,1]
                result[index]=[x,y-h,w,h]; y-=h+gap
            x+=scale*widths[col]+gap
    else:
        rows=np.arange(n).reshape(2,3) if n==6 and preset==2 else np.arange(n).reshape(-1,2)
        widths=np.max(sizes[rows,0],axis=0); heights=np.max(sizes[rows,1],axis=1)
        nr,nc=rows.shape
        if nc==2: widths[:]=widths.max()
        scale=min((available-np.array([nc-1,nr-1])*gap)/[widths.sum(),heights.sum()])
        total=scale*np.array([widths.sum(),heights.sum()])+np.array([nc-1,nr-1])*gap
        y=bottom+(available[1]+total[1])/2
        for row in range(nr):
            x=(1-total[0])/2
            for col in range(nc):
                w,h=scale*widths[col],scale*heights[row]
                result[rows[row,col]]=[x,y-h,w,h]; x+=w+gap
            y-=scale*heights[row]+gap
    return [tuple(row) for row in result]


def boundary_mask(values, faces, mode="automatic", threshold=0):
    values=np.asarray(values,dtype=float)
    if values.ndim!=1 or not np.isfinite(values).all(): raise ValueError("Boundary needs finite scalar vertex values.")
    if mode not in ("automatic","legacy-automatic","threshold"): raise ValueError("Custom bound masks are not yet ported.")
    classes=values.copy()
    if mode=="threshold": classes=(values>threshold).astype(float)
    elif np.sum(values-np.trunc(values))!=0: classes[values!=0]=1
    per_face=classes[faces]
    mixed=~np.all(np.diff(per_face,axis=1)==0,axis=1)
    mask=np.zeros(len(values),dtype=bool); mask[np.unique(faces[mixed])]=True
    mask[values==0]=False
    return mask
