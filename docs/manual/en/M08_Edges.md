# Edges: selection, direction, size, color and opacity

[中文](../zh-CN/M08_Edges.md) · [Manual index](index.md) · [Sparsity details](../../documentation/Edge_Sparsity.en.md)

Use **Visualization Settings → Edges** to control connectivity selection, direction, size, color and opacity. An `.edge` matrix must follow the loaded `.node` row order. Values, coordinate distances and directed relationships have meaning only in that input's declared scientific context; neither edge lengths nor arrowheads imply white-matter tracts. The shared **Apply** commits and renders; **Revert** discards pending edits.

## Visibility and direction

| Control | New-settings default | Current rule |
|---|---|---|
| **Selection** | All Edges | All keeps nonzero eligible off-diagonal edges. Threshold keeps selection values `>= Threshold` (equality included). Sparsity (Top Count) ranks nonzero candidates and keeps a deterministic count. Sparsity (Legacy Threshold) ranks the full N×N matrix, converts its ranked value to a six-decimal cutoff, then keeps all eligible cutoff ties. These modes are **not** interchangeable. |
| **Threshold / Sparsity** | 0 / 0.1 | Threshold field is used only in Threshold; Sparsity fraction is 0–1 and used in either sparsity mode. Top Count fraction 0 selects none; Legacy Threshold fraction 0 still uses the largest matrix value and may show none if that value is diagonal. |
| **Selection Values** | Absolute | Signed or Absolute changes ranking/thresholding only; source weights are not rewritten. Other size/color/opacity signs have separate controls. |
| **Directed Edges** | off | Off uses nonzero upper-triangle candidates; on uses nonzero off-diagonal ordered pairs and draws arrowheads. The matrix is not automatically symmetrized. |
| **Inter Hemi Only** | off | After selection, retains opposite-X-side or midline endpoints by node X=0. This is a coordinate rule, not anatomical hemisphere detection. |

Top Count resolves equal-weight candidates by MATLAB column-major linear index; Legacy Threshold can retain all ties, so final visible density need not equal the fraction. Connected Nodes in M07 uses the finally selected edge pairs. See [exact sparsity and tie rules](../../documentation/Edge_Sparsity.en.md) and [X-side filtering](../../documentation/Edge_Hemisphere.en.md).

## Size and arrowheads

| Control | New-settings default | Current rule |
|---|---|---|
| **Size Mode** | Mapped | Uniform uses Base Size; Mapped maps retained weights to radii 0.4–6 (constant set: 2); Raw clamps to 0.2–6; Threshold first tests original sign-adjusted weights `>= Size Threshold`, then sizes qualifying edges by Mapped or Raw basis. Below threshold uses radius 0.4, not removal. |
| **Base Size / Size Scale** | 1 / 0.7 | Base Size is used in Uniform. Positive Size Scale multiplies radii once in all modes. These are radii in input-coordinate units, not pixel widths. |
| **Size Threshold / Threshold Basis** | 0 / Mapped | Enabled only in Threshold. Basis is Mapped or Raw; the threshold comparison precedes normalization and scaling. |
| **Size Values** | Absolute | Signed or Absolute is independent of Selection Values and color/opacity signs. Negative invalid final radii are rejected rather than silently made positive. |
| **Arrowhead Shape: Length / Width** | 1 / 0.7 | Enabled for Directed Edges. Multipliers are 0.25–3; length is capped at 35% of edge length. The edge tube ends at the arrowhead base to avoid overlap. These settings change geometry, not matrix direction or weight. |

Threshold+Raw has a different lower-radius rule from ordinary Raw; see [full radius calculation](../../documentation/Edge_Sizes.en.md). A zero-radius edge may be absent from geometry without changing its selection/Connected semantics.

## Color and opacity

| Control | New-settings default | Current rule |
|---|---|---|
| **Color Mode** | Uniform | Uniform uses one Color. Mapped uses a 64-entry palette. Threshold uses Low when value `<=` Color Threshold and High when `>`; Length uses Short when original-node Euclidean distance `<` Length Threshold and Long at `>=`. Node Module compares both endpoints; Custom Matrix uses an explicitly bound node-order color-index matrix. |
| **Color / Colormap / Color Limits** | `[1 0.9 0.73]` / Jet / Auto | The Color button is for Uniform. Mapped/Custom Matrix use the selected named colormap or Custom (Colors...); fixed `low high` limits apply only to Mapped. Auto uses retained color weights after selected sign handling. Equal limits use the last palette color. |
| **Color Threshold / Length Threshold** | 0 / 0 | Threshold coloring uses original edge weights with its own sign choice; equality is Low. Length uses input XYZ coordinate units, not tract/geodesic length; equality is Long. |
| **Threshold Values / Mapped Values** | Absolute / Absolute | Separate Signed/Absolute choices for their respective color modes. They do not change Selection Values, radii or opacity. |
| **Low / High colors; Inter-module Color** | gray `[.38 .38 .38]` / `[1 .9 .73]`; gray `[.5 .5 .5]` | Low/High are used for Threshold or Length (buttons become Short/Long). Node Module uses the Nodes module palette for same-module edges and Inter-module Color for different modules. Select Nodes → Modules to make visible node colors match. |
| **Load Colors... / Bind to Nodes** | no matrix | Custom Matrix only. Confirm matrix dimensions and original node order; the binding cannot independently establish scientific correspondence. |
| **Opacity Mode / Value / Range** | Uniform / 0.7 / `[0.1 0.9]` | Uniform uses one 0–1 opacity. Mapped maps selected weights to two **output** opacity endpoints in [0,1]; constant weights use the upper endpoint. A transparent edge is not deselected. |
| **Opacity Values** | Absolute | Signed/Absolute for Mapped opacity only, independent of selection, size and color. |

The **Node Module** palette is derived from the Nodes colormap; the Edges colormap selector does not override it. This mode supports at most 20 distinct modules and rejects excess categories rather than recycling colors. Custom Matrix colors require [explicit binding and file-format review](../../documentation/Custom_Edge_Colors.en.md). Color threshold/length endpoints are detailed in [Edge Colors](../../documentation/Edge_Colors.en.md); mapped opacity in [Edge Opacity](../../documentation/Edge_Opacity.en.md). Changing a visual option does not rewrite the `.edge` file or establish registration.

Before publishing, check dense or directed networks at the intended export size; an edge that is selected may still be hard to see because of its radius, opacity or overlap. The modern renderer is not guaranteed to match historical pixels exactly.
