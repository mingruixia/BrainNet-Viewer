# Migrating from BrainNet Viewer 1.7/1.8

[中文](Migration.zh-CN.md) · [Manual M15](../manual/en/M15_Migration_Troubleshooting.md)

## Practical migration route

1. Preserve the old data and EC MAT configuration. Start the modern project-root `BrainNetViewer` launcher without recursively adding the old program to the MATLAB path. Use Data Sources → **Validate and Load** for input roles, or **Open Scene JSON** for a modern Scene. Local files are read directly. Save ordinary JSON references, or choose a portable ZIP when moving the inputs.
2. Replace `BrainNet_Option.fig` with the right-hand Visualization Settings. The shared **Apply commits and renders**; Revert discards pending edits. Render Scene explicitly redraws; Clear Figure clears only views; camera Reset is not Restore Defaults.
3. Use **Import Settings** only for a trusted EC MAT. Review its `fields_requiring_review`, data roles, `.node` columns 4/5, threshold equalities, module colors, ROI/statistical mode and spatial assumptions before saving a new Scene. A mapped field is not proof of identical scientific meaning or pixels.
4. Use **Save Scene** to preserve one analysis's input references/hashes and applied settings (with optional modern camera/export state). Use **Save/Load Preset** to carry display settings across datasets **without** input paths, camera or export-panel preferences. Neither file grants resource redistribution rights.
5. For geometry, Tools offers Merge Surfaces (2–64), Convert Surface to NV (one), Subdivide Surface to NV and Generate Nodes from Atlas. They write reviewed **new** outputs without registration or implicit legacy `.mesh` coordinate inversion. For static automation use `BrainNetRender`, not an assumed drop-in `BrainNet_MapCfg` signature. Animation is a camera orbit of a static scene; native print is not provided.

<a id="known-limitations"></a>

## Differences requiring explicit review

- The independent NIfTI reader accepts NIfTI-1/2 and paired NIfTI header/image forms, not pure Analyze 7.5. MNI/BIC `.obj` is not Wavefront OBJ. BrainVISA `.mesh` preserves stored XYZ rather than negating all axes. FreeSurfer/MNI filenames and Inspect's AAL/Brodmann labels do **not** establish registration; Inspect does not apply an affine transform.
- Layout 2 uses the split overview when hemispheres can be identified, with a conservative whole-surface fallback for an inseparable mesh. The modern layout numbers and camera controls are described in [M04](../manual/en/M04_Layout_Camera.md).
- Node/edge coloring, sizes, filtering and threshold endpoints, signed volume colormaps and ROI generation have received targeted corrections. Old development Scenes may render differently. Use the [Nodes](../manual/en/M07_Nodes.md), [Edges](../manual/en/M08_Edges.md), [Volume](../manual/en/M09_Volume_Mapping.md) and [ROI](../manual/en/M10_ROI_Inspection.md) chapters and independent boundary-value examples before treating a migration as equivalent.
- Surface Map and statistical ROI P Value now convert supported NIfTI statistic metadata, but automatic atlas/statistic classification, multiple-comparison correction and cluster-level significance inference remain unavailable. Fiber rendering, arbitrary Plot Edit, GIF/EPS/EMF output and native print are not current capabilities. A standalone MATLAB Runtime package is not supplied. Docker/Web deployment is described in its installation guide.

Scene, image and movie provenance may include local paths and metadata. A hash establishes file identity, not anatomical alignment, statistical validity or sharing rights. For symptom-specific first checks see [M15 troubleshooting](../manual/en/M15_Migration_Troubleshooting.md#if-something-goes-wrong).
