# Surface boundaries and binary masks

BrainNet Viewer 2.0 development build · development build

## Workflow

1. Load **Surface Mesh** and, for automatic/threshold modes, **Surface Map** or a volume mapped to the surface.
2. Open **Surface → Boundary**, choose a mode, set its parameters, then use the shared **Apply** to commit and render. The current panel offers None, Automatic, Threshold and Custom Mask; the older Legacy Automatic setting remains a compatibility case, not a separate current menu choice.
3. Choose **Tools → Save Surface Boundary...** after rendering. Select a new `.txt` filename; existing files cannot be overwritten.

For **Custom Mask**, select **Load Mask...**, choose a binary text file and explicitly confirm its correspondence to the loaded surface's original vertex order. **Bind to Surface** binds an imported legacy EC mask after the same confirmation. Loading/binding only stages the edit: **Revert** discards it and **Apply** submits it. Cancel leaves the settings unchanged.

![Current Automatic boundary on the owner-cleared ICBM152 AAL vertex map](../tutorials/assets/captures/tutorial04-aal/04-aal-map-full-window.png)

## Mode semantics

| Mode | Classification and selected vertices | Display |
|---|---|---|
| Modern Automatic | Integer labels if all finite values are within `1e-8` of integers and there are at most 256 distinct finite values; otherwise sign. Both finite endpoints of differing classes are selected, including zeros. | Transition lines |
| Legacy Automatic | Literal legacy finite-value rule: if `sum(T-fix(T)) ~= 0`, merge all nonzero values to 1; otherwise retain values. Select vertices of mixed-class triangles, then remove vertices whose original T is zero. | Vertex colors |
| Threshold | Classes are `T > threshold` (strictly greater). Select mixed-triangle vertices, then remove vertices whose original T is zero. | Vertex colors |
| Custom Mask | Use the supplied original-order binary mask directly. A surface map is not required. | Vertex colors |

Legacy Automatic deliberately preserves signed fractional cancellation: opposite fractions may sum to zero and therefore remain separate classes. It has no 256-label limit. This compatibility choice is **not** an improved continuous isoline method. Threshold boundaries mark vertices, not interpolated geometric isolines. Legacy/Threshold reject NaN and Inf; Modern Automatic excludes edges touching them. Custom selection is independent of mapped values.

Classification and masks use complete original geometry; all views use the same vertex selection. Vertex colors preserve the selected shading mode, and numerical mask compatibility does not imply pixel-identical old lighting or rasterization. Custom masks force full-resolution surface geometry even in interactive mode; node/edge acceleration remains available.

![Current Custom Mask controls with the owner-cleared AAL-derived mask bound to the ICBM152 smoothed surface](../tutorials/assets/captures/topic-guides/surface-custom-mask-panel.png)

## Custom mask safety and portability

Masks contain only whitespace-separated `0`/`1` tokens; `#` comments are supported. There must be exactly one value per original vertex (up to 5 million; text file up to 64 MB). The mask and a SHA-256 of ordered coordinates/faces are embedded in Settings 1.2 and saved with Scene/preset JSON. The source description is informational; replay does not reopen that path.

A matching vertex count alone is insufficient. Rendering/export reject an unbound mask or a different ordered mesh. Binding proves identity on reuse, **not** initial anatomical correspondence: the user must verify the mask's source/order before confirming. Do not rebind a mask merely to suppress a mismatch. Presets containing a mask are geometry-specific, not generic styling presets.

## Migration and compatibility

Settings 1.0/1.1 with None/Modern Automatic migrate to 1.2 with empty mask fields; existing valid camera bindings are migrated only after checking the original signature. Stale cameras are not rebound. Old JSON selecting previously unimplemented Threshold/Custom without the new parameters is rejected for explicit review.

Legacy EC boundary codes 2/3/4 import as Legacy Automatic/Threshold/Custom, preserving `EC.msh.boundary_value` for the latter two. Missing values are rejected; EC custom masks require explicit surface binding. The legacy rendering fallback rejects Modern Automatic and geometry-bound Custom to avoid silent semantic substitution. Use the modern backend; legacy EC conversion alone does not preserve geometry binding.

## Output and independent API

The output has two `#` comment lines followed by exactly one binary value per original vertex. The second line contains provenance JSON: selected mode/threshold, algorithm, Scene/input/dependency hashes and geometry/value fingerprints. An all-zero mask is valid. `transition_edges_computed` is false for vertex-color modes; their zero `transition_edges` is not a measured absence of boundaries. Local paths and Scene metadata may appear; review before sharing.

```matlab
dataRoot = "D:/data";
scene = brainnet.io.readScene("D:/results/scene.json");
data = struct();
for k = 1:numel(scene.Inputs)
    ref = scene.Inputs{k};
    data.(char(ref.Role)) = brainnet.io.readInput(ref, dataRoot);
end
planner = brainnet.render.RenderPlanner;
prepared = planner.prepare(scene, data, ComputeBackend="cpu");
record = brainnet.io.writeBoundary(scene, prepared, ...
    "D:/results/boundary.txt", dataRoot);
```

The Scene must select a supported non-None mode and have verified input hashes. In a rendered app, use `app.saveBoundaryFile(path)`. Saving leaves settings/camera unchanged. It verifies the preparation key, rereads/recomputes inputs, checks exact read-back and dependencies, then publishes without replacement. This adds I/O/computation; it is not a filesystem snapshot or evidence of anatomical registration. App data inputs remain subject to the configured data root.
