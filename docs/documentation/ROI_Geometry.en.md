# ROI boundaries and small-ROI smoothing

development build adds a virtual zero-background halo outside each ROI bounding box,
including outside the input volume. This closes surfaces at volume faces, edges
and corners. World positions retain the original one-based voxel affine; no
translation or resampling is applied to the input.

Meshes use the **0.5 isosurface**, not a union of voxel cubes. A boundary voxel can
extend half a voxel beyond its center and beyond the input center-coordinate range.
Singleton dimensions are treated as one-voxel-thick slabs.

Box/Gaussian smoothing still uses the configured odd kernel (even sizes round up;
size 1 disables smoothing). focused check checks each original **26-connected component**:
each must retain at least one original voxel with smoothed value strictly above
0.5. Otherwise, the **whole ROI** falls back to its original unsmoothed 0.5 surface,
including its large components. No component is dilated or separately patched in.
If all components pass, smoothing is retained. The check is conservative, not an
exact surface-correspondence test. This connectivity is a geometry guard, not the
6/18/26 setting used to define statistical clusters; IDs and selection do not change.

Active smoothing (kernel greater than 1) requires `bwconncomp` from Image Processing
Toolbox. If unavailable, rendering fails explicitly; choose None or kernel 1 to
render without smoothing or this dependency. Protection is not silently disabled.

Inspect preparation provenance under `roi_geometry`:

- `boundary_policy`: `virtual-zero-halo`;
- `effective_smoothing_kernel` and `isosurface_level`;
- `unsmoothed_fallback_labels`: IDs rendered without smoothing;
- `component_checks`: original component counts, at-risk component ordinals and
  their original voxel counts, per ROI (ordinals are not atlas/cluster IDs);
- `component_guard_connectivity` and `component_guard_rule`;
- `skipped_labels`: IDs still producing no mesh.

Colors, ID selection, statistical thresholds and original arrays are unchanged.
This is **not** legacy mesh/pixel equivalence. Smoothing can still shrink shapes,
merge components, split them, or remove thin branches within a component even
when the guard passes. This is not complete topology or volume preservation.
Old scenes may show newly closed boundaries or previously missing small ROIs;
review their geometry after updating/restarting the app. Settings remain 1.16.

