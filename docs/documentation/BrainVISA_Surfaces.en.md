# BrainVISA surfaces (.mesh)

BrainNet Viewer 2.0 development build · development build · 2026-09-06

Select a `.mesh` under **Data Sources → Surface Mesh**, or use **Add Files**. The candidate geometry is validated before replacing the current input. Configure the right-hand sections and click the single **Apply** button at their bottom to commit **and render**; **Render Scene** can explicitly redraw. **Save Scene** and **BrainNetRender** use the same independent reader.

## Supported scope

ASCII and big-/little-endian AIMS binary encoding, `VOID` texture, one time step, triangular polygons. Optional normals are checked for count and finite values; the renderer recomputes display normals. ASCII coordinates are interpreted as the format's float32 values, like binary coordinates. Indices become MATLAB one-based without reordering vertices or faces.

Multi-time-step files, line segments, quadrilaterals, embedded textures, compressed `.mesh.gz`, and Medit files that also use `.mesh` are explicitly unsupported. The reader does not silently select a frame or split polygons. Vertex/face defaults are 10 million / 20 million, configurable through the reader API. Header whitespace before `VOID` is bounded to 4096 bytes. Counts and required remaining bytes are checked before array allocation; invalid tuples, nonfinite values, indices and trailing data are rejected.

## Important migration difference

**Coordinates are retained as stored.** The original BrainNet `.mesh` branch negated X, Y and Z; this modern reader deliberately does not reproduce that implicit inversion. Do not assume a legacy `.mesh` scene has the same orientation or registration. Check landmarks and alignment before combining nodes, volumes or atlases. The Scene summary displays **BrainVISA coordinates as stored; no legacy XYZ inversion; verify registration**.

Adjacent `.minf` files are neither executed nor interpreted; referential/transform metadata there is not applied. Loading succeeds only as geometry, not as proof of MNI/scanner alignment. Save Scene records this boundary. Keep original sources; this is not a lossless mesh writer.

```matlab
reference = brainnet.core.InputReference("surface", "subject/cortex.mesh");
[surface, info] = brainnet.io.readBrainVisaMesh(reference, "D:/my-data");
% Coordinates: 3-by-N, Faces: F-by-3, one-based.
```

The MATLAB runtime requires no AIMS, SPM, Python or MEX reader. Development validation used a four-vertex example from AIMS/CEA documentation and a larger cortex fixture independently converted from FreeSurfer; the latter is **not** native AIMS output. These test files are not included with this guide. Redistribution would require separate AIMS/CeCILL-B and FreeSurfer notice and license review.

## Shared settings controls

Section headers are **Layout >**, **Surface >**, etc.; expanded sections end in **v**. Switch sections without losing pending edits. **Apply** commits the pending values from all sections together; **Revert** discards all pending section edits and restores the last accepted settings. The single pair stays below the scrolling editor, including when long sections are open or all categories are collapsed. Save a preset or Scene after applying changes.
