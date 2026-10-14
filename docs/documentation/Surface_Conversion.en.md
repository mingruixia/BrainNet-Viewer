# Convert one surface to NV

[中文](Surface_Conversion.zh-CN.md) · [Manual](../manual/en/index.md)

1. Choose **Tools → Convert Surface to NV... → Choose File...**. Supported inputs: `.nv`, `.pial`, `.mesh`, BYU `.g`, MNI/BIC `.obj` (not generic Wavefront OBJ), `.mz3/.mz3.gz`, `.gii/.gii.gz`, subject to each reader's restrictions.
2. **Review Inputs** displays the source path/hash, vertex/triangle counts, index ranges and coordinate bounds. Exactly one input is required; use [Merge Surfaces](Surface_Merging.en.md) for multiple inputs.
3. Raw space, units and note are optional. Blank space/units remain `unknown`. Confirm that conversion is **geometry only**: coordinates, vertex order, triangle connectivity and winding are preserved as returned by the reader. Colors, scalar maps, materials, normals and semantic labels are not transferred; GIfTI transforms are recorded as provenance, not applied or activated.
4. **Save New .nv...** writes 17-significant-digit ASCII with exact geometry read-back before publication. Existing destinations, including the input itself, cannot be overwritten. Changed inputs/external GIfTI arrays require a new review. Cancelling file selection/save writes nothing.
5. To display the output, load it through **Surface Mesh**, configure and render. The active Scene and source are not automatically changed. Save within the App's configured data root, or use an appropriate root, as for other Scene inputs.

## Important legacy difference

The old `BrainNet_MergeMesh` single-file `.mesh` branch applied fixed `91-X, 91-Y, 109-Z` coordinates. This modern converter **does not** apply that dataset-specific assumption. It preserves reader/raw coordinates without registration, unit conversion, rescaling, mirroring, subdivision, simplification or repair. If alignment is required, establish an explicit transform separately; do not infer MNI space from the filename or extension. Geometry and topology are preserved, not every original file attribute or byte.

The second `#` comment stores JSON provenance: source/dependency paths and SHA-256, native metadata where available, counts/ranges/bounds, optional declarations and timestamp. Metadata in comments is not automatically activated by the NV reader or assigned to the Scene. Check absolute paths before sharing; conversion does not grant redistribution rights.

The default limits are 5 million vertices and 10 million triangles, checked after reading the input. The geometry and read-back copy require memory; conversion does not use streaming or GPU acceleration. Source hashes are checked before saving, but cannot prevent changes made after the final check.
