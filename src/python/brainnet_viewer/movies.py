"""Deterministic orbit plans and isolated, no-replace movie bundles."""
from copy import deepcopy
from pathlib import Path
import hashlib
import io
import json
import shutil
import tempfile
import time
import numpy as np
import pyvista as pv
from PIL import Image
from .rendering import SceneRenderer, layout
from .session import content_hashes, signature
from .io import sha256


class MovieCancelled(Exception): pass


def movie_plan(format="mp4",width=960,height=720,duration=5.,frame_rate=24,axis="z",
               start_angle=0.,end_angle=360.,safe_fit=True):
    values=(width,height,duration,frame_rate,start_angle,end_angle)
    if not all(np.isscalar(v) and np.isreal(v) and np.isfinite(v) for v in values):
        raise ValueError("Movie parameters must be finite real scalars.")
    if format not in ("png","mp4","avi") or axis not in ("x","y","z"):
        raise ValueError("Choose PNG frames, MP4 or AVI and a world axis x, y or z.")
    if any(isinstance(v,bool) or int(v)!=v for v in (width,height,frame_rate)):
        raise ValueError("Movie dimensions and frame rate must be integers.")
    count=int(np.floor(duration*frame_rate+.5)); delta=end_angle-start_angle
    if (not 128<=width<=3840 or not 128<=height<=3840 or not 0<duration<=120 or not 1<=frame_rate<=60
            or not 2<=count<=1800 or count*width*height>1_000_000_000
            or abs(start_angle)>360 or abs(end_angle)>720 or delta==0 or abs(delta)>360):
        raise ValueError("Use 128–3840 pixels, 1–60 fps, 2–1800 frames, up to 120 seconds / 1 billion frame-pixels and a nonzero orbit up to 360 degrees.")
    if format!="png" and (width%2 or height%2): raise ValueError("Video dimensions must be even. PNG frames allow odd dimensions.")
    if not isinstance(safe_fit,(bool,np.bool_)): raise ValueError("Safe Fit must be boolean.")
    loop=abs(delta)==360
    angles=start_angle+np.arange(count)*delta/(count if loop else count-1)
    return dict(version="1.0",format=format,width=int(width),height=int(height),requested_duration=float(duration),
                frame_rate=int(frame_rate),frame_count=count,actual_duration=count/frame_rate,axis=axis,
                start_angle=float(start_angle),end_angle=float(end_angle),omit_duplicate_endpoint=loop,
                angles=angles.tolist(),safe_fit=bool(safe_fit))


def orbit(base,axis,angle):
    if axis not in ("x","y","z") or not np.isfinite(angle): raise ValueError("Invalid orbit axis or angle.")
    # Exact quadrants match MATLAB cosd/sind, including a complete turn.
    quadrant=angle/90
    if quadrant==int(quadrant): c,s=((1,0),(0,1),(-1,0),(0,-1))[int(quadrant)%4]
    else: c,s=np.cos(np.deg2rad(angle)),np.sin(np.deg2rad(angle))
    rotation={"x":[[1,0,0],[0,c,-s],[0,s,c]],"y":[[c,0,s],[0,1,0],[-s,0,c]],"z":[[c,-s,0],[s,c,0],[0,0,1]]}[axis]
    rotation=np.asarray(rotation); result=deepcopy(base)
    for view in result["views"]:
        target=np.asarray(view["target"])
        view["position"]=(target+rotation@(np.asarray(view["position"])-target)).tolist()
        view["up"]=(rotation@np.asarray(view["up"])).tolist()
    return result


def apply_camera(renderer,state):
    if len(state["views"])!=len(renderer.viewports): raise ValueError("Camera/view count mismatch.")
    for target,view in zip(renderer.plotter.renderers,state["views"]):
        camera=target.camera
        camera.position=view["position"]; camera.focal_point=view["target"]; camera.up=view["up"]
        camera.parallel_projection=view["projection"]=="orthographic"
        camera.parallel_scale=view["parallel_scale"]; camera.view_angle=view["view_angle"]
        target.ResetCameraClippingRange()
    renderer.update_label_records()


def safe_orbit_fit(renderer):
    """Shared world-to-pixel scale that contains each view's orbit sphere."""
    from vtkmodules.util.numpy_support import vtk_to_numpy
    width,height=renderer.plotter.window_size; radii=[]
    for target,(low,high) in zip(renderer.plotter.renderers,renderer.scientific_bounds):
        radius=0.; actors=target.GetActors(); actors.InitTraversal()
        for _ in range(actors.GetNumberOfItems()):
            actor=actors.GetNextActor()
            if not actor.GetVisibility(): continue
            mapper=actor.GetMapper(); mapper.Update(); data=mapper.GetInput()
            if data is None or data.GetPoints() is None: continue
            points=vtk_to_numpy(data.GetPoints().GetData())
            matrix=np.array([[actor.GetMatrix().GetElement(i,j) for j in range(4)] for i in range(4)])
            points=points@matrix[:3,:3].T+matrix[:3,3]
            if len(points): radius=max(radius,float(np.max(np.linalg.norm(points-target.camera.focal_point,axis=1))))
        if radius==0:
            corners=np.array(np.meshgrid(*zip(low,high))).T.reshape(-1,3)
            radius=float(np.max(np.linalg.norm(corners-target.camera.focal_point,axis=1)))
        radii.append(radius)
    pixel=min(min(width*w,height*h)/(2*1.1*max(radius,1e-8))
              for (_,_,w,h),radius in zip(renderer.viewports,radii))
    distance=max(1,5*max(radii))
    for target,(_,_,_,h) in zip(renderer.plotter.renderers,renderer.viewports):
        camera=target.camera; direction=np.asarray(camera.position)-camera.focal_point
        camera.position=np.asarray(camera.focal_point)+direction/np.linalg.norm(direction)*distance
        camera.parallel_projection=True; camera.parallel_scale=height*h/(2*pixel)
        target.ResetCameraClippingRange()
    renderer.update_label_records()


def available_formats():
    try:
        import imageio_ffmpeg as ffmpeg
        ffmpeg.get_ffmpeg_exe()
    except (ImportError,RuntimeError,OSError): return ["png"]
    return ["mp4","avi","png"]


def check_cancel(cancel):
    if cancel(): raise MovieCancelled("Animation cancelled; no output bundle was published.")


def export_movie(source,destination,plan,*,paths=None,settings=None,cancel=lambda:False,progress=lambda done,total:None):
    plan=movie_plan(**{key:plan[key] for key in ("format","width","height","frame_rate","axis","start_angle","end_angle","safe_fit")},
                    duration=plan["requested_duration"])
    if source is None or source.prepared is None: raise ValueError("Render a scene before exporting an animation.")
    prepared=source.prepared; hashes=prepared.input_hashes
    if paths is None: raise ValueError("Provide current Scene input paths for complete movie source verification.")
    current=prepared.settings if settings is None else settings
    if (signature(hashes,current)!=signature(hashes,prepared.settings)
            or paths is not None and content_hashes(paths)!=hashes):
        raise ValueError("Rendered data/settings are stale. Render again before exporting.")
    if plan["format"] not in available_formats(): raise ValueError("Video encoder unavailable. Install the desktop dependencies or use PNG frames.")
    destination=Path(destination).resolve()
    if destination.exists(): raise ValueError("Choose a new output folder; existing files/folders are never overwritten.")
    if not destination.parent.is_dir(): raise ValueError("Parent output folder must already exist.")
    check_cancel(cancel); original=source.capture_camera(); stage=Path(tempfile.mkdtemp(prefix=".brainnet-movie-",dir=destination.parent))
    clone_plot=None; clone=None; writer=None; started=time.monotonic()
    try:
        _,views=layout(prepared.settings["layout"],prepared.split)
        clone_plot=pv.Plotter(off_screen=True,shape=(1,len(views)),window_size=(plan["width"],plan["height"]),border=False)
        clone=SceneRenderer(clone_plot)
        clone.render(prepared,orientation_labels=False)
        state=deepcopy(original)
        # Preserve the source's per-view relative zoom at the movie aspect ratio.
        pixel=clone.pixel_scale(plan["width"],plan["height"])
        for view,(_,_,_,h) in zip(state["views"],clone.viewports):
            view["parallel_scale"]=view["zoom_factor"]*plan["height"]*h/(2*pixel)
        apply_camera(clone,state)
        if plan["safe_fit"]: safe_orbit_fit(clone)
        base=clone.capture_camera(); entries=[]; video=""; encoder_version=""
        if plan["format"]!="png":
            import imageio_ffmpeg as ffmpeg
            video="movie."+plan["format"]; encoder_version=ffmpeg.get_ffmpeg_version()
            writer=ffmpeg.write_frames(str(stage/video),(plan["width"],plan["height"]),fps=plan["frame_rate"],
                codec="libx264" if plan["format"]=="mp4" else "mjpeg",pix_fmt_out="yuv420p" if plan["format"]=="mp4" else "yuvj420p",
                macro_block_size=1,ffmpeg_log_level="error",ffmpeg_timeout=30,
                output_params=["-threads","2","-crf","18"] if plan["format"]=="mp4" else ["-threads","2","-q:v","2"])
            writer.send(None)
        for index,angle in enumerate(plan["angles"],1):
            check_cancel(cancel); apply_camera(clone,orbit(base,plan["axis"],angle)); clone_plot.render()
            pixels=clone_plot.screenshot(return_img=True)
            if pixels.shape[:2]!=(plan["height"],plan["width"]): raise ValueError("Movie capture size mismatch.")
            pixels=np.ascontiguousarray(pixels[:,:,:3]); buffer=io.BytesIO(); Image.fromarray(pixels).save(buffer,format="PNG")
            png=buffer.getvalue(); name=f"frame-{index:06d}.png" if not video else ""
            if name: (stage/name).write_bytes(png)
            if index==1: (stage/"preview.png").write_bytes(png)
            if writer is not None: writer.send(pixels)
            entries.append(dict(index=index,angle=angle,file=name,sha256=hashlib.sha256(png).hexdigest()))
            progress(index,plan["frame_count"]); check_cancel(cancel)
        if writer is not None: writer.close(); writer=None
        verified=plan["frame_count"]
        if video:
            import imageio_ffmpeg as ffmpeg
            decoder=ffmpeg.read_frames(str(stage/video))
            try:
                metadata=next(decoder)
                if tuple(metadata["size"])!=(plan["width"],plan["height"]) or abs(metadata["fps"]-plan["frame_rate"])>1e-6:
                    raise ValueError("Encoded dimensions/frame rate do not match the plan.")
                verified=0
                for frame in decoder:
                    check_cancel(cancel); verified+=1
                    if len(frame)!=plan["width"]*plan["height"]*3: raise ValueError("Decoded video frame size mismatch.")
            finally: decoder.close()
            if verified!=plan["frame_count"]: raise ValueError("Encoded frame count does not match the plan.")
        if paths is not None and content_hashes(paths)!=hashes: raise ValueError("Input changed during export. Render again.")
        record=dict(kind="brainnet-camera-movie",schema_version="1.0",plan=plan,settings=prepared.settings,input_hashes=hashes,
                    source_camera=original,orbit_base_camera=base,source_camera_untouched=source.capture_camera()==original,
                    camera_rule="World-axis rotation about each view target; position/up rotated from base, never accumulated.",
                    lighting_rule="VTK camera-relative lights follow each frame; static orientation labels omitted.",
                    frames=entries,video_file=video,video_sha256=sha256(stage/video) if video else "",verified_frames=verified,
                    frame_hash_semantics="SHA-256 of pre-encoding PNG bytes; lossy video pixels need not match.",
                    encoder_version=encoder_version,elapsed_seconds=time.monotonic()-started)
        if not record["source_camera_untouched"]: raise ValueError("Source camera changed during export; output was not published.")
        (stage/"provenance.json").write_text(json.dumps(record,ensure_ascii=False,allow_nan=False,indent=2)+"\n",encoding="utf-8")
        check_cancel(cancel)
        # Claim destination exclusively (a Windows directory rename must not
        # replace an existing empty folder on POSIX).
        destination.mkdir()
        published=[]
        try:
            for item in stage.iterdir():
                target=destination/item.name
                with target.open("xb") as stream:
                    published.append(target)
                    with item.open("rb") as source_file: shutil.copyfileobj(source_file,stream)
        except Exception:
            for item in published: item.unlink(missing_ok=True)
            try: destination.rmdir()
            except OSError: pass  # Preserve any unrelated files added concurrently.
            raise
        return {**record,"output_folder":str(destination)}
    finally:
        try:
            if writer is not None: writer.close()
        finally:
            try:
                if clone is not None: clone.dispose()
            finally:
                try:
                    if clone_plot is not None: clone_plot.close()
                finally: shutil.rmtree(stage,ignore_errors=True)
