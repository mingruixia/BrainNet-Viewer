# Edge sparsity and ties

Choose a mode in **Visualization Settings → Edges → Selection**, enter a fraction from 0 to 1, then use global **Apply** to commit and render. Both sparsity modes require **Modern Batch Renderer**.

| Mode | Ranking and cutoff | Ties and endpoints |
|---|---|---|
| Sparsity (Top Count) | Nonzero off-diagonal candidates only; upper triangle for undirected, both directions for directed. Keep ceil(fraction × candidate count). | Equal weights use ascending MATLAB linear index (column-major). Fraction 0 selects none; 1 selects all candidates. |
| Sparsity (Legacy Threshold) | Rank all N×N entries, including diagonal, zeros and both triangles; round fraction × N² to an integer and clamp to [1,N²]. Convert that ranked value to a six-decimal threshold, matching the old UI. | Select nonzero, off-diagonal candidates >= threshold, retaining all cutoff ties. Fraction 0 still uses the maximum; diagonal maxima can leave no visible edges. Rounding the cutoff upward can exclude its original edge. |

Selection Values chooses Signed or Absolute ranking, without changing stored edge weights. Undirected selection uses the upper triangle; it does not average an asymmetric matrix. Hemisphere filtering happens afterward, without refilling the count. Connected nodes use the final pairs. Neither fraction promises the final density: zero entries, ties, direction, hemisphere filtering and later appearance settings can change the result. Top Count is deterministic for a fixed node order, not invariant under relabeling tied nodes. Its results in existing Scene/presets remain unchanged.

Settings **1.13.0** adds `selection_mode="legacy-sparsity"`; existing `sparsity` retains Top Count semantics. Scene/presets preserve the mode and fraction; only valid old camera bindings migrate.

Legacy EC stores a threshold, **not the sparsity fraction**. Importing EC therefore correctly yields Threshold mode; the original fraction is not recoverable. For a data-specific conversion, `settings.toLegacy(edgeMatrix)` resolves Legacy Threshold from the exact matrix and reports the loss of adaptive sparsity. Reimport yields the same selected edges for that matrix, but the threshold will not adapt to another matrix. Conversion without the matrix fails explicitly. Top Count cannot generally be represented by a threshold when ties straddle the cutoff, so EC conversion is rejected; use Scene/presets or an explicit threshold. Previous development exports that silently substituted the unrelated Threshold field cannot be repaired without their source settings/data.

 Full UI visual acceptance and complete legacy parity are separate work.
