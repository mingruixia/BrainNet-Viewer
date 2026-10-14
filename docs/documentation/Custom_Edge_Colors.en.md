# Custom edge colors

[中文](Custom_Edge_Colors.zh-CN.md)

1. Load the original node and edge files; select **Edges > Color Mode > Custom Matrix**.
2. **Load Colors...** accepts whitespace `.txt`/`.edge` matrices (optional `#` comments) or JSON with `matrix`, `indices`, `colors`. Confirm that rows/columns follow the original node order. Loading stages settings; the global **Apply** commits and renders.
3. Text files map sorted unique category values (including zero) to the current palette. JSON preserves the supplied category order and RGB rows. Named palettes generate at least two colors; numeric palettes use their first K rows without interpolation and need at least K rows. A single JSON RGB color is internally duplicated, without changing its category color.
4. Existing EC imports are unbound: use **Bind to Nodes**, confirm, then Apply. **Revert** discards staged changes. Save Scene/Save Preset embeds the matrix, category order, palette and binding.

For directed edge i→j, the category is matrix(i,j); j→i may differ. The category list selects the RGB row by exact numeric equality. Duplicate category keys, invalid RGB, non-square/nonfinite matrices, count mismatches, missing bindings and unmapped categories on selected edges are rejected. Unused cells may contain unmapped categories. Colors do not select edges or modify their weight, size or opacity.

Limits: 4 million matrix entries, 4096 categories, 64 MB input file. Custom colors are not subject to the separate 20-module limit. For three nodes in the corresponding order, save either example below as a `.txt` or `.json` file. These are documentation examples, not bundled test fixtures.

```text
# Directed categories, including zero as an explicit category.
0 -2 7
7 0 -2
-2 7 0
```

```json
{"matrix":[[0,-2,7],[7,0,-2],[-2,7,0]],"indices":[7,-2,0],"colors":[[1,0,0],[0,0,1],[0.5,0.5,0.5]]}
```

Settings **1.11.0** adds `edge.custom_color`. Older Custom settings had no usable matrix; they upgrade with empty data and cannot render until actual data is loaded/bound. EC color=6 imports/exports actual `color_custom_matrix`, `color_custom_index`, `CM` (also writes CM_custom), without executing expressions. Missing EC data is rejected. EC does not preserve the modern binding, so reimport requires confirmation. The App requires Modern Batch Renderer for Custom.

The binding records **node coordinates in their original order**. It detects subsequent changes in coordinates or ordering, but cannot establish the initial anatomical correspondence or distinguish coincident nodes. A preset must be bound explicitly to a new node set. Saved camera bindings are retained only when their original signatures remain valid. Saved files may contain source paths; review these before sharing.
