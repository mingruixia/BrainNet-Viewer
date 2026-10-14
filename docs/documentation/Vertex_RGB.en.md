# Per-vertex RGB and independent Double Brain colors

Select a surface in Data Sources. In **Surface**, set **Double Brain** first if needed, then choose **Load RGB...**. Confirm that rows follow the loaded surface's original vertex order. This stages **Vertex RGB** color mode; use the single global **Apply** to commit and render. **Revert** discards uncommitted changes. **Bind RGB** confirms a previously loaded/imported table against the current surface; it cannot detect an initially incorrect correspondence.

## Text format

Whitespace-separated TXT, exactly three finite values per nonempty row, in **[0,1]**. Spaces/tabs and `#` comments are supported. No header, row IDs, alpha column or 0–255 auto-conversion. Malformed rows are rejected, not silently skipped. Limits: 1,000,000 RGB rows and 64 MiB per text file.

```text
# Red, green, blue for three successive vertices
1 0 0
0 1 0
0 0 1
```

For a surface with N vertices, single-brain mode requires N rows. Double Brain requires 2N: first N for brain 1, next N for brain 2, both following the SAME original surface vertex order. RGB order is separate from the node-row grouping used by [Double Brain](Double_Brain.en.md). Changing brain count requires a matching table or choosing Uniform. This is surface color, not a statistical map or registration method.

## Rendering and safety

- Binding fingerprints ordered surface coordinates AND faces. A changed/reordered mesh or wrong row count is rejected before replacing the current render. Geometry matching cannot establish the original anatomical correspondence; the user must confirm it.
- Original mesh resolution is retained while Vertex RGB is active, including Interactive performance mode. No vertex decimation or guessed color resampling occurs; large surfaces can therefore render more slowly.
- RGB bypasses the scalar colormap and surface colorbar. Global interpolation/flat/faceted shading and lighting still affect appearance. All supported multi-view layouts subset colors using original vertex indices.
- Custom boundary masks override only marked vertices. In Double Brain, unmarked vertices retain each brain's own RGB table; source coordinates and Inspect remain unchanged.
- Settings 1.18 embeds the table, binding and source description in Scene/preset JSON. The original TXT is not required for replay, but the surface is. Larger tables increase JSON and export-metadata size.
- EC import/export preserves `msh.color_table` and `doublebrain`. Imported EC tables require explicit binding; their original correspondence is not assumed. A nonempty color table with custom surface coloring and no map context becomes Vertex RGB. Modern Batch Renderer is required for bound RGB; the legacy adapter rejects it explicitly. Check the resulting appearance when using the exported EC in an older renderer.

Old configurations migrate with an empty table. A previously stored `vertex-rgb` mode no longer silently becomes Uniform: load and bind colors or explicitly choose another mode. RGB is not enabled automatically in old Scenes.
