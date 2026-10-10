# Export a rotating brain scene

## Desktop workflow

1. Load data and press **Apply** to commit visualization settings and render with **Modern Batch Renderer**; **Render Scene** can explicitly redraw.
2. Adjust the canvas view if needed, then choose **Tools → Export Animation...**.
3. Select MP4, AVI or PNG frames; set pixel dimensions, duration, frame rate, world X/Y/Z axis and start/end angle offsets.
4. Leave **Safe Fit** enabled to fit geometry throughout the orbit. Turn it off only when you intentionally want to preserve the current framing (cropping can occur).
5. Choose **Export...** and enter a **new folder name** under an existing parent directory. This creates a bundle, not a single file. Existing paths cannot be overwritten.

![Current animation controls used in the real-surface tutorial](../tutorials/assets/captures/tutorial12-animation/12-animation-controls.png)

**Cancel Export** stops after the current frame/codec operation, removes staging output and leaves the window open. Closing the window while exporting requests cancellation and closes it after cleanup. Input controls are disabled during export. Failure/cancellation never publishes a partial bundle.

The exporter renders a private, full-quality copy of the prepared data once and reuses its geometry for every frame. It never rotates the main canvas or changes Scene/settings/export preferences. The main camera is therefore unchanged on success, cancellation and failure. Encoding and rendering are offline; the requested playback frame rate is not a promise of real-time export speed. No GPU video-encoder acceleration is claimed.

## Angles, timing and framing

- Offsets are relative to the current camera, not absolute anatomical azimuths. A positive angle follows a right-handed rotation about the selected **world** axis; decrease the end angle to reverse direction.
- Each view orbits its own target. Position and up-vector are calculated from the base camera for each frame, avoiding accumulated drift and pole singularities. Multiple views retain equal camera distance/scale and fixed, non-overlapping axes rectangles.
- Frame count is `round(duration × fps)`; actual duration is count/fps. A full ±360° orbit omits the duplicate endpoint; partial orbits include both endpoints. Playback looping depends on the external player.
- Safe Fit changes **only the export copy**: it centers geometry, uses orthographic projection and a rotation-safe bounding radius shared across views. This can make the brain smaller than the current canvas. Without Safe Fit, projection, target, distance and view angle are preserved.
- Camera-relative lights follow the orbit. Static anatomical orientation labels are omitted because they could become misleading during rotation. Node labels may extend beyond the geometry-fitting bound.

This is a camera animation of a static dataset. It does not animate time-varying connectivity, reconstruct fibers, register anatomy or alter scientific coordinates.

Background and styles come from the applied Scene settings, not the Light/Dark interface theme. The private renderer uses full quality, so a simplified interactive canvas is not a pixel-exact preview of the movie.

## Formats and bundle contents

| Format | Output | Notes |
|---|---|---|
| MP4 | `movie.mp4` | MATLAB MPEG-4 profile, quality 95; shown only when available |
| AVI | `movie.avi` | Motion JPEG AVI, quality 95; typically larger |
| PNG | `frame-000001.png`, etc. | Lossless image sequence, one file per frame |

Every bundle also contains `preview.png` and `provenance.json`: full Scene, prepared-data fingerprints, original and orbit-base cameras, plan, per-frame angles/hashes, renderer/MATLAB version and verified frame count. Video frame hashes refer to **pre-encoding PNG bytes**, not decoded lossy pixels. The final video has its own file hash. Original input files are not copied; paths/metadata may be private and should be reviewed before sharing.

Video outputs are decoded before publication to verify frame count and dimensions. Files are staged under a unique sibling folder; the complete bundle is then moved without replacement. The renderer consumes already prepared numeric data, not freshly reread input files; hashes describe that snapshot. Cross-platform pixel identity and codec availability are not guaranteed.

Limits: 128–3840 pixels per dimension, 1–60 fps, 2–1800 frames, up to 120 requested seconds and one billion total frame-pixels. Video dimensions must be even. This build supports a nonzero orbit of at most 360°; transparency and audio are not included.

## MATLAB API

After rendering in an existing app:

```matlab
record = app.exportMovie("D:/results/orbit-01", ...
    Format="mp4", Width=960, Height=720, ...
    Duration=5, FrameRate=24, Axis="z", ...
    StartAngle=0, EndAngle=360, SafeFit=true);
```

GUI-independent use: `brainnet.export.MovieExporter.export(renderer, scene, prepared, newFolder, ...)` accepts the same options plus `Cancel=@() false` and `Progress=@(done,total) []`. The renderer must have a valid current camera and the prepared data must match the Scene input/mapping key. The API never overwrites an existing bundle.
