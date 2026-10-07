# Subdivide a surface to NV

[中文](Surface_Subdivision.zh-CN.md) · [Manual](../manual/en/index.md)

Choose **Tools → Subdivide Surface to NV...** to make a new, denser ASCII `.nv` from one supported surface. This is a geometry-changing operation; it does not replace the active Scene or source file.

1. Select one `.nv`, `.pial`, `.mesh`, BYU `.g`, MNI/BIC `.obj`, `.mz3/.mz3.gz`, or `.gii/.gii.gz` surface and select **Review**.
2. Choose 1–3 levels. Each level inserts one shared midpoint per undirected triangle edge and replaces every triangle with four triangles. Level 1 gives 4× faces; level 2, 16×; level 3, 64×. Coordinates are linear midpoints; no smoothing, curvature preservation, registration, resampling, normal generation, decimation or repair occurs.
3. Review source/hash and predicted counts. The default limit is 5 million vertices and 10 million triangles; outputs above these limits are rejected before allocation/publishing. Large outputs need substantial memory.
4. Space, units and note are optional. Blank remains `unknown`; no MNI/mm inference or transformation occurs. Confirm that colors, scalar maps, materials, normals, labels and active GIfTI transforms are not transferred.
5. **Save New .nv...** writes only a new file. It uses 17-significant-digit geometry, exact read-back validation, source/external-array fingerprints and no-overwrite publication. Load the result through **Surface Mesh** when ready.

## Scope and legacy status

This is a modern, explicitly defined linear subdivision utility. The old capability audit rendering-detail requirements concerns rendering-detail controls and their persistence; no original saved-subdivision algorithm was found. Accordingly, this tool is not claimed to recreate an old rendering quality mode or to preserve scalar/attribute correspondence. Existing mesh nodes/edges/volume maps can become misaligned with the new geometry unless you establish correspondence separately.

The second `#` line contains JSON provenance: source/dependency hashes, input/output counts, level-by-level counts, method, optional declarations and timestamp. Review absolute paths before sharing. Final source fingerprint checks cannot make a filesystem snapshot. No GPU/multicore speed claim, settings/Scene-schema change, full regression or cross-platform certification is made.

