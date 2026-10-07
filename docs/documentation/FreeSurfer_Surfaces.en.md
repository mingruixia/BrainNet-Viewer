# FreeSurfer surfaces (.pial)

BrainNet Viewer 2.0 development build · development build · 2026-09-06

## Desktop workflow

1. Launch BrainNet Viewer. Under **Data Sources → Surface Mesh**, select a `.pial` file; **Add Files** also recognizes this extension.
2. Read the **Scene** note: **FreeSurfer coordinates as stored; verify registration**. The file is checked before replacing the selected surface.
3. Adjust **Visualization Settings → Layout / Surface**, then select **Render Scene**. For a single hemisphere, start with **Single View** and use **Fit** as needed.
4. Use **Save Scene** for later replay, or **Export Figure** for images. Existing PNG/JPEG/TIFF/BMP/PDF/SVG export rules apply.

Custom export dimensions preserve brain proportions and add background margins when the canvas aspect ratio differs. Raster output uses the requested pixel dimensions (physical dimensions are converted using DPI and rounded to pixels); rounding corrections pad the canvas without cropping or stretching the brain.

A malformed new `.pial` is rejected before current input references or loaded arrays are replaced. Existing graphics are not closed during this file-selection preflight. An error may be displayed; this does not turn the invalid input into a selected mesh. Batch imports through Scene JSON still follow the existing explicit Scene selection/loading workflow.

## Supported encodings

| Encoding | On-disk geometry | Handling |
|---|---|---|
| Triangle, magic 16777214 | Big-endian float32 coordinates; int32 zero-based triangles | Coordinates and face order retained; indices become one-based |
| Old quad, magic 16777215 | Big-endian int16 coordinates scaled by 1/100; uint24 indices/counts | Official FreeSurfer quad split, preserving vertex order |
| New quad, magic 16777213 | Big-endian float32 coordinates; uint24 indices/counts | Same quad split |

Quad splitting follows the current FreeSurfer C++ `WHICH_FACE_SPLIT` decision using both initial zero-based vertex IDs. Triangles with repeated indices that arise from degenerate quad encodings are removed, as in that implementation. This can differ from NiBabel's historical first-index-parity split; NiBabel is used as the independent oracle for the **triangle** standard sample, not the quad split.

The desktop/Scene dispatch in this step accepts `.pial` only for this reader. Other FreeSurfer suffixes, ASCII surfaces, patch files and `.pial.gz` have not been added to the UI or advertised as supported. Do not rename a patch/ASCII/compressed file and assume it becomes compatible.

## Coordinate and metadata boundary

Coordinates are retained as stored. Typical FreeSurfer cortical surfaces use surface RAS in millimeters, which is not automatically scanner RAS or MNI space. No registration, reflection, centering, or footer transformation is applied. Confirm the coordinate system before combining a surface with nodes, volumes or atlases; successful loading is not proof of alignment. See the [official coordinate guide](https://surfer.nmr.mgh.harvard.edu/fswiki/CoordinateSystems).

The returned `SurfaceData.Metadata` / second output records encoding, counts, indexing, creation stamp, removed quad triangles and trailing-byte count. Trailing volume geometry/tags are explicitly **not interpreted or applied**, even when present. GUI-selected files also save this information in the input reference metadata when saving a Scene. Manually authored Scene JSON retains the caller's metadata; the reader does not silently rewrite it.

Default safety limits are 10 million vertices and 20 million output triangles; both may be changed explicitly through the reader API. Counts are checked against remaining file bytes before allocation. Triangle comment lines are limited to 4096 bytes each. Non-finite coordinates, out-of-range indices, unsupported signatures and truncated geometry are rejected.

## MATLAB and CLI

```matlab
reference = brainnet.core.InputReference("surface", "subject/lh.pial");
[surface, info] = brainnet.io.readFreeSurferSurface(reference, "D:/my-data");
% surface.Coordinates is 3-by-N; surface.Faces is F-by-3, one-based.
scene = brainnet.core.Scene("LH_PIAL", "Left pial surface", 1, 0, {reference});
brainnet.io.writeScene(scene, "left-scene.json", "D:/my-data");
BrainNetRender("left-scene.json", "left.png", DataRoot="D:/my-data", ...
    ComputeBackend="cpu", Width=1200, Height=900);
```

The reader is MATLAB code only; it does not call SPM, FreeSurfer, NiBabel or a MEX library. NiBabel is used only for development validation. The standard fsaverage fixture and its license/source notices are in `tests/fixtures/freesurfer`; it is not automatically included in release packages.
