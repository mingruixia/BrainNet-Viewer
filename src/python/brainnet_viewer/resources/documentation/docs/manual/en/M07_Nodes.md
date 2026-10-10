# Nodes: visibility, labels, size and color

[中文](../zh-CN/M07_Nodes.md) · [Manual index](index.md) · [Node data rules](../../documentation/Node_Selection.en.md)

Use **Visualization Settings → Nodes** to control marker visibility, labels, size and color. In a `.node` row, columns 1–3 are XYZ coordinates, **column 4 supplies module/color values**, column 5 supplies node-size values, and column 6 is a label. Verify units and anatomical space rather than inferring them from the extension. The shared **Apply** commits and renders; **Revert** discards pending edits.

## Visibility and labels

| Control | New-settings default | Current rule |
|---|---|---|
| **Selection** | All Nodes | Threshold keeps nodes with original **Selection Basis > Threshold**; equality is excluded. Connected Nodes keeps either endpoint of an edge retained after edge filtering; no selected edges means no Connected nodes. |
| **Selection Basis / Threshold** | Node Value / 0 | Enabled for Threshold. Node Value reads column 5; Module reads column 4. Module still uses a numeric `>` comparison, not equality to a chosen ID. Mapped radii and Scale do not affect this test. |
| **Label Mode** | No Labels | All Labels, No Labels, or Threshold. Labels appear only on visible nodes with nonzero rendered radius; a label exactly `-` is suppressed, but a hyphenated name remains valid. |
| **Label Basis / Label Threshold** | Node Value / 0 | Enabled for Threshold labels. Uses the original column 5 or 4 value with strict `>`; independent of node-selection threshold. |
| **Font / Font Size** | Arial / 10 | Font name and a positive numeric size (editor limit >0 to 100). Font Units defaults to Points; other offered units are Pixels, Normalized, Inches and Centimeters. |
| **Font Style / Label Color / Keep Labels in Front** | Normal + Normal / black / off | Weight is Normal or Bold; angle Normal or Italic. The front option changes display order, not data coordinates; it cannot guarantee collision-free dense labels. |

## Node size

| Control | New-settings default | Current rule |
|---|---|---|
| **Size Mode** | Mapped | Uniform uses Base Size; Mapped normalizes source values to radii; Raw uses unnormalized source values; Threshold uses either Mapped or Raw radius rules then replaces radii **strictly below** Size Threshold with 1. Equality remains. |
| **Size Source** | Node Value | Column 5 by default, or Module/column 4 as a modern extension. Inactive in Uniform. This choice does not alter color mode. |
| **Base Size / Scale** | 3 / 1 | Base Size matters in Uniform; positive Scale multiplies the resulting radius exactly once in all modes. Radius is in input-coordinate units, not screen pixels. |
| **Size Threshold: Mapped/Raw, value** | Mapped / 0 | Enabled only for Threshold. Comparison occurs before Scale; a below-threshold radius becomes 1 before scaling. This threshold changes size, not visibility. |

Mapped sizes follow the legacy normalization (including its log compression for large ranges); constant input gives radius 4 before Scale. Raw negative/invalid final radii are rejected rather than silently made positive. A zero final radius omits that sphere and its label but does not delete the input node or its edges. See [numeric size rules](../../documentation/Node_Sizes.en.md).

## Node color

| Control | New-settings default | Current rule |
|---|---|---|
| **Color Mode** | Uniform | Uniform uses one Color; Mapped samples a palette from **column 4**; Modules assigns colors by sorted unique column-4 module IDs; Threshold uses two colors split by column 4. Column 5 is not the default color source. |
| **Color / Colormap / Color Limits** | RGB `[37 89 152]/255` / Jet / Auto | Color button is active in Uniform. Palette is active for Mapped or Modules and can be custom through Colors...; fixed `low high` limits apply to Mapped, clamping outside values. Auto uses the full input column-4 range, not just visible nodes. |
| **Color Threshold / Low (<=) / High (>)** | 0 / `[37 89 152]/255` / red | In Threshold, column-4 values `<=` threshold use Low, values `>` use High. Mapped limits/palette do not change these two fixed colors. |

For Modules, the palette comes from the **Nodes** colormap; same-module edge coloring can inherit it when Edges → Node Module is selected. A custom palette is not the same as the explicit, geometry-bound Vertex RGB surface table. See [node color semantics](../../documentation/Node_Colors.en.md), [selection/labels](../../documentation/Node_Selection.en.md) and [label placement](../../documentation/Node_Labels.en.md).

Dense labels can overlap even when **Keep Labels in Front** is enabled. Inspect their placement at the intended export size and simplify labels or the view when necessary.
