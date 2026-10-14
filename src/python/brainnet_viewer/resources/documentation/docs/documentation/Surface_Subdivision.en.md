# Subdivide a surface to NV

[中文](Surface_Subdivision.zh-CN.md) · [Manual](../manual/en/index.md)

Choose **Tools → Subdivide Surface to NV...** to make a new, denser ASCII `.nv` from one supported surface. This is a geometry-changing operation; it does not replace the active Scene or source file.

1. Select one `.nv`, `.pial`, `.mesh`, BYU `.g`, MNI/BIC `.obj`, `.mz3/.mz3.gz`, or `.gii/.gii.gz` surface and select **Review**.
2. Choose 1–3 levels. Each level inserts one shared midpoint per undirected triangle edge and replaces every triangle with four triangles. Level 1 gives 4× faces; level 2, 16×; level 3, 64×. Coordinates are linear midpoints; no smoothing, curvature preservation, registration, resampling, normal generation, decimation or repair occurs.
3. Review source/hash and predicted counts. The default limit is 5 million vertices and 10 million triangles; outputs above these limits are rejected before allocation/publishing. Large outputs need substantial memory.
4. Space, units and note are optional. Blank remains `unknown`; no MNI/mm inference or transformation occurs. Confirm that colors, scalar maps, materials, normals, labels and active GIfTI transforms are not transferred.
5. **Save New .nv...** writes only a new file. It uses 17-significant-digit geometry, exact read-back validation, source/external-array fingerprints and no-overwrite publication. Load the result through **Surface Mesh** when ready.

## Method and compatibility

Subdivision adds vertices and faces by linear interpolation. It is separate from the Render Detail setting and does not preserve per-vertex scalar or attribute correspondence. Establish a new correspondence before combining the result with existing nodes, edges or volume maps.

The second `#` line contains JSON provenance: source and dependency hashes, input and output counts, counts at each level, method, optional declarations and timestamp. Review absolute paths before sharing. The source is checked before saving, but can still change after the final check. This utility does not provide GPU or multicore acceleration.
