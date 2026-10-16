# Display and statistical interpretation

[中文](Scientific_Interpretation.zh-CN.md) · [Manual](../manual/en/index.md)

BrainNet Viewer controls how supplied data are displayed. A display threshold,
color or marker size does not establish anatomical correspondence or statistical
significance. Retain the input data, Scene and export provenance alongside figures.

## Surface values and missing data

For a scalar surface map, exact zero and nonfinite values use the base surface
color. Finite nonzero values, including values close to zero, use the selected
colormap. The legend describes the continuous numeric scale; it does not reserve
an entire color bin for zero. The input scalar array is not rewritten.

Volume mapping has separate **Adjust Null** and positive/negative display limits.
Those controls should not be interpreted as a test for statistical significance.

## P values and clusters

**P Value (Uncorrected)** converts supported NIfTI statistical metadata to a
voxelwise cutoff. T, R and Z use a two-sided test; F uses the upper tail. Selecting
only positive or negative values changes the display, not that test definition.
Neither FDR nor family-wise error correction is applied.

Cluster Size removes components smaller than the chosen number of voxels when
cluster filtering is active. It is an extent filter, not a corrected cluster
P value. Adjacent positive and negative retained voxels currently belong to the
same component under the selected connectivity rule. Report these settings if
they affect a published figure.

## Networks and marker size

Sparsity selects a fraction of the eligible nonzero off-diagonal connections,
using the upper triangle for undirected matrices. It is not density relative to
all possible node pairs. Equal weights at a count boundary are resolved by
column-major matrix order; small changes in node order can therefore change
which tied connections are shown. Threshold selection keeps all ties meeting
the cutoff. No symmetry correction is applied to an asymmetric matrix.

Mapped node size can shift and repeatedly log-compress the input before mapping
it to radii from 2 to 7; constant values give radius 4. Scale then multiplies the
radius. Radius, projected area and sphere volume do not encode the same quantity.
Use [the size rules](Node_Sizes.en.md) when describing a figure, particularly when
comparing datasets with different input ranges.

## Anatomical space

RAS coordinates and millimetres describe axes and units, not a registration to
MNI space. Check the reference image, affine and hemisphere correspondence before
combining datasets. Inter-hemisphere edge filtering uses the sign of X; points
at X = 0 are not excluded as same-side pairs. This rule assumes a suitable
midline and must not be used to infer registration from coordinates alone.
