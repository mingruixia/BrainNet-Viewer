# Edge Threshold and Length colors

BrainNet Viewer 2.0 development build · development build · Settings 1.6

[中文](Edge_Colors.zh-CN.md) · [Migration](Migration.en.md) · [Colormaps](Colormaps.en.md)

## Two fixed colors, two boundary rules

| Color Mode | Low color | High color | Source |
|---|---|---|---|
| Threshold | Low (<=): value <= Color Threshold | High (>): value > Color Threshold | Original selected edge weight, with independent Signed or Absolute conversion |
| Length | Short (<): distance < Length Threshold | Long (>=): distance >= Length Threshold | Euclidean distance between the two original node XYZ coordinates |

Threshold equality belongs to Low; Length equality belongs to Long. Both modes use exactly the two chosen RGB colors. The uniform Color, Colormap and Color Limits do not determine either group. A zero Length Threshold assigns every rendered edge to Long. Lighting/transparency can change the apparent pixel color; numerical RGB checks use patch color data, not screenshots.

**Threshold Values** is independent of the selection **Value Mode**. Selection determines which edges remain; coloring uses their original signed weights, not the transformed selection measure. For example, selecting absolute weight >= 2 retains -3, 2 and 3. With Signed coloring and Color Threshold 2, -3 and 2 use Low, and 3 uses High. With Absolute coloring, -3 and 3 use High. Node radius, camera zoom, hemisphere views and directed-arrow length do not define the original node distance.

Length uses the coordinate units supplied in the node file. It is not a tract length, geodesic distance, inferred millimeter unit or white-matter measurement. Coordinate registration and units must be established independently. Both ends of a directed edge use the same edge color, including its arrowhead.

## Desktop workflow

1. Load node and edge files in Data Sources, then Validate and Load.
2. Open **Visualization Settings → Edges >**, scroll to Color, and select Threshold or Length.
3. For Threshold, choose Threshold Values and Color Threshold. For Length, set Length Threshold. Inactive palette/limit controls and the inactive threshold are disabled.
4. Choose both colors. Buttons read Low (<=) / High (>) or Short (<) / Long (>=), matching the selected rule.
5. Use the single bottom **Apply** to commit and render. **Revert** restores the applied settings. Save Scene or Save Preset stores applied colors and thresholds; uncommitted edits are not saved.

![Current Threshold edge-color controls](../tutorials/assets/captures/topic-guides/edge-color-threshold-panel.png)

![Current Length edge-color controls](../tutorials/assets/captures/topic-guides/edge-color-length-panel.png)

These focused captures show the current controls, not the appearance of a rendered network. Changing the UI theme does not redefine edge groups. The captures do not certify all dark-theme contrasts or label readability.

## Legacy EC and older development files

For full-window layout behavior, see [window layout](Window_Layout.en.md). These focused controls do not certify every display session or DPI setting.

Legacy EC.edg.color=3/4 maps to Threshold/Length. Both require a finite RGB EC.edg.CM with at least 64 rows: row 1 is High/Long, row 64 is Low/Short. Missing/short/invalid arrays are rejected instead of inventing colors. Export restores those rows and the respective color_threshold/color_distance. Threshold color_abs=0/1 maps to Signed/Absolute, independently of draw_abs; a missing color_abs uses the legacy default Absolute. Length does not use color_abs. Import reports retain other unmapped fields for review.

Settings **1.6.0** adds edge.color_low, edge.color_high and edge.threshold_value_mode. The last field applies only to Threshold, not Mapped, size or opacity. Scene v0.1 and preset v1.0 envelopes are unchanged. Current-version documents missing required fields are rejected.

Settings 1.0–1.5 retain the previous base color as Low, use the previous colormap endpoint as High, and default Threshold Values to Absolute. This is a deterministic upgrade, **not recovery of the original EC or preservation of the previous continuous-color appearance**. Threshold equality and Length appearance can change. Review both colors or reimport the untouched original EC. Scene metadata includes edge_color_upgrade; camera rebinding occurs only if the old canonical input/settings signature matched. Stale cameras remain stale; presets do not carry cameras. Previous builds need not accept Settings 1.6.

## Mapped colors — development build update

Under **Edges > Color**, choose Mapped. **Mapped Values** independently chooses Signed or Absolute before range calculation; it does not alter selection, radii, opacity or Threshold Values. Leave the range field empty for Auto over retained weights, or enter `low high` for Fixed. Apply with the single global **Apply**; **Revert** restores applied values.

Mapped edges use 64 colors and the legacy index rule `round(weight*k+b)`, where `k=63/(high-low)` and `b=64-k*high`; indices are clipped to 1–64. Equal bounds (including constant Auto weights) use color 64. For example, a fixed range [-2,2] maps weights [-3,-2,0,2,3] to [1,1,33,64,64]. Named and modern custom palettes are sampled to 64 colors. This differs from the former 256-level mapping and its first-color constant rule. Nonfinite/complex weights, reversed ranges and arithmetic overflow are rejected.

Legacy Mapped EC (`edg.color=2`) imports `color_abs`, `color_map_type` (1 Auto / 2 Fixed), both fixed bounds and actual `CM` rows 1–64. Missing/invalid CM or incomplete Fixed bounds are rejected; longer tables use their first 64 rows, matching the legacy edge indexing. Missing sign/type use Absolute/Auto. Export writes an explicit 64-row CM and the corresponding active sign/range; inactive Auto bounds are canonicalized to 0/1. Colormap expression strings are not executed.

Settings **1.8.0** adds `edge.mapped_value_mode`. New settings default to Absolute; older 1.0–1.7 settings without this field migrate to Signed, preserving their former sign handling, **not their exact colors**. Previously ignored original EC sign/palette/range cannot be recovered: reimport the original EC when available. Scene metadata records `edge_mapped_color_upgrade`; valid old camera signatures alone are rebound. Review colors after migration. Scene/preset envelope versions remain unchanged.

These are focused tests only, not a new full regression or a full visual/UI certification. The focused settings captures above do not certify the rendered network's appearance.

## Remaining boundaries

### Module colors — development build update

Choose **Node Module** and set **Inter-module Color**. Both endpoints are compared: same-module edges use the **Nodes** module palette, cross-module edges use the explicit RGB. Sorted unique labels from **all loaded nodes**, including isolated/hidden nodes, determine palette rows; edge selection or direction does not renumber colors. Label 21 is an ordinary label, not a cross-module sentinel. Since focused check, same-module edges inherit the Nodes colormap; choose Nodes → Modules if visible node colors should match. The Edges colormap field does not override this mode.

This version supports at most **20 distinct modules**; extra modules produce an error, not recycled colors. Named/custom palettes are sampled to 20 rows. Legacy EC color=5 imports CM rows 1–20 plus inter-module row 21, and exports those 21 rows. Missing/short/invalid CM is rejected. Export equivalence requires at most 20 modules and no original label 21 because the old renderer has a sentinel collision; the App requires Modern Batch Renderer for this mode.

Settings **1.10.0** adds `edge.inter_module_color`. Older settings default to gray [0.5,0.5,0.5] and require color review; the former first-endpoint behavior is not preserved. Scene metadata records the upgrade and only rebinds valid old camera signatures. Reimport the original EC to recover its palette. Use the global Apply/Revert; no extra subpanel buttons. The focused settings captures above are not network-rendering acceptance evidence.

Uniform, Threshold and Length rules remain unchanged. Related guides cover [Raw/Threshold sizes and independent size signs](Edge_Sizes.en.md), [independent opacity signs](Edge_Opacity.en.md), [custom-matrix colors and node binding](Custom_Edge_Colors.en.md), [Inter Hemi Only](Edge_Hemisphere.en.md) and [sparsity/tie rules](Edge_Sparsity.en.md). This guide does not close every legacy-compatibility issue; see [known limitations](Migration.en.md#known-limitations).
