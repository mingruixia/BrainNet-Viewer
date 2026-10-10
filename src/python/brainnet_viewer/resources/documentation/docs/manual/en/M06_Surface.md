# Surface appearance, maps and boundaries

[中文](../zh-CN/M06_Surface.md) · [Manual index](index.md) · [Boundary details](../../documentation/Surface_Boundaries.en.md)

Use **Visualization Settings → Surface** to set the surface color, opacity, boundaries and vertex colors. **Apply** commits and renders. A loaded Scene or preset keeps its explicit values unless you edit them.

| Control | New-settings default | Meaning / enabling rule |
|---|---|---|
| **Color Mode** | Uniform | **Uniform** uses one RGB surface color; **Scalar Map** colors vertices from a loaded surface map or supported volume-to-surface mapping; **Vertex RGB** uses an explicitly bound original-order RGB table. Choose the mode that matches the data, not merely a desired palette. |
| **Uniform Color** | `[0.95 0.95 0.95]` | Active only for Uniform; **Choose Surface Color** changes the single color. |
| **Opacity** | Settings default 0.3 | Slider range 0 (transparent) to 1 (opaque). A new surface-only or surface-plus-map/volume Scene instead starts at **1**; explicit Scene/preset values are preserved. This display opacity does not change input values. |
| **Colormap** | Parula | Active for a loaded scalar surface map. Choose a named palette or **Custom (Colors...)**. Volume-to-surface coloring uses the **Volume** panel's separate colormap; Vertex RGB bypasses scalar palettes. |
| **Color Limits** | Auto | For Scalar Map, enter `Auto` or two numeric endpoints (for example `-2 2`). Fixed limits control color scaling, not vertex-value filtering. Recheck them when switching datasets. |
| **Show Surface Colorbar** | on | Shows one continuous colorbar when a scalar surface map or volume-to-surface map is displayed; Uniform and Vertex RGB have no scalar bar. Existing Scenes/presets retain an explicit off setting. Atlas ROI ID legends are separate categorical keys. |
| **Boundary** | None | **Automatic** draws class-transition lines; **Threshold** marks vertices at a strict value threshold; **Custom Mask** uses an original-order binary mask. Boundary operations need the relevant map except Custom Mask. |
| **Boundary Color** | black `[0 0 0]` | Active when a boundary mode is selected; changes display color only. |
| **Boundary Threshold** | 0 | Numeric field used only by Threshold; its classification is `value > threshold`, not `>=`. |
| **Load Mask... / Bind to Surface** | no mask | Available for Custom Mask. Import or bind a binary table only after verifying original vertex order; a matching count alone cannot prove anatomical correspondence. The status line reports binding state. |
| **Double Brain** | off | Displays a second copy of one surface in Single View, Left/Superior/Anterior only; optional node/edge data follow explicit row ordering. No surface-map/volume input. This is not arbitrary two-subject composition. |
| **Load RGB... / Bind RGB** | no RGB table | Text is N×3 finite RGB in [0,1] for one brain, or 2N×3 for Double Brain, in original surface vertex order. Binding is required; it does not independently verify initial correspondence. The status line reports binding state. |

## Double Brain and boundary examples

Double Brain copies **one** surface for a side-by-side network comparison. If a node file contains N rows, rows 1 through `floor(N/2)` belong to the first display and the remaining rows to the second. For example, a 180-row file may place 90 matched regions in each copy. Its edge file is then 180×180: the upper-left and lower-right 90×90 blocks describe within-copy connections, and the two off-diagonal blocks describe connections between copies. The program does not discover which rows correspond to the same regions or verify a longitudinal, group or subject interpretation. Prepare and review the ordering before turning on Double Brain; an ordinary 90×90 edge matrix is not the paired network for a 180-row node file.

The boundary gallery compares Double Brain, categorical atlas outlines and continuous mapped color. A region outline is a display boundary, not a new ROI volume. Continuous colors require a scale and must not be interpreted as category IDs. Automatic, Threshold and Custom Mask boundaries follow the rules above. Recheck visibility when changing surface opacity, map range or export resolution.

**Automatic** in the current panel is the modern line-style boundary option; an older Legacy Automatic setting can be read for compatibility but is not a separate current panel choice. Threshold and Custom Mask use vertex colors rather than geometric isolines. See [boundary algorithms and mask safety](../../documentation/Surface_Boundaries.en.md). **Vertex RGB** preserves the original mesh while active and can cost more for large surfaces; it is not a scalar map or statistical threshold. See [RGB format/binding](../../documentation/Vertex_RGB.en.md) and [Double Brain ordering](../../documentation/Double_Brain.en.md).

The **Volume** section controls volume mapping algorithm, sign/threshold handling and ROI drawing; these are separate from Surface's scalar palette and are described in M09. A visually plausible map is not evidence that the mesh and volume are registered. Confirm coordinate spaces before anatomical interpretation.

For an AAL-derived vertex-label exercise with **Automatic** boundaries and binary-mask export, see [tutorial 04](../../tutorials/en/04_Vertex_Maps_and_Boundaries.md). Atlas IDs are categories, not effect sizes.

## Inspect on the rendered canvas

Click **Inspect**, then click a displayed **surface vertex or node**. A compact label inside that view shows the source index, available value or module information, assumed-MNI XYZ, **Brodmann Area** and **AAL region**. Another pick replaces the label; clicking Inspect again clears it. There is no separate popup. Edges, arrowheads, ROI meshes and fibers are not pick targets. Surface picks report the nearest displayed source vertex rather than interpolating the exact mouse-hit position.

Inspect treats input coordinates as already in the relevant MNI-like space. It does not register data, apply transforms or verify alignment. Native-space, animal or unregistered inputs may produce plausible but incorrect labels. Verify coordinates before anatomical interpretation. See [Inspect limits](../../documentation/Scene_Inspection.en.md).

The bundled AAL/Brodmann lookup resources support the [AAL vertex-map exercise](../../tutorials/en/04_Vertex_Maps_and_Boundaries.md). A successful lookup does not prove spatial registration.
