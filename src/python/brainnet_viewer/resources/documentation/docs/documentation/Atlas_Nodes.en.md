# Generate nodes from a label atlas

[中文](Atlas_Nodes.zh-CN.md) · [Manual](../manual/en/index.md)

Choose **Tools → Generate Nodes from Atlas...** in the English desktop App.

1. Browse to a discrete integer NIfTI atlas (`.nii`, `.nii.gz`, or NIfTI `.hdr/.img`, including compressed pairs). The independent reader supports NIfTI-1/2 without SPM. Pure Analyze 7.5 and probabilistic/4-D atlases are not supported here.
2. Leave Region IDs blank for all nonzero IDs in ascending order, or enter distinct existing IDs separated by spaces/commas to retain that order. Negative IDs are allowed; zero is background. Ranges/expressions and automatic region-name lookup are not supported.
3. Set constant Color / module and Size value, then **Review Atlas**. Both default to **0**, matching the original `BrainNet_GenCoord`. Zero size does not guarantee visibility: choose an appropriate value or Uniform node sizing when rendering.
4. Inspect counts, affine method, coordinates and source fingerprints. Declare the affine's coordinate space and units and confirm that you verified them. These declarations do not transform coordinates. Editing input/options requires a new review.
5. **Save New .node...** writes a new file only. Existing destinations are rejected; cancellation writes nothing. Changed header/image sources require review again. Neither source atlas nor current Scene is modified.
6. Load through **Node Coordinates**, configure, then render. An accompanying edge matrix must follow the selected region order.

## Scientific meaning and limits

For each label, the unweighted mean of **one-based voxel-centre indices** is transformed by the reader's corresponding one-based affine. This preserves the legacy centroid rule, including sheared/reflected affines, without an added half-voxel offset. The reader resolves the affine; the tool does not register data, infer MNI/mm, resample labels or snap centroids inside regions. A disconnected/concave region's centroid can lie outside it. The reader applies intensity scaling before integer-label validation.

Each row is `X Y Z module size label`; label is the original numeric region ID. All nodes share the selected module/size constants. A `#` JSON comment records source paths/SHA-256 (both paired members), region order/counts, centroid rule, affine, declared space/units and timestamp. Review paths before sharing. Modern node import accepts comments; every external `.node` reader has not been certified.

Voxel grouping uses million-element chunks instead of rescanning the atlas per region. Reading and initial unique-label detection still use the full atlas: this is not streaming, multi-core or GPU acceleration; no benchmark speedup is claimed. Up to 100,000 labels are accepted. The window previews the first 100 nodes but saves all reviewed nodes. No settings schema change or automatic Scene loading.
