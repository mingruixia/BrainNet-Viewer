# Atlas and statistical ROIs

In **Volume / ROI**, enable Display and choose **ROIs (Atlas / Statistical)**.
Use the shared **Apply** / **Revert** controls.

| Threshold Mode | Meaning of ROI Selection |
|---|---|
| None | Original positive integer atlas labels, unchanged; threshold and cluster size ignored |
| Value | Connected components of finite nonzero voxels with `abs(value) >= abs(threshold)`; no minimum-size filter |
| Cluster | Same value threshold, then remove components smaller than Cluster Size (voxel count) |
| P Value | Convert supported NIfTI T/F/R/Z metadata to an uncorrected statistic cutoff, then remove components smaller than Cluster Size |

Value, Cluster and P Value assign consecutive IDs starting at 1 in MATLAB `bwlabeln`
component order **after filtering**, not size order. IDs are local to these settings:
changing the threshold, minimum size or 6/18/26 connectivity can change them.
ROI Selection applies to these IDs; Draw All selects all surviving components.
Positive and negative neighbours are connected together, matching the legacy
nonzero-mask rule. This is not separate positive/negative inference.

Equality is retained for both statistic and cluster-size thresholds. Zero is
background even at threshold zero. NaN/Inf are excluded before connectivity.
Cluster sizes 0 or 1 keep all nonempty components. Statistical values are replaced
by cluster IDs for mesh generation; surface mapping retains filtered statistic values.
The original input and spatial affine are not modified. Preparation provenance
records the representation, filtering, sign policy and surviving voxel counts.

## Migration and limitations

- Use **Cluster**, including with statistic threshold zero, to reproduce the old
  statistical ROI value-plus-size filtering. The old runtime `surf.test` flag is
  not part of an EC-only configuration. Verify the data type and all settings
  after importing EC; automatic metadata-based statistical detection is not added.
- Previous development versions ignored threshold options in the ROI branch.
  Existing ROI scenes with Value/Cluster now change intentionally; use None for
  an atlas. Serialized field names and Settings schema 1.14 are unchanged.
- ROI P Value now uses the same NIfTI description/intent conversion as Surface Map,
  with the legacy ROI Cluster Size filter after voxelwise thresholding; see
  [M09](../manual/en/M09_Volume_Mapping.md) and [M10](../manual/en/M10_ROI_Inspection.md).
  This does not establish cluster-level significance or correct for multiple comparisons.
  The current version supports [ID-bound custom ROI colors](ROI_Colors.en.md), with no missing-color fallback.
- The current version supports [boundary closure and whole-ROI unsmoothed fallback](ROI_Geometry.en.md).
  Inspect `roi_geometry.unsmoothed_fallback_labels` and `skipped_labels`.
  The current version supports a conservative per-component survival guard with whole-ROI fallback;
  this is not full topology preservation or legacy smoothing/expansion equivalence.


