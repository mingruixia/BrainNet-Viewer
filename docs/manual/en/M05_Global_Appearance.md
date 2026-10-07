# M05 · Global appearance and rendering detail

[中文](../zh-CN/M05_Global_Appearance.md) · [Manual index](index.md) · [Background policy](../../documentation/Backgrounds.en.md)

Use **Visualization Settings → Global** for the canvas background, shading, lighting and rendering detail. **Apply** commits and renders. A Scene or preset may contain different explicit values; the table describes new settings, not a promise to overwrite loaded configurations.

| Control | New-settings default | Meaning / constraints |
|---|---|---|
| **Background Color → Choose Color** | white `[1 1 1]` | Sets the scientific canvas background, not the Light/Dark interface theme. App export set to **current** follows the rendered canvas color. |
| **Surface Shading** | **Interpolated** | Flat, Faceted or Interpolated surface face/vertex shading. Faceted draws black mesh outlines and may cost more on dense meshes. This is display shading, not mesh smoothing. |
| **Lighting Model** | **Phong** | None, Flat, Gouraud or Phong lighting for shaded geometry. Appearance depends on material, view and graphics backend. |
| **Light Direction** | **Right** | Headlight, Right or Left. Camera/light behavior should be inspected after manual rotation; the choice does not change data coordinates. |
| **Surface Material** | **Dull** | Dull, Shiny, Metal or Custom. Custom enables the three strength fields below; presets follow MATLAB's material behavior. |
| **Ambient / Diffuse / Specular Strength** | `[0.5 0.5 0.5]` stored | Each accepts 0–1 and is editable for Custom material. Values affect lighting response, not underlying scalar data. |
| **Render Detail** | **Adaptive (modern)** | Adaptive uses load-aware renderer policy. Legacy Low/Moderate/High use node sphere detail 10/50/100 and edge-cylinder sides 5/10/20; High can be costly. The surface topology is unchanged. |
| **Show Orientation Labels** | off | Multi-view pane badges are X<=0 / X>0 unless the Scene has an explicit, input-bound anatomical-X declaration; only then can they say L/R. They label panes, not the screen's left/right edge. Single View and six complete-data Overview have no half-space badges. |

## Compare appearance settings

Material changes the balance of ambient, diffuse and specular reflections. **Dull** gives a relatively subdued shape; **Shiny** and **Metal** emphasize highlights. A Custom material lets you adjust the three strengths rather than replacing the input mesh. Surface Shading controls whether neighboring vertex colors are interpolated and whether triangle boundaries are visible; use Faceted to inspect mesh edges, not to infer an anatomical boundary. The Lighting Model controls how illumination is calculated, while Light Direction chooses where it comes from. These are separate decisions: an interpolated color map can still look flat under weak lighting, and changing illumination never changes a statistic in the source map.

The appearance gallery compares material, shading and light direction on one geometry. Set the palette and statistical range first, choose lighting and material, then check legibility at the intended export size. Use **Render Detail** conservatively on dense networks: higher sphere and cylinder tessellation increases geometry without adding measurements or changing surface topology.

**Restore Defaults** resets display settings while keeping the current canvas visible. Click **Apply** or **Render Scene** to redraw; export is paused until the retained preview is replaced. It does not return to the welcome page.

**Theme** in the top bar changes UI colors only. For export, **current** preserves the actual scientific canvas background; transparent raster requests may be rejected rather than silently flattened. See [backgrounds](../../documentation/Backgrounds.en.md). Lighting/material specifics and the exact legacy geometry table are in [Material Settings](../../documentation/Material_Settings.en.md) and [Render Detail](../../documentation/Render_Detail.en.md).

The App does not infer anatomy from a filename or species. To show anatomical L/R, first verify coordinate units, shared registration, the X=0 midline and positive-X direction, then attach the declaration to hashed Scene inputs using the [documented Scene/API workflow](../../documentation/Orientation_Labels.en.md). Merely ticking **Show Orientation Labels** without that declaration shows coordinate halves. Check label contrast on the display and in the exported figure.
