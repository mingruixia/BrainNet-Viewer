"""Legacy triangle readers. Coordinates stay as stored; sidecars are never executed."""
import gzip
import io
import re
import struct
import numpy as np

MAX_BYTES=1024**3


class Cursor:
    def __init__(self,data,endian="<",ascii=False):
        self.data=data; self.offset=0; self.endian=endian; self.ascii=ascii
        self.tokens=data.decode("ascii").split() if ascii else None

    def take(self,count,dtype):
        if not 0<=count<=60_000_000: raise ValueError("Array exceeds the input limit.")
        if self.ascii:
            end=self.offset+count
            if end>len(self.tokens): raise ValueError("Truncated ASCII surface.")
            result=np.asarray(self.tokens[self.offset:end],dtype=float); self.offset=end
            if not np.isfinite(result).all(): raise ValueError("Nonfinite surface value.")
            return result
        dtype=np.dtype(self.endian+dtype); end=self.offset+count*dtype.itemsize
        if end>len(self.data): raise ValueError("Truncated binary surface.")
        result=np.frombuffer(self.data,dtype,count,self.offset).copy(); self.offset=end
        return result

    def integer(self,maximum=20_000_000,minimum=1,dtype="i4"):
        value=float(self.take(1,dtype)[0])
        if not np.isfinite(value) or value!=int(value) or not minimum<=value<=maximum: raise ValueError("Invalid surface count or index declaration.")
        return int(value)

    def finish(self):
        if self.offset!=(len(self.tokens) if self.ascii else len(self.data)): raise ValueError("Unexpected trailing data or multiple surface objects.")


def read_legacy(path):
    from .io import Surface
    if path.stat().st_size>MAX_BYTES: raise ValueError("Surface exceeds 1 GiB limit.")
    data=path.read_bytes(); suffix=path.suffix.lower()
    if suffix in (".byu",".g"):
        cursor=Cursor(data,ascii=True); parts=cursor.integer(100_000); nv=cursor.integer(10_000_000); nf=cursor.integer(); entries=cursor.integer(60_000_000)
        if parts>nf or entries!=nf*3: raise ValueError("BYU requires triangular, ordered parts.")
        ranges=cursor.take(parts*2,"i4").reshape(-1,2)
        if not np.equal(ranges,np.floor(ranges)).all() or ranges[0,0]!=1 or ranges[-1,1]!=nf or (ranges[:,0]>ranges[:,1]).any() or not np.equal(ranges[1:,0],ranges[:-1,1]+1).all(): raise ValueError("Invalid BYU part coverage.")
        points=cursor.take(3*nv,"f8").reshape(-1,3); faces=cursor.take(entries,"i4").reshape(-1,3)
        if (faces[:,:2]<=0).any() or (faces[:,2]>=0).any(): raise ValueError("BYU triangles must terminate with a negative third index.")
        faces=np.abs(faces)-1; cursor.finish()
    elif suffix==".mesh":
        mode=data[:5]
        if mode==b"binar":
            if data[5:9] not in (b"ABCD",b"DCBA"): raise ValueError("Invalid BrainVISA byte order.")
            cursor=Cursor(data[9:],">" if data[5:9]==b"ABCD" else "<")
            if cursor.integer(dtype="u4")!=4 or cursor.data[cursor.offset:cursor.offset+4]!=b"VOID": raise ValueError("Only VOID BrainVISA texture is supported.")
            cursor.offset+=4
        elif mode==b"ascii":
            text=data[5:].decode("ascii")
            if text.count("(")!=text.count(")"): raise ValueError("Unclosed BrainVISA tuple.")
            match=re.match(r"\s*VOID\s+",text)
            if not match: raise ValueError("Only VOID BrainVISA texture is supported.")
            cursor=Cursor(re.sub(r"[(),]"," ",text[match.end():]).encode("ascii"),ascii=True)
        else: raise ValueError("Expected AIMS BrainVISA mesh, not Medit mesh.")
        if cursor.integer(dtype="u4")!=3 or cursor.integer(dtype="u4")!=1: raise ValueError("Only a single triangular BrainVISA time step is supported.")
        cursor.integer(2**32-1,0,"u4"); nv=cursor.integer(10_000_000,dtype="u4")
        points=cursor.take(3*nv,"f4").astype(np.float32).astype(float).reshape(-1,3)
        normals=cursor.integer(10_000_000,0,"u4")
        if normals not in (0,nv): raise ValueError("Invalid BrainVISA normals count.")
        if not np.isfinite(cursor.take(3*normals,"f4")).all(): raise ValueError("Invalid BrainVISA normals.")
        if cursor.integer(2**32-1,0,"u4")!=0: raise ValueError("BrainVISA embedded textures are unsupported.")
        nf=cursor.integer(dtype="u4"); faces=cursor.take(3*nf,"u4").reshape(-1,3); cursor.finish()
    elif suffix==".obj":
        if data[:1] not in (b"P",b"p"): raise ValueError("Expected MNI/BIC polygon object, not Wavefront OBJ.")
        def parse(endian):
            cursor=Cursor(data[1:],endian,ascii=data[:1]==b"P")
            if not np.isfinite(cursor.take(5,"f4")).all(): raise ValueError("Invalid MNI material.")
            nv=cursor.integer(10_000_000); points=cursor.take(3*nv,"f4").reshape(-1,3)
            if not np.isfinite(cursor.take(3*nv,"f4")).all(): raise ValueError("Invalid MNI normals.")
            nf=cursor.integer(); flag=cursor.integer(2,0); colors=cursor.take(4*[1,nf,nv][flag],"u1")
            if cursor.ascii and ((colors<0)|(colors>1)).any(): raise ValueError("Invalid MNI RGBA.")
            ends=cursor.take(nf,"i4")
            if not (np.equal(ends,np.arange(1,nf+1)*3).all() or (ends==3).all()): raise ValueError("MNI OBJ requires triangular polygons.")
            faces=cursor.take(3*nf,"i4").reshape(-1,3); cursor.finish()
            return Surface(points,faces,path)
        candidates=[]
        for endian in ("<",">") if data[:1]==b"p" else ("<",):
            try: candidates.append(parse(endian))
            except (ValueError,UnicodeError): pass
        if len(candidates)!=1: raise ValueError("Invalid or ambiguous MNI OBJ byte order/geometry.")
        return candidates[0]
    elif suffix==".mz3":
        if data[:2]==b"\x1f\x8b":
            with gzip.GzipFile(fileobj=io.BytesIO(data)) as stream: data=stream.read(MAX_BYTES+1)
            if len(data)>MAX_BYTES: raise ValueError("Decoded MZ3 exceeds 1 GiB limit.")
        if len(data)<16: raise ValueError("Truncated MZ3 header.")
        magic,flags,nf,nv,skip=struct.unpack_from("<HHIII",data)
        if magic!=23117 or not 1<=flags<=31 or flags&3!=3 or flags&24==24 or not 3<=nv<=10_000_000 or not 1<=nf<=20_000_000 or skip>16_777_216: raise ValueError("Unsupported MZ3 header/attributes.")
        cursor=Cursor(data); cursor.offset=16+skip
        faces=cursor.take(3*nf,"u4").reshape(-1,3); points=cursor.take(3*nv,"f4").reshape(-1,3)
        if flags&4: cursor.take(4*nv,"u1")  # validated, not applied as appearance
        if flags&24:
            width=8 if flags&16 else 4; remaining=len(data)-cursor.offset
            if remaining%(nv*width) or not 1<=remaining//(nv*width)<=256: raise ValueError("Invalid MZ3 scalar layers.")
            if np.isinf(cursor.take(remaining//width,"f8" if width==8 else "f4")).any(): raise ValueError("Infinite MZ3 scalar.")
        cursor.finish()
    else: raise ValueError("Unsupported legacy surface format.")
    return Surface(points,faces,path)
