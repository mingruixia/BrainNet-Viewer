# Inspect nodes and surface vertices

BrainNet Viewer 2.0 MATLAB desktop development build

## Desktop workflow

1. Load a Scene and click **Render Scene**.
2. Click **Inspect** in the canvas toolbar, then click a rendered node or surface. A compact label appears inside the selected view; no separate inspector window opens.
3. The label shows the source node/vertex index, an assumed-MNI XYZ coordinate, available value/module information, a **Brodmann Area**, and an **AAL region**. Click another point to replace the label.
4. Click **Inspect** again to leave picking mode and clear the label. Re-rendering or changing Scene also clears it. Pop-out views can be picked while Inspect is active.

The label deliberately omits file paths, voxel indices, atlas IDs and internal lookup methods. Programmatic results still include detailed provenance and status fields.

## Scientific limits

The desktop lookup currently assumes input coordinates already use the MNI space of the bundled AAL and Brodmann resources. **It does not check that assumption, perform registration, or apply an affine or nonlinear transform.** An atlas label for subject-native, non-human, FreeSurfer RAS, or differently scaled coordinates can be misleading. Confirm coordinate provenance before interpreting labels.

Surface selection reports the nearest displayed source vertex, not an interpolated value at the exact hit. Node selection reports the source node. Decorative boundaries, edges, arrowheads and ROI meshes do not intercept surface picks. Edge, ROI-mesh and fiber-object inspection are not supported.

The old programmatic `brainnet.query.SceneInspector.query` API still accepts explicit transform settings for internal/legacy use, but affine setup and loaded-volume label dictionaries are not currently exposed in the desktop Inspect interface. Saving a Scene preserves its existing inspection metadata; the desktop's current direct AAL/Brodmann workflow queries both atlases.

## MATLAB API

```matlab
result = app.inspectPoint("surface",[10 20 30]);
node = app.inspectPoint("node",[10 20 30],5);
```

These programmatic results include source identity, query statuses and both `aal_region` and `brodmann_area`.
