# M09 · Volume-to-surface mapping and statistical controls

[中文](../zh-CN/M09_Volume_Mapping.md) · [Manual index](index.md) · [Signed color-axis rules](../../documentation/Volume_Display.en.md) · [Real T-map tutorial](../../tutorials/en/05_Volume_to_Surface_Mapping.md)

Use **Visualization Settings → Volume** to map a 3-D NIfTI onto a surface. A readable NIfTI is not automatically aligned with a separately loaded surface. Mapping transforms surface coordinates by the volume affine to sample voxels; it does **not** perform image registration. Verify the surface/volume coordinate spaces and units before interpreting locations. **Apply** commits settings and renders; **Revert** discards pending changes.

In the Volume panel, **Threshold Mode**, **Statistical Threshold**, **P Value**, **Cluster Size** and **Voxel Connectivity** appear above the **Surface Mapping** section because they also govern statistical ROIs. Controls enable according to Volume Type and Threshold Mode; ROI P Value uses Cluster Size, while Surface Map P Value does not.

| Control | New-settings default | Current rule |
|---|---|---|
| **Display Volume** | off | Enables the chosen Volume Type. A newly loaded file does not by itself establish scientific suitability. |
| **Volume Type** | Surface Map | Surface Map maps a 3-D volume onto a loaded surface; **ROIs (Atlas / Statistical)** extracts labelled meshes and uses the M10 controls. |
| **Mapping Algorithm** | 2 | Used for Surface Map only. The eight algorithms below have different numerical meanings, not a simple low/high-quality order. |
| **Threshold Mode** | None | None keeps values; Value keeps finite values with `abs(value) >= abs(Statistical Threshold)`; Cluster adds a minimum connected-component size. P Value converts supported NIfTI statistical metadata into a voxelwise cutoff. In ROI mode it also applies Cluster Size; see M10. |
| **Statistical Threshold / P Value / Cluster Size / Voxel Connectivity** | 0 / 0.05 / 0 / 18 neighbors | Value and Cluster use the numeric threshold; Cluster also uses voxel count and 6/18/26 connectivity. P Value requires `0 < P < 1` and valid statistic metadata. The original volume is not rewritten. |

For Value/Cluster, zero is background, nonfinite voxels are excluded, equality at the absolute-value threshold is retained, and Cluster removes components **smaller** than Cluster Size. The 6/18/26 selection defines statistical connectivity; it is not the separate 26-connected safety check used in ROI smoothing. Cluster filtering can change the values available for later mapping and the resulting color range. See [statistical ROI rules](../../documentation/Statistical_ROI.en.md).

For P Value, the reader uses the NIfTI description from SPM, REST or DPABI (`SPM{T_[20]}`, `REST{F_[3,20]}`, `DPABI{R_[20]}`, or a Z token); a standard NIfTI CORREL/TTEST/FTEST/ZSCORE intent and its parameters are a fallback. Missing or invalid degrees of freedom cause an error, never a silent numeric-threshold fallback. T, R and Z use **two-sided** uncorrected P; F uses the **upper tail** and excludes negative F values. The resulting statistic cutoff, degrees of freedom, tail and metadata source are recorded in render preparation/provenance. P filtering occurs **before** mapping; interpolation or neighborhood smoothing can subsequently change vertex values, so a displayed vertex value is not itself a voxelwise P-value test. There is no family-wise/FDR correction or spatial registration.

## Mapping algorithm (Surface Map)

| No. / menu label | Calculation and boundary caution |
|---|---|
| **1 · Nearest Voxel** | Round the transformed surface position and sample that voxel. Invalid/out-of-volume positions receive zero. |
| **2 · Average Surface Neighbors** | Take algorithm 1 values first, then average each vertex with its surface-mesh neighbors and itself. This is a surface-adjacency average, **not** a 3×3×3 voxel mean; mesh topology affects the result. |
| **3 · Average 3-by-3 Voxel Neighborhood** | Apply a 3×3×3 mean filter to the volume, then nearest-voxel sample it. Volume boundary handling follows the filter implementation. |
| **4 · Gaussian Voxel Smoothing** | Apply MATLAB `smooth3(...,'gaussian')` to the volume, then nearest-voxel sample it. This alters sampled values and may mix nearby labels/signs. |
| **5 · Trilinear Interpolation** | Interpolate the eight enclosing voxel values at an interior position; outside the supported interior returns zero. |
| **6 · Maximum 3-by-3 Voxel Neighborhood** | At a valid interior rounded position, take the maximum of 27 voxels. |
| **7 · Minimum 3-by-3 Voxel Neighborhood** | At a valid interior rounded position, take the minimum of 27 voxels. |
| **8 · Extremum 3-by-3 Voxel Neighborhood** | Choose the 27-voxel sample with greatest absolute magnitude and **retain its original sign**. |

The mapping gallery illustrates how the eight algorithms display the same input. It is not an accuracy ranking. For a discrete atlas, start with Nearest Voxel: averaging and interpolation can create values that are not source labels. For continuous statistics, algorithms 2 and 5 can give smoother displays; they respectively average sampled mesh neighbors and interpolate the volume at each vertex. Record the chosen method and compare the result with the source map before interpreting a location.

For sign and color-range choices, **Display Values** changes the signed color axis but does not remove negative or positive vertex values. If a map contains values from −3 to +6, Both mode uses a symmetric −6 to +6 axis; a +3 and a −3 therefore have comparable distance from the center even though +6 is the observed positive maximum. Positive Only or Negative Only uses the corresponding half of the palette. Change the relevant bounds only after checking the actual sampled value distribution and the displayed colorbar; do not interpret white/null color as a formal nonsignificant voxel unless the thresholding and adjustment rules warrant that interpretation.

CPU supports all eight. The current GPU mapping path supports algorithms 1 and 5 only; an explicit GPU request for the other algorithms falls back to CPU with a recorded reason. Auto chooses GPU for algorithm 5 on sufficiently large surfaces when a supported GPU is available; otherwise it uses CPU. This is an execution policy, not a guarantee of speedup on every dataset.

## Ranges and sign display

| Control | New-settings default | Current rule |
|---|---|---|
| **Positive Range / Negative Range** | Auto / Auto | Enter `Auto` or minimum and maximum (either endpoint may be Auto). Manual bounds persist when the volume file changes and are identified in Scene Summary; recheck them for each new dataset. **Auto Ranges** only resets the pending fields—click **Apply** to commit and render. |
| **Colormap** | Blue-White-Red | One 256-entry palette: its lower half represents negative values and upper half positive values. A custom RGB palette can be set with Colors.... The Surface panel's scalar-map palette is separate. |
| **Display Values** | Positive & Negative | Both, Positive Only or Negative Only changes the **color axis, not which vertex values exist**. Both uses a symmetric `[-M,+M]` axis around zero even when the data extrema differ; one-sided modes use the respective palette half. Values outside a chosen range clamp to endpoint colors. |
| **Adjust for Null / Null Color** | on / `[0.95 0.95 0.95]` | When on, the null-side palette region receives Null Color; when off, finite values use the continuous palette. Null Color is editable only when adjustment is on. This changes display, not sampled values. |

Both-mode symmetry can reduce contrast for the smaller-magnitude sign. Do not infer absence of an effect merely because one side is pale; inspect the numeric data and actual colorbar. The illustrated example uses a resting-state example map from a published study, but its alignment to a chosen surface still needs independent verification. See [signed-axis details](../../documentation/Volume_Display.en.md).

Multiple-comparison correction is **not available**. Check the source map's statistic, degrees of freedom, coordinate alignment and your analysis-specific inference policy before interpretation.
