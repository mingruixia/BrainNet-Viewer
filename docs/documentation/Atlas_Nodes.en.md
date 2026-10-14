# Generate nodes from a label atlas

[中文](Atlas_Nodes.zh-CN.md) · [Manual](../manual/en/index.md)

Choose **Tools → Generate Nodes from Atlas...** in the English desktop App.

1. Browse to a discrete integer NIfTI atlas (`.nii`, `.nii.gz`, or NIfTI `.hdr/.img`, including compressed pairs). The independent reader supports NIfTI-1/2 without SPM. Pure Analyze 7.5 and probabilistic/4-D atlases are not supported here.
2. Leave Region IDs blank for all nonzero IDs in ascending order, or enter distinct existing IDs separated by spaces/commas to retain that order. Negative IDs are allowed; zero is background. Ranges/expressions and automatic region-name lookup are not supported.
3. Set constant Color / module and Size value, then **Review Atlas**. Both default to **0**, matching the original `BrainNet_GenCoord`. Zero size does not guarantee visibility: choose an appropriate value or Uniform node sizing when rendering.
4. Inspect counts, affine method, coordinates and source fingerprints. Declare the affine's coordinate space and units and confirm that you verified them. These declarations do not transform coordinates. Editing input/options requires a new review.
5. **Save New .node...** writes a new file only. Existing destinations are rejected; cancellation writes nothing. Changed header/image sources require review again. Neither source atlas nor current Scene is modified.
6. Load through **Node Coordinates**, configure, then render. An accompanying edge matrix must follow the selected region order.

## Interpretation and limitations

For each label, the unweighted mean of **one-based voxel-centre indices** is transformed by the reader's corresponding one-based affine. This preserves the legacy centroid rule, including sheared/reflected affines, without an added half-voxel offset. The reader resolves the affine; the tool does not register data, infer MNI/mm, resample labels or snap centroids inside regions. A disconnected/concave region's centroid can lie outside it. The reader applies intensity scaling before integer-label validation.

Each row is `X Y Z module size label`; label is the original numeric region ID. All nodes share the selected module/size constants. A `#` JSON comment records source paths/SHA-256 (both paired members), region order/counts, centroid rule, affine, declared space/units and timestamp. Review paths before sharing. Modern node import accepts comments; other `.node` readers may have different comment-handling rules.

Voxel grouping processes one million elements at a time, avoiding a separate atlas scan for each region. Reading the atlas and finding its unique labels still require the full volume in memory. The operation does not use streaming, multiple CPU cores or GPU acceleration. Up to 100,000 labels are accepted; the window previews the first 100 nodes and saves all reviewed nodes. Load the saved file explicitly to use it in a Scene.
