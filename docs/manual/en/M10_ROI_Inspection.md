# M10 · Atlas and statistical ROIs

[中文](../zh-CN/M10_ROI_Inspection.md) · [Manual index](index.md) · [Statistical ROI rules](../../documentation/Statistical_ROI.en.md) · [Bilateral AAL insula tutorial](../../tutorials/en/06_AAL_Insula_ROIs_and_Inspection.md) · [AAL map Inspect exercise](../../tutorials/en/04_Vertex_Maps_and_Boundaries.md)

Set **Display Volume** on and choose **Volume Type → ROIs (Atlas / Statistical)** to draw atlas or statistical regions. **Apply** commits and renders; **Revert** discards pending edits. ROI identifiers are labels, not continuous quantitative values.

The shared threshold controls are above **Surface Mapping** in the Volume panel, not inside that surface-only section. In ROI mode, P Value and Cluster Size are enabled together; Statistical Threshold is used by Value/Cluster instead.

## ROI controls

| Control | New-settings default | Current rule |
|---|---|---|
| **Threshold Mode** | None | None preserves positive integer atlas IDs. Value and Cluster construct connected regions with `abs(value) >= abs(Statistical Threshold)`; Cluster also removes components smaller than Cluster Size. P Value converts supported NIfTI T/F/R/Z metadata into a statistic cutoff, then applies Cluster Size before assigning ROI IDs. |
| **Statistical Threshold / P Value / Cluster Size / Voxel Connectivity** | 0 / 0.05 / 0 / 18 neighbors | Value/Cluster use the numeric threshold; P Value requires `0 < P < 1` and valid statistic metadata. T/R/Z are two-sided; F is upper-tail only. P Value and Cluster use Cluster Size in voxels, not mm³. Zero and nonfinite voxels are excluded; choose 6, 18 or 26 connectivity. |
| **Draw All ROIs** | on | Draws every valid positive ID. While on, **ROI Selection** is disabled. |
| **ROI Selection** | empty | Turn Draw All off to enter positive IDs separated by spaces or commas. Typing a nonempty list also turns Draw All off. Atlas mode uses source IDs; statistical Value/Cluster/P Value modes use newly assigned, consecutive component IDs, which can change with thresholds, Cluster Size or connectivity. |
| **ROI Color Mode** | Label Index | Uniform uses one ROI Color; Label Index cycles the selected categorical ROI Palette by ID; Custom requires an explicit `ROI_ID R G B` table. Color modes do not redefine region membership. |
| **ROI Palette** | HSV | Label Index can choose any named palette, including Viridis, Plasma, Inferno, Magma and Cividis. Its 256 colors cycle by positive ROI ID; this is **categorical indexing**, not a continuous quantitative colorbar. HSV and Lines generally separate categories better than sequential gradients. |
| **Show ROI ID Legend** | off | Optional ROI ID/color key in the first rendered view; at most 16 entries are shown, with an overflow count. It is not a value colorbar. |
| **ROI Color / Load ROI Colors... / Custom table** | `[0.8 0.2 0.2]` / no table | ROI Color applies in Uniform. For Custom, enter or load rows `ROI_ID R G B`, unique positive integer IDs and finite RGB in [0,1]. Every selected ID present in the volume needs a color; missing rows cause an error rather than a fallback. |
| **ROI Smoothing / Smoothing Kernel** | Gaussian / 3 | None, Box or Gaussian. Kernel is in voxels; 1 disables smoothing, and larger effective odd kernels soften boundaries. This is display mesh smoothing, not a change to the stored volume or scientific cluster IDs. |

ROI P Value follows the legacy sequence: convert P to a statistic cutoff, discard subthreshold/nonfinite voxels, remove components smaller than Cluster Size, then number surviving components. Positive and negative T/R/Z voxels in contact can form one ROI; F excludes negative values. The cutoff, degrees of freedom, metadata source, removed clusters and resulting IDs are recorded in preparation provenance. Missing/contradictory metadata raises an error. This is an **uncorrected voxelwise threshold**; Cluster Size does not by itself establish cluster-level significance, and no multiple-comparison correction or registration is performed. An atlas should normally use None, not P Value.

ROI meshes use a 0.5 isosurface and a virtual zero halo to close regions touching volume borders. Smoothing checks each original 26-connected component and conservatively falls back to the whole original ROI if one would disappear. This does **not** guarantee volume, thin-branch or full topology preservation. Active smoothing with kernel >1 requires Image Processing Toolbox (`bwconncomp`); without it choose None or kernel 1. See [ROI geometry](../../documentation/ROI_Geometry.en.md), [custom colors](../../documentation/ROI_Colors.en.md) and [statistical numbering](../../documentation/Statistical_ROI.en.md). Recheck a Custom table whenever statistical filtering changes IDs. Automatic atlas/statistic classification is not provided.

For surface and node picking, see [Inspect in the Surface chapter](M06_Surface.md#inspect-on-the-rendered-canvas). ROI meshes are not Inspect pick targets.
